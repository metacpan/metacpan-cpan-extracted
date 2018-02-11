#pragma once
#include <memory>
#include <stdint.h>
#include <stddef.h>
#include <panda/cast.h>

namespace panda {

static long int void_refcnt = 1;

namespace {
    template <typename T>
    struct HasRetain {
        typedef char yes;
        typedef char no[2];

        struct fallback { int retain; };
        struct mixed_type: T, fallback {};
        template < typename U, U > struct type_check {};

        template < typename U > static no&  test( type_check< int (fallback::*), &U::retain >* = 0 );
        template < typename U > static yes& test( ... );

        static const bool value = sizeof( yes ) == sizeof( test< mixed_type >( NULL ) );
    };

    template <typename T>
    struct HasRelease {
        typedef char yes;
        typedef char no[2];

        struct fallback { int release; };
        struct mixed_type: T, fallback {};
        template < typename U, U > struct type_check {};

        template < typename U > static no&  test( type_check< int (fallback::*), &U::release >* = 0 );
        template < typename U > static yes& test( ... );

        static const bool value = sizeof( yes ) == sizeof( test< mixed_type >( NULL ) );
    };

    template <typename T>
    struct IsRefCounted {
        static const bool value = HasRelease<T>::value && HasRetain<T>::value;
    };
}

class Refcnt {
public:
    void    retain  () const { ++_refcnt; }
    void    release () const { if (--_refcnt <= 0) delete this; }
    int32_t refcnt  () const { return _refcnt; }
protected:
    Refcnt () : _refcnt(0) {}
    virtual ~Refcnt () {}
private:
    mutable int32_t _refcnt;
};

template <typename T>
class iptr {
public:
    template <class U> friend class iptr;
    typedef T element_type;

    iptr ()                   : ptr(NULL)    {}
    iptr (T* pointer)         : ptr(pointer) { if (ptr) ptr->retain(); }
    iptr (const iptr<T>& oth) : ptr(oth.ptr) { if (ptr) ptr->retain(); }
    template<class U>
    iptr (const iptr<U>& oth) : ptr(oth.ptr) { if (ptr) ptr->retain(); }

    iptr (iptr<T>&& oth) {
        ptr = oth.ptr;
        oth.ptr = NULL;
    }

    template<class U>
    iptr (iptr<U>&& oth) {
        ptr = oth.ptr;
        oth.ptr = NULL;
    }

    ~iptr () { if (ptr) ptr->release(); }

    iptr<T>& operator= (T* pointer) {
        if (ptr) ptr->release();
        ptr = pointer;
        if (pointer) pointer->retain();
        return *this;
    }

    iptr<T>& operator= (const iptr<T>& oth) { return iptr<T>::operator=(oth.ptr); }
    template<class U>
    iptr<T>& operator= (const iptr<U>& oth) { return iptr<T>::operator=(oth.ptr); }

    iptr<T>& operator= (iptr<T>&& oth) {
        std::swap(ptr, oth.ptr);
        return *this;
    }

    template<class U>
    iptr<T>& operator= (iptr<U>&& oth) {
        if (ptr) ptr->release();
        ptr = oth.ptr;
        oth.ptr = NULL;
        return *this;
    }

    void reset () {
        if (ptr) ptr->release();
        ptr = NULL;
    }

    void reset (T* p) { operator=(p); }

    T* operator-> () const { return ptr; }
    T& operator*  () const { return *ptr; }
    operator T*   () const { return ptr; }
    explicit
    operator bool () const { return ptr; }

    T* get () const { return ptr; }

private:
    T* ptr;
};

template <typename T1, typename T2>
inline iptr<T1> static_pointer_cast (const iptr<T2>& ptr) {
    return iptr<T1>(static_cast<T1*>(ptr.get()));
}

template <typename T1, typename T2>
inline iptr<T1> const_pointer_cast (const iptr<T2>& ptr) {
    return iptr<T1>(const_cast<T1*>(ptr.get()));
}

template <typename T1, typename T2>
inline iptr<T1> dynamic_pointer_cast (const iptr<T2>& ptr) {
    return iptr<T1>(dyn_cast<T1*>(ptr.get()));
}

class RefCounted {
public:
    void    retain  () const { ++_refcnt; on_retain(); }
    void    release () const { bool delete_me = --_refcnt <= 0; on_release(); if (delete_me && _refcnt <= 0) delete this; }
    int32_t refcnt  () const { return _refcnt; }
protected:
    RefCounted () : _refcnt(0) {}
    virtual void on_retain  () const {}
    virtual void on_release () const {}
    virtual ~RefCounted () {}
private:
    mutable int32_t _refcnt;
};

template <typename T, bool A = IsRefCounted<T>::value>
class shared_ptr {};

template <typename T>
class shared_ptr<T, true> {
public:
    typedef T element_type;

    shared_ptr () : ptr(NULL) {}

    shared_ptr (T* pointer) : ptr(pointer) {
        if (ptr) ptr->retain();
    }

    shared_ptr (const shared_ptr<T,true>& oth) : ptr(oth.ptr) {
        if (ptr) ptr->retain();
    }

    template<class U>
    shared_ptr (const shared_ptr<U,true>& oth) : ptr(oth.get()) {
        if (ptr) ptr->retain();
    }

    ~shared_ptr () {
        if (ptr) ptr->release();
    }

    shared_ptr<T,true>& operator= (T* pointer) {
        if (ptr) ptr->release();
        ptr = pointer;
        if (ptr) ptr->retain();
        return *this;
    }

    shared_ptr<T,true>& operator= (const shared_ptr<T,true>& oth) {
        return shared_ptr<T,true>::operator=(oth.ptr);
    }

    void reset () {
        if (ptr) ptr->release();
        ptr = NULL;
    }

    template <class U>
    void reset (U* p) {
        operator=(p);
    }

    T* operator-> () const { return ptr; }
    T& operator*  () const { return *ptr; }
    operator T*   () const { return ptr; }
    explicit operator bool () const { return ptr; }

    T*       get       () const { return ptr; }
    long int use_count () const { return ptr->refcnt(); }
    bool     unique    () const { return ptr->refcnt() == 1; }

private:
    T* ptr;
};

template <typename T>
class shared_ptr<T, false> {
public:
    typedef T element_type;

    shared_ptr () : ptr(NULL), refcnt(&void_refcnt) {
        refcnt_inc();
    }
    shared_ptr (std::nullptr_t) : shared_ptr() {}

    explicit shared_ptr (T* pointer) {
        ptr = pointer;
        if (ptr) {
            refcnt = new long int;
            *refcnt = 1;
        } else {
            refcnt = &void_refcnt;
            refcnt_inc();
        }
    }

    shared_ptr (const shared_ptr<T,false>& oth) : ptr(oth.ptr), refcnt(oth.refcnt) {
        refcnt_inc();
    }

    template<typename T2>
    shared_ptr (const shared_ptr<T2,false>& oth) : ptr(oth.ptr), refcnt(oth.refcnt) {
        refcnt_inc();
    }

    template<typename T2>
    shared_ptr (const shared_ptr<T2,false>& oth, T* pointer) : ptr(pointer), refcnt(oth.refcnt) {
        refcnt_inc();
    }

    ~shared_ptr () {
        refcnt_dec();
    }

    shared_ptr<T,false>& operator= (const shared_ptr<T,false>& oth) {
        refcnt_dec();
        ptr = oth.ptr;
        refcnt = oth.refcnt;
        refcnt_inc();
        return *this;
    }

    void reset () {
        refcnt_dec();
        ptr = NULL;
        refcnt = &void_refcnt;
        refcnt_inc();
    }

    template <class U>
    void reset (U* p) {
        operator=(p);
    }

    T* operator-> () const { return ptr; }
    T& operator*  () const { return *ptr; }
    operator T*   () const { return ptr; }
    explicit operator bool () const { return ptr; }

    T*       get       () const { return ptr; }
    long int use_count () const { return *refcnt; }
    bool     unique    () const { return *refcnt == 1; }

    template<typename U, bool A> friend class shared_ptr;

private:
    T*   ptr;
    long int* refcnt;

    void refcnt_inc () {
        ++*refcnt;
    }

    void refcnt_dec () {
        if (--*refcnt <= 0) {
            delete ptr;
            delete refcnt;
        }
    }
};

template <typename T1, typename T2>
inline shared_ptr<T1,false> static_pointer_cast (const shared_ptr<T2,false>& shptr) {
    return shared_ptr<T1,false>(shptr, static_cast<T1*>(shptr.get()));
}

template <typename T1, typename T2>
inline shared_ptr<T1,true> static_pointer_cast (const shared_ptr<T2,true>& shptr) {
    return shared_ptr<T1,true>(static_cast<T1*>(shptr.get()));
}

template <typename T1, typename T2>
inline shared_ptr<T1,false> const_pointer_cast (const shared_ptr<T2,false>& shptr) {
    return shared_ptr<T1,false>(shptr, const_cast<T1*>(shptr.get()));
}

template <typename T1, typename T2>
inline shared_ptr<T1,true> const_pointer_cast (const shared_ptr<T2,true>& shptr) {
    return shared_ptr<T1,true>(const_cast<T1*>(shptr.get()));
}

template <typename T1, typename T2>
inline shared_ptr<T1,false> dynamic_pointer_cast (const shared_ptr<T2,false>& shptr) {
    if (T1* p = dyn_cast<T1*>(shptr.get())) return shared_ptr<T1,false>(shptr, p);
    return shared_ptr<T1,false>();
}

template <typename T1, typename T2>
inline shared_ptr<T1,true> dynamic_pointer_cast (const shared_ptr<T2,true>& shptr) {
    if (T1* p = dyn_cast<T1*>(shptr.get())) return shared_ptr<T1,true>(p);
    return shared_ptr<T1,true>();
}

template <typename T1, typename T2>
inline std::shared_ptr<T1> static_pointer_cast (const std::shared_ptr<T2>& shptr) {
    return std::static_pointer_cast<T1>(shptr);
}
template <typename T1, typename T2>
inline std::shared_ptr<T1> const_pointer_cast (const std::shared_ptr<T2>& shptr) {
    return std::const_pointer_cast<T1>(shptr);
}
template <typename T1, typename T2>
inline std::shared_ptr<T1> dynamic_pointer_cast (const std::shared_ptr<T2>& shptr) {
    return std::dynamic_pointer_cast<T1>(shptr);
}

namespace {
    template <typename T, bool refcounted = IsRefCounted<T>::value>
    struct make_shared_impl;

    template <typename T>
    struct make_shared_impl<T, true> {
        template <typename... Args>
        static shared_ptr<T, true> make_shared(Args&&... args) {
            return new T(std::forward<Args>(args)...);
        }
    };

    template <typename T>
    struct make_shared_impl<T, false> {
        template <typename... Args>
        static shared_ptr<T, true> make_shared(Args&&... args) {
            struct tmp : public T, public virtual RefCounted {
                using T::T;
            };

            return new tmp(std::forward<Args>(args)...);
        }
    };
}

template <typename T, typename... Args>
shared_ptr<T> make_shared(Args&&... args) {
    //return make_shared_impl<T>::make_shared(std::forward<Args>(args)...);
    return shared_ptr<T>(new T(std::forward<Args>(args)...));
}

}
