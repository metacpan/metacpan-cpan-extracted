use strict;
use warnings;
use Test::More;
use utf8;

use MAB2::Parser::XML;
my $parser = MAB2::Parser::XML->new( './t/mab2.xml' );
isa_ok( $parser, 'MAB2::Parser::XML' );
my $record = $parser->next();
ok($record->{_id} eq '47918-4', 'record _id' );
is_deeply($record->{record}->[0], ['001', ' ', '_', '47918-4'], 'first field');
ok($parser->next()->{_id} eq '54251-9', 'next record');

$parser = MAB2::Parser::XML->new( q{<datensatz typ="h" status="n" mabVersion="M2.0" xmlns="http://www.ddb.de/professionell/mabxml/mabxml-1.xsd"><feld nr="001" ind=" ">47918-4</feld><feld nr="002" ind="a">19991118</feld><feld nr="003" ind=" ">20101112110154</feld><feld nr="004" ind=" ">20110211</feld><feld nr="016" ind=" ">550915044<tf/>DNB</feld><feld nr="025" ind="a">010420517</feld><feld nr="025" ind="o">85117764</feld><feld nr="025" ind="z">47918-4</feld><feld nr="026" ind=" ">ZDB47918-4</feld><feld nr="030" ind=" ">b|zucz|z|||37</feld><feld nr="036" ind="a">XA-DE</feld><feld nr="037" ind="b">ger</feld><feld nr="050" ind=" ">a|a|||||||||||</feld><feld nr="052" ind=" ">pmg||||ze||||z|</feld><feld nr="070" ind=" ">9001</feld><feld nr="070" ind="a">DNB</feld><feld nr="070" ind="b">1242</feld><feld nr="073" ind=" ">24,1</feld><feld nr="331" ind=" ">C't</feld><feld nr="335" ind=" ">Magazin für Computer-Technik</feld><feld nr="370" ind="a">Magazin für Computer-Technik</feld><feld nr="370" ind="a">Ct</feld><feld nr="405" ind=" ">Nachgewiesen 1983 -</feld><feld nr="406" ind="b"><uf code="j">1983</uf></feld><feld nr="410" ind=" ">Hannover</feld><feld nr="412" ind=" ">Heise</feld><feld nr="425" ind="b">1983</feld><feld nr="523" ind=" ">Ersch. im Abonnement auch zusammen mit d. CD-ROM c't-plus-rom. - Periodizität: 14-tägl.</feld><feld nr="527" ind="z">1307745-4           CD-ROM-Ausg. ---><tf/>C't-ROM</feld><feld nr="527" ind="z">1357019-5           Disketten-Ausg. ---><tf/>C't-Sammeldiskette</feld><feld nr="527" ind="z">1417097-8           CD-ROM-Ausg. ---><tf/>C't-plus-rom</feld><feld nr="527" ind="z">2031802-9           Online-Ausg. ---><tf/>C't</feld><feld nr="529" ind="z">2015583-9           Beil. 1997 u. 2000 - 2001 ---><tf/>C't / Freeware, Shareware</feld><feld nr="529" ind="z">1480287-9           Beil. 1998 - 1999 ---><tf/>C't / Shareware, Freeware</feld><feld nr="529" ind="z">2088571-4           Beil. ab 2002 ---><tf/>Software-Kollektion</feld><feld nr="529" ind="z">54251-9             Beil. ---><tf/>C't / Special</feld><feld nr="529" ind="z">2233486-5           Ab 2005 Beil. ---><tf/>C't / Ratgeber</feld><feld nr="529" ind="z">2495944-3           Ab 2009 Beil. ---><tf/>C't / Kompakt</feld><feld nr="529" ind="z">2490138-6           Ab 2009 Beil. ---><tf/>C't / Medien</feld><feld nr="529" ind="z">2470478-7           Ab 2009 Beil. ---><tf/>C't / Extra</feld><feld nr="529" ind="z">2564783-0           Ab 2009 Beil. ---><tf/>C't / Special / Digitale Fotografie</feld><feld nr="529" ind="z">2563469-0           Ab 2010 Beil. ---><tf/>C't digital photography</feld><feld nr="537" ind=" ">(üa/Z)</feld><feld nr="542" ind="a">ISSN 0724-8679</feld><feld nr="542" ind="z">: DM 6.00 (Einzelh.), DM 58.00 (jährl.)</feld><feld nr="545" ind="a"><uf code="a">ISSN 0724-8679 = C't</uf></feld><feld nr="574" ind=" ">84,A27,0450</feld><feld nr="673" ind="b">2013198-7           Hannover</feld><feld nr="700" ind=" ">|28<tf/>DNB</feld><feld nr="700" ind=" ">|004<tf/>DNB</feld><feld nr="700" ind="l">|820</feld><feld nr="700" ind=" ">|004<tf/>ZDB</feld><feld nr="700" ind=" ">|070<tf/>ZDB</feld><feld nr="700" ind="z">|795</feld><feld nr="700" ind="z">|100</feld><feld nr="700" ind="z">|z101</feld><feld nr="710" ind="a">Mikrocomputer</feld><feld nr="902" ind="s">  4115533-6           Personalcomputer</feld><feld nr="902" ind="s">  4067488-5           Zeitschrift</feld><feld nr="904" ind="a">DE-600<tf/>DE-600</feld><feld nr="907" ind="s">  4039206-5           Mikrocomputer</feld><feld nr="907" ind="s">  4067488-5           Zeitschrift</feld><feld nr="909" ind="a">DE-600<tf/>DE-600</feld><feld nr="912" ind="s">  4148885-4           Datentechnik</feld><feld nr="912" ind="s">  4067488-5           Zeitschrift</feld><feld nr="914" ind="a">DE-600<tf/>DE-600</feld><feld nr="917" ind="s">  4070083-5           Computer</feld><feld nr="917" ind="s">  4148885-4           Datentechnik</feld><feld nr="917" ind="f"> 1|Zeitschrift</feld><feld nr="919" ind="a">DE-600<tf/>DE-600</feld></datensatz>} );
isa_ok( $parser, 'MAB2::Parser::XML' );
$record = $parser->next();
ok($record->{_id} eq '47918-4', 'record _id' );
is_deeply($record->{record}->[0], ['001', ' ', '_', '47918-4'], 'first field');

use MAB2::Parser::RAW;
$parser = MAB2::Parser::RAW->new( './t/mab2.dat' );
isa_ok( $parser, 'MAB2::Parser::RAW' );
$record = $parser->next();
ok($record->{_id} eq '47918-4', 'record _id' );
ok($record->{record}->[0][3] eq '02020nM2.01200024      h', 'record leader' );
is_deeply($record->{record}->[1], ['001', ' ', '_', '47918-4'], 'first field');
ok($parser->next()->{_id} eq '54251-9', 'next record');

use MAB2::Parser::Disk;
$parser = MAB2::Parser::Disk->new( './t/mab2disk.dat' );
isa_ok( $parser, 'MAB2::Parser::Disk' );
$record = $parser->next();
ok($record->{_id} eq '47918-4', 'record _id' );
ok($record->{record}->[0][3] eq '02020nM2.01200024      h', 'record leader' );
is_deeply($record->{record}->[1], ['001', ' ', '_', '47918-4'], 'first field');
ok($parser->next()->{_id} eq '54251-9', 'next record');

done_testing;