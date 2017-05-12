#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "table.h"

#ifndef MIN
#define MIN(A, B)  ((A) < (B)) ? (A) : (B)
#endif
#ifndef MAX
#define MAX(A, B)  ((A) > (B)) ? (A) : (B)
#endif

Array * array_init(float value)
{
        Array * result;

        if ((result = (Array *)malloc(sizeof(Array))) == NULL) {
                fprintf(stderr, "Memory error\n");
                exit(2);
        }

        if ((result->data = (NUM *)malloc(sizeof(NUM))) == NULL) {
                fprintf(stderr, "Memory error\n");
                exit(2);
        }

        result->data[0] = value;
        result->len = 1;
        return result;
}

void array_print(FILE * file, Array * arr)
{
        register unsigned int i;

        if (arr == NULL) {
                printf("NULL");
                return;
        }
        fprintf(file, "[");

        for (i = 0; i < array_len(arr); i++) {
                fprintf(file, "%f", array_get(arr, i));
                if (i < (array_len(arr) - 1))
                        printf(", ");
        }
        fprintf(file, "]");
}

int array_copy(Array * dest, Array * src)
/* Copy one array to the other. */
{
        assert(array_len(dest) == array_len(src));

        memcpy(dest->data, src->data, array_len(dest) * sizeof(NUM));

        return 0;
}


Array * array_push(Array * input, float value)
{
        input->len++;
        input->data = (NUM *) realloc(input->data, input->len * sizeof(NUM));
        if (input->data == NULL) {
                fprintf(stderr, "Memory error\n");
                exit(2);
        }
        input->data[input->len - 1] = value;
        return input;
}

int array_error()
{
        fprintf(stderr, "Array out of bounds!\n");
        exit(3);
}

int  array_delete(Array * array)
{
        if (array == NULL)
                return 1;

        if (array->data != NULL)
                free(array->data);

        free(array);
        return 0;
}

void _table_expand(Table *tb, unsigned int i);

Table * table_init()
{
        Table * result;

        result = (Table *)malloc(sizeof(Table));
        if (result == NULL) {
                fprintf(stderr, "Memory error\n");
                exit(2);
        }

        result->order = 1;
        result->capacity = result->order = 0;
        result->rows = (Array **)malloc(sizeof(Array *));
        if (result->rows == NULL) {
                fprintf(stderr, "Memory error\n");
                exit(2);
        }
        result->rows[0] = NULL;

        _table_expand(result, 999);
        result->order = 0;

        return result;
}

void table_print(FILE * file, Table * tb)
{
        register unsigned int i;
        fprintf(file, "TABLE OF ORDER %d AND CAPACITY %d\n", tb->order, tb->capacity);

        for (i = 0; i < tb->order; i++) {
                fprintf(file, "%d: ", i);
                array_print(file, table_get(tb, i));
                fprintf(file, "\n");
        }
}

void _table_expand(Table *tb, unsigned int i)
{
        unsigned int j;

        if (i < tb->capacity)
                return;

        tb->rows = (Array **)realloc(tb->rows, (i + 1) * sizeof(Array *));
        if (tb->rows == NULL) {
                fprintf(stderr, "Memory error\n");
                exit(2);
        }

        for (j = tb->order; j <= i; j++) {
                tb->rows[j] = NULL;
        }

        tb->capacity = tb->order = i + 1;
}

Array * table_add(Table * tb, unsigned int i, Array * row)
{
        if (i >= tb->capacity)
                _table_expand(tb, i);
        else {
                if (i >= tb->order) {
                        tb->order = i + 1;
                }
        }

        tb->rows[i] = row;
        return row;
}

Array * table_get(Table * tb, unsigned int i)
{
        if (i >= tb->order)
                return NULL;

        return tb->rows[i];
}

int     table_delete(Table * tb)
{
        unsigned int i;

        if (tb->rows != NULL) {
                for (i = 0; i < tb->order; i++) {
                        if (tb->rows[i] != NULL) {
                                if (tb->rows[i]->data != NULL)
                                        free(tb->rows[i]->data);
                                free(tb->rows[i]);
                        }
                }
                free(tb->rows);
        }

        free(tb);
        return 0;
}
