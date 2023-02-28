=encoding utf-8

=head1 NAME

App::Greple::tee - eşleşen metni harici komut sonucu ile değiştiren modül

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Greple'ın B<-Mtee> modülü, eşleşen metin parçasını verilen filtre komutuna gönderir ve bunları komut sonucuyla değiştirir. Bu fikir B<teip> adlı komuttan türetilmiştir. Kısmi verileri harici filtre komutuna atlamak gibidir.

Filtre komutu modül bildirimini (C<-Mtee>) takip eder ve iki tire (C<-->) ile sonlanır. Örneğin, bir sonraki komut verideki eşleşen kelime için C<a-z A-Z> argümanları ile C<tr> komutunu çağırır.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Yukarıdaki komut eşleşen tüm kelimeleri küçük harften büyük harfe dönüştürür. Aslında bu örneğin kendisi çok kullanışlı değildir çünkü B<greple> aynı şeyi B<--cm> seçeneği ile daha etkili bir şekilde yapabilir.

Varsayılan olarak, komut tek bir işlem olarak yürütülür ve eşleşen tüm veriler karışık olarak gönderilir. Eşleşen metin satırsonu ile bitmiyorsa, önce eklenir ve sonra kaldırılır. Veriler satır satır eşlenir, bu nedenle girdi ve çıktı verilerinin satır sayısı aynı olmalıdır.

B<--discrete> seçeneği kullanıldığında, eşleşen her parça için ayrı bir komut çağrılır. Farkı aşağıdaki komutlarla anlayabilirsiniz.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

B<--discrete> seçeneği kullanıldığında giriş ve çıkış verilerinin satırları aynı olmak zorunda değildir.

=head1 OPTIONS

=over 7

=item B<--discrete>

Eşleşen her parça için ayrı ayrı yeni komut çağırın.

=back

=head1 WHY DO NOT USE TEIP

Öncelikle, B<teip> komutu ile yapabildiğiniz her şeyi kullanın. Mükemmel bir araçtır ve B<greple>'den çok daha hızlıdır.

B<greple> belge dosyalarını işlemek için tasarlandığından, eşleşme alanı kontrolleri gibi buna uygun birçok özelliğe sahiptir. Bu özelliklerden yararlanmak için B<greple> kullanmaya değer olabilir.

Ayrıca, B<teip> birden fazla veri satırını tek bir birim olarak işleyemezken, B<greple> birden fazla satırdan oluşan bir veri yığını üzerinde ayrı komutlar çalıştırabilir.

=head1 EXAMPLE

Sonraki komut, Perl modül dosyasında bulunan L<perlpod(1)> tarzı belge içindeki metin bloklarını bulacaktır.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Yukarıdaki komutu B<deepl> komutunu çağıran B<-Mtee> modülü ile birlikte çalıştırarak DeepL servisi ile çevirebilirsiniz:

    greple -Mtee deepl text --to JA - -- --discrete ...

B<deepl> tek satırlık girdi için daha iyi çalıştığından, komut kısmını bu şekilde değiştirebilirsiniz:

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

Yine de özel modül L<App::Greple::xlate::deepl> bu amaç için daha etkilidir. Aslında, B<tee> modülünün uygulama ipucu B<xlate> modülünden gelmiştir.

=head1 EXAMPLE 2

Sonraki komut LICENSE belgesinde bazı girintili kısımlar bulacaktır.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
Bu kısmı B<tee> modülünü B<ansifold> komutu ile kullanarak yeniden biçimlendirebilirsiniz:

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
