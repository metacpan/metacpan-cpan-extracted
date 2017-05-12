package Class::Can;
use strict;
use warnings;
use Class::ISA;
use Devel::Symdump;
our $VERSION = 0.01;

=head1 NAME

Class::Can - inspect a class/method and say what it can do (and why)

=head1 SYNOPSIS

  use Class::Can;
  print Dumper { Class::Can->interrogate( 'Class::Can' ) };
  __END__
  $VAR1 = {
            'interrogate' => 'Class::Can'
  };

=head1 DESCRIPTION

Class::Can interrogates the object heirarchy of a package to return a
hash detailling what methods the class could dispatch (as the key),
and the package it found it in (as the value).

=cut

sub interrogate {
    my ($self, $class) = @_;
    my %can;
    for my $package (reverse Class::ISA::self_and_super_path( $class )) {
        my @methods = Devel::Symdump->new( $package )->functions;
        s{.*::}{} for @methods;
        @can{ @methods } = ($package) x @methods;
    }
    return %can;
}

1;

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004 Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Class::ISA, Devel::Symdump

=cut
