use strict;
use warnings;
require ExtUtils::MakeMaker;
use Config::IniFiles;
use Cwd;
use File::Spec::Functions;
use File::Basename;
use Sys::Hostname;
use File::Find;
use File::Copy;
use File::Path;

use constant WIN32 => $^O eq 'MSWin32';

unless (-d 'tt2') {
  die "Please run this from the top-level directory";
}

my $httpd = WIN32 ? 'C:\Apache2' : '/usr/local/httpd';

my $cfg = Config::IniFiles->new();
print <<'END';

This script will take you through a dialogue to set up
some configuration details.

We first gather some information for setting up the
database tables.

END

my $cwd = getcwd;
my $home = $ENV{HOME} || $cwd;
my $config = catfile $home, 'csl', 'cpan.conf';
$config = prompt('Location of configuration file?', $config);
unless (check_dir(dirname($config))) {
  die "Need a valid location to save the configuration file";
}
if (-f $config) {
  if (prompt_y("'$config' exists. Overwrite it?")) {
    unlink $config or die "Cannot unlink $config: $!";
  }
  else {
    die "Please specify a different configuration file name";
  }
}
$cfg->SetFileName($config);

my $html_root;

if (prompt_y('Are you running a local CPAN mirror?')) {
  my $CPAN = prompt('Path to top-level CPAN directory?',
                   '/var/ftp/pub/CPAN');
  die qq{$CPAN does not exist} unless (-d $CPAN);
  $cfg->newval('CPAN', 'CPAN', $CPAN);
  my $pod_root = prompt('Path to store pod sources?',
                       catdir($httpd, 'POD'));
  if ($pod_root = check_dir($pod_root)) {
    $cfg->newval('CPAN', 'pod_root', $pod_root);
  }
  else {
    warn "Will not insert configuration for pod sources\n";
  }
  $html_root = prompt('Path to store html files?',
                      catdir($httpd, 'htdocs', 'CPAN'));
  if ($html_root = check_dir($html_root)) {
    $cfg->newval('CPAN', 'html_root', $html_root);
  }
  else {
    warn "Will not insert configuration for html files\n";
  }
}
else {
  $cfg->newval('CPAN', 'no_mirror', 1);
  my $CPAN = prompt('Location to store CPAN index files?',
                    catdir($home, '.cpan', 'build'));
  if ($CPAN = check_dir($CPAN)) {
    $cfg->newval('CPAN', 'CPAN', $CPAN);
  }
  else {
    die "Must have a valid location to store index files";
  }
  my $remote_mirror = prompt('CPAN mirror to fetch index files?',
                            'http://www.cpan.org');
  $cfg->newval('CPAN', 'remote_mirror', $remote_mirror);
}

unless (prompt_y('Gather Win32 ppm package information?')) {
  $cfg->newval('CPAN', 'no_ppm', 1);
}

if (prompt_y('Guess unassigned module categories?')) {
  my $cat_threshold = prompt('Threshold value for guesses?', 0.998);
  $cfg->newval('CPAN', 'cat_threshold', $cat_threshold);
}
else {
  $cfg->newval('CPAN', 'no_cat', 1);
}
$cfg->newval('CPAN', 'DEBUG', 1);

my $multiplex;
if (prompt_y('Use a multiplexer for mirror redirects?')) {
  $multiplex = prompt('Address of multiplexer',
                         'http://www.perl.com/CPAN');
  $cfg->newval('CPAN', 'multiplex', $multiplex);
}

print <<'END';

For the database, as well as needing the name, we will
also require the user and password who has permission to
create/query/alter/drop tables. It is assumed the database 
has already been created, and that this user has already 
been set up with the proper privileges.

END

my $db = prompt('Name of database?', 'pause');
$cfg->newval('DB', 'db', $db);
my $user = WIN32 ? $ENV{USERNAME} : getpwuid($>);
$user = prompt('User to create/query/alter/drop tables?', $user);
$cfg->newval('DB', 'user', $user);
my $passwd = prompt("Password for '$user'?", 'q1w2e3r4');
$cfg->newval('DB', 'passwd', $passwd);
my $host = hostname;

my %config;
my ($tt2, $static);
my $web = prompt_y('Set up configuration for a web server?');
if ($web) {
  print <<'END';

We now gather some information for configuring the
web server.

END
  $config{db_sub} = $cfg->val('DB', 'db');
  $config{nobody_sub} = prompt('User to query tables?', 'nobody');
  $config{no_pass_sub} = prompt("Password for '$config{nobody_sub}'?", 
                                'p0o9i8u7');

  $tt2 = prompt('Location of installed tt2 templates?',
                   catdir($httpd, 'tt2'));
  if ($tt2 = check_dir($tt2)) {
    $cfg->newval('WWW', 'tt2', $tt2);
    $config{tt2_sub} = $tt2;
  }
  else {
    die "Need a valid directory for tt2 pages\n";
  }
  my $geoip = prompt('Location of list of CPAN mirrors?',
                     catfile($tt2, 'cpan.txt'));
  if ($geoip = check_dir(dirname($geoip))) {
    $cfg->newval('WWW', 'geoip', $geoip);
  }
  else {
    warn "Will not insert configuration for CPAN mirrors list\n";
  }
  unless ($html_root) {
    $html_root = prompt('Path to store html files?',
                        catdir($httpd, 'htdocs', 'CPAN'));
    unless (check_dir($html_root)) {
      die "Need a valid directory for html files\n";
    }
  }
  $config{store_sub} = $html_root;
  $static = catdir $html_root, 'faqs';
  $static = prompt('Path to store static pages?', 
                   $static);
  unless (check_dir($static)) {
    die "Need a valid directory to store static html files\n";
  }
  $config{static_store_sub} = $static;

  my $css = prompt("Name of css file? (relative to $html_root)",
                   'cpan.css');
  $cfg->newval('WWW', 'css', $css);
  my $up = prompt("image to indicate 'up' (relative to $html_root)?",
                  'up.png');
  $cfg->newval('WWW', 'up_img', $up);

  $config{url_sub} = 'http://' . $host;
  $config{url_sub} = prompt('URL of main search page?', $config{url_sub});
  $config{docs_sub} = $config{url_sub} . '/htdocs';
  $config{docs_sub} = prompt('URL of module documentation?', 
                             $config{docs_sub});
  $config{static_sub} = $config{docs_sub} . '/faqs';
  $config{static_sub} = prompt('URL of static info pages?', 
                               $config{static_sub});
  $config{multiplex_sub} = $multiplex ||
    'http://www.cpan.org';
  $config{multiplex_sub} = prompt('URL of default download?', 
                                  $config{multiplex_sub});

  $config{user_sub} = $user;
  $config{user_sub} = prompt('Name of maintainer?', $config{user_sub});
  $config{email_sub} = $config{user_sub} . '@' . $host;
  $config{email_sub} = prompt("Email for $config{user_sub}?", 
                              $config{email_sub});
  $config{img_sub} = $config{url_sub} . '/icons/cpan.jpg';
  $config{img_sub} = prompt('URL of CPAN image?', $config{img_sub});
  $config{splash_sub} = $config{url_sub} . '/tt2/images/splash';
  $config{splash_sub} = prompt('URL of tt2 splash images?', 
                               $config{splash_sub});
}

print "Writing $config\n";
$cfg->WriteConfig($config) or die "Cannot write $config: $!";

my $tt2_config = catfile $cwd, 'tt2', 'config';
print "Writing $tt2_config\n";
my $pat = join '|', map {$_ . '_sub'} 
  qw(url docs static multiplex user email img splash);
$pat = qr{$pat};
open(my $fh, '>', $tt2_config) or die "Cannot write to $tt2_config: $!";
while (<DATA>) {
  last if /^xxxxx/;
  s/($pat)/$config{$1}/;
  print $fh $_;
}

my $csl_conf = catfile $cwd, 'csl.conf';
print "Writing Apache conf file $csl_conf\n";
$pat = join '|', map {$_ . '_sub'} 
  qw(store static_store db nobody no_pass tt2);
$pat = qr{$pat};
open($fh, '>', $csl_conf) or die "Cannot write to $csl_conf: $!";
while (<DATA>) {
  s/($pat)/$config{$1}/;
  print $fh $_;
}

my $local_tt2 = catdir $cwd, 'tt2';
print "Copying files from $local_tt2 to $tt2\n";
my @files;
finddepth(sub {
            push @files, canonpath($File::Find::name) 
              if (-f $_ and $File::Find::name !~ /CVS/);
          }, $local_tt2);
foreach my $file (@files) {
  (my $relative = $file) =~ s{^\Q$local_tt2}{};
  my $to = canonpath(catfile $tt2, $relative);
  my $dir = dirname($to);
  unless (-d $dir) {
    mkpath($dir, 1, 0777) or die "Cannot mkpath $dir: $!";
  }
  copy($file, $to) or die "Cannot copy $file to $to: $!";
}

my $local_static = catdir $cwd, 'htdocs';
print "Copying files from $local_static to $static\n";
@files = ();
finddepth(sub {
            push @files, canonpath($File::Find::name) 
              if (-f $_ and $File::Find::name !~ /CVS/);
          }, $local_static);
foreach my $file (@files) {
  (my $relative = $file) =~ s{^\Q$local_static}{};
  my $to = canonpath(catfile $static, $relative);
  my $dir = dirname($to);
  unless (-d $dir) {
    mkpath($dir, 1, 0777) or die "Cannot mkpath $dir: $!";
  }
  copy($file, $to) or die "Cannot copy $file to $to: $!";
}

print <<"END";

The CSL configuration file was written to
   $config
and a sample httpd configuration file as
   $csl_conf
You can now run
   csl_index --conf $config --setup
to set up and populate the database. Afterwards,
   csl_index --conf $config
will update it.

END

sub check_dir {
  my $dir = shift;
  return $dir if (-d $dir);
  if (prompt_y(qq{'$dir' does not exist. Create it?})) {
    mkdir($dir) or die "mkdir $dir failed: $!";
    return $dir;
  }
  warn "Will not create $dir.\n";
  return;
}

sub prompt {
  my ($q, $default) = @_;
  ExtUtils::MakeMaker::prompt($q, $default);
}

sub prompt_y {
  my $q = shift;
  prompt($q, 'yes') =~ /^y/i;
}

sub prompt_n {
  my $q = shift;
  prompt($q, 'no') =~ /^n/i;
}

__DATA__
[% home = 'url_sub' %]
[% 
   PROCESS splash/config;
   search = "$home/search"
   download = 'multiplex_sub'
   doc = 'docs_sub'
   static = 'static_sub'
   main = "$static/cpan-search.html"
   cpanimg = 'img_sub'
   testers = 'http://testers.cpan.org/show/'
   searchcpan = 'http://search.cpan.org/'
   rt = 'http://rt.cpan.org/NoAuth/Bugs.html?Dist='
   splash.images = 'splash_sub'
   cpan = 'http://www.cpan.org'
   backpan = 'http://backpan.cpan.org'
   splash.style.default.col.fore = 'grey75'
   splash.style.default.col.text = 'black'
   splash.style.select.col.fore = 'sky'
   splash.style.select.col.text = 'black'
   splash.style.select.font.bold = 1
   splash.style.select.font.size = '+1'
   maintainer = 'user_sub'
   maintainer_email = 'email_sub'
   faq =  "$static/faq.html"
   dslip = "$static/dslip.html"
   ppm = "$static/ppm.html"
   extra_files = { readme => {name => 'README', link => 'README.html'},
                   meta => {name => 'META', link => 'META.html'},
                   changes => {name => 'Changes', link => 'Changes.html'},
                   install => {name => 'INSTALL', link => 'INSTALL.html'},
                }
%]
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
<Directory "store_sub">
   Options Indexes FollowSymLinks
   AllowOverride None
   Order allow,deny
   Allow from all
</Directory>
<Directory "static_store_sub">
   <Files *.html>
      SetHandler type-map
   </Files>
</Directory>

PerlLoadModule Apache2::CPAN::Query
CSL_db db_sub
CSL_user nobody_sub
CSL_passwd no_pass_sub
CSL_tt2 "tt2_sub"
CSL_html_root "store_sub"
CSL_html_uri "docs_sub"

<Location "/search">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->search
</Location>
<LocationMatch "/~[A-Za-z0-9-]+">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->cpanid
</LocationMatch>
<Location "/author">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->author
</Location>
<Location "/dist">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->dist
</Location>
<Location "/module">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->module
</Location>
<Location "/chapter">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->chapter
</Location>
<Location "/recent">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->recent
</Location>
<Location "/mirror">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->mirror
</Location>
<Location "/perldoc">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->perldoc
</Location>
 
