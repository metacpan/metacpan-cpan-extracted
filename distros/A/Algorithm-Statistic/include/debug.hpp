#include <iostream>

#ifndef NDEBUG  
    #undef DEBUG
    #undef DEBUG_ITERABLE
    #define DEBUG(name, x) std::cout << name << ": " << x << std::endl; 
    #define DEBUG_ITERABLE(name, start, end) \
        std::cout << name << ": "; \
        for (auto it=start; it!=end; ++it) { \
            std::cout << *it << " "; \
        } \
        std::cout << std::endl;
#else
    #undef DEBUG
    #undef DEBUG_ITERABLE
    #define DEBUG(name, x) 
    #define DEBUG_ITERABLE(name, start, end) 
#endif

