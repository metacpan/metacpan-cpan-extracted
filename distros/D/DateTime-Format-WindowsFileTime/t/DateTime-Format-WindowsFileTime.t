use Test::More tests => 2;
BEGIN { use_ok('DateTime::Format::WindowsFileTime') };

my $dt = DateTime::Format::WindowsFileTime->parse_datetime( '01C4FA8464623000' );
is("$dt",'2005-01-14T22:00:00');
