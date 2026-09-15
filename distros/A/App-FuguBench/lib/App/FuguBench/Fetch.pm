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

package App::FuguBench::Fetch;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Fugu::CLI qw(EXIT_SUCCESS EXIT_ERROR);
use Fugu::Curl;

# App::FuguBench::Fetch - the fetch verb.
#
# The verb downloads one URL to one file through Fugu::Curl, which
# runs curl, wget, or ftp (DEPS-FETCH-1). It takes the argument order
# of the ftp helper of Tooling: the file first, and the URL after it
# (DEPS-FETCH-2). A make recipe that called the helper calls the verb,
# and the deps verb names it in the trace of a download.
#
# The verb reads no checkout (CLI-CHECKOUT-5), so it runs in a tree
# with no .toolingrc.
#
# The URL reaches the downloader as one argument, with no '--'
# separator ahead of it, so it takes a shape check first
# (DEPS-FETCH-4). check_url holds that check, and the deps verb calls
# it over each manifest URL.
#
# Fugu::Curl writes the bytes beside the destination and renames the
# file on success, so a failed download leaves no file. The verb
# reports the reason of a failure and returns 1.

# App::FuguBench::Fetch->command($verb):
#	The entry of the Fugu::CLI table. The module holds one verb,
#	so it ignores the name.
sub command ( $, $ )
{
	return {
		summary => 'download one URL to one file',
		usage   => '<file> <url>',
		run     => sub ( $app, @argv ) { return _run( $app, @argv ) },
	};
}

# App::FuguBench::Fetch::check_url($app, $url, $where):
#	Hold one URL to the shape that the downloader allows
#	(DEPS-FETCH-4). Fugu::Curl places the URL last and builds no
#	'--' separator, so a URL that starts with a dash reaches the
#	downloader as an option. A scheme starts with a letter, so the
#	scheme rule covers the dash as well.
#
#	$where names the source of the URL in the message. The
#	function returns 1 for a URL that passes, and 0 for one that
#	does not, which it reports. The deps verb runs this check over
#	each manifest URL, so one check serves both (CLI-PROGRAM-6).
sub check_url ( $app, $url, $where )
{
	return 1 if $url =~ m{\A[a-z][a-z0-9+.-]*://}i;

	$app->cli->log->error(
		'%s: the URL must start with a scheme, because the'
		    . ' downloader takes no -- separator: %s',
		$where, $url
	);

	return 0;
}

# _run($app, @argv):
#	The body of the verb. The arguments are the destination file
#	and the URL, in that order, and every other command line is a
#	usage error. A URL of the wrong shape is one as well, so the
#	verb names the fault and then prints the usage (CLI-PROGRAM-3).
sub _run ( $app, @argv )
{
	my $cli = $app->cli;

	return $cli->command_usage_error('fetch') if @argv != 2;
	my ( $file, $url ) = @argv;

	return $cli->command_usage_error('fetch')
	    unless check_url( $app, $url, 'the command line' );

	# Fugu::Curl reports an absent downloader as a failed fetch,
	# so one branch covers it and every other failure.
	my $curl = Fugu::Curl->new;
	unless ( $curl->fetch( $url, $file ) ) {
		$cli->log->error( '%s', $curl->error );
		return EXIT_ERROR;
	}

	return EXIT_SUCCESS;
}

1;
