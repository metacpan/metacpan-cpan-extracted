=head1 NAME

Acme::DonMartin - For programs that are easy to dictate over the telephone

=head1 VERSION

This document describes version 0.09 of Acme::DonMartin, released
2006-11-03.

=head1 SYNOPSIS

    use Acme::DonMartin;
    print "Hello world\n";

=head1 DESCRIPTION

Perl is a very difficult language to dictate over the phone. All
those pesky punctuation characters and gruesome glyphs make it very
laborious to speak out loud.

To compound the problem, most people can't even agree on what
something as basic as C<#> should be called. Some of the names for
it (although by no means exhaustive) include:

     pound, pound sign, number sign, flash, hash, sharp,
     grid, crosshatch, octothorpe, square, pig-pen, hex,
     tictactoe, scratchmark, crunch, thud, thump, splat.

(and if you say these last few out loud, I think you can begin to
see where this is going). And if you think that's bad, wait until
you hear some of the sillier symbols, like C<%>, C<&> and C<@>.

The first time you run a program under C<Acme::DonMartin>, nothing
happens, but your source code is magically transformed into Don
Martin cartoon sound effects. The code continues to work as before,
but now the above program looks something like this:

   #! /usr/local/bin/perl

   use Acme::DonMartin;
   gashlikt ahweeeeee dipada fliff gahak dapada zap thwizzik
   gahork tik gark dakdik gleet skroook skronk chomple dig
   klooonn sloople tik fling splork gleet cook chook wiz
   bombah boomer poong glong shuka spatz

The next time it is run, it will function as it did previously.

Now you can pick up the phone and dictate it to someone else
and they can type it in to a computer and run it with much
less chance of confusion or error.

This is also a security feature. It is expected that a government
official who has wire-tapped your line will be laughing too hard
to be able to recover the source code.

=cut

=head1 DIAGNOSTICS

=over 4

=item C<zownt thlip spoosh>

Something weird happened.

=back

=head1 BUGS

None known.

Please report any bugs or feature requests to
C<bug-acme-donmartin@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-DonMartin>.

=head1 SEE ALSO

L<Acme::Bleach>,
L<Acme::Buffy>,
L<Acme::Bushisms>,
L<Acme::Morse>,
L<Acme::Ook>,
L<Acme::Phlegethoth>,
L<Acme::Pony>,
L<Acme::Python>,
etc. etc. and of course
L<http://en.wikipedia.org/wiki/Don_Martin>

=head1 AUTHOR

Copyright (C) 2005-2006, David Landgren, all rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Acme::DonMartin;

use strict;
use vars qw/ $VERSION /;

$VERSION = 0.09;

use vars qw/ $thud $thuk $thump $thwa $thwak $thwat $thwip %thwip $thwit $thwock
$thwop %thwop @thwop/; $thwit=length$thwop[length($thwop[$thwat=$thwa=0])-length
($thwop[1])];$thwop=map{$thwat+=length}@thwop[do{$thwop+=length for@thwop[$thwit
..$thwit+length($thwop[6])];$thwop}..do{$thwop&=$thwa;$thwop+=length$_ for@thwop
[3..14.1592645];$thwop}];$thwa=($thwop>>length$thwop[5])<<($thwip=1<<1+1)+1;open
$thwit=undef,"+<$0" or die q=zownt thlip spoosh\n=;$thwa=chr$thwa;while(<$thwit>
){$thump.=$_;last if/^\s*use +@{[__PACKAGE__]}/}$thwak=$thump;$thud=<$thwit>;use
Compress::Zlib;$thud=~s/\s+$//;push @{$thwop{$thwip{$_}=$thwop++%$thwat}},qq{$_}
while $_=shift @thwop;$thuk=do{$thwat=$thwip^4; @thwop=split / /, $thud;!@thwop?
length($thwak):do{exists$thwip{$_}&&++$thwat for@thwop;$thwat!=@thwop}};$thwop=!
$thuk;if($thuk){for(split//,compress($thud.do{@thwop=();local$/=undef,<$thwit>})
){$thwock=$thwop{ord$_}[rand$thwip];if(length join($thwa,@thwop,$thwock)>$thwip{
q{thwak}}-$thwip{thwit}){$thwak.=join($thwa,@thwop).$/;@thwop=( );$thump=''}push
@thwop, $thwock} @thwop and do{seek $thwit, $thwop=$thwip-$thwip, $thwip=$thwop-
$thwop;print$thwit($thwak,$thump,join($thwa,@thwop),$/);seek$thwit,$thwip,$thwop
;}} else {$thwop=$thwip{qq{shpork}}-$thwip{q{shklink}};eval uncompress do{while(
<$thwit>){$thwock.=chr for map{$thwip{$_}}(/(s(?:h(?:k(?:l(?:i(?:z(?:z(?:ortch|i
tz)|(?:ort|i)ch)|k(?:sa)?|tza|nk)|o(?:(?:(?:rbbado)?r)?p|ort)|u(?:r(?:ch|tz|k)|n
k)|a(?:zitch|kle))|alo?ink|witz)?|l(?:o(?:o[kp]|r[kp]|ip)|i(?:k(?:le)?|pp)|ur[kp
]|ak)|p(?:l(?:(?:oi|e)p|iple)|i(?:kk|sh)le|o(?:oosh|rk))|a(?:[fk]|sh(?:wik)?|zza
tz|bamp)?|o(?:o(?:ka?|ga|o)|(?:mpa|ss)h)|n(?:i(?:kkle|p)|orkle)|i(?:f(?:fle)?|ka
?)|t(?:o(?:in|r)|i)k|u(?:ffle|ka)|muzorft|wika?)|p(?:l(?:a(?:z(?:[ai]tc|oos)h|p(
?:idy|ple)?|d(?:ish|unk)|sh(?:idy)?|t(?:ch)?|k)?|o(?:r(?:p(?:le)?|t(?:ch)?|k)|yd
oing|o?sh|it|p)|i(?:sh(?:idy|le)?|tch|p)|esh|urp)|r(?:o(?:in(?:g(?:(?:acho|doi)n
k)?|k)|wmmm|p)|i(?:z(?:aw|z)itz|t(?:sits|z))|a(?:zo)?t)|a(?:(?:(?:ma)?m)?p|z(?:o
osh|at)|sh(?:le)?|loosh|tz|k)?|o(?:o(?:sht?|f)|p(?:ple)?)|wa(?:p(?:po)?|ko|ng|t)
|u(?:kkonk|tz?|sh)|ma(?:mp?|p)|itza?)|k(?:r(?:o(?:i(?:nch|k)|n(?:ch|k)|o(?:ok|m)
|tch)|a(?:k(?:it)?|z[ai]tz|wk)|i(?:bble|cha?|tch|nk)|ee(?:k(?:le)?|ch|e)|uncha?)
|l(?:o(?:r(?:(?:tc|s)h|k)|shitty|osh|p)|i(?:(?:zzor|t)ch|(?:sh)?k)|u(?:k(?:le)?|
rk|sh)|azoncho|erch)|a(?:p(?:(?:lun|as)ch|roing)|z(?:ee|oo)ch)|w(?:a(?:(?:pp|k)o
)?|(?:ee|on|i)k)|n(?:i(?:(?:ff|k)le|tch)|osh))|w(?:i(?:[ft]|z(?:za[kt]|ap)|padda
|sh)|o(?:osh|rf))|c(?:h(?:l(?:oo[pt]|[ae]p|i[pt])|klurt)|reeeezt)|t(?:o(?:o(?:pf
t|ng|f)|ink)|roinggoink|amp)|l(?:o(?:(?:bb|op)le|tch)|ur[kp]|apth|ice)|n(?:i(?:k
ker|p)|a[pt]|uffle|ork)|i(?:t(?:tzle|z)?|zz(?:otz|le))|m(?:a(?:c?k|sh)|ek)|(?:s(
?:li|ss)|u)t|(?:azzik|ree)k|o(?:und|b))|g(?:a(?:s(?:h(?:k(?:litz(?:ka)?|utzga)|p
lutzga|likt|ook)|(?:m[ai]t|kroo)ch|p(?:l(?:oo|u)sh)?)|d(?:o(?:i?ng|on)|a(?:ff|ng
)|i(?:ff|nk))|r(?:(?:un)?k|rargh|oof)|z(?:o[ow]nt|ikka|ap)|l(?:oo(?:om|n)|ink)|h
(?:o(?:ff|rk)|ak)|(?:plo[nr]|c)?k|flor|mop)?|l(?:o(?:o(?:[kt]|(?:ch|d)le|p(?:le)
?)|r(?:[pt]|k(?:le)?|gle)|(?:ydoi|m)p|i(?:ng|p)|n [gt])|u(?:r(?:k(?:le)?|gle)|k(
?:k?le)?|t(?:ch)?|nk|p)|a(?:n(?:gadang|k)|(?:kk|rg)le|(?:din|w)k|p)|i(?:k(?:ity|
le|a)?|t(?:ch)?|nk|sh|p)|ee[pt])|r(?:o(?:wr(?:rooom)?|ink|on)|eedle|aw?k|unch|in
g)|i(?:(?:shkl[ou]r|kkadi)k|(?:gazi )? ng)|o(?:o(?:glooom|ma|sh)|rshle|yng|nk)|u
(?:(?:kgu|w)k|r(?:gle|n))|(?:hom|wa)p)|f(?:l(?:i(?:[kt]|f(?:f(?:l(?:aff|e))?)?|(
?:badi)?p|n[gk]|zaff)|o(?:[fk]|o(?:[mnt]|f(?:ity)?)|r[fk]|ba)|a(?:(?:fflif)?f|d(
?:at|ip)|badap|k)|eedle|u[kt])|w(?:i(?:zz(?:a(?:ch|p)|ish)?|sk(?:itty)?|p(?:ada)
?|t)|a(?:(?:bada|ddap)p|p(?:ada)?|s ?k|ch|m)|o(?:[fp]|o(?:sh|f))|ee[np]?|ump)|a(
?:g(?:roo(?:osh|n)|woosh|lork)|(?:sh(?:klor|un))?k|ba(?:dap)?|p(?:adda)?|roolana
|zzat)|i(?:zz(?:azzit|itz)|tz(?:rower)?|d(?:dit|ip)|ff|p)|u(?:sh(?:shklork)?|rsh
(?:glurk)?|nk(?:ada)?|mp|t)|o(?:o(?:[fnp]|sht?|woom|mp?)|ing|m?p|wm)|r(?:ugga|ac
k|oom|it)|err[ai]p|sssh)|k(?:a(?:ch(?:u(?:nka?|gh)|o(?:nk|o)|aah)|p(?:oooshshish
|la[km]|f)|sh(?:(?:in|oo)k|prit za)?|t(?:oo(?:n[gk]|f)|y)|z(?:a(?:sh|k)|ik|op)|(
?:doon|rra|w)k|l(?:loon|oong)|k(?:roosh|a)?|bo(?:omm|ff)|h(?:eeee|ak))?|l(?:i(?:
n(?:g(?:dinggoon)?|(?:kadin)?k)|(?:krun)?k)|o(?:o(?:n[gk]?|bada|onn)|n[gk]|ink|m
?p)|a(?:k(?:kle)?|n[gk]|dwak)|u(?:m(?:ble|p)|pada|n?k))|r(?:u(?:nch(?:le)?|gazun
ch)|a(?:k(?:kle)?|rkle|sh)|i(?:k(?:it)?|dit)|eek)|i(?:(?:ttoo)?ng|(?:kati)?k|pf)
|w(?:o(?:n[gk]|i?p)|ee[ek]|app)|o(?:o(?:kook|ng)|ff)|(?:erack|u)k)|t(?:h(?:o(?:o
(?:noonn|mp?|f)?|ip(?:oing)?|m?p|rk|t)|w(?:i(?:[pt]|zzik)|o(?:c?k|p)|a[kpt]?|uk)
|u(?:(?:gawun|nc)?k|(?:balu|m)p|rch|d)|l(?:u(?:ck|p)|i[kp]|oop)|a(?:p(?:loof)?|f
f|k)|h(?:h[hu]t|lorp)|i(?:koosh|z))|i(?:k(?:a(?:tik)?|kak?)?|n(?:g(?:alinga)?|k)
|p(?:pity)?)|o(?:o(?:[df]|w(?:it|oo)|n[gk]?|ong|mp)|n[gk]|ing|k)|w(?:ee(?:(?:dl)
?e|n)|o(?:[kp]|ng))|a(?:k(?:ka)?|gak|p)?|z(?:o?o|wa|i)ng|(?:r[ou]m|ff)p|e(?:eoo|
ar)|ubba)|p(?:l(?:o(?:o(?:[mp]|(?:badoo)?f|sh)|r(?:[fk]|tch)|bble|i?p|nk)|a(?:[f
km]|pf?)|i(?:pple|nk|f)|u(?:nk|rp|f))|i(?:t(?:t(?:w(?:ee|oo)n|oo(?:ie)?)|ooie)|n
[gk]|k)|a(?:[fkm]|t(?:w(?:eeee|ang))?|(?:da)?p)|w(?:o(?:(?:mp)?f|ing|k)|a(?:dak|
m)|een)|o(?:[kpw]|i(?:n[gk]|t)|ffisss|ong)|h(?:oo[mno ]|lakffa|elop|wam)|u(?:ff(
?:le|a)?|cka|tt)|f(?:fft|lap)|rawk|sssh)|b(?:l(?:o(?:o(?:[fp]|ma?|oot)|r[fpt]|bb
le|it|nk|p)|a(?:p(?:ple)?|mp?|tch)|i(?:[bf]|(?:di)?t|nk)|ee(?:ble|gh|p)|u(?:[bt]
|ka))|r(?:ee(?:(?:bee)?p|(?:dee)?t)|(?:(?:ood)?oo|nng)t|a(?:[kp]|vo)|rrapp|ing)|
o(?:o(?:m(?:er|a)?|ng)|mbah|rfft|il|ng)|a(?:[kmp]|r(?:ramm|f)|hoo|ng|sh)?|(?:ee[
dy]oo|wee)p|z(?:own|z)t|u(?:mp|r)|ing)|d(?:o(?:o(?:(?:(?:tbwee)?|o)t|b(?:ad)?a|m
[ap]?|n[kt]|dle|p)|i(?:[pt]|nk)|kka|ng?|mp|w)|a(?:k(?:k(?:a(?:dak)?|itydak)|dik)
?|b(?:omp|wak|a)|p(?:ad?da)?|ng)?|i(?:[gt]|n(?:g(?:aling?a)?|k)?|k(?:ka)?|pad?da
|mpah)|u(?:(?:bb|gg)a|rp)|r(?:ipple|oot)|ee(?:be|p))|c(?:h(?:a(?:k(?:(?:l[ai]|un
)k|a))?|o(?:mp(?:ity|le)|[no]k|p)|i(?:ka(?:klak)?|[mr]?p)|u(?:kkunk|nka?|ga|h)|e
e(?:om)?p)|l(?:a(?:tt(?:er|a)|n[gk]|ck|ka|p)|i(?:[cn]? k|p)|o(?:i?nk|mp)|unk)|r(
?:u(?:nch(?:le)?|gazunch)|ash)|a[kw]|ook)|z(?:i(?:k(?:k(?:ik|a)|a)?|z(?:(?:azi|z
a)k)?|(?:di)?t|ngo|ch|p)|o(?:o(?:[ot]|ka)|w(?:nt|m)|ck|t)|a(?:[pt]|(?:zi)?k|chit
ty)|w(?:ee(?:[nt]|ch)|[io]t)|(?:glu|ni)k|litz|unch|eem)|w(?:h(?:o(?:osh|mp)|i(?:
rr|sk)|a[kp]|eeah)|i(?:nk(?:ity)?|z)|a(?:[kp]|mp?)|ee(?:oooo)?|unk(?:ada)?|on[gk
])|y(?:a(?:(?:a(?:ug|c)|hha)h|(?:gga)?k|rgh?)|u(?:k(?:kle)?|g)|i(?:ng|p)|eech)|h
(?:u(?:ff(?:le|a)?|sh(?:le)?|m)|a(?:k(?:kle)?|ah|r)?|o(?:nk|ot)?|ee|ic|m)|r(?:o(
?:om(?:ba)?|w[mr]|r)|umb(?:oom|le)|r(?:rrrr|ip)|a(?:wg)?h|ipf?)|a(?:r(?:g(?:le|h
)?|argh)|h(?:weeeeee|h)|a(?:ak|rh)|ling|ooga|c?k|gh)|o(?:o(?:[fht]|o(?:[hm]|kk)|
n[kt]|ga|mp)|g(?:gock|h)|nnnnnghk)|v(?:o(?:o(?:fen|m)|w[mn])|r(?:oo(?:o?n|m)|een
)|ar?room)|u(?:m(?:p[fh]|ble)|(?:nkli)?k|[lr]p|gh)|m(?:a(?:bbit|m?p)|impah|uffle
|mm)|e(?:c(?:ch|k)|ech)|l(?:aflatch|eddle)|(?:q[uw]ac|no)k|jugarum|inkle) /xg )}
join(q..=>map{chr$thwip{$_}}split chr$thwop,$thud).$thwock}}exit;BEGIN{@thwop=do
{do{qw{ phoom doot chunk broot durp klank ho glakkle glukkle kazik splatch  glup
clip chika pak ping  whap  rumboom  kookook  flink  dokka  pwam  pwompf  chaklak
shklizzitz phoon gazoont puffa blapple tzong plapf pucka  twok  oooh  ging  spla
sputz dikka rowm oookk dooba tffp  skrunch  zap  thaploof  fwapada  blorf  tromp
klumble wamp mimpah kloink klump foosht cloink screeeezt kloong spamp  zak  flik
dripple sklurk goyng krak shkwitz gadang thwak fwop pop oomp  ploip  thoip  gark
thud flip doom zeem kachugh wunkada flof fashunk chomple shlork breep skloshitty
thluck cha  broodoot  clonk  skaproing  greedle  tink  bravo  fursh  hak  splort
fashklork fwabadap fwump thhhut slurp  spwat  glap  aling  trump  king  chompity
stoopft shpliple tika tubba  thwat  splazoosh  groink  clatta  tikka  glangadang
muffle gurgle sknosh shika kloon gadoing zooo blit crunchle tok  foop  pat  vowm
glork cak har clang toomp splazatch sklik glit dak sob phwam kaboff dink yug bam
spa splazitch boong spitz yargh fut klunk blooma kik skrazatz ding ferrip  glank
pittween zooka barf sproingachonk hm spazoosh clank pffft spritsits  bluka  clap
sklitch splop thwa thop pween umph chukkunk yaaugh fizzitz chook toon kaplam shk
schlip thot ooom phooo sprat thwok  urp  shkloort  kapf  flaffliff  fop  tikatik
fagwoosh chakunk shtork splapidy dabwak thaff cheep ecch gahak grawk wam shuffle
breebeep zika paf dakkadak hoot pink schlap fwizz spitza skronk katoonk  blobble
gaplork skrotch breedeet frack googlooom thwip klop kipf spwappo zit aarh  toing
shossh kachunka doip chuh vrooon domp skruncha fapadda  thoipoing  clik  sknitch
slurk fwoof zowm tooong pittwoon rah snuffle skribble spashle slotch thwit  snap
floofity skrak shlook kashook caw plif wong yaggak skroik  kikatik  tagak  glook
kweek faba bleegh blort glukle klakkle fwee gloople  doodle  claka  blidit  voom
fween fomp chuga ugh pluf sha vown sklerch putt fitzrower gloochle  gahoff  kawk
pik fip tippity rrrrrr bur shazzatz patwang foosh fwak  hum  splip  shlik  kwoip
kachoo fleedle ploosh rip skwik thoom frugga zwit  gishklork  sprop  oonk  floof
doit fabadap tweee clunk dong  gack  pwadak  rrip  shooka  toowoo  beedoop  room
sklishk fling funkada glawk phlakffa wheeah zingo thwock aooga  shnorkle  katoof
dingalina click spwang stamp sworf spmamp kloonk puffle vroom nok gloing skricha
thomp fush sploit bang thork varroom bloof dipadda shaf  tip  shklizortch  zazik
splash galink poong quack gadoon  droot  tikkak  zweech  chaka  smek  krugazunch
fwoosh splat gashlikt shklurtz fazzat booma shklorbbadorp floot  groon  krunchle
sit kaheeee dapadda  shklurk  puff  kluk  blonk  zachitty  skwako  huffle  zlitz
gasmitch plork mamp fwizzach shash toowit gadiff brnngt  tzing  tweedle  gashook
shkalink breet glorp chaklik brap kling pflap blut pam  gloydoip  snikker  glont
glomp shploip snork sklork skapasch smack thunck kweee bak kerackk zoot skniffle
inkle blorp cheeomp gaflor honk shpishle bleeble klonk swipadda  oof  gashkutzga
glik rawgh shlorp kwapp glutch plam zidit thiz ooga kwop  furshglurk  gooma  fak
shtik gloodle clack skroook tik slice skreek gak kazop guwk glut  gukguk  shklik
ting skreech gorshle  sprizzitz  ulp  gluk  splesh  fwof  doonk  glurgle  hushle
gaskrooch sknikle gazap slobble gazownt dingalinga bweep glink wiz  poit  pwoing
gasmatch toof tzwang yahhah shklakle gadink fowm shklazitch gikkadik  growrrooom
glort sut splap splish zizzak klik  thloop  spwap  gashplutzga  yukkle  pittooie
poing spoosht chimp yaach whak plap  chop  skrakit  whirr  shuka  fwask  fwizzap
skweek ploobadoof funk bump fladip glong psssh kalloon fwit bloit dugga  kaloong
dimpah bash splortch glikity  flut  kashpritza  shklorp  gasp  hic  gamop  flork
stroinggoink din skwappo  shooo  crugazunch  glika  fliff  spatz  zikkik  dipada
splitch wink whoosh sloople zot shklop bahoo shloop sklop  zownt  thhlorp  dakka
zunch bzzt bring shmuzorft mabbit pittoo  thoof  shkaloink  thlip  boil  kladwak
spukkonk blam vreen garunk ferrap sprazot blink  sittzle  barramm  spoosh  plurp
swizzat huff boom thwizzik haah cook goosh kachunk zgluk  fwiskitty  znik  klink
schlit plortch shiffle ta tingalinga doop swit  skreee  pitooie  floom  gasplush
klak zwot jugarum thoo umble zik argh dabomp glurk thlup spush  sproing  glurkle
klong foom fwap foon kapoooshshish shashwik ying spritz sklukle blop faglork zat
klingdinggoon shlikle daba glorgle snat bing sklizzorch kreek  sproink  poffisss
skrich zizazik hush phelop ak glikle mmm zip spazat yarg splurp fap schklurt wak
skazeech krik map kwong ploof splak sploosh kridit shik prawk chirp rumble clomp
gloot fluk whisk fump flok wap skluk yip pwok beeyoop fagroon fwam ghomp  grunch
fwip gring spladunk zock skwonk  chikaklak  bap  shpikkle  uk  klupada  splapple
spamamp sploydoing spak gurn stoink kachonk fiff skwa gasploosh agh  froom  thap
chonk gleet spwako shtoink dapada dakdik laflatch  shplep  kazak  doobada  foomp
toonk wee thhhht klang tween flif  fwipada  thuk  thubalup  zweet  plop  brrrapp
skazooch fwach shompah plunk glitch  glargle  dakkitydak  fitz  zich  dubba  ogh
thugawunk deep splishidy floba spoof garrargh slapth krunch unklik kazash roomba
shif galoon oggock fwisk karrak thwop shwika schloop  blif  doomp  boomer  sslit
bombah varoom voofen kaplak fiddit kwonk dik vroon  foowoom  gloip  leddle  thak
gloop flak skreekle plipple plorf shwik skritch krash kash gashklitz poink smash
dang shlurp gishklurk splorp thoomp fwizzish glip  splashidy  kloobada  shkliksa
shnip bloooot whomp sound dig  arg  deebe  argle  spopple  zikka  oot  ga  shlak
kakroosh sklorsh spmap dit onnnnnghk bloop pow  plak  rowr  skrawk  thwuk  yeech
fidip shlipp bong skrink spash shklitza blamp ziz foing  smak  kadoonk  spladish
fagrooosh dap sklush plink  thlik  ooh  kak  gahork  pwof  bzownt  shklunk  foof
sproingdoink arargh stoong swif ripf shlurk thump schloot swish  gaplonk  swizap
kaboomm hee floon eech dootbweet  plaf  oont  fladat  yak  shook  plobble  sreek
shpooosh kahak sizzotz klikrunk tak thwap krikit faroolana chunka koong ka dooot
shklurch shak chip growr shklizzortch flibadip klinkadink twong borfft snip spap
skroinch shklink katy sprowmmm sizzle da splork  kuk  skrazitz  clatter  skronch
blib flabadap stoof gladink schlep fushshklork winkity ror gwap teeoo eck shloip
ploop aaak ahweeeeee dow  wonk  blatch  sazzikk  umpf  glunk  tood  shpork  tonk
fwaddapp koff ack spmam  glorkle  zween  sklazoncho  dooma  toong  crash  shooga
gazikka doink florf ploom garoof kittoong tzoong tong  gashklitzka  fliffle  tap
gleep spop weeoooo splorple ahh shklizich twop  gigazing  patweeee  huffa  qwack
splosh doont fsssh fizzazzit gadaff plonk katoong pok klooonn flifflaff yuk  don
sprizawitz krarkle flizaff  gonk  flaf  skroom  gadong  klomp  clink  padap  pap
shnikkle ba spaloosh fweep crunch blub sput brak  thikoosh  swizzak  kaka  bleep
grak kachaah hakkle blap takka galooom bloom ha swoosh sitz sssst  kashink  wunk
skaplunch frit skloosh thurch krakkle glish shabamp tear sklortch thoonoonn flit
splishle}}}}$thwit=


                'This module is dedicated to Don Martin'
                                   ;
                               1931-2000



