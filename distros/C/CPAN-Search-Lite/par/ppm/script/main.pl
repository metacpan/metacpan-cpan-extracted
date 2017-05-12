#!/usr/bin/perl -w
use strict;
use PPM::Reps qw($reps);
use Getopt::Long;
use File::Which;
use Config;

unless ($^O eq 'MSWin32') {
  warn "This script is intended for Win32 only";
  sleep(10);
  die;
}

require Win32;
import Win32 qw(MB_ICONSTOP MB_ICONEXCLAMATION);
my $title = 'PAR::WebStart ppm install';

my ($dist, $rep);
my $use = qq{Usage: $0 --dist=dist_name --rep=rep_alias};
my $result = GetOptions("dist=s" => \$dist,
                        "rep=s" => \$rep);
unless ( ($dist and $rep) or not $result ) {
  error_message($use);
}

my $info;
if ($dist and $rep) {
  error_message(qq{"$dist" does not appear to be a valid distribution name})
    unless $dist =~ m!^[+\-_\.\@0-9\w]+$!;
  error_message(qq{"$rep" does not appear to be a valid repository alias})
    unless $rep =~ m!^[a-zA-Z0-9]+$!;
  $info = $reps->{$rep};
  error_message(qq{No information for the "$rep" repository available})
    unless $info;
}
else {
  error_message($use);
}

my $perl_version = "5.$Config{PERL_VERSION}";
my $rep_version = $info->{PerlV};
unless ($perl_version eq $rep_version) {
  error_message(qq{Your perl version ($perl_version) does not match the repository version ($rep_version) for $rep.});
}

confirm_install($info, $dist);

my $ppm = which('ppm');
unless ($ppm) {
  error_message(qq{Could not find 'ppm' in yor PATH});
}

my @args = ($ppm, 'install');
my $what;
if ($rep eq 'AS56' or $rep eq 'AS58') {
  $what = $dist;
}
else {
  $what = sprintf("%s/%s.ppd", $info->{location}, $dist);
}
push @args, $what;
print "@args\n";
unless (system(@args) == 0) {
  error_message(qq{system @args failed: $?});
}

# comment out the next two lines if you want
# the window to automatically close when done
print "\nPress return to close the window ";
my $ans = <STDIN>;

sub error_message {
  my $msg = shift;
  Win32::MsgBox($msg, 0 | MB_ICONSTOP(), $title);
  die;
}

sub confirm_install {
  my ($info, $dist) = @_;
  my $msg = <<"END";
You are about to install "$dist" from
  $info->{location} ($info->{desc})
Press OK to continue, or Cancel to quit.
END
  my $rc = Win32::MsgBox($msg, 1 | MB_ICONEXCLAMATION(), $title);
  die unless ($rc == 1);
}

