use 5.010;
use strict;
use warnings;

use Complete::Module qw(complete_module);
use Complete::Path;
use Complete::Util qw(arrayify_answer);
use File::Slurper qw(write_text);
use File::Temp qw(tempdir);
use Filesys::Cap qw(fs_is_cs);
use Test::More 0.98;

sub test_complete {
    my %args = @_;
    my $actual_res = arrayify_answer(complete_module(%{$args{args}}));
    is_deeply($actual_res, $args{result}) or diag explain $actual_res;
}

1;
