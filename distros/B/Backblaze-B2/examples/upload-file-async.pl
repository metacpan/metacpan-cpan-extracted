#!perl -w
use strict;
use JSON::XS;
use Backblaze::B2;
use Getopt::Long;
use Promises 'collect';

GetOptions(
    'c|credentials:s' => \my $credentials_file,
);

my ($bucket_id, @files) = @ARGV;

=head1 SYNOPSIS

=cut

my $b2 = Backblaze::B2->new(
    version => 'v1',
    api => 'Backblaze::B2::v1::AnyEvent',
    log_message => sub { warn sprintf "[%d] %s\n", @_; },
);

sub await($) {
    my $promise = $_[0];
    my @res;
    if( $promise->is_unfulfilled ) {
        require AnyEvent;
        my $await = AnyEvent->condvar;
        $promise->then(sub{ $await->send(@_)});
        @res = $await->recv;
    } else {
        @res = @{ $promise->result }
    }
    @res
};

my $credentials = $b2->read_credentials( $credentials_file );
if( ! $credentials->{authorizationToken}) {
    await $b2->authorize_account(%$credentials);
};

my $bucket = $b2->bucket_from_id( $bucket_id );
    
await collect( 
    map {
        my $file = $_;
        $bucket->upload_file(
            bucketId => $bucket_id,
            file => $file,
        )->then(sub {
            my( $res ) = @_;
            print "$file uploaded\n";
        })->catch(sub {
            warn "@_"
        });
    } @files );

