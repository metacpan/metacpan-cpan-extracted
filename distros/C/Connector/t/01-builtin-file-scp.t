use strict;
use warnings;
use English;

Log::Log4perl->easy_init( { level   => 'ERROR' } );

# The user running this test must be able to connect to localhost
# using ssh key authentication (ssh localhost) and have access to /tmp");

BEGIN {

    use Test::More;
    unless ( $ENV{CONN_HAVE_SSH_CONFIG} ) {
        plan skip_all => "Skipping SCP tests - setup ssh-key auth and set CONN_HAVE_SSH_CONFIG=1";
        exit;
    }

    use_ok( 'Connector::Builtin::File::SCP' );
}

require_ok( 'Connector::Builtin::File::SCP' );


# diag "Connector::Proxy::File::Path tests\n";
###########################################################################
my $conn = Connector::Builtin::File::SCP->new({
    LOCATION  => 'localhost:/tmp',
    file => '[% ARGS.0 %].txt',
    content => 'Hello [% NAME %]',
    filemode => 0644
});

my $filename = 'test'.$$;
# set/get success
ok($conn->set($filename, { NAME => 'John Doe' }),'write file');
is($conn->get($filename.'.txt'), 'Hello John Doe');

unlink("/tmp/$filename.txt");

# read/write no-existing location
$conn = Connector::Builtin::File::SCP->new({
    LOCATION  => 'localhost:/this-should-not-exist',
    file => '[% ARGS.0 %].txt',
    content => 'Hello [% NAME %]',
    filemode => 0644
});

eval { $conn->set('test', { NAME => 'John Doe' }); };
like($EVAL_ERROR, "/Unable to transfer data/");

is($conn->get('test.txt'), undef);


# read/write to non existing host 
$conn = Connector::Builtin::File::SCP->new({
    LOCATION  => 'do.not.resolve.local:/tmp',
    file => '[% ARGS.0 %].txt',
    content => 'Hello [% NAME %]',
    filemode => 0644,
    timeout => 1,
});

my $start = time();
eval { $conn->set('test', { NAME => 'John Doe' }); };
like($EVAL_ERROR, "/Unable to transfer data/");

ok(time() - $start <= 3, 'timeout alarm'); 

is($conn->get('test.txt'), undef);

done_testing;