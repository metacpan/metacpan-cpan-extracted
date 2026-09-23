# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package App::FuguSeed::Words;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use App::FuguSeed::Check    ();
use App::FuguSeed::ListFile ();
use App::FuguSeed::Sheet    ();
use Fugu::CLI               ();
use Fugu::File              ();

# App::FuguSeed::Words - the flow of fuguseed-words (WORDS-PROGRAM).
#
# The module dispatches the verbs build and check through Fugu::CLI
# (D-06). It reads the two share files of the sheet and the sheet
# under check, and it prints the result of a verb on standard output.
# Every diagnostic goes to standard error through the logger of the
# command line interface (WORDS-PROGRAM-4).
#
# The program sees no seed word, so it can run on any computer (D-01).
# No module that it loads maps 12 words to anything, and none of them
# loads the mnemonic module of fuguseed-qr (SEC-TRUST-1).
# t/fuguseed/words-program.t proves the rule at the load, and it scans
# each source of the program for the name of that module
# (TEST-PACK-3). The name is therefore absent from this file.

# NAME and DIST:
#	The name of the program in a diagnostic, and the name of the
#	distribution that holds the share files.
use constant NAME => 'fuguseed-words';
use constant DIST => 'App-FuguSeed';

# SHARE:
#	The directory of the share files, under the root of the
#	checkout and under the share tree of an install
#	(LIST-SHARE-2).
use constant SHARE => 'share/fuguseed';

# SUCCESS and FAILURE:
#	Two of the three exit codes of Fugu LIB-CLI. The third one is
#	the usage error, and Fugu::CLI returns it
#	(WORDS-PROGRAM-2).
use constant SUCCESS => 0;
use constant FAILURE => 1;

# $class->run(@argument):
#	Dispatch the verb and give the exit code of the program.
sub run ( $class, @argument )
{
	my $cli = $class->_cli;

	# Fugu::CLI prints the help for an empty argument list and it
	# gives 0. A command line without a verb is a usage error
	# here (WORDS-PROGRAM-3).
	return $cli->usage_error unless @argument;

	return $cli->run(@argument);
}

# $class->share($name):
#	The path of the share file $name, in a checkout and in an
#	installed distribution, or undef when no tree holds it
#	(LIST-SHARE-2).
sub share ( $, $name )
{
	return Fugu::File->share_path(
		SHARE . "/$name",
		from => __FILE__,
		dist => DIST
	);
}

# $class->_cli:
#	The command line interface: the two verbs, their arguments,
#	and their options (WORDS-PROGRAM-2).
#
#	The epilogue names the path of the shipped word list, because
#	both verbs take a list file and a person needs that path.
sub _cli ($class)
{
	my $list = $class->share('english.txt');

	return Fugu::CLI->new(
		name     => NAME,
		usage    => '<command> [arguments]',
		epilogue => defined $list
		? "The shipped word list is $list\n"
		: undef,
		commands => {
			build => {
				usage   => '<list> [--date YYYY-MM-DD]',
				summary => 'write the word sheet to '
				    . 'standard output',
				options => { 'date=s' => 1 },
				run     => sub ( $cli, @argument ) {
					return $class->_build( $cli,
						@argument );
				},
			},
			check => {
				usage   => '<sheet> <list>',
				summary => 'prove that a word sheet is '
				    . 'correct for a list',
				run => sub ( $cli, @argument ) {
					return $class->_check( $cli,
						@argument );
				},
			},
		} );
}

# $class->_build($cli, @argument):
#	The build verb: write the sheet of one list to standard
#	output (WORDS-BUILD-1).
sub _build ( $class, $cli, @argument )
{
	return $cli->command_usage_error('build') unless @argument == 1;

	my $date = $cli->option('date') // _today();
	unless ( $date =~ /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/ ) {
		$cli->log->error( '%s: the date must read YYYY-MM-DD', NAME );
		return $cli->command_usage_error('build');
	}

	my $list = App::FuguSeed::ListFile->read( $argument[0] );
	return FAILURE unless defined $list;

	my $template = $class->_share_text( $cli, 'sheet.html' );
	my $style    = $class->_share_text( $cli, 'sheet.css' );
	return FAILURE unless defined $template && defined $style;

	# A class name after print is a bareword filehandle on perl
	# v5.34, so the sheet reaches a variable first.
	my $sheet = App::FuguSeed::Sheet->build(
		list     => $list,
		template => $template,
		style    => $style,
		date     => $date
	);
	print $sheet;

	return SUCCESS;
}

# $class->_check($cli, @argument):
#	The check verb: prove one sheet against one list. The verb is
#	silent on success, and it prints one line for each defect on
#	standard error (WORDS-CHECK-1, WORDS-CHECK-2).
sub _check ( $class, $cli, @argument )
{
	return $cli->command_usage_error('check') unless @argument == 2;

	my ( $path, $list_path ) = @argument;
	my $sheet = Fugu::File->read($path);
	unless ( defined $sheet ) {
		$cli->log->error( '%s: cannot read the sheet %s', NAME, $path );
		return FAILURE;
	}

	my $list = App::FuguSeed::ListFile->read($list_path);
	return FAILURE unless defined $list;

	my $style = $class->_share_text( $cli, 'sheet.css' );
	return FAILURE unless defined $style;

	my @defects = App::FuguSeed::Check->defects( $sheet, $list, $style );
	return SUCCESS unless @defects;

	# A defect names a byte offset or a position, and it can hold
	# a percent sign, so the message is an argument of the format.
	$cli->log->error( '%s', $_ ) for @defects;

	return FAILURE;
}

# $class->_share_text($cli, $name):
#	The text of the share file $name, or undef with one
#	diagnostic (LIST-SHARE-2).
sub _share_text ( $class, $cli, $name )
{
	my $path = $class->share($name);
	unless ( defined $path ) {
		$cli->log->error( '%s: cannot find the share file %s',
			NAME, $name );
		return;
	}

	my $text = Fugu::File->read($path);
	$cli->log->error( '%s: cannot read the share file %s', NAME, $path )
	    unless defined $text;

	return $text;
}

# _today():
#	The date of this moment, in UTC, as YYYY-MM-DD.
sub _today ()
{
	my @now = gmtime time;

	return sprintf '%04d-%02d-%02d', $now[5] + 1900, $now[4] + 1, $now[3];
}

1;
