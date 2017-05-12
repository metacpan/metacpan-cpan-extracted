use warnings;
use strict;
use Test::More;
use DOCSIS::ConfigFile qw(encode_docsis decode_docsis);

plan skip_all => 'cannot find tos.bin' unless -e 't/data/tos.bin';

my $tos = decode_docsis slurp('t/data/tos.bin');
eval { encode_docsis($tos) };

# Used to be: [DOCSIS] IpTos is too long. (0x3030ff) at /Users/jhthorsen/git/_old/docsis-configfile/lib/DOCSIS/ConfigFile.pm line 317.
ok !$@, "Able to encode IpTos 0x3030ff ($@)";

done_testing;

sub slurp {
  open my $FH, '<', $_[0];
  local $/;
  readline $FH;
}
