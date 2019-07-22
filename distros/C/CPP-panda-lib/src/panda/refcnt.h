#pragma once
#include "cast.h"
#include "traits.h"
#include <memory>
#include <stdint.h>
#include <stddef.h>
#include <assert.h>

namespace panda {

template <typename T>
struct iptr {
    template <class U> friend struct iptr;
    typedef T element_type;

    iptr ()                : ptr(NULL)    {}
    iptr (T* pointer)      : ptr(pointer) { if (ptr) refcnt_inc(ptr); }
    iptr (const iptr& oth) : ptr(oth.ptr) { if (ptr) refcnt_inc(ptr); }

    template <class U, typename = enable_if_convertible_t<U*, T*>>
    iptr (const iptr<U>& oth) : ptr(oth.ptr) { if (ptr) refcnt_inc(ptr); }

    iptr (iptr&& oth) {
        ptr = oth.ptr;
        oth.ptr = NULL;
    }

    template <class U, typename = enable_if_convertible_t<U*, T*>>
    iptr (iptr<U>&& oth) {
        ptr = oth.ptr;
        oth.ptr = NULL;
    }

    ~iptr () { if (ptr) refcnt_dec(ptr); }

    iptr& operator= (T* pointer) {
        if (pointer) refcnt_inc(pointer);
        if (ptr) refcnt_dec(ptr);
        ptr = pointer;
        return *this;
    }

    iptr& operator= (const iptr& oth) { return operator=(oth.ptr); }

    template <class U, typename = enable_if_convertible_t<U*, T*>>
    iptr& operator= (const iptr<U>& oth) { return operator=(oth.ptr); }

    iptr& operator= (iptr&& oth) {
        std::swap(ptr, oth.ptr);
        return *this;
    }

    template <class U, typename = enable_if_convertible_t<U*, T*>>
    iptr& operator= (iptr<U>&& oth) {
        if (ptr) {
            if (ptr == oth.ptr) return *this;
            refcnt_dec(ptr);
        }
        ptr = oth.ptr;
        oth.ptr = NULL;
        return *this;
    }

    void reset () {
        if (ptr) refcnt_dec(ptr);
        ptr = NULL;
    }

    void reset (T* p) { operator=(p); }

    T* operator-> () const noexcept { return ptr; }
    T& operator*  () const noexcept { return *ptr; }
    operator T*   () const noexcept { return ptr; }

    explicit
    operator bool () const noexcept { return ptr; }

    T* get () const noexcept { return ptr; }

    uint32_t use_count () const noexcept { return refcnt_get(ptr); }

    T* detach () noexcept {
        auto ret = ptr;
        ptr = nullptr;
        return ret;
    }

    void swap (iptr& oth) noexcept {
        std::swap(ptr, oth.ptr);
    }

private:
    T* ptr;
};

template <typename T, typename... Args>
iptr<T> make_iptr (Args&&... args) {
    return iptr<T>(new T(std::forward<Args>(args)...));
}

template <class T>
void swap (iptr<T>& a, iptr<T>& b) noexcept { a.swap(b); }

struct weak_storage;

struct Refcnt {
    void retain  () const { ++_refcnt; }
    void release () const {
        if (_refcnt > 1) --_refcnt;
        else delete this;
    }
    uint32_t refcnt () const noexcept { return _refcnt; }

protected:
    Refcnt () : _refcnt(0) {}
    virtual ~Refcnt ();

private:
    friend iptr<weak_storage> refcnt_weak (const Refcnt*);

    mutable uint32_t _refcnt;
    mutable iptr<weak_storage> _weak;

    iptr<weak_storage> get_weak () const;
};

struct Refcntd : Refcnt {
    void release () const {
        if (refcnt() <= 1) const_cast<Refcntd*>(this)->on_delete();
        Refcnt::release();
    }

protected:
    virtual void on_delete () noexcept {}
};

struct weak_storage : public Refcnt {
    weak_storage () : valid(true) {}
    bool valid;
};

inline void               refcnt_inc  (const Refcnt*  o) { o->retain(); }
inline void               refcnt_dec  (const Refcntd* o) { o->release(); }
inline void               refcnt_dec  (const Refcnt*  o) { o->release(); }
inline uint32_t           refcnt_get  (const Refcnt*  o) { return o->refcnt(); }
inline iptr<weak_storage> refcnt_weak (const Refcnt*  o) { return o->get_weak(); }

template <typename T1, typename T2> inline iptr<T1> static_pointer_cast  (const iptr<T2>& ptr) { return iptr<T1>(static_cast<T1*>(ptr.get())); }
template <typename T1, typename T2> inline iptr<T1> const_pointer_cast   (const iptr<T2>& ptr) { return iptr<T1>(const_cast<T1*>(ptr.get())); }
template <typename T1, typename T2> inline iptr<T1> dynamic_pointer_cast (const iptr<T2>& ptr) { return iptr<T1>(dyn_cast<T1*>(ptr.get())); }

template <typename T1, typename T2> inline std::shared_ptr<T1> static_pointer_cast  (const std::shared_ptr<T2>& shptr) { return std::static_pointer_cast<T1>(shptr); }
template <typename T1, typename T2> inline std::shared_ptr<T1> const_pointer_cast   (const std::shared_ptr<T2>& shptr) { return std::const_pointer_cast<T1>(shptr); }
template <typename T1, typename T2> inline std::shared_ptr<T1> dynamic_pointer_cast (const std::shared_ptr<T2>& shptr) { return std::dynamic_pointer_cast<T1>(shptr); }

template <typename T>
struct weak_iptr {
    template <class U> friend struct weak_iptr;
    typedef T element_type;

    weak_iptr() : storage(nullptr), object(nullptr) {}
    weak_iptr(const weak_iptr&) = default;
    weak_iptr& operator=(const weak_iptr& o) = default;

    weak_iptr(weak_iptr&&) = default;
    weak_iptr& operator=(weak_iptr&& o) = default;

    template <typename U, typename = enable_if_convertible_t<U*, T*>>
    weak_iptr(const iptr<U>& src) : storage(src ? refcnt_weak(src.get()) : nullptr), object(src ? src.get() : nullptr) {}

    template <typename U, typename = enable_if_convertible_t<U*, T*>>
    weak_iptr(const weak_iptr<U>& src) : storage(src.storage), object(src.object) {}

    template <class U>
    weak_iptr& operator=(const weak_iptr<U>& o) {
        storage = o.storage;
        object = o.object;
        return *this;
    }

    template <class U>
    weak_iptr& operator=(const iptr<U>& src) {
        storage = src ? refcnt_weak(src.get()) : nullptr;
        object  = src ? src.get() : nullptr;
        return *this;
    }

    template <class U>
    weak_iptr& operator=(weak_iptr<U>&& o) {
        storage = std::move(o.storage);
        object = std::move(o.object);
        return *this;
    }

    iptr<T> lock() const {
        return expired() ? nullptr : object;
    }

    bool expired() const {
        return !operator bool();
    }

    explicit operator bool() const {
        return storage && storage->valid;
    }

    size_t use_count() const {
        return *this ? refcnt_get(object) : 0;
    }

    size_t weak_count() const {
        if (!storage) return 0;
        if (storage->valid) return storage.use_count() - 1; // object itself refers to weak storage, ignore this reference in count
        return storage.use_count();
    }

    void reset() noexcept {
        storage.reset();
        object = nullptr;
    }

    void swap(weak_iptr& oth) noexcept {
        storage.swap(oth.storage);
        std::swap(object, oth.object);
    }

private:
    iptr<weak_storage> storage;
    T* object; // it is cache, it never invalidates itself, use storage->object to check validity
};

template <class T>
void swap(weak_iptr<T>& a, weak_iptr<T>& b) noexcept { a.swap(b); }

template <class T> struct _weak_t;
template <class T> struct _weak_t<iptr<T>> {
    using type = weak_iptr<T>;;
};

template <typename T>
using weak = typename _weak_t<T>::type;

}
