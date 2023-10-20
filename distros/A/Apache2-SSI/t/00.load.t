#!perl
# t/00.load.t - check module loading and create testing directory
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG @modules );
    use Test::More qw( no_plan );
    our @modules;
    use Module::Generic::File qw( file );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use strict;
    use warnings;
    my $lib = file( './lib' );
    $lib->find(sub
    {
        return(1) unless( $_->extension eq 'pm' );
        diag( "Checking file '$_'" ) if( $DEBUG );
        my $base = $_->relative( $lib );
        $base =~ s,\.pm$,,;
        $base =~ s,/,::,g;
        push( @modules, $base );
    });
    use_ok( $_ ) for( sort( @modules ) );
};

use strict;
use warnings;

my $object = Apache2::SSI->new(
    debug => 0,
    document_uri => '../index.html?q=something&l=en_GB',
    document_root => './t/htdocs',
) || BAIL_OUT( Apache2::SSI->error );
isa_ok( $object, 'Apache2::SSI' );

done_testing();

# To generate the list of modules:
# for m in `find ./lib -type f -name "*.pm"`; do echo $m | perl -pe 's,./lib/,,' | perl -pe 's,\.pm$,,' | perl -pe 's/\//::/g' | perl -pe 's,^(.*?)$,use_ok\( "$1" \)\;,'; done

__END__

r