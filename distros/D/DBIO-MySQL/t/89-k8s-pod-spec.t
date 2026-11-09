use strict;
use warnings;

# xbin/dbio-mysql-k8s builds its database pod in _pod_spec. That pod must carry
# the cpu AND memory requests and limits, and the credentials, of the checked-in
# manifest maint/k8s/mariadb.yaml (house rule "Live testing", point 4; karr k85).
# Compared against the manifest itself, so neither side can drift alone.
#
# Offline: the script is loaded with do FILE (its main runs only when it is
# the program), with its two Kubernetes modules stubbed -- nothing is contacted.

use Test::More;
use CPAN::Meta::YAML;

my $script   = 'xbin/dbio-mysql-k8s';
my $manifest = 'maint/k8s/mariadb.yaml';

plan skip_all => "$script / $manifest not present (built dist)"
  unless -f $script && -f $manifest;

# The script `use`s these; only their names are needed to compile it.
$INC{'Kubernetes/REST/Kubeconfig.pm'} = __FILE__;
$INC{'IO/K8s.pm'}                     = __FILE__;

{
  local @ARGV;
  my $ok = do "./$script";
  die "loading $script failed: " . ($@ || $! || 'false return') unless $ok;
}

my $yaml = do {
  open my $fh, '<', $manifest or die "$manifest: $!";
  local $/;
  CPAN::Meta::YAML->read_string(<$fh>) or die CPAN::Meta::YAML->errstr;
};
my ($pod) = grep { ($_->{kind} // '') eq 'Pod' } @$yaml;
ok $pod, "$manifest carries a Pod";
my $want = $pod->{spec}{containers}[0];

my $spec = main::_pod_spec('dbio-test', 'dbio-mariadb', 'mariadb:11');
my ($got) = @{ $spec->{spec}{containers} };

for my $kind (qw(requests limits)) {
  for my $res (qw(cpu memory)) {
    ok defined $want->{resources}{$kind}{$res},
      "manifest declares resources.$kind.$res";
    is $got->{resources}{$kind}{$res}, $want->{resources}{$kind}{$res},
      "pod resources.$kind.$res matches the manifest";
  }
}

# Same credentials: the script passes MYSQL_*, the manifest MARIADB_* (the
# mariadb image takes both).
my %want_env = map { $_->{name} => $_->{value} } @{ $want->{env} };
my %got_env  = map { $_->{name} => $_->{value} } @{ $got->{env} };
for my $var (qw(USER PASSWORD ROOT_PASSWORD DATABASE)) {
  is $got_env{"MYSQL_$var"}, $want_env{"MARIADB_$var"},
    "MYSQL_$var matches the manifest's MARIADB_$var";
}

done_testing;
