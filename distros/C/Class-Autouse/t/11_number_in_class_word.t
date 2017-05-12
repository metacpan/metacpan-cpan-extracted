#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10; 
use File::Temp;
use IO::File;
use Class::Autouse;

# write a temp directory of modules for testing
my $temp_dir;
BEGIN {
	$temp_dir = File::Temp::tempdir(CLEANUP => 1);
}
use lib $temp_dir;

sub try_class {
	my $class = shift;
	my $msg = shift;
	my $r;
	eval { $r = $class->can("mymethod") };
	ok(!$@, "no exception calling can() on class when $msg");
	ok($r, "the can() method works for a real method when $msg");
	eval { $r = $r->() };
	is($r,"$class mymethod", "return value is as expected when $msg");
}

mkfile(class_name => 'SomeClass::123');
use_ok("SomeClass::123");
try_class("SomeClass::123", "used normally");

mkfile(class_name => 'SomeClass::456');
Class::Autouse->autouse("SomeClass::456");
try_class("SomeClass::456","used via Class::Autouse directly");

mkfile(class_name => 'SomeClass::789');
Class::Autouse->autouse(sub { my $class = shift; if ($class =~ /SomeClass::789/) { eval "use $class"  } });
try_class("SomeClass::789","used via Class::Autouse via callback");

sub mkfile {
	my (%args) = @_;
	my $cname = $args{'class_name'};
	my $fname = $cname;
	$fname =~ s/::/\//g;
	my $dname = $fname;
	$dname =~ s/\/[^\/]+//;
	mkdir( "$temp_dir/$dname" );
	die $! unless -d "$temp_dir/$dname";
	$fname =~ s/::/\//g;
	my $n1 = "$temp_dir/${fname}.pm";
	my $m1 = IO::File->new(">$n1");
	die "failed to create file $n1: $!" unless $m1;
	my $src = class_src(@_);
	$m1->print($src);
	$m1->close;
}

sub class_src {
	my (%args) = @_;
	my ($cname, $pname, $ptype, $has_autoload) = @args{'class_name','parent_class_name', 'parent_class_type', 'has_autoload'};

	my $src = <<EOS;
package $cname;

sub mymethod { "$cname mymethod" }

1;
EOS
	#print "####\n$src\n###\n";
	return $src;
}

