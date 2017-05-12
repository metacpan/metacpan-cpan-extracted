#ifndef __TABLE_H
#define __TABLE_H

#define NUM float

typedef struct {
        unsigned int len;
        NUM * data;
} Array;

typedef struct {
        unsigned int order;
        unsigned int capacity;
        Array ** rows;
} Table;



/* Public Array interface */
Array * array_init(NUM value);
Array * array_push(Array * input, NUM value);
int array_error();
int  array_delete(Array * array);
int array_copy(Array * dest, Array * src);
void array_print(FILE * file, Array * array);

#define array_get(A, i) ((i >= (A)->len) ? array_error() : (A)->data[(i)])
#define array_set(A, i, value) ((i >= (A)->len) ? array_error() : ((A)->data[(i)] = (value)))
#define array_len(A)    ((A)->len)
#define array_incr(A, i, amount) ((i >= (A)->len) ? array_error() : ((A)->data[(i)] += (amount)))

#define array_diveq(A, i, amount) ((i >= (A)->len) ? array_error() : ((A)->data[(i)] /= (amount)))


/* Public Table interface */
Table * table_init();
Array * table_add(Table * tb, unsigned int i, Array * row);
Array * table_get(Table * tb, unsigned int i);
/*Array * table_remove(Table * tb, unsigned int i);*/
int     table_delete(Table * tb);
void    table_print(FILE * file, Table * tb);
#define table_len(T)     (T)->order


#endif
