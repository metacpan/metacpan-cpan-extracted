use strict;
use Test;
BEGIN { plan tests => 15 }
use Config::Natural;
use File::Spec;
Config::Natural->options(-quiet => 1);
my $obj = new Config::Natural;

$obj->read_source(File::Spec->catfile('t', 'eva', 'weapons.txt'));
$obj->read_source(\*DATA);

# check that root-level params are correctly appended
ok( $obj->param('101'), "Everything that has a beginning has an end"    );  #01

# check that params inside lists are correctly appended
ok( $obj->param('i18n-title')->[0]{'lang'}, 'en'                        );  #02
ok( $obj->param('i18n-title')->[0]{'title'}, 'Neon Genesis Evangelion'  );  #03
ok( $obj->param('i18n-title')->[1]{'lang'}, 'ja'                        );  #04
ok( $obj->param('i18n-title')->[1]{'title'}, 'Shin Seiki Evangelion'    );  #05

# check that array-params are correctly appended
my $weapons = -1;
my @expected_weapons = (
        'progressive knife', 'sonic glaive', 'smash hook',
        'palet riffle', 'rocket launcher', 'positron gun',
        'N2 bomb', 'Longinus spear'
);

$weapons = $obj->param('weapons');
ok( ref $weapons, 'ARRAY'                      );  #06
ok( scalar @$weapons, scalar @expected_weapons );  #07
for my $i (0..$#expected_weapons) {                #08-15
    ok( $weapons->[$i], $expected_weapons[$i] )
}


__END__

101 = Everything 

i18n-title {
  lang = en
  title = Neon 
  title += Genesis 
  title + = Evangelion
}

101 += that has a beginning 

i18n-title {
  lang = ja
  title = Shin 
  title += Seiki 
  title + = Evangelion
}

weapons += (
  Longinus spear
)

101 += has an end
