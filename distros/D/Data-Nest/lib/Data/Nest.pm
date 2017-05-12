package Data::Nest;
use 5.008005;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = "0.06";

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/nest/;

sub new {
    my $class = shift;
    my %opt = @_;

    return bless {
        keyname => "key",
        valname => "values",
        keys => [],
        rollups => [],
        tree => {},
        noValues => $opt{noValues} || 0,
        delimiter => $opt{delimiter} || "_____",
    }, $class;
}

sub nest {
    my %opt = @_;

    my $self = new Data::Nest(%opt);
    $self;
}

sub keyname {
    my $self = shift;
    my $keyname = shift;
    return $self->{keyname} unless($keyname);
    $self->{keyname} = $keyname;
    $self;
}

sub valname {
    my $self = shift;
    my $valname = shift;
    return $self->{valname} unless($valname);
    $self->{valname} = $valname;
    $self;
}

sub key {
    my $self = shift;
    my @keys = @_;

    return $self->{keys} unless(scalar @keys);
    push @{$self->{keys}}, [@keys];
    $self;
}

sub rollup {
    my $self = shift;
    my ($name, $func) = @_;

    push @{$self->{rollups}}, {name => $name, func => $func};
    $self;
}

sub _entries {
    my $self = shift;
    my $array = shift;
    my $depth = shift;
    return $array if($depth >= scalar @{$self->{keys}});
    my $key = $self->{keys}[$depth];

    my $branch = [];
    my %map;

    foreach my $obj (@$array){
        my $k = join($self->{delimiter}, map { (ref $_ ne "CODE") ? (exists $obj->{$_} ? $obj->{$_} : $self->{delimiter}) : $_->($obj); } @$key);
        $map{$k} = [] unless exists $map{$k};
        push @{$map{$k}}, $obj;
    }

    foreach my $k (sort keys %map){
        my $values = $self->_entries($map{$k}, $depth+1);
        my $obj = {};
        $obj->{$self->{keyname}} = $k;
        $obj->{$self->{valname}} = $values;
        if($depth + 1 >= scalar @{$self->{keys}}){
            foreach my $roll (@{$self->{rollups}}){
                $obj->{$roll->{name}} = $roll->{func}(@$values);
            }
            if($self->{noValues}){
                delete $obj->{$self->{valname}};
            }
        }
        push @$branch, $obj;
    }

    $branch;
}

sub entries {
    my $self = shift;
    my $data = shift;
    $self->_entries($data, 0);
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Nest - nest array of hash easily. and calculate optional measurements corresponding to results of nest.

=head1 SYNOPSIS

    use Data::Nest;

    my $nest = Data::Nest->new();
    $nest->key("mykey");
    my $nested = $nest->entries([
      {mykey => 1, val => 1},
      {mykey => 2, val => 2},
      {mykey => 1, val => 3},
      {mykey => 1, val => 4},
      {mykey => 2, val => 5},
    ]);
    print Dumper $nested;

    # [
    #   {key => 1, values => [
    #     {mykey => 1, val => 1},
    #     {mykey => 1, val => 3},
    #     {mykey => 1, val => 4},
    #   ]},
    #   {key => 2, values => [
    #     {mykey => 2, val => 2},
    #     {mykey => 2, val => 5},
    #   ]},
    # ]

=head1 DESCRIPTION

Data::Nest is array of hash nesting utility.
Easily add measurements like "sum", "sumsq", "average",....
It's easy to nest data for prepareing data mining and data visualization.

=head1 LICENSE

Copyright (C) muddydixon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

muddydixon E<lt>muddydixon@gmail.comE<gt>

=cut
