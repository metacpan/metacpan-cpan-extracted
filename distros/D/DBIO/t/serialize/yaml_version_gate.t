use strict;
use warnings;

use Test::More;
use File::Temp ();
use File::Spec;
use lib 't/lib';
use TestDBIO::Child;

# DBIO::InflateColumn::Serializer::YAML loads a stored value with
# $YAML::LoadBlessed = 0, a variable YAML knows from 1.25 on. With an older
# YAML that assignment does nothing and stored objects would come back
# blessed. So the module refuses to load with an older YAML, instead of
# quietly doing less than it says. YAML is stubbed in a temporary lib, in a
# child perl, so the verdict does not depend on the YAML installed here.

my $tmp = File::Temp->newdir;

sub load_with_yaml_version {
  my ($version) = @_;

  my $lib = File::Spec->catdir($tmp, "yaml-$version");
  mkdir $lib or die "mkdir $lib: $!";
  open my $fh, '>', File::Spec->catfile($lib, 'YAML.pm') or die "write stub: $!";
  print {$fh} "package YAML;\nour \$VERSION = '$version';\nsub Dump { '' }\nsub Load { undef }\n1;\n";
  close $fh or die "close stub: $!";

  my $report = File::Spec->catfile($tmp, "report-$version");
  my $run = TestDBIO::Child::run_perl(
    code => q{
    my $report = shift;
    my $ok = eval { require DBIO::InflateColumn::Serializer::YAML; 1 };
    open my $out, '>', $report or die $!;
    print {$out} $ok ? "loaded\n" : "died: $@";
    },
    inc  => [ $lib, grep { !ref } @INC ],
    args => [$report],
  );
  $run->{status} == 0 or die "child perl failed: $run->{status}";

  open my $in, '<', $report or die "read report: $!";
  local $/;
  return scalar <$in>;
}

like load_with_yaml_version('1.24'), qr/\Adied: .*YAML version 1\.25 required.*1\.24/s,
  'an older YAML stops the module at load, naming the version needed and the one found';

is load_with_yaml_version('1.25'), "loaded\n", 'YAML 1.25 is accepted';

done_testing;
