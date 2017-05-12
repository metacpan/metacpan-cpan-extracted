# Arch Perl library, Copyright (C) 2005 Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use 5.005;
use strict;

package Arch::DiffParser;

use Arch::Util qw(load_file);

my $FILE1_PREFIX = '--- ';
my $FILE2_PREFIX = '+++ ';
my $HUNK_PREFIX  = '@@ ';
my $UNMOD_PREFIX = ' ';
my $DEL_PREFIX   = '-';
my $ADD_PREFIX   = '+';
my $NOEOL_PREFIX = '\ No newline at end of file';

use constant FILE1_LINE => 1 << 1;
use constant FILE2_LINE => 1 << 2;
use constant HUNK_LINE  => 1 << 3;
use constant UNMOD_LINE => 1 << 4;
use constant DEL_LINE   => 1 << 5;
use constant ADD_LINE   => 1 << 6;
use constant NOEOL_LINE => 1 << 7;

sub new ($) {
	my $class = shift;

	my $self = {
		data => undef,
	};
	return bless $self, $class;
}

sub parse ($$) {
	my $self = shift;
	my $content = $self->{content} = shift;
	die "Arch::DiffParser::parse: no diff content\n" unless $content;

	my @lines = $content =~ /(.*\n)/g;
	my $hunks = [];
	my $changes = [];

	$lines[0] =~ /^\Q$FILE1_PREFIX\E(.+?)(?:\t(.+))?$/o
		or die "Unexpected line 1: $lines[0]";
	my ($filename1, $mtime1) = ($1, $2);
	$lines[1] =~ /^\Q$FILE2_PREFIX\E(.+?)(?:\t(.+))?$/o
		or die "Unexpected line 2: $lines[1]";
	my ($filename2, $mtime2) = ($1, $2);

	my $last_line = FILE2_LINE;
	my $ln1 = 0;
	my $ln2 = 0;

	for (my $i = 2; $i < @lines; $i++) {
		if ($lines[$i] =~ /^\Q$HUNK_PREFIX\E-(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))?/o) {
			push @$hunks, [ $1, defined $2? $2: 1, $3, defined $4? $4: 1, $i ];
			$last_line = HUNK_LINE;
			$ln1 = $1; $ln2 = $3;
		} elsif ($lines[$i] =~ /^\Q$DEL_PREFIX\E/o) {
			die if $last_line == ADD_LINE;
			push @$changes, [ $ln1, 0, $ln2, 0, $i ]
				unless $last_line == DEL_LINE;
			$changes->[-1][1]++;
			$last_line = DEL_LINE;
			$ln1++;
		} elsif ($lines[$i] =~ /^\Q$ADD_PREFIX\E/o) {
			push @$changes, [ $ln1, 0, $ln2, 0, $i ]
				unless $last_line & (DEL_LINE | ADD_LINE | NOEOL_LINE);
			$changes->[-1][3]++;
			$last_line = ADD_LINE;
			$ln2++;
		} elsif ($lines[$i] =~ /^\Q$UNMOD_PREFIX\E/o) {
			$last_line = UNMOD_LINE;
			$ln1++; $ln2++;
		} elsif ($lines[$i] =~ /^\Q$NOEOL_PREFIX\E/o) {
			$last_line = NOEOL_LINE;
		} else {
			die "Unrecognized diff line #" . ($i + 1) . ":\n$lines[$i]";
		}
	}

	$self->{data} = {
		lines     => \@lines,
		filename1 => $filename1,
		filename2 => $filename2,
		mtime1    => $mtime1,
		mtime2    => $mtime2,
		hunks     => $hunks,
		changes   => $changes,
	};
	return $self;
}

sub parse_file ($$) {
	my $self = shift;
	my $file_name = shift;
	die "Arch::DiffParser::parse_file: no diff file name\n"
		unless $file_name;

	return $self->parse(load_file($file_name));
}

sub diff_data ($) {
	my $self = shift;

	my $data = $self->{data};
	die "Arch::DiffParser::info: no last diff info, perform parse first\n"
		unless $data;
	return $data;
}

sub content ($%) {
	my $self = shift;
	my %args = @_;

	return join("", @{$self->diff_data->{lines}});
}

sub lines ($) {
	my $self = shift;
	return $self->diff_data->{lines};
}

sub filename1 ($) {
	my $self = shift;
	return $self->diff_data->{filename1};
}

sub filename2 ($) {
	my $self = shift;
	return $self->diff_data->{filename2};
}

sub mtime1 ($) {
	my $self = shift;
	return $self->diff_data->{mtime1};
}

sub mtime2 ($) {
	my $self = shift;
	return $self->diff_data->{mtime2};
}

sub hunks ($) {
	my $self = shift;
	return $self->diff_data->{hunks};
}

sub changes ($) {
	my $self = shift;
	return $self->diff_data->{changes};
}

1;

__END__

=head1 NAME

Arch::DiffParser - parse file's diff and perform some manipulations

=head1 SYNOPSIS 

    use Arch::DiffParser;
    my $dp = Arch::DiffParser->new;

    # usable for "annotate" functionality
    my $changes = $dp->parse_file("f.diff")->changes;

    $dp->parse($diff_content);
    $dp->parse("--- f1.c\t2005-02-26\n+++ f2.c\t2005-02-28\n...");
    # prints "f1.c, f2.c"
    printf "%s, %s\n", $dp->filename1, $dp->filename2;

    # enclose lines in <span class="patch_{mod,orig,line,add,del}">
    my $html = $dp->markup_content;

=head1 DESCRIPTION

This class provides a limited functionality to parse a single file diff in
unified format. Multiple diffs may be parsed sequentially. The parsed data
is stored for the last diff, and is replaced on the following parse.

=head1 METHODS

The following class methods are available:

B<new>,
B<parse>,
B<parse_file>,
B<content>,
B<lines>,
B<filename1>,
B<filename2>,
B<mtime1>,
B<mtime2>,
B<hunks>,
B<changes>.

=over 4

=item B<new>

Construct the C<Arch::DiffParser> instanse.

=item B<parse> I<diff_content>

Parse the I<diff_content> and store its parsed data.

=item B<parse_file> I<diff_filename>

Like B<parse>, but read the I<diff_content> from I<diff_filename>.

=item B<diff_data>

Return hashref containing certain parsed data. Die if called before
any B<parse> methods. The keys are:
"lines",
"filename1",
"filename2",
"mtime1",
"mtime2",
"hunks",
"changes".

The value of "hunks" and "changes" is arrayref of arrayrefs with 5 elements:
[ line-number-1, num-lines-1, line-number-2, num-lines-2, "lines"-index ].

A "hunk" describes a set of lines containing some combination of unmodified,
deleted and added lines, a "change" describes an inter-hunk atom that only
contains zero or more deleted lines and zero or more added lines.

=item B<lines>

=item B<filename1>

=item B<filename2>

=item B<mtime1>

=item B<mtime2>

=item B<hunks>

=item B<changes>

These methods are just shortcuts for B<diff_data>->{I<method>}.

=item B<content> [I<%args>]

Return content of the last diff.

I<%args> keys are "fileroot1" and "fileroot2"; if given, these will replace
the subdirs "orig" and "mod" that arch usually uses in the filepaths.

=item B<markup_content> [I<%args>]

Like B<content>, but every non-context line is enclosed into markup
E<lt>span class="patch_I<name>"E<gt>lineE<lt>/spanE<gt>, where I<name>
is one of "orig" (filename1), "mod" (filename2), "line" (hunk linenums),
"add" (added), del (deleted).

Not implemented yet.

=back

=head1 BUGS

No support for newlines in source file names yet.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<Text::Diff::Unified>, L<Algorithm::Diff>.

=cut
