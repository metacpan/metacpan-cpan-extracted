#!/usr/bin/env perl

package GetMCEThings;
use Moose;
with 'BioX::Workflow::Command::run::Rules::Directives::MCE';

use Data::Dumper;

sub doTask {
    my $self = shift;
    my ($sym) = @_;
    print Dumper($sym);
    return $sym;
}

package DoMCEThings;
use Moose;
use Data::Dumper;
use MCE::Map;
use Algorithm::Loops qw(NestedLoops);

my $self = GetMCEThings->new();

my @symbol = ('abc', 'def');
my $CPUs = 1;
my %data = ();

my @samples = ('sample1', 'sample2');
my @split = (1 .. 5);
$data{samples} = \@samples;
$data{splits} = \@split;

my $data_loop = [ { value => 'samples', key => 'sample' }, { value => 'splits', key => 'split' } ];

my @keys = (
    'sample',
    'split',
);

my @array = (
    $data{samples},
    $data{splits}
);

my @terms = NestedLoops(\@array,
    sub {
        my @things = @_;
        my $values = [];
        for (my $x = 0; $x <= $#things; $x++) {
            my $key = $keys[$x];
            push(@{$values}, { key => $key, value => $things[$x] });
        }
        return $values;
    });

#print Dumper(\@terms);

process(\@terms);

sub process {
    my $map = shift;
    MCE::Map::init {chunk_size => 1, max_workers => 'auto'};
    my @res = mce_map {$self->doTask($_)} @{$map};
    print Dumper(\@res);
#    print Dumper(\%data);
#    print %data; # data exchange between the manager and worker processes works
}

#sub doTask {
#    my ($sym) = @_;
#    print Dumper($sym);
#    return $sym;
#}

1;
