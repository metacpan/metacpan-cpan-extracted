package APR::HTTP::Headers::Compat;

use warnings;
use strict;

use Carp;
use APR::HTTP::Headers::Compat::MagicHash;

use base qw( HTTP::Headers );

=head1 NAME

APR::HTTP::Headers::Compat - Make an APR::Table look like an HTTP::Headers

=head1 VERSION

This document describes APR::HTTP::Headers::Compat version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use APR::HTTP::Headers::Compat;

  # We're running under mod_perl2...
  my $hdrs = APR::HTTP::Headers::Compat->new( $r->headers_out );

  # Now we can treat $hdrs as if it was an HTTP::Headers
  $hdrs->header( 'Content-Type' => 'text/plain' );

=head1 DESCRIPTION

Under mod_perl HTTP headers are stashed in L<APR::Table> objects.
Sometimes you will encounter code (such as L<FirePHP::Dispatcher>) that
needs an L<HTTP::Headers>. This module wraps an C<APR::Table> in a
subclass of C<HTTP::Headers> so that it can be used wherever an
C<HTTP::Headers> is expected.

Synchronisation is bi-directional; changes via the C<HTTP::Headers>
interface are reflected immediately in the underlying C<APR::Table> and
direct changes to the table show up immediately in the wrapper.

=head1 INTERFACE 

Unless otherwise stated below all methods are inherited from
C<HTTP::Headers>.

=head2 C<< new >>

Create a new wrapper around an existing C<APR::Table>.

  # Normally you'll be given the table - we're creating one here for the
  # sake of the example
  my $table = APR::Table::make( APR::Pool->new, 1 );

  # Wrap the table so it can be used as an HTTP::Headers instance
  my $h = APR::HTTP::Headers::Compat->new( $table );

Optionally header initialisers may be passed:

  my $h = APR::HTTP::Headers::Compat->new( $table,
    'Content-type' => 'text/plain'
  );

=cut

sub new {
  my ( $class, $table ) = ( shift, shift );
  my %self = %{ $class->SUPER::new( @_ ) };
  tie %self, 'APR::HTTP::Headers::Compat::MagicHash', $table, %self;
  return bless \%self, $class;
}

sub _magic { tied %{ shift() } }

=head2 C<< clone >>

Clone this object. The clone is a regular L<HTTP::Headers> object rather
than an C<APR::HTTP::Headers::Compat>.

=cut

sub clone { bless { %{ shift() } }, 'HTTP::Headers' }

=head2 C<< table >>

Get the underlying L<APR::Table> object. Changes made in either the
table or the wrapper are reflected immediately in the other.

=cut

sub table { shift->_magic->table }

=head2 C<< remove_content_headers >>

This will remove all the header fields used to describe the content of a
message. All header field names prefixed with Content- falls into this
category, as well as Allow, Expires and Last-Modified. RFC 2616 denote
these fields as Entity Header Fields.

The return value is a new C<HTTP::Headers> object that contains the
removed headers only. Note that the returned object is I<not> an
C<APR::HTTP::Headers::Compat>.

=cut

sub remove_content_headers {
  my $self = shift;

  return $self->SUPER::remove_content_headers( @_ )
   unless defined wantarray;

  # This gets nasty. We downbless ourself to be an HTTP::Headers so that
  # when HTTP::Headers->remove_content_headers does
  #
  #   my $c = ref( $self )->new
  #
  # it creates a new HTTP::Headers instead of attempting to create a
  # new APR::HTTP::Headers::Compat.

  my $class = ref $self;
  bless $self, 'HTTP::Headers';
  
  # Calls SUPER::remove_content_headers due to rebless
  my $other = $self->remove_content_headers( @_ );
  bless $self, $class;

  # Return a non-magic HTTP::Headers
  return $other;
}

1;
__END__

=head1 CAVEATS

Because the underlying storage for the headers is an C<APR::Table>
attempts to store an object (such as a L<URI> instance) in the table
will not behave as expected.

I haven't benchmarked but it's certain that this implementation will be
substantially slower than C<HTTP::Headers>.

=head1 DEPENDENCIES

L<APR::Pool>, L<APR::Table>, L<HTTP::Headers>, L<Storable>, L<Test::More>

=head1 SEE ALSO

L<FirePHP::Dispatcher>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-apr-http-headers-compat@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
