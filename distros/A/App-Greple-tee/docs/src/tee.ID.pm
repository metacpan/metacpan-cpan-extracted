=encoding utf-8

=head1 NAME

App::Greple::tee - modul untuk mengganti teks yang cocok dengan hasil perintah eksternal

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Modul B<-Mtee> dari Greple mengirimkan bagian teks yang cocok dengan perintah filter yang diberikan, dan menggantinya dengan hasil perintah. Idenya berasal dari perintah yang disebut B<teip>. Ini seperti melewatkan sebagian data ke perintah filter eksternal.

Perintah filter mengikuti deklarasi modul (C<-Mtee>) dan diakhiri dengan dua tanda hubung (C<-->). Sebagai contoh, perintah berikutnya memanggil perintah C<tr> dengan argumen C<a-z A-Z> untuk kata yang cocok dalam data.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Perintah di atas mengubah semua kata yang cocok dari huruf kecil menjadi huruf besar. Sebenarnya contoh ini sendiri tidak begitu berguna karena B<greple> dapat melakukan hal yang sama secara lebih efektif dengan opsi B<--cm>.

Secara default, perintah ini dijalankan sebagai satu proses, dan semua data yang cocok dikirim ke proses tersebut secara bersamaan. Jika teks yang dicocokkan tidak diakhiri dengan baris baru, maka teks tersebut akan ditambahkan sebelum dan dihapus setelahnya. Data dipetakan baris demi baris, sehingga jumlah baris data input dan output harus sama.

Dengan menggunakan opsi B<--discrete>, perintah individual dipanggil untuk setiap bagian yang cocok. Anda dapat mengetahui perbedaannya dengan perintah berikut.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Baris data input dan output tidak harus identik ketika digunakan dengan opsi B<--discrete>.

=head1 OPTIONS

=over 7

=item B<--discrete>

Memanggil perintah baru satu per satu untuk setiap bagian yang cocok.

=back

=head1 WHY DO NOT USE TEIP

Pertama-tama, kapanpun Anda dapat melakukannya dengan perintah B<teip>, gunakanlah. Ini adalah alat yang sangat baik dan jauh lebih cepat daripada B<greple>.

Karena B<greple> didesain untuk memproses file dokumen, maka ia memiliki banyak fitur yang sesuai untuk itu, seperti kontrol area pencocokan. Mungkin ada baiknya menggunakan B<greple> untuk memanfaatkan fitur-fitur tersebut.

Selain itu, B<teip> tidak dapat menangani beberapa baris data sebagai satu kesatuan, sedangkan B<greple> dapat menjalankan perintah individual pada potongan data yang terdiri dari beberapa baris.

=head1 EXAMPLE

Perintah berikutnya akan menemukan blok teks di dalam dokumen gaya L<perlpod(1)> yang disertakan dalam file modul Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Anda dapat menerjemahkannya melalui layanan DeepL dengan menjalankan perintah di atas yang diyakinkan dengan modul B<-Mtee> yang memanggil perintah B<deepl> seperti ini:

    greple -Mtee deepl text --to JA - -- --discrete ...

Karena B<deepl> bekerja lebih baik untuk input satu baris, Anda dapat mengubah bagian perintah seperti ini:

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

Modul khusus L<App::Greple::xlate::deepl> lebih efektif untuk tujuan ini. Sebenarnya, petunjuk implementasi dari modul B<tee> berasal dari modul B<xlate>.

=head1 EXAMPLE 2

Perintah selanjutnya akan menemukan beberapa bagian yang menjorok ke dalam dokumen LICENSE.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
Anda dapat memformat ulang bagian ini dengan menggunakan modul B<tee> dengan perintah B<ansifold>:

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

L<App::Greple::tee>, L<https://github.com/kaz-utashiro/App-Greple-tee>

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
