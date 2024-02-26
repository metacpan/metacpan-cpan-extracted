=encoding utf8

=head1 NAME

update - Greple module to update file content

=head1 SYNOPSIS

greple -Mupdate

Options:

  --update       replace file content
  --with-backup  make backup files

  --diff         produce diff output
  -U#            specify unified diff context length

  --discard      simply discard the output

=head1 VERSION

Version 1.03

=head1 DESCRIPTION

This B<greple> module substitute the target file content by command
output.  For example, next command replace all words in the file to
uppercase.

    greple -Mupdate '\w+' --cm 'sub{uc}' --update file

Above is a very simple example but you can implement arbitrarily
complex function in conjunction with other various B<greple> options.

You can check how the file will be edited by B<--diff> option.

    greple -Mupdate '\w+' --cm 'sub{uc}' --diff file

Command B<sdif> or B<cdif> would be useful to see the difference
visually.

    greple -Mupdate '\w+' --cm 'sub{uc}' --diff file | cdif

This module has been spun off from L<App::Greple::subst> module.
Consult it for more practical use case.

=head1 OPTIONS

=over 7

=item B<--update>

=item B<--update::update>

Update the target file by command output.  Entire file content is
produced and any color effects are canceled.  Without this option,
B<greple> behaves as normal operation, that means only matched lines
are printed.

File is not touched as far as its content does not change.

The file is also not updated if the output is empty.  This is to
prevent the contents of the file from being erased if none of the
match strings are included.  If you want to intentionally empty a
file, you need to think of another way.

=item B<--with-backup>[=I<suffix>]

Backup original file with C<.bak> suffix.  If optional parameter is
given, it is used as a suffix string.  If the file exists, C<.bak_1>,
C<.bak_2> ... are used.

=item B<--discard>

=item B<--update::discard>

Simply discard the command output without updating file.

=begin comment

=item B<--create>

=item B<--update::create>

Create new file and write the result.  Suffix ".new" is appended to
the original filename.

=end comment

=item B<--diff>

=item B<--update::diff>

Option B<-diff> produce diff output of original and converted text.
Option B<-U#> can be used to specify context length.

=begin comment

=item B<--diffcmd>=I<command>

Specify diff command name used by B<--diff> option.  Default is "diff
-u".

=end comment

=back

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

Copyright 2022-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::update;
use v5.14;
use warnings;

our $VERSION = '1.03';

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

our $debug = 0;
our $remember_data = 1;
our $opt_update_diffcmd = "diff -u";
our $opt_suffix = '';
our $opt_backup;
our $opt_U = '';

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
	$opt_suffix = $opt_backup ne '' ? $opt_backup : '.bak';
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
    my $diverted = 0;
    my $buffer;

    sub divert_stdout {
	$buffer = @_ ? shift : '/dev/null';
	$diverted = $diverted == 0 ? 1 : return;
	open  UPDATE_STDOUT, '>&', \*STDOUT or die "open: $!";
	close STDOUT;
	open  STDOUT, '>', $buffer or die "open: $!";
    }

    sub recover_stdout {
	$diverted = $diverted == 1 ? 0 : return;
	close STDOUT;
	open  STDOUT, '>&', \*UPDATE_STDOUT or die "open: $!";
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
	$fh = new_tmpfile IO::File or die "new_tmpfile: $!\n";
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

    if ($_ eq $divert_buffer or $divert_buffer eq '') {
	return;
    }

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

builtin diffcmd=s     $opt_update_diffcmd
builtin update-suffix=s      $opt_suffix
builtin U=i           $opt_U
builtin remember!     $remember_data
builtin with-backup:s $opt_backup

option default \
	--prologue update_initialize \
	--begin    update_begin

expand ++dump --all -h --color=never --no-newline --no-line-number
option --update::diff    ++dump --of &update_diff
option --update::create  ++dump --begin update_divert --end update_file() --update-suffix=.new
option --update::update  ++dump --begin update_divert --end update_file(replace)
option --update::discard ++dump --begin update_divert --end update_file(discard)

option --diff    --update::diff
option --create  --update::create
option --update  --update::update
option --discard --update::discard

#  LocalWords:  greple diff sdif cdif
