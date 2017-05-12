package Alien::V8;

use strict;
use warnings;

use File::ShareDir qw(dist_dir);
use File::Spec;

our $VERSION = '0.03';

sub incdir {
    my $class = shift;
    
    return File::Spec->catdir(
        dist_dir("Alien-V8"),
        "include"
    );
}

sub libdir {
    my $class = shift;
    
    return File::Spec->catdir(
        dist_dir("Alien-V8"),
        "lib"
    );
}

1;

__END__

=head1 NAME

Alien::V8 - Builds and installs the V8 JavaScript engine

=head1 SYNOPSIS

    use Alien::V8;
    
    # Where to find "v8.h"
    my $incdir = Alien::V8->incdir();
    
    # Where to v8 shared library (i.e.: libv8.so, libv8.dylib, ...)
    my $libdir = Alien::V8->libdir();

=head1 AUTHORS

  Remy Chibois <rchibois at gmail dot com>

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2011 Remy Chibois

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut