# Arch Perl library, Copyright (C) 2004-2005 Mikhael Goikhman
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

package Arch::Util;

# import 2 functions for backward compatibility only; remove after summer 2005
use Arch::Backend qw(arch_backend is_baz);

use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	arch_backend is_baz
	run_pipe_from run_cmd run_tla
	is_tla_functional
	load_file save_file
	copy_dir remove_dir setup_config_dir
	standardize_date date2daysago date2age
	parse_creator_email adjacent_revision _parse_revision_descs
);

sub run_pipe_from (@) {
	my $arg0 = shift || die;
	my @args = (split(' ', $arg0), @_);

	@args = ("'" . join("' '", map { s/'/'"'"'/g; $_ } @args) . "'")  # "
		if $] < 5.008;
	print STDERR "executing: '" . join("' '", @args) . "'\n"
		if $ENV{DEBUG} && ("$ENV{DEBUG}" & "\1") ne "\0";

	# perl-5.005 does not pass compilation without "eval"...
	my $pipe_success = $] >= 5.006?
		eval qq{ no warnings; open(PIPE, '-|', \@args) }: open(PIPE, "$args[0]|");
	die "Can't start (@args): $!\n" unless $pipe_success;
	return \*PIPE;
}

# in scalar context return the output string, in list context - list of lines
sub run_cmd (@) {
	my $arg0 = shift || die;
	my @args = (split(' ', $arg0), @_);

	my $pipe = run_pipe_from(@args);
	local $/ = undef unless wantarray;
	my @lines = <$pipe>;
	close($pipe);
	chomp @lines if wantarray;
	return wantarray? @lines: $lines[0] || "";
}

sub run_tla (@) {
	my $arg1 = shift || die;
	unshift @_, $Arch::Backend::EXE, split(' ', $arg1);
	goto \&run_cmd;
}

sub is_tla_functional () {
	eval { run_tla("help --help") } ? 1 : 0;
}

sub load_file ($;$) {
	my $file_name = shift;
	my $content_ref = shift;
	print STDERR "load_file: $file_name\n"
		if $ENV{DEBUG} && ("$ENV{DEBUG}" & "\4") ne "\0";
	open(FILE, "<$file_name") or die "Can't load $file_name: $!\n";
	local $/ = undef;
	my $content = <FILE>;
	close(FILE) or die "Can't close $file_name in load: $!\n";
	if ($content_ref) {
		$$content_ref = $content if ref($content_ref) eq 'SCALAR';
		if (ref($content_ref) eq 'ARRAY') {
			$content =~ s/\r?\n$//;
			@$content_ref = map { chomp; $_ } split(/\r?\n/, $content, -1);
		}
	}
	return defined wantarray? $content: undef;
}

sub save_file ($$) {
	my $file_name = shift;
	print STDERR "save_file: $file_name\n"
		if $ENV{DEBUG} && ("$ENV{DEBUG}" & "\4") ne "\0";
	open(FILE, ">$file_name") or die "Can't save $file_name: $!\n";
	print FILE
		ref($_[0]) eq 'SCALAR'? ${$_[0]}:
		ref($_[0]) eq 'ARRAY'? map { m|$/$|? $_: "$_$/" } @{$_[0]}:
		$_[0];
	close(FILE) or die "Can't close $file_name in save: $!\n";
	return 1;
}

sub copy_dir ($$) {
	my $dir1 = shift;
	my $dir2 = shift;
	my $out = run_cmd("/bin/cp -PRp", $dir1, $dir2);
	warn $out if $out;
}

sub remove_dir (@) {
	my @dirs = grep { $_ } @_;
	return unless @dirs;
	my $out = run_cmd("/bin/rm -rf", @dirs);
	warn $out if $out;
}

sub setup_config_dir (;$@) {
	my $dir = shift;
	$dir ||= $ENV{ARCH_MAGIC_DIR};
	$dir ||= ($ENV{HOME} || "/tmp") . "/.arch-magic";

	foreach my $subdir ("", @_) {
		next unless defined $subdir;
		$dir .= "/$subdir" unless $subdir eq "";
		stat($dir);
		die "$dir exists, but it is not a writable directory\n"
			if -e _ && !(-d _ && -w _);
		unless (-e _) {
			print STDERR "making dir: $dir\n"
				if $ENV{DEBUG} && ("$ENV{DEBUG}" & "\2") ne "\0";
			mkdir($dir, 0777) or die "Can't mkdir $dir: $!\n";
		}
	}
	return $dir;
}

my %months = (
	Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6,
	Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12,
);
sub standardize_date ($) {
	my $date = shift;
	if ($date =~ /\w+ (\w+) +(\d+) +(\d+):(\d+):(\d+) (\w+) (\d+)/) {
		$date = sprintf("%04d-%02d-%02d %02d:%02d:%02d %s",
			$7, $months{$1} || 88, $2, $3, $4, $5, $6);
	}
	return $date;
}

# return (creator_name, creator_email, creator_username)
sub parse_creator_email ($) {
	my $creator = shift;
	my $email = 'no@email.defined';
	my $username = "_none_";
	if ($creator =~ /^(.*?)\s*<((?:(.+?)@)?.*)>$/) {
		($creator, $email, $username) = ($1, $2, $3);
	}
	return ($creator, $email, $username);
}

sub adjacent_revision ($$) {
	my $full_revision = shift;
	my $offset = shift || die "adjacent_revision: no offset given\n";
	die "adjacent_revision: no working revision\n" unless $full_revision;

	$full_revision =~ /^(.*--.*?)(\w+)-(\d+)$/
		or die "Invalid revision ($full_revision)\n";
	my $prefix = $1;
	my $new_num = $3 + $offset;
	return undef if $new_num < 0;
	my $new_word = $2 =~ /^patch|base$/?
		$new_num? 'patch': 'base':
		$new_num? 'versionfix': 'version';
	return "$prefix$new_word-$new_num";
}

sub date2daysago ($) {
	my $date_str = shift;

	return -10000 unless $date_str =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) ([^\s]+)/;

	# timezone is not taken in account...
	require Time::Local;
	my $time = Time::Local::timegm($6, $5, $4, $3, $2 - 1, $1 - 1900);
	my $daysago = int((time - $time) / 60 / 60 / 24);

	return $daysago unless wantarray;
	return ($daysago, $time, $7);
}

sub date2age ($) {
	my $daysago = date2daysago($_[0]);
	return "bad-date" if $daysago <= -10000;

	my ($sign, $days) = $daysago =~ /^(-?)(.*)$/;
	my $str =
		$days ==   1? "1 day":
		$days <=  33? "$days days":
		$days <=  59? int($days / 7 + 0.5) . " weeks":
		$days <= 550? int($days / 30.42 + 0.5) . " months":
		int($days / 365.25 + 0.5) . " years";
	return "$sign$str";
}

# gets tla lines with undef meaning the delimiter for revisions;
# intended for parsing of "abrowse --desc" and "logs --cDs"
sub _parse_revision_descs ($$) {
	my $num_spaces = shift || die;
	my $revision_lines = shift || die;

	my $spaces = " " x $num_spaces;
	$spaces || die "Invalid number of spaces ($num_spaces)";

	my @revision_descs = ();
	while (@$revision_lines) {
		my ($line1, $line2) = splice @$revision_lines, 0, 2;
		my @summary_lines = ();
		push @summary_lines, shift @$revision_lines while defined $revision_lines->[0];
		shift @$revision_lines;  # throw away undef delimiter
		my $summary = join("\n", @summary_lines);
		$line2 =~ s/^$spaces//; $summary =~ s/^$spaces//mg;

		my ($name, $kind) = $line1 =~ /^(\S+)(?:\s+\((.*?)\))?/
			or die "Unexpected output of tla, subline 1:\n\t$line1\n";
		$kind = !$kind? "unknown": $kind =~ /tag/? "tag": $kind =~ /import/? "import": "cset";
		my ($date, $creator) = $line2 =~ /^(.+?)\s{6}(.*)/
			or die "Unexpected output of tla, subline 2:\n\t$line2\n";
		$date = standardize_date($date);
		my $age = date2age($date);

		my @version_part;
		push @version_part, 'version', $1 if $name =~ s/^(.*)--(.*)/$2/;

		my ($creator1, $email, $username) = parse_creator_email($creator);
		push @revision_descs, {
			name     => $name,
			summary  => $summary,
			creator  => $creator1,
			email    => $email,
			username => $username,
			date     => $date,
			age      => $age,
			kind     => $kind,
			@version_part,
		};
	}
	return \@revision_descs;
}

1;

__END__

=head1 NAME

Arch::Util - Arch utility functions

=head1 SYNOPSIS

    use Arch::Util qw(run_tla load_file save_file setup_config_dir);

    my $abrowse_output = run_tla('abrowse --summary --date --creator');
    my ($full_version) = run_tla('tree-version');
    my @full_revisions = run_tla('logs', '-r', '-f');

    my $cfg_dir = setup_config_dir(undef, "archipelago");
    my $content = load_file("$cfg_dir/versions.cfg");
    $content =~ s/^last_version = .*/last_version = $full_version/m;
    save_file("$cfg_dir/versions.cfg", $content);

=head1 DESCRIPTION

A set of helper functions suitable for GNU Arch related projects in Perl.

Higher (object oriented) levels of Arch/Perl library make use of these
helper functions.

=head1 FUNCTIONS

The following functions are available:

B<run_tla>,
B<run_cmd>,
B<run_pipe_from>,
B<load_file>,
B<save_file>,
B<copy_dir>,
B<remove_dir>,
B<setup_config_dir>,
B<standardize_date>,
B<date2daysago>,
B<date2age>,
B<parse_creator_email>,
B<adjacent_revision>.

The system functions die on errors.

=over 4

=item B<is_tla_functional>

Verify whether the system has a working arch backend installed (and
possibly configured by environment variables, like TLA or ARCH_BACKEND),
needed for this perl library to function.

=item B<run_tla> I<subcommand_with_args>

=item B<run_tla> I<subcommand> arg ...

Run the given I<tla> subcommand with optional arguments. Return the tla
output in the scalar context, and a list of B<chomp>-ed lines in the list
context.

=item B<run_cmd> I<shell_command_with_args>

=item B<run_cmd> I<shell_command> I<arg> ...

Run the given shell command (like I<wc> or I<awk>) with optional arguments.
Return the command output in the scalar context, and a list of B<chomp>-ed
lines in the list context.

B<run_tla> is implemented using B<run_cmd>.

=item B<run_pipe_from> I<shell_command_with_args>

=item B<run_pipe_from> I<shell_command> I<arg> ...

Run the given shell command (like I<ls> or I<tar>) with optional arguments
in the separate process. Return the pipe (file handle) that may be used to
read the command output from.

B<run_cmd> is implemented using B<run_pipe_from>.

=item B<load_file> I<file_name>

=item B<load_file> I<file_name> I<scalar_ref>

=item B<load_file> I<file_name> I<array_ref>

Load the given I<file_name>. Return the file content if the returning value
is expected. As a side effect, may modify the I<scalar_ref> or I<array_ref>
if given, in the last case all file lines are split and B<chomp>-ed.

=item B<save_file> I<file_name> I<content>

Save the given I<content> in the given I<file_name>. The I<content> may be
either scalar, scalar ref, or array ref (see B<load_file>).

=item B<copy_dir> I<dir1> I<dir2>

Copy I<dir1> to I<dir2> recursivelly, preserving as many attributes as
possible.

=item B<remove_dir> I<dir> ..

Remove I<dir> (or dirs) recusivelly. Please be careful.

=item B<setup_config_dir>

=item B<setup_config_dir> I<dir>

=item B<setup_config_dir> I<dir> I<subdir> ...

Create (if needed) the configuration I<dir> that defaults to either
$ARCH_MAGIC_DIR or I<~/.arch-magic> or I</tmp/.arch-magic> if $HOME is
unset.

If one or more consecutive I<subdir> given, repeat the same procedure
for the sub-directory (including creating and diagnostics if needed).

Return a name of the existing directory (including sub-directories if any).

=item B<standardize_date> I<default_unix_date_string>

Try to convert the given date string to "yyyy-mm-dd HH:MM:SS TMZ".
If failed, the original string is returned.

=item B<date2daysago> I<date_string>

Convert a date string to time difference to now in full days.

In list content, return (num_days_ago, unix_time, timezone_str).

=item B<date2age> I<date_string>

Like B<date2daysago>, but return a human readable string, like "5 days"
or "-6 weeks" or "7 months" or "3 years".

=item B<parse_creator_email> I<my_id>

Try to parse the I<arch> B<my-id> of the patch creator. Return a list of
his/her name and email.

=item B<adjacent_revision> I<full_revision> I<offset>

Given the I<full_revision> and positive or negative offset, try to guess the
full name of the adjacent revision.

=back

=head1 BUGS

Awaiting for your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<tla>, L<Arch>.

=cut
