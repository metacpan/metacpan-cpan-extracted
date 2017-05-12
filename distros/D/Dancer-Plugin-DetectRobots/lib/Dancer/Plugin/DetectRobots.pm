package Dancer::Plugin::DetectRobots;
{
  $Dancer::Plugin::DetectRobots::VERSION = '0.6';
}

use strict;
use warnings;

use Regexp::Assemble qw();

use Dancer ':syntax';
use Dancer::Plugin;

my $conf = plugin_setting;
my $key  = $conf->{session_key} || 'robot_client';
my $type = $conf->{type} || 'BASIC';

my $reList = _read_list();
my $basic = _assemble( $reList, 'basic' );
my $extended = _assemble( $reList, 'extended' );
my $generic = _assemble( $reList, 'generic' );

register is_robot => sub {
	my $ua = request->user_agent;
	my $value = "";
	if( session( $key ) ) {
		$value = session $key;
	}
	if( $value eq "NO") {
		return 0;
	}
	elsif( $value eq "BASIC") {
		return 1;
	}
	elsif( $value eq "EXTENDED") {
		return 1;
	}
	elsif( $value eq "GENERIC") {
		return 1;
	}

	my $rv = 0;

	if ( $type eq "BASIC" ) {
		if ( $ua =~ $basic ) {
			session $key => $type;
			$rv = 1;
		}
		else {
			session $key => "NO";
		}
	}
	elsif ( $type eq "EXTENDED" ) {
		if ( $ua =~ $basic ) {
			session $key => $type;
			$rv = 1;
		}
		elsif ( $ua =~ $extended ) {
			session $key => $type;
			$rv = 1;
		}
		else {
			session $key => "NO";
		}
	}
	elsif ( $type eq "GENERIC" ) {
		if ( $ua =~ $generic ) {
			session $key => $type;
			$rv = 1;
		}
		else {
			session $key => "NO";
		}
	}
	return $rv;
};

sub _assemble {
	my ( $list, $use_type ) = @_;

	my $ra = Regexp::Assemble->new( flags => 'i' );
	foreach my $r ( @{ $list->{$use_type} } ) {
		$ra->add($r);
	}

	return $ra->re;
}

sub _read_list {
	my $bots = { basic => [], extended => [], generic => [], };
	my $currentType = 'basic';

	while (<Dancer::Plugin::DetectRobots::DATA>) {
		chomp;
		next unless $_;
		$currentType = 'extended' if /\A##\s+EXTENDED/;
		$currentType = 'generic'  if /\A##\s+GENERIC/;

		push @{ $bots->{$currentType} }, $_;
	}

	return $bots;
}

register_plugin;

1;

=pod

=head1 NAME

Dancer::Plugin::DetectRobots - Dancer plugin to determine if the user is a robot

=head1 VERSION

version 0.6

=head1 DESCRIPTION

A plugin for Dancer applications providing a keyword, is_robot,
which tests request->user_agent and returns 1 if the user_agent
appears to be a robot.

To use, simply call is_robot whenever/wherever you would like to 
know if the user is a bot or a human.  For example, if you would 
like to skip logging for bots

	if( ! is_robot ) {
		log_message("your log message");
	}

The plugin has been written to be as efficient as possible.  The
list of Robot UserAgent strings is only matched against request->user_agent
once per session.

This is done by storing its results in a session variable so a session
engine must be enabled.  Session::Cookie would be a poor choice since
the optimization will be lost when dealing with a search engine or robot.

The first call to is_robot in a session checks to see if the session 
variable has been set, if if it has, it returns 0 or 1 based upon the 
session variable.

By default the session variable key is "robot_client"

The check is done against the list of UserAgent strings used
by AWStats.  There are three levels of testing, BASIC which matches
AWStats LevelForRobotsDetection=1, EXTENDED which matches 
LevelForRobotsDetection=2 and GENERIC which is a very lax test.

By default the level is set to BASIC

You can change these settings. See L<CONFIGURATION>

=head1 NAME

Dancer::Plugin::DetectRobots - A plugin to detect if the HTTP_USER_AGENT
matches a known search engine or robot string.

=head1 SYNOPSYS

In your configuration, make sure you have session configured. Of course you can
use any session engine.

  session: "simple"

In your Dancer App

  use Dancer;
  use Dancer::Plugin::DetectRobots;

  if( is_robot ) {
	...
  }
  else {
	processing goes here
	...
  }

=head1 METHODS

=head2 is_robot

  # returns 1 if the HTTP_USER_AGENT as returned by request->user_agent
  # matches one of the strings used by AWStats to detect search engines and
  # bots

  if ( is_robot ) {
	..
  }

=head1 CONFIGURATION

With no configuration whatsoever, the plugin will work fine, thus contributing
to the I<keep it simple> motto of Dancer.

=head2 configuration default values

These are the default values. See below for a description of the keys

  plugins:
    DetectRobots:
      session_key: robot_client
      type: BASIC

=head2 configuration description

=over

=item session_key

The name of the session key which is used to store the results of the
robot test lookup

B<Default> : C<robot_client>

=item type

This value determinse which of 3 lists the search tests against.  
  BASIC - this is the same as AWStats LevelForRobotsDetection=1
  It tests for major search engines and know bots
  EXTENDED - this is the same as AWStats LevelForRobotsDetection=2
  It tests for major search engines and know bots as in BASIC plus
  about 800 minor bots and search engines.
  GENERIC - this is a very simple test that only looks for a couple of 
  dozen generic bot strings, e.g. robot, crawl, hunter, spider ...

B<Default> : C<BASIC>

=back

=head1 COPYRIGHT

This software is copyright (c) 2014 by Dan Busarow <dan@buildingonline.com>.

=head1 LICENCE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHORS

This module has been written by Dan Busarow <dan@buildingonline.com>
based upon Plack::Middleware::DetectRobots by Heiko Jansen <hjansen@cpan.org>

=head1 SEE ALSO

L<Dancer>

=head1 AUTHOR

Dan Busarow

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Dan Busarow

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
appie
architext
baiduspider
bingbot
bingpreview
bjaaland
contentmatch
ferret
googlebot\-image
googlebot
google\-sitemaps
google[_+ ]web[_+ ]preview
grabber
gulliver
virus[_+ ]detector
harvest
htdig
jeeves
linkwalker
lilina
lycos[_+ ]
moget
muscatferret
myweb
nomad
scooter
slurp
^voyager\/
weblayers
antibot
bruinbot
digout4u
echo!
fast\-webcrawler
ia_archiver\-web\.archive\.org
ia_archiver
jennybot
mercator
netcraft
msnbot\-media
petersnews
relevantnoise\.com
unlost_web_crawler
voila
webbase
webcollage
cfetch
zyborg
wisenutbot
## EXTENDED
[^a]fish
abcdatos
abonti\.com
acme\.spider
ahoythehomepagefinder
ahrefsbot
alkaline
anthill
arachnophilia
arale
araneo
aretha
ariadne
powermarks
arks
aspider
atn\.txt
atomz
auresys
backrub
bbot
bigbrother
blackwidow
blindekuh
bloodhound
borg\-bot
brightnet
bspider
cactvschemistryspider
calif[^r]
cassandra
cgireader
checkbot
christcrawler
churl
cienciaficcion
collective
combine
conceptbot
coolbot
core
cosmos
cruiser
cusco
cyberspyder
desertrealm
deweb
dienstspider
digger
diibot
direct_hit
dnabot
download_express
dragonbot
dwcp
e\-collector
ebiness
elfinbot
emacs
emcspider
esther
evliyacelebi
fastcrawler
feedcrawl
fdse
felix
fetchrover
fido
finnish
fireball
fouineur
francoroute
freecrawl
funnelweb
gama
gazz
gcreep
getbot
geturl
golem
gougou
grapnel
griffon
gromit
gulperbot
hambot
havindex
hometown
htmlgobble
hyperdecontextualizer
iajabot
iaskspider
hl_ftien_spider
sogou
icjobs\.de
iconoclast
ilse
imagelock
incywincy
informant
infoseek
infoseeksidewinder
infospider
inspectorwww
intelliagent
irobot
iron33
israelisearch
javabee
jbot
jcrawler
jobo
jobot
joebot
jubii
jumpstation
kapsi
katipo
kilroy
ko[_+ ]yappo[_+ ]robot
kummhttp
labelgrabber\.txt
larbin
legs
linkidator
linkscan
lockon
logo_gif
macworm
magpie
marvin
mattie
mediafox
merzscope
meshexplorer
mindcrawler
mnogosearch
momspider
monster
motor
msnbot
muncher
mwdsearch
ndspider
nederland\.zoek
netcarta
netmechanic
netscoop
newscan\-online
nhse
northstar
nzexplorer
objectssearch
occam
octopus
openfind
orb_search
packrat
pageboy
parasite
patric
pegasus
perignator
perlcrawler
phantom
phpdig
piltdownman
pimptrain
pioneer
pitkow
pjspider
plumtreewebaccessor
poppi
portalb
psbot
python
raven
rbse
resumerobot
rhcs
road_runner
robbie
robi
robocrawl
robofox
robozilla
roverbot
rules
safetynetrobot
search\-info
search_au
searchprocess
senrigan
sgscout
shaggy
shaihulud
sift
simbot
site\-valet
sitetech
skymob
slcrawler
smartspider
snooper
solbot
speedy
spider[_+ ]monkey
spiderbot
spiderline
spiderman
spiderview
spry
sqworm
ssearcher
suke
sunrise
suntek
sven
tach_bw
tagyu_agent
tailrank
tarantula
tarspider
techbot
templeton
titan
titin
tkwww
tlspider
ucsd
udmsearch
universalfeedparser
urlck
valkyrie
verticrawl
victoria
visionsearch
voidbot
vwbot
w3index
w3m2
wallpaper
wanderer
wapspIRLider
webbandit
webcatcher
webcopy
webfetcher
webfoot
webinator
weblinker
webmirror
webmoose
webquest
webreader
webreaper
websnarf
webspider
webvac
webwalk
webwalker
webwatch
whatuseek
whowhere
wired\-digital
wmir
wolp
wombat
wordpress
worm
woozweb
wwwc
wz101
xget
1\-more_scanner
360spider
a6-indexer
accoona\-ai\-agent
activebookmark
adamm_bot
adsbot-google
almaden
aipbot
aleadsoftbot
alpha_search_agent
allrati
aport
archive\.org_bot
argus
arianna\.libero\.it
aspseek
asterias
awbot
backlinktest\.com
becomebot
bender
betabot
biglotron
bittorrent_bot
biz360[_+ ]spider
blogbridge[_+ ]service
bloglines
blogpulse
blogsearch
blogshares
blogslive
blogssay
bncf\.firenze\.sbn\.it\/raccolta\.txt
bobby
boitho\.com\-dc
bookmark\-manager
boris
bubing
bumblebee
candlelight[_+ ]favorites[_+ ]inspector
careerbot
cbn00glebot
cerberian_drtrs
cfnetwork
cipinetbot
checkweb_link_validator
commons\-httpclient
computer_and_automation_research_institute_crawler
converamultimediacrawler
converacrawler
copubbot
cscrawler
cse_html_validator_lite_online
cuasarbot
cursor
custo
datafountains\/dmoz_downloader
dataprovider\.com
daumoa
daviesbot
daypopbot
deepindex
dipsie\.bot
dnsgroup
domainchecker
domainsdb\.net
dulance
dumbot
dumm\.de\-bot
earthcom\.info
easydl
eccp
edgeio\-retriever
ets_v
exactseek
extreme[_+ ]picture[_+ ]finder
eventax
everbeecrawler
everest\-vulcan
ezresult
enteprise
facebook
fast_enterprise_crawler.*crawleradmin\.t\-info@telekom\.de
fast_enterprise_crawler.*t\-info_bi_cluster_crawleradmin\.t\-info@telekom\.de
matrix_s\.p\.a\._\-_fast_enterprise_crawler
fast_enterprise_crawler
fast\-search\-engine
favicon
favorg
favorites_sweeper
feedburner
feedfetcher\-google
feedflow
feedster
feedsky
feedvalidator
filmkamerabot
filterdb\.iss\.net
findlinks
findexa_crawler
firmilybot
foaf-search\.net
fooky\.com\/ScorpionBot
g2crawler
gaisbot
geniebot
gigabot
girafabot
global_fetch
gnodspider
goforit\.com
goforitbot
gonzo
grapeshot
grub
gpu_p2p_crawler
henrythemiragorobot
heritrix
holmes
hoowwwer
hpprint
htmlparser
html[_+ ]link[_+ ]validator
httrack
hundesuche\.com\-bot
i-bot
ichiro
iltrovatore\-setaccio
infobot
infociousbot
infohelfer
infomine
insurancobot
integromedb\.org
internet[_+ ]ninja
internetarchive
internetseer
internetsupervision
ips\-agent
irlbot
isearch2006
istellabot
iupui_research_bot
jrtwine[_+ ]software[_+ ]check[_+ ]favorites[_+ ]utility
justview
kalambot
kamano\.de_newsfeedverzeichnis
kazoombot
kevin
keyoshid
kinjabot
kinja\-imagebot
knowitall
knowledge\.com
kouaa_krawler
krugle
ksibot
kurzor
lanshanbot
letscrawl\.com
libcrawl
linkbot
linkdex\.com
link_valet_online
metager\-linkchecker
linkchecker
livejournal\.com
lmspider
ltbot
lwp\-request
lwp\-trivial
magpierss
mail\.ru
mapoftheinternet\.com
mediapartners\-google
megite
metaspinner
miadev
microsoft bits
microsoft.*discovery
microsoft[_+ ]url[_+ ]control
mini\-reptile
minirank
missigua_locator
misterbot
miva
mizzu_labs
mj12bot
mojeekbot
msiecrawler
ms_search_4\.0_robot
msrabot
msrbot
mt::telegraph::agent
mydoyouhike
nagios
nasa_search
netestate ne crawler
netluchs
netsprint
newsgatoronline
nicebot
nimblecrawler
noxtrumbot
npbot
nutchcvs
nutchosu\-vlib
nutch
ocelli
octora_beta_bot
omniexplorer[_+ ]bot
onet\.pl[_+ ]sa
onfolio
opentaggerbot
openwebspider
oracle_ultra_search
orbiter
yodaobot
qihoobot
passwordmaker\.org
pear_http_request_class
peerbot
perman
php[_+ ]version[_+ ]tracker
pictureofinternet
ping\.blo\.gs
plinki
pluckfeedcrawler
pogodak
pompos
popdexter
port_huron_labs
postfavorites
projectwf\-java\-test\-crawler
proodlebot
pyquery
rambler
redalert
rojo
rssimagesbot
ruffle
rufusbot
sandcrawler
sbider
schizozilla
scumbot
searchguild[_+ ]dmoz[_+ ]experiment
searchmetricsbot
seekbot
semrushbot
sensis_web_crawler
seokicks\.de
seznambot
shim\-crawler
shoutcast
siteexplorer\.info
slysearch
snap\.com_beta_crawler
sohu\-search
sohu
snappy
spbot
sphere_scout
spiderlytics
spip
sproose_crawler
ssearch_bot
steeler
steroid__download
suchfin\-bot
superbot
surveybot
susie
syndic8
syndicapi
synoobot
tcl_http_client_package
technoratibot
teragramcrawlersurf
test_crawler
testbot
t\-h\-u\-n\-d\-e\-r\-s\-t\-o\-n\-e
topicblogs
turnitinbot
turtlescanner
turtle
tutorgigbot
twiceler
ubicrawler
ultraseek
unchaos_bot_hybrid_web_search_engine
unido\-bot
unisterbot
updated
ustc\-semantic\-group
vagabondo\-wap
vagabondo
vermut
versus_crawler_from_eda\.baykan@epfl\.ch
vespa_crawler
vortex
vse\/
w3c\-checklink
w3c[_+ ]css[_+ ]validator[_+ ]jfouffa
w3c_validator
watchmouse
wavefire
waybackarchive\.org
webclipping\.com
webcompass
webcrawl\.net
web_downloader
webdup
webfilter
webindexer
webminer
website[_+ ]monitoring[_+ ]bot
webvulncrawl
wells_search
wesee:search
wonderer
wume_crawler
wwweasel
xenu\'s_link_sleuth
xenu_link_sleuth
xirq
y!j
yacy
yahoo\-blogs
yahoo\-verticalcrawler
yahoofeedseeker
yahooseeker\-testing
yahooseeker
yahoo\-mmcrawler
yahoo!_mindset
yandex
flexum
yanga
yet-another-spider
yooglifetchagent
z\-add_link_checker
zealbot
zhuaxia
zspider
zeus
ng\/1\.
ng\/2\.
exabot
^[1-3]$
alltop
applesyndication
asynchttpclient
blogged_crawl
bloglovin
butterfly
buzztracker
carpathia
catbot
chattertrap
check_http
coldfusion
covario
daylifefeedfetcher
discobot
dlvr\.it
dreamwidth
drupal
ezoom
feedmyinbox
feedroll\.com
feedzira
fever\/
freenews
geohasher
hanrss
inagist
jacobin club
jakarta
js\-kit
largesmall crawler
linkedinbot
longurl
metauri
microsoft\-webdav\-miniredir
^motorola$
movabletype
^mozilla\/3\.0 \(compatible$
^mozilla\/4\.0$
^mozilla\/4\.0 \(compatible;\)$
^mozilla\/5\.0$
^mozilla\/5\.0 \(compatible;$
^mozilla\/5\.0 \(en\-us\)$
^mozilla\/5\.0 firefox\/3\.0\.5$
^msie
netnewswire
 netseer 
netvibes
newrelicpinger
newsfox
nextgensearchbot
ning
pingdom
pita
postpost
postrank
printfulbot
protopage
proximic
quipply
r6\_
ratingburner
regator
rome client
rpt\-httpclient
rssgraffiti
sage\+\+
scoutjet
simplepie
sitebot
summify\.com
superfeedr
synthesio
teoma
topblogsinfo
topix\.net
trapit
trileet
tweetedtimes
twisted pagegetter
twitterbot
twitterfeed
unwindfetchor
wazzup
windows\-rss\-platform
wiumi
xydo
yahoo! slurp
yahoo pipes
yahoo\-newscrawler
yahoocachesystem
yahooexternalcache
yahoo! searchmonkey
yahooysmcm
yammer
yeti
yie8
youdao
yourls
zemanta
zend_http_client
zumbot
wget
libwww
^java\/[0-9]
## GENERIC
robot
checker
crawl
discovery
hunter
scanner
spider
sucker
bot[\s_+:,\.\;\/\\\-]
[\s_+:,\.\;\/\\\-]bot
curl
php
ruby\/
no_user_agent
