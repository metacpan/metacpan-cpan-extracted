package Alien::Proj4;

use strict;
use warnings;
use parent qw( Alien::Base );

our $VERSION = '2.019107';

#  most of the following are for compat with PDLA Makefiles
#  and should not be used by other code
sub installed {1}

sub import {
    #  do nothing
    return;
}

sub default_lib {
    return;
}

sub default_inc {
    return;
}

sub libflags {
    my ($class) = @_;
    my $flags = join ' ',  $class->libs;
    return $flags;
}

sub incflags {
    my ($class) = @_;
    my $flags = $class->cflags;
    return $flags;
}

# dup of code currently in PDLA::GIS::Proj
sub load_projection_descriptions {
  my ($class) = @_;
  my $incflags = $class->cflags;
  my $libflags = $class->libs;
  
  require Inline;
  Inline->bind(C => <<'EOF', inc => $incflags, libs => $libflags) unless defined &list_projections;
#include "projects.h"
HV *list_projections() {
  struct PJ_LIST *lp;
  SV* scalar_val;
  HV *hv = newHV();
  for (lp = pj_get_list_ref() ; lp->id ; ++lp) {
      scalar_val  = newSVpv( *lp->descr, 0 );
      hv_store( hv, lp->id, strlen( lp->id ), scalar_val, 0 );
  }
  return hv;
}
EOF
  list_projections();
}

# dup of code currently in PDLA::GIS::Proj
sub load_projection_information {
    my ($class) = @_;
    my $descriptions = $class->load_projection_descriptions();
    my $info = {};
    foreach my $projection ( keys %$descriptions ) {
        my $description = $descriptions->{$projection};
        my $hash = {};
        $hash->{CODE} = $projection;
        my @lines = split( /\n/, $description );
        chomp @lines;
        # Full name of this projection:
        $hash->{NAME} = $lines[0];
        # The second line is usually a list of projection types this one is:
        my $temp = $lines[1];
        $temp =~ s/no inv\.*,*//;
        $temp =~ s/or//;
        my @temp_types = split(/[,&\s]/, $temp );
        my @types = grep( /.+/, @temp_types );
        $hash->{CATEGORIES} = \@types;
        # If there's more than 2 lines, then it usually is a listing of parameters:
        # General parameters for all projections:
        $hash->{PARAMS}->{GENERAL} =
            [ qw( x_0 y_0 lon_0 units init no_defs geoc over ) ];
        # Earth Figure Parameters:
        $hash->{PARAMS}->{EARTH} =
            [ qw( ellps b f rf e es R R_A R_V R_a R_g R_h R_lat_g ) ];
        # Projection Specific Parameters:
        my @proj_params = ();
        if( $#lines >= 2 ) {
            foreach my $i ( 2 .. $#lines ) {
                my $text = $lines[$i];
                my @temp2 = split( /\s+/, $text );
                my @params = grep( /.+/, @temp2 );
                foreach my $param (@params) {
                    $param =~ s/=//;
                    $param =~ s/[,\[\]]//sg;
                    next if $param =~ /^and|or|Special|for|Madagascar|fixed|Earth|For|CH1903$/;
                    push(@proj_params, $param);
                }
            }
        }
        $hash->{PARAMS}->{PROJ} = \@proj_params;
        # Can this projection do inverse?
        $hash->{INVERSE} = ( $description =~ /no inv/ ) ? 0 : 1;
        $info->{$projection} = $hash;
    }
    # A couple of overrides:
    $info->{ob_tran}->{PARAMS}->{PROJ} =
        [ 'o_proj', 'o_lat_p', 'o_lon_p', 'o_alpha', 'o_lon_c',
          'o_lat_c', 'o_lon_1', 'o_lat_1', 'o_lon_2', 'o_lat_2' ];
    $info->{nzmg}->{CATEGORIES} = [ 'fixed Earth' ];
    return $info;
}


1;

__END__

=head1 NAME

Alien::Proj4 - Compile the PROJ library, version 4

=head1 BUILD STATUS
 
=begin HTML
 
<p>
    <img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
    <a href="https://travis-ci.org/shawnlaffan/perl-alien-proj4"><img src="https://travis-ci.org/shawnlaffan/perl-alien-proj4.svg?branch=master" /></a>
    <a href="https://ci.appveyor.com/project/shawnlaffan/perl-alien-proj4"><img src="https://ci.appveyor.com/api/projects/status/3lv9qu9ea2ex3p5d?svg=true" /></a>
</p>

=end HTML

=head1 SYNOPSIS

    use Alien::Proj4;

    
=head1 DESCRIPTION

PROJ is a generic coordinate transformation software.  See L<https://proj4.org/about.html>.

This Alien package is probably most useful for compilation of other modules, e.g. L<PDLA::Rest>.

This is a fork of the main L<Alien::proj>, but with the major version fixed to 4.
Later versions of the proj code have changed their API, so this ensure stability until
dependent projects have updated.  

The Proj library can be accessed from Perl code via the L<Geo::Proj4> package.  

=head1 REPORTING BUGS

Please send any bugs, suggestions, or feature requests to 
L<https://github.com/PDLPorters/Alien-Proj4/issues>.

=head1 SEE ALSO

L<Alien::proj>

L<Geo:Proj4>

L<Geo::GDAL::FFI>

L<Alien::geos::af>


=head1 AUTHORS

Shawn Laffan, E<lt>shawnlaffan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE


Copyright 2018- by Shawn Laffan


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
