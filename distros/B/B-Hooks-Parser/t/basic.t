use strict;
use warnings;
use Test::More tests => 9;
use Test::Fatal;

BEGIN { use_ok('B::Hooks::Parser'); }

our $x;

BEGIN { $x = "BEGIN { is(B::Hooks::Parser::get_linestr(), \$x); }\n" }
BEGIN { is(B::Hooks::Parser::get_linestr(), $x); }

sub eval_test($) {
    my($src) = @_;
    $x = undef;
    is eval($src), 1;
    like $x, qr/^\Q$src\E(?:\n;)?/;
}
eval_test(qq{ BEGIN { \$x = B::Hooks::Parser::get_linestr(); } 1 ;});
eval_test(qq{ BEGIN { \$x = B::Hooks::Parser::get_linestr(); } q\x{0}1\x{0} ;});

is(B::Hooks::Parser::get_linestr, undef, 'get_linestr returns undef at runtime');
ok(B::Hooks::Parser::get_linestr_offset() < 0, 'get_linestr_offset returns something negative at runtime');

like(
    exception { B::Hooks::Parser::set_linestr('foo') },
    qr/at runtime/,
    'set_linestr fails at runtime',
);
