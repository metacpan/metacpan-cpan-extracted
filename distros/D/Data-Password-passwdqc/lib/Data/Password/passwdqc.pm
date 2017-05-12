package Data::Password::passwdqc;

use strict;
use warnings;

use POSIX qw(INT_MAX);
use List::MoreUtils qw(none);
use Carp qw(croak);
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

our $VERSION = '0.08';

require XSLoader;
XSLoader::load('Data::Password::passwdqc', $VERSION);


subtype 'Data::Password::passwdqc::ArrayRefOfInts',
    as 'ArrayRef[Int]',
    where {
        my @min = @{ $_ };
        @min == 5 && none(sub { $_ > INT_MAX }, @min) && none (sub { $_ && $min[$_] > $min[$_ - 1] },  0 .. $#min);
    };

coerce 'Data::Password::passwdqc::ArrayRefOfInts',
    from 'ArrayRef[Int|Undef]',
    via { [ map { defined() ? $_ : INT_MAX } @{ $_ } ] };

enum 'Data::Password::passwdqc::OneOrZero', [ 1, 0 ];

coerce 'Data::Password::passwdqc::OneOrZero',
    from 'Bool',
    via { $_ && 1 || 0 };

has 'min' => (
    is      => 'rw',
    isa     => 'Data::Password::passwdqc::ArrayRefOfInts',
    default => sub { [INT_MAX, 24, 11, 8, 7] },
    trigger => sub { $_[0]->_clear_params },
    coerce  => 1,
);

has 'max' => (
    is      => 'rw',
    isa     => subtype( 'Int' => where { $_ >= 8 && $_ <= INT_MAX } ),
    default => 40,
    trigger => sub { $_[0]->_clear_params },
);

has 'passphrase_words' => (
    is      => 'rw',
    isa     => subtype( 'Int' => where { $_ <= INT_MAX } ),
    default => 3,
    trigger => sub { $_[0]->_clear_params },
);

has 'match_length' => (
    is      => 'rw',
    isa     => subtype( 'Int' => where { $_ <= INT_MAX } ),
    default => 4,
    trigger => sub { $_[0]->_clear_params },
);

has 'similar_deny' => (
    is      => 'rw',
    isa     => 'Data::Password::passwdqc::OneOrZero',
    default => 1,
    trigger => sub { $_[0]->_clear_params },
    coerce  => 1,
);

has 'random_bits' => (
    is      => 'rw',
    isa     => subtype( 'Int' => where { $_ == 0 || $_ >= 24 && $_ <= 85 } ),
    default => 47,
    trigger => sub { $_[0]->_clear_params },
);

has '_params' => (
    is       => 'rw',
    clearer  => '_clear_params',
    lazy     => 1,
    builder  => '_build_params',
    init_arg => undef,
);

has 'reason' => (
    is       => 'rw',
    clearer  => '_clear_reason',
    init_arg => undef,
);


sub _build_params {
    my $self = shift;
    
    my $params = pack 'i*', @{ $self->min }, $self->max,
                            $self->passphrase_words, $self->match_length,
                            $self->similar_deny, $self->random_bits;
    return $params;
}


sub validate_password {
    my $self = shift;
    my ($new_pass, $old_pass) = @_;

    my $reason;
    if (@_ > 1) {
        $reason = password_check($self->_params, $new_pass, $old_pass); 
    } else {
        $reason = password_check($self->_params, $new_pass); 
    }

    if ($reason) {
        $self->reason($reason);
        return !1;
    }

    return !0;
}

sub generate_password {
    my $self = shift;

    my $pass = password_generate($self->_params);
    croak 'Failed to generate password' unless defined $pass;

    return $pass;
}

before [ qw(validate_password generate_password) ] => sub { $_[0]->_clear_reason };

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Password::passwdqc - Check password strength and generate password using passwdqc

=head1 SYNOPSIS

  use Data::Password::passwdqc;

  my $pwdqc = Data::Password::passwdqc->new;
  print 'OK' if $pwdqc->validate_password('arrive+greece7glove');

  my $is_valid = $pwdqc->validate_password('new password', '0ld+pas$w0rd');
  print 'Bad password: ' . $pwdqc->reason if not $is_valid;

  my $password = $pwdqc->generate_password;

=head1 DESCRIPTION

Data::Password::passwdqc provides an object oriented Perl interface to
Openwall Project's passwdqc. It allows you to check password strength
and also lets you generate quality controllable random password.

=head1 ATTRIBUTES

=over 4

=item I<min [Int0, Int1, Int2, Int3, Int4]>

Defaults to C<[undef, 24, 11, 8, 7]>.

The minimum allowed password lengths for different kinds of passwords
and passphrases. C<undef> can be used to disallow passwords of a given
kind regardless of their length. Each subsequent number is required to
be no larger than the preceding one.

Int0 is used for passwords consisting of characters from one character
class only. The character classes are: digits, lower-case letters,
upper-case letters, and other characters. There is also a special class
for non-ASCII characters, which could not be classified, but are assumed
to be non-digits.

Int1 is used for passwords consisting of characters from two character
classes that do not meet the requirements for a passphrase.

Int2 is used for passphrases. Note that besides meeting this length
requirement, a passphrase must also consist of a sufficient number of
words (see the C<passphrase_words> option below).

Int3 and Int4 are used for passwords consisting of characters from three
and four character classes, respectively.

When calculating the number of character classes, upper-case letters
used as the first character and digits used as the last character of a
password are not counted.

In addition to being sufficiently long, passwords are required to contain
enough different characters for the character classes and the minimum
length they have been checked against.

=item I<max Int>

Defaults to 40.

The maximum allowed password length. This can be used to prevent users
from setting passwords that may be too long for some system services.

The value 8 is treated specially: with C<max=8>, passwords longer than 8
characters will not be rejected, but will be truncated to 8 characters for
the strength checks and the user will be warned. This is to be used with
the traditional DES-based password hashes, which truncate the password
at 8 characters.

It is important that you do set C<max=8> if you are using the traditional
hashes, or some weak passwords will pass the checks.

=item I<passphrase_words Int>

Defaults to 3.

The number of words required for a passphrase, or 0 to disable the
support for user-chosen passphrases.

=item I<match_length Int>

Defaults to 4.

The length of common substring required to conclude that a password is at
least partially based on information found in a character string, or 0 to
disable the substring search.  Note that the password will not be rejected
once a weak substring is found; it will instead be subjected to the
usual strength requirements with the weak substring partially discounted.

The substring search is case-insensitive and is able to detect and remove
a common substring spelled backwards.

=item I<random_bits Int>

Defaults to 47.

The size of randomly-generated passphrases in bits (24 to 85), or 0 to
disable this feature.

=back

=head1 METHODS

=over 4

=item B<validate_password>

  $is_valid = $pwdqc->validate_password('new password');
  $is_valid = $pwdqc->validate_password('new password', 'old password');
  print $pwdqc->reason if not $is_valid;

Checks passphrase quality. Returns a true value on success. If the check
fails, it returns a false value and sets C<reason>.

=item B<generate_password>

  my $password = $pwdqc->generate_password;

Generates a random passphrase. Throws an exception if passphrase cannot
be generated.

=back

=head1 AUTHORS

Sherwin Daganato E<lt>sherwin@daganato.comE<gt>

The copy of passwdqc bundled with this module was written by Solar Designer and Dmitry V. Levin.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.openwall.com/passwdqc/>

=cut
