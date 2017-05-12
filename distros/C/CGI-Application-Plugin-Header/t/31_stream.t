# copied and rearranged from CGI-Application-Plugin-Stream's t/basic.t

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More tests => 14;
#BEGIN {
#  use_ok('CGI::Application::Plugin::Stream');

#  unshift @INC, 't/lib';
#}

use strict;
#use TieOut;



# Useless here, since the point is to test streaming directly.
#$ENV{CGI_APP_RETURN_ONLY} = 1;

#####


my $stdout = tie *STDOUT, 'TieOut' or die;
my ($content_sent, $test_name);

##############

# Testing with a file handle

my $app = StreamTest->new();
$app->with_fh();

$content_sent = $stdout->read;

$test_name = "with fh: Content-Disposition and filename headers are correct";
like($content_sent, qr/Content-Disposition: attachment; filename="FILE"/i,$test_name);

$test_name    = 'with fh: Content-type detected correctly by File::MMagic';
like($content_sent, qr!Content-Type: text/plain!i, $test_name);

$test_name    = 'with fh: correct Content-Length  header found';
like($content_sent, qr/Content-Length: 29/i,$test_name);

# Testing with a file
$app = StreamTest->new();
$app->run();

$content_sent = $stdout->read;
$test_name = "Content-Disposition and filename headers are correct";
like($content_sent, qr/Content-Disposition: attachment; filename="31_stream.txt"/i,$test_name);

$test_name = 'Content-type detected correctly by File::MMagic';
like($content_sent, qr!Content-Type: text/plain!i, $test_name);

$test_name = 'correct Content-Length header found';
like($content_sent, qr/Content-Length: 29/i,$test_name);

###

SKIP: {
    skip 'incompatible with CGI::Application::Plugin::Header', 1;
    $test_name = 'Setting a custom Content-Length';
    $app = StreamTest->new();
    $app->header_props(Content_Length => 1 );
    $app->with_fh();
    $content_sent = $stdout->read;
    like($content_sent, qr/Content-Length: 1/i,$test_name);
};

###

SKIP: {
    skip 'incompatible with CGI::Application::Plugin::Header', 1;
    $test_name = 'Setting a custom -Content-Length';
    $app = StreamTest->new();
    $app->header_props(-Content_Length => 4 );
    $app->with_fh();
    $content_sent = $stdout->read;
    like($content_sent, qr/Content-Length: 4/i,$test_name);
};

###

$test_name = 'Setting a custom type';
$app = StreamTest->new();
$app->header_props(type => 'jelly/bean' );
$app->with_fh();
$content_sent = $stdout->read;
like($content_sent, qr/jelly/i,$test_name);

###

$test_name = 'Setting a custom -type';
$app = StreamTest->new();
$app->header_props(-type => 'recumbent/bicycle' );
$app->with_fh();
$content_sent = $stdout->read;
like($content_sent, qr/recumbent/i,$test_name);

###

$test_name = 'Setting a custom attachment';
$app = StreamTest->new();
$app->header_props(attachment => 'save_the_planet_from_the_humans.txt' );
$app->with_fh();
$content_sent = $stdout->read;
like($content_sent, qr/save_the_planet/i,$test_name);

###

$test_name = 'Setting a custom -type';
$app = StreamTest->new();
$app->header_props(-attachment => 'do_some_yoga.mp3' );
$app->with_fh();
$content_sent = $stdout->read;
like($content_sent, qr/yoga/i,$test_name);

###

$test_name = 'Setting a non-attachment header is preserved';
$app = StreamTest->new();
$app->header_props(-dryer => 'clothes_line' );
$app->with_fh();
$content_sent = $stdout->read;
like($content_sent, qr/dryer/i,$test_name);

###

$test_name = 'Setting a explicit byte Content-Length at least doesn\'t die';
$app = StreamTest->new();
$app->with_bytes();
$content_sent = $stdout->read;
like($content_sent, qr/Content-type/i,$test_name);


#################

package StreamTest;
use parent 'CGI::Application';
use CGI::Application::Plugin::Stream (qw/stream_file/);
use CGI::Application::Plugin::Header;

sub setup {
    my $self = shift;
    $self->run_modes([qw/start with_fh with_bytes/])
}


sub start {
    my $self = shift;
    return $self->stream_file('t/31_stream.txt');
}

sub with_fh  {
    my $self = shift;

    my $fh;
    open($fh,'<t/31_stream.txt') || die;
    return $self->stream_file($fh);
}

sub with_bytes  {
    my $self = shift;
    return $self->stream_file('t/31_stream.txt',2048);
}

# copied from CGI-Application-Plugin-Stream's t/lib/TieOut.pm

package TieOut;

sub TIEHANDLE {
	bless( \(my $scalar), $_[0]);
}

sub PRINT {
	my $self = shift;
	$$self .= join('', @_);
}

sub PRINTF {
	my $self = shift;
    my $fmt  = shift;
	$$self .= sprintf $fmt, @_;
}

sub read {
	my $self = shift;
	return substr($$self, 0, length($$self), '');
}

# Thanks, Makio!
sub FILENO { 1; }
sub BINMODE { 1; }
