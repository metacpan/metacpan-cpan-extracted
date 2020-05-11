#!/usr/bin/env perl
package # hide from PAUSE
    makecpanfile;

# Make a cpanfile from the dependencies in Makefile.PL.
# Modified from https://github.com/miyagawa/cpanfile/blob/master/README.md
# by miyagawa.  Assumes MYMETA.json has already been created.
use strict;
use warnings;

use CPAN::Meta;
use File::Slurp qw(write_file);
use Module::CPANfile;

my $meta = CPAN::Meta->load_file("MYMETA.json");
my $file = Module::CPANfile->from_prereqs($meta->prereqs);
my $contents = <<EOT . $file->to_string;
# Auto-generated from Makefile.PL by cpanfile-from-Makefile-PL
EOT
    # Note: No timestamp so that the header line doesn't show up in the git diff
write_file('cpanfile', $contents);
