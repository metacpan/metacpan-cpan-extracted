package Bio::Phylo::BeagleOperation;
use strict;
use warnings;
use beagle;
use base 'Bio::Phylo';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

our $AUTOLOAD;
my %op;

sub get_op { $op{shift->get_id} }

sub AUTOLOAD {
    my $self   = shift;
    my $value  = shift;
    my $method = $AUTOLOAD;
    my $op = $self->get_op;
    if ( not $op ) {
        $op = beagle::BeagleOperation->new;
        $op{$self->get_id} = $op;
    }
    if ( $method =~ /(s|g)et_(\S+)$/ ) {
        my $setter = $1;
        my $field = $2;
        my @parts = split /_/, $field;
        my $key = $parts[0];
        for my $i ( 1 .. $#parts ) {
            $key .= ucfirst $parts[$i];
        }
        if ( $setter eq 's' ) {
            $op->{$key} = $value;
            return $self;
        }
        elsif ( $setter eq 'g' ) {
            return $op->{$key};
        }
    }
    
}

1;
