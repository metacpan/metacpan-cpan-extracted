package Data::Pokemon::Go::Relation::Dual;
use 5.008001;

use Moose;

extends 'Data::Pokemon::Go::Relation::Single';

# subroutine ==============================================================

override 'effective' => sub {
    my $self = shift;
    return super() if @{ $self->types() } == 1;

    my @types = map{ Data::Pokemon::Go::Relation::Single->new( types => $_ ) } @{ $self->types() };

    my %hash;
    foreach my $type ( $types[0]->effective(), $types[1]->effective() ) {
        $hash{$type} = $hash{$type}? 1.96: 1.4;
    }

    foreach my $type ( $types[0]->invalid(), $types[1]->invalid() ) {
        delete $hash{$type} if $hash{$type};
    }

    my @list = ();
    while( my ( $type, $damage ) = each %hash ) {
        push @list, { type => $type, damage => $damage };
    }
    my @order = sort{ $b->{damage} <=> $a->{damage} } @list;
    return map{ $_->{type} } @order if wantarray;
    return $order[0]{type} if @order == 1;
    return $order[0]{type} if $order[0]{damage} > 1.4;
    return;
};

override 'invalid' => sub {
    my $self = shift;
    return super() if @{ $self->types() } == 1;

    my @types = map{ Data::Pokemon::Go::Relation::Single->new( types => $_ ) } @{ $self->types() };

    my %hash;
    foreach my $type ( $types[0]->invalid(), $types[1]->invalid() ) {
        $hash{$type} = $hash{$type}? 0.51: 0.714;
    }

    foreach my $type ( $types[0]->effective(), $types[1]->effective() ) {
        delete $hash{$type};
    }

    my @list = ();
    while( my ( $type, $damage ) = each %hash ) {
        push @list, { type => $type, damage => $damage };
    }
    my @order = sort{ $a->{damage} <=> $b->{damage} } @list;
    return map{ $_->{type} } @order if wantarray;
    return $order[0]{type} if @order == 1;
    return $order[0]{type} if $order[0]{damage} < 0.714;
    return;
};

override 'advantage' => sub {
    my $self = shift;
    return super() if @{ $self->types() } == 1;

    my @types = map{ Data::Pokemon::Go::Relation::Single->new( types => $_ ) } @{ $self->types() };

    my %hash;
    foreach my $type ( $types[0]->advantage(), $types[1]->advantage() ) {
        $hash{$type} = $hash{$type}? 0.51: 0.714;
    }

    my %average;
    foreach my $type0 ( $types[0]->advantage() ){
        foreach my $type1 ( $types[1]->disadvantage() ){
            $average{$type0} ||= 1 if $type0 eq $type1;
        }
    }
    foreach my $type0 ( $types[0]->disadvantage() ){
        foreach my $type1 ( $types[1]->advantage() ){
            $average{$type0} ||= 1 if $type0 eq $type1;
        }
    }

    foreach my $type ( $self->invalid(), keys %average ) {
        delete $hash{$type};
    }

    my @list = ();
    while( my ( $type, $damage ) = each %hash ) {
        push @list, { type => $type, damage => $damage };
    }
    my @order = sort{ $a->{damage} <=> $b->{damage} } @list;
    return map{ $_->{type} } @order if wantarray;
    return $order[0]{type} if @order == 1;
    return $order[0]{type} if $order[0]{damage} < 0.714;
    return;
};

override 'disadvantage' => sub {
    my $self = shift;
    return super() if @{ $self->types() } == 1;

    my @types = map{ Data::Pokemon::Go::Relation::Single->new( types => $_ ) } @{ $self->types() };

    my %hash;
    foreach my $type ( $types[0]->disadvantage(), $types[1]->disadvantage() ) {
        $hash{$type} = $hash{$type}? 1.96: 1.4;
    }

    my %average;
    foreach my $type0 ( $types[0]->advantage() ){
        foreach my $type1 ( $types[1]->disadvantage() ){
            $average{$type0} ||= 1 if $type0 eq $type1;
        }
    }
    foreach my $type0 ( $types[0]->disadvantage() ){
        foreach my $type1 ( $types[1]->advantage() ){
            $average{$type0} ||= 1 if $type0 eq $type1;
        }
    }

    foreach my $type ( keys %average ) {
        delete $hash{$type};
    }

    foreach my $type ( $self->effective() ) {
        my $attacker = Data::Pokemon::Go::Relation::Single->new( types => $type );
        foreach my $effective ( $attacker->effective() ) {
            $hash{$type} ||= 1 if grep{ $_ eq $effective } @{ $self->types() };
        }
    }

    my @list = ();
    while( my ( $type, $damage ) = each %hash ) {
        push @list, { type => $type, damage => $damage };
    }
    my @order = sort{ $b->{damage} <=> $a->{damage} } @list;
    return map{ $_->{type} } @order if wantarray;
    return $order[0]{type} if @order == 1;
    return $order[0]{type} if $order[0]{damage} > 1.4;
    return;
};

override 'recommended' => sub {
    my $self = shift;
    return super() if @{ $self->types() } == 1;

    my @recommended = ();
    foreach my $type1 ( $self->effective() ){
        foreach my $type2 ( $self->advantage() ){
            push @recommended, $type1 if $type1 && $type2 and $type1 eq $type2;
        }
    }
    @recommended = ( $self->effective(), $self->advantage() ) unless @recommended;
    my $effective = $self->effective();
    if (
        $effective
        and not grep{ /^$effective$/ } $self->disadvantage()
        and not grep{ /^$effective$/ } @recommended
    ) {
        unshift @recommended, $effective;
    }

    for( my $i = 0; $i <= @recommended; $i++ ) {
        next unless $recommended[$i];
        foreach my $type ( $self->disadvantage() ) {
                splice @recommended, $i, 1 if $type eq $recommended[$i];
        }
    }
    return @recommended;
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
__END__

=encoding utf-8

=head1 NAME

Data::Pokemon::Go::Relation::Dual - It's new $module

=head1 SYNOPSIS

    use Data::Pokemon::Go::Relation::Dual;

=head1 DESCRIPTION

Data::Pokemon::Go::Relation::Dual is ...

=head1 LICENSE

Copyright (C) Yuki Yoshida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida E<lt>worthmine@gmail.comE<gt>

=cut

