use Test::More tests => 2;

BEGIN { use_ok( 'DateTime::Format::Bork' ); }

my $object = DateTime::Format::Bork->new ();
isa_ok ($object, 'DateTime::Format::Bork');
