#!/usr/bin/perl -w
use strict;
use CPAN::Util qw(has_cpan has_cpanplus download);
use Getopt::Long;
use constant WIN32 => CPAN::Util::WIN32;

if (WIN32()) {
  require Win32;
  import Win32 qw(MB_ICONSTOP MB_ICONEXCLAMATION);
}

my $title = 'PAR::WebStart CPAN/CPANPLUS install';
my ($dist, $cpanid, $module);
my $result = GetOptions("dist=s" => \$dist,
                        "cpanid=s" => \$cpanid,
                        "module=s" => \$module);
my $use = <<"END";

Usage: $0 --dist=dist-0.1.tar.gz --cpanid=ABC
       $0 --module=ABC::DEF
END

unless (($module or ($dist and $cpanid)) or not $result) {
  error_message($use);
}

my $install;
if ($dist and $cpanid) {
  $cpanid = uc($cpanid);
  error_message(qq{"$dist" does not appear to be a valid distribution name})
    unless $dist =~ m!^[+\-_\.\@0-9\w]+(\.tar\.gz|\.tgz|\.zip)$!;
  error_message(qq{"$cpanid" does not appear to be a valid CPAN id})
    unless $cpanid =~ m!^[-A-Z0-9]+$!;
  $install = download($cpanid, $dist);
}
elsif ($module) {
  error_message(qq{"$module" does not appear to be a valid module name})
    unless $module =~ m!^[A-Za-z0-9\:]+$!;
  $install = $module;
}
else {
  error_message($use);
}

confirm_install($install) or die;

eval {require CPANPLUS::Config;};
if ($@) {
  eval {require CPAN;};
  error_message{q{Must have either CPAN or CPANPLUS available}} if $@;
  error_message(q{Please configure CPAN.pm first.}) unless has_cpan();
  CPAN::Shell->install($install);
}
else {
  error_message(q{Please configure CPANPLUS.pm first.}) unless has_cpanplus();
  require CPANPLUS::Backend;
  my $cp = CPANPLUS::Backend->new(conf => {debug => 0,
                                           verbose => 1});
  $cp->install(modules => [$install]);
}

# comment out the next two lines if you want
# the window to automatically close when done
print "\nPress return to close the window ";
my $ans = <STDIN>;

sub error_message {
   my $msg = shift;
   if (WIN32()) {
     Win32::MsgBox($msg, 0 | MB_ICONSTOP(), $title);
   }
   else {
     warn "\n $msg \n";
     sleep(10);
   }
   die;
}

sub confirm_install {
  my $what = shift;
  if (WIN32()) {
    my $msg = <<"END";
You are about to install "$what".
Press OK to continue, or Cancel to quit.
END
    my $rc = Win32::MsgBox($msg, 1 | MB_ICONEXCLAMATION(), $title);
    return ($rc == 1) ? 1 : 0;
  }
  else {
     print qq{\n\nPreparing to install "$what"\n\n};
     # Comment out the next two lines to proceed immediately
     # with installation without the opportunity for an interrupt
     print "Press Control-C to abort ...\n";
     sleep(7);
  }
}
