
package DBIx::Informix::Perform::Widgets::ButtonSet;

use strict;

use base qw(Curses::Widgets::ButtonSet);

use Curses;			# for KEY_foo constants.
use Curses::Widgets;

sub _conf {
    my $self = shift;
    my %stuff = @_;
    $stuff{TABORDER} = "\n"
	unless exists $stuff{TABORDER};
    $stuff{ACTIVATEKEY} = "\n";
    $self->SUPER::_conf(%stuff);
}

sub input_key {
  # Process input a keystroke at a time.
  #
  # Usage:  $self->input_key($key);

  my $self = shift;
  my $in = shift;
  my $conf = $self->{CONF};
  my ($value, $hz) = @$conf{qw(VALUE HORIZONTAL)};
  my @labels = @{ $$conf{LABELS} };
  my $num = scalar @labels;
  my %initials = map { (lc(substr($labels[$_], 0, 1)), $_) } 0..$#labels;

  my $ival = $initials{lc($in)};
  if (defined($ival)) {
      $value = $ival;
      $$conf{EXIT} = 1;
  }
  elsif ($hz) {
    if ($in eq KEY_RIGHT or $in eq ' ') {
      ++$value;
      $value = 0 if $value == $num;
    } elsif ($in eq KEY_LEFT) {
      --$value;
      $value = ($num - 1) if $value == -1;
    } else {
      beep;
    }
  } else {
    if ($in eq KEY_UP) {
      --$value;
      $value = ($num - 1) if $value == -1;
    } elsif ($in eq KEY_DOWN  or  $in eq ' ') {
      ++$value;
      $value = 0 if $value == $num;
    } else {
      beep;
    }
  }

  $$conf{VALUE} = $value;
}

sub execute {
  my $self = shift;
  my $mwh = shift;
  my $conf = $self->{CONF};
  my $func = $$conf{'INPUTFUNC'} || \&scankey;
  my $regex = $$conf{'FOCUSSWITCH'};
  my $key;

  $self->draw($mwh, 1);

  while (1) {
    $key = &$func($mwh);
    if (defined $key) {
      if (defined $regex) {
        return $key if ($key =~ /^[$regex]/ || ($regex =~ /\t/ &&
          $key eq KEY_STAB));
      }
      $self->input_key($key);
    }
    $self->draw($mwh, 1);
    if ($conf->{EXIT}) {
	$conf->{EXIT} = undef;
	return $conf->{ACTIVATEKEY}; # pretend we got the "go" key.
    }
  }
}


1;

