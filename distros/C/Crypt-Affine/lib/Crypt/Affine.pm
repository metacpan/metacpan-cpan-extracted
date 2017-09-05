package Crypt::Affine;

$Crypt::Affine::VERSION   = '0.13';
$Crypt::Affine::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Crypt::Affine - Interface to the Affine cipher.

=head1 VERSION

Version 0.13

=cut

use 5.006;
use autodie;
use Data::Dumper;
use Crypt::Affine::Params qw(FilePath ZeroOrOne PositiveNum);

use Moo;
use namespace::clean;

=head1 DESCRIPTION

The affine cipher is a type of mono alphabetic substitution cipher,  wherein each
letter in an alphabet is mapped to its numeric equivalent &  then encrypted using
a  simple  mathematical  function. It inherits the weaknesses of all substitution
ciphers. In  the  affine  cipher  the  letters of an alphabet of size m are first
mapped  to  the  integers in the range 0..m-1. It then uses modular arithmetic to
transform  the  integer  that  each  plaintext letter corresponds to into another
integer  that  correspond to a ciphertext letter.The function for encryption of a
single letter can be defined as below:

E(x) = (mx + r) % l

where  'l'  is the size of the alphabet and 'm' & 'r' are the key  of cipher. The
value 'm' must be choosen such that 'm' and 'l' are coprime.

Similarly the function for decryption of a single letter can be defined as below:

D(x) = (m ^ -1) (x - r) % l

where  (m ^ -1)  is the modular multiplicative inverse of 'm' modulo 'l'  and  it
satisfies the equation below:

m (m ^ -1) % l = 1

=cut

has  'm'       => (is => 'ro', isa => PositiveNum, required => 1 );
has  'r'       => (is => 'ro', isa => PositiveNum, required => 1 );
has  'reverse' => (is => 'ro', isa => ZeroOrOne,   default  => sub { return 0; });
has  'source'  => (is => 'ro', isa => FilePath);

=head1 CONSTRUCTOR

The constructor expects the following parameters as described below in the table:

    +----------+----------+-------------------------------------------------+
    | Key      | Required | Description                                     |
    +----------+----------+-------------------------------------------------+
    |  m       |    Yes   | Any positive number.                            |
    |  r       |    Yes   | Any positive number.                            |
    |  reverse |    No    | 0 or 1, depending whether to use reverse set of |
    |          |          | alphabets. Default is 0.                        |
    |  source  |    No    | Filename with complete path containing comma    |
    |          |          | separated list of alphabets. By default it uses |
    |          |          | A-Z, a-z.                                       |
    +----------+----------+-------------------------------------------------+

    use strict; use warnings;
    use Crypt::Affine;

    my $affine = Crypt::Affine->new({ m => 5, r => 8 });

=head1 METHODS

=head2 encrypt()

Encrypts the given string of alphabets ignoring any non-alphabets.

    use strict; use warnings;
    use Crypt::Affine;

    my $affine    = Crypt::Affine->new({ m => 5, r => 8 });
    my $original  = 'affine cipher';
    my $encrypted = $affine->encrypt($original);

    print "Original : [$original]\n";
    print "Encrypted: [$encrypted]\n";

=cut

sub encrypt {
    my ($self, $data) = @_;

    return unless defined $data;

    $self->_prepare() unless defined $self->{_a};
    my $encrypt = '';
    foreach (split //,$data) {
        (_unsupported($_))
        ?
        ($encrypt .= $_)
        :
        ($encrypt .= $self->_encrypt($_));
    }

    return $encrypt;
}

=head2 decrypt()

Decrypts the given string of alphabets ignoring any non-alphabets.

    use strict; use warnings;
    use Crypt::Affine;

    my $affine    = Crypt::Affine->new({ m => 5, r => 8 });
    my $original  = 'affine cipher';
    my $encrypted = $affine->encrypt('affine cipher');
    my $decrypted = $affine->decrypt($encrypted);

    print "Original : [$original]\n";
    print "Encrypted: [$encrypted]\n";
    print "Decrypted: [$decrypted]\n";

=cut

sub decrypt {
    my ($self, $data) = @_;

    return unless defined $data;

    $self->_prepare() unless defined $self->{_a};
    my $decrypt = '';
    foreach (split //,$data) {
        (_unsupported($_))
        ?
        ($decrypt .= $_)
        :
        ($decrypt .= $self->_decrypt($_));
    }

    return $decrypt;
}

#
#
# PRIVATE METHODS

sub _prepare {
    my ($self) = @_;

    my @data = ();
    my ($i, $j) = (1, 1);
    my ($a_, $z_, $l_, %_a, %_z, $_data);

    if (defined($self->{'source'}) && (-e $self->{'source'})) {
        local undef $/;
        open(my $IN, $self->{'source'});
        $_data = <$IN>;
        close($IN);

        chomp $_data;
        @data = split /\,/,$_data;
    }

    @data = ('a'..'z', 'A'..'Z') unless scalar(@data);
    $l_ = scalar(@data);
    foreach (@data) {
        $a_->{$_} = $i++;
        $z_->{$_} = ($l_ + 1) - $j++;
    }
    $self->{'r'} = $l_ if ($self->{'r'} > abs($l_));

    %_a = reverse %{$a_};
    %_z = reverse %{$z_};

    $self->{'a_'} = $a_;
    $self->{'z_'} = $z_;
    $self->{'l_'} = $l_;
    $self->{'_a'} = \%_a;
    $self->{'_z'} = \%_z;
}

sub _encrypt {
    my ($self, $char) = @_;

    my $i = (($self->{'m'} * $self->{'a_'}->{$char}) + $self->{'r'}) % $self->{'l_'};
    $i = $self->{'l_'} if ($i == 0);

    (defined($self->{'reverse'}) && ($self->{'reverse'}))
    ?
    return $self->{'_z'}->{$i}
    :
    return $self->{'_a'}->{$i};
}

sub _decrypt {
    my ($self, $char) = @_;

    my $i = 0;
    my $j = 0;

    (defined($self->{'reverse'}) && ($self->{'reverse'}))
    ?
    ($i = $self->{'z_'}->{$char})
    :
    ($i = $self->{'a_'}->{$char});

    $j = (_multiplier($self->{'m'}, $self->{'l_'}) * ($i - $self->{'r'})) % $self->{'l_'};
    $j = $self->{'l_'} if ($j == 0);

    return $self->{'_a'}->{$j};
}

sub _unsupported {
    my ($byte) = @_;

    return 1 if ($byte =~ /[\#\+\%\&\=\,\;\:\!\?\.\"\'\-\<\>\(\)\[\]\@\\\_\s]/);
    return 0;
}

sub _multiplier {
    my ($a, $m) = @_;

    $m = abs($m);
    $a = $a % $m;
    my ($b, $x, $y, $n) = ($m, 1, 0);

    while ($a != 0) {
        $n = int($b / $a);
        ($a, $b, $x, $y) = ($b - $n * $a, $a, $y - $n * $x, $x);
    }

    return $y % $m;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Crypt-Affine>

=head1 BUGS

Please report any bugs/feature requests to C<bug-crypt-affine at rt.cpan.org>  or
through the web interface at  L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-Affine>.
I will be notified & then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::Affine

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-Affine>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-Affine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-Affine>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-Affine/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2017 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Crypt::Affine
