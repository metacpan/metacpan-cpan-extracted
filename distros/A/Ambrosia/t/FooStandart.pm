package Foo;
use strict;
use warnings;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    return bless {}, $class;
}

sub pro_a{my $self=shift; if (my $v = shift) {$self->{pro_a}=$v;} return $self->{pro_a};}
sub pro_b{my $self=shift; if (my $v = shift) {$self->{pro_b}=$v;} return $self->{pro_b};}
sub pro_c{my $self=shift; if (my $v = shift) {$self->{pro_c}=$v;} return $self->{pro_c};}
sub pro_d{my $self=shift; if (my $v = shift) {$self->{pro_d}=$v;} return $self->{pro_d};}
sub pro_e{my $self=shift; if (my $v = shift) {$self->{pro_e}=$v;} return $self->{pro_e};}
sub pro_f{my $self=shift; if (my $v = shift) {$self->{pro_f}=$v;} return $self->{pro_f};}
sub pro_g{my $self=shift; if (my $v = shift) {$self->{pro_g}=$v;} return $self->{pro_g};}
sub pro_h{my $self=shift; if (my $v = shift) {$self->{pro_h}=$v;} return $self->{pro_h};}
sub pro_i{my $self=shift; if (my $v = shift) {$self->{pro_i}=$v;} return $self->{pro_i};}
sub pro_j{my $self=shift; if (my $v = shift) {$self->{pro_j}=$v;} return $self->{pro_j};}
sub pro_k{my $self=shift; if (my $v = shift) {$self->{pro_k}=$v;} return $self->{pro_k};}
sub pro_l{my $self=shift; if (my $v = shift) {$self->{pro_l}=$v;} return $self->{pro_l};}
sub pro_m{my $self=shift; if (my $v = shift) {$self->{pro_m}=$v;} return $self->{pro_m};}
sub pro_n{my $self=shift; if (my $v = shift) {$self->{pro_n}=$v;} return $self->{pro_n};}
sub pro_o{my $self=shift; if (my $v = shift) {$self->{pro_o}=$v;} return $self->{pro_o};}
sub pro_p{my $self=shift; if (my $v = shift) {$self->{pro_p}=$v;} return $self->{pro_p};}
sub pro_q{my $self=shift; if (my $v = shift) {$self->{pro_q}=$v;} return $self->{pro_q};}
sub pro_r{my $self=shift; if (my $v = shift) {$self->{pro_r}=$v;} return $self->{pro_r};}
sub pro_s{my $self=shift; if (my $v = shift) {$self->{pro_s}=$v;} return $self->{pro_s};}
sub pro_t{my $self=shift; if (my $v = shift) {$self->{pro_t}=$v;} return $self->{pro_t};}
sub pro_u{my $self=shift; if (my $v = shift) {$self->{pro_u}=$v;} return $self->{pro_u};}
sub pro_v{my $self=shift; if (my $v = shift) {$self->{pro_v}=$v;} return $self->{pro_v};}
sub pro_w{my $self=shift; if (my $v = shift) {$self->{pro_w}=$v;} return $self->{pro_w};}
sub pro_x{my $self=shift; if (my $v = shift) {$self->{pro_x}=$v;} return $self->{pro_x};}
sub pro_y{my $self=shift; if (my $v = shift) {$self->{pro_y}=$v;} return $self->{pro_y};}
sub pro_z{my $self=shift; if (my $v = shift) {$self->{pro_z}=$v;} return $self->{pro_z};}

sub pri_a{my $self=shift; if (my $v = shift) {$self->{pri_a}=$v;} return $self->{pri_a};}
sub pri_b{my $self=shift; if (my $v = shift) {$self->{pri_b}=$v;} return $self->{pri_b};}
sub pri_c{my $self=shift; if (my $v = shift) {$self->{pri_c}=$v;} return $self->{pri_c};}
sub pri_d{my $self=shift; if (my $v = shift) {$self->{pri_d}=$v;} return $self->{pri_d};}
sub pri_e{my $self=shift; if (my $v = shift) {$self->{pri_e}=$v;} return $self->{pri_e};}
sub pri_f{my $self=shift; if (my $v = shift) {$self->{pri_f}=$v;} return $self->{pri_f};}
sub pri_g{my $self=shift; if (my $v = shift) {$self->{pri_g}=$v;} return $self->{pri_g};}
sub pri_h{my $self=shift; if (my $v = shift) {$self->{pri_h}=$v;} return $self->{pri_h};}
sub pri_i{my $self=shift; if (my $v = shift) {$self->{pri_i}=$v;} return $self->{pri_i};}
sub pri_j{my $self=shift; if (my $v = shift) {$self->{pri_j}=$v;} return $self->{pri_j};}
sub pri_k{my $self=shift; if (my $v = shift) {$self->{pri_k}=$v;} return $self->{pri_k};}
sub pri_l{my $self=shift; if (my $v = shift) {$self->{pri_l}=$v;} return $self->{pri_l};}
sub pri_m{my $self=shift; if (my $v = shift) {$self->{pri_m}=$v;} return $self->{pri_m};}
sub pri_n{my $self=shift; if (my $v = shift) {$self->{pri_n}=$v;} return $self->{pri_n};}
sub pri_o{my $self=shift; if (my $v = shift) {$self->{pri_o}=$v;} return $self->{pri_o};}
sub pri_p{my $self=shift; if (my $v = shift) {$self->{pri_p}=$v;} return $self->{pri_p};}
sub pri_q{my $self=shift; if (my $v = shift) {$self->{pri_q}=$v;} return $self->{pri_q};}
sub pri_r{my $self=shift; if (my $v = shift) {$self->{pri_r}=$v;} return $self->{pri_r};}
sub pri_s{my $self=shift; if (my $v = shift) {$self->{pri_s}=$v;} return $self->{pri_s};}
sub pri_t{my $self=shift; if (my $v = shift) {$self->{pri_t}=$v;} return $self->{pri_t};}
sub pri_u{my $self=shift; if (my $v = shift) {$self->{pri_u}=$v;} return $self->{pri_u};}
sub pri_v{my $self=shift; if (my $v = shift) {$self->{pri_v}=$v;} return $self->{pri_v};}
sub pri_w{my $self=shift; if (my $v = shift) {$self->{pri_w}=$v;} return $self->{pri_w};}
sub pri_x{my $self=shift; if (my $v = shift) {$self->{pri_x}=$v;} return $self->{pri_x};}
sub pri_y{my $self=shift; if (my $v = shift) {$self->{pri_y}=$v;} return $self->{pri_y};}
sub pri_z{my $self=shift; if (my $v = shift) {$self->{pri_z}=$v;} return $self->{pri_z};}

1;
