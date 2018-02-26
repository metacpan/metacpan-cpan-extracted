#!/usr/bin/env perl
package App::Module::Lister;
use strict;

use subs qw();
use vars qw($VERSION);

$VERSION = '0.151';

=encoding utf8

=head1 NAME

App::Module::Lister - List the Perl modules in @INC

=head1 SYNOPSIS

	# run the .pm file
	prompt> perl Lister.pm

		---OR---
	# rename this file to something your webserver will treat as a
	# CGI script and upload it. Run it to see the module list
	prompt> cp Lister.pm lister.cgi
		... modify the shebang line if you must
	prompt> ftp www.example.com
		... upload file
	prompt> wget http://www.example.com/cgi-bin/lister.cgi


=head1 DESCRIPTION

This is a program to list all of the Perl modules it finds in C<@INC>
for a no-shell web hosting account. It has these explicit design goals:

=over 4

=item * Is a single file FTP upload such that it's ready to run (no archives)

=item * Runs as a CGI script

=item * Runs on a standard Perl 5.004 system with no non-core modules

=item * Does not use CPAN.pm (which can't easly be configured without the shell)

=back

If you have a shell account, you should just use C<CPAN.pm>'s autobundle
feature.

You do not need to install this module. You just need the C<.pm> file.
The rest of the distribution is there to help me give it to other
people and test it.

You might have to modify the shebang line (the first line in the file)
to point to Perl. Your web hoster probably has instructions on what
that should be. As shipped, this program uses the C<env> trick described
in L<perlrun>. If that doesn't work for you, you'll probably see an
error like:

	 /usr/bin/env: bad interpreter: No such file or directory

That's similar to the error you'll see if you have the wrong path
to C<perl>.

The program searches each entry in C<@INC> individually and outputs
modules as it finds them.

=cut

use File::Find qw(find);
use File::Spec;

run(\*STDOUT) unless caller;

sub run {
	my $fh = shift || \*STDOUT;

	my( $wanted, $reporter, $clear ) = generator();

	print $fh "This is Perl $]\n";

	foreach my $inc ( @INC ) {
		find( { wanted => $wanted }, $inc );

		my $count = 0;
		foreach my $file ( $reporter->() ) {
			my $version = parse_version_safely( $file );

			my $module_name = path_to_module( $inc, $file );

			print $fh "$module_name\t$version\n";

			#last if $count++ > 5;
			}

		$clear->();
		}
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
 # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

BEGIN {
	print "Content-type: text/plain\n\n" if exists $ENV{REQUEST_METHOD};
	}

=head2 Subroutines

=over 4

=item run( FILEHANDLE )

Do the magic, sending the output to C<FILEHANDLE>. By default, it sends
the output to C<STDOUT>.

=item generator

Returns three closures to find, report, and clear a list of modules.
See their use in C<run>.

=cut

sub generator {
	my @files = ();

	sub { push @files,
		File::Spec->canonpath( $File::Find::name )
		if m/\A\w+\.pm\z/ },
	sub { @files },
	sub { @files = () }
	}

=item parse_version_safely( FILENAME )

Find the C<$VERSION> in C<FILENAME> and return its value. The entire
statement in the file must be on a single line with nothing else (just
like for the PAUSE indexer). If the version is undefined, it returns the
string C<'undef'>.

=cut

sub parse_version_safely { # stolen from PAUSE's mldistwatch, but refactored
	my( $file ) = @_;

	local $/ = "\n";
	local $_; # don't mess with the $_ in the map calling this

	return unless open FILE, "<$file";

	my $in_pod = 0;
	my $version;
	while( <FILE> ) {
		chomp;
		$in_pod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $in_pod;
		next if $in_pod || /^\s*#/;

		next unless /([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
		my( $sigil, $var ) = ( $1, $2 );

		$version = eval_version( $_, $sigil, $var );
		last;
		}
	close FILE;

	return 'undef' unless defined $version;

	return $version;
	}

=item eval_version( STATEMENT, SIGIL, VAR )

Used by C<parse_version_safely> to evaluate the C<$VERSION> line
and return a number.

The C<STATEMENT> is the single statement containing the assignment
to C<$VERSION>.

The C<SIGIL> may be either a C<$> (for a scalar) or a C<*> for a
typeglob.

The C<VAR> is the variable identifier.

=cut

sub eval_version {
	my( $line, $sigil, $var ) = @_;

	my $eval = qq{
		package  # hide from PAUSE
			ExtUtils::MakeMaker::_version;

		local $sigil$var;
		\$$var=undef; do {
			$line
			}; \$$var
		};

	my $version = do {
		local $^W = 0;
		no strict;
		eval( $eval );
		};

	return $version;
	}

=item path_to_module( INC_DIR, PATH )

Turn a C<PATH> into a Perl module name, ignoring the C<@INC> directory
specified in C<INC_DIR>.

=cut

sub path_to_module {
	my( $inc, $path ) = @_;

	my $module_path = substr( $path, length $inc );
	$module_path =~ s/\.pm\z//;

	# XXX: this is cheating and doesn't handle everything right
	my @dirs = grep { ! /\W/ } File::Spec->splitdir( $module_path );
	shift @dirs;

	my $module_name = join "::", @dirs;

	return $module_name;
	}

1;

=back

=head1 TO DO

=over 4

=item *

Guessing the module name from the full path name isn't perfect. If I
run into directories that aren't part of the module name in one of the
C<@INC> directories, this program shows the wrong thing.

For example, I have in C<@INC> the directory
C</usr/local/lib/perl5/5.8.8>. Inside that directory, I expect to find
something like C</usr/local/lib/perl5/5.8.8/Foo/Bar.pm>, which
translates in the module C<Foo::Bar>. If I find a directory like
C</usr/local/lib/perl5/5.8.8/lib/Foo/Bar.pm>, where I created the
extra C<lib> by hand, this program guesses the module name is
C<lib::Foo::Bar>. That's not a great tradegy, but I don't have a
simple way around that right now.

=item *

This program finds all modules, even those installed in multiple
locations. It makes no attempt to figure out which ones Perl will
choose first.

=back

=head1 SEE ALSO

The C<CPAN.pm> module

=head1 SOURCE AVAILABILITY

This source is part of a SourceForge project which always has the
latest sources in CVS, as well as all of the previous releases.

	http://sourceforge.net/projects/brian-d-foy/

If, for some reason, I disappear from the world, one of the other
members of the project can shepherd this module appropriately.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

The idea and some of the testing came from Adam Wohld.

Some bits stolen from C<mldistwatch> in the PAUSE code, by Andreas König.

=head1 COPYRIGHT AND LICENSE

Copyright © 2007-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic 2 license.

=cut

1;
