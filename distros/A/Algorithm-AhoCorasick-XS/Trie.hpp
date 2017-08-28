#ifndef __AHOCORASICK_TRIE_INCLUDED__
#define __AHOCORASICK_TRIE_INCLUDED__

#include <forward_list>
#include <string>

namespace AhoCorasick {
    class Trie {
        public:

        unsigned char label = '\0';
        // Empirically, an array of 8 delivers a good compromise between
        // speed and memory usage.
        Trie *children[8] = {nullptr};
        Trie *next = nullptr;

        // Extensions for AC automaton
        Trie *fail = nullptr;
        std::forward_list<int> out;
        Trie *parent = nullptr;

        Trie() {}
        Trie(unsigned char label, Trie *parent) : label(label), parent(parent) {}

        static int bucket(unsigned char ch) {
            return ch & 7;  // Mask all but last 3 bytes
        }

        Trie *get_child(unsigned char ch) {
            Trie *child = children[ bucket(ch) ];
            if (!child) return nullptr;
            else {
                while (child) {
                    if (child->label == ch) return child;
                    child = child->next;
                }
                return nullptr;
            }
        }

        Trie *add_word(std::string s) {
            return add_cstring(s.data(), s.length());
        }

        private:

        Trie *add_cstring(const char *word, int len) {
            unsigned char first = *word;
            Trie *n = get_child(first);
            if (!n) {
                n = new Trie(first, this);
                int b = bucket(first);
                if (!children[b]) {
                    children[b] = n;
                }
                else {
                    Trie *ll = children[b];
                    while (ll->next) ll = ll->next;
                    ll->next = n;
                }
            }

            if (len > 0) {
                return n->add_cstring(word + 1, len - 1);
            }
            else {
                return this;
            }
        }
    };
}

#endif // __AHOCORASICK_TRIE_INCLUDED__
