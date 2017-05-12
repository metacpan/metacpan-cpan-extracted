#
# $Id: Strip.pm,v 0.1 2001/03/31 10:04:36 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Strip.pm,v $
# Revision 0.1  2001/03/31 10:04:36  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package Carp::Datum::Strip;

require Exporter;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT_OK = qw(datum_strip);

use Log::Agent;

#
# datum_strip
#
# Strip all Datum assertions in file and flow control tracing.
# Also turn Datum off by stripping the "use" line.
#
# Let all DTRACE statements pass through.
#
# Arguments:
#   file	old file path, to strip
#   fnew	new file, stripped
#	ext		when defined, renames fnew as file upon success and file with ext
#
# Returns 1 if OK, undef otherwise.
#
sub datum_strip {
	my ($file, $fnew, $ext) = @_;

	local *OLD;
	local *NEW;

	if ($file eq '-') {
		logdie "can't dup stdin: $!" unless open(OLD, '<&STDIN');
	} else {
		unless (open(OLD, $file)) {
			logerr "can't open $file: $!";
			return;
		}
	}

	if ($fnew eq '-') {
		logdie "can't dup stdout: $!" unless open(NEW, '>&STDOUT');
	} else {
		unless (open(NEW, ">$fnew")) {
			logerr "can't create $fnew: $!";
			close OLD;
			return;
		}
	}

	eval { strip(\*OLD, \*NEW) };
	if (chop $@) {
		logerr "can't write to $fnew: $@";
		close NEW;
		close OLD;
		return;
	}

	if ($file ne '-' && $fnew ne '-') { 
		my $mode = (stat(OLD))[2] & 07777;
		chmod $mode, $fnew or logwarn "can't propagate mode %04o on $fnew: $!";
	}

	unless (close NEW) {
		logerr "can't flush $fnew: $!";
		close OLD;
		return;
	}

	close OLD;
	return 1 if $file eq '-' || $fnew eq '-';
	return 1 unless defined $ext;

	unless (rename($file, "$file$ext")) {
		logwarn "can't rename $file as $file$ext: $!";
		return;
	}

	unless (rename($fnew, $file)) {
		logwarn "can't rename $fnew as $file: $!";
		return;
	}

	return 1;		# OK
}

#
# strip
#
# Lexical stripping of assertions, and return tracing routines.
# We don't have the pretention of handling all the possible cases.
# That would be foolish, because we'd have to write a Perl parser!
#
# Therefore, unless the conventions documented in the Carp::Datum manpage
# are strictly followed, stripping will be incorret.
#
# Note: we don't remove DTRACE, they will be remapped to Log::Agent calls
# dynamically.  We can't do that statically because the syntax is not
# compatible.
#
sub strip {
	my ($old, $new) = @_;

	local $_;
	my $last_was_nl = 0;

	while (<$old>) {
		next if s/^(\s*use Carp::Datum).*;/$1;/;	# Turns it off
		next if s/^(\s*)(?:DVOID|DVAL|DARY)\b/$1/;
		next if s/^(\s*return)\s+DVOID\b/$1/;
		next if s/^(\s*return\s+)(?:(?:DVAL|DARY)\s*)/$1/;

		if (s/^(\s*)(?:DFEATURE|DREQUIRE|DENSURE|DASSERT)\b//) {
			my $indent = $1;
			$_ = skip_to_sc($old, $_);
			s/^\s+//;
			$_ = /^\s*$/ ? '' : ($indent . $_);		# Keep leading indent
			next;
		}
	} continue {
		my $is_nl = /^\s*$/;
		unless ($last_was_nl && $is_nl) {
			print $new $_ or CORE::die "$!\n";
		}
		$last_was_nl = $is_nl;
	}
}

#
# skip_to_sc
#
# Strip to next ';' outside any string.
# We don't handle regexps, here docs, nor syntactic sugar for quotes.
#
# Returns anything after the final ';'.
#
sub skip_to_sc {
	my ($fd, $str) = @_;
	my $str_end = '';
	for (;;) {
		if ($str =~ /^\s*$/) {
			$str = <$fd>;
			return '' unless defined $str;	# EOF
		}

		if ($str_end) {							# Within string
			$str =~ s/\\(?:\\\\)*['"`]//g;		# Remove escaped quotes
			$str_end = '' if $str =~ s/.*$str_end//;
			if ($str_end) {						# Still not reached the end
				$str = '';
				next;
			}
		}

		$str =~ s/^[^'"`;]*//;
		return substr($str, 1) if substr($str, 0, 1) eq ";";
		next if $str =~ /^\s*$/;
		if ($str =~ s/^(['"`])//) {				# Found a string
			$str_end = $1;
			next;
		}
	}
}

1;

=head1 NAME

Carp::Datum::Strip - strips most Carp::Datum calls lexically

=head1 SYNOPSIS

 use Carp::Datum::Strip qw(datum_strip);

 datum_strip("-", "-");
 datum_strip($file, "$file.new", ".bak");

=head1 DESCRIPTION

This module exports a single routine, datum_strip(), whose purpose is
to remove calls to C<Carp::Datum> routines lexically.

Because stripping is done lexically, there are some restrictions about
what is actually supported.  Unless the conventions documented in
L<Carp::Datum> are followed, stripping will be incorrect.

The general guidelines are:

=over 4

=item *

Do not use here documents or generalized quotes (qq) within 
assertion expression or tags.  Write assertions using '' or "",
as appropriate.

=item *

Assertions can be safely put on several lines, but must end with a semi-colon,
outside any string.

=back

There are two calls that will never be stripped: VERIFY() and DTRACE().
The VERIFY() is meant to be preserved (or C<DREQUIRE> would have been used).
C<DTRACE>, when called, will be remapped dynamically to some
C<Log::Agent> routine, depending on the trace level.  See L<Carp::Datum>
for details.

=head1 INTERFACE

The interface of the datum_strip() routine is:

=over 4

=item C<datum_strip> I<old_file>, I<new_file>, [I<ext>]

The I<old_file> specifies the old file path, the one to be stripped.
The stripped version will be written to I<new_file>.

If the optional third argument I<ext> is given (e.g. ".bak"),
then I<old_file> will be renamed with the supplied extension, and I<new_file>
will be renamed I<old_file>.  Renaming only occurs if stripping was successful
(i.e. the new file was correctly written to disk).

The lowest nine "rwx" mode bits from I<old_file> are preserved when
creating I<new_file>.

Both I<old_file> and I<new_file> can be set to "-", in which case STDIN
and STDOUT are used, respectively, and no renaming can occur, nor any
mode bit propagation.

Returns true on success, C<undef> on error.

=back

=head1 AUTHORS

Christophe Dehaudt and Raphael Manfredi are the original authors.

Send bug reports, hints, tips, suggestions to Dave Hoover at <squirrel@cpan.org>.

=head1 SEE ALSO

Carp::Datum(3).

=cut

