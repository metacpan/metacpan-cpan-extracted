#! perl

use Test2::V0;
use Test::TempDir::Tiny;
use File::Path;
use File::Spec::Functions 'rel2abs';
use CIAO::Lib::Param ':all';


use constant PFILE => 'surface_intercept';
use constant PARAM => rel2abs( 'param' );

#--------------------------------------------------------
sub pnames {
    my ( $filename ) = @_;

    open my $fh, '<', $filename
      or die( "unable to open $filename!\n" );

    my @pnames;
    while ( <$fh> ) {
        next if /^\#/;
        my @l = split( /,/ );
        $l[3] =~ s/^"//;
        $l[3] =~ s/"$//;
        push @pnames,
          {
            name  => $l[0],
            type  => $l[1],
            value => $l[3] };
    }

    @pnames;
}

use constant PNAMES => pnames( rel2abs( PFILE . '.par', PARAM ) );


in_tempdir 'test' => sub {

    local $ENV{PFILES} = 'tmp;' . PARAM;
    mkdir( 'tmp', 0755 );

    subtest 'get' => sub {
        my $pf;
        my $value;

        # check for non-existent parameter file
        like( dies { $pf = CIAO::Lib::Param->new( 'foo.par' ) }, qr/parameter file not found/, );

        ok( lives { $pf = CIAO::Lib::Param->new( PFILE, 'rH' ) } )
          or bail_out( $@ );

        is( $pf->get( 'dfm2_filename' ), 'perfect.DFR', 'get' );

        # check out pmatch
        {
            my @lnames = PNAMES;
            my $pm     = $pf->match( q{*} );

            while ( my $pname = $pm->next ) {
                my $lname = ( shift @lnames )->{name};
                is( $pname, $lname, "pnext: $lname" );
            }
        }
    };


    subtest 'two filename new' => sub {

        subtest '[filename, undef]' => sub {
            my $pf;
            ok( lives { $pf = CIAO::Lib::Param->new( [ PFILE, undef ], 'rH' ); } )
              or bail_out( $@ );

            is( $pf->get( 'onlygoodrays' ), T() );
        };

        subtest '[undef, filename]' => sub {
            my $pf;
            ok( lives { $pf = CIAO::Lib::Param->new( [ undef, PFILE ], 'rH' ); } )
              or bail_out( $@ );
            is( $pf->get( 'onlygoodrays' ), T() );
        };

    };


    subtest 'new with arguments' => sub {

        my $pf;
        ok( lives { $pf = CIAO::Lib::Param->new( PFILE, 'rH', 'help+' ); } )
          or bail_out( $@ );
        is( $pf->get( 'help' ), T(), 'command line set' );
    };


    subtest 'pget' => sub {

        my %list = pget( PFILE );

        for my $par ( PNAMES ) {

            my $value
              = $par->{type} eq 's' ? $par->{value}
              : $par->{type} eq 'b' ? { yes => T(), no => F() }->{ $par->{value} }
              :                       number( $par->{value} );

            is( $list{ $par->{name} }, $value, $par->{name} );
        }
    };

    subtest 'super long parameter value' => sub {
        my $pfile = 'acis_bkgrnd_lookup';
        open my $fh, '<', rel2abs( "$pfile.par", PARAM )
          or die( "error opening $pfile\n" );
        my $outfile;
        while ( !defined( $outfile ) && defined( my $line = <$fh> ) ) {
            ( $outfile ) = $line =~ /^outfile,f,h,"([^"]+)"/;
        }

        die( "couldn't parse $pfile\n" )
          if !defined $outfile;
        $fh->close;
        is( pget( $pfile, 'outfile' ), $outfile, 'pget long value' );

        my $pf;
        ok( lives { $pf = CIAO::Lib::Param->new( 'acis_bkgrnd_lookup' ) } ) or bail_out( $@ );
        is( $pf->getstr( 'outfile' ), $outfile, 'pgetstr long value' );
    };


    subtest 'pset of a single value' => sub {
        ok( lives { pset( PFILE, input => 'SnackFud' ); } ) or bail_out( $@ );
    };

    subtest 'pget of a single value' => sub {
        is( pget( PFILE, 'input' ), 'SnackFud' );
    };

    subtest 'pset of multiple values' => sub {
        ok( lives { pset( PFILE, input => 'YoMama', output => 'YoDaddy' ); } ) or bail_out( $@ );
    };

    subtest 'pget of multiple values' => sub {
        my @values;
        ok(
            lives {
                @values = pget( PFILE, qw/ input output / );
            } ) or bail_out( $@ );

        is( \@values, array { item 'YoMama'; item 'YoDaddy'; end; } );
    };

    subtest 'check if command line arguments work with pget' => sub {
        my $value;
        ok( lives { $value = pget( PFILE, ['help+'], 'help' ) } ) or bail_out( $@ );
        is( $value, T() );
    };

};


done_testing;
