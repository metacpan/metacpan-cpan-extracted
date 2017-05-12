use Test::More tests => 2071;
use Test::CGI::Untaint;
use Locale::Constants;

use strict;
use warnings;

use YAML;
use Data::Dumper;

use CGI::Untaint::country;

my $CODES     = [];
my $COUNTRIES = [];

load_data();

#                  in   out    handler
# is_extractable("Red","red","validcolor");

#
# unextractable( $in, $handler );

=head1 SYNOPSIS

    use CGI::Untaint;
    my $handler = CGI::Untaint->new($q->Vars);

                                                                             # submit:
    $country_name  = $handler->extract(-as_countryname     => 'country');    # name e.g. 'United Kingdom'
    $country_code2 = $handler->extract(-as_countrycode     => 'country');    # 2 letter code e.g. 'uk'
    $country_code2 = $handler->extract(-as_country         => 'country');    # 2 letter code
    $country_code3 = $handler->extract(-as_countrycode3    => 'country');    # 3 letter code e.g. 'gbr'
    $country_code2 = $handler->extract(-as_to_countrycode  => 'country');    # name
    $country_code3 = $handler->extract(-as_to_countrycode3 => 'country');    # name
    $country_codenum = $handler->extract(-as_countrynumber => 'country');    # numeric code e.g. '064'
    $country_codenum = $handler->extract(-as_to_countrynumber => 'country'); # name

=cut

foreach my $country_name ( keys %{ $COUNTRIES->[LOCALE_CODE_ALPHA_2] } )
{
    # name in, name out
    is_extractable( $country_name, 
                    $country_name, 
                    'countryname',
                    );
    # name in, code2 out
    is_extractable( $country_name, 
                    $COUNTRIES->[LOCALE_CODE_ALPHA_2]->{ $country_name }, 
                    'to_countrycode',
                    );
    # name in, code3 out
    is_extractable( $country_name, 
                    $COUNTRIES->[LOCALE_CODE_ALPHA_3]->{ $country_name }, 
                    'to_countrycode3',
                    );
    # name in, numeric code out
    is_extractable( $country_name, 
                    $COUNTRIES->[LOCALE_CODE_NUMERIC]->{ $country_name }, 
                    'to_countrynumber',
                    );
}    

unextractable( 'nowhere', 'countryname' );
unextractable( 'nowhere', 'to_countrycode' );
unextractable( 'nowhere', 'to_countrycode3' );
unextractable( 'nowhere', 'to_countrynumber' );

foreach my $code2 ( keys %{ $CODES->[LOCALE_CODE_ALPHA_2] } )
{
    # code2 in, code2 out
    is_extractable( $code2, $code2, 'country' );
    is_extractable( $code2, $code2, 'countrycode' ); # same thing
}    
    
unextractable( 'zz', 'country' );
unextractable( 'zz', 'countrycode' );

foreach my $code3 ( keys %{ $CODES->[LOCALE_CODE_ALPHA_3] } )
{
    # code3 in, code3 out
    is_extractable( $code3, $code3, 'countrycode3' );
}    
    
unextractable( '999',  'countrycode3' );
unextractable( 'zzz',  'countrycode3' );
unextractable( '1234', 'countrycode3' );
unextractable( '0000', 'countrycode3' );
unextractable( 'gb',   'countrycode3' );
unextractable( 'us',   'countrycode3' );
unextractable( 'France',  'countrycode3' );

foreach my $codenum ( keys %{ $CODES->[LOCALE_CODE_NUMERIC] } )
{
    # codenum in, codenum out
    is_extractable( $codenum, $codenum, 'countrynumber' );
}    
    
unextractable( '999',  'countrynumber' );
unextractable( '1234', 'countrynumber' );
unextractable( '0000', 'countrynumber' );
unextractable( 'gb',   'countrynumber' );
unextractable( 'us',   'countrynumber' );
unextractable( 'France',  'countrynumber' );

#diag( "Tested CGI::Untaint::country $CGI::Untaint::country::VERSION" );
    

# warn Dumper( $CODES, $COUNTRIES );


# initialisation code - stuff the DATA into $CODES and $COUNTRIES
# (stolen from Locale::Country)
#=======================================================================
sub load_data {
    my   ($alpha2, $alpha3, $numeric);
    my   ($country, @countries);
    local $_;


    while (<DATA>)
    {
        next unless /\S/;
        chop;
        ($alpha2, $alpha3, $numeric, @countries) = split(/:/, $_);

        $CODES->[LOCALE_CODE_ALPHA_2]->{$alpha2} = $countries[0];
	foreach $country (@countries)
	{
	    $COUNTRIES->[LOCALE_CODE_ALPHA_2]->{"\L$country"} = $alpha2;
	}

	if ($alpha3)
	{
            $CODES->[LOCALE_CODE_ALPHA_3]->{$alpha3} = $countries[0];
	    foreach $country (@countries)
	    {
		$COUNTRIES->[LOCALE_CODE_ALPHA_3]->{"\L$country"} = $alpha3;
	    }
	}

	if ($numeric)
	{
            $CODES->[LOCALE_CODE_NUMERIC]->{$numeric} = $countries[0];
	    foreach $country (@countries)
	    {
		$COUNTRIES->[LOCALE_CODE_NUMERIC]->{"\L$country"} = $numeric;
	    }
	}

    }

    close(DATA);
}


__DATA__
ad:and:020:Andorra
ae:are:784:United Arab Emirates
af:afg:004:Afghanistan
ag:atg:028:Antigua and Barbuda
ai:aia:660:Anguilla
al:alb:008:Albania
am:arm:051:Armenia
an:ant:530:Netherlands Antilles
ao:ago:024:Angola
aq:ata:010:Antarctica
ar:arg:032:Argentina
as:asm:016:American Samoa
at:aut:040:Austria
au:aus:036:Australia
aw:abw:533:Aruba
ax:ala:248:Aland Islands
az:aze:031:Azerbaijan
ba:bih:070:Bosnia and Herzegovina
bb:brb:052:Barbados
bd:bgd:050:Bangladesh
be:bel:056:Belgium
bf:bfa:854:Burkina Faso
bg:bgr:100:Bulgaria
bh:bhr:048:Bahrain
bi:bdi:108:Burundi
bj:ben:204:Benin
bm:bmu:060:Bermuda
bn:brn:096:Brunei Darussalam
bo:bol:068:Bolivia
br:bra:076:Brazil
bs:bhs:044:Bahamas
bt:btn:064:Bhutan
bv:bvt:074:Bouvet Island
bw:bwa:072:Botswana
by:blr:112:Belarus
bz:blz:084:Belize
ca:can:124:Canada
cc:cck:166:Cocos (Keeling) Islands
cd:cod:180:Congo, The Democratic Republic of the:Zaire:Congo, Democratic Republic of the
cf:caf:140:Central African Republic
cg:cog:178:Congo:Congo, Republic of the
ch:che:756:Switzerland
ci:civ:384:Cote D'Ivoire
ck:cok:184:Cook Islands
cl:chl:152:Chile
cm:cmr:120:Cameroon
cn:chn:156:China
co:col:170:Colombia
cr:cri:188:Costa Rica
cs:scg:891:Serbia and Montenegro:Yugoslavia
cu:cub:192:Cuba
cv:cpv:132:Cape Verde
cx:cxr:162:Christmas Island
cy:cyp:196:Cyprus
cz:cze:203:Czech Republic
de:deu:276:Germany
dj:dji:262:Djibouti
dk:dnk:208:Denmark
dm:dma:212:Dominica
do:dom:214:Dominican Republic
dz:dza:012:Algeria
ec:ecu:218:Ecuador
ee:est:233:Estonia
eg:egy:818:Egypt
eh:esh:732:Western Sahara
er:eri:232:Eritrea
es:esp:724:Spain
et:eth:231:Ethiopia
fi:fin:246:Finland
fj:fji:242:Fiji
fk:flk:238:Falkland Islands (Malvinas):Falkland Islands (Islas Malvinas)
fm:fsm:583:Micronesia, Federated States of
fo:fro:234:Faroe Islands
fr:fra:250:France
fx:fxx:249:France, Metropolitan
ga:gab:266:Gabon
gb:gbr:826:United Kingdom:Great Britain
gd:grd:308:Grenada
ge:geo:268:Georgia
gf:guf:254:French Guiana
gh:gha:288:Ghana
gi:gib:292:Gibraltar
gl:grl:304:Greenland
gm:gmb:270:Gambia
gn:gin:324:Guinea
gp:glp:312:Guadeloupe
gq:gnq:226:Equatorial Guinea
gr:grc:300:Greece
gs:sgs:239:South Georgia and the South Sandwich Islands
gt:gtm:320:Guatemala
gu:gum:316:Guam
gw:gnb:624:Guinea-Bissau
gy:guy:328:Guyana
hk:hkg:344:Hong Kong
hm:hmd:334:Heard Island and McDonald Islands
hn:hnd:340:Honduras
hr:hrv:191:Croatia
ht:hti:332:Haiti
hu:hun:348:Hungary
id:idn:360:Indonesia
ie:irl:372:Ireland
il:isr:376:Israel
in:ind:356:India
io:iot:086:British Indian Ocean Territory
iq:irq:368:Iraq
ir:irn:364:Iran, Islamic Republic of:Iran
is:isl:352:Iceland
it:ita:380:Italy
jm:jam:388:Jamaica
jo:jor:400:Jordan
jp:jpn:392:Japan
ke:ken:404:Kenya
kg:kgz:417:Kyrgyzstan
kh:khm:116:Cambodia
ki:kir:296:Kiribati
km:com:174:Comoros
kn:kna:659:Saint Kitts and Nevis
kp:prk:408:Korea, Democratic People's Republic of:Korea, North:North Korea
kr:kor:410:Korea, Republic of:Korea, South:South Korea
kw:kwt:414:Kuwait
ky:cym:136:Cayman Islands
kz:kaz:398:Kazakhstan:Kazakstan
la:lao:418:Lao People's Democratic Republic
lb:lbn:422:Lebanon
lc:lca:662:Saint Lucia
li:lie:438:Liechtenstein
lk:lka:144:Sri Lanka
lr:lbr:430:Liberia
ls:lso:426:Lesotho
lt:ltu:440:Lithuania
lu:lux:442:Luxembourg
lv:lva:428:Latvia
ly:lby:434:Libyan Arab Jamahiriya:Libya
ma:mar:504:Morocco
mc:mco:492:Monaco
md:mda:498:Moldova, Republic of:Moldova
mg:mdg:450:Madagascar
mh:mhl:584:Marshall Islands
mk:mkd:807:Macedonia, the Former Yugoslav Republic of:Macedonia, Former Yugoslav Republic of:Macedonia
ml:mli:466:Mali
mm:mmr:104:Myanmar:Burma
mn:mng:496:Mongolia
mo:mac:446:Macao:Macau
mp:mnp:580:Northern Mariana Islands
mq:mtq:474:Martinique
mr:mrt:478:Mauritania
ms:msr:500:Montserrat
mt:mlt:470:Malta
mu:mus:480:Mauritius
mv:mdv:462:Maldives
mw:mwi:454:Malawi
mx:mex:484:Mexico
my:mys:458:Malaysia
mz:moz:508:Mozambique
na:nam:516:Namibia
nc:ncl:540:New Caledonia
ne:ner:562:Niger
nf:nfk:574:Norfolk Island
ng:nga:566:Nigeria
ni:nic:558:Nicaragua
nl:nld:528:Netherlands
no:nor:578:Norway
np:npl:524:Nepal
nr:nru:520:Nauru
nu:niu:570:Niue
nz:nzl:554:New Zealand
om:omn:512:Oman
pa:pan:591:Panama
pe:per:604:Peru
pf:pyf:258:French Polynesia
pg:png:598:Papua New Guinea
ph:phl:608:Philippines
pk:pak:586:Pakistan
pl:pol:616:Poland
pm:spm:666:Saint Pierre and Miquelon
pn:pcn:612:Pitcairn:Pitcairn Island
pr:pri:630:Puerto Rico
ps:pse:275:Palestinian Territory, Occupied
pt:prt:620:Portugal
pw:plw:585:Palau
py:pry:600:Paraguay
qa:qat:634:Qatar
re:reu:638:Reunion
ro:rou:642:Romania
ru:rus:643:Russian Federation:Russia
rw:rwa:646:Rwanda
sa:sau:682:Saudi Arabia
sb:slb:090:Solomon Islands
sc:syc:690:Seychelles
sd:sdn:736:Sudan
se:swe:752:Sweden
sg:sgp:702:Singapore
sh:shn:654:Saint Helena
si:svn:705:Slovenia
sj:sjm:744:Svalbard and Jan Mayen:Jan Mayen:Svalbard
sk:svk:703:Slovakia
sl:sle:694:Sierra Leone
sm:smr:674:San Marino
sn:sen:686:Senegal
so:som:706:Somalia
sr:sur:740:Suriname
st:stp:678:Sao Tome and Principe
sv:slv:222:El Salvador
sy:syr:760:Syrian Arab Republic:Syria
sz:swz:748:Swaziland
tc:tca:796:Turks and Caicos Islands
td:tcd:148:Chad
tf:atf:260:French Southern Territories:French Southern and Antarctic Lands
tg:tgo:768:Togo
th:tha:764:Thailand
tj:tjk:762:Tajikistan
tk:tkl:772:Tokelau
tm:tkm:795:Turkmenistan
tn:tun:788:Tunisia
to:ton:776:Tonga
tl:tls:626:Timor-Leste:East Timor
tr:tur:792:Turkey
tt:tto:780:Trinidad and Tobago
tv:tuv:798:Tuvalu
tw:twn:158:Taiwan, Province of China:Taiwan
tz:tza:834:Tanzania, United Republic of:Tanzania
ua:ukr:804:Ukraine
ug:uga:800:Uganda
um:umi:581:United States Minor Outlying Islands
us:usa:840:United States:USA:United States of America
uy:ury:858:Uruguay
uz:uzb:860:Uzbekistan
va:vat:336:Holy See (Vatican City State):Holy See (Vatican City)
vc:vct:670:Saint Vincent and the Grenadines
ve:ven:862:Venezuela
vg:vgb:092:Virgin Islands, British:British Virgin Islands
vi:vir:850:Virgin Islands, U.S.
vn:vnm:704:Vietnam
vu:vut:548:Vanuatu
wf:wlf:876:Wallis and Futuna
ws:wsm:882:Samoa
ye:yem:887:Yemen
yt:myt:175:Mayotte
za:zaf:710:South Africa
zm:zmb:894:Zambia
zw:zwe:716:Zimbabwe
