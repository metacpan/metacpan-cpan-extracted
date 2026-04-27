use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis qw(run await_f skip_without_redis cleanup_keys redis_host redis_port with_timeout);
use Test2::V0;
use Future::AsyncAwait;
use Async::Redis;

my $cookbook = 'lib/Async/Redis/Cookbook.pod';
my @examples = _extract_cookbook_examples($cookbook);

my $janitor = skip_without_redis();
ok(@examples, 'found cookbook examples');
run { cleanup_keys($janitor, 'cookbook:*') };

for my $example (@examples) {
    subtest $example->{name} => sub {
        my $redis = Async::Redis->new(
            host            => redis_host(),
            port            => redis_port(),
            connect_timeout => 2,
        );

        my $runner = _compile_example($example);
        my $prefix = "cookbook:$example->{name}:$$";

        my $error;
        eval {
            await_f((async sub {
                await $redis->connect;
                await with_timeout(
                    8,
                    $runner->($redis, redis_host(), redis_port(), $prefix),
                );
            })->());
            1;
        } or $error = $@;

        $redis->disconnect;

        ok(!$error, 'example ran without dying')
            or diag("$error\n\nExample source:\n$example->{code}");
    };
}

run { cleanup_keys($janitor, 'cookbook:*') };

done_testing;

sub _extract_cookbook_examples {
    my ($path) = @_;

    open my $fh, '<', $path or die "open $path: $!";

    my @examples;
    my %seen;
    my $current;

    while (my $line = <$fh>) {
        if ($line =~ /^=for\s+cookbook-test\s+(\S+)\s*$/) {
            die "nested cookbook-test marker at $. in $path" if $current;
            die "duplicate cookbook-test name '$1'" if $seen{$1}++;
            $current = {
                name       => $1,
                start_line => $.,
                lines      => [],
            };
            next;
        }

        if ($line =~ /^=for\s+cookbook-test-end\s+(\S+)\s*$/) {
            die "cookbook-test-end without start at $. in $path" unless $current;
            die "cookbook-test-end '$1' does not match '$current->{name}'"
                unless $1 eq $current->{name};

            my $code = join '', map {
                s/^ {4}//r;
            } @{$current->{lines}};

            push @examples, {
                name       => $current->{name},
                start_line => $current->{start_line},
                code       => $code,
            };
            undef $current;
            next;
        }

        push @{$current->{lines}}, $line if $current;
    }

    die "unclosed cookbook-test '$current->{name}'" if $current;

    return @examples;
}

sub _compile_example {
    my ($example) = @_;

    my $source = <<'PERL' . $example->{code} . <<'PERL';
use strict;
use warnings;
use Future;
use Future::AsyncAwait;
use Future::IO;
use Async::Redis;
use Async::Redis::Pool;

async sub {
    my ($redis, $host, $port, $prefix) = @_;
PERL

    return 1;
}
PERL

    my $runner = eval $source;
    die "compile cookbook example '$example->{name}' from line $example->{start_line}: $@"
        if $@;
    die "cookbook example '$example->{name}' did not compile to a coderef"
        unless ref($runner) eq 'CODE';

    return $runner;
}
