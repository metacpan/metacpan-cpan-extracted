use strict;
use warnings;
use utf8;
use File::Spec;
use open IO => ':utf8', ':std';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use lib 't/runner';
use Runner qw(get_path);

my($script, $module) = ('optex', 'App::optex');

my $script_path = get_path($script, $module) or die Dumper \%INC;

# Add ansicolumn script directory to PATH for child processes
if (my $ac_path = get_path('ansicolumn', 'App::ansicolumn')) {
    my($vol, $dir, $file) = File::Spec->splitpath($ac_path);
    my $ac_dir = File::Spec->catpath($vol, $dir, '');
    $ENV{PATH} = "$ac_dir:$ENV{PATH}";
}

sub optex {
    Runner->new($script_path, @_);
}

sub run {
    optex(@_)->run;
}

1;
