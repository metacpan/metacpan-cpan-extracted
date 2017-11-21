package Data::Pokemon::Go::Role::Types;
use 5.008001;
use utf8;
use Encode;

use Moose::Role;
use Moose::Util::TypeConstraints;

our @All = qw(
    ノーマル かくとう どく じめん ひこう むし いわ
    ゴースト はがね ほのお みず でんき くさ こおり
    エスパー ドラゴン あく フェアリー
);

enum 'Type' => \@All;
has types => ( is => 'rw', default => 'ノーマル', isa => 'Type' );

no Moose::Role;

# initialize ==============================================================
use Path::Tiny;
use YAML::XS;

my $relation = path( 'data', 'Relations.yaml' );
our $Ref_Advantage = YAML::XS::LoadFile($relation);
our $Relations = {};

while( my( $type, $ref ) = each %$Ref_Advantage ){
    while( my( $relation, $values ) = each %$ref ){
        next unless ref $values;
        foreach my $value (@$values){
            push @{$Relations->{$value}{invalid}}, $type if $relation eq 'invalid';
            unshift @{$Relations->{$value}{invalid}}, $type if $relation eq 'void';
            push @{$Relations->{$value}{effective}}, $type if $relation eq 'effective';
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Pokemon::Go::Role::Types - It's new $module

=head1 SYNOPSIS

    use Data::Pokemon::Go::Role::Types;

=head1 DESCRIPTION

Data::Pokemon::Go::Role::Types is ...

=head1 LICENSE

Copyright (C) Yuki Yoshida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida E<lt>worthmine@gmail.comE<gt>

=cut

