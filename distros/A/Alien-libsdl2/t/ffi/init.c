//#ifdef _WIN32
//#include "SDL.h"
//#else
#include "SDL.h"
//#endif
#include <ffi_platypus_bundle.h>

void ffi_pl_bundle_init(const char *package, int argc, void *argv[]) {
  // version = argv[0];
  // say = argv[1];

  // say("in init!");

  // snprintf(buffer, 512, "package = %s, version = %s", package, version);
  // say(buffer);

  // snprintf(buffer, 512, "args = %d", argc);
  // say(buffer);
}

void ffi_pl_bundle_fini(const char *package) {
  // say("in fini!");
}

int Log(const char *line) {
//#ifdef _WIN32
    //warn(line);
//#else
    SDL_Log(line);
//#endif
  return 1;
}