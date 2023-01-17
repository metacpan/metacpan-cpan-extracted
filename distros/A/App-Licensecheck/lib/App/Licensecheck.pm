use Feature::Compat::Class 0.04;

use v5.12;
use utf8;
use warnings;
use autodie;

=head1 NAME

App::Licensecheck - functions for a simple license checker for source files

=head1 VERSION

Version v3.3.7

=head1 SYNOPSIS

    use Path::Tiny;
    use App::Licensecheck;

    my $tempfile = Path::Tiny->tempfile;

    $tempfile->spew(<<EOF);
# Dummy file simply stating some copyright and license.
# Copyright (C) 2020, 2022  Foo Bar.
#
# This file is licensed under version 2 or later of the GPL.
EOF

    my $app = App::Licensecheck->new( top_lines => 0 );  # Parse whole files

    my @output = $app->parse($tempfile);

    my $license    = $output[0];  # => is "GPL-2.0-or-later"
    my $copyrights = $output[1];  # => is "2020, 2022 Foo Bar."

=head1 DESCRIPTION

L<App::Licensecheck> is the core of L<licensecheck> script
to check for licenses of source files.
See the script for casual usage.

=cut

package App::Licensecheck v3.3.7;

class App::Licensecheck;

use Carp         qw(croak);
use Log::Any     ();
use Scalar::Util qw(blessed);
use Path::Tiny();
use Feature::Compat::Try;
use Fcntl qw(:seek);
use Encode 2.93;
use String::Copyright 0.003 {
	format => sub { join ' ', $_->[0] || (), $_->[1] || () }
};
use String::Copyright 0.003 {
	threshold_after => 5,
	format          => sub { join ' ', $_->[0] || (), $_->[1] || () },
	},
	'copyright' => { -as => 'copyright_optimistic' };
use String::License;
use String::License::Naming::SPDX;

use namespace::clean qw(-except new);

# fatalize Unicode::UTF8 and PerlIO::encoding decoding errors
use warnings FATAL => 'utf8';
$PerlIO::encoding::fallback = Encode::FB_CROAK;

no if ( $] >= 5.034 ), warnings => "experimental::try";

field $log;

field $path;

# resolve patterns

field $naming :param = undef;

# parse

field $top_lines :param //= 60;
field $end_bytes :param //= 5000;    # roughly 60 lines of 80 chars
field $encoding :param = undef;
field $fh;
field $content :param = undef;
field $tail_content;
field $offset;
field $license;
field $copyrights;

ADJUST {
	$log = Log::Any->get_logger;

	if ( defined $naming ) {
		croak $log->fatal(
			'parameter "naming" must be a String::License::Naming object')
			unless defined blessed($naming)
			and $naming->isa('String::License::Naming');
	}
	else {
		$naming = String::License::Naming::SPDX->new;
	}

	if ( $encoding and not ref($encoding) eq 'OBJECT' ) {
		$encoding = find_encoding($encoding);
	}
}

method parse
{
	($path) = @_;

	$path = Path::Tiny::path($path);

	try {
		return $self->parse_file;
	}
	catch ($e) {
		if ( $encoding and $e =~ /does not map to Unicode/ ) {
			$log->warnf(
				'failed decoding file %s as %s, will try iso-8859-1',
				$path, $encoding->name
			);
			$log->debugf( 'decoding error: %s', $e );
			try {
				$encoding = find_encoding('iso-8859-1');
				return $self->parse_file;
			}
			catch ($e) {
				if (/does not map to Unicode/) {
					$log->warnf(
						'failed decoding file %s as iso-8859-1, will try raw',
						$path
					);
					$log->debugf( 'decoding error: %s', $e );
					$encoding = undef;
					return $self->parse_file;
				}
				else {
					die $log->fatalf( 'unknown error: %s', $e );
				}
			}
		}
		else {
			die $log->fatalf( 'unknown error: %s', $e );
		}
	}
}

method parse_file
{
	# TODO: stop reuse slots across files, and drop this hack
	$content    = undef;
	$license    = undef;
	$copyrights = undef;

	if ( $top_lines == 0 ) {
		my $licensed = String::License->new(
			string => $self->content_extracleaned,
			naming => $naming,
		);
		$license    = $licensed->as_text;
		$copyrights = copyright( $self->content_cleaned );
	}
	else {
		my $licensed = String::License->new(
			string => $self->content_extracleaned,
			naming => $naming,
		);
		$license    = $licensed->as_text;
		$copyrights = copyright_optimistic( $self->content_cleaned );
		if ( $offset and not $copyrights and $license eq 'UNKNOWN' ) {

			# TODO: stop reuse slots across files, and drop this hack
			$tail_content = undef;

			my $licensed = String::License->new(
				string => $self->content_extracleaned,
				naming => $naming,
			);
			$license    = $licensed->as_text;
			$copyrights = copyright_optimistic( $self->content_cleaned );
		}
		$fh->close;
	}

	return ( $license, $copyrights );
}

method content
{
	if ( $top_lines == 0 ) {
		return $content
			if defined($content);

		if ( not defined($encoding) ) {
			$log->debugf( 'reading whole file %s as raw bytes', $path );
			$content = $path->slurp_raw;
		}
		else {
			my $id = $encoding->name;
			$log->debugf( 'decoding whole file %s as %s', $path, $id );
			$content = $path->slurp( { binmode => ":encoding($id)" } );
		}
		$log->trace("----- content -----\n$content----- end content -----")
			if $log->is_trace;
	}
	elsif ( not defined($license) or not defined($copyrights) ) {

		# TODO: distinguish header from full content
		return $content
			if defined($content);

		$content = '';

		if ( not defined($encoding) ) {
			$log->debugf( 'reading part(s) of file %s as raw bytes', $path );
			$fh = $path->openr_raw;
		}
		else {
			my $id = $encoding->name;
			$log->debugf( 'decoding part(s) of file %s as %s', $path, $id );
			$fh = $path->openr(":encoding($id)");
		}

		while ( my $line = $fh->getline ) {
			last if ( $fh->input_line_number > $top_lines );
			$content .= $line;
		}
		$log->trace("----- header -----\n$content----- end header -----")
			if $log->is_trace;

		if ($end_bytes) {
			my $position = $fh->tell;           # see IO::Seekable
			my $filesize = $path->stat->size;
			if ( $position >= $filesize - $end_bytes ) {    # header overlaps
				if ( $position < $filesize ) {
					$log->debugf(
						'tail offset set to %s (end of header)',
						$position
					);
					$offset = $position;
				}
				elsif ( $position = $filesize ) {
					$log->debug('header end matches file size');
					$offset = 0;
				}
				else {
					$log->error('header end beyond file size');
					$offset = 0;
				}
			}
			elsif ( $position > 0 ) {
				$offset = $filesize - $end_bytes;
				$log->debugf(
					'tail offset set to %s',
					$offset
				);
			}
			elsif ( $position < 0 ) {
				$log->error('header end could not be resolved');
				$offset = 0;
			}
			else {
				$log->error('header end oddly at beginning of file');
				$offset = 0;
			}
		}
	}
	elsif ($offset) {

		# TODO: distinguish tail from full content
		return $content
			if defined($tail_content);

		$tail_content = '';
		$fh->seek( $offset, SEEK_SET );    # see IO::Seekable
		$tail_content .= join( '', $fh->getlines );
		$log->trace("----- tail -----\n$tail_content----- end tail -----")
			if $log->is_trace;

		$content = $tail_content;
	}
	else {
		$log->errorf(
			'tail offset not usable: %s',
			$offset
		);
		return '';
	}

	# TODO: distinguish comment-mangled content from pristine content
	local $_ = $content or return '';

	# Remove generic comments: look for 4 or more lines beginning with
	# regular comment pattern and trim it. Fall back to old algorithm
	# if no such pattern found.
	my @matches = m/^[ \t]*([^a-zA-Z0-9\s]{1,3})[ \t]+\S/mg;
	if ( @matches >= 4 ) {
		my $comment_re = qr/^[ \t]*[\Q$matches[0]\E]{1,3}[ \t]*/m;
		s/$comment_re//g;
	}

	my @wordmatches = m/^[ \t]*(dnl|REM|COMMENT)[ \t]+\S/mg;
	if ( @wordmatches >= 4 ) {
		my $comment_re = qr/^[ \t]*\Q$wordmatches[0]\E[ \t]*/m;
		s/$comment_re//g;
	}

	# Remove other side of "boxed" comments
	s/[ \t]*[*#][ \t]*$//gm;

	# Remove Fortran comments
	s/^[cC]$//gm;
	s/^[cC] //gm;

	# Remove C / C++ comments
	s#(\*/|/\*|(?<!:)//)##g;

	# Strip escaped newline
	s/\s*\\n\s*/ /g;

	$content = $_;

	return $content;
}

my $html_xml_tags_re = qr/<\/?(?:p|br|ref)(?:\s[^>]*)?>/i;

# clean cruft
method content_cleaned
{
	local $_ = $self->content or return '';

	# strip common html and xml tags
	s/$html_xml_tags_re//g;

	# TODO: decode latin1/UTF-8/HTML data instead
	s/\xcb\x97|\xe2\x80[\x90-\x95|\xe2\x81\x83|\xe2\x88\x92|\xef\x89\xa3|\xef\xbc\x8d]|[&](?:ndash|mdash|horbar|minus|[#](?:727|820[8-9]|821[0-3]|8259|8722|65123|65293|x727|z201[0-5]|x2043|x2212|xFE63|xFF0D))[;]/-/gm;
	s/\x58\xa9|\xc2\xa9|\xe2\x92\x9e|\xe2\x92\xb8|\xe2\x93\x92|\xf0\x9f\x84\x92|\xf0\x9f\x84\xab|\xf0\x9f\x85\x92|[&](?:copy|[#](?:169|9374|9400|9426|127250|127275|127314|x0A9|x249E|x24b8|x24D2|x0F112|x0F12B|x0F152))[;]/©/gm;

	# TODO: decode nroff files specifically instead
	s/\\//gm;    # de-cruft nroff files

	return $_;
}

# clean cruft and whitespace
method content_extracleaned
{
	local $_ = $self->content or return '';

	# strip trailing dash, assuming it is soft-wrap
	# (example: disclaimers in GNU autotools file "install-sh")
	s/-\r?\n//g;

	# strip common html and xml tags
	s/$html_xml_tags_re//g;

	tr/\t\r\n/ /;

	# this also removes quotes
	tr% A-Za-z.,:@;0-9\(\)/-%%cd;
	tr/ //s;

	return $_;
}

=encoding UTF-8

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>

=head1 COPYRIGHT AND LICENSE

This program is based on the script "licensecheck" from the KDE SDK,
originally introduced by Stefan Westerfeld C<< <stefan@space.twc.de> >>.

  Copyright © 2007, 2008 Adam D. Barratt

  Copyright © 2012 Francesco Poli

  Copyright © 2016-2022 Jonas Smedegaard

  Copyright © 2017-2022 Purism SPC

This program is free software:
you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License
as published by the Free Software Foundation,
either version 3, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY;
without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Affero General Public License for more details.

You should have received a copy
of the GNU Affero General Public License along with this program.
If not, see <https://www.gnu.org/licenses/>.

=cut

1;
