#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/010_app_mailmake.t
## Test suite for App::mailmake
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use utf8;
    use open ':std' => 'utf8';
    use Test::More;
    use IPC::Open3;
    use Module::Generic::File qw( file tempdir );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

my $tmp = tempdir( cleanup => 1 );

my $plain_file = $tmp->child( 'body.txt' );
$plain_file->unload_utf8( "Hello, World!\n" ) || die( $plain_file->error );

my $html_file = $tmp->child( 'body.html' );
$html_file->unload_utf8( "<p>Hello, <b>World</b>!</p>\n" ) || die( $html_file->error );

my $app = file(__FILE__)->parent(2)->child( 'scripts/mailmake' );

my $base_cmd = qq{$^X -Ilib $app} .
               qq{ --from sender\@example.com} .
               qq{ --to   recipient\@example.com} .
               qq{ --subject "Test message"};
$base_cmd .= qq{ --debug $DEBUG} if( $DEBUG );


# _run( $cmd ) - runs a command, captures stdout and stderr separately.
# Returns ( $stdout, $stderr, $exit_code ).
sub _run
{
    my( $cmd ) = @_;
    my( $stdout, $stderr ) = ( '', '' );
    local $@;
    my $pid = open3( my $in, my $out_fh, my $err_fh, $cmd );
    close( $in );
    # Use IO::Select to read stdout and stderr concurrently - avoids pipe
    # buffer deadlock when one stream fills up before the other is drained.
    require IO::Select;
    my $sel = IO::Select->new( $out_fh, $err_fh );
    while( my @ready = $sel->can_read )
    {
        foreach my $fh ( @ready )
        {
            my $buf;
            my $n = sysread( $fh, $buf, 4096 );
            if( !defined( $n ) || $n == 0 )
            {
                $sel->remove( $fh );
            }
            elsif( $fh == $out_fh )
            {
                $stdout .= $buf;
            }
            else
            {
                $stderr .= $buf;
            }
        }
    }
    waitpid( $pid, 0 );
    my $exit = $? >> 8;
    return( $stdout, $stderr, $exit );
}

# NOTE: --print plain text
subtest '--print plain text' => sub
{
    my $cmd = $base_cmd . qq{ --plain "Hello from mailmake." --print};
    diag( "Running: $cmd" ) if( $DEBUG );
    my( $out, $err, $exit ) = _run( $cmd );
    diag( "stderr: $err" ) if( $err && $DEBUG );
    is( $exit, 0, '--print plain: exit 0' );
    like( $out, qr/^From:\s+sender\@example\.com/mi, '--print plain: From header present' );
    like( $out, qr/^To:\s+recipient\@example\.com/mi, '--print plain: To header present' );
    like( $out, qr/^Subject:/mi, '--print plain: Subject header present' );
    like( $out, qr/Content-Type:\s+text\/plain/i, '--print plain: Content-Type text/plain' );
    like( $out, qr/Hello from mailmake\./, '--print plain: body text present' );
};

# NOTE: --print plain-file
subtest '--print plain-file' => sub
{
    my $cmd = $base_cmd . qq{ --plain-file $plain_file --print};
    diag( "Running $cmd" ) if( $DEBUG );
    my( $out, $err, $exit ) = _run( $cmd );
    diag( "stderr: $err" ) if( $err && $DEBUG );
    is( $exit, 0, '--print plain-file: exit 0' );
    like( $out, qr/Hello, World!/, '--print plain-file: body content correct' );
};

# NOTE: --print html + plain (multipart/alternative)
subtest '--print html + plain (multipart/alternative)' => sub
{
    my $cmd = $base_cmd .
              qq{ --plain "Hello World." --html "<p>Hello World.</p>" --print};
    diag( "Running $cmd" ) if( $DEBUG );
    my( $out, $err, $exit ) = _run( $cmd );
    diag( "stderr: $err" ) if( $err && $DEBUG );
    is( $exit, 0, '--print html+plain: exit 0' );
    like( $out, qr/Content-Type:\s+multipart\/alternative/i,
          '--print html+plain: multipart/alternative structure' );
};

# NOTE: --print with attachment (multipart/mixed)
subtest '--print with attachment (multipart/mixed)' => sub
{
    my $attach = $tmp->child( 'attach.txt' );
    $attach->unload_utf8( "Attachment content.\n" ) || die( $attach->error );
    my $cmd = $base_cmd .
              qq{ --plain "See attachment." --attach $attach --print};
    diag( "Running $cmd" ) if( $DEBUG );
    my( $out, $err, $exit ) = _run( $cmd );
    diag( "stderr: $err" ) if( $err && $DEBUG );
    diag( "$base_cmd output:\n$out" ) if( $exit != 0 && $DEBUG );
    is( $exit, 0, '--print attach: exit 0' );
    like( $out, qr/Content-Type:\s+multipart\/mixed/i,
          '--print attach: multipart/mixed structure' );
};

# NOTE: --print with extra header
subtest '--print with extra header' => sub
{
    my $cmd = $base_cmd .
              qq{ --plain "Header test." --header "X-Mailer:mailmake-test" --print};
    diag( "Running $cmd" ) if( $DEBUG );
    my( $out, $err, $exit ) = _run( $cmd );
    diag( "stderr: $err" ) if( $err && $DEBUG );
    is( $exit, 0, '--print extra header: exit 0' );
    like( $out, qr/^X-Mailer:\s*mailmake-test/mi,
          '--print extra header: X-Mailer present' );
};

# NOTE: missing --from should fail
subtest 'missing --from should fail' => sub
{
    my $cmd = qq{$^X -Ilib scripts/mailmake} .
              qq{ --to recipient\@example.com --plain "x" --print};
    diag( "Running $cmd" ) if( $DEBUG );
    my( $out, $err, $exit ) = _run( $cmd );
    $out .= $err;  # merge for error-checking tests
    isnt( $exit, 0, 'missing --from: non-zero exit' );
};

# NOTE: --gpg-sign and --smime-sign together should fail
subtest '--gpg-sign and --smime-sign together should fail' => sub
{
    my $cmd = $base_cmd .
              qq{ --plain "x" --gpg-sign --smime-sign --print};
    diag( "Running $cmd" ) if( $DEBUG );
    my( $out, $err, $exit ) = _run( $cmd );
    $out .= $err;  # merge for error-checking tests
    isnt( $exit, 0, 'conflicting gpg+smime: non-zero exit' );
};

done_testing();

__END__
