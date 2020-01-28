#pragma once
#include "string.h"
#include "string_view.h"
#include <memory>
#include <functional>
#include <unordered_set>

/*
 * panda::unordered_string_set and panda::unordered_string_multiset are wrappers around STL's versions in case if keys are panda::string.
 * The goal is to make it possible to call some STL's methods with string_view
 */

namespace panda {

    template <class Key, class Hash = std::hash<Key>, class KeyEqual = std::equal_to<Key>, class Allocator = std::allocator<Key>>
    class unordered_string_set : public std::unordered_set<Key, Hash, KeyEqual, Allocator> {
    private:
        template <typename C, typename TR, typename A>
        static inline std::true_type  _is_base_string (panda::basic_string<C,TR,A> const volatile) { return std::true_type(); }
        static inline std::false_type _is_base_string (...) { return std::false_type(); }

        static_assert(decltype(_is_base_string(Key()))::value, "Key must be based on panda::basic_string");

        using Base  = std::unordered_set<Key, Hash, KeyEqual, Allocator>;
        using SVKey = basic_string_view<typename Key::value_type, typename Key::traits_type>;

        static Key _key_from_sv (const SVKey& key) {
            typedef typename Key::value_type FakeCharLiteral[1];
            Key tmp(*(const FakeCharLiteral*)key.data());
            tmp.length(key.length());
            return tmp;
        }
    public:
        using typename Base::key_type;
        using typename Base::value_type;
        using typename Base::size_type;
        using typename Base::difference_type;
        using typename Base::hasher;
        using typename Base::key_equal;
        using typename Base::allocator_type;
        using typename Base::reference;
        using typename Base::const_reference;
        using typename Base::pointer;
        using typename Base::const_pointer;
        using typename Base::iterator;
        using typename Base::const_iterator;
        using typename Base::local_iterator;
        using typename Base::const_local_iterator;

        using Base::Base;
        using Base::find;
        using Base::count;
        using Base::erase;
        using Base::equal_range;

        template <class X, typename = typename std::enable_if<std::is_same<X,SVKey>::value>::type>
        iterator find (X key) { return find(_key_from_sv(key)); }

        template <class X, typename = typename std::enable_if<std::is_same<X,SVKey>::value>::type>
        const_iterator find (X key) const { return find(_key_from_sv(key)); }

        template <class X, typename = typename std::enable_if<std::is_same<X,SVKey>::value>::type>
        size_type count (X key) const { return count(_key_from_sv(key)); }

        template <class X, typename = typename std::enable_if<std::is_same<X,SVKey>::value>::type>
        size_type erase (X key) { return erase(_key_from_sv(key)); }

        template <class X, typename = typename std::enable_if<std::is_same<X,SVKey>::value>::type>
        std::pair<iterator,iterator> equal_range (X key) { return equal_range(_key_from_sv(key)); }

        template <class X, typename = typename std::enable_if<std::is_same<X,SVKey>::value>::type>
        std::pair<const_iterator,const_iterator> equal_range (X key) const { return equal_range(_key_from_sv(key)); }

    };

    template <class Key, class Hash = std::hash<Key>, class KeyEqual = std::equal_to<Key>, class Allocator = std::allocator<Key>>
    class unordered_string_multiset : public std::unordered_multiset<Key, Hash, KeyEqual, Allocator> {
    private:
        template <typename C, typename TR, typename A>
        static inline std::true_type  _is_base_string (panda::basic_string<C,TR,A> const volatile) { return std::true_type(); }
        static inline std::false_type _is_base_string (...) { return std::false_type(); }

        static_assert(decltype(_is_base_string(Key()))::value, "Key must be based on panda::basic_string");

        using Base  = std::unordered_multiset<Key, Hash, KeyEqual, Allocator>;
        using SVKey = basic_string_view<typename Key::value_type, typename Key::traits_type>;

        static Key _key_from_sv (const SVKey& key) {
            typedef typename Key::value_type FakeCharLiteral[1];
            Key tmp(*(const FakeCharLiteral*)key.data());
            tmp.length(key.length());
            return tmp;
        }
    public:
        using typename Base::key_type;
        using typename Base::value_type;
        using typename Base::size_type;
        using typename Base::difference_type;
        using typename Base::hasher;
        using typename Base::key_equal;
        using typename Base::allocator_type;
        using typename Base::reference;
        using typename Base::const_reference;
        using typename Base::pointer;
        using typename Base::const_pointer;
        using typename Base::iterator;
        using typename Base::const_iterator;
        using typename Base::local_iterator;
        using typename Base::const_local_iterator;

        using Base::Base;
        using Base::find;
        using Base::count;
        using Base::erase;
        using Base::equal_range;

        template <class X, typename = typename std::enable_if<std::is_same<X,SVKey>::value>::type>
        iterator find (X key) { return find(_key_from_sv(key)); }

        template <class X, typename = typename std::enable_if<std::is_same<X,SVKey>::value>::type>
        const_iterator find (X key) const { return find(_key_from_sv(key)); }

        template <class X, typename = typename std::enable_if<std::is_same<X,SVKey>::value>::type>
        size_type count (X key) const { return count(_key_from_sv(key)); }

        template <class X, typename = typename std::enable_if<std::is_same<X,SVKey>::value>::type>
        size_type erase (X key) { return erase(_key_from_sv(key)); }

        template <class X, typename = typename std::enable_if<std::is_same<X,SVKey>::value>::type>
        std::pair<iterator,iterator> equal_range (X key) { return equal_range(_key_from_sv(key)); }

        template <class X, typename = typename std::enable_if<std::is_same<X,SVKey>::value>::type>
        std::pair<const_iterator,const_iterator> equal_range (X key) const { return equal_range(_key_from_sv(key)); }

    };

}
