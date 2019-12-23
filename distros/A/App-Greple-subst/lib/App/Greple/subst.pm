=head1 NAME

subst - Greple module for text search and substitution

=head1 VERSION

Version 2.06

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
  --[no-]warn-overlap
  --[no-]warn-include

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

Dictionary file is given by B<--dict> option and contains pattern and
correct string pairs.

    greple -Msubst --dict DICT

If the dictionary file contains following data:

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
preceding to it.  Substitution is done just for string "Monday",
which does not match to the original pattern.  As a matter of fact,
look-ahead and look-behind pattern is removed automatically, next
example works as expected.

    (?<=Black-)Monday  // Friday

Combining with B<greple>'s other options, it is possible to convert
strings in the specific area of the target files.

=end comment

=head2 Overlapped pattern

When the matched string is same or shorter than previously matched
string by another pattern, it is simply ignored (B<--no-warn-include>
by default).  So, if you have to declare conflicted patterns, put the
longer pattern in front.

If the matched string overlaps with previously matched string, it is
warned (B<--warn-overlap> by default) and ignored.

=head1 OPTIONS

=over 7

=item B<--check>=I<ng>|I<ok>|I<any>|I<outstand>|I<all>|I<none>

Option B<--check> takes argument from I<ng>, I<ok>, I<any>,
I<outstand>, I<all> and I<none>.

With default value I<outstand>, command will show information about
correct and incorrect words only when incorrect word was found in the
same file.

With value I<ng>, command will show information only about incorrect
word.  If you want to get data for correct word, use I<ok> or I<any>.

Value I<all> and I<none> make sense only when used with B<--stat>
option, and display information about never matched pattern.

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

=item B<--with-stat>

Print statistical information.  By default, it only prints information
about incorrect words.  Works with B<--check> option.

Option B<--with-stat> print statistics after normal output, while
B<--stat> print only statistics.

=item B<--subst>

Substitute matched pattern to correct string.  Pattern without
replacement string is not changed.

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

=item B<--[no-]warn-overlap>

Warn overlapped pattern.
Default on.

=item B<--[no-]warn-include>

Warn included pattern.
Default off.

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

our $VERSION = '2.06';

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
    &subst_show_stat
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

package App::Greple::subst::SmartString {
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
our $opt_warn_overlap = 1;
our $opt_warn_include = 0;

my $initialized;
my $current_file;
my $contents;
my @fromto;
my @subst_diffcmd;

sub debug {
    $debug = 1;
}

sub subst_initialize {

    $ss_check = bless \$opt_check, "App::Greple::subst::SmartString";

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

{
    my $diverted = 0;

    sub divert_stdout {
	$diverted = $diverted == 0 ? 1 : return;
	open  SUBST_STDOUT, '>&', \*STDOUT or die "open: $!";
	close STDOUT;
	open  STDOUT, '>/dev/null' or die "open: $!";
    }

    sub recover_stdout {
	$diverted = $diverted == 1 ? 0 : return;
	close STDOUT;
	open  STDOUT, '>&', \*SUBST_STDOUT or die "open: $!";
    }
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

sub subst_show_stat {
    my %arg = @_;

    my $from_max = max map { vwidth $_->string  } grep { defined } @fromto;
    my $to_max   = max map { vwidth $_->correct } grep { defined } @fromto;

    for my $i (0 .. $#fromto) {
	my $p = $fromto[$i] // next;
	my($from_re, $to) = ($p->string, $p->correct // '');

	my $hash = $match_list[$i] // {};
	my @keys = keys %{$hash};
	my @ng = grep { $_ ne $to } @keys;
	my @ok = grep { $_ eq $to } @keys;
	if      (is $ss_check 'none') {
	    next if @keys;
	}
	elsif (is $ss_check 'any') {
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

sub mix_regions {
    my $option = ref $_[0] eq 'HASH' ? shift : {};
    my($old, $new) = @_;
    return () if @$new == 0;
    my @old = $option->{destructive} ? @_ : map { [ @$_ ] } @{$old};
    my @new = $option->{destructive} ? @_ : map { [ @$_ ] } @{$new};
    unless ($option->{nosort}) {
	@new = sort({$a->[0] <=> $b->[0] || $b->[1] <=> $a->[1]
			 ||  (@$a > 2 ? $a->[2] <=> $b->[2] : 0)
		    } @new);
    }
    my @out;
    my($include, $overlap) = @{$option}{qw(include overlap)};
    while (@old and @new) {
	while (@old and $old[0][1] <= $new[0][0]) {
	    push @out, shift @old;
	}
	last if @old == 0;
	while (@new and $new[0][1] <= $old[0][0]) {
	    push @out, shift @new;
	}
	while (@new and $new[0][0] < $old[0][1]) {
	    if ($old[0][0] <= $new[0][0] and $new[0][1] <= $old[0][1]) {
		push @$include, [ $new[0], $old[0] ] if $include;
	    } else {
		push @$overlap, [ $new[0], $old[0] ] if $overlap;
	    }
	    shift @new;
	}
    }
    @$old = ( @out, @old, @new );
}

use App::Greple::Regions qw(match_regions);

sub subst_search {
    my $text = $_;
    my %arg = @_;
    $current_file = delete $arg{&FILELABEL} or die;

    my @matched;
    for my $index (0 .. $#fromto) {
	my $p = $fromto[$index] // next;
	my($from_re, $to) = ($p->string, $p->correct // '');
	my @match = match_regions(pattern => $p->regex);
	next if @match == 0 and $opt_check ne 'all';
	my $callback = sub {
	    my($ms, $me, $i, $matched) = @_;
	    my $s = $matched =~ s/\R//rg;
	    $match_list[$index]->{$s}++;
	    my $format = @opt_format[ $i % @opt_format ];
	    sprintf($format,
		    ($opt_subst && $to ne '' && $s ne $to) ?
		    $to : $matched);
	};
	my(@ok, @ng);
	for (@match) {
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
	my $mix =
	    (is $ss_check qw(ng))           ? \@ng :
	    (is $ss_check qw(ok))           ? \@ok :
	    (is $ss_check qw(outstand))     ? ( @ng ? \@match : [] ) :
	    (is $ss_check qw(any all none)) ? \@match :
	    die "Invalid parameter: $opt_check\n";
	mix_regions {
	    overlap => ( my $overlap = [] ),
	    include => ( my $include = [] ),
	    nosort => 1
	}, \@matched, $mix;
	##
	## Warning
	##
	for my $warn (
	    [ "Overlap", $overlap, $opt_warn_overlap ],
	    [ "Include", $include, $opt_warn_include ],
	    ) {
	    my($kind, $list, $show) = @$warn;
	    next unless $show;
	    for my $info (@$list) {
		my($new, $old) = @$info;
		warn sprintf("%s \"%s\" with \"%s\" by #%d /%s/ in %s at %d\n",
			     $kind,
			     substr($_, $new->[0], $new->[1] - $new->[0]),
			     substr($_, $old->[0], $old->[1] - $old->[0]),
			     $index + 1, $p->string,
			     $current_file,
			     $new->[0],
		    );
	    }
	}
    }
    @matched;
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
builtin remember!          $remember_data
builtin warn-overlap!      $opt_warn_overlap
builtin warn-include!      $opt_warn_include

option default \
	--begin subst_begin \
	--le &subst_search --no-regioncolor \
	--subst-color

expand ++dump    --all --need 0 -h --nocolor
option --diff    --subst ++dump --of &subst_diff
option --create  --subst ++dump --begin subst_create
option --replace --subst ++dump --begin subst_create(replace,suffix=.bak)

option --divert-stdout --prologue __PACKAGE__::divert_stdout \
		       --epilogue __PACKAGE__::recover_stdout
option --with-stat     --epilogue subst_show_stat
option --stat          --divert-stdout --with-stat

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

#  LocalWords:  subst Greple greple ng ok outstand linefold dict diff
#  LocalWords:  regex Kazumasa Utashiro
