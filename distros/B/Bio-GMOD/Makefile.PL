#!/usr/bin/perl
use lib './install_util';
use ExtUtils::MakeMaker;
use FindBin '$Bin';
use Cwd;

use IO::File;
use Config;
#require 5.005003;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $VERSION = '0.025';

my $working_dir = cwd;

my @OPTIONS = qw(BIN NONROOT MOD CGIBIN);
my $OPTIONS = join ('|',@OPTIONS);
my %OPTIONS;

my @argv = @ARGV;
@ARGV = ();

foreach (@argv) {
  if (/^--?h/i) {
    die <<END;
To customize install locations, provide one or more of the options
LIB, BIN, MOD, CGIBIN as in BIN=/usr/local/bin

By default, scripts will be installed in /usr/local/bin

Specifying the MOD option will cause MOD specific scripts and cgi
scripts to be built.  Specifying the CGIBIN option will cause these
CGIs to be installed in the corresponding path.

To install as a user without root privileges, in addition to the
arguments above, provide the arguments NONROOT=1,
LIB=/path/to/perl/libs and BIN=/path/to/scripts

For example:
    perl Makefile.PL LIB=~/bio-gmod/perllib \\
		     BIN=~/bio-gmod/bin \\
		     NONROOT=1

will perform a non-privileged installation that places all Bio-GMOD
components (including perl libraries) in the path ~/bio-gmod.

END
;
  } elsif (/($OPTIONS)=(.+)/og) {
    $OPTIONS{$1} = interpolate($2);
  } else {
    push @ARGV,$_;
  }
}

if (-e 'Bio-GMOD.def' && !%OPTIONS) {
  print STDERR "\nShould I use your previous settings to set the file paths and options (y/n) [y]? ";
  chomp (my $line = <>);
  if (!$line || $line =~ /^[yY]/) {
    print STDERR "Using previous settings for file paths and options.\n";
    open F,'Bio-GMOD.def' or die "Bio-GMOD.def: $!";
    while (<F>) {
      chomp;
      next if /^\#/;
      next unless /^($OPTIONS)=(.+)/o;
      $OPTIONS{$1} = interpolate($2);
    }
    close F;
  }
}

# Prompt for which monitor scripts to run
prompt_for_monitor();

$OPTIONS{BIN}    ||= $OPTIONS{INSTALLSCRIPT} if exists $OPTIONS{INSTALLSCRIPT};
$OPTIONS{BIN}    ||= '/usr/local/bin';

# look for non-root installation
if (defined $OPTIONS{NONROOT}) {
  $OPTIONS{INSTALLSITEMAN3DIR} = 'none';
  $OPTIONS{INSTALLSITEMAN1DIR} = 'none';
}

# workaround for known bug in FindBin library
$Bin = "." if -f './Makefile.PL' && -T './Makefile.PL';

open F,">$Bin/Bio-GMOD.def" or die "Can't open $Bin/Bio-GMOD.def for writing: $!";
print F "# This hints file contains configuration information used by Bio-GMOD.pm\n\n";
print F "# To reconfigure, run perl Makefile.PL `cat Bio-GMOD.def`\n\n";
foreach (keys %OPTIONS) {
  print F "$_=$OPTIONS{$_}\n";
}
print F "VERSION=$VERSION\n";
close F;

print STDERR <<END;
----------------------------------------------
           Bio::GMOD File Paths

END
;
foreach (@OPTIONS) {
  printf STDERR "%12s %s\n",$_,$OPTIONS{$_};
}
print STDERR <<END;

(Run perl Makefile.PL -h for help on changing)
----------------------------------------------
END
;

my @scripts = qw/
  gmod_check_versions
  gmod_update_installation
  gmod_update_installation-wormbase
  gmod_monitor_installation
  gmod_monitor_installation-wormbase
  gmod_fetch_genes
  gmod_standard_urls
  /;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      NAME         => 'Bio::GMOD',
	      VERSION_FROM => 'GMOD.pm',
	      PREREQ_PM    => {
			       # DBI          => 1.58,
			       LWP::UserAgent => 2.023,
			       MIME::Lite     => 3.01,     # for Email.pm
			       Net::SMTP      => 2.26,
			       #WWW::Mechanize => '1.0',
			      },
	      PL_FILES     => {
			       'bin/gmod_check_versions.PLS'      => 'bin/gmod_check_versions.pl',
			       'bin/gmod_update_installation.PLS' => 'bin/gmod_update_installation.pl',
			       'bin/gmod_monitor_installation.PLS' => 'bin/gmod_monitor_installation.pl',
			       'bin/gmod_monitor_installation-wormbase.PLS' => 'bin/gmod_monitor_installation-wormbase.pl',
			       'bin/gmod_update_installation-wormbase.PLS'  => 'bin/gmod_update_installation-wormbase.pl',
			       'bin/gmod_fetch_genes.PLS'         => 'bin/gmod_fetch_genes.pl',
			       'bin/gmod_standard_urls.PLS'       => 'bin/gmod_standard_urls.pl',
			       'install_util/cgi_install.PLS'     => 'install_util/cgi_install.pl',
			       'cgi-bin/defaults.wormbase.PLS'    => 'cgi-bin/defaults.wormbase',
			       'cgi-bin/version.wormbase.PLS'     => 'cgi-bin/version.wormbase',
			      },
	      EXE_FILES      => [ map { "bin/$_" . '.pl' } @scripts ],
	      LIB            => $OPTIONS{LIB}, # custom location for perl modules
	      DEFINE	     => '',
	      INC	     => '', # e.g., '-I/usr/include/other'
	      INSTALLSCRIPT  => $OPTIONS{BIN} || $OPTIONS{INSTALL_SCRIPT},
              INSTALLSITEMAN1DIR => $OPTIONS{INSTALLSITEMAN1DIR}, # don't install man pages for 
              INSTALLSITEMAN3DIR => $OPTIONS{INSTALLSITEMAN3DIR}, # non-root user

	      ($] >= 5.005
	       ? (ABSTRACT  => 'Methods for maintaining and interacting with Model Organism Databases',
		  AUTHOR    => 'Todd Harris (harris@cshl.edu)')
	       : ()),
	     );



sub prompt_for_monitor {
  print "\n** Bio::GMOD::Monitor Tests ** \n";
  my $proceed = prompt("Do you want to run the Bio::GMOD::Monitor::* tests (further configuration follows) y/n",'n');
  if( $proceed =~ /^[yY]/) {
    prompt_for_monitor_httpd();
    prompt_for_monitor_acedb();
    prompt_for_monitor_mysqld();
  } else {
    if( -e "t/do_monitor_httpd.tests" ) {
      unlink "t/do_monitor_httpd.tests";
    }
  }
}

sub prompt_for_monitor_httpd {
  my $proceed = prompt("Do you want to run the httpd tests (httpd will be restarted; may need su privs) y/n:",'n');
  if( $proceed =~ /^[yY]/) {
    my $apachectl = prompt("  Full path to apachectl:",'/usr/local/apache/bin/apachectl');
    if (open T,">t/do_monitor_httpd.tests") {
      print T $apachectl,"\n";
    }
    close T;
  } else {
    if( -e "t/do_monitor_httpd.tests" ) {
      unlink "t/do_monitor_httpd.tests";
    }
  }
}

sub prompt_for_monitor_acedb {
  my $proceed = prompt("Do you want to run the acedb tests (acedb will be restarted; may need su privs) y/n:",'n');
  if( $proceed =~ /^[yY]/) {
    if (open T,">t/do_monitor_acedb.tests") {
      print T "do_tests\n";
    }
    close T;
  } else {
    if( -e "t/do_monitor_acedb.tests" ) {
      unlink "t/do_monitor_acedb.tests";
    }
  }
}


sub prompt_for_monitor_mysqld {
  my $proceed = prompt("Do you want to run the mysqld tests (mysqld will be restarted; may need su privs) y/n:",'n');
  if( $proceed =~ /^[yY]/) {
#    my $mysqld = prompt("  Full path to safe_mysqld:",'/usr/local/mysql/bin/mysqld_safe');
    my $initd  = prompt("  Full path to mysql init script:",'/etc/rc.d/init.d/mysqld');
    if (open T,">t/do_monitor_mysqld.tests") {
#      print T "mysqld_safe=$mysqld\n";
      print T "mysql_initd=$initd\n";
    }
    close T;
  } else {
    if( -e "t/do_monitor_mysqld.tests" ) {
      unlink "t/do_monitor_mysqld.tests";
    }
  }
}


sub interpolate {
  my $path = shift;
  my ($to_expand,$homedir);
  return $path unless $path =~ m!^~([^/]*)!;
  eval {
    if ($to_expand = $1) {
      $homedir = (getpwnam($to_expand))[7];
    } else {
      $homedir = (getpwuid($<))[7];
    }
    return $path unless $homedir;
    $path =~ s!^~[^/]*!$homedir!;
  };
  return $path;
}

# Customize make clean
sub MY::clean {
  package MY;
  my $inherited = shift->SUPER::clean(@_);
  $inherited .= "\t-\$(PERL) install_util/make_clean_add.pl\n";
  $inherited;
}

#sub MY::dist_dir {
#  package MY;
#  my $inherited = shift->SUPER::dist_dir(@_);
#  $inherited =~ s!^(\s+.+)!\tpod2text docs/pod/INSTALL.pod > INSTALL\n$1!m;
#  $inherited;
#}
#sub MY::processPL {
#  package MY;
#  my $inherited = shift->SUPER::processPL(@_);
#  $inherited =~ s/(cgi-bin\/gbrowse\w*)\s\:\:.+/$1 : FORCE/g;
#  $inherited;
#}

sub MY::install {
  package MY;
  my $inherited = shift->SUPER::install(@_);
  #  $inherited =~ s/doc_install/doc_install conf_install cgi_install htdocs_install/;
  $inherited =~ s/doc_install/doc_install cgi_install/;
  $inherited;
}

sub MY::postamble {
  my $paths;
  for my $key (keys %OPTIONS) {
    $paths .= qq('$key=$OPTIONS{$key}' ) if defined $OPTIONS{$key};
  }
qq{
#conf_install ::
#	\$(PERL) \"$working_dir/install_util/conf_install.pl\" $paths

#htdocs_install ::
#	\$(PERL) \"$working_dir/install_util/htdocs_install.pl\" $paths

cgi_install ::
	\$(PERL) \"$working_dir/install_util/cgi_install.pl\" $paths

};
}

#sub MY::ppd {
#  package MY;
#  my $repository = 'http://www.gmod.org/ggb/ppm';
#  my $arch       = 'MSWin32-x86-multi-thread';
#  my $inherited = shift->SUPER::ppd(@_);

#  my $implementation;
#  my $newimp;
#  my $oldMM =0;

##VERY irritating--different versions of ExtUtils::MakeMaker has
##different ways of generating the ppd file.
#  if ($inherited =~ /qq\{(<S.*R>\\n)\}.*qq\{(\\t<I.*\/>\\n)\}.*qq\{(\\t\\t<O.*G>\\n)\}/sg){
#    $oldMM=1;
#    my $xml = $1.$2.$3;
#    #warn "$xml\n";
#    $inherited =~ s/qq\{.*>>/qq{$xml}" >/s;
#  } elsif ($inherited =~ /NOECHO/) {
#    my @la = split /\n/, $inherited;
#    my $grab = 0;
#    for (@la) {
#      $grab++ if (m!<IMPLEMENTATION>!); 
#      if ($grab and $_ =~ /\'(.*)\'/) {
#        $implementation .= "$1\n";
#      }
#      $grab = 0 if (m!</IMPLEMENTATION>!);
#    } 
#  }

#  if ($oldMM and $inherited =~ /(\s*\<IMPLEMENTATION\>.*\<\/IMPLEMENTATION\>)/m) {
#    $implementation = $newimp = $1;
#    $newimp      =~ s/ARCHITECTURE NAME=\\"\S+\\"/ARCHITECTURE NAME=\\"$arch\\"/;
#    $newimp      =~ s/\$\(OSNAME\)/MSWin32/;
#    my $impl58   = $newimp;
#    $impl58      =~ s/\Q$arch\E/$arch\-5\.8/;
#    $newimp      .= "\\n\\t\\t$impl58";
#    $inherited   =~ s/\Q$implementation\E/$newimp/;
#  } elsif (!$oldMM and $implementation) {
#    $newimp      = $implementation;
#    $newimp      =~ s/ARCHITECTURE NAME="\S+"/ARCHITECTURE NAME="$arch"/;
#    $newimp      =~ s/\$\(OSNAME\)/MSWin32/;
#    my $impl58   = $newimp;
#    $impl58      =~ s/\Q$arch\E/$arch\-5\.8/;
#    $newimp      .= $impl58;
#    my @la       = split /\n/, $newimp;
#    for my $line (@la) {
#      $line = qq{\t\$(NOECHO) \$(ECHO) '$line' >> \$(DISTNAME).ppd}; 
#    }

#    my @inherit_array = split /\n/, $inherited;
#    my @newinherit;
#    $inherited = '';
#    for (@inherit_array) {
#      if (/<IMPLEMENTATION>/) {
#        push @newinherit, @la;
#        last;
#      } else {
#        push @newinherit, $_; 
#      }
#    }
#    push @newinherit, qq{\t\$(NOECHO) \$(ECHO) '</SOFTPKG>' >> \$(DISTNAME).ppd\n};
#    $inherited = join "\n", @newinherit;
#  }

#  $inherited .= <<END;

#	\@echo "creating Generic-Genome-Browser.ppd"
#	\@echo "creating gbrowse_ppm_support_files-$VERSION.tar.gz"
#	\@\$(TAR) zcf gbrowse_ppm_support_files-$VERSION.tar.gz --exclude CVS --exclude '*~' --exclude '*.PLS' --exclude '.*' --exclude README --exclude '#*' DISCLAIMER INSTALL docs htdocs conf cgi-bin install_util sample_data contrib
#	\@echo "creating gbrowse_ppm-$VERSION.tar.gz"
#	\@\$(TAR) zcf gbrowse_ppm-$VERSION.tar.gz --exclude man1 --exclude man3 blib
#	\@perl -pi -e 's!HREF=""!HREF="$repository/gbrowse_ppm-$VERSION.tar.gz"!' Generic-Genome-Browser.ppd
#	\@perl -pi -e 's!(\\s*</IMPLEMENTATION>)!\\t\\t<INSTALL HREF="$repository/gbrowse_ppm_install.pl" EXEC="PPM_PERL" />\\n\\1!' Generic-Genome-Browser.ppd
#	\@perl -pi -e 's!Bio-Perl!bioperl!' Generic-Genome-Browser.ppd
#END
#;
#}
