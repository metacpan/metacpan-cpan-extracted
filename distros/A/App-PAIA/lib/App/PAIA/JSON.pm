package App::PAIA::JSON;
use strict;
use v5.10;

our $VERSION = '0.30';

use parent 'Exporter';
our @EXPORT = qw(decode_json encode_json);
use JSON::PP qw();

sub decode_json {
    my $json = shift;
    my $data = eval { JSON::PP->new->utf8->relaxed->decode($json); };
    if ($@) {
        my $msg = reverse $@;
        $msg =~ s/.+? ta //sm;
        $msg = "JSON error: " . scalar reverse($msg);
        $msg .= " in " . shift if @_;
        die "$msg\n";
    }
    return $data;
}

sub encode_json {
    JSON::PP->new->utf8->pretty->encode($_[0]); 
}

1;
__END__

=head1 NAME

App::PAIA::JSON - utility functions to encode/decode JSON

=head1 DESCRIPTION

This module wraps and exports method C<encode_json> and C<decode_json> from
L<JSON::PP>. On encoding JSON is pretty-printed. Decoding is relaxed and it
dies with better error message on failure. 

=cut
