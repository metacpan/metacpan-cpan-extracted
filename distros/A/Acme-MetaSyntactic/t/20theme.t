use strict;
use Test::More;
use File::Spec::Functions;
my $dir;
BEGIN { $dir = catdir qw( t lib ); }
use lib $dir;
use Acme::MetaSyntactic;

plan tests => 15;

my @bots = qw( purl url sarko bender );
my $meta = Acme::MetaSyntactic->new( 'bots' );

# existing themes
my @themes = Acme::MetaSyntactic->themes;

# try has_theme
ok( !Acme::MetaSyntactic->has_theme( ), "has no theme?" );
ok( Acme::MetaSyntactic->has_theme( 'test_ams_list' ), "has test_ams_list" );
ok( ! Acme::MetaSyntactic->has_theme( 'bots' ), "but no bots" );

# try to overwrite a theme
eval { Acme::MetaSyntactic->add_theme( test_ams_list => [ @bots ] ); };
like( $@, qr/^The theme test_ams_list already exists!/, "Do not overwrite a theme" );

# try badnames
eval { Acme::MetaSyntactic->add_theme( zlonk => [ qw( 123 bam $c ) ] ); };
like( $@, qr/^Invalid names \(123 \$c\) for theme zlonk/, "Bad names" );

# yep, you can add the theme after creating the instance
Acme::MetaSyntactic->add_theme( bots => [ @bots ] );

ok( Acme::MetaSyntactic->has_theme( 'bots' ), "has bots now" );

my @names = $meta->name;
is( scalar @names, 1, "name() returned a single item" );

push @names, $meta->name(3);
is( scalar @names, 4, "name( 3 ) returned three more items" );

my %seen = map { $_ => 1 } @names;
is_deeply( \%seen, { map { $_ => 1 } @bots }, "Got the whole list");

# the new method exists
$meta = Acme::MetaSyntactic->new( 'test_ams_list' );
@names = $meta->name( bots => 2 );
ok( exists( $seen{$_} ), "the name() method accepts bots" ) for @names;

# and the new function exists as well
$meta = Acme::MetaSyntactic->new( 'test_ams_list' );
@names = metabots( 2 );
ok( exists( $seen{$_} ), "the metabots() function" ) for @names;

is_deeply( [ sort @themes, "bots" ], [ Acme::MetaSyntactic->themes ],
  "Themes list updated" );

is(
    scalar Acme::MetaSyntactic->themes,
    scalar @{ [ Acme::MetaSyntactic->themes ] },
    "themes() works in scalar context"
);
