use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# bulk_inserter must derive one insert_deduplication_token per batch:
# reusing a single static token makes the server deduplicate every
# batch after the first on Replicated tables. Retries of one batch
# reuse its token, keeping single-batch retries idempotent.

{
    package CaptureHttp;
    my $OK = { success => 1, status => 200, content => '',
               headers => {} };
    sub new {
        my ($class, @queue) = @_;
        bless { queue => \@queue, urls => [] }, $class;
    }
    sub post {
        my ($self, $url) = @_;
        push @{$self->{urls}}, $url;
        my $r = @{$self->{queue}} ? shift @{$self->{queue}} : $OK;
        return { %$r };
    }
}

# Distinct batches -> distinct tokens derived from the base.
{
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['v', 'Int32']],
        batch_size => 1, dedup_token => 'stream-7', retries => 0);
    $bi->{http} = CaptureHttp->new;
    $bi->push([1]);
    $bi->push([2]);
    my @urls = @{$bi->{http}{urls}};
    is(scalar @urls, 2, 'two flushes posted');
    my ($t0) = $urls[0] =~ /insert_deduplication_token=([^&]+)/;
    my ($t1) = $urls[1] =~ /insert_deduplication_token=([^&]+)/;
    ok(defined $t0 && defined $t1, 'both flushes carry a token');
    isnt($t1, $t0, 'second batch does not reuse the first batch token');
    like($t0, qr/^stream-7-0$/, 'first batch token is base-0');
    like($t1, qr/^stream-7-1$/, 'second batch token is base-1');
}

# One failed batch retried: both attempts share the batch token.
{
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['v', 'Int32']],
        dedup_token => 'base', retries => 2, retry_wait => 0);
    $bi->{http} = CaptureHttp->new(
        { success => 0, status => 503, content => 'x', headers => {} });
    $bi->push([9]);
    $bi->flush;
    my @urls = @{$bi->{http}{urls}};
    is(scalar @urls, 2, 'failed batch retried once');
    is($urls[0], $urls[1], 'retry reuses the batch token');
}

# Special characters in the base are escaped, not smuggled.
{
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['v', 'Int32']],
        batch_size => 1, dedup_token => 'a b&c', retries => 0);
    $bi->{http} = CaptureHttp->new;
    $bi->push([1]);
    like($bi->{http}{urls}[0],
         qr/insert_deduplication_token=a%20b%26c-0(?:&|$)/,
         'derived token is URI-escaped');
}

# No token configured -> no param (unchanged default).
{
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['v', 'Int32']], batch_size => 1);
    $bi->{http} = CaptureHttp->new;
    $bi->push([1]);
    unlike($bi->{http}{urls}[0], qr/insert_deduplication_token/,
           'no token by default');
}

done_testing();
