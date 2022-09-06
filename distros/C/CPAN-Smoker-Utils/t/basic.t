use warnings;
use strict;
use Test::More;
use Test::Warnings 0.026 qw(:all :no_end_test);

BEGIN {
    use_ok( 'CPAN::Smoker::Utils', qw(is_distro_ok) );
}

my $dummy = 'ARFREITAS/Module::Name';

note('Testing is_distro_ok');
my $result;
like( warning { $result = is_distro_ok($dummy) },
    qr/^invalid\sstring/, 'got the expected warning' );
ok( !$result, 'fails with a warning if a module name is passed instead' );

while (<DATA>) {
    chomp;
    ok( is_distro_ok($_), "$_ passes" );
}

close(DATA);

done_testing;

__DATA__
AADLER/Inline-Octave
ADDI/File-FDpasser
ADESC/Devel-CoreStack
AIVATURI/VMware-LabManager
AKINT/Zabbix-ServerScript
ALTREUS/OpusVL-SysParams
AMALTSEV/XAO
ANDREWF/LaTeX-Driver
ANTONC/Async-Simple-Pool
APEIRON/Net-IRC
APOCAL/Task-POE-All
ARAK/Fax-Hylafax-Client
ASCOPE/Net-Google
ATHOMASON/Gearman-Spawner
BDFOY/Brick
BDFOY/Bundle-BDFOY
BINGOS/POE-Component-Client-HTTP
BINGOS/POE-Loop-AnyEvent
BOOK/Net-Proxy
BOUTROSLB/HPCI
BRIANSKI/XML-Comma
CADAVIS/Task-BeLike
CAIDAPERL/Chart-Graph
CHIM/Task-BeLike-CHIM-Cabinet
CINDY/Memcached-Server
CLAESJAC/Test-Harness-FileFilter
CORION/WWW-Mechanize-Shell
CORLISS/Curses-Widgets
COSIMO/Net-Statsd-Server
CRTLSOFT/Parse-Pidl
CTRLSOFT/Parse-Pidl
DBOOK/POE-Loop-EV
DBUCHMAN/MegaDistro
DCOLLINS/Perlwikipedia
DESIMINER/Date-Business
DMAKI/Plack-Server-AnyEvent-Server-Starter
DOM/Wiki-Toolkit-Plugin-Ping
DOY/IO-Pty-Easy
DROLSKY/Alzabo-GUI-Mason
DROLSKY/HTML-Mason
DUFF/Module-Install-RPM
DVKLEIN/Hardware-1Wire-HA7Net
ECALDER/POE-Component-Child
EESTABROO/IMAP-Admin
ELACOUR/RT-Extension-FollowUp
GIFF/Net-FTP-RetrHandle
GMPASSOS/Mail-SendEasy
GRICHTER/Apache-SessionX
GRICHTER/DBIx-Recordset
GRICHTER/Embperl
GRYPHON/Daemon-Device
GUGOD/Acme-Tests
GWYN/POEx-HTTP-Server
HDIAS/Mail-Salsa
HESCO/LedgerSMB-API
HINRIK/POE-Component-Server-IRC
HORROCKS/PersistentPerl
ILMARI/Catalyst-Authentication-Store-LDAP
IMACAT/DbFramework
IOANR/Prophet
ISAACSON/Rstat-Client
ITYNDALL/Net-Amazon-Thumbnail
IVAN/Net-SSH
JANE/Data-TDMA
JEFFOBER/Argon
JEZRA/Devel-GDB
JHOBLITT/Pod-Tidy
JLMARTIN/NRD-Daemon
JLMARTIN/Paws
JMMILLS/Module-Install-AgressiveInclude
JPIERCE/EZDBI
JSTOWE/Term-Screen
JUNNAMA/Net-Azure-StorageClient
JWACH/xDash
KANE/File-Fetch
KARMAN/Net-LDAP-Class
KMCGRAIL/Mail-SpamAssassin
KROW/DBIx-Password
KWILLIAMS/Apache
KWILLIAMS/Crypt-SKey
LAOMOI/XiaoI
LDS/Bio-BigFile
LDS/Bio-SamTools
LEOCHARRE/WWW-Autosite
LSF/App-Prove-Plugin-Distributed
LUSHE/Egg-Release-DBI
LUSOL/tkjuke
MAKAROW/Win32-Script
MARNANEL/App-Bernard
MARNANEL/Flickr-Embed
MARNANEL/Locale-PO-Callback
MARNANEL/Net-RGTP
MAROS/MooseX-App
MAXM/MMM-Text-Search
MCMAHON/Test-WWW-Simple
METZZO/Java
METZZO/TiVo-HME
MICHIELB/Bundle-DBD-mysql
MIKIHOSHI/AnyEvent-IRC-Server
MIYAGAWA/Twiggy
MLEHMANN/PApp
MLEHMANN/RCU
MMABRY/Device-WxM2
MMACHADO/Geo-Weather
MOB/Forks-Super
MOCK/Business-OnlinePayment-Exact
MTW/Bio-ViennaNGS
PBOETTCH/ARCv2
PERLANCAR/Bencher-Backend
PERLANCAR/Language-Expr
PETDANCE/Test-WWW-Mechanize
PEVANS/Protocol-Gearman
PHILIPS/DBIx-MyParse
PIERS/Jabber-mod_perl
PLICEASE/Test-Script
RCAPUTO/POE-Component-Client-HTTP
RICKM/DateTime-LazyInit
ROCKY/Devel-Trepan
ROMM/Net-Whois-IANA
RRA/PGP-Sign
RSOLIV/rrdpoller
SAMV/Tangram
SCHWIGON/Net-SSH-Perl
SCOTT/Attribute-Persistent
SDPRICE/Linux-DVB-DVBT-Apps-QuartzPVR
SHIBAZAKI/WebService-Bitly
SIMONW/LWPx-TimedHTTP
SOMMERB/Myco
SOREAR/IO-Pty-HalfDuplex
SPANG/Prophet
SSCAFFIDI/Stem
SSHIN/Crypt-RNCryptor
STEVEB/Devel-Examine-Subs
STEVEB/FreeRADIUS-Database
STEVENC/WWW-Myspace
SWALTERS/Acme-RPC
TBONE/HTTP-File
THOSPEL/Heap-Simple
TPABA/Term-Screen-Uni
TULSOFT/Monitor-Simple
VIZDOM/DBD-JDBC
WAG/Sudo
WOHL/File-Properties
XEONTIME/Apache-Sling
XERN/Bio-Medpost
XERN/Lingua-EN-GeniaTagger
XSAWYERX/WWW-xkcd
YAMATO/QDBM-File
YANNK/ControlFreak
ZJT/Net-Proxy-Connector-tcp_balance
