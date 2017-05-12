package Authen::HTTP::Signature::Parser;

use strict;
use warnings;

use Moo;
use Authen::HTTP::Signature;
use HTTP::Date qw(str2time);
use Scalar::Util qw(blessed);
use Carp qw(confess);

=head1 NAME

Authen::HTTP::Signature::Parser - Parse HTTP signature headers

=cut

our $VERSION = '0.03';

=head1 PURPOSE

This class parses a HTTP signature 'Authorization' header (if one exists) from a request
object and populates attributes in a L<Authen::HTTP::Signature> object.

=head1 ATTRIBUTES

=over

=item request

The request to be parsed.

=back

=cut

has 'request' => (
    is => 'rw',
    isa => sub { confess "'request' must be blessed" unless blessed($_[0]) },
    predicate => 'has_request',
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if ( @_ == 1 ) {
        unshift @_, "request";
    }

    return $class->$orig(@_);
};

=over

=item get_header

A call back to get a header from C<request>.

=back

=cut

has 'get_header' => (
    is => 'rw',
    isa => sub { die "'get_header' expects a CODE ref\n" unless ref($_[0]) eq "CODE" },
    predicate => 'has_get_header',
    default => sub {
        sub {
            confess "Didn't get 2 arguments" unless @_ == 2;
            my $request = shift;
            confess "'request' isn't blessed" unless blessed $request;
            my $name = shift;

            if( $name eq 'request-line' ) {
                sprintf("%s %s",
                    $request->uri->path_query,
                    $request->protocol);
            } elsif( $name eq '(request-target)' ) {
                sprintf("%s %s",
                    lc($request->method),
                    $request->uri->path_query);
            } else {
                    $request->header($name);
            }
        };
    },
    lazy => 1,
);

=over

=item skew

Defaults to 300 seconds in either direction from your clock. If the Date header data is outside of this range,
the request is considered invalid.

Set this value to 0 to disable skew checks for testing purposes.

=back

=cut

has 'skew' => (
    is => 'rw',
    isa => sub { die "$_[0] isn't an integer" unless $_[0] =~ /[0-9]+/ },
    default => sub { 300 },
);


=head1 METHOD

Errors are fatal.

=over

=item parse()

This method parses signature header components.

=back

=cut

sub parse {
    my $self = shift;
    my $request = shift || $self->request;

    confess "There was no request to parse!" unless $request;

    my $sig_str = $self->get_header->($request, 'authorization');
    confess 'No authorization header value was returned!' unless $sig_str;

    $self->_check_skew($request);

    my ( $sig_text ) = $sig_str =~ /^(Signature).*$/;
    confess "does not match required string 'Signature'" unless $sig_text;

    my ( $b64_str ) = $sig_str =~ /^Signature.*signature="(.*?)".*$/;
    confess "No signature data found!" unless $b64_str;

    my ( $key_id ) = $sig_str =~ /^Signature.*(keyId=".*?").*$/;
    my ( $algo ) = $sig_str =~ /^Signature.*(algorithm=".*?").*$/;
    my ( $ext ) = $sig_str =~ /^Signature.*(ext=".*?").*$/;
    my ( $hdrs ) = $sig_str =~ /^Signature.*(headers=".*?").*$/;

    $key_id =~ s/^keyId="(.*)"$/$1/;
    $algo =~ s/^algorithm="(.*)"$/$1/;
    $ext =~ s/^ext="(.*)"/$1/ if $ext;

    confess "No key id found!" unless $key_id;
    confess "No algorithm found" unless $algo;

    my @headers;
    if ( $hdrs ) {
        $hdrs =~ s/^headers="(.*)"$/$1/;
        @headers = split / /, $hdrs;
    }

    push @headers, "date" unless @headers;

    # die on duplicate headers
    my %h;
    foreach my $hdr ( @headers ) {
        if ( exists $h{$hdr} ) {
            confess "Duplicate header '$hdr' found in signature header parameter. Aborting.";
        }
        $h{$hdr}++;
    }

    # normalize headers to lower-case
    @headers = map { lc } @headers;

    my $ss = join "\n", map {
        if( $self->get_header->($request, $_) ) {
            sprintf("%s: %s", $_, $self->get_header->($request, $_) );
        } else {
            confess "Couldn't get header value for $_\n";
        } } @headers;

    return Authen::HTTP::Signature->new(
        key_id         => $key_id,
        headers        => \@headers,
        signing_string => $ss,
        algorithm      => $algo,
        extensions     => $ext,
        signature      => $b64_str,
        request        => $request,
    );
}

sub _check_skew {
    my $self = shift;

    if ( $self->skew ) {
        my $request = shift;
        confess "No request found" unless $request;
        my $header_time = str2time( $self->get_header->($request, 'date') );
        confess "No Date header was returned (or could be parsed)" unless $header_time;

        my $diff = abs(time - $header_time);
        if ( $diff >= $self->skew ) {
           confess "Request is outside of clock skew tolerance: $diff seconds computed, " . $self->skew . " seconds allowed.\n";
        }
    }

    return 1;

}


=head1 SEE ALSO

L<Authen::HTTP::Signature>

=cut

1;
