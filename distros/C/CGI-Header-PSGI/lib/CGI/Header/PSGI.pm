package CGI::Header::PSGI;
use 5.008_009;
use strict;
use warnings;
use parent 'CGI::Header::Adapter';
use Carp qw/croak/;

our $VERSION = '0.62001';

sub status {
    my $self = shift;
    return $self->{status} unless @_;
    $self->{status} = shift;
    $self;
}

sub has_status {
    exists $_[0]->{status};
}

sub status_code {
    my $self = shift;
    my $code = $self->has_status ? $self->status : '200';
    $code =~ s/\D*$//;
    $code;
}

sub finalize {
    my $self    = shift;
    my $status  = $self->status_code;
    my $headers = $self->as_arrayref;

    for ( my $i = 1; $i < @$headers; $i += 2 ) {
        $headers->[$i] = $self->process_newline( $headers->[$i] );
    }

    $status, $headers;
}

1;

__END__

=head1 NAME

CGI::Header::PSGI - Generate PSGI-compatible response header arrayref

=head1 SYNOPSIS

  use CGI::PSGI;
  use CGI::Header::PSGI;

  my $app = sub {
      my $env    = shift;
      my $query  = CGI::PSGI->new( $env );
      my $header = CGI::Header::PSGI->new( query => $query );
        
      my $body = do {
          # run CGI.pm-based application
      };

      return [
          $header->finalize,
          [ $body ]
      ];
  };

=head1 VERSION

This document refers to CGI::Header::PSGI 0.54001.

=head1 DESCRIPTION

This module can be used to convert CGI.pm-compatible HTTP header properties
into L<PSGI> response header array reference. 

This module requires your query class is orthogonal to a global variable
C<%ENV>. For example, L<CGI::PSGI> adds the C<env>
attribute to CGI.pm, and also overrides some methods which refer to C<%ENV>
directly. This module doesn't solve those problems at all.

=head2 METHODS

This class inherits all methods from L<CGI::Header::Adapter>.

Adds the following methods to the superclass:

=over 4

=item $header->status_code

Returns HTTP status code.

  my $code = $header->status_code; # => 200

=back

Overrides the following method of the superclass:

=over 4

=item ($status_code, $headers) = $header->finalize

Behaves like C<CGI::PSGI>'s C<psgi_header> method.
Return the status code and PSGI header array reference of this response.

  $header->finalize;
  # => (
  #     200,
  #     [ 'Content-Type' => 'text/plain' ]
  # )

=back

=head1 SEE ALSO

L<CGI::Emulate::PSGI>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

