#!perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

use Astro::XSPEC::Model::Parse;

use IO::File;
use File::Temp;
use Data::Dumper;

my %udata;

sub model {

    my ( $event, $model, $args ) = @_;

    if ( $event eq 'start' )
    {
        my %current = ( model => $model, pars => [] );

        $args->{_current} = \%current;
        $args->{models} ||= [];
        push @{$args->{models}}, \%current;
    }

    else
    {
        dump_model( $args->{fh}, $args->{models}[-1], scalar @{$args->{models}} );
    }

    return 1;
}

sub par { 

    my ( $info, $args ) = @_;

    my $model = $args->{_current};

    push @{$model->{pars}}, $info;

    return 1;
}

sub par_rec {

    return join( ' ', 
                 map { m{(^\s*$)|(\s+)|(km/s|r_s)} ? qq["$_"] : $_ } 
                 grep { defined $_ } 
                 @_ );
}

sub dump_model { 

    my ( $fh, $info, $n ) = @_;

    my $model = $info->{model};

    $fh->print( "\n" )
        if $n > 1;

    $fh->print( par_rec( @{$model}{ qw[ name npars elo ehi subname 
                                     type calcvar forcecalc ] } )
                , "\n" );

    for my $par ( @{ $info->{pars} } )
    {
        if ( $par->{type} eq 'scale' )
        {
            $fh->print( '*' , par_rec( @{$par}{qw[ name units value ] }), "\n" );
        }
        elsif ( $par->{type} eq 'switch' )
        {
            $fh->print( '$', par_rec( @{$par}{ qw[ name units value hard_min
                                 soft_min soft_max hard_max delta ] } ), "\n" );
        }
        else
        {
            $fh->print( 
                par_rec( @{$par}{ qw[ name units value hard_min soft_min soft_max 
                              hard_max delta periodic ] } ), "\n" );
        }
    }

    $fh->flush;
}

sub diff {

    my ( $exp, $res ) = 
        map { 
            local $/ = undef;
            my $fh = IO::File->new( $_ ) or die( "unable to open $_\n" ); 
            my $d = $fh->getline;
            $d =~ s/\s+/ /g;
            $d
    } @_;

    return $exp eq $res;
}

my $parser = Astro::XSPEC::Model::Parse->new( model => { start => \&model,
                                                         end => \&model,
                                              },
                                              par => \&par,
                                              args => \%udata
    );


for my $model_dat ( <data/*.dat> )
{
    %udata = ();
    $udata{fh} = File::Temp->new;
    $parser->parse_file( $model_dat );
    ok( diff( $model_dat, $udata{fh}->filename ), $model_dat );
}
