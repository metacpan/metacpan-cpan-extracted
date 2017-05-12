#!perl
use Test::Most;
use utf8;

# For email distribution below\
BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }

use lib qw(t/lib);
use ZapziTestDatabase;

use App::Zapzi;
use App::Zapzi::Distribute;

my $running_on_windows = $^O eq 'MSWin32';
test_can();

my ($test_dir, $app) = ZapziTestDatabase::get_test_app();
my $test_file_base = generate_test_file();
my $test_file_full = "$test_dir/$test_file_base";

test_no_distributor();
test_invalid_distributor();
test_copy_distributor();
SKIP: {
    skip "Script tests not supported on Windows" if $running_on_windows;
    test_script_distributor();
}
test_email_distributor();

done_testing();

sub test_can
{
    can_ok( 'App::Zapzi::Distribute', qw(distribute) );
}

sub generate_test_file
{
    my $filename = "output.book";

    open my $fh, '>', "$test_dir/$filename"
        or die "Could not create test file for distribution: $!";

    my $contents = "This is a test file for distibution\n";
    print {$fh} $contents;

    close $fh;

    my $file_length = length($contents);
    $file_length++ if $running_on_windows; # Account for CRLF on Windows
    is( -s "$test_dir/$filename", $file_length,
        "Created test file size OK" );

    return $filename;
}

sub test_no_distributor
{
    my $dist = App::Zapzi::Distribute->new(file => $test_file_full);
    isa_ok( $dist, 'App::Zapzi::Distribute' );

    ok( $dist->distribute, 'Will do nothing if no distributor defined' );
    is( $dist->completion_message, '', 'No message if no distributor' );

    $dist = App::Zapzi::Distribute->new(file => $test_file_full,
                                        method => '');
    ok( $dist->distribute, 'Will do nothing if distributor set to blank' );
}

sub test_invalid_distributor
{
    my $dist = App::Zapzi::Distribute->new(file => $test_file_full,
                                           method => 'nonesuch');
    isa_ok( $dist, 'App::Zapzi::Distribute' );

    ok( ! $dist->distribute, 'Error if invalid distributor set' );
    like( $dist->completion_message, qr/'nonesuch' not defined/,
          'Error message set if invalid distributor' );

}

sub test_copy_distributor
{
    my $destination_dir = "$test_dir/dest";
    mkdir $destination_dir
        or die "Could not create directory $destination_dir: $!\n";

    my $destination_file = "$destination_dir/copied.book";

    # Copy to directory
    my $dist = App::Zapzi::Distribute->new(file => $test_file_full,
                                           method => 'copy',
                                           destination => $destination_dir);
    isa_ok( $dist, 'App::Zapzi::Distribute' );
    ok( $dist->distribute, 'Copy to directory returns OK' );
    like( $dist->completion_message,
          qr/File copied to '$destination_dir' successfully/,
          'OK message for successful copy to directory' );
    my $dir_copy_full = "$destination_dir/$test_file_base";
    is( -s $dir_copy_full, -s $test_file_full,
        'Copied file size correct' );

    # Copy to file
    $dist = App::Zapzi::Distribute->new(file => $test_file_full,
                                        method => 'copy',
                                        destination => $destination_file);
    isa_ok( $dist, 'App::Zapzi::Distribute' );
    ok( $dist->distribute, 'Copy to file returns OK' );
    like( $dist->completion_message,
          qr/File copied to '$destination_file' successfully/,
          'OK message for successful copy to file' );
    is( -s $destination_file, -s $test_file_full,
        'Copied file size correct' );

    # Copy to non-existent path
    $destination_file = "$test_dir/no/such/path/to/file.book";
    $dist = App::Zapzi::Distribute->new(file => $test_file_full,
                                        method => 'copy',
                                        destination => $destination_file);
    isa_ok( $dist, 'App::Zapzi::Distribute' );
    ok( ! $dist->distribute, 'Copy to non-existent path returns error' );
    like( $dist->completion_message,
          qr/Error copying file/,
          'Error message for failed copy to file' );
}

sub test_script_distributor
{
    # Run a script that echos the param back and exits successfully
    my $dist = App::Zapzi::Distribute->
        new(file => $test_file_full,
            method => 'script',
            destination => 't/testfiles/distribute-script-echo.pl');
    isa_ok( $dist, 'App::Zapzi::Distribute' );
    ok( $dist->distribute, 'Echo script returns OK' );
    like( $dist->completion_message,
          qr/$test_file_base/,
          'OK message for successful echo script' );

    # Run a script that returns an error
    $dist = App::Zapzi::Distribute->
        new(file => $test_file_full,
            method => 'script',
            destination => 't/testfiles/distribute-script-error.pl');
    isa_ok( $dist, 'App::Zapzi::Distribute' );
    ok( ! $dist->distribute, 'Error script returns error' );
    like( $dist->completion_message,
          qr/Error signalled/,
          'OK message for error script' );

    # Script does not exist
    $dist = App::Zapzi::Distribute->
        new(file => $test_file_full,
            method => 'script',
            destination => 't/testfiles/no-such-script');
    isa_ok( $dist, 'App::Zapzi::Distribute' );
    ok( ! $dist->distribute, 'Non-existent script returns error' );
    like( $dist->completion_message,
          qr/Script does not exist/,
          'OK message for non-existent script' );
}

sub test_email_distributor
{
    # Use the test email transport (ie email is not actually sent out)
    # to check if it was processed correctly.

    my $recipient = 'test@example.com';
    my $dist = App::Zapzi::Distribute->
        new(file => $test_file_full,
            method => 'email',
            destination => $recipient);
    isa_ok( $dist, 'App::Zapzi::Distribute' );
    ok( $dist->distribute, 'Email with test transport returns OK' );
    like( $dist->completion_message,
          qr/Emailed to $recipient/,
          'OK message for successful email with test transport' );

    my @deliveries = Email::Sender::Simple->default_transport->deliveries;
    is( scalar(@deliveries), 1, 'One email sent via test transport' );
    my $email = $deliveries[0];
    if ($email)
    {
        is( $email->{successes}->[0], $recipient,
            "Correct recipient for test transport");
    }

    # Try a missing recipient
    $recipient = '';
    $dist = App::Zapzi::Distribute->
        new(file => $test_file_full,
            method => 'email',
            destination => $recipient);
    isa_ok( $dist, 'App::Zapzi::Distribute' );
    ok( ! $dist->distribute, 'Email with missing recipient gives an error' );
    like( $dist->completion_message, qr/recipient does not exist/,
          'Message indicates missing recipient' );

    # Try making the sendmail call fail
    $recipient = [];
    $dist = App::Zapzi::Distribute->
        new(file => $test_file_full,
            method => 'email',
            destination => $recipient);
    isa_ok( $dist, 'App::Zapzi::Distribute' );
    ok( ! $dist->distribute, 'Email throwing exception gives an error' );
}
