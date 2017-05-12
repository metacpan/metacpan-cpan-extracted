use strict;
use warnings;

use Test::MockObject;
use Test::Simple tests => 1;
use Apache::Precompress;
use File::Temp qw/ tempfile/;
use Compress::Zlib 1.0;
use File::Spec;
use Cwd;

my $request = Test::MockObject->new();
my $dir_conf = Test::MockObject->new();
my $log_obj = Test::MockObject->new();
my $constants = Test::MockObject->new();

my ($fh, $filename) = tempfile();

my $data;

Test::MockObject->fake_module('Apache',
	request => sub { $request }
);

my $pwd = cwd();
my $dir = File::Spec->catdir($pwd, 't');
$request->mock('filename', 
                sub { return $dir . '/decompress.html' }
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

$request->mock('log',
	sub
	{
		my $self = shift;
		my $error = shift;
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
		$data .= shift;
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
			'Accept-Encoding'	=>	"gzip"
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

# We now have compressed content. Check that it matches the
# file. Decompress here and check that it matches the 
# baseline.

open($fh, '>', $filename);
binmode($fh);
print $fh $data;
close($fh);

# Open the temp file
my $contents = "";
my $buffer;
my $gz = gzopen($filename, "rb") 
            or die(".gz: $gzerrno\n");
while($gz->gzread($buffer,4096) > 0)
{
	$contents .= $buffer;
}

# Compare the file to the data below
my $base = "";
open (FH,'<',$dir . '/baseline.html');
{
	local $/ = undef;
	$base = <FH>;
}
close FH;

ok($contents eq $data, "The compressed content matches the baseline");