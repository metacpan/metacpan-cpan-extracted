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

sub optex {
    Runner->new($script_path, @_);
}

sub run {
    optex(@_)->run;
}

sub line {
    qr/\A(?:.*\n){$_[0]}\z/;
}

1;
