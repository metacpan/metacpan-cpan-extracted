#!/usr/bin/perl
#===============================================================================
#
#  DESCRIPTION:  Modify files after Dist::Zilla is finished
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  11/10/2011 04:10:36 PM
#===============================================================================

use strict;
use warnings;
use Carp;
use File::Spec;
use File::Slurp;

my $dir = $ARGV[0] or die "Need build directory";

fix_Wgtd($dir);

sub fix_Wgtd {
    my ($dir) = @_;
    my $filename = File::Spec->catfile($dir, qw( bin/gwrap_ls.pl ));

    my $content = read_file($filename);

    $content =~ s/\n\s*### after_build remove from.*### after_build remove to[^\n]*//s;

    $content =~ s/\n[^\n]*### after_build remove[^\n]*//s;

    write_file($filename, $content);
}


