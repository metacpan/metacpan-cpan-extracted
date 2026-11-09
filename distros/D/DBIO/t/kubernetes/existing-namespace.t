use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp ();

# Offline test for the two kinds of namespace DBIO::Test::Kubernetes works in
# (k223).
#
# WHY this is pinned: the module used to assume it owns its namespace -- it
# created one, used fixed object names in it (pod `mysql`, service
# `mysql-svc`), and deleted the whole namespace at the end. An account that is
# confined to one shared namespace can do neither, and the fixed names are the
# lesser problem there. The namespace this was written for already holds a pod
# `mysql` labelled app=mysql behind a LoadBalancer service selecting
# app=mysql, in use by other live suites. A second pod with that label joins
# that service's endpoints and takes a share of its connections; and a cleanup
# that deletes "the namespace", or "everything labelled role=dbio-test-db",
# takes the other databases with it.
#
# The claims, in an existing namespace:
#   1. no Namespace object is created and none is ever deleted;
#   2. names and selector labels are unique per run, and no selector that was
#      there before matches a pod of ours;
#   3. cleanup deletes exactly what this run created, by kind and name -- also
#      after a deploy that died halfway.
# And the namespace of its own keeps working as before: created, plain names,
# deleted as a whole.
#
# No cluster, no kubeconfig contents, no Kubernetes::REST: new() is the real
# one, handed a fake API through a stand-in for the kubeconfig loader.

my $API;

BEGIN {
    package Kubernetes::REST::Kubeconfig;
    sub new { bless {}, shift }
    sub api { $API }
    $INC{'Kubernetes/REST/Kubeconfig.pm'} = __FILE__;
}

{
    package FakeCondition;
    sub type   { $_[0]{type} }
    sub status { $_[0]{status} }

    package FakeStatus;
    sub conditions { $_[0]{conditions} }

    package FakePod;
    sub status { $_[0]{status} }

    package FakeAPI;
    sub new {
        my ($class, %args) = @_;
        return bless { created => [], deleted => [], got => [], %args }, $class;
    }

    sub new_object {
        my ($self, $kind, %args) = @_;
        return { kind => $kind, %args };
    }

    # fail_create_at => N makes the Nth create die, as the API does when a
    # name is taken or the quota is full. The object is then NOT in `created`.
    sub create {
        my ($self, $obj) = @_;
        die "create $obj->{kind} failed: 403 Forbidden\n"
            if $self->{fail_create_at} && ++$self->{create_calls} == $self->{fail_create_at};
        push @{ $self->{created} }, $obj;
        return $obj;
    }

    sub get {
        my ($self, $kind, $name, %args) = @_;
        push @{ $self->{got} }, { kind => $kind, name => $name, %args };
        die $self->{get_error} if $self->{get_error};
        return bless {
            status => bless {
                conditions => [
                    bless { type => 'Ready', status => 'True' }, 'FakeCondition'
                ],
            }, 'FakeStatus',
        }, 'FakePod';
    }

    # fail_delete_kind => KIND makes deletes of that kind die until cleared.
    sub delete {
        my ($self, $kind, $name, %args) = @_;
        die "delete $kind failed: 500\n"
            if ($self->{fail_delete_kind} // '') eq $kind;
        push @{ $self->{deleted} }, { kind => $kind, name => $name, %args };
        return 1;
    }

    sub created { @{ $_[0]{created} } }
    sub deleted { @{ $_[0]{deleted} } }
    sub got     { @{ $_[0]{got} } }
    sub of_kind {
        my ($self, $kind) = @_;
        return grep { $_->{kind} eq $kind } $self->created;
    }
}

require DBIO::Test::Kubernetes;

my $kubeconfig = File::Temp->new;

sub k8s {
    my (%args) = @_;
    $API = delete $args{api} // FakeAPI->new;
    return DBIO::Test::Kubernetes->new(kubeconfig => "$kubeconfig", %args);
}

# The module narrates its progress on STDOUT; keep that out of the TAP stream.
sub quietly {
    my ($code) = @_;
    my $out = '';
    open my $fh, '>', \$out or die "cannot open in-memory handle: $!";
    my @ret = do {
        local *STDOUT = $fh;
        $code->();
    };
    close $fh;
    return wantarray ? @ret : $ret[0];
}

# Kubernetes label-selector semantics, equality form: every key of the
# selector must be on the object with that value.
sub selects {
    my ($selector, $labels) = @_;
    return !grep {
        !exists $labels->{$_} || $labels->{$_} ne $selector->{$_}
    } keys %$selector;
}

sub kind_name { map { "$_->{kind}/$_->{name}" } @_ }
sub created_kind_name {
    my ($api) = @_;
    return map { "$_->{kind}/$_->{metadata}{name}" } $api->created;
}

# What the namespace this was written for holds (dev-dbio, read 2026-10-07):
# the pods other suites run against, their labels, and the selectors that are
# live there -- the service selectors, plus the two a tool or a person deletes
# by.
my %FOREIGN_POD_LABELS = (
    'dbio-ase'           => { app => 'dbio-ase',           'cihq/dbio-db' => 'sybase',     role => 'dbio-test-db' },
    'dbio-clickhouse-db' => { app => 'dbio-clickhouse-db', 'cihq/dbio-db' => 'clickhouse', role => 'dbio-test-db' },
    'dbio-firebird'      => { app => 'dbio-firebird',      'cihq/dbio-db' => 'firebird',   role => 'dbio-test-db' },
    'dbio-mariadb'       => { app => 'dbio-mariadb',       'cihq/dbio-db' => 'mariadb',    role => 'dbio-test-db' },
    'dbio-oracle'        => { app => 'dbio-oracle',        'cihq/dbio-db' => 'oracle',     role => 'dbio-test-db' },
    'dbio-postgresql'    => { app => 'dbio-postgresql',    'cihq/dbio-db' => 'postgresql', role => 'dbio-test-db' },
    'mssql-dev-0'        => { app => 'mssql-dev',          role => 'dbio-test-db' },
    'mysql'              => { app => 'mysql',              'cihq/dbio-db' => 'mysql',      role => 'dbio-test-db' },
);
my %FOREIGN_SELECTORS = (
    'service dbio-ase-svc'           => { app => 'dbio-ase' },
    'service dbio-clickhouse-db-svc' => { app => 'dbio-clickhouse-db' },
    'service dbio-firebird'          => { app => 'dbio-firebird' },
    'service dbio-mariadb'           => { app => 'dbio-mariadb' },
    'service dbio-oracle'            => { app => 'dbio-oracle' },
    'service dbio-postgresql'        => { app => 'dbio-postgresql' },
    'service mssql-dev'              => { app => 'mssql-dev' },
    'service mysql-svc'              => { app => 'mysql' },
    'role=dbio-test-db'              => { role => 'dbio-test-db' },
    'cihq/dbio-db=mysql'             => { 'cihq/dbio-db' => 'mysql' },
    'cihq/dbio-db=postgresql'        => { 'cihq/dbio-db' => 'postgresql' },
);
my %FOREIGN_NAMES = map { $_ => 1 } (
    keys %FOREIGN_POD_LABELS,
    qw( dbio-ase-svc dbio-clickhouse-db-svc dbio-firebird dbio-mariadb
        dbio-oracle dbio-postgresql mssql-dev mysql-svc ),
);

# --- existing namespace: nothing created that is not ours to create ---------

subtest 'existing namespace: no Namespace object, names and labels of the run' => sub {
    my $k8s = k8s(existing_namespace => 'dev-dbio', databases => [qw(pg mysql)]);
    my $api = $k8s->api;
    quietly(sub { $k8s->deploy_databases });

    is($k8s->namespace, 'dev-dbio', 'works in the namespace it was given');
    is(scalar $api->of_kind('Namespace'), 0, 'no Namespace object is created');

    my @pods = $api->of_kind('Pod');
    my @svcs = $api->of_kind('Service');
    is(scalar @pods, 2, 'two pods');
    is(scalar @svcs, 2, 'two services');

    for my $obj (@pods, @svcs) {
        my $name = $obj->{metadata}{name};
        is($obj->{metadata}{namespace}, 'dev-dbio', "$obj->{kind} $name is in dev-dbio");
        ok(!$FOREIGN_NAMES{$name},
            "$obj->{kind} $name does not take a name that is in use there");
        like($name, qr/^[a-z][a-z0-9-]{0,62}$/, "$name is a valid object name");
    }

    # The real harm: one of our pods becoming an endpoint of their service,
    # or being swept up by a selector somebody else deletes by.
    for my $pod (@pods) {
        my $name = $pod->{metadata}{name};
        for my $who (sort keys %FOREIGN_SELECTORS) {
            ok(!selects($FOREIGN_SELECTORS{$who}, $pod->{metadata}{labels}),
                "pod $name is not matched by the selector of: $who");
        }
    }

    # And the other direction: our service selects our pod of that database,
    # and no other pod -- not theirs, not our other database's.
    for my $i (0 .. $#svcs) {
        my $selector = $svcs[$i]{spec}{selector};
        my $name     = $svcs[$i]{metadata}{name};

        ok(scalar(keys %$selector), "service $name has a selector");
        is($svcs[$i]{spec}{type}, undef,
            "service $name is a plain ClusterIP service (reached by port-forward)");
        my @hit = grep { selects($selector, $_->{metadata}{labels}) } @pods;
        is_deeply([ map { $_->{metadata}{name} } @hit ], [ $pods[$i]{metadata}{name} ],
            "service $name selects exactly its own pod");
        ok(!selects($selector, $FOREIGN_POD_LABELS{$_}),
            "service $name does not select the pod $_")
            for sort keys %FOREIGN_POD_LABELS;
    }
};

# --- existing namespace: two runs side by side ------------------------------

subtest 'existing namespace: two runs do not meet' => sub {
    my $one = k8s(existing_namespace => 'dev-dbio', databases => [qw(pg mysql)]);
    my $two = k8s(existing_namespace => 'dev-dbio', databases => [qw(pg mysql)]);
    quietly(sub { $_->deploy_databases }) for $one, $two;

    my %names_of_one = map { $_ => 1 } created_kind_name($one->api);
    my @shared = grep { $names_of_one{$_} } created_kind_name($two->api);
    is_deeply(\@shared, [], 'no object name is used by both runs');

    for my $svc ($one->api->of_kind('Service')) {
        ok(!selects($svc->{spec}{selector}, $_->{metadata}{labels}),
            "service $svc->{metadata}{name} of one run does not select "
            . "pod $_->{metadata}{name} of the other")
            for $two->api->of_kind('Pod');
    }
};

# --- existing namespace: the objects are found again under their names ------

subtest 'existing namespace: readiness and addresses use the created names' => sub {
    my $k8s = k8s(existing_namespace => 'dev-dbio', databases => [qw(pg mysql)]);
    my $api = $k8s->api;
    quietly(sub {
        $k8s->deploy_databases;
        $k8s->wait_for_ready(timeout => 5, interval => 0);
    });

    is_deeply(
        [ map { "$_->{name} in $_->{namespace}" } $api->got ],
        [ map { "$_->{metadata}{name} in dev-dbio" } $api->of_kind('Pod') ],
        'wait_for_ready asks for the pods this run created, not for `pg` and `mysql`',
    );

    my $info = $k8s->connection_info(mode => 'cluster');
    my %svc_of = map { $_->{spec}{selector}{'dbio-test-db'} => $_->{metadata}{name} }
        $api->of_kind('Service');
    is($info->{$_}{host}, "$svc_of{$_}.dev-dbio.svc.cluster.local",
        "$_: the in-cluster address is the service this run created")
        for qw(pg mysql);
};

# --- existing namespace: one label finds every object of the run -----------

subtest 'existing namespace: pod, service and job all carry the run label' => sub {
    my $k8s = k8s(existing_namespace => 'dev-dbio', databases => [qw(pg)]);
    quietly(sub { $k8s->deploy_databases; $k8s->deploy_test_job });

    for my $obj ($k8s->api->created) {
        like($obj->{metadata}{labels}{'dbio-test-run'}, qr/^[a-z0-9]{8}$/,
            "$obj->{kind} $obj->{metadata}{name} carries dbio-test-run");
    }
    my %run = map { $_->{metadata}{labels}{'dbio-test-run'} => 1 } $k8s->api->created;
    is(scalar keys %run, 1, 'and it is the same run id on all of them');

    # A namespace of our own keeps plain objects: nothing new on them.
    my $own = k8s(databases => [qw(pg)]);
    quietly(sub { $own->deploy_databases; $own->deploy_test_job });
    is_deeply(
        [ grep { exists $_->{metadata}{labels}{'dbio-test-run'} } $own->api->created ],
        [], 'no run label in a namespace of its own');
    quietly(sub { $_->cleanup }) for $k8s, $own;
};

# --- waiting: an API failure is not a timeout --------------------------------

subtest 'wait_for_ready and wait_for_job: API errors are not timeouts' => sub {
    my $k8s = k8s(existing_namespace => 'dev-dbio', databases => [qw(pg)]);
    quietly(sub { $k8s->deploy_databases; $k8s->deploy_test_job });

    $k8s->api->{get_error} = "403 Forbidden: pods is forbidden\n";
    throws_ok { quietly(sub { $k8s->wait_for_ready(timeout => 5, interval => 0) }) }
        qr/Reading Pod .* failed: 403 Forbidden/,
        'wait_for_ready: a 403 is thrown as what it is';
    throws_ok { quietly(sub { $k8s->wait_for_job(timeout => 5, interval => 0) }) }
        qr/Reading Job .* failed: 403 Forbidden/,
        'wait_for_job: so is a 403 here';

    $k8s->api->{get_error} = "404 Not Found\n";
    throws_ok { quietly(sub { $k8s->wait_for_ready(timeout => 1, interval => 0) }) }
        qr/Timed out waiting for pg to become ready/,
        'a pod the API does not know yet is still waited for';

    delete $k8s->api->{get_error};
    quietly(sub { $k8s->cleanup });
};

# --- existing namespace: cleanup --------------------------------------------

subtest 'existing namespace: cleanup deletes exactly what was created' => sub {
    my $k8s = k8s(existing_namespace => 'dev-dbio', databases => [qw(pg mysql)]);
    my $api = $k8s->api;
    quietly(sub {
        $k8s->deploy_databases;
        $k8s->deploy_test_job;
    });

    my @created = created_kind_name($api);
    is(scalar @created, 5, 'two pods, two services, one job');
    lives_and {
        is_deeply([ kind_name($k8s->created_objects) ], \@created);
    } 'created_objects names what the API accepted';

    my ($job) = $api->of_kind('Job');
    isnt($job->{metadata}{name}, 'dbio-test-runner',
        'the job does not take the fixed name either');

    quietly(sub { $k8s->cleanup });

    is_deeply([ sort(kind_name($api->deleted)) ], [ sort @created ],
        'every created object is deleted, and nothing else');
    is(scalar(grep { $_->{kind} eq 'Namespace' } $api->deleted), 0,
        'the namespace is not deleted');
    is_deeply(
        [ grep { ($_->{namespace} // '') ne 'dev-dbio' } $api->deleted ], [],
        'every delete names the namespace of the object',
    );

    my ($job_delete) = grep { $_->{kind} eq 'Job' } $api->deleted;
    is($job_delete->{propagationPolicy}, 'Background',
        'the job is deleted together with its pods -- no namespace delete collects them here');

    lives_and { is(scalar(() = $k8s->created_objects), 0) }
        'nothing is left on record';
    quietly(sub { $k8s->cleanup });
    is(scalar $api->deleted, scalar @created, 'a second cleanup deletes nothing again');
};

subtest 'existing namespace: cleanup after a deploy that died halfway' => sub {
    # pg pod, pg service, then the mysql pod is refused.
    my $k8s = k8s(
        existing_namespace => 'dev-dbio',
        databases          => [qw(pg mysql)],
        api                => FakeAPI->new(fail_create_at => 3),
    );
    my $api = $k8s->api;

    throws_ok { quietly(sub { $k8s->deploy_databases }) } qr/403 Forbidden/,
        'the failed create surfaces';

    my @created = created_kind_name($api);
    is(scalar @created, 2, 'two objects made it before the failure');

    quietly(sub { $k8s->cleanup });

    is_deeply([ sort(kind_name($api->deleted)) ], [ sort @created ],
        'cleanup removes the two that exist -- and not the pod that was refused');
    is(scalar(grep { $_->{kind} eq 'Namespace' } $api->deleted), 0,
        'the namespace is not deleted');
};

subtest 'existing namespace: what could not be deleted stays named' => sub {
    # Nothing collects a leftover here, so a failed delete must not vanish
    # from the record: the caller has to be able to name it.
    my $k8s = k8s(
        existing_namespace => 'dev-dbio',
        databases          => [qw(pg)],
        api                => FakeAPI->new(fail_delete_kind => 'Service'),
    );
    my $api = $k8s->api;
    quietly(sub { $k8s->deploy_databases });
    my ($svc) = $api->of_kind('Service');
    my ($pod) = $api->of_kind('Pod');

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        quietly(sub { $k8s->cleanup });
    }

    is_deeply([ kind_name($api->deleted) ], [ "Pod/$pod->{metadata}{name}" ],
        'the pod is deleted although the service delete failed');
    is(scalar @warnings, 1, 'one warning');
    like($warnings[0], qr/Service \Q$svc->{metadata}{name}\E in namespace dev-dbio/,
        'and it names the object that is still there');
    lives_and {
        is_deeply([ kind_name($k8s->created_objects) ],
            [ "Service/$svc->{metadata}{name}" ]);
    } 'created_objects still lists it';

    $api->{fail_delete_kind} = undef;
    quietly(sub { $k8s->cleanup });
    is_deeply(
        [ kind_name($api->deleted) ],
        [ "Pod/$pod->{metadata}{name}", "Service/$svc->{metadata}{name}" ],
        'a second cleanup deletes what was left, and only that',
    );
};

# --- which kind of namespace is said, not guessed ---------------------------

subtest 'the kind of namespace is chosen explicitly' => sub {
    throws_ok {
        k8s(namespace => 'dbio-test-x', existing_namespace => 'dev-dbio')
    } qr/either namespace or existing_namespace/,
        'namespace and existing_namespace together are refused';

    throws_ok { k8s(existing_namespace => $_) } qr/existing_namespace needs the name/,
        'existing_namespace without a name is refused'
        for undef, '';

    lives_and { ok(k8s(existing_namespace => 'dev-dbio')->uses_existing_namespace) }
        'existing_namespace => NAME says so';
    lives_and { ok(!k8s()->uses_existing_namespace) }
        'no namespace argument: a namespace of its own';
    lives_and { ok(!k8s(namespace => 'dbio-test-x')->uses_existing_namespace) }
        'namespace => NAME: a namespace of its own, under that name';
};

# --- a namespace of its own: as before --------------------------------------

subtest 'own namespace: created, plain names, deleted as a whole' => sub {
    my $k8s = k8s(databases => [qw(pg mysql)]);
    my $api = $k8s->api;
    my $ns  = $k8s->namespace;
    quietly(sub { $k8s->deploy_databases });

    like($ns, qr/^dbio-test-[a-z0-9]{8}$/, 'a namespace name is generated');
    is_deeply(
        [ created_kind_name($api) ],
        [ "Namespace/$ns", qw(Pod/pg Service/pg-svc Pod/mysql Service/mysql-svc) ],
        'the namespace is created first, then the plain-named pods and services',
    );

    my ($mysql) = grep { $_->{metadata}{name} eq 'mysql' } $api->of_kind('Pod');
    is_deeply($mysql->{metadata}{labels}, { app => 'mysql', role => 'dbio-test-db' },
        'pod labels are the plain ones');
    my ($mysql_svc) = grep { $_->{metadata}{name} eq 'mysql-svc' } $api->of_kind('Service');
    is_deeply($mysql_svc->{spec}{selector}, { app => 'mysql' },
        'and the service selects on them');

    quietly(sub { $k8s->cleanup });

    is_deeply([ $api->deleted ], [ { kind => 'Namespace', name => $ns } ],
        'cleanup is one delete: the namespace, which takes the rest along');
};

subtest 'own namespace: cleanup after a deploy that died halfway' => sub {
    # namespace, then the first pod is refused.
    my $k8s = k8s(databases => [qw(pg)], api => FakeAPI->new(fail_create_at => 2));
    my $api = $k8s->api;

    throws_ok { quietly(sub { $k8s->deploy_databases }) } qr/403 Forbidden/,
        'the failed create surfaces';
    quietly(sub { $k8s->cleanup });

    is_deeply([ $api->deleted ], [ { kind => 'Namespace', name => $k8s->namespace } ],
        'the namespace this run created does not stay behind');
};

subtest 'own namespace: a namespace that could not be created is not deleted' => sub {
    # The account may not create namespaces, or the name is taken: either way
    # the namespace of that name is not this run's.
    my $k8s = k8s(
        namespace => 'dev-dbio',
        databases => [qw(pg)],
        api       => FakeAPI->new(fail_create_at => 1),
    );
    my $api = $k8s->api;

    throws_ok { quietly(sub { $k8s->deploy_databases }) } qr/403 Forbidden/,
        'the failed create surfaces';
    quietly(sub { $k8s->cleanup });

    is(scalar $api->created, 0, 'nothing was created');
    is(scalar $api->deleted, 0, 'and nothing is deleted');
};

done_testing;
