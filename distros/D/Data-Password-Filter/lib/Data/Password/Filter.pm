package Data::Password::Filter;

$Data::Password::Filter::VERSION   = '0.16';
$Data::Password::Filter::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Data::Password::Filter - Interface to the password filter.

=head1 VERSION

Version 0.16

=cut

use 5.006;
use autodie;
use Data::Dumper;
use File::Share ':all';
use Data::Password::Filter::Params qw(ZeroOrOne FilePath PositiveNum);

use Moo;
use namespace::clean;

=head1 DESCRIPTION

The module is a simple attempt to convert an article written by Christopher Frenz
on the topic "The Development of a Perl-based Password Complexity Filter".However
I  took  the liberty to add my flavour on top of it.

L<http://perl.sys-con.com/node/1911661>

=cut

has 'word_list'             => (is => 'ro');
has 'word_hash'             => (is => 'ro');
has 'length'                => (is => 'ro', isa => PositiveNum, default => sub { return 8; });
has 'min_lowercase_letter'  => (is => 'ro', isa => PositiveNum, default => sub { return 1; });
has 'min_uppercase_letter'  => (is => 'ro', isa => PositiveNum, default => sub { return 1; });
has 'min_special_character' => (is => 'ro', isa => PositiveNum, default => sub { return 1; });
has 'min_digit'             => (is => 'ro', isa => PositiveNum, default => sub { return 1; });
has 'check_variation'       => (is => 'ro', isa => ZeroOrOne,   default => sub { return 1; });
has 'check_dictionary'      => (is => 'ro', isa => ZeroOrOne,   default => sub { return 1; });
has 'user_dictionary'       => (is => 'ro', isa => FilePath );

our $STATUS = {
    'check_dictionary'        => 'Check Dictionary       :',
    'check_length'            => 'Check Length           :',
    'check_digit'             => 'Check Digit            :',
    'check_lowercase_letter'  => 'Check Lowercase Letter :',
    'check_uppercase_letter'  => 'Check Uppercase Letter :',
    'check_special_character' => 'Check Special Character:',
    'check_variation'         => 'Check Variation        :',
};

sub BUILD {
    my ($self) = @_;

    my $dictionary;
    if ($self->user_dictionary) {
        @{$self->{word_list}} = ();
        %{$self->{word_hash}} = ();
        $dictionary = $self->user_dictionary;
    }
    else {
        $dictionary = dist_file('Data-Password-Filter', 'dictionary.txt');
    }

    open(my $DICTIONARY, '<:encoding(UTF-8)', $dictionary);
    while(my $word = <$DICTIONARY>) {
        chomp($word);
        next if length($word) <= 3;
        push @{$self->{word_list}}, $word;
    }
    close($DICTIONARY);

    die("ERROR: Couldn't find word longer than 3 characters in the dictionary.\n")
        unless scalar(@{$self->{word_list}});

    map { $self->{word_hash}->{lc($_)} = 1 } @{$self->{word_list}};
}

=head1 CONSTRUCTOR

Below  is  the list parameters that can be passed to the constructor. None of the
parameters  are  mandatory. The format of user dictionary should be one word perl
line.  It  only  uses the word longer than 3 characters from the user dictionary,
if supplied.

    +-----------------------+---------------------------------------------------+
    | Key                   | Description                                       |
    +-----------------------+---------------------------------------------------+
    | length                | Length of the password. Default is 8.             |
    |                       |                                                   |
    | min_lowercase_letter  | Minimum number of alphabets (a..z) in lowercase.  |
    |                       | Default is 1.                                     |
    |                       |                                                   |
    | min_uppercase_letter  | Minimum number of alphabets (A..Z) in uppercase.  |
    |                       | Default is 1.                                     |
    |                       |                                                   |
    | min_special_character | Minimum number of special characters.Default is 1.|
    |                       |                                                   |
    | min_digit             | Minimum number of digits (0..9). Default is 1.    |
    |                       |                                                   |
    | check_variation       | 1 or 0, depending whether checking variation.     |
    |                       | Default is 1.                                     |
    |                       |                                                   |
    | check_dictionary      | 1 or 0, depending whether checking dictionary.    |
    |                       | Default is 1.                                     |
    |                       |                                                   |
    | user_dictionary       | User supplied dictionary file location. Default   |
    |                       | use its own.                                      |
    +-----------------------+---------------------------------------------------+

The C<check_variation> key,  when set 1, looks for password that only vary by one
character from a dictionary word.

=head1 SPECIAL CHARACTERS

Currently considers the following characters as special:

    !   "   #   $   %   &   '   (   \   |   )
    )   *   +   ,   -   .   /   :   ;   <   =
    >   ?   @   [   \   ]   ^   _   `   {   |
    }   ~

=head1 METHODS

=head2 strength($password)

Returns the strength of the given password and tt is case insensitive.

    +----------------+------------+
    | Score (s)      | Strength   |
    +----------------+------------+
    | s <= 50%       | Very weak. |
    | 50% < s <= 70% | Weak.      |
    | 70% < s <= 90% | Good.      |
    | s > 90%        | Very good. |
    +----------------+------------+

    use strict; use warnings;
    use Data::Password::Filter;

    my $password = Data::Password::Filter->new();
    print "Strength: " . $password->strength('Ab12345?') . "\n";

=cut

sub strength {
    my ($self, $password) = @_;

    die("ERROR: Missing password.\n") unless (defined $password);

    return $self->_strength($password);
}

=head2 score($password)

Returns the score (percentage) of the given password or the previous password for
which the strength has been calculated.

    use strict; use warnings;
    use Data::Password::Filter;

    my $password = Data::Password::Filter->new();
    print "Score   : " . $password->score('Ab12345?')    . "\n";

    $password = Data::Password::Filter->new();
    print "Strength: " . $password->strength('Ab54321?') . "\n";
    print "Score   : " . $password->score()              . "\n";

=cut

sub score {
    my ($self, $password) = @_;

    die("ERROR: Missing password.\n") unless (defined($password) || defined($self->{score}));

    $self->_strength($password) if defined $password;

    return $self->{score};
}

=head2 as_string()

Returns the filter detail.

    use strict; use warnings;
    use Data::Password::Filter;

    my $password = Data::Password::Filter->new();
    print "Strength: " . $password->strength('Ab12345?') . "\n";
    print "Score   : " . $password->score('Ab12345?')    . "\n";
    print $password->as_string() . "\n";

=cut

sub as_string {
    my ($self) = @_;

    return unless defined $self->{result};

    my $string = '';
    foreach (keys %{$STATUS}) {
        if (defined($self->{result}->{$_}) && ($self->{result}->{$_})) {
            $string .= sprintf("%s %s\n", $STATUS->{$_}, '[PASS]');
        }
        else {
            $string .= sprintf("%s %s\n", $STATUS->{$_}, '[FAIL]');
        }
    }

    return $string;
}

#
#
# PRIVATE METHODS

sub _strength {
    my ($self, $password) = @_;

    $self->_checkDictionary($password) if $self->{check_dictionary};
    $self->_checkVariation($password)  if $self->{check_variation};
    $self->_checkLength($password);
    $self->_checkDigit($password);
    $self->_checkUppercaseLetter($password);
    $self->_checkLowercaseLetter($password);
    $self->_checkSpecialCharacter($password);

    my ($count, $score);
    $count = 0;
    foreach (keys %{$STATUS}) {
        $count++ if (defined($self->{result}->{$_}) && ($self->{result}->{$_}));
    }

    $score = (100/(keys %{$STATUS})) * $count;
    $self->{score} = sprintf("%d%s", int($score), '%');

    if ($score <= 50) {
        return 'Very weak';
    }
    elsif (($score > 50) && ($score <= 70)) {
        return 'Weak';
    }
    elsif (($score > 70) && ($score <= 90)) {
        return 'Good';
    }
    elsif ($score > 90) {
        return 'Very good';
    }
}

sub _exists {
    my ($self, $word) = @_;

    return exists($self->{'word_hash'}->{lc($word)});
}

sub _checkDictionary {
    my ($self, $password) = @_;

    $self->{result}->{'check_dictionary'} = !$self->_exists($password);
}

sub _checkLength {
    my ($self, $password) = @_;

    $self->{result}->{'check_length'} = !(length($password) < $self->{length});
}

sub _checkDigit {
    my ($self, $password) = @_;

    my $count = 0;
    $count++ while ($password =~ /\d/g);

    $self->{result}->{'check_digit'} = !($count < $self->{min_digit});
}

sub _checkLowercaseLetter {
    my ($self, $password) = @_;

    my $count = 0;
    $count++ while ($password =~ /[a-z]/g);

    $self->{result}->{'check_lowercase_letter'} = !($count < $self->{min_lowercase_letter});
}

sub _checkUppercaseLetter {
    my ($self, $password) = @_;

    my $count = 0;
    $count++ while ($password =~ /[A-Z]/g);

    $self->{result}->{'check_uppercase_letter'} = !($count < $self->{min_uppercase_letter});
}

sub _checkSpecialCharacter {
    my ($self, $password) = @_;

    my $count = 0;
    $count++ while ($password =~ /!|"|#|\$|%|&|'|\(|\)|\*|\+|,|-|\.|\/|:|;|<|=|>|\?|@|\[|\\|]|\^|_|`|\{|\||}|~/g);

    $self->{result}->{'check_special_character'} = !($count < $self->{min_special_character});
}

sub _checkVariation {
    my ($self, $password) = @_;

    unless (defined($self->{result}->{'check_dictionary'}) && ($self->{result}->{'check_dictionary'})) {
        $self->{result}->{'check_variation'} = 0;
        return;
    }

    my ($regexp, @_password);
    for (my $i = 0; $i <= (length($password)-1); $i++) {
        pos($password) = 0;
        while ($password =~ /(\w)/gc) {
            my $char = $1;
            my $spos = pos($password)-1;
            $char = '.' if ($spos == $i);
            (defined($_password[$i]))
            ?
            ($_password[$i] .= $char)
            :
            ($_password[$i] = $char);
        }
        $regexp .= $_password[$i] . '|';
    }
    $regexp =~ s/\|$//g;

    foreach (@{$self->{'word_list'}}) {
        if (/$regexp/i) {
            $self->{result}->{'check_variation'} = 0;
            return;
        }
    }

    $self->{result}->{'check_variation'} = 1;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Data-Password-Filter>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-password-filter at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Password-Filter>.
I will be notified and then you'll automatically be notified  of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Password::Filter

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Password-Filter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Password-Filter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Password-Filter>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Password-Filter/>

=back

=head1 ACKNOWLEDGEMENT

Christopher Frenz,  author  of "Visual Basic and Visual Basic .NET for Scientists
and Engineers" (Apress) and "Pro Perl Parsing" (Apress).

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
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

1; # End of Data::Password::Filter
