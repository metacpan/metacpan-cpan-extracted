=encoding utf-8

=head1 NAME

App::Greple::tee - 用外部命令结果替换匹配文本的模块

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Greple的B<-Mtee>模块将匹配的文本部分发送到给定的过滤命令，并以命令结果替换它们。这个想法来自于名为B<teip>的命令。它就像绕过部分数据到外部过滤命令。

过滤命令在模块声明之后（C<-Mtee>），以两个破折号结束（C<-->）。例如，下一个命令调用C<tr>命令，参数为C<a-z A-Z>，用于数据中的匹配字。

    greple -Mtee tr a-z A-Z -- '\w+' ...

上述命令将所有匹配的单词从小写转换为大写。事实上，这个例子本身并不那么有用，因为B<greple>可以用B<--cm>选项更有效地做同样的事情。

默认情况下，该命令是作为一个单独的进程执行的，所有匹配的数据被混合在一起发送给它。如果匹配的文本不以换行结尾，就会在前面添加，后面删除。数据是逐行映射的，所以输入和输出数据的行数必须是相同的。

使用B<--discrete>选项，每一个匹配的零件都被调用单独的命令。你可以通过以下命令来区分。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

使用B<--discrete>选项时，输入和输出数据的行数不一定相同。

=head1 OPTIONS

=over 7

=item B<--discrete>

为每个匹配的零件单独调用新的命令。

=back

=head1 WHY DO NOT USE TEIP

首先，只要你能用B<teip>命令做，就使用它。它是一个优秀的工具，比B<greple>快得多。

因为B<greple>是为处理文档文件而设计的，它有许多适合于它的功能，如匹配区控制。也许值得使用B<greple>来利用这些功能。

另外，B<teip>不能将多行数据作为一个单元来处理，而B<greple>可以在由多行组成的数据块上执行单个命令。

=head1 EXAMPLE

下一个命令将找到包含在Perl模块文件中的L<perlpod(1)>风格文件内的文本块。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

你可以通过DeepL，通过执行上述命令与B<-Mtee>模块相结合，调用B<deepl>命令，像这样翻译它们。

    greple -Mtee deepl text --to JA - -- --discrete ...

因为B<deepl>对单行输入效果更好，你可以把命令部分改成这样。

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

不过，专用模块L<App::Greple::xlate::deepl>对这个目的更有效。事实上，B<tee>模块的实现提示来自B<xlate>模块。

=head1 EXAMPLE 2

接下来的命令会发现LICENSE文件中有一些缩进的部分。

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
你可以通过使用B<tee>模块和B<ansifold>命令来重新格式化这部分内容。

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.
    
=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::tee

=head1 SEE ALSO

L<App::Greple::Tee>, L<https://github.com/kaz-utashiro/App-Greple-tee>

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate>.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::tee;

our $VERSION = "0.03";

use v5.14;
use warnings;
use Carp;
use List::Util qw(sum first);
use Text::ParseWords qw(shellwords);
use App::cdif::Command;
use Data::Dumper;

our $command;
our $blockmatch;
our $discrete;

my @jammed;
my($mod, $argv);

sub initialize {
    ($mod, $argv) = @_;
    if (defined (my $i = first { $argv->[$_] eq '--' } 0 .. $#{$argv})) {
	if (my @command = splice @$argv, 0, $i) {
	    $command = \@command;
	}
	shift @$argv;
    }
}

sub call {
    my $data = shift;
    $command // return $data;
    state $exec = App::cdif::Command->new;
    if (ref $command ne 'ARRAY') {
	$command = [ shellwords $command ];
    }
    $exec->command($command)->setstdin($data)->update->data;
}

sub jammed_call {
    my @need_nl = grep { $_[$_] !~ /\n\z/ } 0 .. $#_;
    my @from = @_;
    $from[$_] .= "\n" for @need_nl;
    my @lines = map { int tr/\n/\n/ } @from;
    my $from = join '', @from;
    my $out = call $from;
    my @out = $out =~ /.*\n/g;
    if (@out < sum @lines) {
	die "Unexpected response from command:\n\n$out\n";
    }
    my @to = map { join '', splice @out, 0, $_ } @lines;
    $to[$_] =~ s/\n\z// for @need_nl;
    return @to;
}

sub postgrep {
    my $grep = shift;
    @jammed = my @block = ();
    if ($blockmatch) {
	$grep->{RESULT} = [
	    [ [ 0, length ],
	      map {
		  [ $_->[0][0], $_->[0][1], 0, $grep->{callback} ]
	      } $grep->result
	    ] ];
    }
    return if $discrete;
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    push @block, $grep->cut(@$m);
	}
    }
    @jammed = jammed_call @block if @block;
}

sub callback {
    if ($discrete) {
	call { @_ }->{match};
    }
    else {
	shift @jammed // die;
    }
}

1;

__DATA__

builtin --blockmatch $blockmatch
builtin --discrete!  $discrete

option default \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback

option --tee-each --discrete

#  LocalWords:  greple tee teip DeepL deepl perl xlate
