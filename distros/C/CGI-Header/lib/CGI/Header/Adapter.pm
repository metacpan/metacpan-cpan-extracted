package CGI::Header::Adapter;
use strict;
use warnings;
use parent 'CGI::Header';
use Carp qw/croak/;

sub crlf {
    $CGI::CRLF;
}

sub finalize {
    croak 'call to abstract method ', __PACKAGE__, '::finalize';
}

sub as_string {
    my $self    = shift;
    my $query   = $self->query;
    my $crlf    = $self->crlf;
    my $headers = $self->as_arrayref;

    my @lines;

    # add Status-Line required by NPH scripts
    if ( $self->nph or $query->nph ) {
        my $protocol = $query->server_protocol;
        my $status = $self->process_newline( {@$headers}->{'Status'} || '200 OK' );
        push @lines, "$protocol $status$crlf";
    }

    # add response headers
    for ( my $i = 0; $i < @$headers; $i += 2 ) {
        my $field = $headers->[$i];
        my $value = $self->process_newline( $headers->[$i+1] );
        push @lines, "$field: $value$crlf";
    }

    push @lines, $crlf; # add an empty line

    join q{}, @lines;
}

sub process_newline {
    my $self  = shift;
    my $value = shift;
    my $crlf  = $self->crlf;

    # CR escaping for values, per RFC 822:
    # > Unfolding is accomplished by regarding CRLF immediately
    # > followed by a LWSP-char as equivalent to the LWSP-char.
    $value =~ s/$crlf(\s)/$1/g;

    # All other uses of newlines are invalid input.
    if ( $value =~ /$crlf|\015|\012/ ) {
        # shorten very long values in the diagnostic
        $value = substr($value, 0, 72) . '...' if length $value > 72;
        croak "Invalid header value contains a newline not followed by whitespace: $value";
    }

    $value;
}

sub as_arrayref {
    my $self   = shift;
    my $query  = $self->query;
    my %header = %{ $self->header };

    my ( $attachment, $charset, $cookies, $expires, $nph, $p3p, $status, $target, $type )
        = delete @header{qw/attachment charset cookies expires nph p3p status target type/};

    my @headers;

    $nph ||= $query->nph;

    push @headers, 'Server', $query->server_software if $nph;
    push @headers, 'Status', $status if $status;
    push @headers, 'Window-Target', $target if $target;

    if ( $p3p ) {
        my $tags = ref $p3p eq 'ARRAY' ? join ' ', @{$p3p} : $p3p;
        push @headers, 'P3P', qq{policyref="/w3c/p3p.xml", CP="$tags"};
    }

    my @cookies = ref $cookies eq 'ARRAY' ? @{$cookies} : $cookies;
       @cookies = map { $self->_bake_cookie($_) || () } @cookies;

    push @headers, map { ('Set-Cookie', $_) } @cookies;
    push @headers, 'Expires', $self->_date($expires) if $expires;
    push @headers, 'Date', $self->_date if $expires or @cookies or $nph;
    push @headers, 'Pragma', 'no-cache' if $query->cache;

    if ( $attachment ) {
        my $value = qq{attachment; filename="$attachment"};
        push @headers, 'Content-Disposition', $value;
    }

    push @headers, map { ucfirst $_, $header{$_} } keys %header;

    unless ( defined $type and $type eq q{} ) {
        my $value = $type || 'text/html';
        $charset = $query->charset if !defined $charset;
        $value .= "; charset=$charset" if $charset && $value !~ /\bcharset\b/;
        push @headers, 'Content-Type', $value;
    }

    \@headers;
}

sub _bake_cookie {
    my ( $self, $cookie ) = @_;
    ref $cookie eq 'CGI::Cookie' ? $cookie->as_string : $cookie;
}

sub _date {
    my ( $self, $expires ) = @_;
    CGI::Util::expires( $expires, 'http' );
}

1;

__END__

=head1 NAME

CGI::Header::Adapter - Base class for adapters

=head1 SYNOPSIS

  use parent 'CGI::Header::Adapter';

  sub finalize {
      ...
  }

=head1 DESCRIPTION

This module inherits from L<CGI::Header>, and also adds the following methods
to the class:

=over 4

=item $headers = $header->as_arrayref

Returns an arrayref which contains key-value pairs of HTTP headers.

  $header->as_arrayref;
  # => [
  #     'Content-length' => '3002',
  #     'Content-Type'   => 'text/plain',
  # ]

This method helps you write an adapter for L<mod_perl> or a L<PSGI>
application which wraps your CGI.pm-based application without parsing
the return value of CGI.pm's C<header> method.

=item $header->as_string

Returns the header fields as a formatted MIME header.
If the C<nph> property is set to true, the Status-Line is inserted to
the beginning of the response headers.

=item $header->crlf

Returns the system specific line ending sequence.

=item $header->process_newline

=back

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
