#########################
use strict;
use warnings;
use Test::More tests => 7;
BEGIN { use_ok('D64::File::PRG') };
#########################
{
my $data = join ('', map {chr} (0x41,0x42,0x43));
my $prog = D64::File::PRG->new('RAW_DATA' => \$data, 'LOADING_ADDRESS' => 0x5A59);
my $raw  = $prog->get_data('LOAD_ADDR_INCL' => 1);
is ($raw, 'YZABC', 'accessing raw data with loading address');
}
#########################
{
my $data = join ('', map {chr} (0x44,0x45,0x46));
my $prog = D64::File::PRG->new('RAW_DATA' => \$data, 'LOADING_ADDRESS' => 0x5A59);
my $raw  = $prog->get_data('LOAD_ADDR_INCL' => 0);
is ($raw, 'DEF', 'accessing raw data without loading address');
}
#########################
{
my $data = join ('', map {chr} (0x47,0x48,0x49));
my $prog = D64::File::PRG->new('RAW_DATA' => \$data, 'LOADING_ADDRESS' => 0x5A59);
$prog->change_loading_address('LOADING_ADDRESS' => 0x5857);
my $raw  = $prog->get_data('LOAD_ADDR_INCL' => 1);
is ($raw, 'WXGHI', 'modifying data loading address');
}
#########################
{
my $data = join ('', map {chr} (0x4a,0x4b,0x4c));
my $prog = D64::File::PRG->new('RAW_DATA' => \$data, 'LOADING_ADDRESS' => 0x5A59);
my $src  = $prog->get_data('FORMAT' => 'ASM');
( my $line = (split /\n/, $src)[3] ) =~ s/^\s*(.*?)\s*$/$1/;
is ($line, '.byte $4a, $4b, $4c', 'assembly source code output correctness');
}
#########################
{
my $data = join ('', map {chr} (0x4d,0x4e,0x4f));
my $prog = D64::File::PRG->new('RAW_DATA' => \$data, 'LOADING_ADDRESS' => 0x5A59);
my $src  = $prog->get_data('FORMAT' => 'ASM', 'ROW_LENGTH' => 2);
( my $line = (split /\n/, $src)[3] ) =~ s/^\s*(.*?)\s*$/$1/;
is ($line, '.byte $4d, $4e', 'assembly source code output formatting');
}
#########################
{
my $data = join ('', map {chr} (0x50,0x0d,0x0a,0x0a,0x0d,0x51));
my $prog = D64::File::PRG->new('RAW_DATA' => \$data, 'LOADING_ADDRESS' => 0x5A59);
my $raw  = $prog->get_data('LOAD_ADDR_INCL' => 0);
$raw = join ('', map { sprintf "%c", (ord $_ | 0x50) } (split //, $raw));
is ($raw, 'P]ZZ]Q', 'handling binary data correctly');
}
#########################
