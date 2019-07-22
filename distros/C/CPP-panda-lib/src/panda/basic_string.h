#pragma once
#include "hash.h"
#include "from_chars.h"
#include "string_view.h"
#include <string>
#include <limits>
#include <memory>
#include <iosfwd>
#include <cstdint>
#include <utility>   // swap
#include <assert.h>
#include <iterator>
#include <stdexcept>
#include <initializer_list>

namespace panda {

/*
 * panda::string is an std::string drop-in replacement which has the same API but is much more flexible and allows for behaviors that in other case
 * would lead to a lot of unnecessary allocations/copying.
 *
 * Most important features are:
 *
 * - Copy-On-Write support (COW).
 *       Not only when assigning the whole string but also when any form of substr() is applied.
 *       If any of the COW copies is trying to change, it detaches from the original string, copying the content it needs.
 * - External static string support.
 *       Can be created from external static(immortal) data without allocating memory and copying it.
 *       String will be allocated and copied when you first try to change it.
 *       For example if a function accepts string, you may pass it just a string literal "hello" and nothing is allocated or copied and even the length
 *       is counted in compile time.
 * - External dynamic string support.
 *       Can be created from external dynamic(mortal) data without allocating memory and copying it.
 *       External data will be deallocated via custom destructor when the last string that references to the external data is lost.
 *       As for any other subtype of panda::string copying/substr/etc of such string does not copy anything
 * - SSO support (small string optimization). Up to 23 bytes for 64bit / 11 bytes for 32bit.
 *       It does not mean that all strings <= MAX_SSO_CHARS are in SSO mode. SSO mode is used only when otherwise panda::string would have to allocate
 *       and copy something. For example if you call "otherstr = mystr.substr(offset, len)", then otherstr will not use SSO even if len <= MAX_SSO_CHARS,
 *       because it prefers to do nothing (COW-mode) instead of copying content to SSO location.
 * - Support for getting r/w internal data buffer to manually fill it.
 *       The content of other strings which shares the data with current string will not be affected.
 * - Reallocate instead of deallocate/allocate when possible, which in many cases is much faster
 * - Supports auto convertations between basic_strings with different Allocator template parameter without copying and allocating anything.
 *       For example any basic_string<...> can be assigned to/from string as if they were of the same class.
 *
 * All these features covers almost all generic use cases, including creating zero-copy cascade parsers which in other case would lead to a lot of
 * pain.
 *
 * c_str() is not supported, because strings are not null-terminated
 */

template <class T>
struct DefaultStaticAllocator {
    typedef T value_type;

    static T* allocate (size_t n) {
        void* mem = malloc(n * sizeof(T));
        if (!mem) throw std::bad_alloc();
        return (T*)mem;
    }

    static void deallocate (T* mem, size_t) {
        free(mem);
    }

    static T* reallocate (T* mem, size_t need, size_t /*old*/) {
        void* new_mem = realloc(mem, need * sizeof(T));
        //if (new_mem != mem) { call move constructors if applicable }
        return (T*)new_mem;
    }
};

namespace {
template <typename S>
class _mutable_charref {
public:
    using value_type = typename S::value_type;
    using size_type = typename S::size_type;

    _mutable_charref(S& string, size_type pos): _string(string), _pos(pos) {}

    template <typename Arg, typename = typename std::enable_if<std::is_convertible<Arg, value_type>::value> >
    _mutable_charref& operator= (Arg&& value) {
        _string._detach();
        _string._str[_pos] = std::forward<Arg>(value);
        return *this;
    }
    operator value_type() const { return _string._str[_pos]; }
private:
    S& _string;
    size_type _pos;
};

} // end of anonymous namespace


template <class CharT>
class _basic_string_base {
protected:
    typedef void (*dtor_fn) (CharT*, size_t);

    enum class State : uint8_t {
        INTERNAL, // has InternalBuffer, may have _dtor in case of basic_string<A,B,X> <-> basic_string<A,B,Y> convertations
        EXTERNAL, // has ExternalShared, shares external data, _dtor present, _ebuf->dtor present
        LITERAL,  // shares external data, no Buffer, no _dtor (literal data is immortal)
        SSO       // owns small string, no Buffer, no _dtor
    };

    struct Buffer {
        size_t   capacity;
        uint32_t refcnt;
        CharT    start[(sizeof(void*)-4)/sizeof(CharT)]; // align to word size
    };

    struct ExternalShared : Buffer {
        dtor_fn dtor; // deallocator for ExternalShared, may differ from Alloc::deallocate !
        CharT*  ptr;  // pointer to external data originally passed to string's constructor
    };
};

template <class CharT, class Traits = std::char_traits<CharT>, class Alloc = DefaultStaticAllocator<CharT>>
class basic_string : private _basic_string_base<CharT> {
public:
    class iterator;
    typedef Traits                                     traits_type;
    typedef Alloc                                      allocator_type;
    typedef std::allocator_traits<allocator_type>      allocator_traits;
    typedef typename Traits::char_type                 value_type;
    typedef value_type&                                reference;
    typedef const value_type&                          const_reference;
    typedef typename allocator_traits::pointer         pointer;
    typedef typename allocator_traits::const_pointer   const_pointer;
    typedef const CharT*                               const_iterator;
    typedef std::reverse_iterator<iterator>            reverse_iterator;
    typedef std::reverse_iterator<const_iterator>      const_reverse_iterator;
    typedef typename allocator_traits::difference_type difference_type;
    typedef typename allocator_traits::size_type       size_type;

    using typename _basic_string_base<CharT>::ExternalShared;

private:
    using typename _basic_string_base<CharT>::State;
    using typename _basic_string_base<CharT>::dtor_fn;
    using typename _basic_string_base<CharT>::Buffer;

    template <class C, class T, class A> friend class basic_string;
    friend class _mutable_charref<basic_string>;

    union {
        CharT*       _str;
        const CharT* _str_literal;
    };

    size_type _length;

    union {
        Buffer*         _buf;
        ExternalShared* _ebuf;
        CharT           _sso_start[sizeof(void*)/sizeof(CharT)]; // SSO start (aligned)
    };

    dtor_fn _dtor;
    int8_t  _align[sizeof(void*)-1]; // align to word size (_state is 1 byte), SSO end
    State   _state;

    static const size_type BUF_CHARS     = (sizeof(*_buf) - sizeof(_buf->start)) / sizeof(CharT);
    static const size_type EBUF_CHARS    = sizeof(ExternalShared) / sizeof(CharT);
    static const size_type MAX_SSO_BYTES = sizeof(_buf) + sizeof(_dtor) + sizeof(_align);
    static const CharT     TERMINAL;

public:
    static const size_type npos          = std::numeric_limits<size_type>::max();
    static const size_type MAX_SSO_CHARS = (MAX_SSO_BYTES / sizeof(CharT));
    static const size_type MAX_SIZE      = npos / sizeof(CharT) - BUF_CHARS;

    constexpr basic_string () : _str_literal(&TERMINAL), _length(0), _state(State::LITERAL) {}

    template <size_type SIZE> // implicit constructor for literals, literals are expected to be null-terminated
    constexpr basic_string (const CharT (&str)[SIZE]) : _str_literal(str), _length(SIZE-1), _state(State::LITERAL) {}

    explicit
    basic_string (size_type capacity) : _length(0) {
        _new_auto(capacity);
    }

    basic_string (const CharT* str, size_type len) : _length(len) {
        _new_auto(len);
        traits_type::copy(_str, str, len);
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    explicit
    basic_string (const _CharT* const& str) : basic_string(str, traits_type::length(str)) {}

    basic_string (CharT* str, size_type len, size_type capacity, dtor_fn dtor) {
        _new_external(str, len, capacity, dtor, (ExternalShared*)Alloc::allocate(EBUF_CHARS), &Alloc::deallocate);
    }

    basic_string (CharT* str, size_type len, size_type capacity, dtor_fn dtor, ExternalShared* ebuf, dtor_fn ebuf_dtor) {
        _new_external(str, len, capacity, dtor, ebuf, ebuf_dtor);
    }

    basic_string (size_type len, CharT c) : _length(len) {
        _new_auto(len);
        traits_type::assign(_str, len, c);
    }

    basic_string (const basic_string& oth) {
        _cow(oth, 0, oth._length);
    }

    template <class Alloc2>
    basic_string (const basic_string<CharT, Traits, Alloc2>& oth) {
        _cow(oth, 0, oth._length);
    }

    template <class Alloc2>
    basic_string (const basic_string<CharT, Traits, Alloc2>& oth, size_type pos) {
        _cow_offset(oth, pos, oth._length);
    }

    template <class Alloc2>
    basic_string (const basic_string<CharT, Traits, Alloc2>& oth, size_type pos, size_type len) {
        _cow_offset(oth, pos, len);
    }

    basic_string (basic_string&& oth) {
        _move_from(std::move(oth));
    }

    template <class Alloc2>
    basic_string (basic_string<CharT, Traits, Alloc2>&& oth) {
        _move_from(std::move(oth));
    }

    basic_string (std::initializer_list<CharT> ilist) : basic_string(ilist.begin(), ilist.size()) {}

    explicit
    basic_string (basic_string_view<CharT, Traits> sv) : basic_string(sv.data(), sv.length()) {}

    template <size_type SIZE>
    basic_string& assign (const CharT (&str)[SIZE]) {
        _release();
        _state       = State::LITERAL;
        _str_literal = str;
        _length      = SIZE - 1;
        return *this;
    }

    class iterator {
    public:
        using size_type         = typename basic_string::size_type;
        using value_type        = typename basic_string::value_type;
        using reference         = _mutable_charref<basic_string>;
        using pointer           = _mutable_charref<basic_string>;
        using difference_type   = std::ptrdiff_t;
        using iterator_category = std::random_access_iterator_tag;
        using const_iterator    = typename basic_string::const_iterator;

        iterator(basic_string& string, size_type pos): _string(string), _pos(pos) {}

        iterator& operator++()                      { ++_pos; return *this; }
        iterator operator++(int)                    { iterator copy{_string, _pos }; ++_pos; return copy; }
        iterator& operator--()                      { --_pos; return *this; }
        iterator operator--(int)                    { iterator copy{_string, _pos }; --_pos; return copy; }
        iterator& operator+=(int delta)             { _pos += delta; return *this; }
        iterator& operator-=(int delta)             { _pos -= delta; return *this; }
        reference operator*()                       { return reference{_string, _pos}; }
        reference operator->()                      { return reference{_string, _pos}; }
        reference operator[](size_type i)           { return reference{_string, i + _pos}; }

        difference_type operator-(const iterator& rhs) const { return static_cast<difference_type>(_pos - rhs._pos); }

        bool operator==(const iterator& rhs) const { return _pos == rhs._pos; }
        bool operator!=(const iterator& rhs) const { return _pos != rhs._pos; }
        bool operator< (const iterator& rhs) const { return rhs._pos - _pos > 0; }
        bool operator> (const iterator& rhs) const { return _pos - rhs._pos > 0; }
        bool operator<=(const iterator& rhs) const { return rhs._pos - _pos >= 0; }
        bool operator>=(const iterator& rhs) const { return _pos - rhs._pos >= 0; }

        operator const_iterator() { return _string.data() + _pos; }

        friend inline iterator operator+(int delta, const iterator& it) { return iterator{it._string, it._pos + delta}; }
        friend inline iterator operator+(const iterator& it, int delta) { return iterator{it._string, it._pos + delta}; }
        friend inline iterator operator-(int delta, const iterator& it) { return iterator{it._string, it._pos - delta}; }
        friend inline iterator operator-(const iterator& it, int delta) { return iterator{it._string, it._pos - delta}; }

    private:
        basic_string& _string;
        size_type _pos;
    };


    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    basic_string& assign (const _CharT* const& str) {
        return assign(str, traits_type::length(str));
    }

    basic_string& assign (const CharT* str, size_type len) {
        _reserve_drop(len);
        traits_type::copy(_str, str, len);
        _length = len;
        return *this;
    }

    basic_string& assign (CharT* str, size_type len, size_type capacity, dtor_fn dtor) {
        if (_state != State::EXTERNAL || _buf->refcnt != 1) {
            _release();
            _new_external(str, len, capacity, dtor, (ExternalShared*)Alloc::allocate(EBUF_CHARS), &Alloc::deallocate);
        }
        else _replace_external(str, len, capacity, dtor);
        return *this;
    }

    basic_string& assign (CharT* str, size_type len, size_type capacity, dtor_fn dtor, ExternalShared* ebuf, dtor_fn ebuf_dtor) {
        // EXTERNAL refcnt==1 optimizations do not apply because user already allocated ebuf and in either case we would need to deallocate one ebuf
        _release();
        _new_external(str, len, capacity, dtor, ebuf, ebuf_dtor);
        return *this;
    }

    basic_string& assign (size_type len, CharT c) {
        _reserve_drop(len);
        traits_type::assign(_str, len, c);
        _length = len;
        return *this;
    }

    template <class Alloc2>
    basic_string& assign (const basic_string<CharT, Traits, Alloc2>& source) {
        if (std::is_same<Alloc, Alloc2>::value && this == (void*)&source) return *this;
        _release();
        _cow(source, 0, source._length);
        return *this;
    }

    template <class Alloc2>
    basic_string& assign (const basic_string<CharT, Traits, Alloc2>& source, size_type pos, size_type length = npos) {
        if (std::is_same<Alloc, Alloc2>::value && this == (void*)&source)
            offset(pos, length);
        else {
            _release();
            _cow_offset(source, pos, length);
        }
        return *this;
    }

    template <class Alloc2>
    basic_string& assign (basic_string<CharT, Traits, Alloc2>&& source) {
        if (std::is_same<Alloc, Alloc2>::value && this == (void*)&source) return *this;
        _release();
        _move_from(std::move(source));
        return *this;
    }

    basic_string& assign (std::initializer_list<CharT> ilist) {
        return assign(ilist.begin(), ilist.size());
    }

    basic_string& assign (basic_string_view<CharT, Traits> sv) {
        return assign(sv.data(), sv.length());
    }

    template <size_type SIZE>
    basic_string& operator= (const CharT (&str)[SIZE])                          { return assign(str); }
    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    basic_string& operator= (const _CharT* const& str)                          { return assign(str); }
    basic_string& operator= (CharT c)                                           { return assign(1, c); }
    basic_string& operator= (const basic_string& source)                        { return assign(source); }
    template <class Alloc2>
    basic_string& operator= (const basic_string<CharT, Traits, Alloc2>& source) { return assign(source); }
    basic_string& operator= (basic_string&& source)                             { return assign(std::move(source)); }
    template <class Alloc2>
    basic_string& operator= (basic_string<CharT, Traits, Alloc2>&& source)      { return assign(std::move(source)); }
    basic_string& operator= (std::initializer_list<CharT> ilist)                { return assign(ilist); }
    basic_string& operator= (basic_string_view<CharT, Traits> sv)               { return assign(sv); }

    constexpr size_type    length   () const { return _length; }
    constexpr size_type    size     () const { return _length; }
    constexpr bool         empty    () const { return _length == 0; }
    constexpr const CharT* data     () const { return _str; }
    constexpr size_type    max_size () const { return MAX_SIZE; }

    CharT* buf        () { _detach(); return _str; }
    CharT* shared_buf () { _shared_detach(); return _str; }

    CharT* reserve (size_type capacity) {
        _reserve_save(capacity);
        return _str;
    }

    iterator         begin   () { return iterator(*this, 0); }
    iterator         end     () { return iterator(*this, _length); }
    reverse_iterator rbegin  () { return reverse_iterator(end()); }
    reverse_iterator rend    () { return reverse_iterator(begin()); }

    constexpr const_iterator         cbegin  () const { return data(); }
    constexpr const_iterator         begin   () const { return cbegin(); }
    constexpr const_iterator         cend    () const { return data() + _length; }
    constexpr const_iterator         end     () const { return cend(); }
    constexpr const_reverse_iterator crbegin () const { return const_reverse_iterator(cend()); }
    constexpr const_reverse_iterator rbegin  () const { return crbegin(); }
    constexpr const_reverse_iterator crend   () const { return const_reverse_iterator(cbegin()); }
    constexpr const_reverse_iterator rend    () const { return crend(); }

    explicit
    constexpr operator bool () const { return _length; }

    operator std::basic_string<CharT,Traits> () const { return std::basic_string<CharT,Traits>(_str, _length); }
    operator basic_string_view<CharT,Traits> () const { return basic_string_view<CharT,Traits>(_str, _length); }

    const CharT& at (size_type pos) const {
        if (pos >= _length) throw std::out_of_range("basic_string::at");
        return _str[pos];
    }

    _mutable_charref<basic_string> at (size_type pos) {
        if (pos >= _length) throw std::out_of_range("basic_string::at");
        return _mutable_charref<basic_string>{ *this, pos };
    }

    constexpr const CharT& operator[] (size_type pos) const { return _str[pos]; }
    _mutable_charref<basic_string> operator[] (size_type pos) { return _mutable_charref<basic_string>{ *this, pos }; }

    constexpr const CharT& front () const { return _str[0]; }
    constexpr const CharT& back  () const { return _str[_length-1]; }
    _mutable_charref<basic_string> front () { return _mutable_charref<basic_string>{ *this, 0 }; }
    _mutable_charref<basic_string> back  () { return _mutable_charref<basic_string>{ *this, _length-1 }; }

    size_type capacity () const {
        switch (_state) {
            case State::INTERNAL: return _buf->refcnt == 1 ? _capacity_internal() : 0;
            case State::EXTERNAL: return _buf->refcnt == 1 ? _capacity_external() : 0;
            case State::LITERAL:  return 0;
            case State::SSO:      return _capacity_sso();
        }
        return 0;
    }

    size_type shared_capacity () const {
        switch (_state) {
            case State::INTERNAL: return _capacity_internal();
            case State::EXTERNAL: return _capacity_external();
            case State::LITERAL:  return 0;
            case State::SSO:      return _capacity_sso();
        }
        return 0;
    }

    uint32_t use_count () const {
        switch (_state) {
            case State::INTERNAL:
            case State::EXTERNAL:
                return _buf->refcnt;
            default: return 1;
        }
    }

    void length (size_type newlen) { _length = newlen; }

    void offset (size_type offset, size_type length = npos) {
        if (offset > _length) throw std::out_of_range("basic_string::offset");
        if (length > _length - offset) _length = _length - offset;
        else _length = length;
        _str += offset;
    }

    basic_string substr (size_type offset = 0, size_type length = npos) const {
        return basic_string(*this, offset, length);
    }

    void resize (size_type count) { resize(count, CharT()); }

    void resize (size_type count, CharT ch) {
        if (count > _length) {
            _reserve_save(count);
            traits_type::assign(_str + _length, count - _length, ch);
        }
        _length = count;
    }

    void pop_back () { --_length; }
    void clear    () { _length = 0; }

    void shrink_to_fit () {
        switch (_state) {
            case State::INTERNAL:
                if (_length < MAX_SSO_CHARS) {
                    auto old_buf  = _buf;
                    auto old_dtor = _dtor;
                    _detach_str(_length);
                    _release_internal(old_buf, old_dtor);
                }
                else if (_buf->capacity > _length) {
                    if (_buf->refcnt == 1) _internal_realloc(_length);
                    // else _detach_cow(_length); // NOTE: it's a very hard question should or should not we do it, NOT FOR NOW
                }
                break;
            case State::EXTERNAL:
                if (_length < MAX_SSO_CHARS) {
                    auto old_buf  = _ebuf;
                    auto old_dtor = _dtor;
                    _detach_str(_length);
                    _release_external(old_buf, old_dtor);
                }
                else if (_buf->capacity > _length) {
                    if (_buf->refcnt == 1) _external_realloc(_length);
                    // else _detach_cow(_length); // NOTE: it's a very hard question should or should not we do it, NOT FOR NOW
                }
                break;
            case State::LITERAL:
            case State::SSO:
                break;
        }
    }

    template <class Alloc2>
    void swap (basic_string<CharT, Traits, Alloc2>& oth) {
        std::swap(_str, oth._str);
        std::swap(_length, oth._length);
        std::swap(_buf, oth._buf);
        std::swap(_dtor, oth._dtor);
        std::swap(*((void**)_align), *((void**)oth._align)); // swaps _state also
        if (_state == State::SSO) _str = _sso_start + (_str - oth._sso_start); //  "oth" was SSO
        if (oth._state == State::SSO) oth._str = oth._sso_start + (oth._str - _sso_start); // "this" was SSO
    }

    size_type copy (CharT* dest, size_type count, size_type pos = 0) const {
        if (pos > _length) throw std::out_of_range("basic_string::copy");
        if (count > _length - pos) count = _length - pos;
        traits_type::copy(dest, _str + pos, count);
        return count;
    }

    basic_string& erase (size_type pos = 0, size_type count = npos) {
        if (pos > _length) throw std::out_of_range("basic_string::erase");

        if (count > _length - pos) { // remove trail
            _length = pos;
            return *this;
        }

        _length -= count;

        if (pos == 0) { // remove head
            _str += count;
            return *this;
        }

        switch (_state) {
            case State::INTERNAL:
            case State::EXTERNAL:
                if (_buf->refcnt == 1) {
            case State::SSO:
                    // move tail or head depending on what is shorter
                    if (pos >= _length - pos) traits_type::move(_str + pos, _str + pos + count, _length - pos); // tail is shorter
                    else { // head is shorter
                        traits_type::move(_str + count, _str, pos);
                        _str += count;
                    }
                    break;
                }
                else --_buf->refcnt; // fallthrough
            case State::LITERAL:
                auto old_str = _str;
                _new_auto(_length);
                traits_type::copy(_str, old_str, pos);
                traits_type::copy(_str + pos, old_str + pos + count, _length - pos);
                break;
        }
        return *this;
    }

    const_iterator erase (const_iterator it) {
        size_type pos = it - cbegin();
        erase(pos, 1);
        return cbegin() + pos;
    }

    const_iterator erase (const_iterator first, const_iterator last) {
        size_type pos = first - cbegin();
        erase(pos, last - first);
        return cbegin() + pos;
    }

    template <class Alloc2>
    int compare (const basic_string<CharT, Traits, Alloc2>& str) const {
        return _compare(_str, _length, str._str, str._length);
    }

    template <class Alloc2>
    int compare (size_type pos1, size_type count1, const basic_string<CharT, Traits, Alloc2>& str) const {
        if (pos1 > _length) throw std::out_of_range("basic_string::compare");
        if (count1 > _length - pos1) count1 = _length - pos1;
        return _compare(_str + pos1, count1, str._str, str._length);
    }

    template <class Alloc2>
    int compare (size_type pos1, size_type count1, const basic_string<CharT, Traits, Alloc2>& str, size_type pos2, size_type count2 = npos) const {
        if (pos1 > _length || pos2 > str._length) throw std::out_of_range("basic_string::compare");
        if (count1 > _length - pos1) count1 = _length - pos1;
        if (count2 > str._length - pos2) count2 = str._length - pos2;
        return _compare(_str + pos1, count1, str._str + pos2, count2);
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    int compare (const _CharT* const& s) const {
        return _compare(_str, _length, s, traits_type::length(s));
    }

    template <size_type SIZE>
    int compare (const CharT (&s)[SIZE]) const {
        return _compare(_str, _length, s, SIZE-1);
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    int compare (size_type pos1, size_type count1, const _CharT* const& s) const {
        return compare(pos1, count1, s, traits_type::length(s));
    }

    template <size_type SIZE>
    int compare (size_type pos1, size_type count1, const CharT (&s)[SIZE]) const {
        return compare(pos1, count1, s, SIZE-1);
    }

    int compare (size_type pos1, size_type count1, const CharT* ptr, size_type count2) const {
        if (pos1 > _length) throw std::out_of_range("basic_string::compare");
        if (count1 > _length - pos1) count1 = _length - pos1;
        return _compare(_str + pos1, count1, ptr, count2);
    }

    int compare (basic_string_view<CharT, Traits> sv) const {
        return _compare(_str, _length, sv.data(), sv.length());
    }

    int compare (size_type pos1, size_type count1, basic_string_view<CharT, Traits> sv) const {
        return compare(pos1, count1, sv.data(), sv.length());
    }

    template <class Alloc2>
    size_type find (const basic_string<CharT, Traits, Alloc2>& str, size_type pos = 0) const {
        return find(str._str, pos, str._length);
    }

    size_type find (const CharT* s, size_type pos, size_type count) const {
        if (pos > _length) return npos;
        if (count == 0) return pos;

        const CharT* ptr = traits_type::find(_str + pos, _length - pos, *s);
        const CharT* end = _str + _length;
        while (ptr && end >= ptr + count) {
            if (traits_type::compare(ptr, s, count) == 0) return ptr - _str;
            ptr = traits_type::find(ptr+1, end - ptr - 1, *s);
        }

        return npos;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    size_type find (const _CharT* const& s, size_type pos = 0) const {
        return find(s, pos, traits_type::length(s));
    }

    template <size_type SIZE>
    size_type find (const CharT (&s)[SIZE], size_type pos = 0) const {
        return find(s, pos, SIZE-1);
    }

    size_type find (CharT ch, size_type pos = 0) const {
        if (pos >= _length) return npos;
        const CharT* ptr = traits_type::find(_str + pos, _length - pos, ch);
        if (ptr) return ptr - _str;
        return npos;
    }

    size_type find (basic_string_view<CharT, Traits> sv, size_type pos = 0) const {
        return find(sv.data(), pos, sv.length());
    }

    template <class Alloc2>
    size_type rfind (const basic_string<CharT, Traits, Alloc2>& str, size_type pos = npos) const {
        return rfind(str._str, pos, str._length);
    }

    size_type rfind (const CharT* s, size_type pos, size_type count) const {
        for (const CharT* ptr = _str + ((pos >= _length - count) ? (_length - count) : pos); ptr >= _str; --ptr)
            if (traits_type::compare(ptr, s, count) == 0) return ptr - _str;
        return npos;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    size_type rfind (const _CharT* const& s, size_type pos = 0) const {
        return rfind(s, pos, traits_type::length(s));
    }

    template <size_type SIZE>
    size_type rfind (const CharT (&s)[SIZE], size_type pos = 0) const {
        return rfind(s, pos, SIZE-1);
    }

    size_type rfind (CharT ch, size_type pos = npos) const {
        const CharT* ptr = _str + (pos >= _length ? _length : (pos+1));
        while (--ptr >= _str) if (traits_type::eq(*ptr, ch)) return ptr - _str;
        return npos;
    }

    size_type rfind (basic_string_view<CharT, Traits> sv, size_type pos = npos) const {
        return rfind(sv.data(), pos, sv.length());
    }

    template <class Alloc2>
    size_type find_first_of (const basic_string<CharT, Traits, Alloc2>& str, size_type pos = 0) const {
        return find_first_of(str._str, pos, str._length);
    }

    size_type find_first_of (const CharT* s, size_type pos, size_type count) const {
        if (count == 0) return npos;
        const CharT* end = _str + _length;
        for (const CharT* ptr = _str + pos; ptr < end; ++ptr) if (traits_type::find(s, count, *ptr)) return ptr - _str;
        return npos;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    size_type find_first_of (const _CharT* const& s, size_type pos = 0) const {
        return find_first_of(s, pos, traits_type::length(s));
    }

    template <size_type SIZE>
    size_type find_first_of (const CharT (&s)[SIZE], size_type pos = 0) const {
        return find_first_of(s, pos, SIZE-1);
    }

    size_type find_first_of (CharT ch, size_type pos = 0) const {
        return find(ch, pos);
    }

    size_type find_first_of (basic_string_view<CharT, Traits> sv, size_type pos = 0) const {
        return find_first_of(sv.data(), pos, sv.length());
    }

    template <class Alloc2>
    size_type find_first_not_of (const basic_string<CharT, Traits, Alloc2>& str, size_type pos = 0) const {
        return find_first_not_of(str._str, pos, str._length);
    }

    size_type find_first_not_of (const CharT* s, size_type pos, size_type count) const {
        if (count == 0) return pos >= _length ? npos : pos;
        const CharT* end = _str + _length;
        for (const CharT* ptr = _str + pos; ptr < end; ++ptr) if (!traits_type::find(s, count, *ptr)) return ptr - _str;
        return npos;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    size_type find_first_not_of (const _CharT* const& s, size_type pos = 0) const {
        return find_first_not_of(s, pos, traits_type::length(s));
    }

    template <size_type SIZE>
    size_type find_first_not_of (const CharT (&s)[SIZE], size_type pos = 0) const {
        return find_first_not_of(s, pos, SIZE-1);
    }

    size_type find_first_not_of (CharT ch, size_type pos = 0) const {
        const CharT* end = _str + _length;
        for (const CharT* ptr = _str + pos; ptr < end; ++ptr) if (!traits_type::eq(*ptr, ch)) return ptr - _str;
        return npos;
    }

    size_type find_first_not_of (basic_string_view<CharT, Traits> sv, size_type pos = 0) const {
        return find_first_not_of(sv.data(), pos, sv.length());
    }

    template <class Alloc2>
    size_type find_last_of (const basic_string<CharT, Traits, Alloc2>& str, size_type pos = npos) const {
        return find_last_of(str._str, pos, str._length);
    }

    size_type find_last_of (const CharT* s, size_type pos, size_type count) const {
        if (count == 0) return npos;
        for (const CharT* ptr = _str + (pos >= _length ? (_length - 1) : pos); ptr >= _str; --ptr)
            if (traits_type::find(s, count, *ptr)) return ptr - _str;
        return npos;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    size_type find_last_of (const _CharT* const& s, size_type pos = npos) const {
        return find_last_of(s, pos, traits_type::length(s));
    }

    template <size_type SIZE>
    size_type find_last_of (const CharT (&s)[SIZE], size_type pos = npos) const {
        return find_last_of(s, pos, SIZE-1);
    }

    size_type find_last_of (CharT ch, size_type pos = npos) const {
        return rfind(ch, pos);
    }

    size_type find_last_of (basic_string_view<CharT, Traits> sv, size_type pos = npos) const {
        return find_last_of(sv.data(), pos, sv.length());
    }

    template <class Alloc2>
    size_type find_last_not_of (const basic_string<CharT, Traits, Alloc2>& str, size_type pos = npos) const {
        return find_last_not_of(str._str, pos, str._length);
    }

    size_type find_last_not_of (const CharT* s, size_type pos, size_type count) const {
        if (count == 0) return pos >= _length ? (_length-1) : pos;
        for (const CharT* ptr = _str + (pos >= _length ? (_length - 1) : pos); ptr >= _str; --ptr)
            if (!traits_type::find(s, count, *ptr)) return ptr - _str;
        return npos;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    size_type find_last_not_of (const _CharT* const& s, size_type pos = npos) const {
        return find_last_not_of(s, pos, traits_type::length(s));
    }

    template <size_type SIZE>
    size_type find_last_not_of (const CharT (&s)[SIZE], size_type pos = npos) const {
        return find_last_not_of(s, pos, SIZE-1);
    }

    size_type find_last_not_of (CharT ch, size_type pos = npos) const {
        for (const CharT* ptr = _str + (pos >= _length ? (_length - 1) : pos); ptr >= _str; --ptr)
            if (!traits_type::eq(*ptr, ch)) return ptr - _str;
        return npos;
    }

    size_type find_last_not_of (basic_string_view<CharT, Traits> sv, size_type pos = npos) const {
        return find_last_not_of(sv.data(), pos, sv.length());
    }

    basic_string& append (size_type count, CharT ch) {
        if (count) {
            _reserve_save(_length + count);
            traits_type::assign(_str + _length, count, ch);
            _length += count;
        }
        return *this;
    }

    template <class Alloc2>
    basic_string& append (const basic_string<CharT, Traits, Alloc2>& str) {
        if (!_length && _state != State::INTERNAL) return assign(str); // do not optimize if string had reserved memory
        if (str._length) { // can't call append(const CharT*, size_type) because otherwise if &str == this a fuckup would occur
            _reserve_save(_length + str._length);
            traits_type::copy(_str + _length, str._str, str._length);
            _length += str._length;
        }
        return *this;
    }

    template <class Alloc2>
    basic_string& append (const basic_string<CharT, Traits, Alloc2>& str, size_type pos, size_type count = npos) {
        if (!_length && _state != State::INTERNAL) return assign(str, pos, count); // do not optimize if string had reserved memory
        if (pos > str._length) throw std::out_of_range("basic_string::append");
        if (count > str._length - pos) count = str._length - pos;
        if (count) { // can't call append(const CharT*, size_type) because otherwise if &str == this a fuckup would occur
            _reserve_save(_length + count);
            traits_type::copy(_str + _length, str._str + pos, count);
            _length += count;
        }
        return *this;
    }

    basic_string& append (const CharT* s, size_type count) { // 's' MUST NOT BE any part of this->data()
        if (count) {
            _reserve_save(_length + count);
            traits_type::copy(_str + _length, s, count);
            _length += count;
        }
        return *this;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    basic_string& append (const _CharT* const& s) {
        return append(s, traits_type::length(s));
    }

    template <size_type SIZE>
    basic_string& append (const CharT (&s)[SIZE]) {
        return append(s, SIZE-1);
    }

    basic_string& append (std::initializer_list<CharT> ilist) {
        return append(ilist.begin(), ilist.size());
    }

    basic_string& append (basic_string_view<CharT, Traits> sv) {
        return append(sv.data(), sv.length());
    }

    void push_back (CharT ch) {
        append(1, ch);
    }

    template <size_type SIZE>
    basic_string& operator+= (const CharT (&str)[SIZE])                       { return append(str, SIZE-1); }
    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    basic_string& operator+= (const _CharT* const& str)                       { return append(str); }
    template <class Alloc2>
    basic_string& operator+= (const basic_string<CharT, Traits, Alloc2>& str) { return append(str); }
    basic_string& operator+= (CharT ch)                                       { return append(1, ch); }
    basic_string& operator+= (std::initializer_list<CharT> ilist)             { return append(ilist); }
    basic_string& operator+= (basic_string_view<CharT, Traits> sv)            { return append(sv); }

    basic_string& insert (size_type pos, const basic_string& str) {
        if (this == &str) {
            const basic_string tmp(str);
            return insert(pos, tmp._str, tmp._length);
        }
        else return insert(pos, str._str, str._length);
    }

    template <class Alloc2>
    basic_string& insert (size_type pos, const basic_string<CharT, Traits, Alloc2>& str) {
        return insert(pos, str._str, str._length);
    }

    basic_string& insert (size_type pos, const basic_string& str, size_type subpos, size_type sublen = npos) {
        if (subpos > str._length) throw std::out_of_range("basic_string::insert");
        if (sublen > str._length - subpos) sublen = str._length - subpos;
        if (this == &str) {
            const basic_string tmp(str);
            return insert(pos, tmp._str + subpos, sublen);
        }
        else return insert(pos, str._str + subpos, sublen);
    }

    template <class Alloc2>
    basic_string& insert (size_type pos, const basic_string<CharT, Traits, Alloc2>& str, size_type subpos, size_type sublen = npos) {
        if (subpos > str._length) throw std::out_of_range("basic_string::insert");
        if (sublen > str._length - subpos) sublen = str._length - subpos;
        return insert(pos, str._str + subpos, sublen);
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    basic_string& insert (size_type pos, const _CharT* const& s) {
        return insert(pos, s, traits_type::length(s));
    }

    template <size_type SIZE>
    basic_string& insert (size_type pos, const CharT (&s)[SIZE]) {
        return insert(pos, s, SIZE-1);
    }

    basic_string& insert (size_type pos, const CharT* s, size_type count) {
        if (pos >= _length) {
            if (pos == _length) return append(s, count);
            throw std::out_of_range("basic_string::insert");
        }
        if (count == 0) return *this;
        _reserve_middle(pos, 0, count);
        traits_type::copy(_str + pos, s, count);
        return *this;
    }

    basic_string& insert (size_type pos, size_type count, CharT ch) {
        if (pos >= _length) {
            if (pos == _length) return append(count, ch);
            throw std::out_of_range("basic_string::insert");
        }
        if (count == 0) return *this;
        _reserve_middle(pos, 0, count);
        traits_type::assign(_str + pos, count, ch);
        return *this;
    }

    iterator insert (const_iterator it, size_type count, CharT ch) {
        size_type pos = it - cbegin();
        insert(pos, count, ch);
        return iterator{*this, pos};
    }

    iterator insert (const_iterator it, CharT ch) {
        size_type pos = it - cbegin();
        insert(pos, 1, ch);
        return iterator{*this, pos};
    }

    basic_string& insert (const_iterator it, std::initializer_list<CharT> ilist) {
        return insert(it - cbegin(), ilist.begin(), ilist.size());
    }

    basic_string& insert (size_type pos, basic_string_view<CharT, Traits> sv) {
        return insert(pos, sv.data(), sv.length());
    }

    // fix ambiguity between iterator(char*) and size_t
    basic_string& insert (int pos, size_type count, CharT ch) { return insert((size_type)pos, count, ch); }

    basic_string& replace (size_type pos, size_type remove_count, const basic_string& str) {
        if (this == &str) {
            const basic_string tmp(str);
            return replace(pos, remove_count, tmp._str, tmp._length);
        }
        return replace(pos, remove_count, str._str, str._length);
    }

    template <class Alloc2>
    basic_string& replace (size_type pos, size_type remove_count, const basic_string<CharT, Traits, Alloc2>& str) {
        return replace(pos, remove_count, str._str, str._length);
    }

    template <class Alloc2>
    basic_string& replace (const_iterator first, const_iterator last, const basic_string<CharT, Traits, Alloc2>& str) {
        return replace(first - cbegin(), last - first, str);
    }

    basic_string& replace (size_type pos, size_type remove_count, const basic_string& str, size_type pos2, size_type insert_count = npos) {
        if (pos2 > str._length) throw std::out_of_range("basic_string::replace");
        if (insert_count > str._length - pos2) insert_count = str._length - pos2;
        if (this == &str) {
            const basic_string tmp(str);
            return replace(pos, remove_count, tmp._str + pos2, insert_count);
        }
        return replace(pos, remove_count, str._str + pos2, insert_count);
    }

    template <class Alloc2>
    basic_string& replace (size_type pos, size_type remove_count, const basic_string<CharT, Traits, Alloc2>& str, size_type pos2, size_type insert_count = npos) {
        if (pos2 > str._length) throw std::out_of_range("basic_string::replace");
        if (insert_count > str._length - pos2) insert_count = str._length - pos2;
        return replace(pos, remove_count, str._str + pos2, insert_count);
    }

    basic_string& replace (size_type pos, size_type remove_count, const CharT* s, size_type insert_count) {
        if (pos >= _length) {
            if (pos == _length) return append(s, insert_count);
            throw std::out_of_range("basic_string::replace");
        }
        if (remove_count >= _length - pos) {
            _length = pos;
            return append(s, insert_count);
        }
        if (insert_count == 0) {
            if (remove_count == 0) return *this;
            return erase(pos, remove_count);
        }
        _reserve_middle(pos, remove_count, insert_count);
        traits_type::copy(_str + pos, s, insert_count);
        return *this;
    }

    basic_string& replace (const_iterator first, const_iterator last, const CharT* s, size_type insert_count) {
        return replace(first - cbegin(), last - first, s, insert_count);
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    basic_string& replace (size_type pos, size_type remove_count, const _CharT* const& s) {
        return replace(pos, remove_count, s, traits_type::length(s));
    }

    template <size_type SIZE>
    basic_string& replace (size_type pos, size_type remove_count, const CharT (&s)[SIZE]) {
        return replace(pos, remove_count, s, SIZE-1);
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    basic_string& replace (const_iterator first, const_iterator last, const _CharT* const& s) {
        return replace(first, last, s, traits_type::length(s));
    }

    template <size_type SIZE>
    basic_string& replace (const_iterator first, const_iterator last, const CharT (&s)[SIZE]) {
        return replace(first, last, s, SIZE-1);
    }

    basic_string& replace (size_type pos, size_type remove_count, size_type insert_count, CharT ch) {
        if (pos >= _length) {
            if (pos == _length) return append(insert_count, ch);
            throw std::out_of_range("basic_string::replace");
        }
        if (remove_count >= _length - pos) {
            _length = pos;
            return append(insert_count, ch);
        }
        if (insert_count == 0) {
            if (remove_count == 0) return *this;
            return erase(pos, remove_count);
        }
        _reserve_middle(pos, remove_count, insert_count);
        traits_type::assign(_str + pos, insert_count, ch);
        return *this;
    }

    basic_string& replace (const_iterator first, const_iterator last, size_type insert_count, CharT ch) {
        return replace(first - cbegin(), last - first, insert_count, ch);
    }

    basic_string& replace (const_iterator first, const_iterator last, std::initializer_list<CharT> ilist) {
        return replace(first, last, ilist.begin(), ilist.size());
    }

    basic_string& replace (size_type pos, size_type remove_count, basic_string_view<CharT, Traits> sv) {
        return replace(pos, remove_count, sv.data(), sv.length());
    }

    basic_string& replace (const_iterator first, const_iterator last, basic_string_view<CharT, Traits> sv) {
        return replace(first - cbegin(), last - first, sv);
    }

    template <typename V>
    from_chars_result to_number (V& value, int base = 10) const { return from_chars(_str, _str + _length, value, base); }

    template <typename V>
    from_chars_result to_number (V& value, size_type pos, size_type count = npos, int base = 10) const {
        if (pos > _length) throw std::out_of_range("basic_string::to_number");
        if (count > _length - pos) count = _length - pos;
        return from_chars(_str + pos, _str + pos + count, value, base);
    }

    template <typename V>
    static basic_string from_number (V value, int base = 10) {
        auto maxsz = to_chars_maxsize<V>(base);
        basic_string ret(maxsz);
        auto res = to_chars(ret._str, ret._str + maxsz, value, base);
        assert(!res.ec);
        ret.length(res.ptr - ret.data());
        return ret;
    }

    const CharT* c_str () const {
        if (_state == State::LITERAL) return _str; // LITERALs are NT
        if (shared_capacity() > _length && _str[_length] == 0) return _str; // if we have r/o space after string, let's see if it's already NT
        // string is not NT
        if (capacity() <= _length) const_cast<basic_string*>(this)->_reserve_save(_length + 1); // we're in COW mode or don't have space
        _str[_length] = 0;
        return _str;
    }

    ~basic_string () { _release(); }

private:

    constexpr size_type _capacity_internal () const { return _buf->capacity - (_str - _buf->start); }
    constexpr size_type _capacity_external () const { return _buf->capacity - (_str - _ebuf->ptr); }
    constexpr size_type _capacity_sso      () const { return MAX_SSO_CHARS - (_str - _sso_start); }

    void _new_auto (size_type capacity) {
        if (capacity <= MAX_SSO_CHARS) {
            _state = State::SSO;
            _str   = _sso_start;
        } else {
            if (capacity > MAX_SIZE) throw std::length_error("basic_string::_new_auto");
            _state = State::INTERNAL;
            _buf           = (Buffer*)Alloc::allocate(capacity + BUF_CHARS);
            _buf->capacity = capacity;
            _buf->refcnt   = 1;
            _str           = _buf->start;
            _dtor          = &Alloc::deallocate;
        }
    }

    // becomes INTERNAL for capacity, and copy _str to buffer in the way so that none of internal SSO members are written before copy is made.
    void _new_internal_from_sso (size_type capacity) {
        auto ibuf = (Buffer*)Alloc::allocate(capacity + BUF_CHARS);
        traits_type::copy(ibuf->start, _str, _length);
        ibuf->capacity = capacity;
        ibuf->refcnt   = 1;
        _state = State::INTERNAL;
        _buf   = ibuf;
        _str   = ibuf->start;
        _dtor  = &Alloc::deallocate;
    }

    void _new_internal_from_sso (size_type capacity, size_type pos, size_type remove_count, size_type insert_count) {
        auto ibuf = (Buffer*)Alloc::allocate(capacity + BUF_CHARS);
        if (pos) traits_type::copy(ibuf->start, _str, pos);
        traits_type::copy((CharT*)ibuf->start + pos + insert_count, _str + pos + remove_count, _length - pos - remove_count);
        ibuf->capacity = capacity;
        ibuf->refcnt   = 1;
        _state = State::INTERNAL;
        _buf   = ibuf;
        _str   = ibuf->start;
        _dtor  = &Alloc::deallocate;
    }

    void _new_external (CharT* str, size_type len, size_type capacity, dtor_fn dtor, ExternalShared* ebuf, dtor_fn ebuf_dtor) {
        _state = State::EXTERNAL;
        _str    = str;
        _length = len;
        _dtor   = dtor;
        _ebuf   = ebuf;
        _ebuf->capacity = capacity;
        _ebuf->refcnt   = 1;
        _ebuf->dtor     = ebuf_dtor;
        _ebuf->ptr      = str;
    }

    // releases currently held external string and reuses current ExternalShared for the new external string
    void _replace_external (CharT* str, size_type len, size_type capacity, dtor_fn dtor) {
        _free_external_str();
        _str    = str;
        _length = len;
        _dtor   = dtor;
        _ebuf->capacity = capacity;
        _ebuf->ptr      = str;
    }

    template <class Alloc2>
    void _cow (const basic_string<CharT, Traits, Alloc2>& oth, size_type offset, size_type length) {
        _length = length;
        switch (oth._state) {
            case State::INTERNAL:
            case State::EXTERNAL:
                _state = oth._state;
                _str   = oth._str + offset;
                _buf   = oth._buf;
                _dtor  = oth._dtor;
                ++_buf->refcnt;
                break;
            case State::LITERAL:
                _state = State::LITERAL;
                _str_literal = oth._str_literal + offset;
                break;
            case State::SSO:
                _buf = oth._buf;
                _dtor = oth._dtor;
                *((void**)_align) = *((void**)oth._align); // also sets _state to SSO
                _str = _sso_start + (oth._str - oth._sso_start) + offset;
                break;
        }
    }

    template <class Alloc2>
    void _cow_offset (const basic_string<CharT, Traits, Alloc2>& oth, size_type offset, size_type length) {
        if (offset > oth._length) throw std::out_of_range("basic_string::assign");
        if (length > oth._length - offset) length = oth._length - offset;
        _cow(oth, offset, length);
    }

    template <class Alloc2>
    void _move_from (basic_string<CharT, Traits, Alloc2>&& oth) {
        _length = oth._length;
        _buf    = oth._buf;
        _dtor   = oth._dtor;
        *((void**)_align) = *((void**)oth._align);
        if (oth._state == State::SSO) _str = _sso_start + (oth._str - oth._sso_start);
        else _str = oth._str;

        oth._state       = State::LITERAL;
        oth._str_literal = &TERMINAL;
        oth._length      = 0;
    }

    // loses content, may change state, after call _str is guaranteed to be writable (detaches from COW and statics)
    void _reserve_drop (size_type capacity) {
        switch (_state) {
            case State::INTERNAL: _reserve_drop_internal(capacity); break;
            case State::EXTERNAL: _reserve_drop_external(capacity); break;
            case State::LITERAL:
            case State::SSO:      _new_auto(capacity);
        }
    }

    void _reserve_drop_internal (size_type capacity) {
        if (_buf->refcnt > 1) {
            --_buf->refcnt;
            _new_auto(capacity);
        }
        else if (_buf->capacity < capacity) { // could realloc save anything?
            _free_internal();
            _new_auto(capacity);
        }
        else _str = _buf->start;
    }

    void _reserve_drop_external (size_type capacity) {
        if (_buf->refcnt > 1) {
            --_buf->refcnt;
            _new_auto(capacity);
        }
        else if (_buf->capacity < capacity) {
            _free_external();
            _new_auto(capacity);
        }
        else _str = _ebuf->ptr;
    }

    void _detach () {
        switch (_state) {
            case State::INTERNAL:
            case State::EXTERNAL:
                if (_buf->refcnt > 1) _detach_cow(_length);
                break;
            case State::LITERAL:
                _detach_str(_length);
                break;
            case State::SSO: break;
        }
    }

    void _detach_cow (size_type capacity) {
        --_buf->refcnt;
        _detach_str(capacity);
    }

    void _detach_str (size_type capacity) {
        assert(capacity >= _length);
        auto old_str = _str;
        _new_auto(capacity);
        traits_type::copy(_str, old_str, _length);
    }

    void _shared_detach () {
        if (_state == State::LITERAL) _detach_str(_length);
    }

    void _reserve_save (size_type capacity) {
        if (capacity < _length) capacity = _length;
        switch (_state) {
            case State::INTERNAL: _reserve_save_internal(capacity); break;
            case State::EXTERNAL: _reserve_save_external(capacity); break;
            case State::LITERAL:  _detach_str(capacity);            break;
            case State::SSO:      _reserve_save_sso(capacity);      break;
        }
    }

    void _reserve_save_internal (size_type capacity) {
        if (_buf->refcnt > 1) _detach_cow(capacity);
        else if (_buf->capacity < capacity) _internal_realloc(capacity); // need to grow storage
        else if (_capacity_internal() < capacity) { // may not to grow storage if str is moved to the beginning
            traits_type::move(_buf->start, _str, _length);
            _str = _buf->start;
        }
    }

    void _internal_realloc (size_type capacity) {
        // see if we can reallocate. if _str != _buf->start we should not reallocate because we would need
        // either allocate more space than needed or move everything to the beginning before reallocation
        if (_dtor == &Alloc::deallocate && _str == _buf->start) {
            if (capacity > MAX_SIZE) throw std::length_error("basic_string::_internal_realloc");
            _buf = (Buffer*)Alloc::reallocate((CharT*)_buf, capacity + BUF_CHARS, _buf->capacity + BUF_CHARS);
            _str = _buf->start;
            _buf->capacity = capacity;
        } else { // need to allocate/deallocate
            auto old_buf  = _buf;
            auto old_str  = _str;
            auto old_dtor = _dtor;
            _new_auto(capacity);
            traits_type::copy(_str, old_str, _length);
            _free_internal(old_buf, old_dtor);
        }
    }

    void _reserve_save_external (size_type capacity) {
        if (_buf->refcnt > 1) _detach_cow(capacity);
        else if (_buf->capacity < capacity) _external_realloc(capacity); // need to grow storage, switch to INTERNAL/SSO
        else if (_capacity_external() < capacity) { // may not to grow storage if str is moved to the beginning
            traits_type::move(_ebuf->ptr, _str, _length);
            _str = _ebuf->ptr;
        }
    }

    void _external_realloc (size_type capacity) {
        auto old_buf  = _ebuf;
        auto old_str  = _str;
        auto old_dtor = _dtor;
        _new_auto(capacity);
        traits_type::copy(_str, old_str, _length);
        _free_external(old_buf, old_dtor);
    }

    void _reserve_save_sso (size_type capacity) {
        if (MAX_SSO_CHARS < capacity) {
            _new_internal_from_sso(capacity);
            return;
        }
        else if (_capacity_sso() < capacity) {
            traits_type::move(_sso_start, _str, _length);
            _str = _sso_start;
        }
    }

    // splits string into pwo pieces at position 'pos' with insert_count distance between them replacing remove_count chars after pos.
    // Tries its best not to allocate memory. set the length of string to old length + insert_count - remove_count.
    // The content of part [pos, pos+insert_count) is undefined after operation
    void _reserve_middle (size_type pos, size_type remove_count, size_type insert_count) {
        size_type newlen = _length + insert_count - remove_count;

        switch (_state) {
            case State::INTERNAL:
                if (_buf->refcnt > 1) {
                    --_buf->refcnt;
                    _reserve_middle_new(pos, remove_count, insert_count);
                }
                else if (newlen > _buf->capacity) {
                    auto old_buf  = _buf;
                    auto old_dtor = _dtor;
                    _reserve_middle_new(pos, remove_count, insert_count);
                    _release_internal(old_buf, old_dtor);
                }
                else _reserve_middle_move(pos, remove_count, insert_count, _buf->start, _capacity_internal());
                break;
            case State::EXTERNAL:
                if (_buf->refcnt > 1) {
                    --_buf->refcnt;
                    _reserve_middle_new(pos, remove_count, insert_count);
                }
                else if (newlen > _buf->capacity) {
                    auto old_buf  = _ebuf;
                    auto old_dtor = _dtor;
                    _reserve_middle_new(pos, remove_count, insert_count);
                    _release_external(old_buf, old_dtor);
                }
                else _reserve_middle_move(pos, remove_count, insert_count, _ebuf->ptr, _capacity_external());
                break;
            case State::LITERAL:
                _reserve_middle_new(pos, remove_count, insert_count);
                break;
            case State::SSO:
                if (newlen > MAX_SSO_CHARS) _new_internal_from_sso(newlen, pos, remove_count, insert_count);
                else _reserve_middle_move(pos, remove_count, insert_count, _sso_start, _capacity_sso());
                break;
        }

        _length = newlen;
    }

    void _reserve_middle_new (size_type pos, size_type remove_count, size_type insert_count) {
        auto old_str = _str;
        _new_auto(_length + insert_count - remove_count);
        if (pos) traits_type::copy(_str, old_str, pos);
        traits_type::copy(_str + pos + insert_count, old_str + pos + remove_count, _length - pos - remove_count);
    }

    void _reserve_middle_move (size_type pos, size_type remove_count, size_type insert_count, CharT* ptr_start, size_type capacity_tail) {
        if (remove_count >= insert_count) {
            traits_type::move(_str + pos + insert_count, _str + pos + remove_count, _length - pos - remove_count);
            return;
        }

        auto extra_count = insert_count - remove_count;
        bool has_head_space = _str >= ptr_start + extra_count;
        bool has_tail_space = (capacity_tail - _length) >= extra_count;
        if (has_head_space && has_tail_space) { // move what is shorter
            if (pos > _length - pos - remove_count) { // tail is shorter
                traits_type::move(_str + pos + insert_count, _str + pos + remove_count, _length - pos - remove_count);
            } else { // head is shorter
                if (pos) traits_type::move(_str - extra_count, _str, pos);
                _str -= extra_count;
            }
        }
        else if (has_head_space) {
            if (pos) traits_type::move(_str - extra_count, _str, pos);
            _str -= extra_count;
        }
        else if (has_tail_space) {
            traits_type::move(_str + pos + insert_count, _str + pos + remove_count, _length - pos - remove_count);
        }
        else {
            if (pos) traits_type::move(ptr_start, _str, pos);
            traits_type::move(ptr_start + pos + insert_count, _str + pos + remove_count, _length - pos - remove_count);
            _str = ptr_start;
        }
    }

    // leaves object in invalid state
    void _release () {
        switch (_state) {
            case State::INTERNAL: _release_internal(); break;
            case State::EXTERNAL: _release_external(); break;
            case State::LITERAL:
            case State::SSO: break;
        }
    }

    void _release_internal () { _release_internal(_buf, _dtor); }
    void _release_external () { _release_external(_ebuf, _dtor); }

    void _free_internal     () { _free_internal(_buf, _dtor); }
    void _free_external     () { _free_external_str(); _free_external_buf(); }
    void _free_external_str () { _free_external_str(_ebuf, _dtor); }
    void _free_external_buf () { _free_external_buf(_ebuf); }

    static void _release_internal (Buffer* buf, dtor_fn dtor)          { if (!--buf->refcnt) _free_internal(buf, dtor); }
    static void _release_external (ExternalShared* ebuf, dtor_fn dtor) { if (!--ebuf->refcnt) _free_external(ebuf, dtor); }

    static void _free_internal     (Buffer* buf, dtor_fn dtor)          { dtor((CharT*)buf, buf->capacity + BUF_CHARS); }
    static void _free_external     (ExternalShared* ebuf, dtor_fn dtor) { _free_external_str(ebuf, dtor); _free_external_buf(ebuf); }
    static void _free_external_str (ExternalShared* ebuf, dtor_fn dtor) { dtor(ebuf->ptr, ebuf->capacity); }
    static void _free_external_buf (ExternalShared* ebuf)               { ebuf->dtor((CharT*)ebuf, EBUF_CHARS); }

    static int _compare (const CharT* ptr1, size_type len1, const CharT* ptr2, size_type len2) {
        int r = traits_type::compare(ptr1, ptr2, std::min(len1, len2));
        if (!r) r = (len1 < len2) ? -1 : (len1 > len2 ? 1 : 0);
        return r;
    }

};

template <class C, class T, class A>
const C basic_string<C,T,A>::TERMINAL = C();

template <class C, class T, class A1, class A2> inline bool operator== (const basic_string<C,T,A1>& lhs, const basic_string<C,T,A2>& rhs) { return lhs.compare(rhs) == 0; }
template <class C, class T, class A>            inline bool operator== (const C* lhs, const basic_string<C,T,A>& rhs)                     { return rhs.compare(lhs) == 0; }
template <class C, class T, class A>            inline bool operator== (const basic_string<C,T,A>& lhs, const C* rhs)                     { return lhs.compare(rhs) == 0; }
template <class C, class T, class A>            inline bool operator== (basic_string_view<C,T> lhs, const basic_string<C,T,A>& rhs)       { return rhs.compare(lhs) == 0; }
template <class C, class T, class A>            inline bool operator== (const basic_string<C,T,A>& lhs, basic_string_view<C,T> rhs)       { return lhs.compare(rhs) == 0; }

template <class C, class T, class A1, class A2> inline bool operator!= (const basic_string<C,T,A1>& lhs, const basic_string<C,T,A2>& rhs) { return lhs.compare(rhs) != 0; }
template <class C, class T, class A>            inline bool operator!= (const C* lhs, const basic_string<C,T,A>& rhs)                     { return rhs.compare(lhs) != 0; }
template <class C, class T, class A>            inline bool operator!= (const basic_string<C,T,A>& lhs, const C* rhs)                     { return lhs.compare(rhs) != 0; }
template <class C, class T, class A>            inline bool operator!= (basic_string_view<C,T> lhs, const basic_string<C,T,A>& rhs)       { return rhs.compare(lhs) != 0; }
template <class C, class T, class A>            inline bool operator!= (const basic_string<C,T,A>& lhs, basic_string_view<C,T> rhs)       { return lhs.compare(rhs) != 0; }

template <class C, class T, class A1, class A2> inline bool operator<  (const basic_string<C,T,A1>& lhs, const basic_string<C,T,A2>& rhs) { return lhs.compare(rhs) < 0; }
template <class C, class T, class A>            inline bool operator<  (const C* lhs, const basic_string<C,T,A>& rhs)                     { return rhs.compare(lhs) > 0; }
template <class C, class T, class A>            inline bool operator<  (const basic_string<C,T,A>& lhs, const C* rhs)                     { return lhs.compare(rhs) < 0; }
template <class C, class T, class A>            inline bool operator<  (basic_string_view<C,T> lhs, const basic_string<C,T,A>& rhs)       { return rhs.compare(lhs) > 0; }
template <class C, class T, class A>            inline bool operator<  (const basic_string<C,T,A>& lhs, basic_string_view<C,T> rhs)       { return lhs.compare(rhs) < 0; }

template <class C, class T, class A1, class A2> inline bool operator<= (const basic_string<C,T,A1>& lhs, const basic_string<C,T,A2>& rhs) { return lhs.compare(rhs) <= 0; }
template <class C, class T, class A>            inline bool operator<= (const C* lhs, const basic_string<C,T,A>& rhs)                     { return rhs.compare(lhs) >= 0; }
template <class C, class T, class A>            inline bool operator<= (const basic_string<C,T,A>& lhs, const C* rhs)                     { return lhs.compare(rhs) <= 0; }
template <class C, class T, class A>            inline bool operator<= (basic_string_view<C,T> lhs, const basic_string<C,T,A>& rhs)       { return rhs.compare(lhs) >= 0; }
template <class C, class T, class A>            inline bool operator<= (const basic_string<C,T,A>& lhs, basic_string_view<C,T> rhs)       { return lhs.compare(rhs) <= 0; }

template <class C, class T, class A1, class A2> inline bool operator>  (const basic_string<C,T,A1>& lhs, const basic_string<C,T,A2>& rhs) { return lhs.compare(rhs) > 0; }
template <class C, class T, class A>            inline bool operator>  (const C* lhs, const basic_string<C,T,A>& rhs)                     { return rhs.compare(lhs) < 0; }
template <class C, class T, class A>            inline bool operator>  (const basic_string<C,T,A>& lhs, const C* rhs)                     { return lhs.compare(rhs) > 0; }
template <class C, class T, class A>            inline bool operator>  (basic_string_view<C,T> lhs, const basic_string<C,T,A>& rhs)       { return rhs.compare(lhs) < 0; }
template <class C, class T, class A>            inline bool operator>  (const basic_string<C,T,A>& lhs, basic_string_view<C,T> rhs)       { return lhs.compare(rhs) > 0; }

template <class C, class T, class A1, class A2> inline bool operator>= (const basic_string<C,T,A1>& lhs, const basic_string<C,T,A2>& rhs) { return lhs.compare(rhs) >= 0; }
template <class C, class T, class A>            inline bool operator>= (const C* lhs, const basic_string<C,T,A>& rhs)                     { return rhs.compare(lhs) <= 0; }
template <class C, class T, class A>            inline bool operator>= (const basic_string<C,T,A>& lhs, const C* rhs)                     { return lhs.compare(rhs) >= 0; }
template <class C, class T, class A>            inline bool operator>= (basic_string_view<C,T> lhs, const basic_string<C,T,A>& rhs)       { return rhs.compare(lhs) <= 0; }
template <class C, class T, class A>            inline bool operator>= (const basic_string<C,T,A>& lhs, basic_string_view<C,T> rhs)       { return lhs.compare(rhs) >= 0; }

namespace {
    template <class C, class T, class A>
    inline basic_string<C,T,A> _operator_plus (const C* lhs, size_t llen, const C* rhs, size_t rlen) {
        basic_string<C,T,A> ret(llen + rlen);
        auto buf = const_cast<C*>(ret.data()); // avoid checks for detach
        T::copy(buf, lhs, llen);
        T::copy(buf + llen, rhs, rlen);
        ret.length(llen + rlen);
        return ret;
    }
}

template <class C, class T, class A1, class A2>
inline basic_string<C,T,A1> operator+ (const basic_string<C,T,A1>& lhs, const basic_string<C,T,A2>& rhs) {
    if (lhs.length() == 0) return rhs;
    if (rhs.length() == 0) return lhs;
    return _operator_plus<C,T,A1>(lhs.data(), lhs.length(), rhs.data(), rhs.length());
}

template <class C, class T, class A>
inline basic_string<C,T,A> operator+ (const C* lhs, const basic_string<C,T,A>& rhs) {
    size_t llen = T::length(lhs);
    if (llen == 0) return rhs;
    if (rhs.length() == 0) return basic_string<C,T,A>(lhs, llen);
    return _operator_plus<C,T,A>(lhs, llen, rhs.data(), rhs.length());
}

template <class C, class T, class A>
inline basic_string<C,T,A> operator+ (basic_string_view<C,T> lhs, const basic_string<C,T,A>& rhs) {
    if (lhs.length() == 0) return rhs;
    if (rhs.length() == 0) return basic_string<C,T,A>(lhs);
    return _operator_plus<C,T,A>(lhs.data(), lhs.length(), rhs.data(), rhs.length());
}

template <class C, class T, class A>
inline basic_string<C,T,A> operator+ (C lhs, const basic_string<C,T,A>& rhs) {
    if (rhs.length() == 0) return basic_string<C,T,A>(1, lhs);
    return _operator_plus<C,T,A>(&lhs, 1, rhs.data(), rhs.length());
}

template <class C, class T, class A>
inline basic_string<C,T,A> operator+ (const basic_string<C,T,A>& lhs, const C* rhs) {
    size_t rlen = T::length(rhs);
    if (rlen == 0) return lhs;
    if (lhs.length() == 0) return basic_string<C,T,A>(rhs, rlen);
    return _operator_plus<C,T,A>(lhs.data(), lhs.length(), rhs, rlen);
}

template <class C, class T, class A>
inline basic_string<C,T,A> operator+ (const basic_string<C,T,A>& lhs, basic_string_view<C,T> rhs) {
    if (rhs.length() == 0) return lhs;
    if (lhs.length() == 0) return basic_string<C,T,A>(rhs);
    return _operator_plus<C,T,A>(lhs.data(), lhs.length(), rhs.data(), rhs.length());
}

template <class C, class T, class A>
inline basic_string<C,T,A> operator+ (const basic_string<C,T,A>& lhs, C rhs) {
    if (lhs.length() == 0) return basic_string<C,T,A>(1, rhs);
    return _operator_plus<C,T,A>(lhs.data(), lhs.length(), &rhs, 1);
}

template <class C, class T, class A1, class A2>
inline basic_string<C,T,A1> operator+ (basic_string<C,T,A1>&& lhs, const basic_string<C,T,A2>& rhs) {
    return std::move(lhs.append(rhs));
}

template <class C, class T, class A1, class A2>
inline basic_string<C,T,A1> operator+ (const basic_string<C,T,A1>& lhs, basic_string<C,T,A2>&& rhs) {
    return std::move(rhs.insert(0, lhs));
}

template <class C, class T, class A1, class A2>
inline basic_string<C,T,A1> operator+ (basic_string<C,T,A1>&& lhs, basic_string<C,T,A2>&& rhs) {
    return std::move(lhs.append(std::move(rhs))); // NOTE: there is cases when inserting into second is faster. But we'll need some heuristics to determine that
}

template <class C, class T, class A>
inline basic_string<C,T,A> operator+ (const C* lhs, basic_string<C,T,A>&& rhs) {
    return std::move(rhs.insert(0, lhs));
}

template <class C, class T, class A>
inline basic_string<C,T,A> operator+ (basic_string_view<C,T> lhs, basic_string<C,T,A>&& rhs) {
    return std::move(rhs.insert(0, lhs));
}

template <class C, class T, class A>
inline basic_string<C,T,A> operator+ (C lhs, basic_string<C,T,A>&& rhs) {
    return std::move(rhs.insert(0, 1, lhs));
}

template <class C, class T, class A>
inline basic_string<C,T,A> operator+ (basic_string<C,T,A>&& lhs, const C* rhs) {
    return std::move(lhs.append(rhs));
}

template <class C, class T, class A>
inline basic_string<C,T,A> operator+ (basic_string<C,T,A>&& lhs, basic_string_view<C,T> rhs) {
    return std::move(lhs.append(rhs));
}

template <class C, class T, class A>
inline basic_string<C,T,A> operator+ (basic_string<C,T,A>&& lhs, C rhs) {
    return std::move(lhs.append(1, rhs));
}

template <class C, class T, class A>
inline std::basic_ostream<C,T>& operator<< (std::basic_ostream<C,T>& os, const basic_string<C,T,A>& str) {
    return os.write(str.data(), str.length());
}

template <class C, class T, class A>
inline void swap (basic_string<C,T,A>& lhs, basic_string<C,T,A>& rhs) {
    lhs.swap(rhs);
}

}

namespace std {
    template<class C, class T, class A>
    struct hash<panda::basic_string<C,T,A>> {
        size_t operator() (const panda::basic_string<C,T,A>& s) const {
            return panda::hash::hashXX<size_t>((const char*)s.data(), s.length() * sizeof(C));
        }
    };

    template<class C, class T, class A>
    struct hash<const panda::basic_string<C,T,A>> {
        size_t operator() (const panda::basic_string<C,T,A>& s) const {
            return panda::hash::hashXX<size_t>((const char*)s.data(), s.length() * sizeof(C));
        }
    };
}
