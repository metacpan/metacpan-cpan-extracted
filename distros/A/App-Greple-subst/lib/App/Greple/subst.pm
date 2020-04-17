=encoding utf8

=head1 NAME

subst - Greple module for text search and substitution

=head1 VERSION

Version 2.12

=head1 SYNOPSIS

greple -Msubst --dict I<dictionary> [ options ]

  --check=[ng,ok,any,outstand,all]
  --select=N
  --linefold
  --stat
  --with-stat
  --stat-style=[default,dict]
  --diff
  --diffcmd command
  --replace
  --create
  --[no-]warn-overlap
  --[no-]warn-include

=head1 DESCRIPTION

This B<greple> module supports check and substitution of text file
using a dictionary file.

Dictionary file is given by B<--dict> option and contains pattern and
expected string pairs.

    greple -Msubst --dict DICT

If the dictionary file contains following data:

    colou?r      color
    cent(er|re)  center

Then above command find the first pattern which does not match the
second string, that is "colour" and "centre" in this case.

Field "//" in dictionary file is ignored, so this file can be written
like this:

    colou?r      //  color
    cent(er|re)  //  center

You can use same file by B<greple>'s B<-f> option and string after
"//" is ignored as a comment in that case.

    greple -f DICT ...

=head2 Overlapped pattern

When the matched string is same or shorter than previously matched
string by another pattern, it is simply ignored (B<--no-warn-include>
by default).  So, if you have to declare conflicted patterns, put the
longer pattern in front.

If the matched string overlaps with previously matched string, it is
warned (B<--warn-overlap> by default) and ignored.

=head2 Terminal color

This version uses L<Getopt::EX::termcolor> module.  It sets option
B<--light-screen> or B<--dark-screen> depending on the terminal on
which the command run, or B<BRIGHTNESS> environment variable.

Some terminals (eg: "Apple_Terminal" or "iTerm") are detected
automatically and no action is required.  Otherwise set B<BRIGHTNESS>
environment to 0 (black) to 100 (white) digit depending on terminal
background color.

=head1 OPTIONS

=over 7

=item B<--check>=I<outstand>|I<ng>|I<ok>|I<any>|I<all>|I<none>

Option B<--check> takes argument from I<ng>, I<ok>, I<any>,
I<outstand>, I<all> and I<none>.

With default value I<outstand>, command will show information about
both expected and unexpected words only when unexpected word was found
in the same file.

With value I<ng>, command will show information about unexpected
words.  With value I<ok>, you will get information about expected
words.  Both with value I<any>.

Value I<all> and I<none> make sense only when used with B<--stat>
option, and display information about never matched pattern.

=item B<--select>=I<N>

Select I<N>th entry from the dictionary.  Argument is interpreted by
L<Getopt::EX::Numbers> module.  Range can be defined like
B<--select>=I<1:3,7:9>.  You can get numbers by B<--stat> option.

=item B<--linefold>

If the target data is folded in the middle of text, use B<--linefold>
option.  It creates regex patterns which matches string spread across
lines.  Substituted text does not include newline, though.  Because it
confuses regex behavior somewhat, avoid to use if possible.

=item B<--stat>

=item B<--with-stat>

Print statistical information.  Works with B<--check> option.

Option B<--with-stat> print statistics after normal output, while
B<--stat> print only statistics.

=item B<--stat-style>=[I<default>|I<dict>]

Using B<--stat-style=dict> option with B<--stat> and B<--check=any>,
you can get dictionary style output for your working document.

=item B<--subst>

Substitute unexpected matched pattern to expected string.  Newline
character in the matched string is ignored.  Pattern without
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

=head1 DICTIONARY

This module includes example dictionaries.  They are installed share
directory and accessed by B<--exdict> option.

    greple -Msubst --exdict jtca-katakana-guide-3.dict

=over 7

=item B<--exdict> I<dictionary>

Use I<dictionary> flie in the distribution as a dictionary file.

=item B<--exdictdir>

Show dictionary directory.

=item B<--exdict> jtca-katakana-guide-3.dict

=item B<--jtca-katakana-guide>

Created from following guideline document.

    外来語（カタカナ）表記ガイドライン 第3版
    制定：2015年8月
    発行：2015年9月
    一般財団法人テクニカルコミュニケーター協会 
    Japan Technical Communicators Association
    https://www.jtca.org/standardization/katakana_guide_3_20171222.pdf

=item B<--exdict> jtf-style-guide-3.dict

=item B<--jtf-style-guide>

Created from following guideline document.

    JTF日本語標準スタイルガイド（翻訳用）
    第3.0版
    2019年8月20日
    一般社団法人 日本翻訳連盟（JTF）
    翻訳品質委員会
    https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf

=item B<--exdict> sccc2.dict

=item B<--sccc2>

Dictionary used for "C/C++ セキュアコーディング 第2版" published in
2014.

    https://www.jpcert.or.jp/securecoding_book_2nd.html

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::subst
    or
    $ curl -sL http://cpanmin.us | perl - App::Greple::subst

=head1 SEE ALSO

L<https://github.com/kaz-utashiro/greple>

L<https://github.com/kaz-utashiro/greple-subst>

https://www.jtca.org/standardization/katakana_guide_3_20171222.pdf

https://www.jtf.jp/jp/style_guide/styleguide_top.html,
https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright (C) 2017-2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package App::Greple::subst;

our $VERSION = '2.12';

use v5.14;
use strict;
use warnings;
use utf8;
use open IO => ':utf8';

use Exporter 'import';
our @EXPORT      = qw(
    &subst_initialize
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
use App::Greple::Common;
use App::Greple::Pattern;
use App::Greple::subst::Dict;

use File::Share qw(:all);
$ENV{GREPLE_SUBST_DICT} //= dist_dir 'App-Greple-subst';

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
our $opt_printdict;
our $opt_dictname;
our $opt_subst_diffcmd = "diff -u";
our $opt_U;
our $opt_check = 'outstand';
my  $ss_check;
our @opt_format;
our @default_opt_format = ( '%s' );
our $opt_subst_select;
our $opt_linefold;
our $opt_ignore_space = 1;
our $opt_warn_overlap = 1;
our $opt_warn_include = 0;
our $opt_stat_style = "default";
our $opt_show_comment = 0;
our $opt_show_numbers = 1;
my %stat;

my $current_file;
my $contents;
my @subst_diffcmd;
my $ignorechar_re;
my $dict = new App::Greple::subst::Dict;

sub debug {
    $debug = 1;
}

sub subst_initialize {

    state $once_called++ and return;

    $ss_check = bless \$opt_check, "App::Greple::subst::SmartString";

    @subst_diffcmd = shellwords $opt_subst_diffcmd;

    @opt_format = @default_opt_format if @opt_format == 0;

    $ignorechar_re = $opt_ignore_space ? qr/\s+/ : qr/\R+/;

    if (defined $opt_U) {
	@subst_diffcmd = ("diff", "-U$opt_U");
    }

    for my $dictfile (@opt_dictfile) {
	if (-d $dict) {
	    warn "$dict is directory\n";
	    next;
	}
	read_dict($dictfile);
    }
}

sub subst_begin {
    my %arg = @_;
    $current_file = delete $arg{&FILELABEL} or die;
    $contents = $_ if $remember_data;
}

#
# define &divert_stdout and &recover_stdout
#
{
    my $diverted = 0;

    sub divert_stdout {
	$diverted = $diverted == 0 ? 1 : return;
	open  SUBST_STDOUT, '>&', \*STDOUT or die "open: $!";
	close STDOUT;
	open  STDOUT, '>', '/dev/null' or die "open: $!";
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
    if (not defined $_[0] or length $_[0] == 0) {
	return 0;
    }
    Text::VisualWidth::PP::width $_[0];
}

my @match_list;

sub subst_show_stat {
    my %arg = @_;
    my @fromto = $dict->dictionary;
    my($from_max, $to_max) = (0, 0);
    my @show;
    for my $i (0 .. $#fromto) {
	my $p = $fromto[$i] // next;
	if ($p->is_comment) {
	    push @show, [ $i, $p, {} ];
	    next;
	}
	my($from_re, $to) = ($p->string, $p->correct // '');
	my $hash = $match_list[$i] // {};
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
	$from_max = max $from_max, vwidth $from_re;
	$to_max   = max $to_max  , vwidth $to;
	push @show, [ $i, $p, $hash ];
    }
    if ($opt_show_numbers) {
	printf "HIT_PATTERN=%d/%d NG=%d, OK=%d, TOTAL=%d\n",
	    $stat{hit}, $stat{total},
	    $stat{ng}, $stat{ok}, $stat{ng} + $stat{ok};
    }
    for my $show (@show) {
	my($i, $p, $hash) = @$show;
	if ($p->is_comment) {
	    say $p->comment if $opt_show_comment;
	    next;
	}
	my($from_re, $to) = ($p->string, $p->correct // '');
	my @keys = keys %{$hash};
	if ($opt_stat_style eq 'dict') {
	    vprintf("%-${from_max}s // %s", $from_re // '', $to // '');
	} else {
	    vprintf("%${from_max}s => %-${to_max}s %4d:",
		    $from_re // '', $to // '', $i + 1);
	    for my $key ((sort { $hash->{$b} <=> $hash->{$a} }
			  grep { $_ ne $to } @keys),
			 (grep { $_ eq $to } @keys)) {
		my $index = $key eq $to ? $i * 2 + 1 : $i * 2;
		printf(" %s(%d)",
		       main::index_color($index, $key),
		       $hash->{$key});
	    }
	}
	print "\n";
    }
    $_ = "";
}

sub read_dict {
    my $dictfile = shift;
    say $dictfile if $opt_dictname;

    open DICT, $dictfile or die "$dictfile: $!\n";

    local $_;
    my $flag = FLAG_REGEX;
    $flag |= FLAG_COOK if $opt_linefold;
    while (<DICT>) {
	print if $opt_printdict;
	chomp;
	if (not /^\s*[^#]/) {
	    $dict->add_comment($_);
	    next;
	}
	my @param = grep { not m{^//+$} } split ' ';
	splice @param, 0, -2; # leave last one or two
	my($pattern, $correct) = @param;
	$dict->add($pattern, $correct, flag => $flag);
    }
    close DICT;
}

sub mix_regions {
    my $option = ref $_[0] eq 'HASH' ? shift : {};
    my($old, $new) = @_;
    return () if @$new == 0;
    my @old = $option->{destructive} ? @{$old} : map [ @$_ ], @{$old};
    my @new = $option->{destructive} ? @{$new} : map [ @$_ ], @{$new};
    unless ($option->{nosort}) {
	@new = sort({$a->[0] <=> $b->[0] || $b->[1] <=> $a->[1]
			 ||  (@$a > 2 ? $a->[2] <=> $b->[2] : 0) }
		    @new);
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
    my $index = -1;
    my @effective;
    my $ng = is $ss_check qw(ng any all none);
    my $ok = is $ss_check qw(ok any all none);
    my $outstand = is $ss_check qw(outstand);
    for my $p ($dict->dictionary) {
	$index++;
	$p // next;
	next if $p->is_comment;
	my($from_re, $to) = ($p->string, $p->correct // '');
	my @match = match_regions pattern => $p->regex;
	$stat{total}++;
	$stat{hit}++ if @match;
	next if @match == 0 and $opt_check ne 'all';
	my $hash = $match_list[$index] //= {};
	my $callback = sub {
	    my($ms, $me, $i, $matched) = @_;
	    my $s = $matched =~ s/$ignorechar_re//gr;
	    $hash->{$s}++;
	    my $format = @opt_format[ $i % @opt_format ];
	    sprintf($format,
		    ($opt_subst && $to ne '' && $s ne $to) ?
		    $to : $matched);
	};
	my(@ok, @ng);
	for (@match) {
	    my $matched = substr $text, $_->[0], $_->[1] - $_->[0];
	    if ($matched =~ s/$ignorechar_re//gr ne $to) {
		$_->[2] = $index * 2;
		push @ng, $_;
	    } else {
		$_->[2] = $index * 2 + 1;
		push @ok, $_;
	    }
	    $_->[3] = $callback;
	}
	$stat{ng} += @ng;
	$stat{ok} += @ok;
	$effective[ $index * 2     ] = 1 if $ng || ( @ng && $outstand );
	$effective[ $index * 2 + 1 ] = 1 if $ok || ( @ng && $outstand );
	mix_regions {
	    overlap => ( my $overlap = [] ),
	    include => ( my $include = [] ),
	    nosort  => 1,
	}, \@matched, \@match;
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
    ##
    ## --select
    ##
    if (my $select = $opt_subst_select) {
	my $max = $dict->dictionary;
	use Getopt::EX::Numbers;
	my $numbers = Getopt::EX::Numbers->new(max => $max);
	my %select = do {
	    map  { ($_ * 2 => 1) , ($_ * 2 + 1 => 1) }
	    map  { $_ - 1 }
	    grep { $_ <= $max }
	    map  { $numbers->parse($_)->sequence }
	    split /,/, $select;
	};
	@matched = grep $select{$_->[2]}, @matched;
    }
    grep $effective[$_->[2]], @matched;
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

builtin dict=s         @opt_dictfile
builtin stat-style=s   $opt_stat_style
builtin printdict!     $opt_printdict
builtin dictname!      $opt_dictname
builtin subst-format=s @opt_format
builtin subst!         $opt_subst
builtin diffcmd=s      $opt_subst_diffcmd
builtin U=i            $opt_U
builtin check=s        $opt_check
builtin select=s       $opt_subst_select
builtin linefold!      $opt_linefold
builtin remember!      $remember_data
builtin warn-overlap!  $opt_warn_overlap
builtin warn-include!  $opt_warn_include
builtin ignore-space!  $opt_ignore_space
builtin show-comment!  $opt_show_comment

option default \
	-Mtermcolor::set(default=100,light=--subst-color-light,dark=--subst-color-dark) \
	--prologue subst_initialize \
	--begin subst_begin \
	--le &subst_search --no-regioncolor

expand ++dump    --all --need 0 -h --nocolor
option --diff    --subst ++dump --of &subst_diff
option --create  --subst ++dump --begin subst_create
option --replace --subst ++dump --begin subst_create(replace,suffix=.bak)

option --divert-stdout --prologue __PACKAGE__::divert_stdout \
		       --epilogue __PACKAGE__::recover_stdout
option --with-stat     --epilogue subst_show_stat
option --stat          --divert-stdout --with-stat

option	--subst-color-light \
	--cm 555D/100,000/433 \
	--cm 555D/010,000/343 \
	--cm 555D/001,000/334 \
	--cm 555D/011,000/344 \
	--cm 555D/101,000/434 \
	--cm 555D/110,000/443 \
	--cm 555D/111,000/444 \
	--cm 555D/021,000/354 \
	--cm 555D/201,000/534 \
	--cm 555D/210,000/543 \
	--cm 555D/012,000/345 \
	--cm 555D/102,000/435 \
	--cm 555D/120,000/453 \
	--cm 555D/200,000/533 \
	--cm 555D/020,000/353 \
	--cm 555D/002,000/335 \
	--cm 555D/022,000/355 \
	--cm 555D/202,000/535 \
	--cm 555D/220,000/553 \
	--cm 555D/211,000/544 \
	--cm 555D/121,000/454 \
	--cm 555D/112,000/445 \
	--cm 555D/122,000/455 \
	--cm 555D/212,000/545 \
	--cm 555D/221,000/554 \
	--cm 555D/222,000/L23 \
	$<move(0,0)>

option	--subst-color-dark \
	--cm DS;433,544/L01 \
	--cm DS;343,454/L01 \
	--cm DS;334,445/L01 \
	--cm DS;344,455/L01 \
	--cm DS;434,545/L01 \
	--cm DS;443,554/L01 \
	--cm DS;243,354/L01 \
	--cm DS;423,534/L01 \
	--cm DS;432,543/L01 \
	--cm DS;234,345/L01 \
	--cm DS;324,435/L01 \
	--cm DS;342,453/L01 \
	--cm DS;422,533/L01 \
	--cm DS;242,353/L01 \
	--cm DS;224,335/L01 \
	--cm DS;244,355/L01 \
	--cm DS;424,535/L01 \
	--cm DS;442,553/L01 \
	$<move(0,0)>

##
## Handle included sample dictionaries.
##

option --exdict  --dict $ENV{GREPLE_SUBST_DICT}/$<shift>

option --exdictdir --prologue 'sub{ say "$ENV{GREPLE_SUBST_DICT}"; exit }'

option --jtca-katakana-guide --exdict jtca-katakana-guide-3.dict
option --jtf-style-guide     --exdict jtf-style-guide-3.dict
option --sccc2               --exdict sccc2.dict

option --all-katakana	     --exdict all-katakana.dict

option --dumpdict --printdict --prologue 'sub{exit}'

#  LocalWords:  subst Greple greple ng ok outstand linefold dict diff
#  LocalWords:  regex Kazumasa Utashiro
