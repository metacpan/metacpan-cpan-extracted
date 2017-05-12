package Business::FR::RIB;
use Math::BigInt;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.05';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

########################################################################

=head1 NAME

Business::FR::RIB - Verify French RIB (Releve d'Identite Bancaire)

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

  use Business::FR::RIB;
  my $object = Business::FR::RIB->new('1234567890DWFACEOFBOE08');
  print "RIB valid" if $object->is_valid();

=head1 DESCRIPTION

This module determines whether a French RIB (Releve d'Identite Bancaire)
is well-formed.

Please note that there is no way to determine whether a RIB is linked to
a true bank account without using it or asking the bank.

=head1 METHODS

=cut

########################################################################

sub _check_rib {
    my ($class, $rib) = @_;

    $rib =~ s/\s+//g;

    return '' if($rib !~ m/^\d{10}[\da-zA-Z]{11}(\d{2})$/);

    # check the RIB key
    return '' if($1 > 97 || $1 < 1);

    return $rib;
}# sub _check_rib

########################################################################

=head2 new

 Usage     : my $object = Business::FR::RIB->new();
 Purpose   : Constructor
 Returns   : A Business::FR::RIB object
 Argument  : The new constructor optionally takes a RIB string

=cut

########################################################################

sub new {
    my ($class, $rib) = @_;

    my $self = bless \$rib, $class;

    $rib ||= '';
    $rib = $self->_check_rib($rib);

    return $self;
}# sub new

########################################################################

=head2 is_valid

 Usage     : $object->is_valid();
 Purpose   : Check if the RIB is well-formed
 Returns   : 1 or 0
 Argument  : Optionally take the RIB string as argument
 Comment   : Please note that there is no way to determine
           : whether a RIB is linked to a true bank account
           : without using it or asking the bank.

=cut

########################################################################

sub is_valid {
    my $self = shift;
    my $rib  = shift;

    $$self = $self->_check_rib($rib) if($rib);

    my $cbanque  = $self->get_code_banque();
    my $cguichet = $self->get_code_guichet();
    my $nocompte = $self->get_no_compte();
    my $clerib   = $self->get_cle_rib();

    my %letter_substitution = ("A" => 1, "B" => 2, "C" => 3, "D" => 4, "E" => 5, "F" => 6, "G" => 7, "H" => 8, "I" => 9,
                               "J" => 1, "K" => 2, "L" => 3, "M" => 4, "N" => 5, "O" => 6, "P" => 7, "Q" => 8, "R" => 9,
                                         "S" => 2, "T" => 3, "U" => 4, "V" => 5, "W" => 6, "X" => 7, "Y" => 8, "Z" => 9);
    my $tabcompte = "";

    my $len = length($nocompte);
    return 0 if ($len != 11);

    for (my $i = 0; $i < $len; $i++) {
        my $car = substr($nocompte, $i, 1);
        if ($car !~ m/^\d$/) {
            my $b = $letter_substitution{uc($car)};
            my $c = ( $b + 2**(($b - 10)/9) ) % 10;
            $tabcompte .= $c;
        } else {
            $tabcompte .= $car;
        }
    }
    my $int = "$cbanque$cguichet$tabcompte$clerib";
    return (length($int) >= 21 && Math::BigInt->new($int)->bmod(97) == 0) ? 1 : 0;
}# sub valid_rib

########################################################################

=head2 rib

 Usage     : $object->rib();
 Purpose   : Get and optionnally or set the object's RIB
 Returns   : The RIB
 Argument  : The rib method optionally takes a RIB string

=cut

########################################################################

sub rib {
    my $self = shift;
    my $rib  = shift;

    $$self = $self->_check_rib($rib) if ($rib);

    return $$self;
}# sub rib

########################################################################

=head2 get_code_banque

 Usage     : $object->get_code_banque();
 Returns   : The bank code

=cut

########################################################################

sub get_code_banque {
    my $self = shift;

    return substr($$self, 0, 5);
}# sub get_code_banque

########################################################################

=head2 get_code_guichet

 Usage     : $object->get_code_guichet();
 Returns   : The counter code

=cut

########################################################################

sub get_code_guichet {
    my $self = shift;

    return substr($$self, 5, 5);
}# sub get_code_guichet

########################################################################

=head2 get_no_compte

 Usage     : $object->get_no_compte();
 Returns   : The RIB account number

=cut

########################################################################

sub get_no_compte {
    my $self = shift;

    return substr($$self, 10, 11);
}# sub get_no_compte

########################################################################

=head2 get_cle_rib

 Usage     : $object->get_cle_rib();
 Returns   : The RIB key

=cut

########################################################################

sub get_cle_rib {
    my $self = shift;

    return substr($$self, 21,2);
}# sub get_cle_rib

########################################################################

=head1 BUGS and SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::FR::RIB

Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-FR-RIB
    bug-business-fr-rib at rt.cpan.org

The latest source code can be browsed and fetched at:

    https://dev.fiat-tux.fr/projects/business-fr-rib
    git clone git://fiat-tux.fr/Business-FR-RIB.git

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-FR-RIB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-FR-RIB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-FR-RIB>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-FR-RIB/>

=back

=head1 AUTHOR

    Luc DIDRY
    CPAN ID: LDIDRY
    ldidry@cpan.org
    http://www.fiat-tux.fr/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;
