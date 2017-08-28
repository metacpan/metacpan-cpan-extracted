#include "Matcher.hpp"
#include "Trie.hpp"
#include <queue>

using std::vector;

namespace AhoCorasick {
    Matcher::Matcher(const vector<string> & keywords)
    : words(keywords) {
        build();
    }

    vector<string> Matcher::first_match(const string& input) const {
        vector<match> matches = search(input, true);
        return matches.empty() ? vector<string>({}) : vector<string>({ matches[0].keyword });
    }

    vector<string> Matcher::matches(const string& input) const {
        vector<match> matches = search(input, false);
        vector<string> s;
        for (match m: matches) {
            s.push_back(m.keyword);
        }
        return s;
    }

    vector<match> Matcher::match_details(const string& input) const {
        return search(input, false);
    }

    Matcher::~Matcher() {
        cleanup(root);
    }

    // root is a tree, provided we ignore a) references back to the root
    //   and b) the fail pointer
    void Matcher::cleanup(Trie *node) {
        for (Trie *child: node->children) {
            if (child && child != root) {
                cleanup(child);
            }
        }
        if (node->next && node->next != root) {
            cleanup(node->next);
        }
        delete node;
    }

    void Matcher::build() {
        root = new Trie();
        int i = 0;

        // 1. Build the keyword tree
        for (string& word : words) {
            Trie *node = root->add_word(word);
            node->out.push_front(i);
            i++;
        }

        root->fail = root;

        std::queue<Trie *> queue;
        queue.push(root);

        while (queue.size()) {
            Trie *n = queue.front();
            queue.pop();

            // Reverse the order of this node's out, so earlier keywords are first
            n->out.reverse();

            // add children to queue
            for (Trie *child: n->children) {
                while (child) {
                    queue.push(child);
                    child = child->next;
                }
            }

            // root's fail function is root
            if (n == root) continue;

            // Follow fail function from parent to find the longest suffix
            // (or reach the root)
            Trie *fail = n->parent->fail;
            while (fail->get_child(n->label) == nullptr && fail != root) {
                fail = fail->fail;
            }

            // We found the suffix...
            n->fail = fail->get_child(n->label);

            // ??
            if (n->fail == nullptr) n->fail = root;
            if (n->fail == n) n->fail = root;
        }
    }

    vector<match> Matcher::search(const string& text, bool stopAfterOne) const {
        Trie *n = root;
        vector <match> matches;
        size_t position = 0;
        for (const unsigned char ch : text) {
            // If it doesn't match, follow the fail links
            while (n->get_child(ch) == nullptr && n != root) {
                // Follow fails.
                // If nothing else, this will succeed once n = root, as fail is defined
                // for all characters.
                n = n->fail;
            }

            if (n == root) {
                n = n->get_child(ch);
                if (n == nullptr) n = root;
            }
            else n = n->get_child(ch);

            Trie *no = n;
            while (no != root) {
                for (int matchOffset : no->out) {
                    matches.push_back( {
                        words[matchOffset],
                        position - words[matchOffset].size() + 1,
                        position,
                    } );
                    if (stopAfterOne) {
                        return matches;
                    }
                }
                no = no->fail;
            }
            position++;
        }

        return matches;
    }
}
