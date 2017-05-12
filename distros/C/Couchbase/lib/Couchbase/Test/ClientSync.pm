package Couchbase::Test::ClientSync;
use strict;
use warnings;
use base qw(Couchbase::Test::Common);
use Test::More;
use Couchbase::Constants;
use Data::Dumper;
use Couchbase::Bucket;

sub setup_client :Test(startup)
{
    my $self = shift;
    $self->mock_init();
    $self->cbo($self->make_cbo);
    $self->{basic_keys} = [qw(
        Foo Bar Baz Blargh Bleh Meh Grr Gah)];
}

sub cbo {
    if(@_ == 1) {
        return $_[0]->{object};
    } elsif (@_ == 2) {
        $_[0]->{object} = $_[1];
        return $_[1];
    }
}

sub k2v {
    my ($self,$k) = @_;
    reverse($k);
}

sub v2k {
    my ($self,$v) = @_;
    reverse($v);
}

sub set_ok {
    my ($self,$msg,@args) = @_;
    my $doc = Couchbase::Document->new(@args);
    $self->cbo->upsert($doc);
    ok($doc->is_ok, $msg);
    if(!$doc->is_ok) {
        diag($doc->errstr);
    }
}

sub get_ok {
    my ($self,$key,$expected) = @_;
    my $doc = Couchbase::Document->new($key);
    $self->cbo->get($doc);
    ok($doc->is_ok, "Status OK for GET($key)");
    ok($doc->value eq $expected, "Got expected value for $key");
}

sub T00_set_values_simple :Test(no_plan) {
    my $self = shift;
    foreach my $k (@{$self->{basic_keys}}) {
        $self->set_ok("Key '$k'", $k, $self->k2v($k));
        $self->get_ok($k, $self->k2v($k))
    }
}

sub T01_get_nonexistent :Test(no_plan) {
    my $self = shift;
    my $doc = Couchbase::Document->new('NonExistent');
    $self->cbo->get($doc);
    is($doc->errnum, COUCHBASE_KEY_ENOENT, "Got ENOENT for nonexistent key");
}

sub T02_mutators :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;
    my $doc = Couchbase::Document->new("mutate_key", "BASE");
    $o->remove($doc); #if it already exists

    $doc->format('utf8');

    ok($o->insert($doc), "Inserting new document");
    $doc->is_ok or die "Couldn't insert: " . $doc->errstr;

    ok($o->prepend_bytes($doc, {fragment=>"PREFIX_"}), "Prepending");
    ok($o->append_bytes($doc, {fragment=>"_SUFFIX"}), "Appending");
    ok($o->get($doc), "Retrieval");
    is($doc->value, "PREFIX_BASE_SUFFIX", "Got expected mutated value");
}

sub T03_arithmetic :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;
    my $doc = Couchbase::Document->new("ArithmeticKey");

    $o->remove($doc);
    ok( $o->counter($doc, { delta => -12, initial => 42 }), "Set with initial value");
    is(42, $doc->value);

    $o->counter($doc, { delta => -12, initial => 42 });

    is(30, $doc->value);
    $o->remove($doc);

    $o->counter($doc, { delta => -12 });
    ok($doc->is_not_found, "Not found error without initial");

    ok ($o->counter($doc, { delta => -12, initial => 0 }), "Initial=0 works");
    is(0, $doc->value);

    ok ($o->counter($doc, { delta => 1 }));
    is(1, $doc->value);
}

sub T04_atomic :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;
    my $doc = Couchbase::Document->new("AtomicKey", "SOMEVALUE");

    $o->remove($doc);
    $o->replace($doc);
    ok($doc->is_not_found, "Can't replace missing document");

    ok($o->insert($doc), "Insert works on non-existent doc");
    ok(length($doc->_cas), "Have a CAS");
    my $doc2 = $doc->copy();

    $doc2->_cas(0xdeadbeef);
    $o->replace($doc2);
    ok($doc2->is_cas_mismatch, "Got mismatch on bad CAS");
    ok(length($doc2->_cas), "Still have CAS");

    ok($o->replace($doc2, { ignore_cas => 1}), "Ignore cas works");
    $o->insert($doc2);
    ok($doc2->is_already_exists, "EEXISTS on insert existing");

    my $gdoc = Couchbase::Document->new($doc->id);
    ok($o->get($gdoc));
    ok(length($gdoc->_cas));

    my $newv = $gdoc->value . $gdoc->value;
    $gdoc->value($newv);
    ok($o->replace($gdoc));

    $o->get($doc2);
    is($gdoc->value, $doc2->value);

    # Remove with bad CAS
    $doc2->_cas(0xCAFEBABE);
    ok(! $o->remove($doc2));
    ok($doc2->is_cas_mismatch);
    ok($o->remove($doc2, { ignore_cas => 1}));
}

sub T05_conversion :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;
    my $structure = [ qw(foo bar baz) ];
    my $doc = Couchbase::Document->new("Serialization", $structure);

    ok($o->upsert($doc), "Serialized OK");
    ok($o->get($doc), "Deserialized OK");
    is_deeply($doc->value, $structure, "Got back our array");

    eval { $o->append_bytes($doc, { fragment => $structure }) };
    ok($@, "Got error for append/prepending a serialized structure ($@)");

    # But ensure it works with an explicit format passed
    eval { $o->append_bytes($doc, { fragment => "foo bar baz" }) };
    ok($@, "Got error for append without proper format set ($@)");

    $doc->format('utf8');
    ok($o->append_bytes($doc, { fragment => "foo bar baz" }));

    my $exptxt = <<'EOF';
# KOREAN(UTF8)

\x{b3c4}\x{ba54}\x{c778}\x{c774}\x{b984}                  : google.co.kr
\x{b4f1}\x{b85d}\x{c778}                      : \x{ad6c}\x{ae00}\x{cf54}\x{b9ac}\x{c544}\x{c720}\x{d55c}\x{d68c}\x{c0ac}
\x{b4f1}\x{b85d}\x{c778} \x{c8fc}\x{c18c}                 : \x{c11c}\x{c6b8}\x{c2dc} \x{ac15}\x{b0a8}\x{ad6c} \x{c5ed}\x{c0bc}\x{b3d9} 737 \x{ac15}\x{b0a8}\x{d30c}\x{c774}\x{b0b8}\x{c2a4}\x{c13c}\x{d130} 22\x{ce35}
\x{b4f1}\x{b85d}\x{c778} \x{c6b0}\x{d3b8}\x{bc88}\x{d638}             : 135984
\x{cc45}\x{c784}\x{c790}                      : Domain Administrator
\x{cc45}\x{c784}\x{c790} \x{c804}\x{c790}\x{c6b0}\x{d3b8}             : dns-admin\@google.com
\x{cc45}\x{c784}\x{c790} \x{c804}\x{d654}\x{bc88}\x{d638}  ";
EOF
    $doc = Couchbase::Document->new('utf8_test', $exptxt);
    $o->upsert($doc);
    $o->get($doc);
    is($exptxt, $doc->value,
       "Serializing/Deserializing UTF-8 characters (not bytes!) = FMT_JSON");

    $doc->format('utf8');
    $o->upsert($doc);
    $o->get($doc);
    is($exptxt, $doc->value,
       "Serializing/Deserializing UTF-8 characters (not bytes!) = FMT_UTF8");
}

sub multi_ok {
    my ($rv, $msg, $expect) = @_;
    my @errs;

    if ($expect) {
        @errs = grep {$_->errnum != $expect} @$rv;
    } else {
        @errs = grep { !$_->is_ok } @$rv;
    }

    ok(!@errs, $msg);
}

sub T06_multi :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;

    my @docs = map {Couchbase::Document->new($_,$_)} @{$self->{basic_keys}};
    my $batch = $o->batch();
    map {$batch->upsert($_)} @docs;
    # Return value is ignored
    $batch->wait_all();
    multi_ok(\@docs, "Multi upsert OK");

    $batch = $o->batch();
    map {$batch->get($_)} @docs;
    $batch->wait_all();
    multi_ok(\@docs, "Multi get OK");

    is(scalar grep($_->value eq $_->id, @docs), scalar @docs, "get_multi: Got expected values");

    $batch = $o->batch();
    map{$batch->remove($_)} @docs;
    $batch->wait_all();
    multi_ok(\@docs, "Multi remove OK");
}

sub T07_stats :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;
    my $rv = $o->stats();
    ok($rv->is_ok);
    my $stats = $rv->value;

    ok($stats && ref $stats eq 'HASH', "Got a hashref");
    ok(scalar keys %$stats, "stats not empty");

    if($self->mock && $self->mock->nodes) {
        ok(scalar keys %$stats == $self->mock->nodes, "Got expected stat count");
    } else {
        diag "Cannot determine expected stat count for real cluster";
    }
}

sub T08_iterator :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;
    my @docs = map { Couchbase::Document->new("T08_NonExistent_$_") } (1..200);
    my $batch = $o->batch;
    map {$batch->get($_)} @docs;

    my %khash = ();
    while ((my $doc = $batch->wait_one)) {
        if (exists $khash{$doc->id}) {
            fail("Document returned twice!");
        }
        if (!$doc->is_not_found) {
            fail("Expected NOT_FOUND");
        }
        $khash{$doc->id} = 1;
    }
    is(200, scalar values %khash)
}

sub T10_locks :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;
    my $doc = Couchbase::Document->new("GETL", "value");

    $o->remove($doc); # Ensure it's gone
    $o->insert($doc);
    ok($o->get_and_lock($doc, {lock_duration=>10}), "Locked OK");
    ok($o->unlock($doc), "Unlocked OK");
    #ok($o->unlock($doc), "Unlock again fails");
    #
    #print Dumper($doc);
    #
    #is(COUCHBASE_ETMPFAIL, $doc->errnum, "Temporary failure returned for re-locking");

    # Unlock while locked, but with bad CAS
    my $doc2 = $doc->copy();
    ok($o->get_and_lock($doc2, {lock_duration=>10}));

    $doc->_cas(0xdeadbeef);
    ok((!$o->unlock($doc)), "Can't unlock with stale CAS");
    ok($o->unlock($doc2), "Unlock with good CAS ok");

    # Lock without a timeout (should fail)
    eval { $o->get_and_lock($doc) };
    ok($@, "Can't lock without explicit duration");
    eval { $o->unlock(Couchbase::Document->new("dummy"))};
    ok($@, "Can't unlock with no CAS");

    $o->get_and_lock($doc, {lock_duration=>5});
    ok($o->upsert($doc), "Implicit unlock with CAS ok");
    $o->remove($doc); # Clean up
}

sub wait_for_exp {
    my ($o,$doc,$limit) = @_;
    my $begin_time = time();
    while (time() - $begin_time < $limit) {
        sleep(1);
        $o->get($doc);
        if ($doc->errnum == COUCHBASE_KEY_ENOENT) {
            return 1;
        }
        diag("Sleeping again..");
    }
    return 0;
}

sub T11_expiry :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;

    my $doc = Couchbase::Document->new("exp_key", "exp_val", {expiry=>1});
    ok($o->upsert($doc), "Inserted document with expiry");
    ok(wait_for_exp($o, $doc, 3), "Document is no longer here (expired!)");

    $doc->expiry("bad-expiry");
    eval { $o->upsert($doc) };
    ok($@, "Set with bad expiry raises error ($@)");

    $doc->expiry(-1);
    eval { $o->upsert($doc) };
    ok($@, "Set with negative expiry raises error ($@)");

    # Restore the expiry:
    $doc->expiry(1);
}

sub T12_observe :Test(no_plan) {
    my $self = shift;
    my $cb = $self->cbo;
    my $doc = Couchbase::Document->new("Hello", "World");
    $cb->upsert($doc);

    my $obsret = $cb->observe($doc);
    my @m = grep { $_->{master} } @{$obsret->value};
    ok($m[0]);
    is($cb->get_bucket_config->nreplicas+1, scalar @{$obsret->value});


    # Try again, with master_only
    $obsret = $cb->observe($doc, {master_only=>1});
    ok($obsret->is_ok);
    is(1, scalar @{$obsret->value});
    ok($obsret->value->[0]->{master});
}

sub T13_endure :Test(no_plan) {
    my $self = shift;
    my $cb = $self->cbo;
    my $doc = Couchbase::Document->new("endure_key", "endure_value");

    $cb->upsert($doc, { persist_to => -1, replicate_to => -1 });
    ok($doc->is_ok, "Document inserted OK " . $doc->errstr);

    # Try with a durability batch:
    my @docs = Couchbase::Document->new("endure_$_", "value") for (0..3);
    my $batch = $cb->batch();
    $batch->upsert($_) for @docs;
    $batch->wait_all;

    foreach (@docs) {
        ok(0, "Couldn't upsert") unless $_->is_ok;
    }
    $batch = $cb->durability_batch({persist_to => -1, replicate_to => -1});
    $batch->endure($_) for @docs;
    $batch->wait_all;
    foreach (@docs) {
        ok(0, "Couldn't enure") unless $_->is_ok;
    }
}

sub T14_utf8 :Test(no_plan) {
    use utf8;
    my $self = shift;
    my $txt = "상기 정보는 UTF-8 인코딩되어 서비스되고 있습니다. EUC-KR 인코딩 서비스는 oldwhois.kisa.or.kr에서 서비스 되고 있습니다.";
    my $doc = Couchbase::Document->new('utf8json', { string => $txt });
    my $cb = $self->cbo;
    $cb->upsert($doc);
    $cb->get($doc);
    is($txt, $doc->value->{string});
}
1;
