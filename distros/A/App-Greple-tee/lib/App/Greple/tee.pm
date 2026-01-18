=encoding utf-8

=head1 NAME

App::Greple::tee - module to replace matched text by the external command result

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 VERSION

Version 1.04

=head1 DESCRIPTION

Greple's B<-Mtee> module sends matched text part to the given filter
command, and replace them by the command result.  The idea is derived
from the command called B<teip>.  It is like bypassing partial data to
the external filter command.

Filter command follows module declaration (C<-Mtee>) and terminates by
two dashes (C<-->).  For example, next command call command C<tr>
command with C<a-z A-Z> arguments for the matched word in the data.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Above command convert all matched words from lower-case to upper-case.
Actually this example itself is not so useful because B<greple> can do
the same thing more effectively with B<--cm> option.

By default, the command is executed as a single process, and all
matched data is sent to the process mixed together.  If the matched
text does not end with newline, it is added before sending and removed
after receiving.  Input and output data are mapped line by line, so
the number of lines of input and output must be identical.

Using B<--discrete> option, individual command is called for each
matched text area.  You can tell the difference by following commands.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Lines of input and output data do not have to be identical when used
with B<--discrete> option.

=head1 OPTIONS

=over 7

=item B<--discrete>

Invoke new command individually for every matched part.

=item B<--bulkmode>

With the <--discrete> option, each command is executed on demand.  The
<--bulkmode> option causes all conversions to be performed at once.

=item B<--crmode>

This option replaces all newline characters in the middle of each
block with carriage return characters.  Carriage returns contained in
the result of executing the command are reverted back to the newline
character. Thus, blocks consisting of multiple lines can be processed
in batches without using the B<--discrete> option.

This works well with L<ansifold> command's B<--crmode> option, which
joins CR-separated text and outputs folded lines separated by CR.

=item B<--fillup>

Combine a sequence of non-blank lines into a single line before
passing them to the filter command.  Newline characters between wide
width characters (Japanese, Chinese) are deleted, and other newline
characters are replaced with spaces.  Korean (Hangul) is treated
like ASCII text and joined with space.

=item B<--squeeze>

Combines two or more consecutive newline characters into one.

=item B<-ML> B<--offload> I<command>

L<teip(1)>'s B<--offload> option is implemented in the different
module L<App::Greple::L> (B<-ML>).

    greple -Mtee cat -n -- -ML --offload 'seq 10 20'

You can also use the B<-ML> module to process only even-numbered lines
as follows.

    greple -Mtee cat -n -- -ML 2::2

=back

=head1 CONFIGURATION

Module parameters can be set with B<Getopt::EX::Config> module using
the following syntax:

    greple -Mtee::config(discrete) ...
    greple -Mtee::config(fillup,crmode) ...

This is useful when combined with shell aliases or module files.

Available parameters are: B<discrete>, B<bulkmode>, B<crmode>,
B<fillup>, B<squeeze>, B<blocks>.

=head1 FUNCTION CALL

Instead of an external command, you can call a Perl function by
prefixing the command name with C<&>.

    greple -Mtee '&App::ansifold::ansifold' -w40 -- ...

The function is executed in a forked child process, so it must follow
these requirements:

=over 4

=item *

Read matched text from B<STDIN>

=item *

Print converted result to B<STDOUT>

=item *

Arguments are passed via both C<@ARGV> and C<@_>

=back

Any fully qualified function name can be used:

    greple -Mtee '&Your::Module::function' -- ...

The module is automatically loaded if not already loaded.

For convenience, the following short aliases are available:

=over 4

=item B<&ansicolumn>

Calls C<App::ansicolumn::ansicolumn>.

=item B<&ansifold>

Calls C<App::ansifold::ansifold>.

=item B<&cat-v>

Calls C<App::cat::v-E<gt>new-E<gt>run(@_)>.

=back

Using a function call avoids the overhead of forking an external
process for each invocation, which can significantly improve
performance when used with the B<--discrete> option.

=head1 LEGACIES

The B<--blocks> option is no longer needed now that the B<--stretch>
(B<-S>) option has been implemented in B<greple>.  You can simply
perform the following.

    greple -Mtee cat -n -- --all -SE foo

It is not recommended to use B<--blocks> as it may be deprecated in
the future.


=over 7

=item B<--blocks>

Normally, the area matching the specified search pattern is sent to
the external command. If this option is specified, not the matched
area but the entire block containing it will be processed.

For example, to send lines containing the pattern C<foo> to the
external command, you need to specify the pattern which matches to
entire line:

    greple -Mtee cat -n -- '^.*foo.*\n' --all

But with the B<--blocks> option, it can be done as simply as follows:

    greple -Mtee cat -n -- foo --blocks

With B<--blocks> option, this module behave more like L<teip(1)>'s
B<-g> option.  Otherwise, the behavior is similar to L<teip(1)> with
the B<-o> option.

Do not use the B<--blocks> with the B<--all> option, since the block
will be the entire data.

=back

=head1 WHY DO NOT USE TEIP

First of all, whenever you can do it with the B<teip> command, use
it. It is an excellent tool and much faster than B<greple>.

Because B<greple> is designed to process document files, it has many
features that are appropriate for it, such as match area controls. It
might be worth using B<greple> to take advantage of those features.

Also, B<teip> cannot handle multiple lines of data as a single unit,
while B<greple> can execute individual commands on a data chunk
consisting of multiple lines.

=head1 EXAMPLE

Next command will find text blocks inside L<perlpod(1)> style document
included in Perl module file.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

You can translate them by DeepL service by executing the above command
convined with B<-Mtee> module which calls B<deepl> command like this:

    greple -Mtee deepl text --to JA - -- --fillup ...

The dedicated module L<App::Greple::xlate::deepl> is more effective
for this purpose, though.  In fact, the implementation hint of B<tee>
module came from B<xlate> module.

=head1 EXAMPLE 2

Next command will find some indented part in LICENSE document.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

You can reformat this part by using B<tee> module with B<ansifold>
command.  Using both B<--crmode> options together allows efficient
processing of multi-line blocks:

    greple -Mtee ansifold -sw40 --prefix '     ' --crmode -- --crmode --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

The B<--discrete> option can also be used but will start multiple
processes, so it takes longer to execute.

=head1 EXAMPLE 3

Consider a situation where you want to grep for strings from
non-header lines. For example, you may want to search for Docker image
names from the C<docker image ls> command, but leave the header line.
You can do it by following command.

    greple -Mtee grep perl -- -ML 2: --discrete --all

Option C<-ML 2:> retrieves the second to last lines and sends
them to the C<grep perl> command.  The option --discrete is required
because the number of lines of input and output changes, but since the
command is only executed once, there is no performance drawback.

If you try to do the same thing with the B<teip> command,
C<teip -l 2- -- grep> will give an error because the number of output
lines is less than the number of input lines. However, there is no
problem with the result obtained.

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::tee

=head1 SEE ALSO

L<App::Greple::tee>, L<https://github.com/kaz-utashiro/App-Greple-tee>

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate>

L<App::ansifold>, L<https://github.com/tecolicom/App-ansifold>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::tee;

our $VERSION = "1.04";

use v5.24;
use warnings;
use experimental 'refaliasing';
use Carp;
use List::Util qw(sum first);
use Text::ParseWords qw(shellwords);
use Command::Run;
use Data::Dumper;
use Getopt::EX::Config;
use App::Greple::tee::Autoload qw(resolve);

my $config = Getopt::EX::Config->new(
    debug => 0,
    blocks => 0,
    discrete => 0,
    fillup => 0,
    squeeze => 0,
    bulkmode => 0,
    crmode => 0,
    use => '',
);

our $command;
\our $debug    = \$config->{debug};
\our $blocks   = \$config->{blocks};
\our $discrete = \$config->{discrete};
\our $fillup   = \$config->{fillup};
\our $squeeze  = \$config->{squeeze};
\our $bulkmode = \$config->{bulkmode};
\our $crmode   = \$config->{crmode};

my($mod, $argv);

sub initialize {
    ($mod, $argv) = @_;
    if (defined (my $i = first { $argv->[$_] eq '--' } keys @$argv)) {
	if (my @command = splice @$argv, 0, $i) {
	    $command = \@command;
	}
	shift @$argv eq '--' or die;
    }
}

sub finalize {
    ($mod, $argv) = @_;
    for my $mod (grep length, split /,/, $config->{use}) {
	eval "require $mod; $mod->import()";
	die $@ if $@;
    }
}

use Unicode::EastAsianWidth;

sub InConcatScript {
    return <<"END";
+App::Greple::tee::InFullwidth
-utf8::Hangul
END
}

sub InFullwidthPunctuation {
    return <<"END";
+App::Greple::tee::InFullwidth
&utf8::Punctuation
END
}

sub fillup_block {
    (my $s1, local $_, my $s2) = $_[0] =~ /\A(\s*)(.*?)(\s*)\z/s or die;
    s/(?<=\p{InFullwidthPunctuation})\n//g;
    s/(?<=\p{InConcatScript})\n(?=\p{InConcatScript})//g;
    s/[ ]*\n[ ]*/ /g;
    $s1 . $_ . $s2;
}

sub fillup_paragraphs {
    local *_ = @_ > 0 ? \$_[0] : \$_;
    s{^.+(?:\n.+)*}{ fillup_block ${^MATCH} }pmge;
}

sub call {
    my $data = shift;
    $command // return $data;
    my $exec = Command::Run->new;
    if ($discrete and $fillup) {
	fillup_paragraphs $data;
    }
    if (ref $command ne 'ARRAY') {
	$command = [ shellwords $command ];
    }
    my @command = @$command;
    # Resolve &function to code reference
    if (@command and $command[0] =~ /^&(.+)/) {
	shift @command;
	unshift @command, resolve($1);
    }
    my $out = $exec->command(@command)->with(stdin => $data)->update->data // '';
    if ($squeeze) {
	$out =~ s/\n\n+/\n/g;
    }
    $out;
}

sub bundle_call {
    if ($fillup) {
	fillup_paragraphs for @_;
    }
    my @chop = grep { $_[$_] =~ s/(?<!\n)\z/\n/ } keys @_;
    my @lines = map { int tr/\n/\n/ } @_;
    my $lines = sum @lines;
    my $out = call join '', @_;
    my @out = $out =~ /.*\n/g;
    if (@out < $lines) {
	die "Unexpected short response:\n\n$out\n";
    } elsif (@out > $lines) {
	warn "Unexpected long response:\n\n$out\n";
    }
    my @ret = map { join '', splice @out, 0, $_ } @lines;
    chop for @ret[@chop];
    return @ret;
}

my @bundle;

sub postgrep {
    my $grep = shift;
    if ($blocks) {
	$grep->{RESULT} = [
	    [ [ 0, length ],
	      map {
		  [ $_->[0][0], $_->[0][1], 0, $grep->{callback}->[0] ]
	      } $grep->result
	    ] ];
    }
    return if $discrete and not $bulkmode;
    @bundle = my @block = ();
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    push @block, $grep->cut(@$m);
	}
    }

    if ($crmode) {
	s/\n(?!\z)/\r/g for @block;
    }

    @bundle = do {
	if ($discrete) {
	    map { call $_ } @block;
	} else {
	    bundle_call @block;
	}
    } if @block;

    if ($crmode) {
	s/\r/\n/g for @bundle;
    }
}

sub callback {
    if ($discrete and not $bulkmode) {
	call { @_ }->{match};
    }
    else {
	shift @bundle // die;
    }
}

1;

__DATA__

builtin tee-debug $debug
builtin blocks    $blocks
builtin discrete! $discrete
builtin bulkmode! $bulkmode
builtin crmode!   $crmode
builtin fillup!   $fillup
builtin squeeze   $squeeze

option default \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback

option --tee-each --discrete

#  LocalWords:  greple tee teip DeepL deepl perl xlate
