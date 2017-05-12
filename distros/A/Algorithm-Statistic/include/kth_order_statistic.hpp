#ifndef ALGO_KTH_ORDER_STATISTIC_HPP
#define ALGO_KTH_ORDER_STATISTIC_HPP

/* K-th order statistic evaluator
 * 
 * The same as nth_element in stl library.
 * 
 * Author: I. Karbachinsky <igorkarbachinsky@mail.ru> 2014
 */


#include <iostream>
#include <cassert>
#include <stdexcept>
#include <iterator>
#include <functional>

#include "debug.hpp"

namespace algo {

template<class InputIterator, class Compare=std::minus<typename InputIterator::value_type> >
const InputIterator KthOrderStatistic(const InputIterator begin, const InputIterator end, size_t k, const Compare &compare) {
    typedef typename std::iterator_traits<InputIterator>::value_type T;

    size_t n = std::distance(begin, end);

    DEBUG("", std::endl);
    DEBUG_ITERABLE("Array", begin, end);
    DEBUG("k", k)
    DEBUG("n", n)

    if (n == 0)
        throw std::invalid_argument("Empty array passed");

    if ( k > n)
        throw std::invalid_argument("Bad argument k. Maybe it's out of range");

    auto it = begin,
         jt = end-1;

    auto pivot = begin + n/2;
    const T pivot_value = *pivot; 

    DEBUG("Pivot value", pivot_value);

    do {
        while (compare(*it, pivot_value) < 0) {
            ++it;
        }
        while (compare(*jt, pivot_value) > 0) {
            --jt;
        }

        if (it < jt) {
            DEBUG("Swap it", *it);
            DEBUG("Swap jt", *jt);

            std::iter_swap(it, jt);

            DEBUG_ITERABLE("Array after rearranging", begin, end);

            if (compare(*it, *jt) == 0 && jt - it <= 2)
                break;
        }
    } while (it < jt);

    pivot = jt;

    size_t pivot_n = std::distance(begin, pivot);

    DEBUG("Pivot position after rearranging", pivot_n);

    if (pivot_n == k) {
        DEBUG("FOUND on positon: ", pivot_n);
        return pivot;
    }
    if (pivot_n > k) 
        return KthOrderStatistic<InputIterator, Compare>(begin, pivot, k, compare);
    
    return KthOrderStatistic<InputIterator, Compare>(pivot, end, k - pivot_n, compare);
}

} // namespace algo

#endif
