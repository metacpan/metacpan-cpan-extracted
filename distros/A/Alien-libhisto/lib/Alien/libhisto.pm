package Alien::libhisto;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Base );

our $VERSION = '0.2.0';


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Alien::libhisto - Find or build libhisto fast C histogramming library

=head1 SYNOPSIS

In your C<Makefile.PL>:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper qw( Alien::libhisto !export );

 WriteMakefile(
   Alien::Base::Wrapper->mm_args2(
     NAME => 'My::Module',
     ...
   ),
 );

In your FFI script:

 use FFI::Platypus 2.00;
 use Alien::libhisto;

 my $ffi = FFI::Platypus->new( api => 2 );
 $ffi->lib( Alien::libhisto->dynamic_libs );
 $ffi->attach( histo_version => [] => 'string' );
 print histo_version();

=head1 DESCRIPTION

C<Alien::libhisto> provides the C<libhisto> C histogramming, curve-fitting,
and streaming quantile sketch library for use by Perl XS and FFI modules.

It probes for an existing installation of C<libhisto> via C<pkg-config>. If not
found, it builds C<libhisto> from source using CMake and installs it into Perl's
shared distribution directory.

=head1 SEE ALSO

=over 4

=item * L<Math::Histo>

=item * L<Alien::Build>

=item * L<Alien::Base>

=back

=head1 AUTHOR

Steffen Mueller E<lt>cpan@steffen-mueller.netE<gt>

=head1 LICENSE

MIT License.

=cut
