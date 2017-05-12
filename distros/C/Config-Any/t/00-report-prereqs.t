use strict;
use warnings;

if (!eval { require ExtUtils::MakeMaker }) {
  print "1..0 # SKIP ExtUtils::MakeMaker not available\n";
  exit 0;
}

print "1..1\n";
print "ok 1\n";
print STDERR "#\n# Optional Prereq Versions:\n";
for my $module (qw(
  Config::General
  Config::Tiny
  Cpanel::JSON::XS
  JSON::MaybeXS
  JSON::DWIW
  JSON::XS
  JSON::Syck
  JSON::PP
  JSON
  XML::Simple
  XML::NamespaceSupport
  YAML::XS
  YAML::Syck
  YAML
)) {
  my $file = "$module.pm";
  $file =~ s{::}{/}g;
  my ($full_file) = grep -e, map "$_/$file", @INC;
  my $v;
  if (defined $full_file) {
    $v = MM->parse_version($full_file);
  }
  else {
    $v = 'missing';
  }
  printf STDERR "#   %-25s %s\n", $module, $v;
}
print STDERR "#\n";
