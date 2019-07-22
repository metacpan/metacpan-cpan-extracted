#pragma once
#include "refcnt.h"

namespace panda {
/**
 * owning_list where iterators share owning of nodes with list.
 * Removing of any iterator never invalidates value under it.
 * Forward iterator never invalidates, even if all list cleared.
 * Backward iterator keep valid value, but operator++ may lead to invalid iterator if no one keep reference to it
 * Removeing of element just fork list
 * 1 -> 2 -> 3
 * remove(2)
 * 1 -> 3
 *      ^
 *      2
 * Node will be deleted when all strong reference to it will be forgotten
 * Reference to previous node is weak
 * 1-> 2-> 3
 * iter = last; // it is 3
 * remove(2)
 * remove(3)
 * *iter is still valid and == 3
 * ++iter is invalid, because nobody keeps reference to node 2 and it was removed
 * Like in std::list don't try using reverse_iterator after removing its node, but you can do it wit forward iterator
 * You can use removed reversed_iterator if it is only removed and you are sure than prev is still valid
 */
template <typename T>
struct owning_list {
    struct node_t : Refcnt {
        node_t(const T& value) : value(value), valid(true), next(nullptr), prev(nullptr) {}

        T value;
        bool valid;
        iptr<node_t> next;
        node_t* prev;
    };
    using node_sp = iptr<node_t>;

    static void next_strategy(node_sp& node) {
        node = node->next;
        while (node && !node->valid) {
            node = node->next;
        }
    }

    static void prev_strategy(node_sp& node) {
        node = node->prev;
        while (node && !node->valid) {
            node = node->prev;
        }
    }
    void remove_node(node_t* node);

    using inc_strategy_t = void(*)(node_sp&);

    template<inc_strategy_t inc>
    struct base_iterator {
        node_sp node;

        base_iterator(const node_sp& node) : node(node) {}
        T& operator*() {
            return node->value;
        }
        T* operator->() {
            return &node->value;
        }
        base_iterator& operator++() {
            inc(node);
            return *this;
        }
        base_iterator operator++(int) {
            base_iterator res = *this;
            inc(node);
            return res;
        }

        bool operator ==(const base_iterator& oth) const {
            return node == oth.node;
        }

        bool operator !=(const base_iterator& oth) const {
            return !operator==(oth);
        }
    };

    using reverse_iterator = base_iterator<prev_strategy>;
    using iterator = base_iterator<next_strategy>;

    owning_list() : _size(0), first(nullptr), last(nullptr) {}

    iterator begin() {
        return first;
    }

    iterator end() {
        return iterator(nullptr);
    }

    reverse_iterator rbegin() {
        return last;
    }

    reverse_iterator rend() {
        return reverse_iterator(nullptr);
    }

    template<typename TT = T>
    void push_back(TT&& val) {
        node_sp node = new node_t(std::forward<TT>(val));
        if (last) {
            node->prev = last;
            last->next = node;
            last = node;
        } else {
            first = last = node;
        }
        ++_size;
    }

    template<typename TT = T>
    void push_front(TT&& val) {
        node_sp node = new node_t(std::forward<TT>(val));
        if (first) {
            node->next = first;
            first->prev = node;
            first = node;
        } else {
            first = last = node;
        }
        ++_size;
    }


    void remove(const T& val) {
        node_sp node = first;
        while (node) {
            if (node->value == val) {
                remove_node(node);
                return;
            }
            node = node->next;
        }
    }

    template <inc_strategy_t strategy>
    void erase(base_iterator<strategy> iter) {
        remove_node(iter.node);
    }

    void clear() {
        for (auto iter = begin(); iter != end(); ++iter) {
            iter.node->valid = false;
        }
        first = nullptr;
        last = nullptr;
        _size = 0;
    }

    size_t size() const {
        return _size;
    }

    bool empty() const {
        return _size == 0;
    }

private:
    size_t _size;
    node_sp first;
    node_sp last;
};

template<typename T>
void owning_list<T>::remove_node(owning_list::node_t* node) {
    node->valid = false;
    if (node->prev) {
        node->prev->next = node->next;
    } else {
        first = node->next;
    }
    if (node->next) {
        node->next->prev = node->prev;
    } else {  // it is last value
        last = node->prev;
    }
    _size--;
}

}
