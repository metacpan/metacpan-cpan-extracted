#ifndef __AHOCORASICK_MATCHER_INCLUDED__
#define __AHOCORASICK_MATCHER_INCLUDED__

#include "Trie.hpp"
#include <vector>
#include <string>

using std::vector;
using std::string;

namespace AhoCorasick {
    struct match {
        string keyword;
        size_t start;
        size_t end;
    };

    class Matcher {
        vector<string> words;
        Trie *root;

        public:

        Matcher(const vector<string> & keywords);
        ~Matcher();

        vector <string> matches(const string& input) const;
        vector <string> first_match(const string& input) const;
        vector <match> match_details(const string &input) const;

        private:

        void build();
        vector<match> search(const string& text, bool stopAfterOne) const;
        void cleanup(Trie *node);

        // Prevent copy and assignment, as we have owned pointers
        Matcher & operator=(const Matcher&) = delete;
        Matcher(const Matcher&) = delete;
    };
}

#endif // __AHOCORASICK_MATCHER_INCLUDED__
