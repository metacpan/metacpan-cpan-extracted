# -*- cperl -*-

BEGIN {
    use Config;

    if ($] == 5.008 && $ENV{"LANG"} ne "C") {
    $ENV{LANG} = "C";
    print STDERR "\n\n\n\$ENV{LANG} is not 'C' execing 'perl Makefile.PL'".
    " with ENV{LANG} == 'C'\n You can skip this check by: 'export ".
    "LANG='C' before running 'perl Makefile.PL or by upgrading your Perl'\n\n\n";

    sleep(5);
        exec ($Config{perlpath}, $0, @ARGV )|| die $!;
    }
}
use strict;
BEGIN { $^W = 1; }
use Getopt::Long();
use ExtUtils::MakeMaker();
use Data::Dumper ();
use File::Path;
use File::Copy;
require DBI::DBD;

# Set the variable $File::Find::dont_use_nlink if you're using AFS,
# since AFS cheats.

my $TESTDB = "test";

use vars qw($opt);
$opt = { "help" => \&Usage, };

Getopt::Long::GetOptions(
    $opt,
    "help",
    "testdb=s",
    "testhost=s",
    "testport=s",
    "testuser=s",
    "testpassword=s",
    "cflags=s",
    "libs=s",
    "verbose",
    "bind-type-guessing",
    "nocatchstderr",
    "ssl!",
    "nofoundrows!",
    "pkg-config=s",
    ) || die Usage();

my $source = {};

my $header;
if ($^O !~ /mswin32/i)
{
  #Check for pkg-config first
  $source->{'pkg-config'}="guessed";
  # this is a bit verbose and a more elegant solution is in store
      
  if ($opt->{'pkg-config'})
  {  
    if (-f $opt->{'pkg-config'})
    {
      $source->{'pkg-config'} = "Users choice";
    }
    else
    {
      print <<"MSG";

Specified drizzle configuration script '$opt->{'pkg-config'}' doesn't exist. 
Please check path/permissions. Will try to use default pkg-config 
script found through PATH.
MSG
      $opt->{'pkg-config'}= "pkg-config";
    }
  }
  else
  {
    #if (! `pkg-config`)
    #{
    #  print <<MSG;

#Cannot find the file 'pkg-config'! Your execution PATH doesn't seem 
#not contain the path to pkg-config. Resorting to guessed values!
#MSG
 #   }
 #   $opt->{'pkg-config'} = "pkg-config";
  }
}

for my $key (qw/testdb testhost testuser testpassword cflags libs nocatchstderr ssl nofoundrows
              bind-type-guessing/)
{
  Configure($opt, $source, $key);
}


print <<"MSG";
I will use the following settings for compiling and testing:

MSG

delete $opt->{'help'};
my $keylen = 0;
for my $key (keys %$opt)
{
  $keylen = length($key) if length($key) > $keylen;
}
my $slen = 0;
for my $val (values %$source)
{
  $slen = length($val) if length($val) > $slen;
}

for my $key (sort { $a cmp $b} keys %$opt)
{
  printf("  %-" . $keylen . "s (%-" . $slen . "s) = %s\n",
     $key, $source->{$key}, $opt->{$key})
}

print <<"MSG";

To change these settings, see 'perl Makefile.PL --help' and
'perldoc INSTALL'.

MSG

sleep 5;

eval { require File::Spec };
my $dsn= '';
if (defined $opt->{'bind-type-guessing'}) {
    $dsn= "\$::test_dsn .= \";drizzle_bind_type_guessing=1\";\n"; 
}
my $fileName = $@ ?
  "t/drizzle.mtest" : File::Spec->catfile("t", "drizzle.mtest");
(open(FILE, ">$fileName") &&
 (print FILE ("{ local " . Data::Dumper->Dump([$opt], ["opt"]) .
          "\$::test_host = \$opt->{'testhost'};\n" .
          "\$::test_port = \$opt->{'testport'};\n" .
          "\$::test_user = \$opt->{'testuser'};\n" .
          "\$::test_password = \$opt->{'testpassword'};\n" .
          "\$::test_db = \$opt->{'testdb'};\n" .
          "\$::test_dsn = \"DBI:drizzle:\$::test_db\";\n" .
              "\$::test_dsn .= \":\$::test_host\" if \$::test_host;\n" .
          "\$::test_dsn .= \":\$::test_port\" if \$::test_port;\n".
              $dsn .
          "} 1;\n"))  &&
  close(FILE))  ||  die "Failed to create $fileName: $!";


my $cflags = "-I\$(DBI_INSTARCH_DIR) $opt->{'cflags'}";
if ($^O eq 'VMS') {
  $cflags = "\$(DBI_INSTARCH_DIR),$opt->{'cflags'}";
}
$cflags .= " -DDBD_DRIZZLE_WITH_SSL" if $opt->{'ssl'};
$cflags .= " -DDBD_DRIZZLE_INSERT_ID_IS_GOOD" if $DBI::VERSION > 1.42;
$cflags .= " -DDBD_NO_CLIENT_FOUND_ROWS" if $opt->{'nofoundrows'};
$cflags .= " -g ";
my %o = ( 'NAME' => 'DBD::drizzle',
      'INC' => $cflags,
      'dist'         => { 'SUFFIX'       => ".gz",
                  'DIST_DEFAULT' => 'all installhtml tardist',
                  'COMPRESS'     => "gzip -9f" },
      'clean' => { 'FILES' => '*.xsi' },
        'realclean' => { 'FILES' => 't/drizzle.mtest' },
          'C' => ["dbdimp.c", "drizzle.c"],
          'XS' => {'drizzle.xs' => 'drizzle.c'},
      'OBJECT' => '$(O_FILES)',
      'LIBS' => $opt->{'libs'},
      'VERSION_FROM' => 'lib/DBD/drizzle.pm'
    );


if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
  $o{'CAPI'} = 'TRUE'
    if ($ExtUtils::MakeMaker::VERSION >= 5.43
    &&  $Config::Config{'archname'} =~ /-object\b/i);
  $o{'AUTHOR'} = 'Patrick Galbraith <patg@patg.net>, Clint Byrum <clint@fewbar.com>';
  $o{'ABSTRACT'} =
    'A libdrizzle driver for the Perl5 Database Interface (DBI)';
  $o{'PREREQ_PM'} = { 'DBI' => 1.08,
              'Data::Dumper' => 0 };
}

ExtUtils::MakeMaker::WriteMakefile(%o);
exit 0;


############################################################################
#
#   Name:    Usage
#
#   Purpose: Print Usage message and exit with error status.
#
############################################################################

sub Usage {
  print STDERR <<"USAGE";
Usage: perl $0 [options]

Possible options are:

  --cflags=<flags>       Use <flags> for running the C compiler; defaults
                         to the value of "pkg-config --cflags" or a guessed
                         value
  --libs=<libs>          Use <libs> for running the linker; defaults
                         to the value of "pkg-config --libs" or a gussed
                         value
  --testdb=<db>          Use the database <db> for running the test suite;
                         defaults to $TESTDB
  --testhost=<host>      Use <host> as a database server for running the
                         test suite; defaults to localhost.
  --testport=<port>      Use <port> as the port number of the database;
                         by default the port number is choosen from the
                         drizzle client library
  --pkg-config=<path>  Specify <path> for pkg-config script
                         (Not supported on Win32)
  --nocatchstderr        Supress using the "myld" script that redirects
                         STDERR while running the linker.
  --nofoundrows          Change the behavior of \$sth->rows() so that it
                               returns the number of rows physically modified 
                               instead of the rows matched
  --bind-type-guessing   Toggle the use of driver attribute mysql_bind_type_guessing 
                         This feature makes it so driver-emulated prepared statements
                         try to "guess" if a value being bound is numeric, in which 
                         case, quotes will not be put around the value.
  --ssl                         Enable SSL support (not supported yet)
  --help                 Print this message and exit

All options may be configured on the command line. If they are
not present on the command line, then pkg-config is called (if
it can be found):

  pkg-config --cflags libdrizzle
  pkg-config --libs libdrizzle

and so on. See the INSTALL.html file for details.
USAGE
  exit 1;
}


############################################################################
#
#   Name:    Configure
#
#   Purpose: Automatic configuration
#
#   Inputs:  $param - Name of the parameter being configured
#
#   Returns: Generated value, never undef
#
############################################################################

sub Configure
{
  my($opt, $source, $param) = @_;

  if ($param eq 'bind-type-guessing') {
    $source->{$param}= ($opt->{$param}) ? "User's choice" : 'default';
    return;
  }
  if (exists($opt->{$param}))
  {
    $source->{$param} = "User's choice";
    return;
  }
  if ($param eq 'testuser') {
        unless ($opt->{$param}) {
            my $user = $ENV{USER} || '';
        print "

PLEASE NOTE:

For 'make test' to run properly, you must ensure that the 
database user '$user' can connect to your MySQL server 
and has the proper privileges that these tests require such 
as 'drop table', 'create table', 'drop procedure', 'create procedure'
as well as others. 

You can also optionally set the user to run 'make test' with:

perl Makefile.PL --testuser=username

";
      $opt->{$param} = $user;
      $source->{$param} = 'guessed';
      }
  }
  if ($param eq "testdb") 
  {
    $source->{$param} = "default";
    $opt->{$param} = $TESTDB;
  }
  if ($param eq "nocatchstderr" || $param eq "nofoundrows")
  {
    $source->{$param} = "default";
    $opt->{$param} = 0;
  }
  elsif ($param eq 'testdb' || $param eq 'testhost') 
  {
  }
  elsif ($param eq 'testpassword') {
      $source->{$param} = "default";
      $opt->{$param} = "";
    
  }
  elsif ($param eq "cflags") 
  {
    $source->{$param} = "guessed";
    my $dir = SearchFor('include/libdrizzle-1.0/libdrizzle', 'drizzle_client.h');
    if ($dir) {
      $dir =~ s/\/libdrizzle$//;
      $opt->{$param} = "-I$dir";
      return;
    }
    die <<"MSG";
Failed to determine directory of drizzle.h. Use

  perl Makefile.PL --cflags=-I<dir>

to set this directory. For details see the INSTALL.html file,
section "C Compiler flags" or type

  perl Makefile.PL --help
MSG
  }
  elsif ($param eq "libs") 
  {
    $source->{$param} = "guessed";

    my @files=();
    my $default_libs;
    $default_libs= "-ldrizzle -lz -lm -lcrypt -lnsl";
    @files = qw(libdrizzle.a libdrizzle.so);

    my $dir = SearchFor('lib', @files);

    if ($dir) {
        $opt->{$param} = "-L$dir $default_libs";
      return;
    }
    my $f = join("|", @files);
    die <<"MSG";
Failed to determine directory of $f. Use

  perl Makefile.PL "--$param=-L<dir> $default_libs"

to set this directory. For details see the INSTALL.html file,
section "Linker flags" or type

  perl Makefile.PL --help
MSG
  } 
  elsif ($param eq "ssl") 
  {
    $opt->{$param} = ($opt->{"libs"} =~ /ssl/) ? 1 : 0;
    $source->{$param} = "guessed";
  } 
  else 
  {
    die "Unknown configuration parameter: $param";
  }
}

my $haveFileSpec;
my $fineDir;
sub SearchFor {
  my($subdir, @files) = @_;
  $haveFileSpec = eval { require File::Spec } unless defined($haveFileSpec);

  my @dirs = ($^O =~ /mswin32/i) ? qw(C:) : qw(/usr/local /usr /usr/local/drizzle /opt);
  unshift(@dirs, $fineDir) if defined($fineDir);

  for my $f (@files) {
    for my $dir (@dirs) {
      my $try1 = $haveFileSpec ?
    File::Spec->catdir($dir, $subdir) : "$dir/$subdir";
      my $try2 = $haveFileSpec ?
    File::Spec->catdir($dir, "drizzle") : "$dir/drizzle";
      my $try3 = $haveFileSpec ?
    File::Spec->catdir($try1, "drizzle") : "$try1/drizzle";
      my $try4 = $haveFileSpec ?
    File::Spec->catdir($try2, $subdir) : "$try2/$subdir";
      for my $path ($try3, $try4, $try2, $try1, $dir) {
    my $file = $haveFileSpec ?
      File::Spec->catfile($path, $f) : "$path/$f";
    if (-f $file) {
      $fineDir = $dir;
      return $path;
    }
      }
    }
  }
}

sub SearchFor2 {
  my($files, $dirs) = @_;

  for my $f (@{$files}) 
  {
    for my $dir (@{$dirs}) 
    {
      my $file = $haveFileSpec ?  File::Spec->catfile($dir, $f) : "$dir/$f";
      if (-f $file) 
      {
        $fineDir = $dir;
        return $dir;
      }
    }
  }
}


sub check_include_version {
  
  my ($dir, $ver) = @_;

  my $headerfile;

  $dir =~ s/-I//;
  $dir =~ s/'//g;
  $dir =~ s/\s.*//g;

  open(HEADERFILE ,"<${dir}/drizzle_version.h") or
  (print "Unable to open header file ${dir}/drizzle_version.h" && exit(0));
  {
    local undef $/;
    $headerfile = <HEADERFILE>;
  }
  close(HEADERFILE);

  my ($version_id) = ($headerfile =~ /DRIZZLE_VERSION_ID[\t\s]+(\d+)[\n\r]/);

  if ($version_id < $ver)
  {
    print  <<"MSG";

Version of Drizzle include files in $dir - $1
MSG
    return 0;
  }
  return 1;
}

sub replace
{
  my ($str, $ref)=@_;

  for my $find (keys %{$ref})
  {
    $str =~ s/$find/$ref->{$find}/g;
  }
  $str;
}

sub prepare_files
{
  my ($files)= @_;
  my $line;
  my @lib;

  for my $file (keys %{$files})
  {

    if ($files->{$file}->{makedir})
    {
      mkpath $files->{$file}->{makedir} or die "Can't create dir $files->{$file}->{makedir}"
      unless (-e $files->{$file}->{makedir} && -d $files->{$file}->{makedir});
    }

    my $replace=$files->{$file}->{replace};

    if ($replace)
    {
       open(FILE, $file) or die "Can't open file $file";
       @lib= map { $replace ? replace($_, $replace) : $_; }  <FILE>;
       close(FILE);

       open(FILE, ">".$files->{$file}->{filename}) or die "Can't open file $files->{$file}->{filename}";
       print FILE @lib;
       close(FILE);
    }
    else
    {
       if(!copy($file, $files->{$file}->{filename}))
       {
         die "Unable to copy $file to $files->{$file}->{filename}\n";
       }
    }
  }
}

package MY;

sub libscan {
    my($self, $path) = @_;
    return '' if $path =~ /\B\.svn\b|~#|\BSCCS\b/;
    $path;
}

sub macro {
  "\n" . DBI::DBD::dbd_postamble(@_) . <<"POSTAMBLE";

installhtml: lib/DBD/drizzle/INSTALL.pod
\tpod2html --infile=lib/DBD/drizzle/INSTALL.pod --outfile=INSTALL.html

POSTAMBLE
};

sub dynamic_lib {
  my $self = shift;
  my $result = $self->SUPER::dynamic_lib(@_);
  if (!$::opt->{nocatchstderr}  &&  $result =~ /\$\(LD\)/) {
    $result =~ s/(\$\(LD\))/\$\(PERL\) myld \$(LD)/sg;
  }
  return $result;
}


