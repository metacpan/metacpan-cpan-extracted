use Test::More tests => 6;
use strict;
use warnings;
use FindBin;


BEGIN { use_ok 'Crypt::Keyczar::FileReader' }

my $reader = Crypt::Keyczar::FileReader->new("$FindBin::Bin/data/filereader");
ok($reader);

ok($reader->get_metadata() eq "This is test meta data file.\n");
ok($reader->get_key(1) eq "hello world!\n");
ok($reader->get_key(2) eq "hello secure world!\n");
eval { $reader->get_key(3) };
ok($@);
