#include <cstring>
#include <iostream>
#include <stdint.h>
#include <math.h>
#include "sass.h"

// implement sign indicator (-1, 0, 1)
inline double sign(double x) { return x < 0 ? -1 : x > 0 ? 1 : 0; }

// implement factorial
unsigned int fact(unsigned int x)
{
    unsigned int value = 1;
    for(unsigned int i = 2; i <= x; i++)
    {
        value = value * i;
    }
    return value;
}

// these functions are not available directly in C
inline double csc(double x) { return 1.0 / sin(x); }
inline double sec(double x) { return 1.0 / cos(x); }
inline double cot(double x) { return 1.0 / tan(x); }
inline double csch(double x) { return 1.0 / sinh(x); }
inline double sech(double x) { return 1.0 / cosh(x); }
inline double coth(double x) { return 1.0 / tanh(x); }
inline double acsc(double x) { return 1.0 / asin(x); }
inline double asec(double x) { return 1.0 / acos(x); }
inline double acot(double x) { return 1.0 / atan(x); }
inline double acsch(double x) { return 1.0 / asinh(x); }
inline double asech(double x) { return 1.0 / acosh(x); }
inline double acoth(double x) { return 1.0 / atanh(x); }

// most functions are very simple
#define IMPLEMENT_1_ARG_FN(fn) \
union Sass_Value* fn_##fn(const union Sass_Value* s_args, Sass_Function_Entry cb, struct Sass_Compiler* comp) \
{ \
  if (!sass_value_is_list(s_args)) { \
    return sass_make_error("Invalid arguments for " #fn); \
  } \
  if (sass_list_get_length(s_args) != 1) { \
    return sass_make_error("Exactly one arguments expected for " #fn); \
  } \
  const union Sass_Value* inp = sass_list_get_value(s_args, 0); \
  if (!sass_value_is_number(inp)) { \
    return sass_make_error("You must pass a number into " #fn); \
  } \
  double inp_nr = sass_number_get_value(inp); \
  const char* inp_unit = sass_number_get_unit(inp); \
  return sass_make_number(fn(inp_nr), inp_unit); \
}

// math/numeric
IMPLEMENT_1_ARG_FN(sign)

// math/exponentiation
IMPLEMENT_1_ARG_FN(exp)
IMPLEMENT_1_ARG_FN(log)
IMPLEMENT_1_ARG_FN(log2)
IMPLEMENT_1_ARG_FN(log10)
IMPLEMENT_1_ARG_FN(sqrt)
IMPLEMENT_1_ARG_FN(cbrt)
IMPLEMENT_1_ARG_FN(fact)

// math/trigonometry
IMPLEMENT_1_ARG_FN(sin)
IMPLEMENT_1_ARG_FN(cos)
IMPLEMENT_1_ARG_FN(tan)
IMPLEMENT_1_ARG_FN(csc)
IMPLEMENT_1_ARG_FN(sec)
IMPLEMENT_1_ARG_FN(cot)

// math/hyperbolic
IMPLEMENT_1_ARG_FN(sinh)
IMPLEMENT_1_ARG_FN(cosh)
IMPLEMENT_1_ARG_FN(tanh)
IMPLEMENT_1_ARG_FN(csch)
IMPLEMENT_1_ARG_FN(sech)
IMPLEMENT_1_ARG_FN(coth)

// math/inverse-trigonometry
IMPLEMENT_1_ARG_FN(asin)
IMPLEMENT_1_ARG_FN(acos)
IMPLEMENT_1_ARG_FN(atan)
IMPLEMENT_1_ARG_FN(acsc)
IMPLEMENT_1_ARG_FN(asec)
IMPLEMENT_1_ARG_FN(acot)

// math/inverse-hyperbolic
IMPLEMENT_1_ARG_FN(asinh)
IMPLEMENT_1_ARG_FN(acosh)
IMPLEMENT_1_ARG_FN(atanh)
IMPLEMENT_1_ARG_FN(acsch)
IMPLEMENT_1_ARG_FN(asech)
IMPLEMENT_1_ARG_FN(acoth)

// so far only pow has two arguments
#define IMPLEMENT_2_ARG_FN(fn) \
union Sass_Value* fn_##fn(const union Sass_Value* s_args, Sass_Function_Entry cb, struct Sass_Compiler* comp) \
{ \
  if (!sass_value_is_list(s_args)) { \
    return sass_make_error("Invalid arguments for" #fn); \
  } \
  if (sass_list_get_length(s_args) != 2) { \
    return sass_make_error("Exactly two arguments expected for" #fn); \
  } \
  const union Sass_Value* value1 = sass_list_get_value(s_args, 0); \
  const union Sass_Value* value2 = sass_list_get_value(s_args, 1); \
  if (!sass_value_is_number(value1) || !sass_value_is_number(value2)) { \
    return sass_make_error("You must pass numbers into" #fn); \
  } \
  double value1_nr = sass_number_get_value(value1); \
  double value2_nr = sass_number_get_value(value2); \
  const char* value1_unit = sass_number_get_unit(value1); \
  const char* value2_unit = sass_number_get_unit(value2); \
  if (value2_unit && *value2_unit != 0) { \
    return sass_make_error("Exponent to " #fn " must be unitless"); \
  } \
  return sass_make_number(fn(value1_nr, value2_nr), value1_unit); \
} \

// one argument functions
IMPLEMENT_2_ARG_FN(pow)

// return version of libsass we are linked against
extern "C" const char* ADDCALL libsass_get_version() {
  return libsass_version();
}

// entry point for libsass to request custom functions from plugin
extern "C" Sass_Function_List ADDCALL libsass_load_functions()
{

  // create list of all custom functions
  Sass_Function_List fn_list = sass_make_function_list(33);

  // math/numeric functions
  sass_function_set_list_entry(fn_list,  0, sass_make_function("sign($x)", fn_sign, 0));

  // math/exponentiation functions
  sass_function_set_list_entry(fn_list,  1, sass_make_function("exp($x)", fn_exp, 0));
  sass_function_set_list_entry(fn_list,  2, sass_make_function("log($x)", fn_log, 0));
  sass_function_set_list_entry(fn_list,  3, sass_make_function("log2($x)", fn_log2, 0));
  sass_function_set_list_entry(fn_list,  4, sass_make_function("log10($x)", fn_log10, 0));
  sass_function_set_list_entry(fn_list,  5, sass_make_function("sqrt($x)", fn_sqrt, 0));
  sass_function_set_list_entry(fn_list,  6, sass_make_function("cbrt($x)", fn_cbrt, 0));
  sass_function_set_list_entry(fn_list,  7, sass_make_function("fact($x)", fn_fact, 0));
  sass_function_set_list_entry(fn_list,  8, sass_make_function("pow($base, $power)", fn_pow, 0));

  // math/trigonometry
  sass_function_set_list_entry(fn_list,  9, sass_make_function("sin($x)", fn_sin, 0));
  sass_function_set_list_entry(fn_list, 10, sass_make_function("cos($x)", fn_cos, 0));
  sass_function_set_list_entry(fn_list, 11, sass_make_function("tan($x)", fn_tan, 0));
  sass_function_set_list_entry(fn_list, 12, sass_make_function("csc($x)", fn_csc, 0));
  sass_function_set_list_entry(fn_list, 13, sass_make_function("sec($x)", fn_sec, 0));
  sass_function_set_list_entry(fn_list, 14, sass_make_function("cot($x)", fn_cot, 0));

  // math/hyperbolic
  sass_function_set_list_entry(fn_list, 15, sass_make_function("sinh($x)", fn_sinh, 0));
  sass_function_set_list_entry(fn_list, 16, sass_make_function("cosh($x)", fn_cosh, 0));
  sass_function_set_list_entry(fn_list, 17, sass_make_function("tanh($x)", fn_tanh, 0));
  sass_function_set_list_entry(fn_list, 18, sass_make_function("csch($x)", fn_csch, 0));
  sass_function_set_list_entry(fn_list, 19, sass_make_function("sech($x)", fn_sech, 0));
  sass_function_set_list_entry(fn_list, 20, sass_make_function("coth($x)", fn_coth, 0));

  // math/inverse-trigonometry
  sass_function_set_list_entry(fn_list, 21, sass_make_function("asin($x)", fn_asin, 0));
  sass_function_set_list_entry(fn_list, 22, sass_make_function("acos($x)", fn_acos, 0));
  sass_function_set_list_entry(fn_list, 23, sass_make_function("atan($x)", fn_atan, 0));
  sass_function_set_list_entry(fn_list, 24, sass_make_function("acsc($x)", fn_acsc, 0));
  sass_function_set_list_entry(fn_list, 25, sass_make_function("asec($x)", fn_asec, 0));
  sass_function_set_list_entry(fn_list, 26, sass_make_function("acot($x)", fn_acot, 0));

  // math/inverse-hyperbolic
  sass_function_set_list_entry(fn_list, 27, sass_make_function("asinh($x)", fn_asinh, 0));
  sass_function_set_list_entry(fn_list, 28, sass_make_function("acosh($x)", fn_acosh, 0));
  sass_function_set_list_entry(fn_list, 29, sass_make_function("atanh($x)", fn_atanh, 0));
  sass_function_set_list_entry(fn_list, 30, sass_make_function("acsch($x)", fn_acsch, 0));
  sass_function_set_list_entry(fn_list, 31, sass_make_function("asech($x)", fn_asech, 0));
  sass_function_set_list_entry(fn_list, 32, sass_make_function("acoth($x)", fn_acoth, 0));

  // return the list
  return fn_list;

}

// create a custom header to define to variables
Sass_Import_List custom_header(const char* cur_path, Sass_Importer_Entry cb, struct Sass_Compiler* comp)
{
  // create a list to hold our import entries
  Sass_Import_List incs = sass_make_import_list(1);
  // create our only import entry (must make copy)
  incs[0] = sass_make_import_entry("[math]", strdup(
    "$E: 2.718281828459045235360287471352 !global;\n"
    "$PI: 3.141592653589793238462643383275 !global;\n"
    "$TAU: 6.283185307179586476925286766559 !global;\n"
  ), 0);
  // return imports
  return incs;
}

// entry point for libsass to request custom headers from plugin
extern "C" Sass_Importer_List ADDCALL libsass_load_headers()
{
  // allocate a custom function caller
  Sass_Importer_Entry c_header =
    sass_make_importer(custom_header, 5000, (void*) 0);
  // create list of all custom functions
  Sass_Importer_List imp_list = sass_make_importer_list(1);
  // put the only function in this plugin to the list
  sass_importer_set_list_entry(imp_list, 0, c_header);
  // return the list
  return imp_list;
}