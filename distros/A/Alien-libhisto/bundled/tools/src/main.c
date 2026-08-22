/*
 * Executable main entrypoint dispatching to the libhistocli command runner.
 */

#include "histo/cli.h"
#include <stdio.h>

int main(int argc, char **argv) {
    return histo_cli_main(argc, argv, stdout, stderr);
}
