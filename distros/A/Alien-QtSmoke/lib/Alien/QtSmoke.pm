package Alien::QtSmoke;

=head1 NAME

Alien::QtSmoke

=head1 SYNOPSIS

    use Alien::QtSmoke;

    my $prefix  = Alien::QtSmoke->prefix;
    my $include = Alien::QtSmoke->include;
    my $lib     = Alien::QtSmoke->lib;
    my $ver     = Alien::QtSmoke->ver;

=head1 DESCRIPTION

This module takes care of detecting configuration settings of the QtSmoke
library.

=cut

use strict;
use warnings;

use File::Spec;

our $VERSION = '4.3.3';

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
    return '4.3.3';
}

1;
