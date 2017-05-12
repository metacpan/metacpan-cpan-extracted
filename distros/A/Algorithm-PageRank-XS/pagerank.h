#ifndef __PAGERANK_H
#define __PAGERANK_H
#include "table.h"

Array * page_rank(Table * inbound, unsigned int order, float alpha, float convergence, unsigned int max_times);
Array * initial(unsigned int order);
Array * normalize(Array * vector);

#define is_sink(T, k)    (table_get(T, k) == NULL)

#endif
