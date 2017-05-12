=head1 NAME

Acme::Mobile::Therbligs - count keystrokes to write mobile text messages

=head1 SYNOPSIS

  use Acme::Mobile::Therbligs;

  $thurbs = count_therbligs("See u l8r");

  # $thurbs == 23
  
=head1 DESCRIPTION

This module counts the number of I<therbligs> used to write mobile
text messages.  A therblig is unit used to measure the number of
actions (in this case keypresses or pauses) for people who like to
optimize industrial processes.

So you can use this module to determine useless facts such as that it
takes as many keypresses to write "later" or "great" as it does "l8r"
and "gr8".

The current version is case insensitive and assumes (by default) a
particular brand of Nokia phone. (I have no idea which model it is; it
was cheap, and it works, which is all I care about.)

A description of methods is below.

=over

=cut

package Acme::Mobile::Therbligs;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.05';

use Exporter;

our @ISA = qw( Exporter );

our @EXPORT = qw( count_therbligs );

our %EXPORT_TAGS = (
  'all' => [ @EXPORT ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

use constant DEFAULT_SAME_KEY => 1;

use Carp;
use YAML qw( Load Dump );

=item new

  $obj = Acme::Mobile::Therbligs->new();

This is used for the object-oriented interface. It is only useful if
you want to specify your own keypad or modify the rules:

  open $fh, 'mykeypad.yml';
  $obj = Acme::Mobile::Therbligs->new($fh, \%rules );

The rule file is in L<YAML> format that specifies the characters for
each key pressed (in the order that they occur for each key press).

The optional rules allow one to change the behavior of the counting
function:

  $obj = Acme::Mobile::Therbligs->new($fh,
  {
    SAME_KEY         => 1,
    NO_SENTENCE_CAPS => 0,
  });

=over

=item SAME_KEY

The number of therbligs to count as waiting when having to enter
letters which require pressing the same key (as with the word "high").
Defaults to C<1>.

=item NO_SENTENCE_CAPS

By default the initial letter of the message and of each sentence is
assumed to be capitalized (when counting in case-sensitive mode). This
option disabled that.

=back

=cut

sub new {
  my $class = shift;
  my $self  = { };
  bless $self, $class;
  $self->_initialize(@_);
  return $self;
}

my $Default;

sub _initialize {
  my $self = shift;
  my $fh   = shift;
  my $rule = shift || { };

  $self->{SAME_KEY}         = $rule->{SAME_KEY}         || DEFAULT_SAME_KEY;
  $self->{NO_SENTENCE_CAPS} = $rule->{NO_SENTENCE_CAPS} || 0;
  $self->{NO_SHIFT_CAPS}    = $rule->{NO_SHIFT_CAPS}    || 0;

  unless (defined $Default) {
    $Default = join("", <DATA>, "\n");
  }

  my $file = (defined $fh) ? join("", <$fh>, "\n") : $Default;
  my $keys = Load($file);

  $self->{KEYPAD} = $keys;

  foreach my $key (0..9) {
    croak "Missing $key key",
      unless (exists $keys->{$key});
  }

  $self->{CHAR}   = { };

  foreach my $key (keys %$keys) {
    my $thurb = 1;
    foreach my $char (split //, $keys->{$key}) {
      $self->{CHAR}->{$char} = [$key, $thurb++];
    }
  }

  return $self;
}

my $Self;

{
  $Self = __PACKAGE__->new(undef, {
    SAME_KEY         => DEFAULT_SAME_KEY,
    NO_SENTENCE_CAPS => 0,
    NO_SHIFT_CAPS    => 0,
  });
}

=item count_therbligs

  $count = count_therbligs($message, $case_flag);

  $count = $obj->count_therbligs($message, $case_flag);

Returns the number of "therbligs" (keystrokes) used to generate the
message.  A therblig is either a keystroke, or the pause when one has
to wait in order to enter multiple letters from the same key (such as
with the word "high").

The default number of therbligs for waiting in the same key is
C<1>. There is no way to change that value for this version.

When C<$case_flag> is true, the number of therbligs includes
keystrokes to toggle the shift key.  It assumes that the first letter
of the message or a sentence is capitalized.  (If C<$case_flag> is
unspecified, it is assumed to be false.)

=cut

sub count_therbligs {
  my $self  = shift;
  my $text  = shift;
  my $case  = shift;
  my $debug = shift;                    # for diagnostics

  unless (ref($self)) {
    ($debug, $case, $text, $self) = ($case, $text, $self, $Self);
  }

  my $last  = "";                       # last character
  my $shift = 0;                        # shift flag
  my $start = $case;                    # sentence start flag
  my $thurb = 0;                        # therblig count

  foreach my $char (split //, $text) {

    if ($debug) {
      print STDERR
	"# last=$last char=$char start=$start shift=$shift thurb=$thurb\n";
    }

    unless ($self->{NO_SHIFT_CAPS}) {

      # Note: it assumes characters are lower-case rather than
      # upper-case without shifting.

      if ($char ne lc($char)) {
	if ($case) {
	  unless ($shift||$start) {
	    $shift = 1;
	    $thurb ++;
	  }
	}
	$char = lc($char);
      } elsif ($case) {
	if ((!$self->{NO_SENTENCE_CAPS}) && $start && ($char =~ /[\w]/)) { 
	  $thurb += 2;		        # 2 shifts for initial lowercase
	}
	if ($shift && ($char =~ /[\w]/)) {
	  $shift = 0;
	  $thurb ++;
	}
      }

      unless ($self->{NO_SENTENCE_CAPS}) {
	$start = 0, if ($char =~ /[\w]/);
	$start = 1, if ($char =~ /[\.\!\?]/);
      }
    }

    croak "Unknown character: $char",
      unless (exists $self->{CHAR}->{$char});
    $thurb += $self->{CHAR}->{$char}->[1];
    $thurb += $self->{SAME_KEY},
      if ($self->{CHAR}->{$char}->[0] eq ($self->{CHAR}->{$last}->[0]||""));

    $last = $char;
  }

  if ($debug) {
    print STDERR
      "# last=$last char= start=$start shift=$shift thurb=$thurb\n";
  }

  return $thurb;
}


=back

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

current Maintainer: Rene Schickbauer <rene.schickbauer at gmail.com>

=head1 REPORTING BUGS

We don't know of any bugs, but that doesn't mean there aren't any. Please
the CPAN bugtracker or mail Rene Schickbauer directly.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Robert Rothenberg.  All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

Now maintained by Rene Schickbauer, so i guess everything after version 0.01
is (C) 2010 Rene Schickbauer

=head1 SEE ALSO

This module is similar to L<Device::KeyStroke::Mobile>.

=cut

1;

__DATA__
--- #YAML:1.0
# The default data is for some unknown model of Nokia phone.
0: ' 0'
1: ".,'?!\"1-()@/:"
2: 'abc2ä'
3: 'def3èéêëð'
4: 'ghi4ìíîï'
5: 'jkl5£'
6: 'mno6öøòóôõñ'
7: 'pqrs7ß$'
8: 'tuv8ùúûü'
9: 'wxyz9ýþ'

