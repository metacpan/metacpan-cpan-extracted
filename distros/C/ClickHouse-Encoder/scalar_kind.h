#ifndef CHE_SCALAR_KIND_H
#define CHE_SCALAR_KIND_H

/* Predicates over Perl SVs and raw byte strings used by the encode
 * scalar dispatch to pick between integer / float / string / date
 * paths without parsing the value twice. */

int looks_stringy        (SV *val);
int looks_like_int_str   (const char *s, STRLEN len);
int looks_like_number_str(const char *s, STRLEN len);
int looks_like_date      (const char *s, STRLEN len);

#endif
