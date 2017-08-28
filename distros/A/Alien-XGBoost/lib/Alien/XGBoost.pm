package Alien::XGBoost;
use strict;
use warnings;

use base qw( Alien::Base );

our $VERSION = '0.04';    # VERSION

# ABSTRACT: Alien package to find, and build if necessary XGBoost dynamic library

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Alien::XGBoost - Alien package to find, and build if necessary XGBoost dynamic library

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use Alien::XGBoost;
    use FFI::Platypus;

    my $ffi = FFI::Platypus->new;
    $ffi->lib(Alien::XGBoost->dynamic_libs);
    $ffi->attach(XGBGetLastError => [] => 'string');
    my $error = XGBGetLastError();

=head1 DESCRIPTION

Alien package to find, and build if necessary XGBoost dynamic library.

This module is to be used by other modules that need the XGBoost
dynamic library available, indeed I've made this for L<AI::XGBoost>.

If you only want to use XGBoost in your perl programns, just use
L<AI::XGBoost> and forget this module. If you want to make other XGBoost
wrappers or use from XS then continue reading.

By now there is no support for compiling your modules against XGBoost.
Just using the dynamic library via L<FFI::Platypus> or L<NativeCall>.

=head2 Troubleshooting

The "instructions" to build and install as a module are in the L<alienfile>.

Lots of things can go wrong, and in that case, I'm glad to help, just open an
issue L<https://github.com/pablrod/p5-Alien-XGBoost>.

But this information could be useful:

=over 4

=item Downloading

XGBoost doesn't make releases often L<https://github.com/dmlc/xgboost/releases> (last one from 2016)
So I'm cloning branch master.

XGBoost uses git modules, so I need a recursive clone.

=item Installing

XGBoost cmake doesn't provide a install target for the generated Makefiles, so this module
is copying the dynamic library and the xgboost command to the module share dir

If installation is succesfull you can query the module L<Alien::XGBoost> to know where is 
the dynamic library and command in your system

=back

=head1 SEE ALSO

=over 4

=item L<https://github.com/dmlc/xgboost>

=item L<Alien::Build>

=item L<alienfile>

=item L<AI::XGBoost>

=item L<FFI::Platypus>

=item L<NativeCall>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Graham Ollis <plicease@cpan.org> for all the support and making so many great modules
that make easier to make Alien's:

=over 4

=item L<Alien::Build>

=item L<Alien::Build::Plugin::Build::CMake>

=item L<FFI::CheckLib>

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017 by Pablo Rodríguez González.

=cut
