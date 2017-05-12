#!perl -w
use strict;
use JSON::XS;
use Backblaze::B2;
use Getopt::Long;

GetOptions(
    'c|credentials:s' => \my $credentials_file,
);

=head1 SYNOPSIS

=cut

my $b2 = Backblaze::B2->new(
    version => 'v1',
);

my $credentials = $b2->read_credentials( $credentials_file );
if( ! $credentials->{authorizationToken}) {
    $b2->authorize_account(%$credentials);
};

use Data::Dumper;

for my $id (@ARGV) {
    print "Deleting bucket $id\n";
    print Dumper $b2->delete_bucket(bucketId => $id );
};