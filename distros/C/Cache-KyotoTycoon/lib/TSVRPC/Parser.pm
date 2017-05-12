package TSVRPC::Parser;
use strict;
use warnings;
use base qw/Exporter/;
use URI::Escape qw/uri_escape uri_unescape/;
use MIME::QuotedPrint qw/encode_qp decode_qp/;
use MIME::Base64 qw/encode_base64 decode_base64/;

our @EXPORT = qw/encode_tsvrpc decode_tsvrpc/;

my %ENCODERS = (
    'U' => \&uri_escape,
    'Q' => sub { encode_qp($_[0], '') },
    'B' => sub { encode_base64($_[0], '') },
);
my %DECODERS = (
    'U' => \&uri_unescape,
    'Q' => sub { decode_qp($_[0]) },
    'B' => sub { decode_base64($_[0]) },
);

sub encode_tsvrpc {
    my ($data, $encoding) = @_;
    my $encoder = $encoding ? $ENCODERS{$encoding} : sub { $_[0] };
    my @res;
    while (my ($k, $v) = each %$data){
        push @res, (scalar($encoder->($k)) . "\t" . scalar($encoder->($v)));
    }
    return join "\n", @res;
}

sub decode_tsvrpc {
    my ($data, $encoding) = @_;
    my $decoder = $encoding ? $DECODERS{$encoding} : sub { $_[0] };
    my %res;
    for my $line (split "\n", $data) {
        my ($k, $v) = map { scalar $decoder->($_) } split("\t", $line);
        $res{$k} = $v;
    }
    return wantarray ? %res : \%res;
}

1;
__END__

=head1 NAME

TSVRPC::Parser - TSV-RPC parser

=head1 SYNOPSIS

    my $encoded = TSVRPC::Parser::encode_tsvrpc(\%src, 'B');

    my $decoded = TSVRPC::Parser::decode_tsvrpc($src, 'B');

=head1 DESCRIPTION

This is TSV-RPC parser class.

=head1 FUNCTIONS

=over 4

=item C<< my $encoded = TSVRPC::Parser::encode_tsvrpc(\%src[, $encoding]); >>

Encode plain hashref to TSV with $encoding.

=item C<< my $decoded = TSVRPC::Parser::decode_tsvrpc($src[, $encoding]); >>

Decode TSV to plain hashref.

=back

=head1 ENCODING

=over 4

=item B

Base64 Encoding

=item Q

Quoted-Printable Encoding

=item U

URI Escape

=back

