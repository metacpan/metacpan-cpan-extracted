#ifndef AHO_CORASICK_HPP
#define AHO_CORASICK_HPP

#include <string>
#include <vector>
#include <queue>
#include <memory>
#include "stdio.h"

using std::string;
using std::vector;

namespace AhoCorasick {
  // Number of characters in the input alphabet
  static constexpr int MAXCHARS = 256;

  struct trie {
    unsigned char label;
    trie *children[MAXCHARS] = {nullptr};
    // Extensions for AC automaton
    trie *fail = nullptr;
    vector<int> out = vector<int>();

    trie() : label('\0') {}
    trie(unsigned char label) : label(label) {}
  };

  struct match {
    string keyword;
    size_t start;
    size_t end;
  };

  class Matcher {
    vector<string> words;
    trie *root;

    public:
      Matcher(const vector<string> & keywords)
      : words(keywords) {
        build();
      }

      ~Matcher();

      vector<string> first_match(const string& input) const {
        vector<match> matches = search(input, true);
        return matches.empty() ? vector<string>({}) : vector<string>({ matches[0].keyword });
      }

      vector<string> matches(const string& input) const {
        vector<match> matches = search(input, false);
        vector<string> s;
        for (match m: matches) {
            s.push_back(m.keyword);
        }
        return s;
      }

      vector<match> match_details(const string& input) const {
        return search(input, false);
      }

    private:
      void build();
      vector<match> search(const string& text, bool stopAfterOne) const;
      void cleanup(trie *node);

      // Prevent copy and assignment, as we have owned pointers
      Matcher & operator=(const Matcher&) = delete;
      Matcher(const Matcher&) = delete;
  };

  Matcher::~Matcher() {
      cleanup(root);
  }

  // root is a tree, provided we ignore a) references back to the root
  //   and b) the fail pointer
  void Matcher::cleanup(trie *node) {
    for (unsigned int i = 0; i < MAXCHARS; i++) {
        trie *child = node->children[i];
        if (child != root && child != nullptr) {
            cleanup(child);
        }
    }
    delete node;
  }

  void Matcher::build() {
    root = new trie();
    int i = 0;

    // 1. Build the keyword tree
    for (string& word : words) {
        trie *node = root;
        // Follow the path labelled by root
        for (char& c : word) {
            unsigned char ch = c;

            if (!node->children[ch]) {
                node->children[ch] = new trie(ch);
            }
            node = node->children[ch];
        }
        node->out.push_back(i);
        i++;
    }

    // 2. Complete goto function for root
    //    Set g(root,a) = root for any a that isn't defined
    for (unsigned int i = 0; i < MAXCHARS; i++) {
        if (root->children[i] == nullptr) {
            root->children[i] = root;
        }
    }

    // 3. Compute fail and output for all nodes, in breadth-first order
    std::queue<trie *> queue;
    for (unsigned int i = 0; i < MAXCHARS; i++) {
        trie *q = root->children[i];
        if (q != root) {
            q->fail = root;
            queue.push(q);
        }
    }

    while (queue.size()) {
        trie *r = queue.front();
        queue.pop();
        for (unsigned int i = 0; i < MAXCHARS; i++) {
            trie *u = r->children[i];
            if (u != nullptr) {
                queue.push(u);
                trie *v = r->fail;
                while (v->children[i] == nullptr) {
                    v = v->fail;
                }
                u->fail = v->children[i];

                u->out.insert( u->out.end(), u->fail->out.begin(), u->fail->out.end() );
            }
        }
    }
  }

  vector<match> Matcher::search(const string& text, bool stopAfterOne) const {
    trie *q = root;
    vector <match> matches;
    size_t position = 0;
    for (const unsigned char ch : text) {
        // If it doesn't match, follow the fail links
        while (q->children[ch] == nullptr) {
            // Follow fails.
            // If nothing else, this will succeed once q = root, as fail is defined
            // for all characters.
            q = q->fail;
        }
        // We matched, so follow the goto link (may be root)
        q = q->children[ch];
        for (int matchOffset : q->out) {
            matches.push_back( {
                words[matchOffset],
                position - words[matchOffset].size() + 1,
                position,
            } );
            if (stopAfterOne) {
                return matches;
            }
        }
        position++;
    }

    return matches;
  }
}

#endif
