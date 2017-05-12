#!perl -w
use strict;
use JSON::XS;
use Backblaze::B2;
use Getopt::Long;

GetOptions(
    'c|credentials:s' => \my $credentials_file,
    'o|application-credentials:s' => \my $app_credentials,
);

$app_credentials ||= './app-credentials.json';

my ($bucket_name) = @ARGV;

=head1 SYNOPSIS

=head1 SEE ALSO

L<https://www.backblaze.com/b2/docs/b2_authorize_account.html>

=cut

my $b2 = Backblaze::B2->new(
    version => 'v1',
);

my $credentials = $b2->read_credentials( $credentials_file );
if( ! $credentials->{authorizationToken}) {
    $b2->authorize_account(%$credentials);
};

use Data::Dumper;
warn Dumper $b2->create_bucket(bucketName => $bucket_name );