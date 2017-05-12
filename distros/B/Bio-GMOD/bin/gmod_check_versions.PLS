#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
$file .= $^O eq 'VMS' ? '.com' : '.pl';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl}
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

use strict;
use Bio::GMOD::Util::CheckVersions;

my $mod = shift or die "Usage: gmod_check_version.pl [mod]  eg WormBase, FlyBase, SGD";

my $gmod = Bio::GMOD::Util::CheckVersions->new(-mod=>$mod);

my %live  = $gmod->live_version();
my %dev   = $gmod->development_version();
my %local = $gmod->local_version();

print "LIVE SITE ($live{url})\n";
print "----------------------------\n";
print_keys(\%live);

print "DEV SITE ($dev{url})\n";
print "----------------------------\n";
print_keys(\%dev);

print "LOCAL INSTALLATION\n";
print "----------------------------\n";
print_keys(\%local);


sub print_keys {
  my $hash = shift;
  print "Status      : $hash->{status}\n";
  print "Title       : $hash->{name}\n";
  print "Version     : $hash->{version}\n";
  print "Released    : $hash->{released}\n\n";
}


!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
