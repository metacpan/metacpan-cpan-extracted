#!/usr/bin/perl
use utf8;
use v5.10;

package App::scriptdist;

use strict;
use warnings;

use vars qw(
	@EXPORT @EXPORT_OK %EXPORT_TAGS
	%Content $VERSION
	$Quiet
	);

$VERSION = '1.004';

@EXPORT_OK = qw(
	prompt find_files copy gitify content
	script_template
	%Content
	);
%EXPORT_TAGS = (
	'all' => [ @EXPORT_OK ],
	);

$Quiet = 0;

use Exporter qw(import);

use Cwd;
use ExtUtils::Command;
use ExtUtils::Manifest;
use File::Basename qw(basename);
use File::Find qw(find);
use File::Spec;
use FindBin ();

=encoding utf8

=head1 NAME

App::scriptdist - create a distribution around a perl script

=head1 SYNOPSIS

	use App::scriptdist qw(:all);

=head1 DESCRIPTION

This module provides the utility functions for the scriptdist program
that builds a basic Perl CPAN distribution around a standalone script
file that already exists.

I do not intend this for new development and don't want to create an
authoring tool. You can do that with some other tool (or fork this
one and build your own).

=head1 FUNCTIONS

=over 4

=item prompt( QUERY )

Provide a prompt, get the response, chomp the neewline, and return
the answer.

=cut

sub prompt {
	my( $query ) = shift;

	print $query;

	chomp( my $reply = <STDIN> );

	return $reply;
	}

=item find_files( DIRECTORY )

Find all the files under a directory.

=cut

sub find_files {
	my $directory = shift;

    my @files = ();

	my $wanted = sub {
		return unless -f $_;
		return if $_ =~ m<(?:CVS|\.svn|\.git)>;
		push @files, File::Spec->canonpath( $File::Find::name );
		};

    my %options = (
    	wanted => $wanted,
    	);

    find( \%options, $directory );

    return @files;
	}

=item copy( INPUT_FILE, OUTPUT_FILE, CONFIG_HASH )

Copy the file from one place to another.

=cut

sub copy {
	my( $input, $output, $hash ) = @_;

	print STDERR "Opening input [$input] for output [$output]\n";

	open my $in_fh,  '<', $input  or die "Could not open [$input]: $!\n";
	open my $out_fh, '>', $output or warn "Could not open [$output]: $!\n";

	my $count = 0;

	while( readline $in_fh ) {
		$count += s/%%SCRIPTDIST_(.*?)%%/$hash->{ lc $1 } || ''/gie;
		print {$out_fh} $_
		}

	print STDERR "Copied [$input] with $count replacements\n" unless $Quiet;
	}

=item gitify()

Unless the environment variable C<SCRIPTDIST_SKIP_GIT> is set, init
a git repo, add all the files, and make the initial commit.

=cut

sub gitify {
	return if $ENV{SCRIPTDIST_SKIP_GIT};
	chomp( my $git = `which git` );
	return unless length $git && -x $git;

	system $git, qw'init';
	system $git, qw'add .';
	system $git, qw'commit -a -m ', "Initial commit by $0 $VERSION";
	}

=item script_template( SCRIPT_NAME )

Return the script template.

=cut

sub script_template {
	my $script_name = shift;

	# Test::Pod thinks this stuff is pod if it's at the beginning
	# of the line
	my $script = <<"HERE";
	#!/usr/bin/perl

	=head1 NAME

	$script_name - this script does something

	=head1 SYNOPSIS

	=head1 DESCRIPTION

	=head1 AUTHOR

	=head1 COPYRIGHT

	=cut
HERE

	$script =~ s/^\s+//gm;

	return $script;
	}

=item content( CONFIG_HASH )

Return a hash reference of the contents of the files to add. The key
is the filename and the value is its contents.

=cut

sub content {
	my $hash = shift;

	$Content{"Changes"} =<<"CHANGES";
0.10 - @{ [ scalar localtime ] }
	+ initial distribution created with $hash->{name}
CHANGES

	$Content{"Makefile.PL"} =<<"MAKEFILE_PL";
use ExtUtils::MakeMaker 6.48;

eval "use Test::Manifest 1.21";

my \$script_name = "$$hash{script}";

WriteMakefile(
		'NAME'      => \$script_name,
		'VERSION'   => '$$hash{version}',

		'EXE_FILES' =>  [ \$script_name ],

		'PREREQ_PM' => {
@{ [
				join ",\n", (
					map ( {
						my $v = $_->version // 0;
						"\t\t\t" . $_->module . " => '$v'"
					} @{$hash->{modules}} ), ''
					),
 ] } 			},


		MIN_PERL_VERSION => $$hash{minimum_perl_version},

		clean => { FILES => "*.bak \$script_name-*" },
		);

1;
MAKEFILE_PL

	$Content{"MANIFEST.SKIP"} =<<"MANIFEST_SKIP";
#!include_default

\\.DS_Store
\\.releaserc
\\.svn
\\.git
$$hash{script}-.*

MANIFEST_SKIP

	$Content{".releaserc"} =<<"RELEASE_RC";
cpan_user @{[ $ENV{CPAN_USER} ? $ENV{CPAN_USER} : '' ]}
RELEASE_RC

	$Content{".gitignore"} =<<"GITIGNORE";
.DS_Store
.lwpcookies
$$hash{script}-*
blib
Makefile
pm_to_blib
GITIGNORE

	$Content{"t/test_manifest"} =<<"TEST_MANIFEST";
compile.t
pod.t
TEST_MANIFEST

	$Content{"t/pod.t"} = <<"POD_T";
use Test::More 0.98;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if \$@;
all_pod_files_ok();
POD_T

	$Content{"t/compile.t"} = <<"COMPILE_T";
use Test::More 0.98;

my \$file = "blib/script/$$hash{script}";

BAIL_OUT( "Script file is missing!" ) unless -e \$file;

my \$output = `$^X -c \$file 2>&1`;

BAIL_OUT( "Script file is missing!" ) unless
	like( \$output, qr/syntax OK\$/, 'script compiles' );

done_testing();
COMPILE_T

	\%Content;
	}

=back

=head1 TO DO

=over 4

=item * Copy modules into lib directory (to create module dist)

=item * Command line switches to turn things on and off

=back

=head2 Maybe a good idea, maybe not

=over 4

=item * Add a cover.t and pod coverage test?

=item * Interactive mode?

=back

=head1 SOURCE AVAILABILITY

This source is part of a Github project.

	https://github.com/briandfoy/scriptdist

=head1 CREDITS

Thanks to Soren Andersen for putting this script through its paces
and suggesting many changes to actually make it work.

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT

Copyright © 2004-2024, brian d foy C<< <briandfoy@pobox.com> >>. All rights reserved.

This code is available under the Artistic License 2.0.

=cut

1;
