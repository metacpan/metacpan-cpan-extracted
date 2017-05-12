package App::AutoBuild;
use strict;
use warnings;

=head1 NAME

App::AutoBuild - A perl tool to make it quick and easy to compile a C/C++ project with automatic compilation of dependencies

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Example project layout:

build.pl

	#!/usr/bin/perl
	use App::AutoBuild qw(build shell_config);

	build({
		'cflags'=>[qw(-O2 -Isrc/ -Wall -Wextra), shell_config('sdl-config', '--cflags')],
		'ldflags'=>[qw(-lSDL_image -lm), shell_config('sdl-config', '--libs')],
		'programs'=>{
			# each output executable goes here.  you can list several.
			'main'=>'src/main.c',
		},
	});

src/main.c

	#include "stuff.h"

	int main(int argc, char** argv)
	{
		stuff_function();
		return 0;
	}

src/stuff.c

	#include "stuff.h"

	void stuff_function()
	{
		// hai
	}

src/stuff.h

	#pragma once

	void stuff_function();

Note you don't need to put stuff.c into your build.pl--  it Just Works(tm).

An even shorter example-- instead of a build.pl:

build.sh

	#!/bin/sh

	export CC="clang"
	export CFLAGS="-std=c99 -pedantic -Wall -Wextra -O3"

	perl -MApp::AutoBuild -e 'build("main.c");' -- $@

=head1 COMMAND LINE

	usage: ./build.pl [-h|--help] [-v] [clean]

		-h, --help: dump help

		-v: increase verbosity (-vv or more -v's)
			0 (default) only show compile/link actions, in shortened form
			1 show compile/link actions with full command lines, and at the end a time summary (also shows App::AutoBuild overhead)
			2 shows debugging for job numbers (not useful really yet)

		-d: increase debugosity (-dd or more -d's)
			0 (default) nothing!
			1 show which dependencies caused a recompile
			2 show stat() calls

		-q: be more quiet

		--cc=(compiler path): pick a compiler other than gcc

		--program=(program): don't compile all targets, just this one

		clean: unlink output files/meta file (.autobuild_meta)

=head1 DESCRIPTION

After writing a makefile for my 30th C project, I decided this was dumb and it (the computer) should figure out which object files should be linked in or recompiled.  The idea behind this module is you create a build.pl that uses App::AutoBuild and calls build() with cflags and ldflags, an output binary filename, and a C file to start with (usually the C file with main()).

App::AutoBuild will figure out all the object files your C file depends on.  A list of included header files (.h) will be computed by GCC and remembered in a cache.  At build time, stat() is called on each header file included by your .c file.  If any have a different mtime, the .c file will be recompiled.  If you include a .h file that has a corresponding .c file, this process repeats and the output object code will be linked into your final binary automatically.

This tool isn't supposed to be a make replacement-- there are plenty of those, and at least one great one already in Perl.  The idea is that the build system should know enough about the source code to do what you want for you.  This replaces all the functionality of a makefile for a standard C project with the added bonus of having it only link in the objects that are actually used in each output target.

=head1 CAVEATS

For this to work properly, you must have a scheme and follow it.  Every .c/.cpp file must have an .h/.hpp file that matches (with the exception of the .c/.cpp file with main()).  For now, the .c and .h files must be in the same directory (but this may be fixed in the future).

If you have a .h file and an unrelated .c file with the same name (as in, headers.h and headers.c) in the same folder, the .c file will be compiled and linked in automatically.  If this doesn't work well for you, put the .h files without .c files into a different folder (i.e. "include/") or something.

A .autobuild_meta file is created in the current directory so it can remember modification times and dependency lists of files.  This will definitely be configurable in a future version!

=head1 SUBROUTINES/METHODS

These are exported by default.

=head2 build()

Pass this function a hashref of parameters for how to build your project.  Keys are as follows:

=head3 cflags

An arrayref of cflags

=head3 ldflags

An arrayref of ldflags

=head3 programs

A hashref with binaries as keys, and start-point C files as values.

=head3 rules

An arrayref of rule hashrefs.  See L</RULES>.

=head2 shell_config()

This is a helper function that takes a shell command + args (as an array) to pass to system() and splits the STDOUT into an array by whitespace.

I do all this as arrays because the CFLAGS/LDFLAGS can be added or removed per-file with rules.

=head1 RULES

Rules let you have custom build options per-file.  For now it only supports adding/removing cflags for a given .c file, or adding/removing ldflags for a given output binary.

	{'file'=>'contrib/GLee/GLee.c', 'del_cflags'=>['-pedantic']},
	{'file'=>'configtest', 'add_ldflags'=>['-lyaml'], 'del_ldflags'=>['-lGL', '-lGLU', shell_config('sdl-config', '--libs')]},

These definitely need some more work!

=head1 AUTHOR

Joel Jensen, C<< <yobert at gmail.com> >>

=head1 BUGS/TODO

Please email me if it doesn't work!  I've only tested with GCC and clang.

Job paralellizing would be sweet.  Patches welcome.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Joel Jensen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

use Time::HiRes qw(time);
use Storable qw(store retrieve);
use Digest::MD5();
use autodie qw(system);

use Exporter qw(import);
our @EXPORT = qw(build shell_config);

my $meta_file = '.autobuild_meta';

my $next_jid = 0;
my $system_runtime = 0;

sub build
{
	my $opts = shift;

	if(ref($opts) eq '')
	{
		my $bin = $opts;
		$bin =~ s/\.cp?p?$//;
		$opts = {'programs'=>{$bin=>$opts}};
	}

	my $start = time;

	my $ab = App::AutoBuild->new();
	$ab->args(\@ARGV);

	my @cflags;
	my @ldflags;

	push @cflags, split(/\s+/, $ENV{'CFLAGS'}) if($ENV{'CFLAGS'});
	push @ldflags, split(/\s+/, $ENV{'LDFLAGS'}) if($ENV{'LDFLAGS'});

	push @cflags, @{$opts->{'cflags'}} if($opts->{'cflags'});
	push @ldflags, @{$opts->{'ldflags'}} if($opts->{'ldflags'});

	$ab->cflags(\@cflags);
	$ab->ldflags(\@ldflags);

	if($ENV{'CC'})
	{
		$ab->{'cc'} = $ENV{'CC'};
	}

	for(qw(cc osuffix))
	{
		$ab->{$_} = $opts->{$_} if($opts->{$_});
	}

	$ab->{'rules'} = $opts->{'rules'} || []; # HACK for now until I decide the right way to do this

	for my $bin (keys %{ $opts->{'programs'} })
	{
		if($ab->{'clean'} || !$ab->{'default'} || $ab->{'default'}{$bin})
		{
			$ab->program($opts->{'programs'}{$bin}, $bin);
		}
	}

	my $moar = 1;

	while($moar)
	{
		#$ab->debug_jobs();
		#<STDIN>;
		$moar = $ab->run();
	};

	my $end = time;

	if($ab->{'verbose'} > 0)
	{
		printf(
			"AutoBuild.pm runtime: %.3fs\n".
			"    system() runtime: %.3fs\n".
			"            overhead: %.3fs\n",
			$end - $start,
			$system_runtime,
			($end - $start) - $system_runtime);
	}

	return;
}

sub shell_config
{
	my @cmdline = @_;

	# TODO use system() for this

	my $run = join(' ', @cmdline);
	my $txt = `$run`;
	chomp($txt);

	return split(/\s+/, $txt);
}

sub new
{
	my($class) = @_;
	$class = ref($class) || $class;
	my $self = bless({}, $class);

	if(-e $meta_file)
	{
		$self->{'meta'} = retrieve($meta_file);
	}else
	{
		$self->{'meta'} = {};
	}

	# some defaults
	$self->{'verbose'} = 0;
	$self->{'debug'} = 0;
	$self->{'cc'} = 'gcc';
	$self->{'cpp'} = 'g++';
	$self->{'osuffix'} = 'o';

	$self->{'jobs'} = [];
	$self->{'job_index'} = {};

	return($self);
}

sub DESTROY
{
	my($self) = @_;
	if($self->{'clean'})
	{
		$self->unlink_file($meta_file);
	}else
	{
		store($self->{'meta'}, $meta_file);
	}
	return;
}

sub args
{
	my($self, $argv) = @_;

	for(@$argv)
	{
		if($_ =~ m/^-(v+)$/)
		{
			$self->{'verbose'} += length($1);
		}
		elsif($_ =~ m/^-(d+)$/)
		{
			$self->{'debug'} += length($1);
		}
		elsif($_ eq '-q')
		{
			$self->{'quiet'} = 1;
		}
		elsif($_ eq 'clean')
		{
			$self->{'clean'} = 1;
		}
		elsif($_ =~ m/^--cc=(.+)$/)
		{
			$self->{'cc'} = $1;
		}
		elsif($_ =~ m/^--program=(.+)$/)
		{
			$self->{'default'}{$1} = 1;
		}
		elsif($_ eq '-h' || $_ eq '--help')
		{
			print <<"zap";
usage: $0 [-h|--help] [-v] [clean]

	-h, --help: dump help

	-v: increase verbosity (-vv or more -v's)
		0 (default) only show compile/link actions, in shortened form
		1 show compile/link actions with full command lines, and at the end a time summary (also shows App::AutoBuild overhead)
		2 shows debugging for job numbers (not useful really yet)

	-d: increase debugosity (-dd or more -d's)
		0 (default) nothing!
		1 show which dependencies caused a recompile
		2 show stat() calls

	clean: unlink output files/meta file ($meta_file)
zap
			exit(1);
		}
		else
		{
			warn "ignoring unknown commandline option $_";
		}
	}
}

sub cflags
{
	my($self, $v) = @_;
	if($v)
	{
		$self->{'cflags'} = $v;
	}
	return $self->{'cflags'};
}
sub ldflags
{
	my($self, $v) = @_;
	if($v)
	{
		$self->{'ldflags'} = $v;
	}
	return $self->{'ldflags'};
}


sub program
{
	my($self, $cfile, $out) = @_;

	my %job = (
			'out'=>$out,
			'task'=>'ld',
		);

	my $jid = $self->add_job(\%job);

	$job{'needs'} = [$self->add_build_job($cfile, $jid)];
}

sub add_build_job
{
	my($self, $cfile) = @_;

	my $cpp = 0;
	if(substr($cfile, -4, 4) eq '.cpp')
	{
		$self->{'cpp_ld'} = 1;
		$cpp = 1;
	}
	# otherwise assume C instead of C++

	my $ofile = replace_ext($cfile, $self->{'osuffix'});
	$ofile =~ s/([^\/]+)$/\.$1/;

	my $job_key = $ofile; # add CFLAGS to this when that's customizable per binary
	if(my $existing_jid = $self->{'job_index'}{$job_key})
	{
		return $existing_jid; # dont add a job
	}

	my %job = (
			'cfile'=>$cfile,
			'out'=>$ofile,
			'task'=>'cc',
			'cpp'=>$cpp,
		);

	my $jid = $self->add_job(\%job);
	$self->{'job_index'}{$job_key} = $jid;
	return $jid;
}

sub add_job
{
	my($self, $job) = @_;
	$self->{'jobs'}[$next_jid] = $job;
	return $next_jid++;
}

sub needs_recurse
{
	my($self, $jid) = @_;

	my @r = ($jid);
	my %dups = ($jid=>1);
	my %recursed;

	my $more = 1;

	while($more)
	{
		$more = 0;
		for my $i (@r)
		{
			next if($recursed{$i});
			$recursed{$i} = 1;
			my $n = $self->{'jobs'}[$i]{'needs'};
			next unless($n);
			for my $id (@$n)
			{
				if(!$dups{$id})
				{
					push @r, $id;
					$dups{$id} = 1;
					$more = 1;
				}
			}
		}
	}

	shift @r; # take off our initial job id

	return \@r;
}

sub debug_jobs
{
	my($self) = @_;

	print "\n";
	for(my $i = 0; $i < $next_jid; $i++)
	{
		my $job = $self->{'jobs'}[$i];
		print " job $i: ".$job->{'task'}.' '.$job->{'out'};

		if($job->{'needs'} && scalar @{ $job->{'needs'} })
		{
			print " (needs ".join(', ', @{ $job->{'needs'} }).")";
		}

		if($job->{'done'})
		{
			print " DONE";
		}

		print "\n";
	}
}

sub run
{
	my($self) = @_;

	my @can;

	for(my $i = 0; $i < $next_jid; $i++)
	{
		my $job = $self->{'jobs'}[$i];
		if($job->{'done'})
		{
			next;
		}

		my $met = 1;

		for my $ni (@{ $self->needs_recurse($i) })
		{
			if(!$self->{'jobs'}[$ni]{'done'})
			{
				$met = 0;
			}
		}

		if($met)
		{
			push @can, $i;
		}
	}

	my $r = 0;

	for my $i (@can)
	{
		if($self->{'verbose'} > 1)
		{
			print "executing job $i\n";
		}

		if($self->exec_job($i))
		{
			$r = 1;
		}
	}

	return $r;
}

sub exec_job
{
	my($self, $jid) = @_;
	my $job = $self->{'jobs'}[$jid];

	if($job->{'task'} eq 'cc')
	{
		my $ofile = $job->{'out'};
		my $cfile = $job->{'cfile'};
		my $depfile = $cfile.'.deps';

		my $headers = $self->{'meta'}{$cfile}{'headers'};

		my @cflags = @{ $self->{'cflags'} };
		for my $rule (@{ $self->{'rules'} })
		{
			my $fm = $rule->{'filematch'};
			if(($rule->{'file'} && ($rule->{'file'} eq $cfile || $rule->{'file'} eq $ofile)) ||
			   ($fm && ($cfile =~ m/$fm/ || $ofile =~ m/$fm/)))
			{
				my $add = $rule->{'add_cflags'};
				my $del = $rule->{'del_cflags'};
				if($add)
				{
					for my $f (@$add)
					{
						if(!grep { $_ eq $f } @cflags)
						{
							push @cflags, $f;
						}
					}
				}
				if($del)
				{
					@cflags = grep { my $f = $_; ! grep { $f eq $_ } @$del } @cflags;
				}
			}
		}

		my $exec = $job->{'cpp'} ? $self->{'cpp'} : $self->{'cc'};

		my @gcc = grep { $_ } (
			$exec,
			@cflags,
			'-MF', $depfile, '-MMD',
			'-c', $cfile,
			'-o', $ofile,
		);
		my $exec_str = join(' ', @gcc);

		my @check = ($ofile);
		for(@$headers)
		{
			next if(substr($_, 0, 1) eq '/');
			push @check, $_;
		}

		my $changed = 1;

		if($self->{'meta'}{$ofile})
		{
			if($self->{'meta'}{$ofile}{'exec'} && $self->{'meta'}{$ofile}{'exec'} eq $exec_str)
			{
				$changed = 0;
				if($self->{'debug'} > 2)
				{
					print "cc $ofile has the same GCC options\n";
				}
			}elsif($self->{'debug'})
			{
				print "cc $ofile has changed GCC options\n";
			}
		}

		for my $f (@check)
		{
			if($self->file_changed($f))
			{
				$changed = 1;
				if($self->{'debug'})
				{
					print "cc $cfile has changed dep $f\n";
				}
			}else
			{
				if($self->{'debug'} > 2)
				{
					print "cc $cfile  no changed dep $f\n";
				}
			}
		}

		if($self->{'clean'})
		{
			$self->unlink_file($ofile);
		}
		elsif($changed)
		{

			if($self->{'verbose'})
			{
				print $exec_str."\n";
			}elsif(!$self->{'quiet'})
			{
				print $job->{'cpp'} ? 'cc++ ' : 'cc   ';
				print "$cfile..\n";
			}

			my $start = time;
			system(@gcc);
			$system_runtime += (time - $start);

			$headers = slurp_depfile($depfile);
			$self->{'meta'}{$cfile}{'headers'} = $headers;

			# remember the new md5sum/mtime
			if($self->file_update($ofile))
			{
				$job->{'updated'} = 1;
			}
			$self->{'meta'}{$ofile}{'exec'} = $exec_str;

			for(@$headers)
			{
				next if(substr($_, 0, 1) eq '/');
				$self->file_changed($_);
			}

		}

		my @needs;

		for my $hfile (@$headers)
		{
			next if(substr($hfile, 0, 1) eq '/');
			# look for a matching c file
			my $c = replace_ext($hfile, 'c');
			# look for a matching cpp file
			$c = replace_ext($hfile, 'cpp') if(!-e $c);
			next unless(-e $c);

			push @needs, $self->add_build_job($c);
		}

		$job->{'needs'} = \@needs;
		$job->{'done'} = 1;

		return 1;
	}

	if($job->{'task'} eq 'ld')
	{
		my $out = $job->{'out'};

		my $any_changed = $self->file_changed($out);

		my $needs = $self->needs_recurse($jid);
		my @ofiles;
		for my $n (@{ $self->needs_recurse($jid) })
		{
			my $oj = $self->{'jobs'}[$n];
			push @ofiles, $oj->{'out'};
			if($oj->{'updated'})
			{
				$any_changed = 1;
				if($self->{'debug'})
				{
					print "ld $out has changed dep ".$oj->{'out'}."\n";
				}
			}
		}

		my @ldflags = @{ $self->{'ldflags'} };
		for my $rule (@{ $self->{'rules'} })
		{
			if($rule->{'file'} && $rule->{'file'} eq $out)
			{
				my $add = $rule->{'add_ldflags'};
				my $del = $rule->{'del_ldflags'};
				if($add)
				{
					for my $f (@$add)
					{
						if(!grep { $_ eq $f } @ldflags)
						{
							push @ldflags, $f;
						}
					}
				}
				if($del)
				{
					@ldflags = grep { my $f = $_; ! grep { $f eq $_ } @$del } @ldflags;
				}
			}
		}

		my $exec = $self->{'cpp_ld'} ? $self->{'cpp'} : $self->{'cc'};
		my @gcc = grep { $_ } (
			$exec,
			@ldflags,
			@ofiles,
			'-o', $out,
		);
		my $exec_str = join(' ', @gcc);

		if(!$self->{'meta'}{$out} || !$self->{'meta'}{$out}{'exec'} || $self->{'meta'}{$out}{'exec'} ne $exec_str)
		{
			$any_changed = 1;
			if($self->{'debug'})
			{
				print "cc $out has changed GCC options\n";
			}
		}else
		{
			if($self->{'debug'} > 2)
			{
				print "cc $out has the same GCC options\n";
			}
		}

		if($self->{'clean'})
		{
			$self->unlink_file($out);
		}
		elsif($any_changed)
		{
			if($self->{'verbose'})
			{
				print $exec_str."\n";
			}elsif(!$self->{'quiet'})
			{
				print $self->{'cpp_ld'} ? "ld++ " : "ld   ";
				print "$out..\n";
			}

			my $start = time;
			system(@gcc);
			$system_runtime += (time - $start);

			$self->file_update($out);
			$self->{'meta'}{$out}{'exec'} = $exec_str;
		}else
		{
			if($self->{'verbose'})
			{
				print "Already up to date: $out\n";
			}
		}

		$job->{'done'} = 1;
		return 1;
	}

	die "bad task type: ".($job->{'task'} // 'undef');
}

sub slurp_depfile
{
	my($depfile) = @_;

	open(my $dat, '<', $depfile) || die $!;
	my $slurp = do { local $/ = undef; <$dat> };
	close($dat) || die $!;

	unlink($depfile);

	$slurp =~ s/^.+:\s+//;
	$slurp =~ s/\\\n/ /gsm;

	my @incs = grep { length } split(/\s+/, $slurp);

	return \@incs;
}

sub replace_ext
{
	my($in, $ext) = @_;
	$in =~ s/\.[^.]{1,3}$//;
	$in .= '.'.$ext;
	return $in;
}

sub file_changed
{
	my($self, $file) = @_;

	if(defined $self->{'changed_this_run'}{$file})
	{
		return $self->{'changed_this_run'}{$file};
	}

	if(-e $file)
	{
		my $mtime = $self->mtime($file);
		#my $md5 = $self->md5($file);

		if($self->{'meta'}{$file} && $self->{'meta'}{$file}{'mtime'} && $self->{'meta'}{$file}{'mtime'} == $mtime)
		{
			$self->{'changed_this_run'}{$file} = 0;
			return 0;
		}

		#if($self->{'meta'}{$file} && $self->{'meta'}{$file}{'md5'} && $self->{'meta'}{$file}{'md5'} eq $md5)
		#{
		#	$self->{'changed_this_run'}{$file} = 0;
		#	return 0;
		#}

		$self->{'meta'}{$file}{'mtime'} = $mtime;
		#$self->{'meta'}{$file}{'md5'} = $md5;
	}

	$self->{'changed_this_run'}{$file} = 1;
	return 1;
}
sub file_update
{
	my($self, $file) = @_;

	delete $self->{'mtime_this_run'}{$file};
	delete $self->{'md5_this_run'}{$file};
	delete $self->{'changed_this_run'}{$file};
	return $self->file_changed($file);
}

sub mtime
{
	my($self, $file) = @_;
	if($self->{'mtime_this_run'}{$file})
	{
		return $self->{'mtime_this_run'}{$file};
	}
	if($self->{'debug'} > 1)
	{
		print "stat('$file');\n";
	}
	my @s = stat($file);
	$self->{'mtime_this_run'}{$file} = $s[9];
	return $s[9];
}

sub md5
{
	my($self, $file) = @_;
	if($self->{'md5_this_run'}{$file})
	{
		return $self->{'md5_this_run'}{$file};
	}
	if($self->{'debug'} > 1)
	{
		print " md5('$file');\n";
	}
	open(my $dat, '<', $file) || die "cannot open file for md5: $!";
	my $md5 = Digest::MD5->new();
	$md5->addfile($dat);
	close($dat);
	my $sum = $md5->hexdigest();
	$self->{'md5_this_run'}{$file} = $sum;
	return $sum;
}

sub unlink_file
{
	my($self, $file) = @_;

	if(-e $file)
	{
		if($self->{'verbose'})
		{
			print "unlink('$file');\n";
		}
		unlink($file) || die "could not unlink $file: $!";
	}
}

1;
