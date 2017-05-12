#!/usr/bin/perl -w
# use strict;
use LWP::Simple qw(mirror);


mirror("http://www.cpan.org/modules/03modlist.data.gz", "modlist.data.gz");
system("gzip -dc modlist.data.gz > modlist.data");
open M, "<modlist.data";

# this is pretty dumb, but whatever
my $moddata = "";
while (<M>) {
  next unless $moddata or m/^\s*package/;
  $moddata .= $_; 
}

#print $list;

eval $moddata; 

my $list = ""; 

my $modules = CPAN::Modulelist->data;
for my $m (sort keys %$modules) {
  my $d = $modules->{$m};
  $list .= "$m\n\n" unless $d->{statd} =~ m/^[icS]$/;
}

my $bundle;
{ 
  local $/ = undef;
  open E, "<Everything.pm";
  $bundle = <E>;
  close E;

}

$bundle =~ s/=head1 CONTENTS.*?=head1/=head1 CONTENTS\n$list=head1/s;
open E, ">Everything.pm";
print E $bundle;
close E;

__END__

# crap to read packages.txt - too much bad data there

open P, "<modlist.txt" or die "could not open packages.txt";

my $body = 0;
while (<P>) {
  chomp;
  $body++ if $_ eq "";
  next unless $_ and $body;

#  next if $_ =~ m!/perl5.*tar.gz$!;
#  next if $_ =~ m/(AuthenIMAP.pm.gz|(lot|examples|bid|Tree|CGISession|emergencyrelease|CECALA|DBIx-HTMLView-LATEST|former-0.2beta).tar.gz)$/;
#  next if m!/scripts/!;

  print "[$_]\n";
  my ($module, $dist) = (split /\s+/)[0,2];
  $dist =~ s!.*/([^/]+)$!$1!;
  my ($dist_name, $dist_version) = ($dist =~ m/(.*?)[_.-]V?(\d+(\.\d+){0,2}(_\d+)?([a-z]\d*?)?)(Beta)?.(tar.gz|zip|tgz)$/);
  #print "MOD: $module, dist_name: $dist_name / dist_version: $dist_version\n";
  die "no dist_name or version for $module [$_]" unless $dist_name and $dist_version;
  $body++;
#  last if $body > 10;

}

