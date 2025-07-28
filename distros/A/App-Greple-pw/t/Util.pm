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

sub run {
    greple(@_)->run;
}

sub pw {
    greple '-Mpw', @_;
}

sub slurp {
    my $file = shift;
    open my $fh, "<:utf8", $file or die "open: $!";
    do { local $/; <$fh> };
}

sub line {
    my($text, $line, $comment) = @_;
    like($text, qr/\A(.*\n){$line}\z/, $comment//'');
}

1;