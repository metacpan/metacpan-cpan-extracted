package Alien::SmokeQt;

=head1 NAME

Alien::SmokeQt

=head1 SYNOPSIS

    use Alien::SmokeQt;

    my $prefix  = Alien::SmokeQt->prefix;
    my $include = Alien::SmokeQt->include;
    my $lib     = Alien::SmokeQt->lib;
    my $ver     = Alien::SmokeQt->ver;

=head1 DESCRIPTION

This module takes care of detecting configuration settings of the SmokeQt
library.

=cut

use strict;
use warnings;

use File::Spec;

our $VERSION = '4.6.0';

my $prefix;

sub prefix {
    return $prefix if $prefix;

    my $ext = '.pm';
    $prefix = join '/', split '::', __PACKAGE__;
    $prefix = File::Spec->rel2abs( $INC{$prefix.$ext} );
    $prefix =~ s/$ext$//;
    
    return $prefix;
}

sub lib {
    my $class = shift;
    File::Spec->catdir( $class->prefix, 'lib' );
}

sub include {
    my $class = shift;
    File::Spec->catdir( $class->prefix, 'include' );
}

sub version {
    return $VERSION;
}

1;
