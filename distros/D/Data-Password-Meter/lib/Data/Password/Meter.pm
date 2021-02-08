package Data::Password::Meter;
use strict;
use warnings;

# Todo:
# - see: https://en.wikipedia.org/wiki/Password_strength#NIST_Special_Publication_800-63
# - see: http://www.spiegel.de/netzwelt/web/dashlane-untersuchung-viele-webanbieter-akzeptieren-zu-schwache-passwoerter-a-1161922.html

our $VERSION = '0.10';


# Error messages
my $S = 'The password ';
my @PART = (
  'is too short',
  'should contain special characters',
  'should contain combinations of letters, numbers and special characters'
);
our @ERR = (
  undef,
  'There is no password given',
  'Passwords are not allowed to contain control sequences',
  'Passwords are not allowed to consist of repeating characters only',
  $S . $PART[0],
  $S . $PART[1],
  $S . $PART[2],
  $S . $PART[0] . ' and ' . $PART[1],
  $S . $PART[0] . ' and ' . $PART[2],
  $S . $PART[1] . ' and ' . $PART[2],
  $S . $PART[0] . ', ' . $PART[1] . ' and ' . $PART[2]
);


# Constructor
sub new {
  my $class = shift;

  # Accept threshold parameter
  my $threshold = $_[0] && $_[0] =~ /^\d+$/ ? $_[0] : 25;
  bless [ $threshold, 0 ], $class;
};


# Error code
sub err {
  my $self = shift;
  return 0 unless $self->[2];

  return $self->[2] if @$self == 3;

  # Combinations of errors
  if (@$self == 4) {
    return 7 if $self->[2] == 4 && $self->[3] == 5;
    return 8 if $self->[2] == 4 && $self->[3] == 6;
    return 9 if $self->[2] == 5 && $self->[3] == 6;
  };

  return 10;
};


# Error string
sub errstr {
  return $_[1] ? ($ERR[$_[1]] // '') : ($ERR[$_[0]->err] // '');
};


# Score
sub score {
  $_[0]->[1];
};


# Threshold
sub threshold {
  my $self = shift;
  return $self->[0] unless $_[0];
  $self->[0] = shift if $_[0] =~ /^\d+$/;
};


# Check the strength of the password
sub strong {
  my ($self, $pwd) = @_;

  # Initialize object
  @$self = ($self->threshold // 25, 0);

  # No password is too weak
  unless ($pwd) {
    $self->[2] = 1;
    return;
  };

  # Control characters
  if ($pwd =~ m/[\a\f\v\n\r\t]/) {
    $self->[2] = 2;
    return;
  };

  # Only one repeating character
  if ($pwd =~ /^(.)\1*$/) {
    $self->[2] = 3;
    return;
  };

  my $score = 0;

  # Based on passwordmeter by Steve Moitozo -- geekwisdom.com

  # Length
  my $pwd_l = length $pwd;
  if ($pwd_l < 5) {
    # Less than 5 characters
    $score += 3;
  }
  elsif ($pwd_l > 4 && $pwd_l < 8) {
    # More than 4 characters
    $score += 6;
  }
  elsif ($pwd_l > 7 && $pwd_l < 16) {
    # More than 7 characters
    $score += 12;
  }
  elsif ($pwd_l > 15) {
    # More than 15 characters
    $score += 18;
  };

  if ($pwd_l > 8) {
    # + 2 for every character above 8
    $score += (($pwd_l - 8) * 2);
  }

  # Password is too short
  else {
    push @$self, 4;
  };

  # Letters
  if ($pwd =~ /[a-z]/) {
    # At least one lower case character
    $score++;
  };

  if ($pwd =~ /[A-Z]/) {
    # At least one upper case character
    $score += 5;
  };

  # Numbers
  if ($pwd =~ /\d/) {
    # At least one number
    $score += 5;

    if ($pwd =~ /(?:.*\d){3}/) {
      # At least three numbers
      $score += 5;
    };
  };

  # Special characters
  if ($pwd =~ /[^a-zA-Z0-9]/) {
    # At least one special character
    $score += 5;

    if ($pwd =~ /(?:.*[^a-zA-Z0-9]){2}/) {
      # At least two special characters
      $score += 5;
    };
  }
  else {
    push @$self, 5;
  };

  # Scoring is not enough to succeed
  unless ($score > ($self->threshold - 6)) {
    $self->[1] = $score;
    return;
  };

  # Combos
  if ($pwd =~ /(?:[a-z].*[A-Z])|(?:[A-Z].*[a-z])/) {
    # At least one combination of upper and lower case characters
    $score += 2;
  };

  if ($pwd =~ /(?:[a-zA-Z].*\d)|(?:\d.*[a-zA-Z])/) {
    # At least one combination of letters and numbers
    $score += 2
  };

  if ($pwd =~ /(?:[a-zA-Z0-9].*[^a-zA-Z0-9])|(?:[^a-zA-Z0-9].*[a-zA-Z0-9])/) {
    # At least one combination of letters, numbers and special characters
    $score += 2;
  };

  push @$self, 6;

  $self->[1] = $score;
  return if $score < $self->threshold;

  @$self = ($self->threshold, $score);
  return 1;
};


1;


__END__


=pod

=head1 NAME

Data::Password::Meter - Check the strength of passwords


=head1 SYNOPSIS

  my $pwdm = Data::Password::Meter->new(28);

  # Check a password
  if ($pwdm->strong('s3cur3-p4ssw0rd')) {
    print "The password is strong enough!\n";
    print 'Scored ' . $pwdm->score . ' points!';
  }
  else {
    warn $pwdm->errstr;
  };


=head1 DESCRIPTION

Check the strength of a password. The scoring is based on
L<Passwordmeter|http://www.geekwisdom.com/js/passwordmeter.js>
by Steve Moitozo.


=head1 ATTRIBUTES

=head2 err

  print $pwdm->err;

The L<error code|/ERROR MESSAGES> of the last check.
Returns a C<false> value, if the last check was successful.


=head2 errstr

  print $pwdm->errstr;
  print $pwdm->errstr(4);

The L<error string|/ERROR MESSAGES> of the last check,
or, in case an error code is passed, the corresponding message.
Returns an empty string, if the last check was successful.


=head2 score

  print $pwdm->score;

The score of the last check.


=head2 threshold

  print $pwdm->threshold;
  $pwdm->threshold(28);

The scoring threshold,
the determining factor when a password is too weak.
Every password that is below this threshold
is considered weak.
Defaults to a score of C<25>.


=head1 METHODS

=head2 new

  my $pwd = Data::Password::Meter->new(28);

Constructs a new password check object.
Accepts an optional value for the L<threshold|/threshold>.


=head2 strong

  if ($pwdm->strong('mypassword')) {
    print 'This password is strong!';
  }
  else {
    print 'This password is weak!';
  };

Checks a password for strength.
Returns a false value in case the password
is considered to be weak.


=head1 ERROR MESSAGES

Possible error codes and strings are:

=over 2

=item *

1. There is no password given

=item *

2. Passwords are not allowed to contain control sequences

=item *

3. Passwords are not allowed to consist of repeating characters only

=item *

4. The password is too short

=item *

5. The password should contain special characters

=item *

6. The password should contain combinations of letters,
numbers and special characters

=item *

7. The password is too short and should contain special characters

=item *

8. The password is too short and should contain combinations of letters,
numbers and special characters

=item *

9. The password should contain special characters and should contain
combinations of letters, numbers and special characters

=item *

10. The password is too short, should contain special characters and
should contain combinations of letters, numbers and special characters

=back


=head1 DEPENDENCIES

No dependencies other than core.


=head1 AVAILABILITY

  https://github.com/Akron/Data-Password-Meter


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, Steve Moitozo,
(C) 2013-2021, L<Nils Diewald|https://www.nils-diewald.de/>.

Licensed under the MIT License

=cut
