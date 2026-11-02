
=encoding utf8

=head1 NAME

update - Greple module to update file content

=head1 SYNOPSIS

greple -Mupdate

Options:

  --update       replace file content
  --with-backup  make backup files

  --diff         produce diff output
  -U#, --diff-context=#  unified diff context length
  --diff-command=#       diff command

  --discard      simply discard the output

=head1 VERSION

Version 1.05

=head1 DESCRIPTION

This B<greple> module replaces the content of the target file with the
output of the command.  For example, the next command changes all words
in the file to uppercase.

    greple -Mupdate '\w+' --cs uc --update file

This is a very simple example, but you can implement arbitrarily
complex functions in conjunction with other B<greple> options.

You can check how the file will be edited with the B<--diff> option.

    greple -Mupdate '\w+' --cs uc --diff file

Command B<sdif> or B<cdif> would be useful to see the difference
visually.

    greple -Mupdate '\w+' --cs uc --diff file | cdif

To pass only the matched parts through an external command and write
the result back, use it with L<App::Greple::tee>.  Give B<-Mupdate>
before B<-Mtee>, because the arguments of B<-Mtee> up to C<--> are the
command, and B<--update> after the C<-->:

    greple -Mupdate -Mtee tr a-z A-Z -- --update '\w+' file

Calling a function, as in C<-Mtee '&ansicolumn'>, requires
L<Command::Run> 1.05 or later.

This module has been spun off from the L<App::Greple::subst> module.
Consult it for more practical use cases.

=head1 OPTIONS

There are two kinds of options for this module, such as C<--diff> and
C<--update::diff>.  This is to avoid option name conflicts when used
in combination with other modules.  If you are using this module from
another module and want to use the C<--diff> option in it, call as
C<--update::diff>.

=over 7

=item B<--update>

=item B<--update::update>

Update the target file with the command output.  The entire file
content is produced and any color effects are canceled.  Without this
option, B<greple> behaves as usual, that is, only matched lines are
printed.

The file is not touched as long as its content does not change.

The file is also not updated if the output is empty.  This is to
prevent the contents of the file from being erased if none of the
match strings are included.  If you want to intentionally empty a
file, you need to think of another way.

=item B<--with-backup>[=I<suffix>]

Back up the original file with the C<.bak> suffix.  If the optional
parameter is given, it is used as the suffix.  If the backup file
exists, C<.bak_1>, C<.bak_2> ... are used.

Give the suffix with C<=>.  An argument that follows the option is
taken as the suffix, so in C<--with-backup file> the name of the file
is lost.  Put another option after it or use
C<-Mupdate::config(with_backup)> in that case.

=item B<--discard>

=item B<--update::discard>

Simply discard the command output without updating the file.  This option
can be used when the output of the command is not needed and only side
effects are expected.

=begin comment

=item B<--create>

=item B<--update::create>

Create new file and write the result.  Suffix ".new" is appended to
the original filename.

=end comment

=item B<--diff>

=item B<--update::diff>

Produce a diff of the original and the converted text.

=item B<-U>I<n>, B<--diff-context>=I<n>

Context length of the unified diff produced by B<--diff>.

=item B<--diff-command>=I<command>

Diff command used by B<--diff>.  Default is C<diff -u>.  If the context
length is given, C<diff -U>I<n> is used instead.

=back

=head1 CONFIGURATION

Module parameters can be set with L<Getopt::EX::Config> using the
following syntax:

    greple -Mupdate::config(with_backup) ...
    greple -Mupdate::config(with_backup=.orig) ...
    greple -Mupdate::config(diff_context=3) ...

Options given on the command line override them.  Available
parameters are:

    with_backup    back up the file, as --with-backup
    diff_context   context length of diff, as --diff-context
    diff_command   diff command, as --diff-command (default: diff -u)
    update_suffix  backup suffix (default: none)
    remember       compare with the content that was read, not with
                   the file, in --diff (default: 1)

=head1 LIMITATIONS

Files are always written in UTF-8.  A file read with B<--icode> in
another encoding, such as Shift-JIS, is converted to UTF-8, and
B<--ocode> has no effect on the file.

Binary data read with C<--icode=binary> is not preserved: bytes
outside of ASCII are changed when the file is written.  A file that is
not valid UTF-8 is skipped unless B<--icode> is given.

Greple's B<--of> option does not take effect with B<--update>: the
file is written without the filter.

Standard input has no file to go back to: with B<--update>, the result
is written to a file named C<->.

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::update

=head2 GITHUB

    $ cpanm https://github.com/kaz-utashiro/greple-update.git

=head1 SEE ALSO

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<App::Greple::update>, L<https://github.com/kaz-utashiro/greple-update>

L<App::Greple::subst>, L<https://github.com/kaz-utashiro/greple-subst>

L<App::sdif>, L<App::cdif>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::update;
use v5.24;
use warnings;
use experimental 'refaliasing';

our $VERSION = '1.05';

use utf8;
use open IO => ':utf8';

use Exporter 'import';
our @EXPORT      = qw(
    &update_initialize
    &update_begin
    &update_diff
    &update_divert
    &update_file
    );
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use Carp;
use Encode;
use Data::Dumper;
use App::Greple::Common;
use Text::ParseWords qw(shellwords);
use Getopt::EX::Config;

our $debug = 0;

my $config = Getopt::EX::Config->new(
    remember      => 1,
    diff_command  => "diff -u",
    update_suffix => '',
    with_backup   => undef,
    diff_context  => '',
);

# The builtin options in __DATA__ and the config set the same values.
\our $remember_data      = \$config->{remember};
\our $opt_update_diffcmd = \$config->{diff_command};
\our $opt_suffix         = \$config->{update_suffix};
\our $opt_backup         = \$config->{with_backup};
\our $opt_U              = \$config->{diff_context};

my $current_file;
my $contents;
my @update_diffcmd;

sub debug {
    $debug = 1;
}

sub update_initialize {
    @update_diffcmd = shellwords $opt_update_diffcmd;
    if ($opt_U ne '') {
	@update_diffcmd = ('diff', "-U$opt_U");
    }
    if (defined $opt_backup) {
	# no value: "" from --with-backup, 1 from config(with_backup)
	$opt_suffix = $opt_backup =~ /^1?$/ ? '.bak' : $opt_backup;
    }
}

sub update_begin {
    my %arg = @_;
    $current_file = delete $arg{&FILELABEL} or die;
    $contents = $_ if $remember_data;
}

#
# define &divert_stdout and &recover_stdout
#
{
    my $divert;
    my $bufref;

    sub divert_stdout {
	$bufref = shift;
	return if $divert;
	require IO::Divert;
	$divert = IO::Divert->new(autoprint => 0);
    }

    sub recover_stdout {
	$divert or return;
	$$bufref = $divert->cancel->content;
	undef $divert;
	1;
    }
}

use List::Util qw(first);

sub update_diff {
    my $orig = $current_file;
    my $fh;
    state $fdpath = do {
	my $fd = DATA->fileno;
	first { -r "$_/$fd" } qw( /dev/fd /proc/self/fd );
    };

    if ($fdpath and $remember_data) {
	use IO::File;
	use Fcntl;
	$fh = IO::File->new_tmpfile or die "new_tmpfile: $!\n";
	$fh->binmode(':encoding(utf8)');
	my $fd = $fh->fcntl(F_GETFD, 0) or die "fcntl F_GETFD: $!\n";
	$fh->fcntl(F_SETFD, $fd & ~FD_CLOEXEC) or die "fcntl F_SETFD: $!\n";
	$fh->printflush($contents);
	$fh->seek(0, 0);
	$orig = sprintf "%s/%d", $fdpath, $fh->fileno;
    }

    @update_diffcmd or confess "Empty diff command";
    exec @update_diffcmd, $orig, "-";
    die "exec: $!\n";
}

my $divert_buffer;

sub update_divert {
    my %arg = @_;
    my $filename = delete $arg{&FILELABEL};

    $divert_buffer = '';
    divert_stdout(\$divert_buffer);
}

sub update_file {
    my %arg = @_;
    my $filename = delete $arg{&FILELABEL};
    my $newname = '';

    recover_stdout() or die;
    return if $arg{discard};
    $divert_buffer = decode 'utf8', $divert_buffer;

    return if $divert_buffer eq $_;
    return if $divert_buffer eq '';

    if (my $suffix = $opt_suffix) {
	$newname = $filename . $suffix;
	for (my $i = 1; -f $newname; $i++) {
	    $newname = $filename . $suffix . "_$i";
	}
    }

    my $create = do {
	if ($arg{replace}) {
	    if ($newname ne '') {
		warn "rename $filename -> $newname\n";
		rename $filename, $newname or die "rename: $!\n";
		die if -f $filename;
	    } else {
		warn "overwrite $filename\n";
	    }
	    $filename;
	} else {
	    warn "create $newname\n";
	    $newname;
	}
    };

    open my $fh, ">", $create or die "open: $create $!\n";
    $fh->print($divert_buffer);
    $fh->close;
}

1;

__DATA__

builtin diff-command=s $opt_update_diffcmd
builtin update-suffix=s      $opt_suffix
builtin diff-context|U=i     $opt_U
builtin remember!     $remember_data
builtin with-backup:s $opt_backup

option default \
	--prologue update_initialize \
	--begin    update_begin

expand ++dump --all -h --color=never --no-newline --no-line-number
option --update::diff    ++dump --of &update_diff
option --update::create  ++dump --begin update_divert --end update_file() --update-suffix=.new
option --update::update  ++dump --begin update_divert --end update_file(replace)
option --update::discard        --begin update_divert --end update_file(discard)

option --diff    --update::diff
option --create  --update::create
option --update  --update::update
option --discard --update::discard

#  LocalWords:  greple diff sdif cdif
