use strict;
use Test::More;

use B qw(class);

use B::Tap ':all';
use B::Deparse;
use B::Tools;

my $code = sub { 5963 };
my $cv = B::svref_2object($code);

my ($const) = op_grep { $_->name eq 'const' } $cv->ROOT;
ok $const;
tap($const, $cv->ROOT, \my @buf);

if (1) {
    require B::Concise;
    my $walker = B::Concise::compile('', '', $code);
    B::Concise::walk_output(\my $buf);
    $walker->();
    ::diag($buf);
}
like(B::Deparse->new->coderef2text($code), qr{5963});

$code->();
is_deeply(
    \@buf, [
        [G_SCALAR, 5963]
    ]
);
pass 'no segv';

done_testing;

