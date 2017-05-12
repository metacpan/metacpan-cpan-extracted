package AWS::Signature::V2;
use Moo;
use Digest::SHA qw(hmac_sha256_base64);
use URI::Escape;
use Encode qw/decode_utf8/;

our $VERSION = "0.01";

has aws_access_key => (is => 'rw', required => 1, builder => 1);
has aws_secret_key => (is => 'rw', required => 1, builder => 1);

sub _build_aws_access_key { $ENV{AWS_ACCESS_KEY} }
sub _build_aws_secret_key { $ENV{AWS_SECRET_KEY} }

sub sign {
    my ($self, $url) = @_;
    my %eq    = map { split /=/, $_ } split /&/, $url->query();
    my %q     = map { $_ => decode_utf8( uri_unescape( $eq{$_} ) ) } keys %eq;
    $q{Keywords} =~ s/\+/ /g if $q{Keywords};
    $q{AWSAccessKeyId} = $self->aws_access_key;
    $q{Timestamp} ||= do {
        my ( $ss, $mm, $hh, $dd, $mo, $yy ) = gmtime();
        join '',
          sprintf( '%04d-%02d-%02d', $yy + 1900, $mo + 1, $dd ), 'T',
          sprintf( '%02d:%02d:%02d', $hh,        $mm,     $ss ), 'Z';
    };
    $q{Version} ||= '2010-09-01';
    my $sq = join '&',
      map { $_ . '=' . uri_escape_utf8( $q{$_}, "^A-Za-z0-9\-_.~" ) }
      sort keys %q;
    my $tosign = join "\n", 'GET', $url->host, $url->path, $sq;
    my $signature = hmac_sha256_base64( $tosign, $self->aws_secret_key );
    $signature .= '=' while length($signature) % 4;    # padding required
    $q{Signature} = $signature;
    $url->query_form( \%q );
    $url;
}

sub signature {
    my ($self, $url) = @_;
    my %eq = map { split /=/, $_ } split /&/, $url->query();
    my %q = map { $_ => uri_unescape( $eq{$_} ) } keys %eq;
    $q{Signature};
}


1;
__END__

=encoding utf-8

=head1 NAME

AWS::Signature::V2 - Create a version 2 signature for AWS services

=head1 SYNOPSIS

    use AWS::Signature::V2;
    use LWP::UserAgent->new;

    my $signer = AWS::Signature::V2->new(
        aws_access_key => ..., # defaults to $AWS_ACCESS_KEY
        aws_secret_key => ..., # defaults to $AWS_SECRET_KEY
    );

    my $ua  = LWP::UserAgent->new;
    my $uri = URI->new('https://');
    $uri->query_form(...);
    my $signed_uri = $signer->sign($uri);
    my $response = $ua->get($signed_uri);

=head1 DESCRIPTION

Pretty much the only service that needs this anymore is the Amazon Product
Advertising API.  99% of this code was copied from URI::Amazon::APA.  But
URI::Amazon::APA doesn't support https and I wanted that.

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

