package App::Mowyw::Datasource::Array;

use strict;
use warnings;
use base 'App::Mowyw::Datasource';
use Scalar::Util qw(reftype);

use Carp qw(confess);
#use Data::Dumper;

sub new {
    my ($class, $opts) = @_;
    my $self = bless { OPTIONS => $opts, INDEX => 0 },  ref $class ? ref $class : $class;

#    print Dumper $opts;
    $self->{DATA} = $opts->{source} or confess "Mandatory option 'source' is missing\n";
    if (reftype($self->{DATA}) ne 'ARRAY'){
        confess "Source must be an array";
    }
    if (exists $opts->{limit}){
        $self->{remaining} = $opts->{limit};
    }
    return $self;
}

sub is_exhausted {
    my $self = shift;
    return 1 if (exists $self->{remaining} && $self->{remaining} == 0);
    return scalar(@{$self->{DATA}}) <= $self->{INDEX}
}

sub get {
    my $self = shift;
    $self->{remaining}-- if exists $self->{remaining};
    return $self->{DATA}[$self->{INDEX}];
}

sub next {
    shift->{INDEX}++;
}

sub reset {
    shift->{INDEX} = 0;
}

1;
