use strict;
use warnings;

use Test::More;

use File::Temp ();
use FindBin ();
use JSON::MaybeXS ();
use POSIX ();

use DBIO::Util qw(file_path mkpath slurp_file write_file);

# maint/live-preflight is run before every live suite, and its answer is acted
# on unread: exit 0 starts the run. So it is held to both directions here. On
# the project namespace as it stands on a good day -- eight capped, Ready
# databases behind one LoadBalancer address, reached with an account that may
# neither read nodes nor list across namespaces -- it has to say 0, or it is
# skipped as noise (which is what it was before karr k320: red against a
# healthy cluster on every run). And each thing that makes a live run
# misleading or leaves a mess has to turn it to 1, naming the object and the
# command; "could not look" is 2 and never 0.
#
# No cluster is touched: kubectl and ip are stand-ins, and they are the only
# things in PATH, so a preflight that reaches for anything else finds nothing.

my $preflight = file_path($FindBin::Bin, '..', '..', 'maint', 'live-preflight');

plan skip_all => 'maint/live-preflight is a repository tool and not part of the shipped dist'
  unless -f $preflight;

my $JSON = JSON::MaybeXS->new(canonical => 1, convert_blessed => 1);

my $tmp = File::Temp->newdir;
my $bin = file_path($tmp, 'bin');
mkpath($bin);

sub stand_in {
  my ($name, $body) = @_;
  my $path = file_path($bin, $name);
  write_file($path, "#!$^X\nuse strict;\nuse warnings;\n"
    . "my \$dir = \$ENV{PREFLIGHT_FAKE} or die \"stand-in $name: PREFLIGHT_FAKE is not set\\n\";\n"
    . "{ open my \$log, '>>', \"\$dir/calls\" or die \$!;\n"
    . "  print {\$log} join(\"\\t\", '$name', 'KUBECONFIG=' . (\$ENV{KUBECONFIG} // ''), \@ARGV), \"\\n\" }\n"
    . "sub answer { open my \$fh, '<', \"\$dir/\$_[0]\" or return; local \$/; <\$fh> }\n"
    . $body);
  chmod 0755, $path or die "chmod: $!";
}

# kubectl as the project account sees the cluster: one namespace, and nothing
# beyond it -- no nodes, no namespaces, nothing "-A". It answers a JSON `get`
# of pods, services, jobs and resource quotas with the objects of the case, and
# nothing else at all.
stand_in('kubectl', <<'FAKE');
my @args = grep { !/^--request-timeout=/ } @ARGV;

if (defined(my $error = answer('kubectl-error'))) {
  print STDERR $error;
  exit 1;
}

sub forbidden {
  print STDERR qq{Error from server (Forbidden): $_[0] is forbidden: User }
    . qq{"system:serviceaccount:dev-dbio:agent-dbio" cannot list resource "$_[0]" }
    . qq{in API group "" at the cluster scope\n};
  exit 1;
}

my $verb = shift @args // '';
if ($verb ne 'get') {
  print STDERR "stand-in kubectl: only `get` is answered, not `$verb @args`\n";
  exit 64;
}

forbidden('pods') if grep { $_ eq '-A' or $_ eq '--all-namespaces' } @args;

my %kind = (
  pods => 'Pod', services => 'Service', jobs => 'Job', resourcequotas => 'ResourceQuota',
);
my @asked = split /,/, shift @args // '';
for my $resource (@asked) {
  forbidden($resource) if $resource eq 'nodes' or $resource eq 'namespaces';
  next if $kind{$resource};
  print STDERR "stand-in kubectl: no answer for `get $resource`\n";
  exit 64;
}
if ("@args" ne '-o json') {
  print STDERR "stand-in kubectl: `get @asked` is answered as `-o json` only, not `@args`\n";
  exit 64;
}

require JSON::MaybeXS;
my $json = JSON::MaybeXS->new(canonical => 1);
my %want = map { $kind{$_} => 1 } @asked;
print $json->encode({
  apiVersion => 'v1',
  kind       => 'List',
  items      => [ grep { $want{ $_->{kind} } } @{ $json->decode(answer('objects')) } ],
});
FAKE

# ip: `ip route get ADDRESS`, answered with the route of the case.
stand_in('ip', <<'FAKE');
if ("@ARGV[0, 1]" ne 'route get') {
  print STDERR "stand-in ip: only `route get` is answered, not `@ARGV`\n";
  exit 64;
}
my $route = answer('route') // '';
if ($route !~ /\S/) {
  print STDERR "RTNETLINK answers: Network is unreachable\n";
  exit 2;
}
print "$ARGV[2] $route\n    cache\n";
FAKE

# ------------------------------------------------------------ the objects

my $NS = 'dev-dbio';
my $LB = '10.5.10.71';

sub pod {
  my ($name, %o) = @_;
  my @limits = @{ $o{limits} // [ { cpu => '1', memory => '1Gi' } ] };
  return {
    kind     => 'Pod',
    metadata => {
      name      => $name,
      namespace => $NS,
      labels    => $o{labels} // {},
      ( $o{terminating} ? ( deletionTimestamp => '2026-10-07T20:00:00Z' ) : () ),
      ( $o{owner} ? ( ownerReferences => [ { kind => $o{owner}[0], name => $o{owner}[1] } ] ) : () ),
    },
    spec => {
      containers => [
        map { { name => "c$_", resources => { limits => $limits[$_] } } } 0 .. $#limits
      ],
    },
    status => {
      phase      => $o{phase} // 'Running',
      conditions => [
        { type => 'PodScheduled', status => 'True' },
        { type => 'Ready', status => ( $o{ready} // 1 ) ? 'True' : 'False' },
      ],
    },
  };
}

# A standing database, as the manifests of the family label it.
sub database {
  my ($name, %o) = @_;
  return pod($name, labels => { app => $name, role => 'dbio-test-db' }, %o);
}

sub service {
  my ($name, $address) = @_;
  return {
    kind     => 'Service',
    metadata => { name => $name, namespace => $NS },
    spec     => { type => $address ? 'LoadBalancer' : 'ClusterIP' },
    status   => {
      loadBalancer => $address ? { ingress => [ { ip => $address, ipMode => 'VIP' } ] } : {},
    },
  };
}

sub quota {
  my (%used) = @_;
  my %hard = (
    'limits.memory' => '32Gi', 'requests.cpu' => '8', 'requests.memory' => '24Gi',
    'services.loadbalancers' => '10',
  );
  return {
    kind     => 'ResourceQuota',
    metadata => { name => 'grenzen', namespace => $NS },
    status   => {
      hard => \%hard,
      used => {
        'limits.memory' => '15872Mi', 'requests.cpu' => '2600m', 'requests.memory' => '6784Mi',
        'services.loadbalancers' => '8', %used,
      },
    },
  };
}

my @DATABASES = qw(
  dbio-ase dbio-clickhouse-db dbio-firebird dbio-mariadb
  dbio-oracle dbio-postgresql mssql-dev-0 mysql
);

# The namespace on a good day (2026-10-07): eight databases, each capped and
# Ready, each behind a LoadBalancer service on the one project address.
sub healthy {
  return (
    ( map { database($_) } @DATABASES ),
    ( map { service("$_-svc", $LB) } @DATABASES ),
    quota(),
  );
}

my $GOOD_ROUTE = 'dev ens18 src 10.5.10.37 uid 1000';

# preflight(%case): run it against the case. objects => [...], route => '...',
# kubectl_error => '...' (kubectl fails with it), env => { ... }, path => '...'.
my $case_no = 0;
sub preflight {
  my (%case) = @_;

  my $dir = file_path($tmp, 'case' . ++$case_no);
  mkpath(file_path($dir, 'home', '.kube'));
  write_file(file_path($dir, 'objects'), $JSON->encode($case{objects} // [ healthy() ]));
  write_file(file_path($dir, 'route'), $case{route} // $GOOD_ROUTE);
  write_file(file_path($dir, 'kubectl-error'), $case{kubectl_error})
    if defined $case{kubectl_error};
  write_file(file_path($dir, 'home', '.kube', 'cihq-dev-dbio.yaml'), "# project access\n")
    if $case{project_access};

  my %env = (
    PATH                 => $case{path} // $bin,
    HOME                 => file_path($dir, 'home'),
    PREFLIGHT_FAKE       => $dir,
    KUBECONFIG           => undef,
    DBIO_TEST_KUBECONFIG => undef,
    %{ $case{env} // {} },
  );
  my ($out, $err) = map { file_path($dir, $_) } qw(stdout stderr);

  my $pid = fork // die "fork: $!";
  if (!$pid) {
    for my $name (keys %env) {
      defined $env{$name} ? ($ENV{$name} = $env{$name}) : delete $ENV{$name};
    }
    open STDOUT, '>', $out or POSIX::_exit(126);
    open STDERR, '>', $err or POSIX::_exit(126);
    { no warnings 'exec'; exec { $^X } $^X, $preflight }
    POSIX::_exit(126);
  }
  waitpid $pid, 0;

  my $calls = file_path($dir, 'calls');
  return {
    exit  => ($? & 127) ? 128 + ($? & 127) : $? >> 8,
    said  => slurp_file($out) . slurp_file($err),
    home  => file_path($dir, 'home'),
    calls => [ -e $calls ? ( map { [ split /\t/ ] } split /\n/, slurp_file($calls) ) : () ],
  };
}

sub finding_ok {
  my ($got, $name, @like) = @_;
  subtest $name => sub {
    is $got->{exit}, 1, 'exit 1';
    like $got->{said}, qr/^PREFLIGHT FAILED/m, 'and it says not to start';
    unlike $got->{said}, qr/preflight clear/, 'not that it is clear';
    like $got->{said}, $_->[0], $_->[1] for @like;
  } or diag "exit $got->{exit}\n$got->{said}";
}

sub cannot_check_ok {
  my ($got, $name, @like) = @_;
  subtest $name => sub {
    is $got->{exit}, 2, 'exit 2, "could not look"';
    unlike $got->{said}, qr/preflight clear/, 'which is not a pass';
    like $got->{said}, qr/NOT a pass/, 'and says so';
    like $got->{said}, $_->[0], $_->[1] for @like;
  } or diag "exit $got->{exit}\n$got->{said}";
}

# ------------------------------------------------- the namespace on a good day

my $good = preflight();

subtest 'eight capped, Ready databases, seen with the project account: clear' => sub {
  is $good->{exit}, 0, 'exit 0';
  like $good->{said}, qr/^preflight clear .*safe to start/m, 'it says the run may start';
  unlike $good->{said}, qr/^(FAIL|WARN)/m, 'with no finding and no warning';

  # Several databases at once is the normal state of the namespace, not the
  # violation the old one-database rule made of it. What is up is listed, so
  # that a database nobody expected is seen.
  like $good->{said}, qr/\b8 database\S* Ready\b/, 'eight databases are counted, not objected to';
  like $good->{said}, qr/\b\Q$_\E\b/, "$_ is named" for @DATABASES;

  like $good->{said}, qr/namespace \Q$NS\E\b/, 'the namespace it looked at is named';
  like $good->{said}, qr/route to \Q$LB\E goes via ens18/, 'the route to the project address is shown';
  like $good->{said}, qr{limits\.memory 15872Mi/32Gi}, 'the quota is shown as used/hard';
} or diag "exit $good->{exit}\n$good->{said}";

subtest 'it reads, and only its own namespace' => sub {
  my @kubectl = grep { $_->[0] eq 'kubectl' } @{ $good->{calls} };
  cmp_ok scalar @kubectl, '>', 0, 'kubectl was asked';
  for my $call (@kubectl) {
    my (undef, undef, @args) = @$call;
    my ($verb) = grep { !/^-/ } @args;
    is $verb, 'get', "kubectl @args";
    is_deeply [ grep { /^(-A|--all-namespaces|-n|--namespace(=.*)?)$/ } @args ], [],
      'the namespace is the one of the kubeconfig context, never another';
  }
};

# ------------------------------------------------------------------ findings

# The LimitRange of the project namespace fills in a missing limit, so there a
# pod like this cannot exist. This is the check for everywhere else, and for
# the day the LimitRange is gone: an uncapped database is what took a host
# down once.
finding_ok(
  preflight(objects => [
    healthy(),
    database('stray-db', limits => [ {} ]),
    database('half-db', limits => [ { memory => '1Gi' } ]),
    database('side-db', limits => [ { cpu => '1', memory => '1Gi' }, { cpu => '1' } ]),
  ]),
  'a container without a cpu and a memory limit',
  [ qr/^FAIL .*\b3 pods?\b.*limit/m, 'the finding counts the pods' ],
  [ qr/\bstray-db\b.*\bcpu\b.*\bmemory\b/, 'a pod with no limit at all is named with both' ],
  [ qr/\bhalf-db\b.*\bcpu\b/, 'one that caps memory only is named with cpu' ],
  [ qr/\bside-db\b.*\bc1\b.*\bmemory\b/, 'and an uncapped second container is not hidden by the first' ],
  [ qr/kubectl -n \Q$NS\E delete pod stray-db\b/, 'with the command that removes it' ],
);

# A suite against a database that is not Ready fails with connection errors
# that read like a driver bug. One that is being deleted still reports Ready
# while it goes.
finding_ok(
  preflight(objects => [
    ( grep { $_->{metadata}{name} !~ /^dbio-(oracle|firebird)$/ } healthy() ),
    database('dbio-oracle', ready => 0),
    database('dbio-firebird', terminating => 1),
  ]),
  'a database that is not Ready',
  [ qr/^FAIL .*\b2 database\S* not Ready/m, 'the finding' ],
  [ qr/^\s+dbio-oracle\b/m, 'names the one that is not Ready' ],
  [ qr/^\s+dbio-firebird\b.*Terminating/m, 'and the one that is being deleted' ],
  [ qr/\b6 database\S* Ready\b/, 'and still lists the six that are' ],
  [ qr/kubectl -n \Q$NS\E describe pod dbio-oracle\b/, 'with the command that says why' ],
);

# What an interrupted DBIO::Test::Kubernetes run leaves in an existing
# namespace: its pod carries the run label, its service and its job only the
# run id in their names. The pod of the job is the job's to delete.
my @leftover = (
  pod('dbio-test-ab12cd34-pg', labels => { 'dbio-test-run' => 'ab12cd34', 'dbio-test-db' => 'pg' }),
  service('dbio-test-ab12cd34-pg-svc'),
  { kind => 'Job', metadata => { name => 'dbio-test-ab12cd34-runner', namespace => $NS } },
  pod('dbio-test-ab12cd34-runner-x7k2p',
    labels => { 'job-name' => 'dbio-test-ab12cd34-runner' },
    owner  => [ Job => 'dbio-test-ab12cd34-runner' ],
    phase  => 'Succeeded',
    ready  => 0,
  ),
);

my $left = preflight(objects => [ healthy(), @leftover ]);
finding_ok(
  $left,
  'what a DBIO::Test::Kubernetes run left behind',
  [ qr/^FAIL .*\b3 objects?\b.*DBIO::Test::Kubernetes/m, 'the finding counts pod, service and job' ],
  [ qr{kubectl -n \Q$NS\E delete pod/dbio-test-ab12cd34-pg service/dbio-test-ab12cd34-pg-svc job/dbio-test-ab12cd34-runner$}m,
    'with one delete that names exactly these three' ],
  [ qr/\b8 database\S* Ready\b/, 'and the standing databases are not counted among them' ],
);
unlike $left->{said}, qr/not Ready/,
  'the finished pod of the job is not taken for a database that is down';

# The address of the project is reached from this machine by plain routing. A
# local docker network that covers it takes the route, and the databases then
# look dead from here while they are fine (the dbio-mssql k20 failure, moved
# from the pod range to the project address).
finding_ok(
  preflight(route => 'dev br-0123456789ab src 10.5.10.1 uid 1000'),
  'the route to the project address goes into a docker network',
  [ qr/^FAIL .*route to \Q$LB\E goes via br-0123456789ab/m, 'the finding names address and bridge' ],
  [ qr/docker network rm 0123456789ab\b/, 'with the command that removes the network' ],
);

finding_ok(
  preflight(route => 'dev docker0 src 10.5.0.1 uid 1000'),
  'the route to the project address goes into the default docker bridge',
  [ qr/^FAIL .*route to \Q$LB\E goes via docker0/m, 'the finding names address and bridge' ],
  [ qr{/etc/docker/daemon\.json}, 'and where its range is set' ],
);

finding_ok(
  preflight(route => ''),
  'there is no route to the project address',
  [ qr/^FAIL .*no route to \Q$LB\E/m, 'the finding names the address' ],
  [ qr/Network is unreachable/, 'with what the kernel answered' ],
);

# ------------------------------------------------------- warnings, not findings

# A full quota does not touch a suite that runs against a standing database,
# and a run that starts pods of its own is told by the API, by name, at the
# first create. So it is said, and it does not stop the run.
my $full = preflight(objects => [
  ( grep { $_->{kind} ne 'ResourceQuota' } healthy() ),
  quota('requests.memory' => '24576Mi', 'services.loadbalancers' => '10'),
]);
subtest 'a quota that is used up is a warning' => sub {
  is $full->{exit}, 0, 'exit 0';
  like $full->{said}, qr/^WARN .*\brequests\.memory\b/m, 'the used-up memory is warned about, across units';
  like $full->{said}, qr/^WARN .*\bservices\.loadbalancers\b/m, 'and the used-up count';
  unlike $full->{said}, qr/^WARN .*\b(limits\.memory|requests\.cpu)\b/m, 'what has room is not';
} or diag "exit $full->{exit}\n$full->{said}";

# Nothing to run against is not something the preflight can call wrong: the
# run may be about to start its own pods, or go to a database outside the
# cluster. But a clear verdict over an empty namespace must not look like one
# over eight databases.
my $empty = preflight(objects => []);
subtest 'a namespace without any database is a warning' => sub {
  is $empty->{exit}, 0, 'exit 0';
  like $empty->{said}, qr/^WARN .*no database/m, 'it says there is none';
  like $empty->{said}, qr/^WARN .*route/m, 'and that no route could be looked at';
  like $empty->{said}, qr/^preflight clear .*\b2 warning/m, 'the verdict counts the warnings';
  unlike $empty->{said}, qr/safe to start/, 'and does not call the run safe';
} or diag "exit $empty->{exit}\n$empty->{said}";

# ----------------------------------------------------------- could not look

cannot_check_ok(
  preflight(kubectl_error => "error: You must be logged in to the server (Unauthorized)\n"),
  'the token has expired',
  [ qr/Unauthorized/, 'what kubectl said is passed on' ],
  [ qr/cihq-dev token dbio\b/, 'with the command that renews the token' ],
);

cannot_check_ok(
  preflight(kubectl_error => "Unable to connect to the server: dial tcp: lookup pichu.cihq: no such host\n"),
  'the cluster is not reachable',
  [ qr/no such host/, 'what kubectl said is passed on' ],
);

my $empty_path = file_path($tmp, 'empty');
mkpath($empty_path);
cannot_check_ok(
  preflight(path => $empty_path),
  'no kubectl',
  [ qr/kubectl is not in PATH/, 'the reason' ],
);

# -------------------------------------------------------- which access it uses

sub kubeconfig_used {
  my ($got) = @_;
  my %seen = map { $_->[1] => 1 } grep { $_->[0] eq 'kubectl' } @{ $got->{calls} };
  return join ' ', sort keys %seen;
}

subtest 'the access it looks with' => sub {
  my $project = preflight(project_access => 1);
  is kubeconfig_used($project),
    'KUBECONFIG=' . file_path($project->{home}, '.kube', 'cihq-dev-dbio.yaml'),
    'the project access, where there is one and nothing else is named';
  like $project->{said}, qr/\Q$project->{home}\E.*cihq-dev-dbio\.yaml/, 'and it says which';

  is kubeconfig_used(preflight(project_access => 1, env => { KUBECONFIG => '/k/named' })),
    'KUBECONFIG=/k/named', 'KUBECONFIG is taken as given';

  is kubeconfig_used(preflight(
      project_access => 1,
      env => { KUBECONFIG => '/k/named', DBIO_TEST_KUBECONFIG => '/k/dbio' },
    )),
    'KUBECONFIG=/k/dbio', 'DBIO_TEST_KUBECONFIG goes first, as in DBIO::Test::Kubernetes';

  is kubeconfig_used(preflight()), 'KUBECONFIG=', "without any of them it is kubectl's own default";
};

done_testing;
