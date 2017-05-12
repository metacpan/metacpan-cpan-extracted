use Config;
use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use File::Path;
require 5.8.0;

my $choice;
while (!$choice) {
  $reply = prompt(
		  "\nWhat do you want to build?\n\n" .
		  "  1) Interface to Ace socket server and local databases (pure Perl)\n" .
		  "  2) The above plus XS optimizations (requires C compiler)\n" .
		  "  3) The above plus RPC server interface (requires C compiler)\n\n" .
		  "Enter your choice: ", "1");
  if ($reply =~ /(\d+)/) {
    $choice = $1;
    die "invalid choice: $choice!" if $choice < 1  ||  $choice > 3;
  }
}
$choice ||= 1; # safe default


my @extlib = ();
push @extlib,'Freesubs' if $choice >= 2;
push @extlib,'RPC'      if $choice >= 3;

print "\n";
setup_sitedefs() if prompt("Do you want to install Ace::Browser? ","n") =~ /[yY]/;

my $headers  = "./acelib/wh";
WriteMakefile(
	      'DISTNAME'     => 'AcePerl',
	      'NAME'	     => 'Ace',
	      'VERSION_FROM' => 'Ace.pm', # finds $VERSION
	      'PMLIBDIRS'    => ['GFF','Ace'],
	      'DIR'          => \@extlib,
	      'DEFINE'	     => '',
	      'XSPROTOARG'   => '-noprototypes',
	      'INC'	     => "-I$headers",
	      PREREQ_PM      => {
				 'Digest::MD5'   => 2.0,
				 'Cache::Cache'  => 1.03,
				},
	      'dist'         => {'COMPRESS'=>'gzip -9f', 
                                 'SUFFIX' => 'gz',
	                         'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'
			      },
	      PL_FILES => {'make_docs.PLS' => '.docs',
			   'util/install.PLS'=>'util/install.pl',
			   'util/ace.PLS'=>'util/ace.pl',
			  },
	      EXE_FILES => ['util/ace.pl'],
	      'clean'        => {'FILES' => 'acelib/lib* acelib/*.o acelib/rpcace*.[ch]'},
);

exit 0;

sub setup_sitedefs {
  my ($conf_path,$cgi_path,$html_path);
  eval 'use Ace::Browser::LocalSiteDefs qw($SITE_DEFS $CGI_PATH $HTML_PATH)';
  if ($SITE_DEFS) {
    print "\n";
    print "You have installed Ace::Browser before, using old settings for defaults.\n";
    $conf_path = $SITE_DEFS;
    $cgi_path  = $CGI_PATH;
    $html_path = $HTML_PATH;
  }
  $conf_path ||= '/usr/local/apache/conf/ace';
  $cgi_path  ||= '/usr/local/apache/cgi-bin/ace';
  $html_path ||= '/usr/local/apache/htdocs/ace';

  get_path("site-specific configuration files",\$conf_path);
  get_path("acebrowser CGI scripts",\$cgi_path);
  get_path("acebrowser HTML files and images",\$html_path);

  open F,">Ace/Browser/LocalSiteDefs.pm" or die "Ace/Browser/LocalSiteDefs.pm: $!";
  print F <<END;

# Globals for Ace::Browser::SiteDefs
# these get loaded into whatever package requires them (old style)
package Ace::Browser::LocalSiteDefs;
require Exporter;
\@ISA = qw(Exporter);
\@EXPORT   = qw();
\@EXPORT_OK = qw(\$SITE_DEFS \$CGI_PATH \$HTML_PATH);
\$SITE_DEFS = '$conf_path';
\$CGI_PATH  = '$cgi_path';
\$HTML_PATH = '$html_path';
1;
__END__
=head1 NAME

Ace::Browser::LocalSiteDefs - Master Configuration file for AceBrowser

=head1 SYNOPSIS

 use Ace::Browser::LocalSiteDefs qw($SITE_DEFS $HTML_PATH $CGI_PATH);

=head1 DESCRIPTION

This file, which is created at install time, defines three exportable
variables:

 $SITE_DEFS   Location of the directory that hold's AceBrowser's database-specific
              configuration files, e.g. /usr/local/apache/conf/ace/

 $HTML_PATH   Location of AceBrowser's HTML files and images, e.g. ~www/htdocs/ace/

 $CGI_PATH    Location of AceBrowser's CGI scripts, e.g. ~www/cgi-bin/ace/

=head1 SEE ALSO

L<Ace>

=head1 AUTHOR

Lincoln Stein <lstein\@cshl.org>

Copyright (c) 1997-1998 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut


END
  close F;

  eval <<END;
sub MY::postamble {
'
install-browser :
	util/install.pl acebrowser/htdocs $html_path
	util/install.pl acebrowser/cgi-bin $cgi_path
	util/install.pl acebrowser/conf $conf_path
	mkdir $html_path/images
	chmod go+rwx $html_path/images
';
}
END
   print qq(\n*** After "make install", run "make install-browser" to install acebrowser files. ***\n\n);
}

sub get_path {
  my ($description,$pathref) = @_;

  $$pathref = expand_twiddles(prompt("Directory for the $description (~username ok):",$$pathref));
  return if -d $$pathref;
  return if prompt("$$pathref does not exist.  Shall I create it for you?",'y') !~ /[yY]/;
  mkpath($$pathref) or warn "Couldn't create $$pathref. Please create it before installing.\n";
}

sub expand_twiddles {
  my $path = shift;
  my ($to_expand,$homedir);
  return $path unless $path =~ m!^~([^/]*)!;

  if ($to_expand = $1) {
    $homedir = (getpwnam($to_expand))[7];
  } else {
    $homedir = (getpwuid($<))[7];
  }
  return $path unless $homedir;

  $path =~ s!^~[^/]*!$homedir!;
  return $path;
}
