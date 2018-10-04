package Data::Pokemon::Go::Skill;
use 5.008001;
use utf8;

use Moose;
use Moose::Util::TypeConstraints;
use YAML::XS;
use File::Share 'dist_dir';
my $dir = dist_dir('Data-Pokemon-Go');

with 'Data::Pokemon::Go::Role::Types';

my $data = YAML::XS::LoadFile("$dir/Skill.yaml");
map{ $data->{$_}{name} = $_ } keys %$data;
our @All = map{ $_->{name} } sort{ $a->{type} cmp $b->{type} } values %$data;

enum 'SkillName' => \@All;
has name => ( is => 'rw', isa => 'SkillName' );

has own_type => ( is => 'rw', isa => 'ArrayRef[Type]' );

around 'types' => sub {
    my $orig = shift;
    my $self = shift;
    my $name = $self->name();
    my $type = $data->{$name}{type};
    die "Type may be invalid: $type" unless $type;
    die "Type may be invalid: $type" unless $name eq 'めざめるパワー' or grep{ $type eq $_ } @Data::Pokemon::Go::Role::Types::All;
    return $self->$orig($type) unless $name eq 'めざめるパワー';
    return 'ランダム';
};

__PACKAGE__->meta->make_immutable;
no Moose;

sub exists {
    my $self = shift;
    my $name = shift;
    return CORE::exists $data->{$name};
}

sub strength {
    my $self = shift;
    my $name = $self->name();
    my $num = $data->{$name}{power};
    die "'power' may be invalid: $num" unless $num =~ /^\d{1,3}$/;
    $num *= 1.2 if grep{ $_ eq $self->types() } @{ $self->own_type() || [] };
    return $num;
}

sub motion {
    my $self = shift;
    my $name = $self->name();
    my $num = $data->{$name}{motion};
    die "'motion' may be invalid: $num" unless $num =~ /^\d{3,4}$/;
    return $num || 0.00;
}

sub gauges {
    my $self = shift;
    my $name = $self->name();
    my $num = $data->{$name}{gauges} || 0;
    die "'gauges' may be invalid: $num" unless $num =~ /^(:?0|1|2|3)$/;
    return $num;
}

sub energy {
    my $self = shift;
    my $name = $self->name();
    return $data->{$name}{'energy'} || 0;
}

sub EPS {
    my $self = shift;
    return 0.00 unless $self->energy;
    my $eps = int( $self->energy / $self->motion * 100000 + 0.5 ) / 100;
    return sprintf('%2d.%02d', int $eps, $eps % 1 );
}

sub DPS {
    my $self = shift;
    my $dps = $self->gauges()?
    int( $self->strength() / ( $self->motion() / 1000 + 1 ) * 100 + 0.5 ):
    int( $self->strength() / ( $self->motion() / 1000     ) * 100 + 0.5 );
    return sprintf('%2d.%02d', int $dps / 100 , $dps % 100 );
}

sub point {
    my $self = shift;
    my $point = $self->gauges()?
        ( $self->strength * 1000 - $self->motion ) / ( $self->motion + 1000 ) * 100:
        ( ( $self->strength + $self->energy ) / 2 * 1000  - $self->motion )/ $self->motion * 100;
    return sprintf('%2d.%02d', int $point / 100, $point % 100 ) if $point > 0;
    return '0.00';
}

sub as_string {
    my $self = shift;
    my $better = '';
    $better = '(タイプ一致)' if grep{ $_ eq $self->type() } @{ $self->own_type() || [] };
    my $str = $self->gauges()?
        sprintf("%s(%s) 攻撃力:%.2f DPS:%.2f ゲージ数:%d 評価:%.2f%s\n",
            $self->name,
            $self->types,
            $self->strength,
            $self->DPS(),
            $self->gauges(),
            $self->point(),
            $better,
        ):
        sprintf("%s(%s) 攻撃力:%.2f DPS:%.2f EPS:%.2f 評価:%.2f%s\n",
            $self->name,
            $self->types,
            $self->strength,
            $self->DPS(),
            $self->EPS(),
            $self->point(),
            $better,
        );

    return $str;
}


1;
__END__

=encoding utf-8

=head1 NAME

Data::Pokemon::Go::Relaition - It's new $module

=head1 SYNOPSIS

    use Data::Pokemon::Go::Relaition;

=head1 DESCRIPTION

Data::Pokemon::Go::Relaition is ...

=head1 LICENSE

Copyright (C) Yuki Yoshida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida E<lt>worthmine@gmail.comE<gt>

=cut

