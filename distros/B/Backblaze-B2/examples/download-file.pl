#!perl -w
use strict;
use JSON::XS;
use Backblaze::B2;
use Getopt::Long;

GetOptions(
    'c|credentials:s' => \my $credentials_file,
    'o|target-base:s' => \my $target_base,
);
$target_base ||= '.';

my ($bucket_name, @files) = @ARGV;

=head1 SYNOPSIS

=cut

my $b2 = Backblaze::B2->new(
    version => 'v1',
    log_message => sub { warn sprintf "[%d] %s\n", @_; },
);

my $credentials = $b2->read_credentials( $credentials_file );
if( ! $credentials->{authorizationToken}) {
    $b2->authorize_account(%$credentials);
};

(my $bucket) = grep { $_->name =~ /$bucket_name/ or $_->id eq $bucket_name }
               sort { $a->name cmp $b->name }
               $b2->buckets;

if( ! $bucket ) {
    die "No bucket found with name matching '$bucket_name'";
};

print sprintf "Downloading from bucket %s\n", $bucket->name;
for my $file (@files) {
    
    my $target = join "/", $target_base, $file;
    if( -f $target ) {
        warn "$target already exists, skipping\n";
        next
    };
    
    my $content = $bucket->download_file_by_name(
        file => $file,
    );
    
    open my $fh, '>', $target
        or die "Couldn't create '$target': $!";
    binmode $fh;
    print {$fh} $target;
    
    print sprintf "Downloaded %s (%d bytes) to %s\n", $file, length $content, $target;
};
