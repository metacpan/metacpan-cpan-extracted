#pragma once
#include <string>
#include <iosfwd>
#include <limits>
#include <utility>   // swap
#include <stdexcept>

namespace std {

template <class CharT, class Traits = std::char_traits<CharT>>
class basic_string_view {
public:
    typedef Traits                                traits_type;
    typedef typename Traits::char_type            value_type;
    typedef value_type&                           reference;
    typedef const value_type&                     const_reference;
    typedef CharT*                                pointer;
    typedef const CharT*                          const_pointer;
    typedef CharT*                                iterator;
    typedef const CharT*                          const_iterator;
    typedef std::reverse_iterator<iterator>       reverse_iterator;
    typedef std::reverse_iterator<const_iterator> const_reverse_iterator;
    typedef ptrdiff_t                             difference_type;
    typedef size_t                                size_type;

    static const size_t npos = std::numeric_limits<size_t>::max();

private:
    const CharT* _str;
    size_t    _length;

    static const CharT TERMINAL;

public:

    constexpr basic_string_view () : _str(&TERMINAL), _length(0) {}

    constexpr basic_string_view (const basic_string_view& other) = default;

    constexpr basic_string_view (const CharT* s, size_t count) : _str(s), _length(count) {}

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    constexpr basic_string_view (const _CharT* const& s) : _str(s), _length(traits_type::length(s)) {}

    template <size_t SIZE>
    constexpr basic_string_view (const CharT (&s)[SIZE]) : _str(s), _length(SIZE-1) {}

    basic_string_view& operator= (const basic_string_view& view) = default;

    constexpr const_iterator         begin   () const { return _str; }
    constexpr const_iterator         cbegin  () const { return begin(); }
    constexpr const_iterator         end     () const { return _str + _length; }
    constexpr const_iterator         cend    () const { return end(); }
    constexpr const_reverse_iterator rbegin  () const { return const_reverse_iterator(end()); }
    constexpr const_reverse_iterator crbegin () const { return rbegin(); }
    constexpr const_reverse_iterator rend    () const { return const_reverse_iterator(begin()); }
    constexpr const_reverse_iterator crend   () const { return rend(); }

    constexpr const_reference operator[] (size_t pos) const { return _str[pos]; }

    const_reference at (size_t pos) const {
        if (pos >= _length) throw std::out_of_range("basic_string_view::at");
        return _str[pos];
    }

    constexpr const_reference front    () const { return *_str; }
    constexpr const_reference back     () const { return _str[_length-1]; }
    constexpr const_pointer   data     () const { return _str; }
    constexpr size_t          size     () const { return _length; }
    constexpr size_t          length   () const { return _length; }
    constexpr size_t          max_size () const { return npos - 1; }
    constexpr bool            empty    () const { return _length == 0; }

    void remove_prefix (size_t n) {
        _str += n;
        _length -= n;
    }

    void remove_suffix (size_t n) {
        _length -= n;
    }

    void swap (basic_string_view& v) {
        std::swap(_str, v._str);
        std::swap(_length, v._length);
    }

    size_t copy (CharT* dest, size_t count, size_t pos = 0) const {
        if (pos > _length) throw std::out_of_range("basic_string_view::copy");
        if (count > _length - pos) count = _length - pos;
        traits_type::copy(dest, _str, count);
        return count;
    }

    basic_string_view substr (size_t pos = 0, size_t count = npos) const {
        if (pos > _length) throw std::out_of_range("basic_string_view::substr");
        if (count > _length - pos) count = _length - pos;
        return basic_string_view(_str + pos, count);
    }


    int compare (basic_string_view v) const {
        return _compare(_str, _length, v._str, v._length);
    }

    int compare (size_t pos1, size_t count1, basic_string_view v) const {
        return _compare(pos1, count1, v._str, v._length);
    }

    int compare (size_t pos1, size_t count1, basic_string_view v, size_t pos2, size_t count2) const {
        if (pos2 > v._length) throw std::out_of_range("basic_string_view::compare");
        if (count2 > v._length - pos2) count2 = v._length - pos2;
        return _compare(pos1, count1, v._str + pos2, count2);
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    int compare (const CharT* const& s) const {
        return _compare(_str, _length, s, traits_type::length(s));
    }

    template <size_t SIZE>
    int compare (const CharT (&s)[SIZE]) const {
        return _compare(_str, _length, s, SIZE-1);
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    int compare (size_t pos1, size_t count1, const CharT* const& s) const {
        return compare(pos1, count1, s, traits_type::length(s));
    }

    template <size_t SIZE>
    int compare (size_t pos1, size_t count1, const CharT (&s)[SIZE]) const {
        return compare(pos1, count1, s, SIZE-1);
    }

    int compare (size_t pos1, size_t count1, const CharT* s, size_t count2) const {
        if (pos1 > _length) throw std::out_of_range("basic_string_view::compare");
        if (count1 > _length - pos1) count1 = _length - pos1;
        return _compare(_str + pos1, count1, s, count2);
    }


    size_t find (basic_string_view v, size_t pos = 0) const {
        return find(v._str, pos, v._length);
    }

    size_t find (CharT ch, size_t pos = 0) const {
        if (pos >= _length) return npos;
        const CharT* ptr = traits_type::find(_str + pos, _length - pos, ch);
        if (ptr) return ptr - _str;
        return npos;
    }

    size_t find (const CharT* s, size_t pos, size_t count) const {
        if (pos > _length) return npos;
        if (count == 0) return pos;

        const CharT* ptr = traits_type::find(_str + pos, _length - pos, *s);
        const CharT* end = _str + _length;
        while (ptr && end - ptr >= count) {
            if (traits_type::compare(ptr, s, count) == 0) return ptr - _str;
            ptr = traits_type::find(ptr+1, end - ptr - 1, *s);
        }

        return npos;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    size_t find (const _CharT* const& s, size_t pos = 0) const {
        return find(s, pos, traits_type::length(s));
    }

    template <size_t SIZE>
    size_t find (const CharT (&s)[SIZE], size_t pos = 0) const {
        return find(s, pos, SIZE-1);
    }


    size_t rfind (basic_string_view v, size_t pos = npos) const {
        return rfind(v._str, pos, v._length);
    }

    size_t rfind (CharT ch, size_t pos = npos) const {
        const CharT* ptr = _str + (pos >= _length ? _length : (pos+1));
        while (--ptr >= _str) if (traits_type::eq(*ptr, ch)) return ptr - _str;
        return npos;
    }

    size_t rfind (const CharT* s, size_t pos, size_t count) const {
        for (const CharT* ptr = _str + ((pos >= _length - count) ? (_length - count) : pos); ptr >= _str; --ptr)
            if (traits_type::compare(ptr, s, count) == 0) return ptr - _str;
        return npos;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    size_t rfind (const _CharT* const& s, size_t pos = 0) const {
        return rfind(s, pos, traits_type::length(s));
    }

    template <size_t SIZE>
    size_t rfind (const CharT (&s)[SIZE], size_t pos = 0) const {
        return rfind(s, pos, SIZE-1);
    }


    size_t find_first_of (basic_string_view v, size_t pos = 0) const {
        return find_first_of(v._str, pos, v._length);
    }

    size_t find_first_of (CharT ch, size_t pos = 0) const {
        return find(ch, pos);
    }

    size_t find_first_of (const CharT* s, size_t pos, size_t count) const {
        if (count == 0) return npos;
        const CharT* end = _str + _length;
        for (const CharT* ptr = _str + pos; ptr < end; ++ptr) if (traits_type::find(s, count, *ptr)) return ptr - _str;
        return npos;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    size_t find_first_of (const _CharT* const& s, size_t pos = 0) const {
        return find_first_of(s, pos, traits_type::length(s));
    }

    template <size_t SIZE>
    size_t find_first_of (const CharT (&s)[SIZE], size_t pos = 0) const {
        return find_first_of(s, pos, SIZE-1);
    }


    size_t find_last_of (basic_string_view v, size_t pos = 0) const {
        return find_last_of(v._str, pos, v._length);
    }

    size_t find_last_of (CharT ch, size_t pos = 0) const {
        return rfind(ch, pos);
    }

    size_t find_last_of (const CharT* s, size_t pos, size_t count) const {
        if (count == 0) return npos;
        for (const CharT* ptr = _str + (pos >= _length ? (_length - 1) : pos); ptr >= _str; --ptr)
            if (traits_type::find(s, count, *ptr)) return ptr - _str;
        return npos;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    size_t find_last_of (const _CharT* const& s, size_t pos = 0) const {
        return find_last_of(s, pos, traits_type::length(s));
    }

    template <size_t SIZE>
    size_t find_last_of (const CharT (&s)[SIZE], size_t pos = 0) const {
        return find_last_of(s, pos, SIZE-1);
    }


    size_t find_first_not_of (basic_string_view v, size_t pos = 0) const {
        return find_first_not_of(v._str, pos, v._length);
    }

    size_t find_first_not_of (CharT ch, size_t pos = 0) const {
        const CharT* end = _str + _length;
        for (const CharT* ptr = _str + pos; ptr < end; ++ptr) if (!traits_type::eq(*ptr, ch)) return ptr - _str;
        return npos;
    }

    size_t find_first_not_of (const CharT* s, size_t pos, size_t count) const {
        if (count == 0) return pos >= _length ? npos : pos;
        const CharT* end = _str + _length;
        for (const CharT* ptr = _str + pos; ptr < end; ++ptr) if (!traits_type::find(s, count, *ptr)) return ptr - _str;
        return npos;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    size_t find_first_not_of (const _CharT* const& s, size_t pos = 0) const {
        return find_first_not_of(s, pos, traits_type::length(s));
    }

    template <size_t SIZE>
    size_t find_first_not_of (const CharT (&s)[SIZE], size_t pos = 0) const {
        return find_first_not_of(s, pos, SIZE-1);
    }


    size_t find_last_not_of (basic_string_view v, size_t pos = 0) const {
        return find_last_not_of(v._str, pos, v._length);
    }

    size_t find_last_not_of (CharT ch, size_t pos = 0) const {
        for (const CharT* ptr = _str + (pos >= _length ? (_length - 1) : pos); ptr >= _str; --ptr)
            if (!traits_type::eq(*ptr, ch)) return ptr - _str;
        return npos;
    }

    size_t find_last_not_of (const CharT* s, size_t pos, size_t count) const {
        if (count == 0) return pos >= _length ? (_length-1) : pos;
        for (const CharT* ptr = _str + (pos >= _length ? (_length - 1) : pos); ptr >= _str; --ptr)
            if (!traits_type::find(s, count, *ptr)) return ptr - _str;
        return npos;
    }

    template<class _CharT, typename = typename std::enable_if<std::is_same<_CharT, CharT>::value>::type>
    size_t find_last_not_of (const _CharT* const& s, size_t pos = 0) const {
        return find_last_not_of(s, pos, traits_type::length(s));
    }

    template <size_t SIZE>
    size_t find_last_not_of (const CharT (&s)[SIZE], size_t pos = 0) const {
        return find_last_not_of(s, pos, SIZE-1);
    }


private:

    static int _compare (const CharT* ptr1, size_t len1, const CharT* ptr2, size_t len2) {
        int r = traits_type::compare(ptr1, ptr2, std::min(len1, len2));
        if (!r) r = (len1 < len2) ? -1 : (len1 > len2 ? 1 : 0);
        return r;
    }

};

template <class C, class T> const C basic_string_view<C,T>::TERMINAL = C();

template <class C, class T> inline bool operator== (basic_string_view <C,T> lhs, basic_string_view <C,T> rhs) { return lhs.compare(rhs) == 0; }
template <class C, class T> inline bool operator== (const C* lhs, basic_string_view <C,T> rhs)                { return rhs.compare(lhs) == 0; }
template <class C, class T> inline bool operator== (basic_string_view <C,T> lhs, const C* rhs)                { return lhs.compare(rhs) == 0; }

template <class C, class T> inline bool operator!= (basic_string_view <C,T> lhs, basic_string_view <C,T> rhs) { return lhs.compare(rhs) != 0; }
template <class C, class T> inline bool operator!= (const C* lhs, basic_string_view <C,T> rhs)                { return rhs.compare(lhs) != 0; }
template <class C, class T> inline bool operator!= (basic_string_view <C,T> lhs, const C* rhs)                { return lhs.compare(rhs) != 0; }

template <class C, class T> inline bool operator<  (basic_string_view <C,T> lhs, basic_string_view <C,T> rhs) { return lhs.compare(rhs) < 0; }
template <class C, class T> inline bool operator<  (const C* lhs, basic_string_view <C,T> rhs)                { return rhs.compare(lhs) > 0; }
template <class C, class T> inline bool operator<  (basic_string_view <C,T> lhs, const C* rhs)                { return lhs.compare(rhs) < 0; }

template <class C, class T> inline bool operator<= (basic_string_view <C,T> lhs, basic_string_view <C,T> rhs) { return lhs.compare(rhs) <= 0; }
template <class C, class T> inline bool operator<= (const C* lhs, basic_string_view <C,T> rhs)                { return rhs.compare(lhs) >= 0; }
template <class C, class T> inline bool operator<= (basic_string_view <C,T> lhs, const C* rhs)                { return lhs.compare(rhs) <= 0; }

template <class C, class T> inline bool operator>  (basic_string_view <C,T> lhs, basic_string_view <C,T> rhs) { return lhs.compare(rhs) > 0; }
template <class C, class T> inline bool operator>  (const C* lhs, basic_string_view <C,T> rhs)                { return rhs.compare(lhs) < 0; }
template <class C, class T> inline bool operator>  (basic_string_view <C,T> lhs, const C* rhs)                { return lhs.compare(rhs) > 0; }

template <class C, class T> inline bool operator>= (basic_string_view <C,T> lhs, basic_string_view <C,T> rhs) { return lhs.compare(rhs) >= 0; }
template <class C, class T> inline bool operator>= (const C* lhs, basic_string_view <C,T> rhs)                { return rhs.compare(lhs) <= 0; }
template <class C, class T> inline bool operator>= (basic_string_view <C,T> lhs, const C* rhs)                { return lhs.compare(rhs) >= 0; }

template <class C, class T>
inline std::basic_ostream<C,T>& operator<< (std::basic_ostream<C,T>& os, basic_string_view<C,T> v) {
    return os.write(v.data(), v.length());
}

}
