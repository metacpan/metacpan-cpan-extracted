package Bubblegum::Object::Role::Coercive;

use 5.10.0;
use namespace::autoclean;
use Bubblegum::Role;

use Carp 'confess';

our $VERSION = '0.45'; # VERSION

my $coercable = {
    'UNDEF' => {
        'UNDEF'  => sub { $_[0] },
        'CODE'   => sub { my $this = $_[0]; sub { $this } },
        'NUMBER' => sub { 0 },
        'HASH'   => sub { +{} },
        'ARRAY'  => sub { [undef] },
        'STRING' => sub { "" },
    },
    'CODE' => {
        'UNDEF'  => sub { undef },
        'CODE'   => sub { $_[0] },
        'ARRAY'  => sub { [$_[0]] },
        'NUMBER' => sub { confess 'code to number coercion not possible' },
        'HASH'   => sub { confess 'code to hash coercion not possible' },
        'STRING' => sub { confess 'code to string coercion not possible' },
    },
    'NUMBER' => {
        'UNDEF'  => sub { undef },
        'CODE'   => sub { my $this = $_[0]; sub { $this } },
        'NUMBER' => sub { $_[0] },
        'HASH'   => sub { +{ $_[0] => 1 } },
        'ARRAY'  => sub { [$_[0]] },
        'STRING' => sub { "$_[0]" },
    },
    'HASH' => {
        'UNDEF'  => sub { undef },
        'CODE'   => sub { my $this = $_[0]; sub { $this } },
        'NUMBER' => sub { keys %{$_[0]} },
        'HASH'   => sub { $_[0] },
        'ARRAY'  => sub { [$_[0]] },
        'STRING' => sub { $_[0]->dump },
    },
    'ARRAY' => {
        'UNDEF'  => sub { undef },
        'CODE'   => sub { my $this = $_[0]; sub { $this } },
        'NUMBER' => sub { scalar @{$_[0]} },
        'HASH'   => sub { +{ (@{$_[0]} % 2) ? (@{$_[0]}, undef) : @{$_[0]} } },
        'ARRAY'  => sub { $_[0] },
        'STRING' => sub { $_[0]->dump },
    },
    'STRING' => {
        'UNDEF'  => sub { undef },
        'CODE'   => sub { my $this = $_[0]; sub { $this } },
        'NUMBER' => sub { 0 + (join('', $_[0] =~ /[\d\.]/g) || 0) },
        'HASH'   => sub { +{ $_[0] => 1 } },
        'ARRAY'  => sub { [$_[0]] },
        'STRING' => sub { $_[0] },
    }
};

$coercable->{INTEGER} = $coercable->{NUMBER};
$coercable->{FLOAT}   = $coercable->{NUMBER};

sub to_array {
    my $self = shift;
    my $coerce = 'ARRAY';
    return unless my $type = $self->type;
    return $coercable->{$type}{$coerce}->($self);
}

sub to_code {
    my $self = shift;
    my $coerce = 'CODE';
    return unless my $type = $self->type;
    return $coercable->{$type}{$coerce}->($self);
}

sub to_hash {
    my $self = shift;
    my $coerce = 'HASH';
    return unless my $type = $self->type;
    return $coercable->{$type}{$coerce}->($self);
}

sub to_number {
    my $self = shift;
    my $coerce = 'NUMBER';
    return unless my $type = $self->type;
    return $coercable->{$type}{$coerce}->($self);
}

sub to_string {
    my $self = shift;
    my $coerce = 'STRING';
    return unless my $type = $self->type;
    return $coercable->{$type}{$coerce}->($self);
}

sub to_undef {
    my $self = shift;
    my $coerce = 'UNDEF';
    return unless my $type = $self->type;
    return $coercable->{$type}{$coerce}->($self);
}

{
    no warnings 'once';
    *to_a = \&to_array;
    *to_c = \&to_code;
    *to_h = \&to_hash;
    *to_n = \&to_number;
    *to_s = \&to_string;
    *to_u = \&to_undef;
}

1;
