#!perl

use warnings;
use strict;

use Test::More;

plan tests => 19;

$ENV{'LS_COLORS'} = '';
$ENV{'TAR_COLORS'} = '';


is(`cat t/input/bsd_tar_1 | bin/tarcolor`,
   `cat t/output/bsd_tar_1`,
   "tar tvf test_tar_archive.tgz, no TAR_COLORS set");

is(`cat t/input/gnu_tar_1 | bin/tarcolor`,
   `cat t/output/gnu_tar_1`,
   "gtar tvf test_tar_archive.tgz, no TAR_COLORS set");

is(`cat t/input/bsd_tar_2 | bin/tarcolor`,
   `cat t/output/bsd_tar_2`,
   "tar tvf test_archive.tar.gz, no TAR_COLORS set");

is(`cat t/input/gnu_tar_2 | bin/tarcolor`,
   `cat t/output/gnu_tar_2`,
   "gtar tvf test_archive.tar.gz, no TAR_COLORS set");

is(`cat t/input/gnu_tar_3 | TAR_COLORS="di=01;33" bin/tarcolor`,
   `cat t/output/gnu_tar_3`,
   "gtar tvf test_archive.tar.gz, TAR_COLORS=\"di=01;33\"");

is(`cat t/input/gnu_tar_4 | TAR_COLORS="ex=01;33" bin/tarcolor`,
   `cat t/output/gnu_tar_4`,
   "gtar tvf test_archive.tar.gz, TAR_COLORS ex=\"01;33\" set");

is(`cat t/input/gnu_tar_5 | TAR_COLORS="ln=01;33" bin/tarcolor`,
   `cat t/output/gnu_tar_5`,
   "gtar tvf test_archive.tar.gz, TAR_COLORS ln=\"01;33\" set");

is(`cat t/input/bsd_tar_rwx_filename | TAR_COLORS="ln=40;34" bin/tarcolor`,
   `cat t/output/bsd_tar_rwx_filename`,
   "tar tvf archive_with_rwx_filename.tgz, TAR_COLORS ln=\"40;34\" set");

is(`cat t/input/gnu_tar_rwx_filename | TAR_COLORS="ln=40;34" bin/tarcolor`,
   `cat t/output/gnu_tar_rwx_filename`,
   "gtar tvf archive_with_rwx_filename.tgz, TAR_COLORS ln=\"40;34\" set");

is(`cat t/input/ls_with_colons_and_spaces | bin/tarcolor`,
   `cat t/output/ls_with_colors_and_spaces`,
   "Coloring of pathological ls output");

is(`cat t/input/ls_with_seconds | bin/tarcolor`,
   `cat t/output/ls_with_seconds`,
   "Coloring of ls output with seconds");

is(`cat t/input/gnu_tar_with_jar_file | bin/tarcolor`,
   `cat t/output/gnu_tar_with_jar_file`,
   "Coloring of GNU tar output for a jar file");

is(`cat t/input/mp3_purple_gz_cyan | LS_COLORS='*.mp3=01;35:*.gz=01;36' bin/tarcolor`,
   `cat t/output/mp3_purple_gz_cyan`,
   "Color .mp3 files purple and .gz files cyan");

is(`cat t/input/sun_tar | TAR_COLORS="ln=01;36:*.rpm=01;35" bin/tarcolor`,
   `cat t/output/sun_tar`,
   "Coloring of sun tar output");

is(`cat t/input/pax_1 | TAR_COLORS="ln=01;36:*.rpm=01;35" bin/tarcolor`,
   `cat t/output/pax_1`,
   "Coloring of pax output");

is(`cat t/input/cpio_1 | TAR_COLORS="ln=01;36:*.rpm=01;35" bin/tarcolor`,
   `cat t/output/cpio_1`,
   "Coloring of sun cpio output");

is(`cat t/input/short_lines.txt | bin/tarcolor`,
   `cat t/output/short_lines.txt`,
   "Short lines are passed through with no errors");

is(`cat t/input/blank_lines.txt | bin/tarcolor`,
   `cat t/output/blank_lines.txt`,
   "Blank lines are passed through with no errors");

is(`bin/tarcolor`,
   "Example: tar tvzf some_tarball.tar.gz | tarcolor\n",
   "Displays usage information");
