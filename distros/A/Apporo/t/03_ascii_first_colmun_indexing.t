use strict;
use warnings;
use utf8;
use autodie;

use Apporo;

use Test::More tests => 10;

my $index_path = "/tmp/p5_apporo_index_03.tsv";
my $out_index;
open ($out_index, "> $index_path");

my $data = << "__DATA__";
3dldf	16-Jan-2004 15:20
a2ps	28-Dec-2007 22:55
acct	05-Nov-2010 15:45
acm	08-Dec-2010 14:00
adns	09-Jun-2006 14:05
anubis	20-Dec-2008 07:10
archimedes	25-Oct-2011 08:05
aris	15-Jul-2012 17:40
aspell-dict-csb	11-Mar-2005 15:45
aspell-dict-ga	26-Jul-2010 14:10
aspell-dict-hr	30-Mar-2004 03:10
aspell-dict-is	27-Aug-2004 11:32
aspell-dict-it	02-Jun-2005 16:56
aspell-dict-sk	11-Apr-2009 03:30
aspell	04-Jul-2011 06:20
auctex	14-Mar-2011 14:50
autoconf-archive	07-Apr-2012 14:45
autoconf	24-Apr-2012 23:25
autogen	11-Aug-2012 13:00
automake	14-Aug-2012 07:10
avl	26-Aug-2007 00:55
ballandpaddle	15-Jul-2009 10:20
barcode	02-Aug-2003 07:07
bash	29-Aug-2011 14:31
bayonne	18-Dec-2011 07:15
bc	02-Aug-2003 07:07
binutils	02-Jan-2012 05:20
bison	03-Aug-2012 03:55
bool	02-Aug-2003 07:08
bpel2owfn	30-Jul-2007 06:35
c-graph	26-Apr-2012 11:15
ccaudio	27-Mar-2011 12:50
ccrtp	21-Mar-2012 10:35
ccscript	18-May-2010 20:50
cfengine	02-Aug-2003 07:08
cflow	11-Oct-2011 16:30
cgicc	14-Nov-2009 13:25
chess	04-Mar-2012 04:45
cim	02-Aug-2003 07:08
classpath	16-Mar-2012 12:20
classpathx	28-Apr-2007 15:05
clisp	07-Jul-2010 13:30
combine	05-Jun-2004 09:35
commonc++	31-Mar-2012 10:35
commoncpp	31-Mar-2012 10:35
complexity	15-May-2011 15:10
config	13-Feb-2008 05:45
coreutils	12-Aug-2012 05:00
cpio	10-Mar-2010 08:20
cppi	04-Aug-2012 13:25
cssc	07-Nov-2010 05:55
dap	20-Feb-2008 19:00
ddd	11-Feb-2009 13:15
ddrescue	11-Jun-2012 14:20
dejagnu	24-Mar-2011 16:35
denemo	22-Jun-2012 15:30
dico	04-Mar-2012 09:20
diction	17-Sep-2007 19:55
diffutils	02-Sep-2011 11:30
dionysus	29-Aug-2010 05:55
dismal	03-Apr-2007 18:23
dominion	17-Feb-2005 23:05
dotgnu	10-Dec-2008 14:00
ed	01-Jan-2012 16:45
edma	08-Apr-2010 14:05
electric	02-Jul-2012 16:35
emacs	10-Jun-2012 04:30
emms	16-Sep-2008 13:10
enscript	01-Jun-2010 19:25
fdisk	04-Dec-2011 14:25
ferret	16-Nov-2008 14:45
findutils	06-Jun-2009 10:40
flex	20-Mar-2007 10:36
fontutils	02-Aug-2003 07:10
freedink	27-Apr-2012 14:45
freefont	03-May-2012 12:40
freeipmi	30-Jul-2012 13:55
gama	24-Jul-2012 07:00
garpd	06-Dec-2010 18:10
gawk	01-Apr-2012 17:20
gcal	13-May-2012 12:25
gcc	02-Jul-2012 11:25
gcide	04-Mar-2012 08:30
gcl	15-Jan-2008 12:50
gcompris	02-Aug-2003 07:12
gdb	26-Apr-2012 11:50
gdbm	13-Nov-2011 05:00
gengen	06-Sep-2010 16:10
gengetopt	25-Sep-2011 07:05
gettext	06-Jun-2010 18:10
gforth	02-Nov-2008 15:15
ggradebook	02-Aug-2003 07:12
ghostscript	01-Jan-2012 20:45
gift	24-Mar-2005 10:15
git	23-Feb-2009 16:05
gleem	02-Aug-2003 07:12
glibc	30-Jun-2012 16:10
global	30-May-2012 10:20
glpk	09-Sep-2011 16:30
gmp	06-May-2012 07:35
gnash	31-Jan-2012 11:15
gnats	06-Mar-2005 15:55
gnatsweb	14-Aug-2003 11:04
gnu-arch	20-Jul-2006 06:25
gnu-c-manual	05-Nov-2011 17:55
gnu-crypto	23-Oct-2005 20:30
gnubatch	08-Aug-2012 07:10
gnubik	09-Apr-2011 06:50
gnucap	02-Aug-2003 17:08
gnue	10-May-2010 04:35
gnugo	19-Feb-2009 10:15
GNUinfo	08-Feb-2005 17:34
gnuit	23-Feb-2009 16:05
gnujump	24-Jul-2012 16:40
gnukart	02-Aug-2003 17:08
gnumach	02-Aug-2003 07:13
gnun	28-Jun-2012 15:35
gnunet	06-Jun-2012 07:50
gnupod	06-Nov-2009 06:20
gnuprologjava	06-Jan-2011 09:05
gnuradio	03-Jun-2010 03:55
gnurobots	03-Aug-2008 17:15
GNUsBulletins	24-Mar-2003 18:00
gnuschool	27-Aug-2007 04:10
gnushogi	25-Mar-2012 11:00
gnusound	06-Jul-2008 05:00
gnuspool	21-Oct-2010 17:20
gnustep	17-Feb-2004 17:25
gnutls	04-Aug-2012 15:15
gnutrition	31-Mar-2012 21:35
gnuzilla	12-Jul-2012 13:55
goptical	07-Jan-2012 18:45
gperf	03-Feb-2009 16:20
gprolog	29-Jun-2012 06:15
greg	02-Aug-2003 07:13
grep	04-Jul-2012 11:45
groff	21-Dec-2011 17:20
grub	27-Jun-2012 20:25
gsasl	28-May-2012 14:00
gsegrafix	10-Sep-2011 14:20
gsl	06-May-2011 18:20
gsrc	24-Aug-2011 12:45
gss	24-Nov-2011 19:05
gtypist	29-Nov-2011 18:30
guile-gnome	03-Jul-2008 12:05
guile-gtk	30-Dec-2007 18:55
guile-ncurses	03-Feb-2011 08:20
guile	07-Jul-2012 06:15
gv	02-Dec-2011 08:20
gvpe	11-Feb-2011 23:40
gxmessage	25-Feb-2012 10:45
gzip	17-Jun-2012 15:30
halifax	02-Aug-2003 07:15
health	17-Jun-2012 19:20
hello	20-Apr-2012 14:00
help2man	28-Jul-2012 06:10
hp2xx	14-Aug-2003 11:04
httptunnel	02-Aug-2003 07:13
hurd	07-Jan-2011 12:55
hyperbole	07-Aug-2008 15:20
idutils	03-Feb-2012 07:55
ignuit	27-Feb-2012 09:50
indent	15-Feb-2009 04:55
inetutils	06-Jan-2012 09:20
intlfonts	02-Aug-2003 07:14
jacal	09-Apr-2012 23:20
jel	12-Oct-2007 14:05
jwhois	01-Jul-2007 05:50
kawa	30-May-2012 17:50
less	17-Apr-2011 17:00
libc	30-Jun-2012 16:10
libcdio	27-Oct-2011 04:10
libextractor	28-Nov-2011 07:00
libffcall	16-Jun-2008 12:35
libiconv	07-Aug-2011 14:00
libidn	23-May-2012 04:55
libmatheval	03-Jul-2011 06:15
libmicrohttpd	19-Jul-2012 16:00
librejs	07-Jul-2012 16:15
libsigsegv	03-Apr-2011 12:00
libtasn1	31-May-2012 11:35
libtool	18-Oct-2011 04:25
libunistring	02-May-2010 17:45
libxmi	02-Aug-2003 07:14
Licenses	15-Aug-2012 00:45
lightning	25-Nov-2004 09:50
lilypond	31-May-2006 10:59
liquidwar6	23-Dec-2011 20:30
lsh	07-Mar-2009 15:35
m4	01-Mar-2011 14:50
macchanger	11-May-2004 10:49
MailingListArchives	02-Aug-2003 07:27
mailman	15-Jun-2012 12:50
mailutils	08-Sep-2010 08:55
make	29-Aug-2011 14:01
marst	16-Nov-2007 08:25
maverik	11-Jan-2009 15:50
mc	19-Sep-2007 11:05
mcron	19-Jun-2010 16:50
mcsim	29-Jan-2011 11:10
mdk	09-Oct-2010 20:15
metahtml	02-Aug-2003 17:08
MicrosPorts	02-Aug-2003 08:48
mifluz	07-Jul-2008 15:25
mig	15-Aug-2003 17:42
miscfiles	16-Nov-2010 21:13
mit-scheme	20-Mar-2005 22:45
moe	16-Jan-2011 13:15
motti	10-Jul-2010 13:45
mpfr	03-Jul-2012 19:15
mtools	28-Jun-2011 18:50
myserver	16-Jul-2011 10:45
nano	11-May-2011 01:00
ncurses	04-Apr-2011 19:15
nettle	07-Jul-2012 09:40
non-gnu	08-Apr-2010 20:17
ocrad	10-Jan-2011 10:00
octave	31-May-2012 13:40
oleo	02-Aug-2003 07:14
orgadoc	31-Mar-2004 15:45
osip	05-Oct-2011 14:30
paperclips	02-Aug-2003 17:08
parallel	23-Jun-2012 01:50
parted	02-Mar-2012 12:50
patch	30-Dec-2009 11:30
pem	16-Aug-2011 01:45
pexec	14-Sep-2009 17:10
phantom	02-Aug-2003 07:14
pies	12-Dec-2009 07:30
plotutils	26-Sep-2009 17:00
proxyknife	24-Sep-2007 10:00
pspp	11-Oct-2009 17:40
psychosynth	02-Apr-2012 19:30
pth	08-Jun-2006 14:20
radius	29-Aug-2011 14:03
rcs	05-Jun-2012 06:40
readline	28-Feb-2011 10:05
recutils	13-Jan-2012 06:20
reftex	09-Aug-2009 08:50
rottlog	30-Mar-2010 18:30
rpge	15-Mar-2008 07:45
rush	07-Jul-2010 17:10
sather	07-Jul-2007 08:15
sauce	02-Aug-2003 07:15
savannah	26-Apr-2007 10:16
scm	09-Apr-2012 23:20
screen	07-Aug-2008 06:35
sed	27-Jun-2009 18:25
serveez	20-Jun-2009 11:15
sharutils	29-Apr-2011 14:20
shishi	12-Mar-2012 15:10
shmm	28-Jun-2008 11:05
shtool	18-Jul-2008 04:10
sipwitch	25-Apr-2012 16:30
slib	09-Apr-2012 16:50
smalltalk	22-Mar-2011 03:40
solfege	20-Jun-2012 18:15
sourceinstall	20-Jul-2008 22:25
sovix	15-Dec-2008 06:55
spacechart	14-Aug-2003 11:04
speedx	02-Aug-2003 17:08
spell	21-Jul-2011 15:30
sqltutor	29-Apr-2009 13:15
src-highlite	30-Jun-2012 08:50
stow	18-Feb-2012 15:40
superopt	02-Aug-2003 07:15
swbis	25-Apr-2011 20:00
tar	12-Mar-2011 05:55
termcap	02-Aug-2003 07:15
termutils	02-Aug-2003 07:15
teseq	04-Aug-2008 13:20
texinfo	13-Aug-2012 18:50
thales	09-May-2004 04:25
time	02-Aug-2003 07:15
tramp	04-Jun-2012 14:35
trueprint	02-Aug-2003 07:15
units	28-Jun-2012 15:20
unrtf	07-Jun-2011 15:35
userv	05-Jun-2006 07:40
uucp	02-Aug-2003 07:15
vc-dwim	23-Dec-2011 06:30
vcdimager	17-Mar-2011 20:10
vera	08-Jun-2006 01:45
vmslib	06-Sep-2009 03:10
wb	09-Apr-2012 23:20
wdiff	30-May-2012 16:45
websocket4j	24-Oct-2010 09:40
wget	05-Aug-2012 16:30
which	06-Aug-2008 11:25
windows	11-May-2004 17:05
xaos	02-Aug-2003 07:15
xboard	17-Apr-2012 22:45
xhippo	27-Aug-2007 17:50
xlogmaster	24-Jun-2009 20:45
xnee	27-Apr-2012 08:45
xorriso	20-Jul-2012 16:20
zile	13-Jul-2012 07:20
__DATA__

print $out_index $data;

system("LC_ALL=C sort $index_path > $index_path.sort");
system("mv $index_path.sort $index_path");

close ($out_index);
{
    my $is_there_file = 0;
    my $file_path = $index_path;
    my $file_name = "sample data file";
    if( -f $file_path ) { $is_there_file = 1; }
    is($is_there_file, 1, "write $file_name to /tmp");
    my $file_size = -s $file_path;
    isnt($file_size, 0, "$file_name has data entity");
}

system("apporo_indexer -i $index_path -bt");
{
    my $is_there_file = 0;
    my $file_path = $index_path.".ary";
    my $file_name = "apporo ASCII ary index for first colmun of sample data file";
    if( -f $file_path ) { $is_there_file = 1; }
    is($is_there_file, 1, "write $file_name to /tmp");
    my $file_size = -s $file_path;
    isnt($file_size, 0, "$file_name has data entity");
}

system("apporo_indexer -i $index_path -d");
{
    my $is_there_file = 0;
    my $file_path = $index_path.".did";
    my $file_name = "apporo ASCII did index for sample data file";
    if( -f $file_path ) { $is_there_file = 1; }
    is($is_there_file, 1, "write $file_name to /tmp");
    my $file_size = -s $file_path;
    isnt($file_size, 0, "$file_name has data entity");
}

my $conf_path = "/tmp/p5_apporo_conf_03.tsv";
my $out_conf;
open ($out_conf, "> $conf_path");

my $conf = << "__CONF__";
ngram_length	2
is_pre	true
is_suf	true
is_utf8	false
dist_threshold	0.0
index_path	/tmp/p5_apporo_index_03.tsv
dist_func	edit
entry_buf_len	1024
engine	tsubomi
result_num	10
bucket_size	2000
is_surface	true
is_kana	false
is_roman	false
is_mecab	false
is_juman	false
is_kytea	false
__CONF__

print $out_conf $conf;

close ($out_conf);

{
    my $is_there_file = 0;
    my $file_path = $conf_path;
    my $file_name = "configure file(ASCII, 2-gram, insert dummy character to head and tail of query e.t.c.) of apporo search";
    if( -f $file_path ) { $is_there_file = 1; }
    is($is_there_file, 1, "write $file_name to /tmp");
    my $file_size = -s $file_path;
    isnt($file_size, 0, "$file_name has data entity");
}

my $app = Apporo->new($conf_path);

{
    my $query = "emacs";
    my @arr = @{$app->retrieve($query)};
    my @res = (
        "1	emacs	10-Jun-2012 04:30",
        "0.6	emms	16-Sep-2008 13:10",
        "0.428571	gnumach	02-Aug-2003 07:13",
        "0.4	marst	16-Nov-2007 08:25",
        "0.4	xaos	02-Aug-2003 07:15",
        "0.4	make	29-Aug-2011 14:01",
        "0.4	rcs	05-Jun-2012 06:40",
        "0.4	pies	12-Dec-2009 07:30",
        "0.4	less	17-Apr-2011 17:00",
        "0.4	edma	08-Apr-2010 14:05",
    );
    my %hash_res = ();
    for (my $i = 0; $i <= $#res; $i++) {
        $res[$i] = $res[$i];
        my @cels = split /\t/, $res[$i];
        my $key = $cels[0].$cels[1];
        $hash_res{$key} = $res[$i];
    }
    my %hash_arr = ();
    for (my $i = 0; $i <= $#arr; $i++) {
        my @cels = split /\t/, $arr[$i];
        my $key = $cels[0].$cels[1];
        $hash_arr{$key} = $arr[$i];
    }
    is_deeply(\%hash_arr, \%hash_res, "get the result from the indexes whose index points are all charactors of first column using '$query' query");
}

{
    my $query = "2012";
    my @arr = @{$app->retrieve($query)};
    my @res = ();
    is_deeply(\@arr, \@res, "'$query' is not include in first colmun of target data");
}
