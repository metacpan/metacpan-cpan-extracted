BEGIN { $ENV{DOCSIS_CAN_TRANSLATE_OID} = 0; }
use warnings;
use strict;
use Test::More;
use File::Spec::Functions 'catfile';
use DOCSIS::ConfigFile qw( encode_docsis decode_docsis );

my $zero     = decode_docsis \catfile qw( t data rt70882 encoded.cm.zero );
my $non_zero = decode_docsis \catfile qw( t data rt70882 encoded.cm.non_zero );
my $zero_bin;

@$zero{qw( CmMic CmtsMic )}     = ('0xDUMMY') x 2;
@$non_zero{qw( CmMic CmtsMic )} = ('0xDUMMY') x 2;
is_deeply $zero, $non_zero, 'decoded without trailing zero';

$zero_bin = encode_docsis $zero;
like $zero_bin, qr{DataS_U_512k\0}, 'encoded with trailing zero';

done_testing;
