#-*- perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Polipo.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('Data::Polipo') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $p = new Data::Polipo ("t/o3kvmCJ-O2CcW2TH2KebbA==");

is ($p->status, "HTTP/1.1 200 OK");
is ($p->header->content_type, "image/jpeg");
is ($p->header->content_length, 6457);
is ($p->header->x_polipo_body_offset, 1735);
is ($p->header->x_polipo_location,
    "http://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Japanese_Squirrel_edit2.jpg/120px-Japanese_Squirrel_edit2.jpg");

my $fh = $p->open;
isa_ok ($fh, IO::File);

$fh->binmode or die $!;
local $/ = undef;
my $content = <$fh>;
is (length ($content), $p->header->content_length);
