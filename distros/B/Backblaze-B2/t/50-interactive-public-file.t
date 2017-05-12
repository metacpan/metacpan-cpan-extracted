#!perl -w
use strict;
use JSON::XS;
use Backblaze::B2;
use Test::More;
use Getopt::Long;

GetOptions(
    'o|application-credentials:s' => \my $app_credentials_file,
);

if( ! $app_credentials_file) {
    $app_credentials_file ||= $ENV{B2_CREDENTIALS_FILE};
};

$app_credentials_file ||= './app-credentials.json';

{
    if( !-f $app_credentials_file ) {;
        SKIP: {
            skip sprintf('No app_credentials read from %s; set $ENV{B2_CREDENTIALS_FILE} for interactive tests', $app_credentials_file),1
        }
        done_testing;
        exit;
    };
}

my $bucket_name = 'backblaze-b2-test-bucket';

my $b2 = Backblaze::B2->new(
    version => 'v1',
    log_message => sub { diag sprintf "[%d] %s\n", @_; },
);

my $credentials = $b2->read_credentials( $app_credentials_file );
if( ! $credentials->{authorizationToken}) {
    $b2->authorize_account(%$credentials);
};

ok $b2, "Authorizing works";

(my $bucket) = grep { $_->name =~ /$bucket_name/ or $_->id eq $bucket_name }
               sort { $a->name cmp $b->name }
               $b2->buckets;

if( ! $bucket) {
    diag "No bucket with name '$bucket_name' found, creating";
    $bucket = $b2->create_bucket(name => $bucket_name,
                                 type => 'allPublic' );
    ok $bucket, "We created a (public) bucket: " . $bucket->name;
};

diag "Uploading $0 to public test bucket";
my $f = $bucket->upload_file(
    file => $0,
    target_name => 'my_file.t',
);

use Data::Dumper;
diag "Upload is reachable as " . $f->name;
diag "Upload is reachable as " . $f->downloadUrl;

my $fetch_as = $f->name;
$fetch_as =~ s!\\!/!g; # just in case we ran on Windows
# Backblaze doesn't want to serve backslashes in their filenames

diag sprintf "Downloading from bucket %s\n", $bucket->name;
my $content = $bucket->download_file_by_name(
    fileName => $fetch_as,
);
    
open my $fh, '<', $0
    or die "Can't read myself as '$0': $!";
binmode $fh;
my $expected_content = do { local $/; <$fh> };

is $content, $expected_content, "We can download what we stored";

my $res = $bucket->get_download_authorization(
    fileNamePrefix => $fetch_as,
    validDurationInSeconds => 30,
);
is $res->{fileNamePrefix}, $fetch_as, "We get an authorization token for the file (prefix) we requested";
isn't $res->{authorizationToken}, '', "We get a good authorization token back";

done_testing;