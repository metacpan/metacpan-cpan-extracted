# -*- perl -*-
BEGIN
{
    use strict;
    use lib './lib';
    # use Test2::V0;
    use Test::More;
    use Module::Generic::File qw( file );
    # use Test::More qw( no_plan );
    # use File::Find;
    our @modules;
    my $lib = file( './lib' );
    $lib->find(sub
    {
        return unless( /\.pm$/ );
        # print( "Checking file '$_' ($File::Find::name) -> ", overload::StrVal( $_ ), "\n" );
        # $_ = $File::Find::name;
        $_ = $_->extension( '' );
        my $rel = $_->relative( $lib );
        $rel =~ s,/,::,g;
        # $rel->extension( undef );
        push( @modules, $rel );
    });
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    diag( "Checking module $_" ) if( $DEBUG );
    use_ok( $_ ) for( sort( @modules ) );
};

done_testing();

# To generate the list of modules:
# for m in `find ./lib -type f -name "*.pm"`; do echo $m | perl -pe 's,./lib/,,' | perl -pe 's,\.pm$,,' | perl -pe 's/\//::/g' | perl -pe 's,^(.*?)$,use_ok\( "$1" \)\;,'; done
