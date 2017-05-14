#pragma once

namespace panda {

template <typename It>
class IteratorPair {
    It _begin;
    It _end;
public:
    IteratorPair (It begin, It end) : _begin(begin), _end(end) {}

    It begin () const { return _begin; }
    It end   () const { return _end; }

};

}
