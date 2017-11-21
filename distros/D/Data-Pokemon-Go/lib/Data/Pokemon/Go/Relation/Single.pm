package Data::Pokemon::Go::Relation::Single;
use 5.008001;
use Carp;

use Moose;
use Moose::Util::TypeConstraints;

with 'Data::Pokemon::Go::Role::Types';

# accessor methods ========================================================

subtype 'Types' => as 'ArrayRef[Type]';
coerce 'Types'
    => from 'Type'
    => via {[$_]};
has types => ( is => 'ro', isa => 'Types', coerce => 1, required => 1 );

__PACKAGE__->meta->make_immutable;
no Moose;

my $relations = $Data::Pokemon::Go::Role::Types::Relations;
my $ref_advantage = $Data::Pokemon::Go::Role::Types::Ref_Advantage;

# subroutine ==============================================================

sub effective {
    my $self = shift;
    my $type = $self->types()->[0];
    my $data = $relations->{$type};
    return @{ $data->{effective} || [] } if $data->{effective};
    return;
}

sub invalid {
    my $self = shift;
    my $type = $self->types()->[0];
    my $data = $relations->{$type};
    my @list = @{ $data->{invalid} || [] };
    unshift @list, @{ $data->{void} } if $data->{void};
    return @list if @list;
    return;
}

sub advantage {
    my $self = shift;
    my $type = $self->types()->[0];
    my $data = $ref_advantage->{$type};
    my @list = @{ $data->{invalid} || [] };
    unshift @list, @{ $data->{void} || [] };
    my $i = 0;
    foreach my $value (@list) {
        foreach my $type ( $self->invalid() ){
            splice @list, $i, 1 if $type eq $value;
        }
        $i++;
    }
    return @list;
}

sub disadvantage {
    my $self = shift;
    my $type = $self->types()->[0];
    my $data = $ref_advantage->{$type};
    return @{ $data->{effective} || [] };
}

sub recommended {
    my $self = shift;
    my @recommended = ();
    foreach my $type1 ( $self->effective() ){
        foreach my $type2 ( $self->advantage() ){
            push @recommended, $type1 if $type1 && $type2 and $type1 eq $type2;
        }
    }
    return @recommended if @recommended;

    @recommended = $self->effective(), $self->advantage();
    for( my $i = 0; $i <= @recommended; $i++ ) {
        next unless $recommended[$i];
        foreach my $type ( $self->disadvantage() ) {
            splice @recommended, $i, 1 if $type eq $recommended[$i];
        }
    }
    return @recommended;
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Pokemon::Go::Relation::Single - It's new $module

=head1 SYNOPSIS

    use Data::Pokemon::Go::Relation::Single;

=head1 DESCRIPTION

Data::Pokemon::Go::Relation::Single is ...

=head1 LICENSE

Copyright (C) Yuki Yoshida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida E<lt>worthmine@gmail.comE<gt>

=cut

