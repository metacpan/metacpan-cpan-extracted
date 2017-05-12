package Bio::Tools::Run::QCons;
{
  $Bio::Tools::Run::QCons::VERSION = '0.112881';
}

# ABSTRACT: Run Qcons to analyze protein-protein contacts

use Mouse;
use autodie;
use namespace::autoclean;
use Capture::Tiny 'capture_merged';
use Bio::Tools::Run::QCons::Types 'Executable';

has 'program_name' => (
    is      => 'ro',
    isa     => 'Executable',
    default => 'Qcontacts',
);

has file => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has chains => (
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    required   => 1,
);

has probe_radius => (
    is      => 'ro',
    isa     => 'Num',
    default => 1.4,
);

has _result => ( is => 'ro', lazy_build => 1 );

has [qw(residue_contacts atom_contacts)] => (
    is => 'ro',
    lazy_build => 1,
);

sub _build_residue_contacts {
    return $_[0]->_result->{by_residue};
}

sub _build_atom_contacts {
    return $_[0]->_result->{by_atom};
}

has verbose => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has _temp_dir => (
    is => 'ro',
    isa => 'File::Temp::Dir',
    lazy_build => 1,
);

sub _build__temp_dir {
    require File::Temp;

    return File::Temp->newdir();
}

sub _build__result {

    # Run Qcontacts with the set parameters, and return
    # an array with the contact information.

    my $self = shift;
    my $arguments;
    my $executable = $self->program_name;

    $self->_arguments->{-prefOut} = $self->_temp_dir->dirname . '/';

    my $output = capture_merged {
        system( $executable, %{ $self->_arguments } )
    };

    warn $output if $self->verbose;

    my @contacts_by_atom    = $self->_parse_by_atom();
    my @contacts_by_residue = $self->_parse_by_residue();

    return { by_atom => \@contacts_by_atom, by_residue => \@contacts_by_residue };
}

has _arguments => (
    is         => 'ro',
    init_arg   => undef,
    lazy_build => 1,
);

# Private methods

sub _parse_by_residue {

    # Qcontacts outputs two files. This subroutine parses
    # the file that outputs residue-residue contacts.

    my $self = shift;
    my @contacts;

    # Get the path to the output file.
    my $filename = $self->_arguments->{-prefOut} . '/-by-res.vor';

    open( my $fh, '<', $filename );

    # Parse the file line by line, each line corresponds to a
    # contact.
    while ( my $line = <$fh> ) {
        my @fields = split( /\s+/, $line );

        my %contact = (
            res1 => {
                number => $fields[1],
                name   => $fields[2],
            },
            res2 => {
                number => $fields[5],
                name   => $fields[6],
            },
            area => $fields[8],
        );
        push @contacts, \%contact;
    }

    return @contacts;
}

sub _parse_by_atom {

    # Qcontacts outputs two files. This subroutine parses
    # the file that outputs atom-atom contacts.

    my $self = shift;
    my @contacts;

    # Get the path to the output file.
    my $filename = $self->_arguments->{-prefOut} . '/-by-atom.vor';


    open( my $fh, '<', $filename );
    # Parse the file line by line, each line corresponds to a
    # contact.

    my $meaning_for = {

        # What each parsed field means, depending on the contact
        # type (fields[1])

        # contact type  => {  field number => meaning      }
        V => { 13 => 'area' },
        H => { 13 => 'area', 14 => 'angle', 15 => 'Rno' },
        S => {
            13 => 'area',
            15 => 'dGhb',
            17 => 'dGip',
            18 => 'angle',
            19 => 'Rno'
        },
        I => { 13 => 'area', 14 => 'Rno' },
    };

    while ( my $line = <$fh> ) {
        my @fields = split( ' ', $line );
        my %contact = (
            atom1 => {
                number     => $fields[5],
                name       => $fields[6],
                res_name   => $fields[3],
                res_number => $fields[2],
            },
            atom2 => {
                number     => $fields[11],
                name       => $fields[12],
                res_name   => $fields[9],
                res_number => $fields[8],
            },
            type => $fields[1],
            area => $fields[8],
        );

        # I can't wait for Perl 6's junctions.
        foreach my $type ( keys %$meaning_for ) {
            if ( $type eq $fields[1] ) {
                foreach my $field ( keys %{ $meaning_for->{$type} } ) {

                    # I just realized that there's parameter in the 'S' type
                    # that has a ')' sticked to it, remove it.
                    $fields[$field] =~ s/\)//g;
                    $contact{ $meaning_for->{$type}{$field} }
                        = $fields[$field];
                }
            }
        }

        push @contacts, \%contact;
    }

    return @contacts;

}

sub _build__arguments {
    my $self = shift;
    return {
        -c1 => ${ $self->chains }[0],
        -c2 => ${ $self->chains }[1],
        -i  => $self->file,
        -probe => $self->probe_radius,
    };
}

1;


=pod

=head1 NAME

Bio::Tools::Run::QCons - Run Qcons to analyze protein-protein contacts

=head1 VERSION

version 0.112881

=head1 SYNOPSIS

   my $q = Bio::Tools::Run::QCons->new(
       file => $pdbfile,
       chains => [$chain1, $chain2],
   );

   my $contacts_by_atom = $q->atom_contacts;
   my $contacts_by_residue = $q->residue_contacts;

=head1 DESCRIPTION

This module implements a wrapper for the QCons application. QCons
itself is an implementation of the Polyhedra algorithm for the
prediction of protein-protein contacts. From the program's web page
(L<http://tsailab.tamu.edu/QCons/>):

"QContacts allows for a fast and accurate analysis of protein binding
interfaces. Given a PDB file [...] and the interacting chains of
interest, QContacts will provide a graphical representation of the
residues in contact. The contact map will not only indicate the
contacts present between the two proteins, but will also indicate
whether the contact is a packing interaction,  hydrogen bond, ion pair
or salt bridge (hydrogen-bonded ion pair). Contact maps allow for easy
visualization and comparison of protein-protein interactions."

For a thorough description of the algorithm, its limitations and a
comparison with several others, refer to Fischer, T. et. al: Assessing
methods for identifying pair-wise atomic contacts across binding
interfaces, J. Struc. Biol., vol 153, p. 103-112, 2006.

=head1 ATTRIBUTES

=head2 file

Gets or sets the file with the protein structures to analyze. The file
format should be PDB.

Required.

=head2 chains

    chains => ['A', 'B'];

Gets or sets the chain IDs of the subunits whose contacts the program
will calculate. It takes an array reference of two strings as
argument.

Required.

=head2 probe_radius($radius);

Gets or sets the probe radius that the program uses to calculate the
exposed and buried surfaces. It defaults to 1.4 Angstroms, and unless
you have a really strong reason to change this, you should refrain
from doing it.

=head2 verbose

Output debugging information to C<STDERR>. Off by default.

=head2 program_name

The name of the executable. Defaults to 'Qcontacts', but it can be set
to anything at construction time:

   my $q = Bio::Tools::Run::QCons->new(
       program_name => 'qcons',
       file => $pdbfile,
       chains => [$chain1, $chain2]
   );

Notice that if the binary is not on your PATH environment variable, you
should give C<program_name> a full path to it.

=head2 atom_contacts

Return an array reference with the information of every atom-atom
contact found.

The structure of the array reference is as follows:

   $by_atom = [
                {
                  'area' => '0.400',
                  'type' => 'V',
                  'atom2' => {
                               'number' => '461',
                               'res_name' => 'SER',
                               'res_number' => '59',
                               'name' => 'OG'
                             },
                  'atom1' => {
                               'number' => '2226',
                               'res_name' => 'ASN',
                               'res_number' => '318',
                               'name' => 'CB'
                             }
                },
              ]

This corresponds to the information of one contact. Here, 'atom1'
refers to the atom belonging to the first of the two polypeptides
given to the 'chains' method; 'atom2' refers to the second. The fields
'number' and 'name' refer to the atom's number and name, respectively.
The fields 'res_name' and 'res_number' indicate the atom's parent
residue name and residue id. 'type' indicates one of the five
non-covalent bonds that the program predicts:

=head2 residue_contacts

Returns an array reference with the information of every residue-residue
contact found.

The structure of the array is organized as follows:

   $by_res = [
               {
                 'area' => '20.033',
                 'res1' => {
                             'number' => '318',
                             'name' => 'ASN'
                           },
                 'res2' => {
                             'number' => '59',
                             'name' => 'SER'
                           }
               },
             ]

Here, bond type is obviously not given since the contact can possibly
involve more than one atom-atom contact type. 'res1' and 'res2'
correspond to the residues of the first and second chain ID given,
respectively. 'area' is the sum of every atom-atom contact that the
residue pair has. Their names (as three-letter residue names) and
number are given as hashrefs.

=begin :list

* B<V:> Van der Waals (packing interaction)

* B<I:> Ion pair

* B<S:> Salt bridge (hydrogen-bonded ion pair)

* B<H:> Hydrogen bond (hydrogen-bonded ion pair)

=end :list

Every bond type has the 'area' attribute, which indicates the surface
(in square Angstroms) of the interaction. In addition, all N-O
contacts (I, S and H) have a 'Rno' value that represents the N-O
distance. Directional contacts (S and H) also have an 'angle' feature
that indicates the contact angle. For salt bridges, estimations of the
free energy of hydrogen bond (dGhb) and free energy of ionic pair
(dGip) are also given.

=head1 THANKS

To Chad Davis for prodding me to dust off and release this module to the CPAN.

=head1 AUTHOR

Bruno Vecchi <vecchi.b gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Bruno Vecchi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

