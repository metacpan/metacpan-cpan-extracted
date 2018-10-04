package Data::Pokemon::Go::IV;
use 5.008001;
use Carp;
use YAML::XS;
use List::Util qw(first);
use File::Share 'dist_dir';
my $dir = dist_dir('Data-Pokemon-Go');

use Moose;
__PACKAGE__->meta->make_immutable;
no Moose;

my $data = YAML::XS::LoadFile("$dir/LV.yaml");
my %Dust = ();
push @{ $Dust{ $_->{Dust} } }, { LV => $_->{LV}, Candy => $_->{Candy} } foreach @$data;

sub _calculate_CP {
    my $self = shift;
    my %arg = @_;
    croak "argument 'name' is required" unless exists $arg{name};
    croak "argument 'LV' is required" unless exists $arg{LV};
    croak "argument 'ST' is required" unless exists $arg{ST};
    croak "argument 'AT' is required" unless exists $arg{AT};
    croak "argument 'DF' is required" unless exists $arg{DF};

    my $pg = Data::Pokemon::Go::Pokemon->new( name => $arg{name} );
    my $stamina = $pg->stamina() + $arg{ST};
    my $attack = $pg->attack() + $arg{AT};
    my $defense = $pg->defense() + $arg{DF};
    my $CPM = $self->_calculate_CPM( from => $arg{LV} );
    my $CP = int( sqrt($stamina) * $attack * sqrt($defense) * $CPM ** 2 / 10 );
    return $CP if $CP > 10;
    return 10;
}

sub _calculate_CPM {
    my $self = shift;
    my %arg = @_;
    croak "argument 'from' is required" unless exists $arg{from};
    my $ref = first{ $_->{LV} == $arg{from} } @$data;
    return $ref->{CPM};
}

sub _calculate_HP {
    my $self = shift;
    my %arg = @_;
    croak "argument 'name' is required" unless exists $arg{name};
    croak "argument 'LV' is required" unless exists $arg{LV};
    croak "argument 'ST' is required" unless exists $arg{ST};

    my $CPM = $self->_calculate_CPM( from => $arg{LV} );
    my $pg = Data::Pokemon::Go::Pokemon->new( name => $arg{name} );
    return int ( ( $pg->stamina() + $arg{ST} ) * $CPM );
}

sub _guess_LV {
    my $self = shift;
    my %arg = @_;
    croak "argument 'name' is required" unless exists $arg{name};
    croak "argument 'HP' is required" unless exists $arg{HP};
    croak "argument 'ST' is required" unless exists $arg{ST};

    my $pg = Data::Pokemon::Go::Pokemon->new( name => $arg{name} );
    my @LV = ();
    for( my $i = 1.0; $i <= 40.5; $i += 0.5 ){
        push @LV, $i if $self->_calculate_HP( @_, LV => $i ) == $arg{HP};
    }
    return @LV;
}

sub _guess_ST {
    my $self = shift;
    my %arg = @_;
    croak "argument 'name' is required" unless exists $arg{name};
    croak "argument 'HP' is required" unless exists $arg{HP};
    my $ST = 0;
    for( my $i = 0; $i <= 15; $i++ ){
        return $i if $self->_guess_LV( @_, ST => $i );
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Pokemon::Go::IV - It's new $module

=head1 SYNOPSIS

    use Data::Pokemon::Go::IV;

=head1 DESCRIPTION

Data::Pokemon::Go::IV is ...

=head1 LICENSE

Copyright (C) Yuki Yoshida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida E<lt>worthmine@gmail.comE<gt>

=cut

