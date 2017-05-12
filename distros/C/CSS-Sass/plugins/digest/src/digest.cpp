#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>
#include "sass.h"
#include "crc.h"
#include "md5.h"

#define BUFFERSIZE 1024
#include "b64/encode.hpp"

std::string md5s(const std::string& text, struct Sass_Compiler* comp)
{
  MD5 digester;
  digester.update(text.c_str(), text.length());
  digester.finalize();
  return digester.hexdigest();
}

union Sass_Value* file_not_found(const std::string& file)
{
  std::string err("File not found: ");
  err += file; // add the filename
  return sass_make_error(err.c_str());
}

union Sass_Value* md5f(const std::string& file, struct Sass_Compiler* comp)
{
  std::string path(sass_compiler_find_file(file.c_str(), comp));
  if (path.empty()) {
    return sass_make_error("No filename given");
  }
  else {
    char in[1024];
    MD5 digester;
    std::ifstream fh;
    fh.open (path.c_str(), std::ios::binary);
    if (fh.fail()) return file_not_found(file);
    while(fh.read(in, sizeof(in))) {
      std::streamsize s = fh.gcount();
      digester.update(in, s);
    }
    std::streamsize s = fh.gcount();
    digester.update(in, s);
    digester.finalize();
    std::string rv(digester.hexdigest());
    return sass_make_string(rv.c_str());
  }
}

std::string crc16s(const std::string& text, struct Sass_Compiler* comp)
{
  short int crc = 0xFFFF;
  crc = crc16(text.c_str(), text.length(), crc);
  std::stringstream ss;
  ss << std::setfill('0')
     << std::setw(2)
     << std::hex
     << ((crc & 0x00FF) >> 0)
      << ((crc & 0xFF00) >> 8);
  return ss.str();
}

std::string crc32s(const std::string& text, struct Sass_Compiler* comp)
{
  unsigned long int crc = 0xFFFFFFFF;
  crc = crc32buf(text.c_str(), text.length(), crc);
  std::stringstream ss;
  ss << std::setfill('0')
     << std::setw(8)
     << std::hex
     << (0xFFFFFFFF & crc);
  return ss.str();
}

union Sass_Value* crc16f(const std::string& file, struct Sass_Compiler* comp)
{
  std::string path(sass_compiler_find_file(file.c_str(), comp));
  if (path.empty()) {
    return sass_make_error("No filename given");
  }
  else {
    char in[1024];
    std::ifstream fh;
    short int crc = 0xFFFF;
    fh.open (path.c_str(), std::ios::binary);
    if (fh.fail()) return file_not_found(file);
    while(fh.read(in, sizeof(in))) {
      std::streamsize s = fh.gcount();
      crc = crc16(in, s, crc);
    }
    std::streamsize s = fh.gcount();
    crc = crc16(in, s, crc);
    std::stringstream ss;
    ss << std::setfill('0')
       << std::setw(2)
       << std::hex
       << ((crc & 0x00FF) >> 0)
       << ((crc & 0xFF00) >> 8);
    std::string rv(ss.str());
    return sass_make_string(rv.c_str());
  }
}

union Sass_Value* crc32f(const std::string& file, struct Sass_Compiler* comp)
{
  std::string path(sass_compiler_find_file(file.c_str(), comp));
  if (path.empty()) {
    return sass_make_error("No filename given");
  }
  else {
    char in[1024];
    std::ifstream fh;
    unsigned long int crc = 0xFFFFFFFF;
    fh.open (path.c_str(), std::ios::binary);
    if (fh.fail()) return file_not_found(file);
    while(fh.read(in, sizeof(in))) {
      std::streamsize s = fh.gcount();
      crc = crc32buf(in, s, crc);
    }
    std::streamsize s = fh.gcount();
    crc = crc32buf(in, s, crc);
    std::stringstream ss;
    ss << std::setfill('0')
       << std::setw(8)
       << std::hex
       << (0xFFFFFFFF & crc);
    std::string rv(ss.str());
    return sass_make_string(rv.c_str());
  }
}

std::string base64s(const std::string& text, struct Sass_Compiler* comp)
{
  int len = 0;
  char out[1368];
  size_t size = 1024;
  base64::encoder enc;
  std::stringstream ss;
  const char* in = text.c_str();
  for (size_t i = 0, L = text.length(); i < L; i += size) {
    if (L < i + size) size = L - i;
    len = enc.encode(in, size, out);
    ss << std::string(out, out + len);
    in += size;
  }
  // finalize base64 string
  len = enc.encode_end(out);
  ss << std::string(out, out + len);
  // return string instance
  return ss.str();
}

union Sass_Value* base64f(const std::string& file, struct Sass_Compiler* comp)
{
  std::string path(sass_compiler_find_file(file.c_str(), comp));
  if (path.empty()) {
    return sass_make_error("No filename given");
  }
  else {
    int len = 0;
    char in[1024];
    char out[1368];
    std::ifstream fh;
    base64::encoder enc;
    fh.open (path.c_str(), std::ios::binary);
    if (fh.fail()) return file_not_found(file);
    std::stringstream ss;
    // read into chunks
    while(fh.read(in, sizeof(in))) {
      // encode the readed part
      std::streamsize s = fh.gcount();
      len = enc.encode(in, s, out);
      ss << std::string(out, out + len);
    }
    // encode the final part
    std::streamsize s = fh.gcount();
    len = enc.encode(in, s, out);
    ss << std::string(out, out + len);
    // finalize base64 string
    len = enc.encode_end(out);
    ss << std::string(out, out + len);
    // return string instance
    std::string rv(ss.str());
    return sass_make_string(rv.c_str());
  }
}

// most functions are very simple
#define IMPLEMENT_STR_FN(fn) \
union Sass_Value* fn_##fn(const union Sass_Value* s_args, Sass_Function_Entry cb, struct Sass_Compiler* comp) \
{ \
  if (!sass_value_is_list(s_args)) { \
    return sass_make_error("Invalid arguments for " #fn); \
  } \
  if (sass_list_get_length(s_args) != 1) { \
    return sass_make_error("Exactly one arguments expected for " #fn); \
  } \
  const union Sass_Value* inp = sass_list_get_value(s_args, 0); \
  if (!sass_value_is_string(inp)) { \
    return sass_make_error("You must pass a string into " #fn); \
  } \
  const char* inp_str = sass_string_get_value(inp); \
  std::string rv = fn(inp_str, comp); \
  return sass_make_string(rv.c_str()); \
} \

// string digest functions
IMPLEMENT_STR_FN(md5s)
IMPLEMENT_STR_FN(crc16s)
IMPLEMENT_STR_FN(crc32s)
IMPLEMENT_STR_FN(base64s)

// most functions are very simple
#define IMPLEMENT_FILE_FN(fn) \
union Sass_Value* fn_##fn(const union Sass_Value* s_args, Sass_Function_Entry cb, struct Sass_Compiler* comp) \
{ \
  if (!sass_value_is_list(s_args)) { \
    return sass_make_error("Invalid arguments for " #fn); \
  } \
  if (sass_list_get_length(s_args) != 1) { \
    return sass_make_error("Exactly one arguments expected for " #fn); \
  } \
  const union Sass_Value* inp = sass_list_get_value(s_args, 0); \
  if (!sass_value_is_string(inp)) { \
    return sass_make_error("You must pass a string into " #fn); \
  } \
  const char* inp_str = sass_string_get_value(inp); \
  return fn(inp_str, comp); \
} \

// file digest functions
IMPLEMENT_FILE_FN(md5f)
IMPLEMENT_FILE_FN(crc16f)
IMPLEMENT_FILE_FN(crc32f)
IMPLEMENT_FILE_FN(base64f)

// return version of libsass we are linked against
extern "C" const char* ADDCALL libsass_get_version() {
  return libsass_version();
}

// entry point for libsass to request custom functions from plugin
extern "C" Sass_Function_List ADDCALL libsass_load_functions()
{

  // create list of all custom functions
  Sass_Function_List fn_list = sass_make_function_list(8);

  // string digest functions
  sass_function_set_list_entry(fn_list,  0, sass_make_function("md5($x)", fn_md5s, 0));
  sass_function_set_list_entry(fn_list,  1, sass_make_function("crc16($x)", fn_crc16s, 0));
  sass_function_set_list_entry(fn_list,  2, sass_make_function("crc32($x)", fn_crc32s, 0));
  sass_function_set_list_entry(fn_list,  3, sass_make_function("base64($x)", fn_base64s, 0));

  // file digest functions
  sass_function_set_list_entry(fn_list,  4, sass_make_function("md5f($x)", fn_md5f, 0));
  sass_function_set_list_entry(fn_list,  5, sass_make_function("crc16f($x)", fn_crc16f, 0));
  sass_function_set_list_entry(fn_list,  6, sass_make_function("crc32f($x)", fn_crc32f, 0));
  sass_function_set_list_entry(fn_list,  7, sass_make_function("base64f($x)", fn_base64f, 0));

  // return the list
  return fn_list;

}

// entry point for libsass to request custom headers from plugin
extern "C" Sass_Importer_List ADDCALL libsass_load_headers()
{
  // create list of all custom functions
  Sass_Importer_List imp_list = sass_make_importer_list(1);
  // put the only function in this plugin to the list
  sass_importer_set_list_entry(imp_list, 0, 0);
  // return the list
  return imp_list;
}