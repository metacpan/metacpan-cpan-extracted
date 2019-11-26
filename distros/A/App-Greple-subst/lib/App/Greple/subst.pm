=head1 NAME

subst - Greple module for text search and substitution

=head1 VERSION

Version 2.02

=head1 SYNOPSIS

greple -Msubst --dict I<dictionary> [ options ]

  --check=[ng,ok,any,outstand,all]
  --select=N
  --linefold
  --stat
  --diff
  --diffcmd command
  --replace
  --create

=head1 DESCRIPTION

This B<greple> module supports search and substitution for text based
on dictionary file.

=begin comment

Substitution can be indicated by option B<--subst-from> and
B<--subst-to>, or specification file.

Next command replaces all string "FROM" to "TO".

  greple -Msubst --subst-from FROM --subst-to TO FROM

Of course, you should rather use B<sed> in this case.  Option
B<--subst-from> and B<--subst-to> can be repeated, and substitution is
done in order.

=end comment

Dictionary file is given by B<--dict> option and contians pattern and
correct string pairs.

    greple -Msubst --dict DICT

If the dictionary file cotains following data:

    colou?r      color
    cent(er|re)  center

Then above command find first pattern which does not match to second
string, that is "colour" and "centre" in this case.

Field "//" in dictionary file is ignored, so this file can be written
like this:

    colou?r      //  color
    cent(er|re)  //  center

You can use same file by B<greple>'s B<-f> option and string after
"//" is ignored as a comment in that case.

    greple -f DICT ...

=begin comment

Actually, it takes the second last field as a target, and the last
field as a substitution string.  All other fields are ignored.  This
behavior is useful when the pattern requires longer text than the
string to be converted.  See the next example:

    Black-\KMonday  // Monday  Friday

Pattern matches to string "Monday", but requires string "Black-" is
preceeding to it.  Substitution is done just for string "Monday",
which does not match to the original pattern.  As a matter of fact,
look-ahead and look-behind pattern is removed automatically, next
example works as expected.

    (?<=Black-)Monday  // Friday

Combining with B<greple>'s other options, it is possible to convert
strings in the specific area of the target files.

=end comment

=over 7

=item B<--check>=I<ng>|I<ok>|I<any>|I<outstand>|I<all>|I<none>

Option B<--check> takes argument from I<ng>, I<ok>, I<any>,
I<outstand>, I<all> and I<none>.

With default value I<outstand>, command will show information about
correct and incorrect words only when incorrect word was found.

With value I<ng>, command will show information only about incorrect
word.  If you want to get data for correct word, use I<ok> or I<any>.

Value I<all> and I<none> makes sense only when used with B<--stat>
option.

=item B<--select>=I<N>

Select I<N>th entry from the dictionary.  Argument is interpreted by
L<Getopt::EX::Numbers> module.  Range can be defined like
B<--select>=I<1:3,7:9>.

=item B<--linefold>

If the target data is folded in the middle of text, use B<--linefold>
option.  It creates regex patterns which matches string spread across
lines.  Substituted text does not include newline, though.  Because it
confuses regex behavior somewhat, avoid to use if possible.

=item B<--stat>

Print statistical information.  By default, it only prints information
about incorrect words.  Works with B<--check> option.

=item B<--subst>

Substitute matched pattern to correct string.

=item B<--diff>

=item B<--diffcmd>=I<command>

Option B<-diff> produce diff output of original and converted text.

Specify diff command name used by B<--diff> option.  Default is "diff
-u".

=item B<--replace>

Replace the target file by converted result.  Original file is renamed
to backup name with ".bak" suffix.

=item B<--create>

Create new file and write the result.  Suffix ".new" is appended to
original filename.

=back

=head1 LICENSE

Copyright (C) Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<https://github.com/kaz-utashiro/greple>

L<https://github.com/kaz-utashiro/greple-subst>

=head1 AUTHOR

Kazumasa Utashiro

=cut


package App::Greple::subst;

our $VERSION = '2.02';

use v5.14;
use strict;
use warnings;
use utf8;
use open IO => ':utf8';

use Exporter 'import';
our @EXPORT      = qw(
    &subst_begin
    &subst_diff
    &subst_create
    &subst_stat
    &subst_stat_show
    &subst_search
    );
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use Carp;
use Data::Dumper;
use Text::ParseWords qw(shellwords);
use Getopt::EX::Numbers;
use Getopt::EX::Module; # to avoid error. why?
use App::Greple::Common;
use App::Greple::Pattern;

# oo interface
our @ISA = 'App::Greple::Pattern';
{
    sub new {
	my $class = shift;
	die if @_ < 2;
	my($pattern, $correct) = splice @_, 0, 2;
	my $obj = $class->SUPER::new($pattern, @_);
	$obj->correct($correct);
	$obj;
    }
    sub correct {
	my $obj = shift;
	@_ ? $obj->{CORRECT} = shift : $obj->{CORRECT};
    }
}

package SmartString {
    use List::Util qw(any);
    sub new {
	my($class, $var) = @_;
	bless ref $var ? $var : \$var, $class;
    }
    sub is {
	my $obj = shift;
	any { $_ eq $$obj } @_;
    }
}

our $debug = 0;
our $remember_data = 1;
our $opt_subst = 0;
our @opt_subst_from;
our @opt_subst_to;
our @opt_dictfile;
our $opt_subst_diffcmd = "diff -u";
our $opt_U;
our $opt_check = 'outstand';
my  $ss_check;
our @opt_format;
our @default_opt_format = ( '%s' );
our $opt_subst_select;
our $opt_linefold;

my $initialized;
my $current_file;
my $contents;
my @fromto;
my @subst_diffcmd;

sub debug {
    $debug = 1;
}

sub subst_initialize {

    $ss_check = bless \$opt_check, "SmartString";

    @subst_diffcmd = shellwords $opt_subst_diffcmd;

    @opt_format = @default_opt_format if @opt_format == 0;

    if (defined $opt_U) {
	@subst_diffcmd = ("diff", "-U$opt_U");
    }

    for my $dict (@opt_dictfile) {
	read_dict($dict);
    }

    if (my $select = $opt_subst_select) {
	my $max = @fromto;
	my $numbers = Getopt::EX::Numbers->new(max => $max);
	my @select = do {
	    map  { $_ - 1 }
	    sort { $a <=> $b }
	    grep { $_ <= $max }
	    map  { $numbers->parse($_)->sequence }
	    split /,/, $select;
	};
	@fromto = sub {
	    my @result = (undef) x $max;
	    @result[@select] = @fromto[@select];
	    @result;
	}->(@fromto);
    }

    $initialized = 1;
}

sub subst_begin {
    my %arg = @_;
    $current_file = delete $arg{&FILELABEL} or die;
    $contents = $_ if $remember_data;

    local $_; # for safety
    subst_initialize if not $initialized;
}

use Text::VisualWidth::PP;
use Text::VisualPrintf qw(vprintf vsprintf);
use List::Util qw(max);

sub vwidth {
    if (not defined $_[0] or length $_[0] eq 0) {
	return 0;
    }
    Text::VisualWidth::PP::width $_[0];
}

my @match_list;

sub subst_stat {
    my %arg = @_;
    $current_file = delete $arg{&FILELABEL} or die;

    for my $i (0 .. $#fromto) {
	my $p = $fromto[$i] // next;
	my($from_re, $to) = ($p->regex, $p->correct);

	my @match;
	while (/$from_re/gp) {
	    push @match, ${^MATCH};
	}
	my $hash = $match_list[$i] //= {};
	for my $match (@match) {
	    $match =~ s/\R//g;
	    $hash->{$match}++;
	}
    }

    $_ = "";
}

sub subst_stat_show {
    my %arg = @_;

    my $from_max = max map { vwidth $_->string  } grep { defined } @fromto;
    my $to_max   = max map { vwidth $_->correct } grep { defined } @fromto;

    for my $i (0 .. $#fromto) {
	my $p = $fromto[$i] // next;
	my($from_re, $to) = ($p->string, $p->correct);

	my $hash = $match_list[$i];
	my @keys = keys %{$hash};
	my @ng = grep { $_ ne $to } @keys;
	my @ok = grep { $_ eq $to } @keys;
	if      (is $ss_check 'none') {
	    next if @keys;
	} elsif (is $ss_check 'any') {
	    next unless @keys;
	} elsif (is $ss_check 'ng', 'outstand') {
	    next unless @ng;
	} elsif (is $ss_check 'ok') {
	    next unless @ok;
	}
	vprintf("%3d: %${from_max}s => %-${to_max}s",
		$i + 1, $from_re // '', $to // '');
	for my $key ((sort { $hash->{$b} <=> $hash->{$a} }
		      grep { $_ ne $to } @keys),
		     (grep { $_ eq $to } @keys)) {
	    my $index = $key eq $to ? $i * 2 + 1 : $i * 2;
	    printf(" %s(%d)",
		   main::index_color($index, $key),
		   $hash->{$key});
	}
	print "\n";
    }

    $_ = "";
}

sub read_dict {
    my $dict = shift;

    open DICT, $dict or die "$dict: $!\n";

    local $_;
    my $flag = FLAG_REGEX;
    $flag |= FLAG_COOK if $opt_linefold;
    while (<DICT>) {
	chomp;
	s/^\s*#.*//;
	/\S/ or next;

	my @param = grep { not m{^//+$} } split ' ';
	splice @param, 0, -2; # leave last one or two
	my($pattern, $correct) = @param;
	push @fromto, __PACKAGE__->new($pattern, $correct, flag => $flag);
    }
    close DICT;
}

use App::Greple::Regions qw(match_regions merge_regions);

sub subst_search {
    my $text = $_;
    my %arg = @_;
    $current_file = delete $arg{&FILELABEL} or die;

    my @matched;
    for my $index (0 .. $#fromto) {
	my $p = $fromto[$index] // next;
	my($from_re, $to) = ($p->string, $p->correct);
	my @r = match_regions(pattern => $p->regex);
	next if @r == 0 and $opt_check ne 'all';
	my $callback = sub {
	    my($ms, $me, $i, $s) = @_;
	    my $format = @opt_format[ $i % @opt_format ];
	    sprintf($format,
		    ($opt_subst && $s =~ s/\R//gr ne $to) ? $to : $s);
	};
	my(@ok, @ng);
	for (@r) {
	    my $matched = substr($text, $_->[0], $_->[1] - $_->[0]);
	    if ($matched =~ s/\R//gr ne $to) {
		$_->[2] = $index * 2;
		push @ng, $_;
	    } else {
		$_->[2] = $index * 2 + 1;
		push @ok, $_;
	    }
	    $_->[3] = $callback;
	}
	if      (is $ss_check 'ng') {
	    push @matched, @ng;
	} elsif (is $ss_check 'ok') {
	    push @matched, @ok;
	} elsif (is $ss_check 'any', 'all') {
	    push @matched, @r;
	} elsif (is $ss_check 'outstand') {
	    push @matched, @r if @ng;
	}
    }
    merge_regions { nojoin => 1 }, @matched;
}

sub subst_diff {
    my $orig = $current_file;
    my $io;

    if ($remember_data) {
	use IO::Pipe;
	$io = new IO::Pipe;
	my $pid = fork() // die "fork: $!\n";
	if ($pid == 0) {
	    $io->writer;
	    binmode $io, ":encoding(utf8)";
	    print $io $contents;
	    exit;
	}
	$io->reader;
    }

    # clear close-on-exec flag
    if ($io) {
	use Fcntl;
	my $fd = $io->fcntl(F_GETFD, 0) or die "fcntl F_GETFD: $!\n";
	$io->fcntl(F_SETFD, $fd & ~FD_CLOEXEC) or die "fcntl F_SETFD: $!\n";
	$orig = sprintf "/dev/fd/%d", $io->fileno;
    }

    exec @subst_diffcmd, $orig, "-";
    die "exec: $!\n";
}

sub subst_create {
    my %arg = @_;
    my $filename = delete $arg{&FILELABEL};

    my $suffix = $arg{suffix} || '.new';

    my $newname = do {
	my $tmp = $filename . $suffix;
	for (my $i = 1; -f $tmp; $i++) {
	    $tmp = $filename . $suffix . "_$i";
	}
	$tmp;
    };

    my $create = do {
	if ($arg{replace}) {
	    warn "rename $filename -> $newname\n";
	    rename $filename, $newname or die "rename: $!\n";
	    die if -f $filename;
	    $filename;
	} else {
	    warn "create $newname\n";
	    $newname;
	}
    };
	
    close STDOUT;
    open  STDOUT, ">$create" or die "open: $!\n";
}

1;

__DATA__

builtin dict|subst-file=s  @opt_dictfile
builtin subst-format=s     @opt_format
builtin subst!             $opt_subst
builtin diffcmd=s          $opt_subst_diffcmd
builtin U=i                $opt_U
builtin check=s            $opt_check
builtin select=s           $opt_subst_select
builtin linefold!          $opt_linefold

option default   --begin subst_begin --le &subst_search --subst-color
option --stat    --begin subst_stat --epilogue subst_stat_show
expand ++dump    --all --need 0 -h --nocolor
option --diff    --subst ++dump --of &subst_diff
option --create  --subst ++dump --begin subst_create
option --replace --subst ++dump --begin subst_create(replace,suffix=.bak)

option  --subst-color \
        --cm 555D/100,K/433 \
        --cm 555D/010,K/343 \
        --cm 555D/001,K/334 \
        --cm 555D/011,K/344 \
        --cm 555D/101,K/434 \
        --cm 555D/110,K/443 \
        --cm 555D/111,K/444 \
        --cm 555D/021,K/354 \
        --cm 555D/201,K/534 \
        --cm 555D/210,K/543 \
        --cm 555D/012,K/345 \
        --cm 555D/102,K/435 \
        --cm 555D/120,K/453 \
        --cm 555D/200,K/533 \
        --cm 555D/020,K/353 \
        --cm 555D/002,K/335 \
        --cm 555D/022,K/355 \
        --cm 555D/202,K/535 \
        --cm 555D/220,K/553 \
        --cm 555D/211,K/544 \
        --cm 555D/121,K/454 \
        --cm 555D/112,K/445 \
        --cm 555D/122,K/455 \
        --cm 555D/212,K/545 \
        --cm 555D/221,K/554 \
        --cm 555D/222,K/L23
