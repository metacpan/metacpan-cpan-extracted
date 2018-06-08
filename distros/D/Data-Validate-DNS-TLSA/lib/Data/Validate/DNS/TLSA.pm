#
# This file is part of Data-Validate-DNS-TLSA
#
# This software is copyright (c) 2018 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

package Data::Validate::DNS::TLSA;
$Data::Validate::DNS::TLSA::VERSION = '0.02';
# ABSTRACT: Validate DNS Transport Layer Security Association (TLSA) Record Values

use strict;
use warnings;

use parent 'Exporter';

use List::Util qw(any);
use Taint::Util qw(untaint);

our @EXPORT_OK = qw(
    is_tlsa_port
    is_tlsa_protocol
    is_tlsa_domain_name
    is_tlsa_selector
    is_tlsa_matching_type
    is_tlsa_cert_usage
    is_tlsa_cert_association);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK);


sub new {
    my $class = shift;
    bless { @_ }, ref $class || $class;
}


sub is_tlsa_port {
    my ($self, $value, %opts) = _maybe_oo(@_);

    $opts{underscore} ||= 0;

    if ($opts{underscore} and substr($value,0,1) ne '_') {
        return;
    }

    (my $port = $value) =~ s/^_//;

    unless ($port =~ /^[1-9][0-9]*$/) {
        return;
    }

    if ($port < 0 or $port > 65535) {
        return;
    }

    untaint($value);

    return $value;
}


sub is_tlsa_protocol {
    my ($self, $value, %opts) = _maybe_oo(@_);

    $opts{underscore} ||= 0;
    $opts{strict}     ||= 0;

    if ($opts{underscore} and substr($value,0,1) ne '_') {
        return;
    }

    (my $proto = $value) =~ s/^_//;

    unless ($proto =~ /^[a-zA-Z]+$/) {
        return;
    }

    if ($opts{strict}) {
        # strict mode, only allow protocols specified in RFC 6698
        unless (any { $_ eq lc($proto) } qw(tcp udp sctp)) {
            return;
        }
    }

    # otherwise, we already checked that its a-Z.
    untaint($value);

    return $value;
}


sub is_tlsa_domain_name {
    my ($self, $value, %opts) = _maybe_oo(@_);

    unless (defined $opts{underscore}) {
        $opts{underscore} = 1;
    }

    my @labels = split /\./, $value;

    if (scalar @labels < 2) {
        return;
    }

    my ($port, $proto) = @labels;

    if (is_tlsa_port($port, %opts) and is_tlsa_protocol($proto, %opts)) {
        untaint($value);
        return $value;
    }

    return;
}


sub is_tlsa_matching_type {
    my ($self, $value, %opts) = _maybe_oo(@_);

    return unless _is_int8($value);

    if ($opts{strict}) {
        # strict mode, only allow registered types
        if (($value >= 0 and $value < 3) or $value == 255) {
            untaint($value);
            return $value;
        }
    }
    else {
        # just a syntax check
        if ($value >= 0 and $value <= 255) {
            untaint($value);
            return $value;
        }
    }

    return;
}


sub is_tlsa_selector {
    my ($self, $value, %opts) = _maybe_oo(@_);

    return unless _is_int8($value);

    if ($opts{strict}) {
        # strict mode, only allow registered selectors
        if (($value >= 0 and $value < 2) or $value == 255) {
            untaint($value);
            return $value;
        }
    }
    else {
        # just a syntax check
        if ($value >= 0 and $value <= 255) {
            untaint($value);
            return $value;
        }
    }

    return;
}


sub is_tlsa_cert_usage {
    my ($self, $value, %opts) = _maybe_oo(@_);

    return unless _is_int8($value);

    if ($opts{strict}) {
        # strict mode, only allow registered values
        if (($value >= 0 and $value < 4) or $value == 255) {
            untaint($value);
            return $value;
        }
    }
    else {
        # just a syntax check
        if ($value >= 0 and $value <= 255) {
            untaint($value);
            return $value;
        }
    }

    return;
}


sub is_tlsa_cert_association {
    my ($self, $value) = _maybe_oo(@_);

    # must contain some hex chars
    if ($value !~ /[0-9a-fA-F]/) {
        return;
    }

    # hex string with white space allowed.
    if ($value =~ /[^0-9a-fA-F\s]/) {
        return;
    }

    untaint($value);

    return $value;
}

sub _is_int8 {
    my $val = shift;

    if ($val =~ /[^0-9]/) {
        return 0;
    }

    if ($val < 0 or $val > 255) {
        return 0;
    }
    else {
        return 1;
    }
}

sub _maybe_oo {
    my $self = shift if ref $_[0];

    return ($self, @_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Validate::DNS::TLSA - Validate DNS Transport Layer Security Association (TLSA) Record Values

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Data::Validate::DNS::TLSA ':all';

 # Validating a TLSA port number
 if (is_tlsa_port('_443', underscore => 1)) {
    print 'Looks like a valid TLSA port number';
 }
 if (is_tlsa_port('443')) {
    print 'Looks like a valid TLSA port number';
 }

 # Validating a TLSA protocol value
 if (is_tlsa_protocol('_tcp', underscore => 1)) {
    print 'Looks like a valid TLSA protocol';
 }
 if (is_tlsa_protocol('tcp')) {
    print 'Looks like a valid TLSA protocol';
 }

 # Validating a TLSA domain name
 if (is_tlsa_domain_name('_443._tcp.example.com')) {
    print 'Looks like a valid TLSA domain name'
 }

 # Validating a TLSA selector
 if (is_tlsa_selector('1')) {
    print 'Looks like a valid TLSA selector';
 }

 # Validating a TLSA matching type value
 if (is_tlsa_matching_type('2')) {
    print 'Looks like a valid TLSA matching type';
 }

 # Validating a TLSA certificate usage value
 if (is_tlsa_cert_usage('3')) {
    print 'Looks like a valid TLSA Certificate Usage value';
 }

 # Validating a TLSA certificate association value
 if (is_tlsa_cert_association($hash)) {
    print 'Looks like a valid TLSA Certificate Assocation value';
 }

 # or, use the Object interface
 my $v = Data::Validate::DNS::TLSA->new;

 unelss ($v->is_tlsa_selector($suspect)) {
    Carp::croak "$suspect is not a valid TLSA selector";
 }

=head1 DESCRIPTION

This module offers functions for validating DNS Transport Level Security
Association (TLSA) record fields to make input validation and untainting easier
and more readable.

All of the functions return an untainted value on success and a false value
(undef or empty list) on failure.  In scalar context you should check that the
return value is defined.

All functions can be called as methods if using the object oriented interface.

=head1 METHODS

=head2 new()

Constructor

=head1 FUNCTIONS

=head2 is_tlsa_port($value, %options)

Returns the untainted port number (without the leading underscore) if it is a
valid TLSA port string.

Options:

=over 4

=item *

B<underscore> [default: false]

Require the leading underscore.

=back

=head2 is_tlsa_protocol($value, %options)

Returns the TLSA protocol string (without the leading underscore)  if it is valid.

Options:

=over 4

=item *

B<strict> [default: false]

Require the protocol value to be one of the values from L<RFC 6698|https://tools.ietf.org/html/rfc6698>.  That is, one of C<tcp>, C<udp>, or C<sctp>.

=item *

B<underscore> [default false]

Require the leading underscore.

=back

=head2 is_tlsa_domain_name($value, %opts)

Return the untainted value if C<$value> is a valid looking TLSA DNS name.  For
example, C<_443._tcp.example.com>.  This only checks the syntax of the first
two labels (the port and protocol). C<%opts> are the same options that
L<is_tlsa_port()> and L<is_tlsa_protocol()> accept.  However, C<underscore>
defaults to C<true> in this case.

=head2 is_tlsa_matching_type($value, %opts)

Return the untainted value if it looks like a valid TLSA matching type value.

Options:

=over 4



=back

* B<strict> [default: false]
Require the value to be one of the matching types from L<RFC 6698|https://tools.ietf.org/html/rfc6698>.

=head2 is_tlsa_selector($value, %opts)

Return the untainted selector if it is a valid TLSA selector value.

Options:

=over 4

=item *

B<strict> [default: false]

Require the value to be one of the TLSA Selector Values from L<RFC 6698|https://tools.ietf.org/html/rfc6698>.

=back

=head2 is_tlsa_cert_usage($value, %opts)

Return the untainted value if it is a valid TLSA Certificate Usage value.

=over 4

=item *

B<strict> [default: false]

Require the value to be one of the TLSA Certificate Usage Values from L<RFC 6698|https://tools.ietf.org/html/rfc6698>.

=back

=head2 is_tlsa_cert_association($value, %opts)

Return the untainted value if it is a valid TLSA Certificate Association.

=head1 SEE ALSO

L<RFC 6698|https://tools.ietf.org/html/rfc6698>

=head1 SOURCE

The development version is on github at L<http://https://github.com/mschout/perl-data-validate-dns-tlsa>
and may be cloned from L<git://https://github.com/mschout/perl-data-validate-dns-tlsa.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/perl-data-validate-dns-tlsa/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
