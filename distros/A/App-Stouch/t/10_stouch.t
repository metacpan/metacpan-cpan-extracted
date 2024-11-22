#!/usr/bin/perl
use 5.016;
use strict;
use warnings;

use Test::More;

use File::Find;
use File::Path qw(remove_tree);
use File::Spec;

use App::Stouch;

plan tests => 18;

local $/ = undef;

my $TEMPLATE_DIR = File::Spec->catfile(qw(t data templates));

@ARGV = (
	"-t", $TEMPLATE_DIR,
	"-p",  " foo => stuff ",
	"t.pl"
);

my $s1 = App::Stouch->init();
$s1->run();

ok(-f "t.pl", "Generated file was created");

is($s1->get('Template'), undef, "'Template' is ok");
is($s1->get('TemplateDir'), $TEMPLATE_DIR, "'TemplateDir' is ok");
is_deeply($s1->get('TemplateParam'), { foo => "stuff" }, "'TemplateParam' is ok");
is_deeply($s1->get('Files'), ['t.pl'], "'Files' is ok");

open my $ifh, '<', File::Spec->catfile(qw(t data ideality t.pl))
	or die "Faile to open t/data/ideality/t.pl for reading: $!";
open my $tfh, '<', "t.pl"
	or die "Failed to open t.pl for reading: $!";

is(readline $tfh, readline $ifh, "Generated file's contents look ok");

close $ifh;
close $tfh;

@ARGV = (
	"-t", $TEMPLATE_DIR,
	"-p", "prgnam => foo, prgver => bar, prgbin => baz",
	"-T", "c",
	"t.h",
);

my $s2 = App::Stouch->init();
$s2->run();

ok(-f "t.h", "Generated file was created");

is($s2->get('Template'), 'c', "'Template' is ok");
is($s2->get('TemplateDir'), $TEMPLATE_DIR, "'TemplateDir' is ok");
is_deeply($s2->get('TemplateParam'),
	{
		prgnam => "foo",
		prgver => "bar",
		prgbin => "baz",
	},
	"'TemplateParam' is ok"
);
is_deeply($s2->get('Files'), ['t.h'], "'Files' is ok");

open $ifh, '<', File::Spec->catfile(qw(t data ideality t.c))
	or die "Failed to open t/data/ideality/t.c for reading: $!";
open $tfh, '<', "t.h",
	or die "Failed to open t.h for reading $!";

is(readline $ifh, readline $tfh, "Generated file's contents look ok");

close $ifh;
close $tfh;

@ARGV = (
	"-t", $TEMPLATE_DIR,
	"t.dir"
);

my $s3 = App::Stouch->init();
$s3->run();

ok(-d "t.dir", "Generated directory was created");

is($s3->get('Template'), undef, "'Template' is ok");
is($s3->get('TemplateDir'), $TEMPLATE_DIR, "'TemplateDir' is ok");
is_deeply($s3->get('TemplateParam'), {}, "'TemplateParam' is ok");
is_deeply($s2->get('Files'), ['t.dir'], "'Files' is ok");

my (@il, @tl);
find(sub { push @il, $_ }, File::Spec->catfile(qw(t data ideality t.dir)));
find(sub { push @tl, $_ }, 't.dir');

is_deeply(\@tl, \@il, "Generated directory tree looks ok");

done_testing();

END {
	unlink      "t.pl"  if -e "t.pl";
	unlink      "t.h"   if -e "t.h";
	remove_tree "t.dir" if -e "t.dir";
}
