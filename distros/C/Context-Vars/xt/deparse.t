#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use B::Deparse;
use Context::Vars qw($dp);

# A sub with a scope still deparses as it was written, with no warning.

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

sub named { $dp = 'named'; $dp }
sub labelled { FIRST: $dp = 'lab'; $dp }

my $d = B::Deparse->new;
my $text = $d->coderef2text(\&named);
like($text, qr/\$(?:main::)?dp = 'named'/, 'the assignment is there');
unlike($text, qr/XXX|context_vars/, 'and nothing that was not written');

my $lab = $d->coderef2text(\&labelled);
like($lab, qr/FIRST:/, 'a sub whose first statement has a label deparses');
like($lab, qr/\$(?:main::)?dp = 'lab'/, 'with its assignment');
is(Context::Vars::_scope_kind(\&labelled), 2, 'it is the one kind that uses an op of its own');
diag "labelled: " . join(' ', split ' ', $lab);

is_deeply([grep { !/unexpected OP_(?:CUSTOM|CONTEXT_VARS_SCOPE)|context_vars_scope/i } @warnings], [], 'no other warning');
diag "B::Deparse warned about the op of its own: @warnings" if @warnings;

my $concise = '';
require B::Concise;
B::Concise::walk_output(\$concise);
B::Concise::compile('-exec', \&named)->();
like($concise, qr/nextstate/, 'B::Concise walks it');

done_testing;
