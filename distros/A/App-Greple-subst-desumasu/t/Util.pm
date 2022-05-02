use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';

use lib 't/runner';
use Runner qw(get_path);

my $greple_path = get_path('greple', 'App::Greple') or die Dumper \%INC;

sub greple {
    Runner->new($greple_path, @_);
}

sub desumasu {
    greple '-Msubst::desumasu', @_;
}

sub slurp {
    my $file = shift;
    open my $fh, "<:utf8", $file or die "open: $!";
    do { local $/; <$fh> };
}

1;
