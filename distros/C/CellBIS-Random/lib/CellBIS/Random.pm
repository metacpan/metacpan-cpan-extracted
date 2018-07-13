package CellBIS::Random;
use strict;
use warnings;
use utf8;

use Carp ();
use Scalar::Util qw(blessed weaken);
use List::SomeUtils qw(part);

# ABSTRACT: Tool for Randomize characters in strings.
our $VERSION = '0.1';

# Constructor :
# ------------------------------------------------------------------------
sub new {
  my $class = shift;
  my $self = {
    string => shift,
    result => 'null'
  };
  bless $self, $class;
  return $self;
}

sub set_string {
  my ($self, $string) = @_;
  $self->{string} = $string;
}

sub get_result {
  my $self = shift;
  return $self->{result};
}

sub random {
  my $self = shift;
  my $arg_len = scalar @_;
  my $string = '';
  my $count_odd = 0;
  my $count_even = 0;
  my $nested = 0;
  Carp::croak(q{Arguments is less than 2 or 3})
    unless $arg_len == 2 or $arg_len >= 3;
  
  if (blessed($self)) {
    $string = $self->{string};
    ($count_odd, $count_even) = @_ if ($arg_len >= 2);
    ($count_odd, $count_even, $nested) = @_ if ($arg_len >= 3);
    ($string, $count_odd, $count_even, $nested) = @_ if ($arg_len >= 4);
  } else {
    ($string, $count_odd, $count_even) = @_ if ($arg_len >= 3);
    ($string, $count_odd, $count_even, $nested) = @_ if ($arg_len >= 4);
  }
  
  my $result = $string;
  my $i = 0;
  
  # For Nested loop == 1 :
  if ($nested == 1) {
    if ($count_odd != 0 and $count_even != 0) {
      $i = 0;
      while ($i < $count_odd) {
        $result = $self->_union_odd_even($string);
        $i++;
      }
    }
    if ($count_odd != 0 and $count_even == 0) {
      $i = 0;
      while ($i < $count_even) {
        $result = $self->_union_even_odd($string);
        $i++;
      }
    }
  }
  
  # For Nested loop == 2 :
  elsif ($nested == 2) {
    if ($count_odd != 0 and $count_even != 0) {
      for ($i = 0; $i < $count_odd; $i++) {
        $result = $self->_union_odd_even($string);
        $result = $self->loop_union_for_odd_even($count_even, $result, 'even_odd');
      }
    }
    if ($count_odd != 0 and $count_even == 0) {
      $i = 0;
      while ($i < $count_odd) {
        $result = $self->_union_odd_even($string);
        $i++;
      }
    }
    if ($count_odd == 0 and $count_even != 0) {
      $i = 0;
      while ($i < $count_odd) {
        $result = $self->_union_even_odd($string);
        $i++;
      }
    }
  }
  
  # For Nested loop == 0 :
  else {
    if ($count_odd != 0 and $count_even != 0) {
      $i = 0;
      my $result1 = $self->loop_union_for_odd_even($count_odd, $result, 'odd_even');
      $result = $self->loop_union_for_odd_even($count_even, $result1, 'even_odd');
    }
    if ($count_odd != 0 and $count_even == 0) {
      $i = 0;
      $result = $self->loop_union_for_odd_even($count_odd, $result, 'odd_even');
    }
    if ($count_odd == 0 and $count_even != 0) {
      $i = 0;
      $result = $self->loop_union_for_odd_even($count_even, $result, 'even_odd');
    }
  }
  $self->{'result'} = $result if blessed($self);
  return $result;
}

sub unrandom {
  my $self = shift;
  my $arg_len = scalar @_;
  my $string = '';
  my $count_odd = 0;
  my $count_even = 0;
  my $nested = 0;
  Carp::croak(q{Arguments is less than 2 or 2})
    unless $arg_len == 2 or $arg_len >= 3;
  
  if (blessed($self)) {
    $string = $self->{string};
    ($count_odd, $count_even) = @_ if ($arg_len >= 2);
    ($count_odd, $count_even, $nested) = @_ if ($arg_len >= 3);
    ($string, $count_odd, $count_even, $nested) = @_ if ($arg_len >= 4);
  } else {
    ($string, $count_odd, $count_even) = @_ if ($arg_len >= 3);
    ($string, $count_odd, $count_even, $nested) = @_ if ($arg_len >= 4);
  }
  
  my $result = $string;
  my $i = 0;
  
  # For Nested loop == 1 :
  if ($nested == 1) {
    if ($count_odd != 0 and $count_even != 0) {
      $i = 0;
      while ($i < $count_odd) {
        $result = $self->_reverse_union_odd_even($string);
        $i++;
      }
    }
    if ($count_odd != 0 and $count_even == 0) {
      $i = 0;
      while ($i < $count_even) {
        $result = $self->_reverse_union_even_odd($string);
        $i++;
      }
    }
  }
  
  # For Nested loop == 2 :
  elsif ($nested == 2) {
    if ($count_odd != 0 and $count_even != 0) {
      # $i = 0;
      for ($i = 0; $i < $count_odd; $i++) {
        $result = $self->reverse_loop_union_for_odd_even($count_even, $string, 'even_odd');
        $result = $self->_reverse_union_odd_even($result);
      }
    }
    if ($count_odd != 0 and $count_even == 0) {
      $i = 0;
      while ($i < $count_odd) {
        $result = $self->_reverse_union_odd_even($string);
        $i++;
      }
    }
    if ($count_odd == 0 and $count_even != 0) {
      $i = 0;
      while ($i < $count_odd) {
        $result = $self->_reverse_union_even_odd($string);
        $i++;
      }
    }
  }
  
  # For Nested loop == 0 :
  else {
    if ($count_odd != 0 and $count_even != 0) {
      my $result1 = $self->reverse_loop_union_for_odd_even($count_even, $result, 'even_odd');
      $result = $self->reverse_loop_union_for_odd_even($count_odd, $result1, 'odd_even');
    }
    if ($count_odd != 0 and $count_even == 0) {
      $i = 0;
      $result = $self->reverse_loop_union_for_odd_even($count_odd, $string, 'odd_even');
    }
    if ($count_odd == 0 and $count_even != 0) {
      $i = 0;
      $result = $self->reverse_loop_union_for_odd_even($count_even, $string, 'even_odd');
    }
  }
  $self->{'result'} = $result if blessed($self);
  return $result;
}

#############################################################################################
# UTILITIES :
#############################################################################################

sub loop_union_for_odd_even {
  my ($self, $count_loop, $string, $type) = @_;
  my $result = $string;
  my $i = 0;
  
  if ($type eq 'odd_even') {
    while ($i < $count_loop) {
      $result = $self->_union_odd_even($result);
      $i++;
    }
  }
  if ($type eq 'even_odd') {
    while ($i < $count_loop) {
      $result = $self->_union_even_odd($result);
      $i++;
    }
  }
  
  return $result;
}

sub reverse_loop_union_for_odd_even {
  my ($self, $count_loop, $string, $type) = @_;
  
  my $result = $string;
  my $i = 0;
  
  if ($type eq 'odd_even') {
    while ($i < $count_loop) {
      $result = $self->_reverse_union_odd_even($result);
      $i++;
    }
  }
  if ($type eq 'even_odd') {
    while ($i < $count_loop) {
      $result = $self->_reverse_union_even_odd($result);
      $i++;
    }
  }
  
  return $result;
}

sub _reverse_union_odd_even {
  my ($self, $string) = @_;
  
  my @arr_str = $self->_split_blen($string, 1);
  my $i = 0;
  my ($even, $odd) = part {$i++ % 2} @arr_str;
  my $str_odd = join '', @{$odd};
  my $str_even = join '', @{$even};
  my $len_odd = length $str_odd;
  my $len_even = length $str_even;
  my $for_odd = substr $string, 0, $len_odd;
  my $for_even = substr $string, $len_odd, $len_even;
  my @arr_even = $self->_split_blen($for_even, 1);
  my @arr_odd = $self->_split_blen($for_odd, 1);
  my $result = '';
  
  if ($len_even > $len_odd) {
    $i = 0;
    while ($i < $len_even) {
      $result .= $arr_even[$i] if exists $arr_even[$i];
      $result .= $arr_odd[$i] if exists $arr_odd[$i];
      $i++;
    }
  }
  if ($len_even == $len_odd) {
    $i = 0;
    while ($i < $len_odd) {
      $result .= $arr_even[$i] if exists $arr_even[$i];
      $result .= $arr_odd[$i] if exists $arr_odd[$i];
      $i++;
    }
  }
  return $result;
}

sub _reverse_union_even_odd {
  my ($self, $string) = @_;
  
  my @arr_str = $self->_split_blen($string, 1);
  my $i = 0;
  my ($even, $odd) = part {$i++ % 2} @arr_str;
  my $str_even = join '', @{$even};
  my $str_odd = join '', @{$odd};
  my $len_even = length $str_even;
  my $len_odd = length $str_odd;
  my $for_even = substr $string, 0, $len_even;
  my $for_odd = substr $string, $len_even, $len_odd;
  my @arr_even = $self->_split_blen($for_even, 1);
  my @arr_odd = $self->_split_blen($for_odd, 1);
  my $result = '';
  if ($len_even > $len_odd) {
    $i = 0;
    while ($i < $len_even) {
      $result .= $arr_even[$i] if exists $arr_even[$i];
      $result .= $arr_odd[$i] if exists $arr_odd[$i];
      $i++;
    }
  }
  if ($len_even == $len_odd) {
    $i = 0;
    while ($i < $len_odd) {
      $result .= $arr_even[$i] if exists $arr_even[$i];
      $result .= $arr_odd[$i] if exists $arr_odd[$i];
      $i++;
    }
  }
  return $result;
}

sub _union_odd_even {
  my ($self, $string) = @_;
  
  my $odd_char = $self->_odd_even_char('odd', $string);
  my $even_char = $self->_odd_even_char('even', $string);
  
  return $odd_char . $even_char;
}

sub _union_even_odd {
  my ($self, $string) = @_;
  
  my $even_char = $self->_odd_even_char('even', $string);
  my $odd_char = $self->_odd_even_char('odd', $string);
  
  return $even_char . $odd_char;
}

sub _odd_even_char {
  my ($self, $type, $string) = @_;
  my $data = '';
  
  my @arr_str = $self->_split_blen($string, 1);
  
  my @result = ();
  my @pre_data = ();
  my @pre_data1 = ();
  my @data = ();
  if ($type eq 'odd') {
    @result = grep {$_ % 2 == 1} 0 .. $#arr_str;
    @pre_data1 = map {$pre_data[$_] => $arr_str[$result[$_]]} 0 .. $#result;
    @data = grep (defined, @pre_data1);
  }
  if ($type eq 'even') {
    @result = grep {$_ % 2 == 0} 0 .. $#arr_str;
    @pre_data1 = map {$pre_data[$_] => $arr_str[$result[$_]]} 0 .. $#result;
    @data = grep (defined, @pre_data1);
  }
  $data = join '', @data;
  return $data;
}

sub _split_bchar {
  my ($self, $string, $delimiter) = @_;
  
  # Split :
  my @split = split /$delimiter/, $string;
  
  # Return :
  return @split;
}

sub _split_blen {
  my ($self, $string, $length) = @_;
  
  # Split :
  my $len = "." x $length;
  my @data = grep {length > 0} split(/($len)/, $string);
  
  # Return :
  return @data;
}

1;

=encoding utf8

=head1 NAME

CellBIS::Random - Tool for Randomize characters in strings.

=head1 SYNOPSIS

  use CellBIS::Random;
  
  my $rand = CellBIS::Random->new();
  
  my $string = 'my_string_test_random';
  $rand->set_string($random);
  
  my $random = $rand->random(2, 3);
  print 'Random : ', $random, "\r"; #-> ynsn_dtgso__tmrtrmaei
  
  my $unrandom = $rand->unrandom(2, 3);
  print 'Unrandom : ', $unrandom, "\r"; #-> my_string_test_random

=head1 DESCRIPTION

The purpose of this module is to randomize characters in strings.
Before a random or unrandom character (extract from random), the string
will be converted to an array to get an odd/even number of key array.

=head1 METHODS

There is four methods C<set_string>, C<get_result>, C<random> and C<unrandom>.

Specifically for C<random> and C<unrandom> methods, you can use two or three arguments.
If using Object Oriented, you can use 2 arguments. But if using Procedural, you can use 3 arguments.
  
  # Object Oriented
  # Arguments : <number_of_random_odd>, <number_of_random_even>
  $rand->random(2, 3);
  $rand->unrandom(2, 3);
  
  # Procedural
  # Arguemnts : <your_string_to_random>, <number_of_random_odd>, <number_of_random_even>
  CellBIS::Random->random('your string to random', 2, 3);
  CellBIS::Random->unrandom('result of random to extract', 2, 3);

=head2 set_string

Method to set up string for Random action.

=head2 get_result

Method to get result of random character and Extract result of random.

=head2 random

With C<set_string> :

  use CellBIS::Random;
  
  my $string = 'my string here';
  $rand->set_string($string);
  
  my $result_random = $rand->random(2, 3);
  print "Random Result : $result_random \n";
  
Without C<set_string> :
  
  my $result_random = $rand->random('my string here', 2, 3);
  print "Random Result : $result_random \n";

=head2 unrandom

With C<set_string> :

  $rand->set_string($result_random);
  
  my $result_unrandom = $rand->unrandom(2, 3);
  print "Extract Random Result : $result_unrandom \n";
  
Without C<set_string> :
  
  my $result_unrandom = $rand->unrandom($rand->{result}, 2, 3);
  print "Extract Random Result : $result_unrandom \n";
  
=head1 EXAMPLES

Example to using Procedural and Object Oriented

=head2 Procedural

Case 1

  use CellBIS::Random;
  
  my $result_random = CellBIS::Random->random('my string here', 2, 3);
  print "Random Result : $result_random \n";
  
  my $extract_random = CellBIS::Random->unrandom($result_random, 2, 3);
  print "Extract Random Result : $extract_random \n";
  
Case 2

  use CellBIS::Random;
  
  my $rand = CellBIS::Random->new();
  my $result_random = $rand->random('my string here', 2, 3);
  print "Random Result : $result_random \n";
  
  my $extract_random = $rand->unrandom($result_random, 2, 3);
  print "Extract Random Result : $extract_random \n";
  
=head2 Object Oriented

Case 1

  use CellBIS::Random;
  
  my $rand = CellBIS::Random->new();
  
  # For Random
  $rand->set_string('my string here');
  $rand->random(2, 3);
  my $result_random = $rand->get_result();
  
  print "Random Result : $result_random \n";
  
  =====================================================
  
  # For Extract Random
  $rand->set_string($result_random);
  $rand->unrandom(2, 3);
  my $extract_random = $rand->get_result();
  
  print "Extract Random Result : $extract_random \n";
  
Case 2

  use CellBIS::Random;
  
  my $rand = CellBIS::Random->new();
  
  # For Random
  $rand->set_string('my string here');
  my $result_random = $rand->random('my string here', 2, 3);
  
  print "Random Result : $result_random \n";
  
  =====================================================
  
  # For Extract Random
  my $extract_random = $rand->unrandom($result_random, 2, 3);
  
  print "Extract Random Result : $extract_random \n";
  
  
=head1 AUTHOR

Achmad Yusri Afandi, E<lt>yusrideb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Achmad Yusri Afandi

This program is free software, you can redistribute it and/or modify it under the terms of
the Artistic License version 2.0.

=cut
