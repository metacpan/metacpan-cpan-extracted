use warnings;
use strict;
use Test::More;
use DOCSIS::ConfigFile qw( encode_docsis decode_docsis );

plan skip_all => 'cannot find test-files' unless -e 't/data/rt70882/encoded.cm.zero';

my $zero     = decode_docsis slurp('t/data/rt70882/encoded.cm.zero');
my $non_zero = decode_docsis slurp('t/data/rt70882/encoded.cm.non_zero');
my $zero_bin;

$zero->{$_}     = 'MIC' for grep {/Mic/} keys %$zero;
$non_zero->{$_} = 'MIC' for grep {/Mic/} keys %$non_zero;

is_deeply $zero, $non_zero, 'decoded without trailing zero';

$zero_bin = encode_docsis $zero;
like $zero_bin, qr{DataS_U_512k\0}, 'encoded with trailing zero';

done_testing;

sub slurp {
  open my $FH, '<', $_[0];
  local $/;
  readline $FH;
}
