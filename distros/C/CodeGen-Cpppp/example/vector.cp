#! /usr/bin/env cpppp
## param $namespace;
## param $vector_t;
## param $el_t = 'int';
## param $el_dtor;
## param $el_copy_ctor= sub($dest, $src) { "*($dest) = *($src)" };
##
## $namespace ||= "vector_$el_t" =~ s/\s*\*\s*/_p/gr =~ s/_t$//r;
## $vector_t ||= $namespace . '_t';

## section PUBLIC;
typedef struct $namespace {
  size_t capacity, count;
  $el_t el[];
} ${namespace}_t;

bool ${namespace}_realloc($vector_t **vec_p, size_t capacity);
void ${namespace}_free($vector_t **vec_p);
bool ${namespace}_append($vector_t **vec_p, $el_t *value_p);

## section PRIVATE;

bool ${namespace}_realloc($vector_t **vec_p, size_t capacity) {
   $vector_t tmp;
   size_t size, i;
## if ($el_dtor) {
   // Exists and shrinking?
   if (*vec_p && capacity < (*vec_p)->count)
      // Run destructor for each deleted element
      for (i=(*vec_p)->count; i > capacity;) {
         $el_dtor((*vec_p)->el[--i]);
      }
## }
   size= sizeof(struct $namespace) + capacity * sizeof($el_t);
   tmp= ($vector_t*)( *vec_p? realloc(*vec_p, size) : malloc(size) );
   if (!tmp) return false;
   if (!*vec_p)
      tmp->count= 0;
   tmp->capacity= capacity;
   *vec_p= tmp;
}

void ${namespace}_free($vector_t **vec_p) {
   if (*vec_p) {
## if ($el_dtor) {
      // Run destructor for each deleted element
      for (i=(*vec_p)->count; i > 0;) {
         $el_dtor((*vec_p)->el[--i]);
      }
## }
      free(*vec_p);
      *vec_p= NULL;
   }
}

bool ${namespace}_append($vector_t **vec_p, $el_t *value_p) {
   if ((*vec_p)->count >= (*vec_p)->capacity)
      if (!${namespace}_realloc(vec_p, (*vec_p)->capacity << 1))
         return false;
   ${{ $el_copy_ctor->( '(*vec_p)->el + (*vec_p)->count', 'value_p' ) }};
   return true;
}

