#!perl
BEGIN
{
	use strict;
	use warnings;
	use lib './lib';
	use Scalar::Util ();
    use Test::More qw( no_plan );
    use_ok( 'DB::Object' );
	our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

my $dbh = DB::Object->new( debug => $DEBUG );
isa_ok( $dbh, 'DB::Object' );
my $p = $dbh->P( type => 'inet', value => '127.0.0.1' );
isa_ok( $p, 'DB::Object::Placeholder' );
can_ok( $p, 'replace' );
can_ok( $p, 'type' );
can_ok( $p, 'value' );
my $addr = Scalar::Util::refaddr( $p );
my $q = "SELECT * FROM ip_registry WHERE ip_addr = inet($p) OR inet($p) << ip_addr";
is( $q, "SELECT * FROM ip_registry WHERE ip_addr = inet(__PLACEHOLDER__${addr}__) OR inet(__PLACEHOLDER__${addr}__) << ip_addr", 'query string with placeholder objects' );
my $types = $p->replace( \$q );
isa_ok( $types, 'Module::Generic::Array' );
SKIP:
{
    if( !defined( $types ) )
    {
        skip( 'failed replace', 3 );
    }
    is( $types->length, 2, '2 placeholders found' );
    is( $types->first, 'inet', 'placeholder data type' );
    is( $q, "SELECT * FROM ip_registry WHERE ip_addr = inet(?) OR inet(?) << ip_addr", 'processed query' );
};

done_testing();

__END__

