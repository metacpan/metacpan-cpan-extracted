/**
 * This code uses the json-c library
 *
 * gcc -l json -o catjson catjson-c.c
 *
 * Patrick . Hochstenbach @ UGent . be
 */
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <json/json.h>

int main(int argc, char *argv[]) {
    char *line = NULL;
    size_t size;
    json_object *new_obj;

    while (getline(&line, &size, stdin) != -1) {
       new_obj = json_tokener_parse(line);
       printf("%s\n", json_object_to_json_string(new_obj));
    }
    return 0;
}
