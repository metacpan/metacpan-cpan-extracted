#pragma once

namespace panda {

template <typename Begin, typename End = Begin>
class IteratorPair {
    Begin _begin;
    End _end;
public:
    IteratorPair (Begin begin, End end) : _begin(begin), _end(end) {}

    Begin begin () const { return _begin; }
    End end   () const { return _end; }

};

template <typename Begin, typename End = Begin>
IteratorPair<Begin, End> make_iterator_pair(Begin begin, End end) {
    return IteratorPair<Begin, End>(begin, end);
}

}
