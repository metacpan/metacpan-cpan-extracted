use strict;
use warnings;

use Test::MockObject;
use Test::Simple tests => 1;
use Apache::Precompress;
use File::Spec;
use Cwd;

my $request = Test::MockObject->new();
my $dir_conf = Test::MockObject->new();
my $log_obj = Test::MockObject->new();
my $constants = Test::MockObject->new();

my $data;

Test::MockObject->fake_module('Apache',
	request => sub { $request }
);

my $pwd = cwd();
my $dir = File::Spec->catdir($pwd, 't');

$request->mock('filename', 
                sub { return $dir . '/decompress.html'; }
);

$dir_conf->mock('get', 
	sub
	{
		my $self = shift;
		my $name = shift;
		my $opts = {
			'Filter'	=>	'off',
			'SSI'		=>	'off',
		};
		return	$opts->{$name};
	}
);

$request->set_always('dir_config', $dir_conf);

$request->mock('send_http_header',
	sub
	{
		my $self = shift;
	}
);

$log_obj->mock('error',
	sub
	{
		my $self = shift;
		my $error = shift;
	}
);

$request->set_always('log', $log_obj);

$request->mock('print',
	sub
	{
		my $self = shift;
		$data = shift;
	}
);

$request->mock('content_encoding',
	sub
	{
		my $self = shift;
	}
);

$request->mock('header_in',
	sub
	{
		my $self = shift;
		my $name = shift;
		
		my $opts = {
			'Accept-Encoding'	=>	""
		};
		return	$opts->{$name};
	}
);

sub Apache::Constants::OK
{
	return 200;
}

sub Apache::Constants::SERVER_ERROR
{
	return 500;
}

sub Apache::Constants::NOT_FOUND
{
	return 404;
}

Apache::Precompress::handler($request);

# Compare the file to the data below
my $contents = "";

open (FH,'<',$dir . '/baseline.html');
{
	local $/ = undef;
	$contents = <FH>;
}
close FH;


ok($contents eq $data, "The decompressed content matches the baseline");
