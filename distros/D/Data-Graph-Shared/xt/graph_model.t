use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Graph::Shared;

my $dir = tempdir(CLEANUP => 1);
my $steps = $ENV{GRAPH_MODEL_STEPS} || 3000;
for my $kind (qw(anonymous file memfd)) {
    for my $capacity ([1, 1], [5, 7], [63, 65], [65, 129], [127, 127]) {
        my ($mn, $me) = @$capacity;
        subtest "$kind $mn nodes/$me edges" => sub {
            srand(2026 + $mn + $me);
            my $path = "$dir/$mn-$me.graph";
            my $g = $kind eq 'memfd' ? Data::Graph::Shared->new_memfd('model', $mn, $me)
                  : Data::Graph::Shared->new($kind eq 'file' ? $path : undef, $mn, $me);
            my $peer = $kind eq 'memfd' ? Data::Graph::Shared->new_from_fd($g->memfd)
                     : $kind eq 'file' ? Data::Graph::Shared->new($path, $mn, $me) : $g;
            $mn = $g->max_nodes;
            my (%data, %adj);
            my $edge_count = sub { my $n = 0; $n += @$_ for values %adj; $n };
            my $snapshot = sub {
                my $h = shift;
                my @ids = $h->nodes;
                return {
                    nodes => \@ids,
                    data => {map { $_ => $h->node_data($_) } @ids},
                    adj => {map { $_ => [$h->neighbors($_)] } @ids},
                    degrees => {map { $_ => $h->degree($_) } @ids},
                    counts => [$h->node_count, $h->edge_count],
                };
            };
            my $verify = sub {
                my ($h, $label) = @_;
                is_deeply $snapshot->($h), {
                    nodes => [sort { $a <=> $b } keys %data],
                    data => \%data, adj => \%adj,
                    degrees => {map { $_ => scalar @{$adj{$_}} } keys %data},
                    counts => [scalar keys %data, $edge_count->()],
                }, $label;
            };
            my $last_step = 0;
            my $ok = eval {
                for my $step (0 .. $steps + $mn + $me + 1) {
                    $last_step = $step;
                    my $h = $step % 2 ? $peer : $g;
                    my $op = $step <= $mn ? 0 : $step <= $mn + $me + 1 ? 1 : int rand 5;
                    my $node = int rand($mn + 2);
                    my $value = int(rand(2001)) - 1000;
                    if ($op == 0) {
                        my $id = $h->add_node($value);
                        if (keys(%data) == $mn) {
                            die "full node pool accepted a node\n" if defined $id;
                        } else {
                            die "invalid allocated node\n" unless defined($id) && $id < $mn && !exists $data{$id};
                            $data{$id} = $value;
                            $adj{$id} = [];
                        }
                    } elsif ($op == 1) {
                        my $src = $step <= $mn + $me + 1 ? 0 : $node;
                        my $dst = int rand($step <= $mn + $me + 1 ? $mn : $mn + 2);
                        my $expected = exists($data{$src}) && exists($data{$dst}) && $edge_count->() < $me;
                        my $got = $h->add_edge($src, $dst, $value);
                        die "wrong add_edge result\n" if !!$got != !!$expected;
                        unshift @{$adj{$src}}, [$dst, $value] if $expected;
                    } elsif ($op == 2 || $op == 3) {
                        my $method = $op == 2 ? 'remove_node' : 'remove_node_full';
                        my $expected = exists $data{$node};
                        my $got = $h->$method($node);
                        die "wrong $method result\n" if !!$got != !!$expected;
                        if ($expected) {
                            delete $data{$node};
                            delete $adj{$node};
                            if ($op == 3) {
                                $_ = [grep { $_->[0] != $node } @$_] for values %adj;
                            }
                        }
                    } else {
                        if (exists $data{$node}) {
                            $h->set_node_data($node, $value);
                            $data{$node} = $value;
                        } else {
                            eval { $h->set_node_data($node, $value) };
                            die "missing node accepted by setter\n" unless $@ =~ /does not exist/;
                        }
                    }
                    die "wrong node count\n" if $h->node_count != keys %data;
                    die "wrong edge count\n" if $h->edge_count != $edge_count->();
                    $verify->($h, "model after step $step") if $step % 100 == 0;
                }
                $verify->($peer, 'final mutable peer');
                $g->freeze;
                $verify->($g, 'frozen producer');
                $verify->(Data::Graph::Shared->new_readonly($path), 'read-only reopen') if $kind eq 'file';
                1;
            };
            ok $ok, 'all mutations agree with the reference model' or diag "step $last_step: $@";
        };
    }
}
done_testing;
