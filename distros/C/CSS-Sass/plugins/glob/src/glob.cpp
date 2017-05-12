#include <cstring>
#include <cstdlib>
#include <iostream>
#include <stdint.h>
#include <string>
#include "FS.hpp"
#include "sass.h"
#include <libgen.h>

// return version of libsass we are linked against
extern "C" const char* ADDCALL libsass_get_version() {
  return libsass_version();
}

// create a custom importer to resolve glob-based includes
Sass_Import_List glob_importer(const char* cur_path, Sass_Importer_Entry cb, struct Sass_Compiler* comp)
{

  // get the base directory from previous import
  Sass_Import_Entry imp = sass_compiler_get_last_import(comp);
  char* prev = strdup(sass_import_get_abs_path(imp));
  std::string pattern(dirname(prev)); std::free(prev);
  pattern += std::string("/") + cur_path;

  // instantiate the matcher instance
  FS::Match* matcher = new FS::Match(pattern);
  // get vector of matches (results are cached)
  const std::vector<FS::Entry*> matches = matcher->getMatches();

  // propagate error back to libsass
  if (matches.empty()) return NULL;
  
  // get the cookie from importer descriptor
  // void* cookie = sass_importer_get_cookie(cb);
  // create a list to hold our import entries
  Sass_Import_List incs = sass_make_import_list(matches.size());
  
  // iterate over the list and print out the results
  std::vector<FS::Entry*>::const_iterator it = matches.begin();
  std::vector<FS::Entry*>::const_iterator end = matches.end();

  // attach import entry for each match
  size_t i = 0; while (i < matches.size()) {
    // create intermediate string object
    std::string path(matches[i]->path());
    // create the resolved import entries (paths to be loaded)
    incs[i ++ ] = sass_make_import(path.c_str(), path.c_str(), 0, 0);
  }

  // return imports
  return incs;

}

// entry point for libsass to request custom importers from plugin
extern "C" Sass_Importer_List ADDCALL libsass_load_importers()
{
  // allocate a custom function caller
  Sass_Importer_Entry c_header =
	sass_make_importer(glob_importer, 3000, (void*) 0);
  // create list of all custom functions
  Sass_Importer_List imp_list = sass_make_importer_list(1);
  // put the only function in this plugin to the list
  sass_importer_set_list_entry(imp_list, 0, c_header);
  // return the list
  return imp_list;
}