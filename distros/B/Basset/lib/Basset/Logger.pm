package Basset::Logger;

#Basset::Logger, copyright and (c) 2004, 2006 James A Thomason III
#Basset::Logger is distributed under the terms of the Perl Artistic License.

=pod

=head1 NAME

Basset::Logger - Logger object. Writes things to files.

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 DESCRIPTION

my $logger = Basset::Logger->new(
	'handle' => '/tmp/weasels.log'
);

$logger->log("Weasels in the hen house!");

$logger->close();

Create a logger object, then log data to it, then close it when you're done. Easy as pie.
Works beautifully in conjunction with Basset::NotificationCenter.

You will B<need> to put a types entry into your conf file for

 logger=Basset::Logger

(or whatever center you're using)

=cut


$VERSION = '1.01';

use Basset::Object;
our @ISA = Basset::Object->pkg_for_type('object');

use strict;
use warnings;

=pod

=head1 ATTRIBUTES

=over

=item handle

The place you log to. Either a string (which will be opened in append mode) or a globref.

 $logger->handle('/path/to/log.log');
 open (LOG, ">>/path/to/log.log");
 $logger->handle(\*LOG);

=cut

__PACKAGE__->add_attr(['handle', '_isa_file_accessor']);

=pod

=begin btest handle

my $o = __PACKAGE__->new();
$test->ok($o, "Got object for handle");
$test->is(scalar($o->handle($o)), undef, "Cannot set handle to unknown reference");
$test->is($o->errcode, "BL-03", "proper error code");

local $@ = undef;
eval "use File::Temp";
my $file_temp_exists = $@ ? 0 : 1;

if ($file_temp_exists) {
	my $temp = File::Temp->new;
	my $name = $temp->filename;
	$test->is(ref($o->handle($name)), 'GLOB', "created glob");
	open (my $glob, $name);
	$test->is($o->handle($glob), $glob, "set glob");
	chmod 000, $name;
	$test->is(scalar($o->handle($name)), undef, "could not set handle to unwritable file");
	$test->is($o->errcode, "BL-01", "proper error code");
}

=end btest

=cut


=pod

=item closed

=cut

__PACKAGE__->add_attr('closed');

=pod

=begin btest closed

{
	my $o = __PACKAGE__->new();
	$test->ok($o, "Got object");
	$test->is(scalar(__PACKAGE__->closed), undef, "could not call object method as class method");
	$test->is(__PACKAGE__->errcode, "BO-08", "proper error code");
	$test->is(scalar($o->closed), 0, 'closed is 0 by default');
	$test->is($o->closed('abc'), 'abc', 'set closed to abc');
	$test->is($o->closed(), 'abc', 'read value of closed - abc');
	my $h = {};
	$test->ok($h, 'got hashref');
	$test->is($o->closed($h), $h, 'set closed to hashref');
	$test->is($o->closed(), $h, 'read value of closed  - hashref');
	my $a = [];
	$test->ok($a, 'got arrayref');
	$test->is($o->closed($a), $a, 'set closed to arrayref');
	$test->is($o->closed(), $a, 'read value of closed  - arrayref');
}

my $o = __PACKAGE__->new();
$test->ok($o, "got object");
$test->is($o->close, 1, "closing non-existent handle is fine");
$test->is($o->closed, 0, "handle remains open");

local $@ = undef;
eval "use File::Temp";
my $file_temp_exists = $@ ? 0 : 1;

if ($file_temp_exists) {
	my $temp = File::Temp->new;
	my $name = $temp->filename;
	$test->is(ref($o->handle($name)), 'GLOB', "created glob");
	$test->is($o->closed, 0, "file handle is open");
	$test->is($o->close, 1, "closed file handle");
	$test->is($o->closed, 1, "filehandle is closed");
}

=end btest

=cut


=pod

=item stamped

=cut

__PACKAGE__->add_attr('stamped');

=pod

=begin btest stamped

my $o = __PACKAGE__->new();
$test->ok($o, "Got object");
$test->is(scalar(__PACKAGE__->stamped), undef, "could not call object method as class method");
$test->is(__PACKAGE__->errcode, "BO-08", "proper error code");
$test->is(scalar($o->stamped), 1, 'stamped is 1 by default');
$test->is($o->stamped('abc'), 'abc', 'set stamped to abc');
$test->is($o->stamped(), 'abc', 'read value of stamped - abc');
my $h = {};
$test->ok($h, 'got hashref');
$test->is($o->stamped($h), $h, 'set stamped to hashref');
$test->is($o->stamped(), $h, 'read value of stamped  - hashref');
my $a = [];
$test->ok($a, 'got arrayref');
$test->is($o->stamped($a), $a, 'set stamped to arrayref');
$test->is($o->stamped(), $a, 'read value of stamped  - arrayref');

=end btest

=cut


sub init {
	return shift->SUPER::init(
		'closed' => 0,
		'stamped' => 1,
		@_
	);
};

=pod

=begin btest init

my $o = __PACKAGE__->new();
$test->ok($o, "Got logger object");
$test->is($o->closed, 0, 'closed is 0');
$test->is($o->stamped, 1, 'stamped is 1');

=end btest

=cut


# _file_accessor is a dumbed down version of the one in Mail::Bulkmail.
#
# _file_accessor is an internal accessor for accessing external information. Said external information can be a
# path to a file or a globref containing an already openned file handle. It will open up path/to/file strings and 
# create an internal filehandle. it also makes sure that all filehandles are piping hot.

sub _isa_file_accessor {
	my $pkg = shift;
	my $attr = shift;
	my $prop = shift;
	
	return sub  {
		my $self	= shift;
		my $file	= shift;
	
		if (defined $file){
			if (! ref $file) {
				my $handle = $self->gen_handle();
				open ($handle, ">>" . $file)
					or return $self->error("Could not open file $file : $!", "BL-01");
				select((select($handle), $| = 1)[0]); 		#Make sure the file is piping hot!
				$self->closed(0);
				return $self->$prop($handle);
			}
			elsif (ref ($file) eq 'GLOB') {
				select((select($file), $| = 1)[0]); 		#Make sure the file is piping hot!
				$self->closed(0);
				return $self->$prop($file);
			}
			else {
				return $self->error("File error. I don't know what a $file is", "BL-03");
			};
		}
		else {
			return $self->$prop();
		};
	}

};

=pod

=item log

logs the item to the logger's handle.

 $logger->log("one val", "two vals", "three vals");

prints out one per line, tab indented on subsequent lines.

 one val
 	two vals
 	three vals

=cut

sub log {
	my $self	= shift;
	my $note	= shift or return $self->error("Cannot log w/o notification", "BL-07");
	
	return $self->error("Cannot log to closed handle", "BL-08") if $self->closed;
	
	my $args	= ref $note ? $note->{'args'} || [] : [$note];

	my $handle	= $self->handle or return;

	my $printed = 0;
	
	if (@$args) {
	
		if ($self->stamped) {
			my $stamp = localtime;
			print $handle "AT (", $stamp, "):\t";
		};
	
		foreach my $value (@$args) {
			my $tab = $printed++ ? "\t" : "";
			print $handle $tab, $value, "\n" if defined $value;
		};
	}
	
	return 1;

};

=pod

=begin btest log

my $o = __PACKAGE__->new();
$test->ok($o, "got object");
$test->is($o->close, 1, "closing non-existent handle is fine");
$test->is($o->closed, 0, "handle remains open");

$test->is(scalar($o->log('foo')), undef, "Cannot log w/o handle");

$test->is($o->closed(1), 1, "closed handle");
$test->is(scalar($o->log), undef, "Cannot log w/o note");
$test->is($o->errcode, "BL-07", "proper error code");
$test->is(scalar($o->log('foo')), undef, "Cannot log to closed handle");
$test->is($o->errcode, "BL-08", "proper error code");


local $@ = undef;
eval "use File::Temp";
my $file_temp_exists = $@ ? 0 : 1;

if ($file_temp_exists) {
	{
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		$test->is(ref($o->handle($name)), 'GLOB', "created glob");
		$test->is($o->log('foo'), 1, "logged foo to file");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			$test->like($in_file, qr{^AT \(\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+\):\tfoo\n$}, "data was logged to file with stamp");
		}
	}
	{
		$test->is($o->stamped(0), 0, "shut off time stamping");
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		$test->is(ref($o->handle($name)), 'GLOB', "created glob");
		$test->is($o->log('foo'), 1, "logged foo to file");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			$test->like($in_file, qr{^foo\n$}, "data was logged to file without stamp");
		}
		$test->is($o->stamped(1), 1, "turned on time stamping");
	}
	{
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		$test->is(ref($o->handle($name)), 'GLOB', "created glob");
		$test->is($o->log({'args' => ['foo']}), 1, "logged foo to file in note");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			$test->like($in_file, qr{^AT \(\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+\):\tfoo\n$}, "data was logged to file with stamp");
		}
	}
	{
		$test->is($o->stamped(0), 0, "shut off time stamping");
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		$test->is(ref($o->handle($name)), 'GLOB', "created glob");
		$test->is($o->log({'args' => ['foo']}), 1, "logged foo to file in note");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			$test->like($in_file, qr{^foo\n$}, "data was logged to file without stamp");
		}
		$test->is($o->stamped(1), 1, "turned on time stamping");
	}
	{
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		$test->is(ref($o->handle($name)), 'GLOB', "created glob");
		$test->is($o->log({'args' => ['foo', 'bar']}), 1, "logged foo, bar to file in note");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			$test->like($in_file, qr{^AT \(\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+\):\tfoo\n\tbar\n$}, "data was logged to file with stamp");
		}
	}
	{
		$test->is($o->stamped(0), 0, "shut off time stamping");
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		$test->is(ref($o->handle($name)), 'GLOB', "created glob");
		$test->is($o->log({'args' => ['foo', 'bar']}), 1, "logged foo, bar to file in note");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			$test->like($in_file, qr{^foo\n\tbar\n$}, "data was logged to file with stamp");
		}
		$test->is($o->stamped(1), 1, "turned on time stamping");
	}
	{
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		$test->is(ref($o->handle($name)), 'GLOB', "created glob");
		$test->is($o->log({'args' => ['foo', undef]}), 1, "logged foo, undef to file in note");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			$test->like($in_file, qr{^AT \(\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+\):\tfoo\n$}, "data was logged to file with stamp");
		}
	}
	{
		my $temp = File::Temp->new;
		my $name = $temp->filename;
		$test->is(ref($o->handle($name)), 'GLOB', "created glob");
		$test->is($o->log({}), 1, "logged empty note to file in note");
		open (my $reader, $name);
		{
			local $/ = undef;
			my $in_file = <$reader>;
			$test->is($in_file,'', "no data logged w/o args");
		}
	}
}


=end btest

=cut



sub close {
	my $self = shift;

	my $handle	= $self->handle or return 1;
	
	close($handle) or return $self->error("Canot close handle : $!", "BL-06");
	
	$self->closed(1);
	
	return 1;
}

=pod

=begin btest close

my $o = __PACKAGE__->new();
$test->ok($o, "got object");
$test->is($o->close, 1, "closing non-existent handle is fine");
$test->is($o->closed, 0, "handle remains open");

local $@ = undef;
eval "use File::Temp";
my $file_temp_exists = $@ ? 0 : 1;

if ($file_temp_exists) {
	my $temp = File::Temp->new;
	my $name = $temp->filename;
	$test->is(ref($o->handle($name)), 'GLOB', "created glob");
	$test->is($o->closed, 0, "file handle is open");
	$test->is($o->close, 1, "closed file handle");
	$test->is($o->closed, 1, "filehandle is closed");
}

=end btest

=cut


sub DESTROY {
	my $self = shift;
	
	$self->close unless $self->closed;
	
	#$self->SUPER::DESTROY(@_);
}

1;
