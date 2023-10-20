=encoding utf8

=head1 NAME

subst - Greple module for text search and substitution

=head1 VERSION

Version 2.3301

=head1 SYNOPSIS

greple -Msubst --dict I<dictionary> [ options ]

  Dictionary:
    --dict      dictionary file
    --dictdata  dictionary data

  Check:
    --check=[ng,ok,any,outstand,all,none]
    --select=N
    --linefold
    --stat
    --with-stat
    --stat-style=[default,dict]
    --stat-item={match,expect,number,ok,ng,dict}=[0,1]
    --subst
    --[no-]warn-overlap
    --[no-]warn-include

  File Update:
    --diff
    --diffcmd command
    --create
    --replace
    --overwrite

=head1 DESCRIPTION

This B<greple> module supports check and substitution of text files
based on dictionary data.

Dictionary file is given by B<--dict> option and each line contains
matching pattern and expected string pairs.

    greple -Msubst --dict DICT

If the dictionary file contains following data:

    colou?r      color
    cent(er|re)  center

above command finds the first pattern which does not match the second
string, that is "colour" and "centre" in this case.

Field C<//> in dictionary data is ignored, so this file can be written
like this:

    colou?r      //  color
    cent(er|re)  //  center

You can use same file by B<greple>'s B<-f> option and string after
C<//> is ignored as a comment in that case.

    greple -f DICT ...

Option B<--dictdata> can be used to provide dictionary data in command
line.

    greple --dictdata $'colou?r color\ncent(er|re) center\n'

Dictionary entry starting with a sharp sign (C<#>) is a comment and
ignored.

=head2 Overlapped pattern

When the matched string is same or shorter than previously matched
string by another pattern, it is simply ignored (B<--no-warn-include>
by default).  So, if you have to declare conflicted patterns, place
the longer pattern earlier.

If the matched string overlaps with previously matched string, it is
warned (B<--warn-overlap> by default) and ignored.

=head2 Terminal color

This version uses L<Getopt::EX::termcolor> module.  It sets option
B<--light-screen> or B<--dark-screen> depending on the terminal on
which the command run, or B<TERM_BGCOLOR> environment variable.

Some terminals (eg: "Apple_Terminal" or "iTerm") are detected
automatically and no action is required.  Otherwise set
B<TERM_BGCOLOR> environment to #000000 (black) to #FFFFFF (white)
digit depending on terminal background color.

=head1 OPTIONS

=over 7

=item B<--dict>=I<file>

Specify dictionary file.

=item B<--dictdata>=I<data>

Specify dictionary data by text.

=item B<--check>=C<outstand>|C<ng>|C<ok>|C<any>|C<all>|C<none>

Option B<--check> takes argument from C<ng>, C<ok>, C<any>,
C<outstand>, C<all> and C<none>.

With default value C<outstand>, command will show information about
both expected and unexpected words only when unexpected word was found
in the same file.

With value C<ng>, command will show information about unexpected
words.  With value C<ok>, you will get information about expected
words.  Both with value C<any>.

Value C<all> and C<none> make sense only when used with B<--stat>
option, and display information about never matched pattern.

=item B<--select>=I<N>

Select I<N>th entry from the dictionary.  Argument is interpreted by
L<Getopt::EX::Numbers> module.  Range can be defined like
B<--select>=C<1:3,7:9>.  You can get numbers by B<--stat> option.

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

=item B<--stat-style>=C<default>|C<dict>

Using B<--stat-style=dict> option with B<--stat> and B<--check=any>,
you can get dictionary style output for your working document.

=item B<--stat-item> I<item>=[0,1]

Specify which item is shown up in stat information.  Default values
are:

    match=1
    expect=1
    number=1
    ng=1
    ok=1
    dict=0

If you don't need to see pattern field, use like this:

    --stat-item match=0

Multiple parameters can be set at once:

    --stat-item match=number=0,ng=1,ok=1

=item B<--subst>

Substitute unexpected matched pattern to expected string.  Newline
character in the matched string is ignored.  Pattern without
replacement string is not changed.

=item B<--[no-]warn-overlap>

Warn overlapped pattern.
Default on.

=item B<--[no-]warn-include>

Warn included pattern.
Default off.

=back

=head2 FILE UPDATE OPTIONS

=over 7

=item B<--diff>

=item B<--diffcmd>=I<command>

Option B<--diff> produce diff output of original and converted text.

Specify diff command name used by B<--diff> option.  Default is "diff
-u".

=item B<--create>

Create new file and write the result.  Suffix ".new" is appended to
original filename.

=item B<--replace>

Replace the target file by converted result.  Original file is renamed
to backup name with ".bak" suffix.

=item B<--overwrite>

Overwrite the target file by converted result with no backup.

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

=item B<--jtca>

Customized B<--jtca-katakana-guide>.  Original dictionary is
automatically generated from published data.  This dictionary is
customized for practical use.

=item B<--exdict> jtf-style-guide-3.dict

=item B<--jtf-style-guide>

Created from following guideline document.

    JTF日本語標準スタイルガイド（翻訳用）
    第3.0版
    2019年8月20日
    一般社団法人 日本翻訳連盟（JTF）
    翻訳品質委員会
    https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf

=item B<--jtf>

Customized B<--jtf-style-guide>.  Original dictionary is automatically
generated from published data.  This dictionary is customized for
practical use.

=item B<--exdict> sccc2.dict

=item B<--sccc2>

Dictionary used for "C/C++ セキュアコーディング 第2版" published in
2014.

    https://www.jpcert.or.jp/securecoding_book_2nd.html

=item B<--exdict> ms-style-guide.dict

=item B<--ms-style-guide>

Dictionary generated from Microsoft localization style guide.

    https://www.microsoft.com/ja-jp/language/styleguides

Data is generated from this article:

    https://www.atmarkit.co.jp/news/200807/25/microsoft.html

=item B<--microsoft>

Customized B<--ms-style-guide>.  Original dictionary is automatically
generated from published data.  This dictionary is customized for
practical use.

Amendment dictionary can be found
L<here|https://github.com/kaz-utashiro/greple-subst/blob/master/share/ms-amend.dict>.
Please raise an issue or send a pull-request if you have request to update.

=back

=head1 JAPANESE

This module is originaly made for Japanese text editing support.

=head2 KATAKANA

Japanese KATAKANA word have a lot of variants to describe same word,
so unification is important but it's quite tiresome work.  In the next
example,

    イ[エー]ハトー?([ヴブボ]ォ?)  //  イーハトーヴォ

left pattern matches all following words.

    イエハトブ
    イーハトヴ
    イーハトーヴ
    イーハトーヴォ
    イーハトーボ
    イーハトーブ

This module helps to detect and correct them.

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::subst

=head1 SEE ALSO

L<https://github.com/kaz-utashiro/greple>

L<https://github.com/kaz-utashiro/greple-subst>

L<https://github.com/kaz-utashiro/greple-update>

L<https://www.jtca.org/standardization/katakana_guide_3_20171222.pdf>

L<https://www.jtf.jp/jp/style_guide/styleguide_top.html>,
L<https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf>

L<https://www.microsoft.com/ja-jp/language/styleguides>,
L<https://www.atmarkit.co.jp/news/200807/25/microsoft.html>

L<文化庁 国語施策・日本語教育 国語施策情報 内閣告示・内閣訓令 外来語の表記|https://www.bunka.go.jp/kokugo_nihongo/sisaku/joho/joho/kijun/naikaku/gairai/index.html>

L<https://qiita.com/kaz-utashiro/items/85add653a71a7e01c415>

L<イーハトーブ|https://ja.wikipedia.org/wiki/%E3%82%A4%E3%83%BC%E3%83%8F%E3%83%88%E3%83%BC%E3%83%96>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2017-2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


use v5.14;
package App::Greple::subst;

our $VERSION = '2.3301';

use warnings;
use utf8;
use open IO => ':utf8';

use Exporter 'import';
our @EXPORT      = qw(
    &subst_initialize
    &subst_begin
    &subst_diff
    &subst_update
    &subst_show_stat
    &subst_search
    );
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use Carp;
use Data::Dumper;
use Text::ParseWords qw(shellwords);
use Encode;
use Getopt::EX::Colormap qw(colorize);
use Getopt::EX::LabeledParam;
use App::Greple::Common;
use App::Greple::Pattern;
use App::Greple::subst::Dict;

use File::Share qw(:all);
$ENV{GREPLE_SUBST_DICT} //= dist_dir 'App-Greple-subst';

our $debug = 0;
our $remember_data = 1;
our $opt_subst = 0;
our @opt_subst_from;
our @opt_subst_to;
our @opt_dictfile;
our @opt_dictdata;
our $opt_printdict;
our $opt_dictname;
our $opt_check = 'outstand';
our @opt_format;
our @default_opt_format = ( '%s' );
our $opt_subst_select;
our $opt_linefold;
our $opt_ignore_space = 1;
our $opt_warn_overlap = 1;
our $opt_warn_include = 0;
our $opt_stat_style = "default";
our @opt_stat_item;
our %opt_stat_item = (
    map( { $_ => 1 } qw(match expect number ng ok) ),
    map( { $_ => 0 } qw(dict) ),
    );
our $opt_show_comment = 0;
our $opt_show_numbers = 1;
my %stat;

my $current_file;
my $contents;
my $ignorechar_re;
my @dicts;

sub debug {
    $debug = 1;
}

sub subst_initialize {

    state $once_called++ and return;

    Getopt::EX::LabeledParam
	->new(HASH => \%opt_stat_item)
	->load_params(@opt_stat_item);

    @opt_format = @default_opt_format if @opt_format == 0;

    $ignorechar_re = $opt_ignore_space ? qr/\s+/ : qr/\R+/;

    my $config = { linefold  => $opt_linefold,
		   dictname  => $opt_dictname,
		   printdict => $opt_printdict };
    for my $data (@opt_dictdata) {
	push @dicts, App::Greple::subst::Dict->new(
	    DATA => $data,
	    CONFIG => $config,
	    );
    }
    for my $file (@opt_dictfile) {
	if (-d $file) {
	    warn "$file is directory\n";
	    next;
	}
	push @dicts, App::Greple::subst::Dict->new(
	    FILE => $file,
	    CONFIG => $config,
	    );
    }

    if (@dicts == 0) {
	warn "Module -Msubst requires dictionary data.\n";
	main::usage();
	die;
    }
}

sub subst_begin {
    my %arg = @_;
    $current_file = delete $arg{&FILELABEL} or die;
    $contents = $_ if $remember_data;
}

use Text::VisualWidth::PP;
use Text::VisualPrintf qw(vprintf vsprintf);
use List::Util qw(max any sum first);

sub vwidth {
    if (not defined $_[0] or length $_[0] == 0) {
	return 0;
    }
    Text::VisualWidth::PP::width $_[0];
}

my @match_list;

sub subst_show_stat {
    my %arg = @_;
    my($from_max, $to_max) = (0, 0);
    my $i = -1;
    my @show_list;
    for my $dict (@dicts) {
	my @fromto = $dict->words;
	my @show;
	for my $p (@fromto) {
	    $i++;
	    $p // die;
	    if ($p->is_comment) {
		push @show, [ $i, $p, {} ] if $opt_show_comment;
		next;
	    }
	    my($from_re, $to) = ($p->string, $p->correct // '');
	    my $hash = $match_list[$i] // {};
	    my @keys = keys %{$hash};
	    my @ng = grep { $_ ne $to } @keys;
	    my @ok = grep { $_ eq $to } @keys;
	    if    ($opt_check eq 'none'    ) { next if @keys != 0 }
	    elsif ($opt_check eq 'any'     ) { next if @keys == 0 }
	    elsif ($opt_check eq 'ok'      ) { next if @ok   == 0 }
	    elsif ($opt_check eq 'ng'      ) { next if @ng   == 0 }
	    elsif ($opt_check eq 'outstand') { next if @ng   == 0 }
	    elsif ($opt_check eq 'all')      { }
	    else { die }
	    $from_max = max $from_max, vwidth $from_re;
	    $to_max   = max $to_max  , vwidth $to;
	    push @show, [ $i, $p, $hash ];
	}
	push @show_list, [ $dict => \@show ];
    }
    if ($opt_show_numbers) {
	no warnings 'uninitialized';
	printf "HIT_PATTERN=%d/%d NG=%d, OK=%d, TOTAL=%d\n",
	    $stat{hit}, $stat{total},
	    $stat{ng}, $stat{ok}, $stat{ng} + $stat{ok};
    }
    for my $show_list (@show_list) {
	my($dict, $show) = @{$show_list};
	next if @$show == 0;
	my $dict_format = ">>> %s <<<\n";
	if ($opt_stat_item{dict}) {
	    print colorize('000/L24E', sprintf($dict_format, $dict->NAME));
	}
	for my $item (@$show) {
	    my($i, $p, $hash) = @$item;
	    if ($p->is_comment) {
		say $p->comment if $opt_show_comment;
		next;
	    }
	    my($from_re, $to) = ($p->string, $p->correct // '');
	    my @keys = keys %{$hash};
	    if ($opt_stat_style eq 'dict') {
		vprintf("%-${from_max}s // %s", $from_re // '', $to // '');
	    } else {
		my @ng = sort { $hash->{$b} <=> $hash->{$a} } grep { $_ ne $to } @keys
		    if $opt_stat_item{ng};
		my @ok = grep { $_ eq $to } @keys
		    if $opt_stat_item{ok};
		vprintf("%${from_max}s => ", $from_re // '') if $opt_stat_item{match};
		vprintf("%-${to_max}s",      $to // '')      if $opt_stat_item{expect};
		vprintf(" %4d:",             $i + 1)         if $opt_stat_item{number};
		for my $key (@ng, @ok) {
		    my $index = $key eq $to ? $i * 2 + 1 : $i * 2;
		    printf(" %s(%s)",
			   main::index_color($index, $key),
			   colorize($key eq $to ? 'DB' : 'DR', $hash->{$key})
			);
		}
	    }
	    print "\n";
	}
    }
    $_ = "";
}

use App::Greple::Regions qw(match_regions merge_regions filter_regions);

sub subst_search {
    my $text = $_;
    my %arg = @_;
    $current_file = delete $arg{&FILELABEL} or die;

    my @matched;
    my $index = -1;
    my @effective;
    my $ng = {ng=>1,        any=>1, all=>1, none=>1}->{$opt_check} ;
    my $ok = {       ok=>1, any=>1, all=>1, none=>1}->{$opt_check} ;
    my $outstand = $opt_check eq 'outstand';
    for my $dict (@dicts) {
	for my $p ($dict->words) {
	    $index++;
	    $p // next;
	    next if $p->is_comment;
	    my($from_re, $to) = ($p->string, $p->correct // '');
	    my @match = match_regions pattern => $p->regex;

	    ##
	    ## Remove all overlapped matches.
	    ##
	    my($in, $over, $out, $im, $om) = filter_regions \@match, \@matched;
	    @match = @$out;
	    for my $warn (
		[ "Include", $in,   $im, $opt_warn_include ],
		[ "Overlap", $over, $om, $opt_warn_overlap ],
		) {
		my($kind, $list, $match, $show) = @$warn;
		$show and @$list or next;
		for my $i (0 .. @$list - 1) {
		    my($a, $b) = ($list->[$i], $match->[$i]);
		    warn sprintf("%s \"%s\" with \"%s\" by #%d /%s/ in %s at %d\n",
				 $kind,
				 substr($_, $a->[0], $a->[1] - $a->[0]),
				 substr($_, $b->[0], $b->[1] - $b->[0]),
				 $index + 1, $p->string,
				 $current_file,
				 $a->[0],
			);
		}
	    }

	    $stat{total}++;
	    $stat{hit}++ if @match;
	    next if @match == 0 and $opt_check ne 'all';

	    my $hash = $match_list[$index] //= {};
	    my $callback = sub {
		my($ms, $me, $i, $matched) = @_;
		$stat{$i % 2 ? 'ok' : 'ng'}++;
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
	    $effective[ $index * 2     ] = 1 if $ng || ( @ng && $outstand );
	    $effective[ $index * 2 + 1 ] = 1 if $ok || ( @ng && $outstand );

	    @matched = merge_regions { nojoin => 1 }, @matched, @match;
	}
    }
    ##
    ## --select
    ##
    if (my $select = $opt_subst_select) {
	my $max = sum map { int $_->words } @dicts;
	use Getopt::EX::Numbers;
	my $numbers = Getopt::EX::Numbers->new(min => 1, max => $max);
	my @select;
	for (my @select_index = do {
	    map  { $_ * 2, $_ * 2 + 1 }
	    map  { $_ - 1 }
	    grep { $_ <= $max }
	    map  { $numbers->parse($_)->sequence }
	    split /,/, $select;
	}) {
	    $select[$_] = 1;
	}
	@matched = grep $select[$_->[2]], @matched;
    }
    grep $effective[$_->[2]], @matched;
}

1;

__DATA__

builtin         dict=s @opt_dictfile
builtin     dictdata=s @opt_dictdata
builtin   stat-style=s $opt_stat_style
builtin    stat-item=s @opt_stat_item
builtin    printdict!  $opt_printdict
builtin     dictname!  $opt_dictname
builtin subst-format=s @opt_format
builtin        subst!  $opt_subst
builtin        check=s $opt_check
builtin       select=s $opt_subst_select
builtin     linefold!  $opt_linefold
builtin     remember!  $remember_data
builtin warn-overlap!  $opt_warn_overlap
builtin warn-include!  $opt_warn_include
builtin ignore-space!  $opt_ignore_space
builtin show-comment!  $opt_show_comment

option default \
	-Mtermcolor::bg(default=100,light=--subst-color-light,dark=--subst-color-dark) \
	--prologue subst_initialize \
	--begin subst_begin \
	--le +&subst_search --no-regioncolor

##
## Now these options are implemented by -Mupdate module
## --diffcmd, -U are built-in options
##
autoload -Mupdate \
	--update::diff   \
	--update::create \
	--update::update \
	--update::discard

option --diff      --subst --update::diff
option --create    --subst --update::create
option --replace   --subst --update::update --with-backup
option --overwrite --subst --update::update

option --with-stat --epilogue subst_show_stat
option --stat      --update::discard --with-stat

autoload -Msubst::dyncmap --dyncmap

help	--subst-color-light light terminal color
option	--subst-color-light --colormap --dyncmap \
	range=0-2,except=000:111:222,shift=3,even="555D/%s",odd="IU;000/%s"

help	--subst-color-dark dark terminal color
option	--subst-color-dark --colormap --dyncmap \
	range=2-4,except=222:333:444,shift=1,even="D;L01/%s",odd="IU;%s/L01"

##
## Handle included sample dictionaries.
##

option --exdict  --dict $ENV{GREPLE_SUBST_DICT}/$<shift>

option --exdictdir --prologue 'sub{ say "$ENV{GREPLE_SUBST_DICT}"; exit }'

option --jtca-katakana-guide --exdict jtca-katakana-guide-3.dict
option --jtf-style-guide     --exdict jtf-style-guide-3.dict
option --ms-style-guide      --exdict ms-style-guide.dict

option --sccc2     --exdict sccc2.dict
option --jtca      --exdict jtca.dict
option --jtf       --exdict jtf.dict
option --microsoft --exdict ms-amend.dict --exdict ms-style-guide.dict

# deprecated. don't use.
option --ms --microsoft

option --all-sample-dict --jtf --jtca --microsoft

option --all-katakana --exdict all-katakana.dict

option --dumpdict --printdict --prologue 'sub{exit}'

#  LocalWords:  subst Greple greple ng ok outstand linefold dict diff
#  LocalWords:  regex Kazumasa Utashiro
