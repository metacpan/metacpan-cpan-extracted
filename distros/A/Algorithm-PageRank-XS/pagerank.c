#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "pagerank.h"
#include "table.h"

#ifndef MIN
#define MIN(A, B)  ((A) < (B)) ? (A) : (B)
#endif
#ifndef MAX
#define MAX(A, B)  ((A) > (B)) ? (A) : (B)
#endif


Array * page_rank(Table * inbound, unsigned int order, float alpha, float convergence, unsigned int max_times)
{
        register int t = 0, k, i;
        register float norm2 = 1.0, prod_scalar, x;
        unsigned int total_size = order;
        Array * vector = initial(total_size);
        Array * new_vector = initial(total_size);
        Array * tmp;



        x = 1.0 - alpha;

        while (t < max_times && norm2 >= convergence) {
                t++;
                norm2 = 0.0;
                prod_scalar = 0.0;

                for (k = 0; k < total_size; k++) {
                        if (is_sink(inbound, k))
                                prod_scalar += array_get(vector, k) * alpha;
                }
                prod_scalar += x;

                for (k = 0; k < total_size; k++) {
                        array_set(new_vector, k, prod_scalar);
                        if (!is_sink(inbound, k)) {
                                tmp = table_get(inbound, k);
                                for (i = 0; i < array_len(tmp); i++) {
                                        array_incr(new_vector, k,
                                                   array_get(vector,
                                                             (int)array_get(tmp, i)) *
                                                   alpha);
                                }
                        }
                        norm2 += (array_get(new_vector, k) - array_get(vector, k)) *
                                (array_get(new_vector, k) - array_get(vector, k));
                }

                t++;

                norm2 = sqrt((double)norm2) / total_size;

                array_copy(vector, new_vector);
        }

        array_delete(new_vector);
        return normalize(vector);
}


Array * initial(unsigned int order)
{
        register int i;
        register float value = 1.0 / order;
        Array * vector = array_init(value);

        for (i = 1; i < order; i++)
                array_push(vector, value);

        return vector;
}


Array * normalize(Array * vector)
{
        register int i;
        register double sum = 0;

        for (i = 0; i < array_len(vector); i++)
                sum += array_get(vector, i);

        for (i = 0; i < array_len(vector); i++)
                array_diveq(vector, i, sum);

        return vector;

}
