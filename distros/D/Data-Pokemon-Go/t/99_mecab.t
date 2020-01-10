use strict;
use Test::More 0.98 tests => 1;
use Test::More::UTF8;

use lib './lib';
use Data::Pokemon::Go::Pokemon qw($All);
my $pg = Data::Pokemon::Go::Pokemon->new();

my @list = ();
my @regions_jp = qw( カントー ジョウト ホウエン シンオウ イッシュ アローラ ガラル);
foreach my $region (@regions_jp){
     push @list, [ $region, 1, 1, 1, '名詞', '固有名詞', '地域', '一般', '*', '*', $region, $region, $region ];
}

SKIP: {
    skip "Not local", 1 unless $ENV{'USER'} eq 'yuki.yoshida';

    foreach (@Data::Pokemon::Go::Pokemon::List){
        my $name = $pg->get_Pokemon_name( $All->{$_}, 'ja' );
        next if scalar @list and grep{ $_->[0] eq $name } @list;
         push @list, [ $name, 1, 1, 1, '名詞', '固有名詞', '人名', '一般', '*', '*', $name, $name, $name ];
    }

    require Text::CSV_XS;
    my $csv = Text::CSV_XS->new({ binary => 1, quote_char => undef });
    open my $fh, ">:encoding(utf8)", "share/MeCab.csv" or die "Couldn't open CSV: $!";
    map{ $csv->say( $fh, $_ ) } @list;
    close $fh or die "Couldn't write CSV: $!";

    is -e "share/MeCab.csv", 1, "Succeed to create share/MeCab.csv";        # 2
}

done_testing();
