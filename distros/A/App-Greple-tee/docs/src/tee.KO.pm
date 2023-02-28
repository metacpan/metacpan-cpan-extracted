=encoding utf-8

=head1 NAME

App::Greple::tee - 일치하는 텍스트를 외부 명령 결과로 대체하는 모듈

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Greple의 B<-Mtee> 모듈은 지정된 필터 명령에 일치하는 텍스트 부분을 전송하고 명령 결과로 대체합니다. 이 아이디어는 B<teip>이라는 명령에서 파생되었습니다. 일부 데이터를 외부 필터 명령으로 우회하는 것과 같습니다.

필터 명령은 모듈 선언(C<-Mtee>)을 따르고 두 개의 대시(C<-->)로 끝납니다. 예를 들어, 다음 명령은 데이터에서 일치하는 단어에 대한 C<a-z A-Z> 인수를 사용하여 C<tr> 명령을 호출합니다.

    greple -Mtee tr a-z A-Z -- '\w+' ...

위의 명령은 일치하는 모든 단어를 소문자에서 대문자로 변환합니다. 사실 이 예제 자체는 B<--cm> 옵션을 사용하면 동일한 작업을 더 효과적으로 수행할 수 있기 때문에 그다지 유용하지 않습니다.

기본적으로 이 명령은 단일 프로세스로 실행되며 일치하는 모든 데이터가 혼합되어 전송됩니다. 일치하는 텍스트가 개행으로 끝나지 않으면 앞에 추가되고 뒤에 제거됩니다. 데이터는 한 줄씩 매핑되므로 입력 및 출력 데이터의 줄 수는 동일해야 합니다.

B<-- 불연속> 옵션을 사용하면 일치하는 각 부분에 대해 개별 명령이 호출됩니다. 다음 명령을 통해 차이점을 확인할 수 있습니다.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

B<-- 불연속> 옵션과 함께 사용할 경우 입력 및 출력 데이터의 줄이 동일할 필요는 없습니다.

=head1 OPTIONS

=over 7

=item B<--discrete>

일치하는 모든 부분에 대해 개별적으로 새 명령을 호출합니다.

=back

=head1 WHY DO NOT USE TEIP

우선, B<teip> 명령으로 할 수 있을 때마다 이 명령을 사용하세요. 이 명령은 훌륭한 도구이며 B<greple>보다 훨씬 빠릅니다.

B<greple>은 문서 파일을 처리하도록 설계되었기 때문에 일치 영역 제어와 같이 이에 적합한 기능이 많이 있습니다. 이러한 기능을 활용하려면 B<greple>을 사용하는 것이 좋습니다.

또한 B<teip>은 여러 줄의 데이터를 단일 단위로 처리할 수 없는 반면, B<greple>은 여러 줄로 구성된 데이터 청크에 대해 개별 명령을 실행할 수 있습니다.

=head1 EXAMPLE

다음 명령은 Perl 모듈 파일에 포함된 L<perlpod(1)> 스타일 문서 내에서 텍스트 블록을 찾습니다.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

DeepL 서비스에서 위 명령어를 B<-Mtee> 모듈과 결합하여 실행하면 다음과 같이 B<deepl> 명령어를 호출합니다:

    greple -Mtee deepl text --to JA - -- --discrete ...

B<deepl>은 한 줄 입력에 더 잘 동작하므로 명령어 부분을 다음과 같이 변경할 수 있습니다:

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

하지만 이런 용도로는 전용 모듈인 L<App::Greple::xlate::deep>을 사용하는 것이 더 효과적입니다. 사실 B<tee> 모듈의 구현 힌트는 B<xlate> 모듈에서 따온 것입니다.

=head1 EXAMPLE 2

다음 명령은 라이선스 문서에서 들여쓰기된 부분을 찾습니다.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
이 부분은 B<tee> 모듈을 B<ansifold> 명령과 함께 사용하여 다시 포맷할 수 있습니다:

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

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate>

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
