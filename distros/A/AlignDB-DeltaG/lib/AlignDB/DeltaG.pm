package AlignDB::DeltaG;
use Moose;
use YAML::Syck;

our $VERSION = '1.1.0';

has 'temperature' => ( is => 'rw', isa => 'Num', default => sub {37.0}, );
has 'salt_conc'   => ( is => 'rw', isa => 'Num', default => sub {1.0}, );
has 'deltaH'      => ( is => 'ro', isa => 'HashRef', );
has 'deltaS'      => ( is => 'ro', isa => 'HashRef', );
has 'deltaG'      => ( is => 'ro', isa => 'HashRef', );

sub BUILD {
    my $self = shift;

    # Load thermodynamic data
    my ( $deltaH, $deltaS ) = $self->_load_thermodynamic_data;
    $self->{deltaH} = $deltaH;
    $self->{deltaS} = $deltaS;

    # Recalculate the deltaG hash on current temperature and salt conditions
    my $deltaG = $self->_init_deltaG;
    $self->{deltaG} = $deltaG;

    return;
}

sub polymer_deltaG {
    my $self    = shift;
    my $polymer = shift;

    $polymer = uc $polymer;
    return if $polymer =~ /[^AGCT]/;

    my $deltaG = $self->deltaG;

    my $polymer_len = length $polymer;
    my $dG          = 0;

    # calculate deltaG
    foreach ( 0 .. $polymer_len - 2 ) {
        my $nn = substr( $polymer, $_, 2 );
        $dG += $deltaG->{$nn};
    }

    # terminal correction
    my $init_terminal = "init" . substr( $polymer, 0, 1 );
    $dG += $deltaG->{$init_terminal};

    my $end_terminal = "init" . substr( $polymer, -1, 1 );
    $dG += $deltaG->{$end_terminal};

    # Symmetry correction
    my $rc_polymer = $self->_rev_com($polymer);
    if ( $polymer eq $rc_polymer ) {
        $dG += $deltaG->{sym};
    }

    return $dG;
}

# Load thermodynamic data comes from references
sub _load_thermodynamic_data {
    my $self = shift;

    #-------------------#
    # deltaH (kcal/mol)
    #-------------------#
    my %deltaH = qw{
        AA -7.6 TT -7.6
        AT -7.2
        TA -7.2
        CA -8.5 TG -8.5
        GT -8.4 AC -8.4
        CT -7.8 AG -7.8
        GA -8.2 TC -8.2
        CG -10.6
        GC -9.8
        GG -8.0 CC -8.0
        initC 0.2 initG 0.2
        initA 2.2 initT 2.2
        sym 0.0
    };

    #--------------------#
    # deltaS (cal/K.mol)
    #--------------------#
    my %deltaS = qw{
        AA -21.3 TT -21.3
        AT -20.4
        TA -21.3
        CA -22.7 TG -22.7
        GT -22.4 AC -22.4
        CT -21.0 AG -21.0
        GA -22.2 TC -22.2
        CG -27.2
        GC -24.4
        GG -19.9 CC -19.9
        initC -5.7 initG -5.7
        initA 6.9 initT 6.9
        sym -1.4
    };

    return ( \%deltaH, \%deltaS );
}

# Recalculate deltaG by the new temperature and salt_conc values
sub _init_deltaG {
    my $self = shift;

    # dG = dH - TdS, and dS is dependent on the salt concentration
    my $temperature = $self->temperature;
    my $salt_conc   = $self->salt_conc;
    my $deltaH      = $self->deltaH;
    my $deltaS      = $self->deltaS;

    my %deltaG = qw{
        initC 1.96
        initG 1.96
        initA 0.05
        initT 0.05
        sym 0.43
    };

    # the length of each NN dimer is 2, therefore the modifier is 1
    # total sodium concentration should be above 0.05 M and below 1.1 M
    my $entropy_adjust = ( 0.368 * log($salt_conc) );

    foreach my $key ( keys %{$deltaH} ) {

        # the length of each monomer is 1, thus the modifier of dS is 0
        # and the values are precalulated
        next if $key =~ /init|sym/;

        my $dS = $deltaS->{$key} + $entropy_adjust;
        my $dG
            = $deltaH->{$key} - ( ( 273.15 + $temperature ) * ( $dS / 1000 ) );
        $deltaG{$key} = $dG;
    }

    return \%deltaG;
}

sub _rev_com {
    my $self     = shift;
    my $sequence = shift;

    $sequence = reverse $sequence;                       # reverse
    $sequence =~ tr/ACGTMRWSYKVHDBN/TGCAKYSWRMBDHVN/;    # complement

    return $sequence;
}

1;    # Magic true value required at end of module

__END__

=pod

=encoding UTF-8

=head1 NAME

AlignDB::DeltaG - Calculate deltaG of polymer DNA sequences

=head1 SYNOPSIS

=over 2

=item Normal use

    use AlignDB::DeltaG
    my $deltaG = AlignDB::DeltaG->new(
        temperature => 37,
        salt_conc   => 1,
    );
    my $seq = "TAACAAGCAATGAGATAGAGAAAGAAATATATCCA";
    print "$seq deltaG: ", $deltaG->polymer_deltaG($seq), "\n";

=item Reset conditionss

    use AlignDB::DeltaG;
    # default value:
    #   temperature => 37,
    #   salt_conc   => 1,
    my $deltaG = AlignDB::DeltaG->new;
    $deltaG->temperature(30);
    $deltaG->salt_conc(0.1);
    $deltaG->BUILD;
    my $seq = "TAACAAGCAATGAGATAGAGAAAGAAATATATCCA";
    print "$seq deltaG: ", $deltaG->polymer_deltaG($seq), "\n";

=back

=head1 DESCRIPTION

C<AlignDB::DeltaG> is a simple class to calculate deltaG of polymer DNA sequences using the NN model.

In the near future, it may be extanded to calculate oligonucleotide thermodynamics.

=head2 Reference

 1. SantaLucia J, Jr. 2004. Annu Rev Biophys Biomol Struct;
 2. SantaLucia J, Jr. 1998. Proc Natl Acad Sci U S A;

=head1 ATTRIBUTES

C<temperature> - default: 37.0 degree centigrade

C<salt_conc> - salt concentration, Default: 1 [Na+], in M. Should be above 0.05 M and below 1.1 M

C<deltaH> - enthalpy, isa HashRef

C<deltaS> - entropy (cal/K.mol), isa HashRef

C<deltaG> - free energy, isa HashRef

=head1 METHODS

=head2 BUILD

rebuild the object by the new temperature and/or salt_conc values

=head2 polymer_deltaG

    my $dG = $obj->polymer_deltaG($seq);

Calculate deltaG of a given sequence.

This method is the main calculating sub.

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
