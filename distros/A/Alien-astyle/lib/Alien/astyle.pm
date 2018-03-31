use strict;
use warnings;
package Alien::astyle;

our $VERSION = '0.010000';

use base qw( Alien::Base );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::astyle - Find or build astyle, the Artistic Style code formatter

=head1 SYNOPSIS

From a Perl script

 use Alien::astyle;
 use Env qw(@PATH);
 unshift @PATH, Alien::astyle->bin_dir();  # `astyle` command is now in your path

From Alien::Base Build.PL

 use Alien:Base::ModuleBuild;
 my $builder = Module::Build->new(
   ...
   alien_bin_requires => [ 'Alien::astyle' ],
   ...
 );
 $builder->create_build_script;

=head1 DESCRIPTION

This package can be used by other CPAN modules that require astyle.

=head1 AUTHOR

William N. Braswell, Jr. <wbraswell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by William N. Braswell, Jr.;

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
