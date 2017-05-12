package main;
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use File::Spec;
use Amazon::S3::FastUploader;

my %opts = (
    process => 1,
    ssl => 0,
    encrypt => 0,
);

GetOptions(
    \%opts,
    'verbose',
    'process=i',
    'ssl',
    'encrypt',
    'help'
) or $opts{help}++;

pod2usage(2) if $opts{help};

my $local_dir = shift;
my $remote_dir = shift;
my ($bucket_name, $target_dir) = ( $remote_dir =~ m|s3://([^/]+)/(.+)$| );

die "no such directory $local_dir" if ! -d $local_dir;

my $config = {
        aws_access_key_id => $ENV{AWS_ACCESS_KEY_ID},
        aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
        secure => $opts{ssl},
        encrypt => $opts{encrypt},
        retry => 5,
        process => $opts{process},
        verbose => $opts{verbose},
    };

my $uploader = Amazon::S3::FastUploader->new($config);
$uploader->upload($local_dir, $bucket_name, $target_dir);

__END__

=head1 Name

S3 Uploader - a script to upload recursively a directory to Amazon S3


=head1 SYNOPSIS

 -v  verbose
 -p  max process (default 1 if ommitted)
 -s  use ssl
 -h  help (this)

example:

 upload.pl -v -p 10 /path/to/dir s3://bucketname/foo/bar/dir/

=cut

