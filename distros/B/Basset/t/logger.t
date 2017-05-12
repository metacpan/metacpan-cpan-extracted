use Test::More tests => 89;
use Basset::Logger;
package Basset::Logger;
{		Test::More::ok(1, "uses strict");
		Test::More::ok(1, "uses warnings");
};
{
#line 67  handle

my $o = Basset::Logger->new();
Test::More::ok($o, "Got object for handle");
Test::More::is(scalar($o->handle($o)), undef, "Cannot set handle to unknown reference");
Test::More::is($o->errcode, "BL-03", "proper error code");

local $@ = undef;
eval "use File::Temp";
my $file_temp_exists = $@ ? 0 : 1;

if ($file_temp_exists) {
	my $temp = File::Temp->new;
	my $name = $temp->filename;
	Test::More::is(ref($o->handle($name)), 'GLOB', "created glob");
	open (my $glob, $name);
	Test::More::is($o->handle($glob), $glob, "set glob");
	chmod 000, $name;
	Test::More::is(scalar($o->handle($name)), undef, "could not set handle to unwritable file");
	Test::More::is($o->errcode, "BL-01", "proper error code");
}
};
{
#line 104  closed

{
	my $o = Basset::Logger->new();
	Test::More::ok($o, "Got object");
	Test::More::is(scalar(Basset::Logger->closed), undef, "could not call object method as class method");
	Test::More::is(Basset::Logger->errcode, "BO-08", "proper error code");
	Test::More::is(scalar($o->closed), 0, 'closed is 0 by default');
	Test::More::is($o->closed('abc'), 'abc', 'set closed to abc');
	Test::More::is($o->closed(), 'abc', 'read value of closed - abc');
	my $h = {};
	Test::More::ok($h, 'got hashref');
	Test::More::is($o->closed($h), $h, 'set closed to hashref');
	Test::More::is($o->closed(), $h, 'read value of closed  - hashref');
	my $a = [];
	Test::More::ok($a, 'got arrayref');
	Test::More::is($o->closed($a), $a, 'set closed to arrayref');
	Test::More::is($o->closed(), $a, 'read value of closed  - arrayref');
}

my $o = Basset::Logger->new();
Test::More::ok($o, "got object");
Test::More::is($o->close, 1, "closing non-existent handle is fine");
Test::More::is($o->closed, 0, "handle remains open");

local $@ = undef;
eval "use File::Temp";
my $file_temp_exists = $@ ? 0 : 1;

if ($file_temp_exists) {
	my $temp = File::Temp->new;
	my $name = $temp->filename;
	Test::More::is(ref($o->handle($name)), 'GLOB', "created glob");
	Test::More::is($o->closed, 0, "file handle is open");
	Test::More::is($o->close, 1, "closed file handle");
	Test::More::is($o->closed, 1, "filehandle is closed");
}
};
{
#line 157  stamped

my $o = Basset::Logger->new();
Test::More::ok($o, "Got object");
Test::More::is(scalar(Basset::Logger->stamped), undef, "could not call object method as class method");
Test::More::is(Basset::Logger->errcode, "BO-08", "proper error code");
Test::More::is(scalar($o->stamped), 1, 'stamped is 1 by default');
Test::More::is($o->stamped('abc'), 'abc', 'set stamped to abc');
Test::More::is($o->stamped(), 'abc', 'read value of stamped - abc');
my $h = {};
Test::More::ok($h, 'got hashref');
Test::More::is($o->stamped($h), $h, 'set stamped to hashref');
Test::More::is($o->stamped(), $h, 'read value of stamped  - hashref');
my $a = [];
Test::More::ok($a, 'got arrayref');
Test::More::is($o->stamped($a), $a, 'set stamped to arrayref');
Test::More::is($o->stamped(), $a, 'read value of stamped  - arrayref');
};
{
#line 190  init

my $o = Basset::Logger->new();
Test::More::ok($o, "Got logger object");
Test::More::is($o->closed, 0, 'closed is 0');
Test::More::is($o->stamped, 1, 'stamped is 1');
};
{
#line 289  log

my $o = Basset::Logger->new();
Test::More::ok($o, "got object");
Test::More::is($o->close, 1, "closing non-existent handle is fine");
Test::More::is($o->closed, 0, "handle remains open");

Test::More::is(scalar($o->log('foo')), undef, "Cannot log w/o handle");

Test::More::is($o->closed(1), 1, "closed handle");
Test::More::is(scalar($o->log), undef, "Cannot log w/o note");
Test::More::is($o->errcode, "BL-07", "proper error code");
Test::More::is(scalar($o->log('foo')), undef, "Cannot log to closed handle");
Test::More::is($o->errcode, "BL-08", "proper error code");


local $@ = undef;
eval "use File::Temp";
my $file_temp_exists = $@ ? 0 : 1;

if ($file_temp_exists) {
	{
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		Test::More::is(ref($o->handle($name)), 'GLOB', "created glob");
		Test::More::is($o->log('foo'), 1, "logged foo to file");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			Test::More::like($in_file, qr{^AT \(\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+\):\tfoo\n$}, "data was logged to file with stamp");
		}
	}
	{
		Test::More::is($o->stamped(0), 0, "shut off time stamping");
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		Test::More::is(ref($o->handle($name)), 'GLOB', "created glob");
		Test::More::is($o->log('foo'), 1, "logged foo to file");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			Test::More::like($in_file, qr{^foo\n$}, "data was logged to file without stamp");
		}
		Test::More::is($o->stamped(1), 1, "turned on time stamping");
	}
	{
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		Test::More::is(ref($o->handle($name)), 'GLOB', "created glob");
		Test::More::is($o->log({'args' => ['foo']}), 1, "logged foo to file in note");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			Test::More::like($in_file, qr{^AT \(\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+\):\tfoo\n$}, "data was logged to file with stamp");
		}
	}
	{
		Test::More::is($o->stamped(0), 0, "shut off time stamping");
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		Test::More::is(ref($o->handle($name)), 'GLOB', "created glob");
		Test::More::is($o->log({'args' => ['foo']}), 1, "logged foo to file in note");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			Test::More::like($in_file, qr{^foo\n$}, "data was logged to file without stamp");
		}
		Test::More::is($o->stamped(1), 1, "turned on time stamping");
	}
	{
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		Test::More::is(ref($o->handle($name)), 'GLOB', "created glob");
		Test::More::is($o->log({'args' => ['foo', 'bar']}), 1, "logged foo, bar to file in note");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			Test::More::like($in_file, qr{^AT \(\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+\):\tfoo\n\tbar\n$}, "data was logged to file with stamp");
		}
	}
	{
		Test::More::is($o->stamped(0), 0, "shut off time stamping");
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		Test::More::is(ref($o->handle($name)), 'GLOB', "created glob");
		Test::More::is($o->log({'args' => ['foo', 'bar']}), 1, "logged foo, bar to file in note");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			Test::More::like($in_file, qr{^foo\n\tbar\n$}, "data was logged to file with stamp");
		}
		Test::More::is($o->stamped(1), 1, "turned on time stamping");
	}
	{
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		Test::More::is(ref($o->handle($name)), 'GLOB', "created glob");
		Test::More::is($o->log({'args' => ['foo', undef]}), 1, "logged foo, undef to file in note");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			Test::More::like($in_file, qr{^AT \(\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+\):\tfoo\n$}, "data was logged to file with stamp");
		}
	}
	{
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		Test::More::is(ref($o->handle($name)), 'GLOB', "created glob");
		Test::More::is($o->log({}), 1, "logged empty note to file in note");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			Test::More::is($in_file,'', "no data logged w/o args");
		}
	}
}
};
{
#line 435  close

my $o = Basset::Logger->new();
Test::More::ok($o, "got object");
Test::More::is($o->close, 1, "closing non-existent handle is fine");
Test::More::is($o->closed, 0, "handle remains open");

local $@ = undef;
eval "use File::Temp";
my $file_temp_exists = $@ ? 0 : 1;

if ($file_temp_exists) {
	my $temp = File::Temp->new;
	my $name = $temp->filename;
	Test::More::is(ref($o->handle($name)), 'GLOB', "created glob");
	Test::More::is($o->closed, 0, "file handle is open");
	Test::More::is($o->close, 1, "closed file handle");
	Test::More::is($o->closed, 1, "filehandle is closed");
}
};
