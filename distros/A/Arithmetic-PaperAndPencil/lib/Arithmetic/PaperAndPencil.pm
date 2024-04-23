# -*- encoding: utf-8; indent-tabs-mode: nil -*-

use 5.38.0;
use utf8;
use strict;
use warnings;
use open ':encoding(UTF-8)';
use feature      qw/class/;
use experimental qw/class/;
use Arithmetic::PaperAndPencil::Action;
use Arithmetic::PaperAndPencil::Char;
use Arithmetic::PaperAndPencil::Label;

class Arithmetic::PaperAndPencil 0.01;

use Arithmetic::PaperAndPencil::Number qw/max_unit adjust_sub/;

use Carp;
use Exporter 'import';
use POSIX qw/floor ceil/;
use List::Util qw/min max/;

our $VERSION = 0.01;

field @action;

method from_csv {
  my ($csv) = @_;
  @action = ();
  for my $line (split("\n", $csv)) {
    my $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => 'dummy');
    $action->from_csv($line);
    push @action, $action;
  }
}

method csv {
  my $result = join "\n", map { $_->csv } @action;
  if (substr($result, -1, 1) ne "\n") {
    $result .= "\n";
  }
  return $result;
}

method html(%param) {
  my $lang   = $param{lang}   // 'fr';
  my $silent = $param{silent} // 0;
  my $level  = $param{level}  // 3;
  my $css    = $param{css};
  my $talkative = 1 - $silent; # "silent" better for API, "talkative" better for programming
  my $result    = '';
  my @sheet     = ();
  my %vertical_lines = ();
  my %cache_l2p_col  = ();
  my $c_min     = 0;
  my $l_min     = 0;

  # checking the minimum line number
  my sub check_l_min($l) {
    if ($l < $l_min) {
      # inserting new empty lines before the existing ones
      for ($l .. $l_min - 1) {
        unshift @sheet, [];
      }
      # updating the line minimum number
      $l_min = $l;
    }
  }
  # logical to physical line number
  my sub l2p_lin($logl) {
    my $result = $logl - $l_min;
    return $result;
  }

  # checking the minimum column number
  my sub check_c_min($c) {
    if ($c < $c_min) {
      my $delta_c = $c_min - $c;
      for my $line (@sheet) {
        for (1 .. $delta_c) {
          unshift @$line, Arithmetic::PaperAndPencil::Char->space_char;
        }
      }
      $c_min = $c;
      %cache_l2p_col  = ();
    }
  }
  # logical to physical column number
  my sub l2p_col($logc) {
    if ($cache_l2p_col{$logc}) {
      return $cache_l2p_col{$logc};
    }
    my $result = $logc - $c_min;
    for my $col (keys %vertical_lines) {
      if ($logc > $col) {
        ++$result;
      }
    }
    $cache_l2p_col{$logc} = $result;
    return $result;
  }

  my sub filling_spaces($l, $c) {
    # putting spaces into all uninitialised boxes
    for my $l1 (0 .. l2p_lin($l)) {
      $sheet[$l1][0] //= Arithmetic::PaperAndPencil::Char->space_char;
    }
    for my $c1 (0 .. l2p_col($c)) {
      $sheet[l2p_lin($l)][$c1] //= Arithmetic::PaperAndPencil::Char->space_char;
    }
  }

  for my $action (@action) {
    if ($action->label =~ /^TIT/ or $action->label eq 'NXP01') {
      @sheet          = ();
      %vertical_lines = ();
      %cache_l2p_col  = ();
      $c_min          = 0;
      $l_min          = 0;
    }

    # Drawing a vertical line
    if ($action->label eq 'DRA01') {
      if  ($action->w1c != $action->w2c) {
        die "The line is not vertical, starting at column ", $action->w1c, " and ending at column ", $action->w2c;
      }
      # checking the line and column minimum numbers
      check_l_min($action->w1l);
      check_l_min($action->w2l);
      check_c_min($action->w1c);
      # making some clear space for the vertical line
      unless ($vertical_lines{$action->w1c}) {
        $vertical_lines{$action->w1c} = 1;
        # clearing the cache
        %cache_l2p_col  = ();

        # shifting characters past the new vertical line's column
        for my $l (0 .. $#sheet) {
          for my $c (0 .. l2p_col($action->w1c)) {
             $sheet[$l][$c] //= Arithmetic::PaperAndPencil::Char->space_char;
          }
          my $line = $sheet[$l];
          splice(@$line, l2p_col($action->w1c) + 1, 0, Arithmetic::PaperAndPencil::Char->space_char);
          $sheet[$l] = $line;
        }
      }
      # making the vertical line
      for my $l ($action->w1l .. $action->w2l) {
        filling_spaces($l, $action->w1c);
        $sheet[l2p_lin($l)][l2p_col($action->w1c) + 1] = Arithmetic::PaperAndPencil::Char->pipe_char;
      }
    }

    # drawing an horizontal line or drawing a hook over a dividend
    my sub draw_h($at, $from, $to) {
      # checking the line and column minimum numbers
      check_l_min($at);
      check_c_min($from);
      check_c_min($to);
      # begin and end
      my ($c_beg, $c_end);
      if ($from > $to) {
        $c_beg = l2p_col($to);
        $c_end = l2p_col($from);
        filling_spaces($at, $from);
      }
      else {
        $c_beg = l2p_col($from);
        $c_end = l2p_col($to);
        filling_spaces($at, $to);
      }
      for my $i ($c_beg .. $c_end) {
        $sheet[l2p_lin($at)][$i]->set_underline(1);
      }
    }

    # Drawing an horizontal line
    if ($action->label eq 'DRA02') {
      if ($action->w1l != $action->w2l) {
        die "The line is not horizontal, starting at line {$action->w1l} and ending at line {$action->w2l}";
      }
      draw_h($action->w1l, $action->w1c, $action->w2c);
    }

    # Drawing a hook over a dividend (that is, an horizontal line above)
    if ($action->label eq 'HOO01') {
      if  ($action->w1l != $action->w2l) {
        die "The hook is not horizontal, starting at line {$action->w1l} and ending at line {$action->w2l}";
      }
      draw_h($action->w1l - 1, $action->w1c, $action->w2c);
    }

    # Drawing an oblique line
    if ($action->label eq 'DRA03') {
      if ($action->w2c - $action->w1c != $action->w2l - $action->w1l) {
        die "The line is not oblique";
      }
      # checking the line and column minimum numbers
      check_l_min($action->w1l);
      check_l_min($action->w2l);
      check_c_min($action->w1c);
      check_c_min($action->w2c);
      # begin and end
      my ($l_beg, $c_beg);
      if ($action->w2l > $action->w1l) {
        # line is defined top-left to bot-right
        $l_beg = $action->w1l;
        $c_beg = $action->w1c;
      }
      else {
        # line was defined bot-right to top-left
        $l_beg = $action->w2l;
        $c_beg = $action->w2c;
      }
      # drawing the line top-left to bot-right
      for my $i (0 .. abs($action->w2l - $action->w1l)) {
        filling_spaces($l_beg + $i, $c_beg + $i);
        my $l1 = l2p_lin($l_beg + $i);
        my $c1 = l2p_col($c_beg + $i);
        $sheet[$l1][$c1]->set_char('\\');
        # the line
        #   $sheet[$l1; $c1] = backslash_char->char;
        # would be wrong, because in some cases it would clobber the "underline" attribute of an already existing char
      }
    }
    if ($action->label eq 'DRA04') {
      if ($action->w2c - $action->w1c != $action->w1l - $action->w2l) {
        die "The line is not oblique";
      }
      # checking the line and column minimum numbers
      check_l_min($action->w1l);
      check_l_min($action->w2l);
      check_c_min($action->w1c);
      check_c_min($action->w2c);
      # begin and end
      my ($l_beg, $c_beg);
      if ($action->w2l > $action->w1l) {
        # line is defined top-right to bot-left
        $l_beg = $action->w1l;
        $c_beg = $action->w1c;
      }
      else {
        # line was defined bot-left to top-right
        $l_beg = $action->w2l;
        $c_beg = $action->w2c;
      }
      # drawing the line top-right to bot-left
      for my $i (0 .. abs($action->w2l - $action->w1l)) {
        filling_spaces($l_beg + $i, $c_beg - $i);
        my $l1 = l2p_lin($l_beg + $i);
        my $c1 = l2p_col($c_beg - $i);
        $sheet[$l1][$c1]->set_char('/');
        # the line
        #   $sheet[$l1; $c1] = slash_char();
        # would be wrong, because in some cases it would clobber the "underline" attribute of an already existing char
      }
    }

    # Reading some digits (or other characters) and possibly striking them
    if ($action->r1val ne '') {

      # checking the line and column minimum numbers
      # (should not be necessary: if the digits are being read, they must have been previously written)
      check_l_min($action->r1l);
      check_c_min($action->r1c - length($action->r1val) + 1);

      # putting spaces into all uninitialised boxes
      # (should not be necessary, for the same reason)
      filling_spaces($action->r1l, $action->r1c);

      # tagging each char
      for my $i (0 .. length($action->r1val) - 1) {
         my $str = substr($action->r1val, $i, 1);
         for ($sheet[l2p_lin($action->r1l)][l2p_col($action->r1c - length($action->r1val) + $i + 1)]) {
           $_->set_read(1);
           if ($action->r1str) {
             $_->set_strike(1);
           }
         }
      }
    }
    if ($action->r2val ne '') {

      # checking the line and column minimum numbers
      # (should not be necessary, for the same reason as r1val)
      check_l_min($action->r2l);

      # putting spaces into all uninitialised boxes
      # (should not be necessary, for the same reason)
      filling_spaces($action->r2l, $action->r2c);

      # tagging each char
      for my $i (0 .. length($action->r2val) - 1) {
         my $str = substr($action->r2val, $i, 1);
         for ($sheet[l2p_lin($action->r2l)][l2p_col($action->r2c - length($action->r2val) + $i + 1)]) {
           $_->set_read(1);
           if ($action->r2str) {
             $_->set_strike(1);
           }
         }
      }
    }

    # Writing some digits (or other characters)
    if ($action->w1val ne '') {
      # checking the line and column minimum numbers
      check_l_min($action->w1l);
      check_c_min($action->w1c - length($action->w1val) + 1);
      # putting spaces into all uninitialised boxes
      filling_spaces($action->w1l, $action->w1c);
      # putting each char separately into its designated box
      for my $i (0 .. length($action->w1val) - 1) {
         my $str = substr($action->w1val, $i, 1);
         for ($sheet[l2p_lin($action->w1l)][l2p_col($action->w1c - length($action->w1val) + $i + 1)]) {
           $_->set_char($str);
           $_->set_write(1);
         }
      }
    }
    if ($action->w2val ne '') {
      # checking the line and column minimum numbers
      check_l_min($action->w2l);
      check_c_min($action->w2c - length($action->w2val) + 1);
      # putting spaces into all uninitialised boxes
      filling_spaces($action->w2l, $action->w2c);
      # putting each char separately into its designated box
      for my $i (0 .. length($action->w2val) - 1) {
         my $str = substr($action->w2val, $i, 1);
         for ($sheet[l2p_lin($action->w2l)][l2p_col($action->w2c - length($action->w2val) + $i + 1)]) {
           $_->set_char($str);
           $_->set_write(1);
         }
      }
    }

    # Erasing characters
    if ($action->label eq 'ERA01') {
      if ($action->w1l != $action->w2l) {
        die "The chars are not horizontally aligned, starting at line {$action->w1l} and ending at line {$action->w2l}";
      }
      # checking the line and column minimum numbers
      check_l_min($action->w1l);
      check_c_min($action->w1c);
      check_c_min($action->w2c);
      # begin and end
      my ($c_beg, $c_end);
      if ($action->w1c > $action->w2c) {
        $c_beg = l2p_col($action->w2c);
        $c_end = l2p_col($action->w1c);
        filling_spaces($action->w1l, $action->w1c);
      }
      else {
        $c_beg = l2p_col($action->w1c);
        $c_end = l2p_col($action->w2c);
        filling_spaces($action->w1l, $action->w2c);
      }
      for my $i ($c_beg .. $c_end) {
        $sheet[l2p_lin($action->w1l)][$i]->set_char(' ');
      }
    }

    # Talking
    if ($talkative or substr($action->label, 0, 3) eq 'TIT') {
      my $line = Arithmetic::PaperAndPencil::Label::full_label($action->label, $action->val1, $action->val2, $action->val3, $lang);
      if ($line) {
        if (substr($action->label, 0, 3) eq 'TIT') {
          $line = "<operation>$line</operation>\n";
        }
        else {
          $line = "<talk>$line</talk>\n";
        }
        $result .= $line;
      }
    }

    # Showing the operation
    if ($action->level <= $level) {
      my $op = '';
      for my $l (0 .. $#sheet) {
        my $line  = $sheet[$l];
        my $line1 = join('', map { $_->pseudo_html } @$line);
        $op .= $line1 . "\n";
      }
      if ($op ne '') {
        $result .= "<pre>\n$op</pre>\n";
      }
      # untagging written and read chars
      for my $line (@sheet) {
        for my $char (@$line) {
          $char->set_read (0);
          $char->set_write(0);
        }
      }
    }
  }

  # simplyfing pseudo-HTML
  $result =~ s{</underline><underline>}{}g;
  $result =~ s{</strike><strike>}{}g;
  $result =~ s{</write>(\h*)<write>}{$1}g;
  $result =~ s{</read>(\h*)<read>}{$1}g;

  # changing pseudo-HTML into proper HTML
  $result =~ s/operation>/h1>/g;
  if ($css->{talk}) {
    $result =~ s!</talk>!</p>!g;
    $result =~ s!<talk>!<p class='$css->{talk}'>!g;
  }
  else {
    $result =~ s/talk>/p>/g;
  }
  if ($css->{underline}) {
    $result =~ s!</underline>!</span>!g;
    $result =~ s!<underline>!<span class='$css->{underline}'>!g;
  }
  else {
    $result =~ s/underline>/u>/g;
  }
  # maybe I should replace all "strike" tags by "del"? or by "s"?
  # see https://www.w3schools.com/tags/tag_strike.asp : <strike> is not supported in HTML5
  if ($css->{strike}) {
    $result =~ s!</strike>!</span>!g;
    $result =~ s!<strike>!<span class='$css->{strike}'>!g;
  }
  if ($css->{read}) {
    $result =~ s!</read>!</span>!g;
    $result =~ s!<read>!<span class='$css->{read}'>!g;
  }
  else {
    $result =~ s/read>/em>/g;
  }
  if ($css->{write}) {
    $result =~ s!</write>!</span>!g;
    $result =~ s!<write>!<span class='$css->{write}'>!g;
  }
  else {
    $result =~ s/write>/strong>/g;
  }
  $result =~ s/\h+$//gm;

  return $result;
}

method addition(@numbers) {
  if (@numbers == 0) {
    croak "The addition needs at least one number to add";
  }

  my $action;
  my $nb         = 0+ @numbers;
  my $radix      = $numbers[0]->radix;
  my $max_length = 0;
  my @digits; # storing the numbers' digits
  my @total;  # storing the total's digit positions

  $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => "TIT01", val1 => "$radix");
  push @action, $action;

  for my $i (0 .. $#numbers) {
    my $n = $numbers[$i];
    # checking the number
    if ($n->radix != $radix) {
      croak "All numbers must have the same radix";
    }
    # writing the number
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => $i, w1c => 0, w1val => $n->value);
    push(@action, $action);
    # preparing the horizontal line
    if ($max_length < $n->chars) {
      $max_length = $n->chars;
    }
    # feeding the table of digits
    my $val = reverse($n->value);
    for my $j (0 .. length($val) - 1) {
      my $x = substr($val, $j, 1);
      push(@{$digits[$j]}, { lin => $i, col => -$j, val => $x } );
    }
  }
  $action = Arithmetic::PaperAndPencil::Action->new(level => 2, label => 'DRA02', w1l => $nb - 1, w1c => 1 - $max_length
                                                                                , w2l => $nb - 1, w2c => 0);
  push(@action, $action);
  for my $j (0 .. $max_length -1) {
    $total[$j] = { lin => $nb, col => -$j };
  }
  my $result = $self->_adding(\@digits, \@total, 0, $radix);
  return Arithmetic::PaperAndPencil::Number->new(value => $result, radix => $radix);
}

method subtraction(%param) {
  my $high = $param{high};
  my $low  = $param{low};
  my $type = $param{type}  // 'std';

  my Arithmetic::PaperAndPencil::Action $action;
  my $radix = $high->radix;
  my $leng  = $high->chars;
  if ($low->radix != $radix) {
    croak "The two numbers have different bases: $radix != @{[$low->radix]}";
  }
  if ($type ne 'std' && $type ne 'compl') {
    croak "Subtraction type '$type' unknown";
  }
  if ($high < $low) {
    croak "The high number @{[$high->value]} must be greater than or equal to the low number @{[$low->value]}";
  }
  if (@action) {
    $action[-1]->set_level(0);
  }
  if (($type eq 'std')) {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'TIT02', val1 => $high->value, val2 => $low->value, val3 => $radix);
    push(@action, $action);
    # set-up
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 0, w1c => $leng, w1val => $high->value);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 1, w1c => $leng, w1val => $low->value);
    push(@action, $action);

    # computation
    my $result = '';
    $result = $self->_embedded_sub(basic_level => 0, l_hi => 0, c_hi => $leng, high => $high
                                                   , l_lo => 1, c_lo => $leng, low  => $low
                                                   , l_re => 2, c_re => $leng);
    $action[-1]->set_level(0);
    return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
  }
  else {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'TIT15', val1 => $high->value, val2 => $low->value, val3 => $radix);
    push(@action, $action);
    my Arithmetic::PaperAndPencil::Number $complement = $low->complement($leng);
    # set-up
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                                   , label => 'SUB03', val1 => $radix, val2 => $low->value, val3  => $complement->value
                                                     , w1l  => 0     , w1c  => $leng      , w1val => $high->value
                                                     , w2l  => 1     , w2c  => $leng      , w2val => $complement->value);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 2, label => 'DRA02', w1l => 1, w1c => 1
                                               , w2l => 1, w2c => $leng);
    push(@action, $action);

    my @digits; # storing the numbers' digits
    my @result; # storing the result's digit positions
    my $compl_val = '0' x ($leng - $complement->chars) . $complement->value;
    for my $i (0 .. $leng - 1) {
      $digits[$i][0] = { lin => 0, col => $leng - $i, val => substr($high->value, $leng - $i - 1, 1) };
      $digits[$i][1] = { lin => 1, col => $leng - $i, val => substr($compl_val  , $leng - $i - 1, 1) };
      $result[$i]    = { lin => 2, col => $leng - $i };
    }
    my $result = substr($self->_adding(\@digits, \@result, 0, $radix), 1);
    # getting rid of leading zeroes except if the result is zero
    $result =~ s/^0*//;
    if ($result eq '') {
      $result = '0';
    }
    $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => 'SUB04', val1 => $result, r1l => 2, r1c => 0, r1val => '1', r1str => 1);
    push(@action, $action);
    return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
  }
}

method multiplication(%param) {
  my $multiplicand = $param{multiplicand};
  my $multiplier   = $param{multiplier};
  my $type         = $param{type}         // 'std';
  my $direction    = $param{direction}    // 'ltr';        # for the 'boat' type, elementary products are processed left-to-right or right-to-left ('rtl')
  my $mult_and_add = $param{mult_and_add} // 'separate';   # for the 'boat' type, addition is a separate subphase (contrary: 'combined')
  my $product      = $param{product}      // 'L-shaped';   # for the 'jalousie-?" types, the product is L-shaped along the rectangle (contrary: 'straight' on the bottom line)

  my Arithmetic::PaperAndPencil::Action $action;
  if ($multiplicand->radix != $multiplier->radix) {
    die "Multiplicand and multiplier have different bases: @{[$multiplicand->radix]} != @{[$multiplier->radix]}";
  }
  my $title = '';
  my $radix = $multiplicand->radix;
  if    ($type eq 'std'       ) { $title = 'TIT03' ; }
  elsif ($type eq 'shortcut'  ) { $title = 'TIT04' ; }
  elsif ($type eq 'prepared'  ) { $title = 'TIT05' ; }
  elsif ($type eq 'jalousie-A') { $title = 'TIT06' ; }
  elsif ($type eq 'jalousie-B') { $title = 'TIT07' ; }
  elsif ($type eq 'boat'      ) { $title = 'TIT08' ; }
  elsif ($type eq 'russian'   ) { $title = 'TIT19' ; }
  if ($title eq '') {
    die "Multiplication type '$type' unknown";
  }
  if ($type eq 'jalousie-A' || $type eq 'jalousie-B') {
    if ($product ne 'L-shaped' && $product ne 'straight') {
      die "Product shape '$product' should be 'L-shaped' or 'straight'";
    }
  }
  if ($type eq 'boat') {
    if ($direction ne 'ltr' && $direction ne 'rtl') {
      die "Direction '$direction' should be 'ltr' (left-to-right) or 'rtl' (right-to-left)";
    }
    if ($mult_and_add ne 'separate' && $mult_and_add ne 'combined') {
      die "Parameter mult_and_add '$mult_and_add' should be 'separate' or 'combined'";
    }
  }

  my $len1 = $multiplicand->chars;
  my $len2 = $multiplier->chars;
  if (@action) {
    $action[-1]->set_level(0);
  }
  $action = Arithmetic::PaperAndPencil::Action->new(level => 9
               , label => $title
               , val1  => $multiplicand->value
               , val2  => $multiplier->value
               , val3  => $multiplier->radix
               );
  push(@action, $action);

  # caching the partial products for prepared and shortcut multiplications
  my %mult_cache = (1 => $multiplicand);
  if ($type eq 'prepared') {
    my $limit = max(split('', $multiplier->value));
    $self->_preparation(factor => $multiplicand, limit => $limit, cache => \%mult_cache);
  }

  if ($type eq 'std' || $type eq  'shortcut' || $type eq 'prepared') {
    # set-up
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                          , label => 'WRI00', w1l => 0, w1c => $len1 + $len2, w1val => $multiplicand->value
                                            , w2l => 1, w2c => $len1 + $len2, w2val => $multiplier->value);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 2
                          , label => 'DRA02', w1l => 1, w1c => min($len1, $len2)
                                            , w2l => 1, w2c => $len1 + $len2);
    push(@action, $action);

    # multiplication of two single-digit numbers
    if ($len1 == 1 && $len2 == 1) {
      my Arithmetic::PaperAndPencil::Number $pdt = $multiplier * $multiplicand;
      $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => 'MUL02'
                   , r1l => 0, r1c => 2, r1val => $multiplier->value   , val1 => $multiplier->value
                   , r2l => 1, r2c => 2, r2val => $multiplicand->value , val2 => $multiplicand->value
                   , w1l => 2, w1c => 2, w1val => $pdt->value          , val3 => $pdt->value
                   );
      push(@action, $action);
      return $pdt;
    }
    # multiplication with a single-digit multiplier
    if ($len2 == 1 && $type eq 'prepared') {
      my Arithmetic::PaperAndPencil::Number $pdt;
      $pdt = $mult_cache{$multiplier->value};
      $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => 'WRI05', val1 => $pdt->value
                   , w1l => 2, w1c => $len1 + 1, w1val => $pdt->value
                   );
      push(@action, $action);
      return $pdt;
    }
    if ($len2 == 1) {
      my Arithmetic::PaperAndPencil::Number $pdt;
      $pdt = $self->_simple_mult(basic_level => 0, l_md => 0, c_md => $len1 + 1, multiplicand => $multiplicand
                                                 , l_mr => 1, c_mr => $len1 + 1, multiplier   => $multiplier
                                                 , l_pd => 2, c_pd => $len1 + 1 );
      $action[-1]->set_level(0);
      return $pdt;
    }
    # multiplication with a multi-digit multiplier
    my Arithmetic::PaperAndPencil::Number $pdt;
    $pdt = $self->_adv_mult(basic_level => 0, l_md => 0, c_md => $len1 + $len2, multiplicand => $multiplicand
                                            , l_mr => 1, c_mr => $len1 + $len2, multiplier   => $multiplier
                                            , l_pd => 2, c_pd => $len1 + $len2
                                            , type => $type, cache => \%mult_cache);
    $action[-1]->set_level(0);
    return $pdt;
  }
  if ($type eq 'jalousie-A' || $type eq 'jalousie-B') {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                          , label => 'DRA02', w1l => 0, w1c => 1
                                            , w2l => 0, w2c => 2 * $len1);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                  , label => 'DRA01', w1l => 1        , w1c => 0
                                    , w2l => 2 * $len2, w2c => 0);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                  , label => 'DRA01', w1l => 1        , w1c => 2 * $len1
                                    , w2l => 2 * $len2, w2c => 2 * $len1);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                  , label => 'DRA02', w1l => 2 * $len2, w1c => 1
                                    , w2l => 2 * $len2, w2c => 2 * $len1);
    push(@action, $action);
  }
  if ($type eq 'jalousie-A') {
    for my $i (1 .. $len1) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 0, w1c => 2 * $i - 1, w1val => substr($multiplicand->value, $i - 1, 1));
      push(@action, $action);
    }
    for my $i (1 .. $len2) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 2 * $i, w1c => 2 * $len1 + 1, w1val => substr($multiplier->value, $i - 1, 1));
      push(@action, $action);
    }
    for my $i (1 .. $len1 + $len2 - 1) {
      my $l1 = 1;
      my $c1 = 2 * $i;
      my $l2 = 2 * $len2;
      my $c2 = 2 * ($i - $len2) + 1;
      if ($c1 >= 2 * $len1) {
        $l1 += $c1 - 2 * $len1;
        $c1  = 2 * $len1;
      }
      if ($c2 <= 0 && $product eq 'L-shaped') {
        $l2 -= 1 - $c2;
        $c2  = 1;
      }
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DRA04', w1l => $l1, w1c => $c1, w2l => $l2, w2c => $c2);
      push(@action, $action);
    }
    # end of set-up phase
    $action[-1]->set_level(2);

    # multiplication phase
    my @partial;
    for my $l (1 .. $len2) {
      my $x = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplier->value, $l - 1, 1));
      for my $c (1 .. $len1) {
        my $y = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplicand->value, $c - 1, 1));
        my Arithmetic::PaperAndPencil::Number $pdt   = $x * $y;
        my Arithmetic::PaperAndPencil::Number $unit  = $pdt->unit;
        my Arithmetic::PaperAndPencil::Number $carry = $pdt->carry;
        $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                     , label => 'MUL01', r1l => 2 * $l    , r1c => 2 * $len1 + 1, r1val => $x->value    , val1 => $x->value
                                       , r2l => 0         , r2c => 2 * $c - 1   , r2val => $y->value    , val2 => $y->value
                                       , w1l => 2 * $l - 1, w1c => 2 * $c - 1   , w1val => $carry->value, val3 => $pdt->value
                                       , w2l => 2 * $l    , w2c => 2 * $c       , w2val => $unit->value
                                       );
        push(@action, $action);
        $partial[$len1 + $len2 - $l - $c    ][2 * $l    ] = { lin => 2 * $l    , col => 2 * $c    , val => $unit->value };
        $partial[$len1 + $len2 - $l - $c + 1][2 * $l - 1] = { lin => 2 * $l - 1, col => 2 * $c - 1, val => $carry->value };
      }
      # end of line
      $action[-1]->set_level(3);
    }
    # end of multiplication phase
    $action[-1]->set_level(2);

    # Addition phase
    my @final;
    my $limit;
    if    ($product eq 'L-shaped') { $limit = $len1;         }
    elsif ($product eq 'straight') { $limit = $len1 + $len2; }
    for my $i (0 .. $limit - 1) {
      $final[$i] = { lin => 2 * $len2 + 1, col => 2 * ($len1 - $i) - 1 };
    }
    for my $i ($limit .. $len1 + $len2 - 1) {
      $final[$i] = { lin => 2 * ($len1 + $len2 - $i), col => 0 };
    }
    my $result = $self->_adding(\@partial, \@final, 0, $radix);
    $action[-1]->set_level(0);
    return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
  }
  if ($type eq 'jalousie-B') {
    for my $i (1 .. $len1) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 0, w1c => 2 * $i, w1val => substr($multiplicand->value, $i - 1, 1));
      push(@action, $action);
    }
    for my $i (1 .. $len2) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 2 * ($len2 - $i + 1), w1c => 0, w1val => substr($multiplier->value, $i - 1, 1));
      push(@action, $action);
    }
    for my $i (1 - $len2 .. $len1 - 1) {
      my $l1 = 1;
      my $c1 = 1 + 2 * $i;
      my $l2 = 2 * $len2;
      my $c2 = 2 * ($i + $len2);
      if ($c1 <= 0) {
        $l1 += 1 - $c1;
        $c1  = 1;
      }
      if ($c2 >= 2 * $len1 && $product eq 'L-shaped') {
        $l2 -= $c2 - 2 * $len1;
        $c2  = 2 * $len1;
      }
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DRA03', w1l => $l1, w1c => $c1, w2l => $l2, w2c => $c2);
      push(@action, $action);
    }
    # end of set-up phase
    $action[-1]->set_level(2);

    # multiplication phase
    my @partial;
    for my $l (1 .. $len2) {
      my $x = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplier->value, $len2 - $l, 1));
      for my $c (1 .. $len1) {
        my $y = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplicand->value, $c - 1, 1));
        my Arithmetic::PaperAndPencil::Number $pdt   = $x * $y;
        my Arithmetic::PaperAndPencil::Number $unit  = $pdt->unit;
        my Arithmetic::PaperAndPencil::Number $carry = $pdt->carry;
        $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                     , label => 'MUL01', r1l => 2 * $l    , r1c => 0         , r1val => $x->value    , val1 => $x->value
                                       , r2l => 0         , r2c => 2 * $c    , r2val => $y->value    , val2 => $y->value
                                       , w1l => 2 * $l    , w1c => 2 * $c - 1, w1val => $carry->value, val3 => $pdt->value
                                       , w2l => 2 * $l - 1, w2c => 2 * $c    , w2val => $unit->value
                                       );
        push(@action, $action);
        $partial[$len1 - $c + $l - 1][2 * $l - 1] = { lin => 2 * $l - 1, col => 2 * $c    , val => $unit->value };
        $partial[$len1 - $c + $l    ][2 * $l    ] = { lin => 2 * $l    , col => 2 * $c - 1, val => $carry->value };
      }
      # end of line
      $action[-1]->set_level(3);
    }
    # end of multiplication phase
    $action[-1]->set_level(2);

    # Addition phase
    my @final;
    my $limit;
    if    ($product eq 'L-shaped') { $limit = $len2; }
    elsif ($product eq 'straight') { $limit = 0;     }
    for my $i (0 .. $limit - 1) {
      $final[$i] = { lin => 2 * $i + 2, col => 2 * $len1 + 1 };
    }
    for my $i ($limit .. $len1 + $len2 - 1) {
      $final[$i] = { lin => 2 * $len2 + 1, col => 2 * ($len1 + $len2 - $i) };
    }
    my $result = $self->_adding(\@partial, \@final, 0, $radix);
    $action[-1]->set_level(0);
    return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
  }
  if ($type eq 'boat') {
    # set up phase
    my $tot_len = $len1 + $len2 - 1;
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l =>  0, w1c => $tot_len, w1val => $multiplicand->value);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DRA02', w1l => -1, w1c => 0, w2l => -1, w2c => $tot_len);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 2, label => 'DRA02', w1l =>  0, w1c => 0, w2l =>  0, w2c => $tot_len);
    push(@action, $action);

    # arrays of line numbers per column
    my @lines_below = ( 1 ) x ($len1 + $len2);
    my @lines_above = (-1 ) x ($len1 + $len2);
    my @result      = ('0') x ($len1 + $len2);

    # multiplication phase
    my @partial;
    for my $col ($len2 .. $tot_len) {
      my $x  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplicand->value, $col - $len2, 1));
      # write the multiplier at the proper column
      $self->_push_below($multiplier, $col, \@lines_below);

      # partial products
      my @range = (1 .. $len2);
      my $last  = $len2;
      if ($direction eq 'rtl') {
        @range = reverse(@range);
        $last  = 1;
      }
      for my $c (@range) {
        my $y  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplier->value, $c - 1, 1));
        my Arithmetic::PaperAndPencil::Number $pdt = $x * $y;
        $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'MUL01'
                       , val1 => $y->value, r1l => $lines_below[$col - $len2 + $c] - 1, r1c => $col - $len2 + $c, r1val => $y->value, r1str => 1
                       , val2 => $x->value, r2l => 0                                  , r2c => $col             , r2val => $x->value, r2str => 0+ ($c == $last)
                       , val3 => $pdt->value);
        push(@action, $action);
        if ($mult_and_add eq 'separate') {
          $self->_push_above($pdt, $col - $len2 + $c, \@lines_above, \@partial, $tot_len);
        }
        else {
          $self->_add_above($pdt, $col - $len2 + $c, \@lines_above, \@result);
        }
        $action[-1]->set_level(4);
      }
      $action[-1]->set_level(3);
    }

    # addition phase
    my @final;
    my $result;
    if ($mult_and_add eq 'separate') {
      for my $col (0 .. -1 + @lines_above) {
        $final[$col] = { lin => $lines_above[$tot_len - $col], col => $tot_len - $col };
      }
      $result = $self->_adding(\@partial, \@final, 0, $radix, 1);
    }
    else {
       $result = join('', @result);
    }
    $action[-1]->set_level(0);
    return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
  }
  if ($type eq 'russian') {
    # set-up
    my Arithmetic::PaperAndPencil::Number $md = $multiplicand;
    my Arithmetic::PaperAndPencil::Number $mr = $multiplier;
    my $c_md = 2 * $len2 + 1 + $len1;
    my $c_mr = $len2;
    $action = Arithmetic::PaperAndPencil::Action->new(level => 3, label => 'WRI00'
                                        , w1l => 0, w1c => $c_md, w1val => $md->value
                                        , w2l => 0, w2c => $c_mr, w2val => $mr->value);
    push(@action, $action);

    # first phase, doubling the multiplicand and halving the multiplier
    my $l = 0;
    my @lines = ();
    push(@lines, { mr => $mr, md => $md });
    while ($mr->value ne '1') {
      $mr = $self->_halving( l1 => $l, c1 => $c_mr, l2 => $l + 1, c2 => $c_mr, number => $mr);
      $md = $self->_doubling(l1 => $l, c1 => $c_md, l2 => $l + 1, c2 => $c_md, number => $md);
      push(@lines, { mr => $mr, md => $md });
      $l++;
    }
    $action[-1]->set_level(2);

    # second phase, testing even numbers and striking
    my @partial;
    my @final;
    for my $l (0 .. $#lines) {
      my $line = $lines[$l];
      $mr = $line->{mr};
      $md = $line->{md};
      if ($mr->is_odd) {
        my @digit_list = split('', reverse($md->value));
        for my $i (0 .. $#digit_list) {
          push @{$partial[$i]}, { lin => $l, col => $c_md - $i, val => $digit_list[$i] };
        }
      }
      else {
        $action = Arithmetic::PaperAndPencil::Action->new(level => 4, label => 'MUL03'
                       , val1 => $mr->value, r1l => $l, r1c => $c_mr, r1val => $mr->value
                       , val2 => $md->value, r2l => $l, r2c => $c_md, r2val => $md->value, r2str => 1);
        push(@action, $action);
      }
      if ($mr->value eq '1') {
        my @digit_list = split('', reverse($md->value));
        for my $i(0 .. $#digit_list) {
          $final[$i] = { lin => 0+ @lines, col => $c_md - $i };
        }
        $action = Arithmetic::PaperAndPencil::Action->new(level => 2, label => 'DRA02'
                       , w1l => $l, w1c => $c_md + 1 - $md->chars
                       , w2l => $l, w2c => $c_md);
        push(@action, $action);
      }
    }
    $action[-1]->set_level(2);

    # third phase, adding
    my $result = $self->_adding(\@partial, \@final, 0, $radix);
    $action[-1]->set_level(0);

    return  Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
  }
}

method division(%param) {
  my $dividend     = $param{dividend};
  my $divisor      = $param{divisor};
  my $type         = $param{type}           // 'std';
  my $result       = $param{result}         // 'quotient';
  my $mult_and_sub = $param{mult_and_sub}   // 'combined';

  my Arithmetic::PaperAndPencil::Action $action;
  my $radix = $dividend->radix;
  if ($radix != $divisor->radix) {
    die "Dividend and divisor have different bases: {$radix} != @{[$divisor->radix]}";
  }
  if ($divisor->value eq '0') {
    die "Division by zero is impossible";
  }

  if (@action) {
    $action[-1]->set_level(0);
  }
  my $len1  = $dividend->chars;
  my $len2  = $divisor ->chars;
  my $bot   = 2;
  my $title = '';
  if    ($type eq 'std'     ) { $title = 'TIT09' ; }
  elsif ($type eq 'cheating') { $title = 'TIT10' ; }
  elsif ($type eq 'prepared') { $title = 'TIT11' ; $mult_and_sub = 'separate' }
  elsif ($type eq 'boat'    ) { $title = 'TIT12' ; }
  if ($title eq '') {
    die "Division type '$type' unknown";
  }
  if ($result ne 'quotient' && $result ne 'remainder' && $result ne 'both') {
    die "Result type '$result' unknown";
  }
  if ($mult_and_sub ne 'combined' && $mult_and_sub ne 'separate') {
    die "Mult and sub type '$mult_and_sub' unknown";
  }
  $action = Arithmetic::PaperAndPencil::Action->new(level => 9
                                                  , label => $title
                                                  , val1  => $dividend->value
                                                  , val2  => $divisor->value
                                                  , val3  => $radix
                                                  );
  push(@action, $action);

  # Divisions with obvious results
  my $zero = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '0');
  my $one  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '1');
  if ($divisor->value eq '1') {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => 'DIV05'
                  , val1 => $dividend->value, w1l => 1, w1c => 0, w1val => $dividend->value);
    push(@action, $action);
    if    ($result eq 'quotient' ) { return $dividend; }
    elsif ($result eq 'remainder') { return $zero; }
    elsif ($result eq 'both'     ) { return ($dividend, $zero); }
  }
  if ($dividend < $divisor) {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => 'DIV06', val1 => $dividend->value, val2 => $divisor->value
                                                      , w1l => 1, w1c => 0, w1val => '0');
    push(@action, $action);
    if    ($result eq 'quotient' ) { return $zero; }
    elsif ($result eq 'remainder') { return $dividend; }
    elsif ($result eq 'both'     ) { return ($zero, $dividend); }
  }

  # caching the partial products for prepared, cheating and boat divisions
  my %div_cache = (0 => $zero, 1 => $divisor);
  if ($type eq 'prepared') {
      $self->_preparation(factor => $divisor, limit => 'Z', cache => \%div_cache);
    # the actual limit will be '9' for radix 10, 'F' for radix 16, etc. But 'Z' will give the same result
  }
  if ($type eq 'cheating' || $type eq 'boat') {
    my Arithmetic::PaperAndPencil $dummy = Arithmetic::PaperAndPencil->new;
    $dummy->_preparation(factor => $divisor, limit => 'Z', cache => \%div_cache);
  }

  # setup
  my $delta = $len2 - 1; # how long we must shorten the divisor and the partial dividend to compute the quotient first candidate
  my $lin_d = 0;         # line   for the successive partial dividends
  my $col_q = $len1 + 1; # column for the successive single-digit partial quotients
  my $col_r = $len2;     # column for the successive partial dividends and remainders
  my $len_dvd1 = 1;      # length of the part of the dividend used to compute the first candidate digit
  # yes, string comparison or left-aligned comparison, to know if we need a short hook or a long hook
  if ($dividend lt $divisor) {
    $col_r++;
    $len_dvd1++;
  }

  # computation
  if ($type eq 'std' || $type eq 'cheating' || $type eq 'prepared') {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 0, w1c => $len1, w1val => $dividend->value);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DRA02', w1l => 0, w1c => $len1 + 1
                                                                                  , w2l => 0, w2c => $len1 + $len2);
    push(@action, $action);
    my Arithmetic::PaperAndPencil::Number $quotient;
    my Arithmetic::PaperAndPencil::Number $rem;
    ($quotient, $rem) = $self->_embedded_div(l_dd => 0, c_dd => $len1        , dividend => $dividend
                                           , l_dr => 0, c_dr => $len1 + $len2, divisor  => $divisor
                                           , l_qu => 1, c_qu => $len1 + 1
                                           , basic_level => 0, type => $type, mult_and_sub => $mult_and_sub, mult_cache => \%div_cache
                                           , stand_alone => 1
                                           );
    $action[-1]->set_level(0);
    if    ($result eq 'quotient' ) { return   $quotient; }
    elsif ($result eq 'remainder') { return   $rem; }
    elsif ($result eq 'both'     ) { return ( $quotient, $rem); }
  }
  if ($type eq 'boat') {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'WRI00', w1val => $dividend->value . '{'
                                                      , w1l => 0, w1c   => $len1 + 1);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'DRA02', w1l => 0, w1c => 1
                                                                                  , w2l => 0, w2c => $len1);

    push(@action, $action);

    # arrays of line numbers per column
    my @lines_below = ( 1) x ($len1 + 1);
    my @lines_above = (-1) x ($len1 + 1);
    $self->_push_below($divisor, $col_r, \@lines_below);

    $col_q++;
    my $quotient = '';
    my $rem      = '';
    my Arithmetic::PaperAndPencil::Number $part_dvr1 = $divisor->carry($delta); # single-digit divisor to compute the quotient first candidate
    my $part_dvd  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($dividend->value, 0, $col_r));

    while ($col_r <= $len1) {
      my Arithmetic::PaperAndPencil::Number $part_dvd1 = $part_dvd->carry($delta); # single-digit dividend or 2-digit dividend to compute the quotient first candidate
      my Arithmetic::PaperAndPencil::Number $theo_quo  = $part_dvd1 / $part_dvr1;  # theoretical quotient first candidate
      my Arithmetic::PaperAndPencil::Number $act_quo;                              # actual quotient first candidate
      $rem = '';
      my $label;
      if ($part_dvd < $divisor) {
        $theo_quo = $zero;
        $act_quo  = $zero;
      }
      else {
        my $dig  = max( grep { $div_cache{$_} <= $part_dvd } keys(%div_cache));
        $act_quo = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $dig);
        $label = 'DIV03';
      }
      if ($theo_quo->value eq '0') {
        # cannot flag $part_dvd and $divisor as read, because there are not on a single line.
        $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DIV01', val1 => $part_dvd->value
                                                                                      , val2 => $divisor ->value
                                                                                      , val3 => '0', w1l => 0, w1c => $col_q, w1val => '0');
        push(@action, $action);
        # striking the useless divisor
        for my $i (0 .. $len2 - 1) {
          $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'WRI00'
                                  , r1l => $lines_below[$col_r - $i] - 1, r1c => $col_r - $i, r1val => substr($divisor->value, -$i - 1, 1), r1str => 1);
          push(@action, $action);
        }
        $rem = $part_dvd->value;
        $quotient .= '0';
        ++$col_q;
        ++$col_r;
        if ($col_r <= $len1) {
          $self->_push_below($divisor, $col_r, \@lines_below);
        }
        $part_dvd = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $rem . substr($dividend->value, $col_r - 1, 1));
        next;
      }
      elsif ($theo_quo->value eq $act_quo->value) {
        # cannot flag $part_dvd and $divisor as read, because there are not on a single line.
        $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DIV01', val1 => $part_dvd1->value
                                                                                      , val2 => $part_dvr1->value
                                                                                      , val3 => $theo_quo ->value
                                                           , w1l  => 0, w1c => $col_q, w1val => $act_quo  ->value);
        push(@action, $action);
      }
      else {
        # cannot flag $part_dvd and $divisor as read, because there are not on a single line.
        $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'DIV01', val1 => $part_dvd1->value
                                                                                      , val2 => $part_dvr1->value
                                                                                      , val3 => $theo_quo ->value);
        push(@action, $action);
        $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => $label
                                 , val1 => $act_quo->value, w1l => 0, w1c => $col_q, w1val => $act_quo->value);
        push(@action, $action);
      }
      my $carry = '0';
      for my $i (0 .. $divisor->chars - 1) {
        my $divisor_digit = substr($divisor->value, - $i - 1, 1);
        my $temp  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $divisor_digit);
        $temp *= $act_quo;
        $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'MUL01'    , val3  => $temp->value
                              , r1l => 1                            , r1c   => $col_q     , r1val => $act_quo->value           , val1 => $act_quo->value
                              , r2l => $lines_below[$col_r - $i] - 1, r2c   => $col_r - $i, r2val => $divisor_digit, r2str => 1, val2 => $divisor_digit
                              );
        push(@action, $action);
        if ($carry ne '0') {
          $temp  += Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $carry);
          $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'ADD02', val1 => $carry, val2 => $temp->value);
          push(@action, $action);
        }
        my $dividend_digit = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($part_dvd->value, - $i - 1, 1));
        my Arithmetic::PaperAndPencil::Number $adjusted_dividend;
        my Arithmetic::PaperAndPencil::Number $rem_digit;
        ($adjusted_dividend, $rem_digit) = adjust_sub($dividend_digit, $temp);
        if ($i == $divisor->chars - 1) {
          $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'SUB02'
                                                          , val1  => $rem_digit->value, val2 => $adjusted_dividend->value
                           , r1l => $lines_above[$col_r - $i] + 1, r1c => $col_r - $i, r1val => $adjusted_dividend->value, r1str => 1
                           );
          push(@action, $action);
          $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'WRI04', val1  => $rem_digit->value
                                , w1l => $lines_above[$col_r - $i]--, w1c => $col_r - $i, w1val => $rem_digit->value
                                );
          push(@action, $action);
          $rem   = $rem_digit->value . $rem;
        }
        else {
          $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'SUB02'
                                                          , val1  => $rem_digit->value   , val2  => $adjusted_dividend->value
                               , r1l => $lines_above[$col_r - $i] + 1, r1c => $col_r - $i, r1val => $adjusted_dividend->value, r1str => 1
                               );
          push(@action, $action);
          my $label = 'WRI02';
          if ($adjusted_dividend->carry->value eq '0') {
            $label = 'WRI03';
          }
          $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => $label, val1  => $rem_digit->value, val2 => $adjusted_dividend->carry->value
                               , w1l => $lines_above[$col_r - $i]--, w1c => $col_r - $i, w1val => $rem_digit->value
                               );
          push(@action, $action);
          $rem   = $rem_digit->value . $rem;
          $carry = $adjusted_dividend->carry->value;
        }
      }
      $action[-1]->set_level(4);
      $quotient .= $act_quo->value;
      ++$col_q;
      ++$col_r;
      if ( $col_r <= $len1) {
        $self->_push_below($divisor, $col_r, \@lines_below);
      }
      $part_dvd = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $rem . substr($dividend->value, $col_r - 1, 1));
    }

    $action[-1]->set_level(0);
    if    ($result eq 'quotient' ) { return   Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $quotient); }
    elsif ($result eq 'remainder') { return   Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $rem); }
    elsif ($result eq 'both'     ) { return ( Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $quotient)
                                            , Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $rem)); }
  }

}

method square_root($number, %param) {
  my $mult_and_sub = $param{mult_and_sub} // 'combined';

  my Arithmetic::PaperAndPencil::Action $action;
  my $radix = $number->radix;

  $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => "TIT13", val1 => $number->value, val2 => $radix);
  push(@action, $action);

  # set-up
  my $nb_dig = ceil($number->chars / 2); # number of digits of the square root
  $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'WRI00', w1l => 0, w1c => 0, w1val => $number->value);
  push(@action, $action);
  $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'DRA01', w1l => 0, w1c => 0, w2l => 2, w2c => 0);
  push(@action, $action);
  $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'DRA02', w1l => 0, w1c => 1, w2l => 0, w2c => $nb_dig);
  push(@action, $action);
  $action = Arithmetic::PaperAndPencil::Action->new(level => 2, label => 'WRI00', w1l => 0, w1c => $nb_dig, w1val => '.' x $nb_dig);
  push(@action, $action);

  # first phase, square root proper
  my $col_first;
  my $remainder = '';
  my Arithmetic::PaperAndPencil::Number $partial_number = $number->carry(2 * ($nb_dig - 1));
  my Arithmetic::PaperAndPencil::Number $partial_root   = $partial_number->square_root;
  my $root = $partial_root->value;
  $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'SQR01', val1  => $partial_number->value, val2 => $root
                                           , r1l => 0, r1c => -2 * ($nb_dig - 1), r1val => $partial_number->value
                                           , w1l => 0, w1c => 1                 , w1val => $root
                                           );
  push(@action, $action);
  my Arithmetic::PaperAndPencil::Number $partial_square = $partial_root * $partial_root;
  if ($mult_and_sub eq 'combined') {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'MUL01', val1 => $root, val2 => $root, val3 => $partial_square->value);
    push(@action, $action);
    my ($x, $y) = adjust_sub($partial_number->unit, $partial_square);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'SUB02', val1 => $y->value
                                                                                  , val2 => $x->value);
    push(@action, $action);
    if ($x->carry->value eq '0') {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI03', val1  => $y->value
                                          , w1l   => 1, w1c   => -2 * ($nb_dig - 1) , w1val => $y->value
                                          );
      push(@action, $action);
      $remainder = $y->value;
    }
    else {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI02', val1  => $y->value, val2 => $x->carry->value
                                          , w1l   => 1, w1c   => -2 * ($nb_dig - 1) , w1val => $y->value
                                          );
      push(@action, $action);
      my ($z, $t) = adjust_sub($partial_number->carry, $x->carry);
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'SUB01'
                               , val1 => $x->carry->value         , val2  => $t->value, val3 => $z->value
                               , w1l => 1, w1c => -2 * $nb_dig + 1, w1val => $t->value);
      push(@action, $action);
      $remainder = $t->value . $y->value;
    }
  }
  else {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'MUL01'
                           , val1 => $root, val2 => $root       , val3  => $partial_square->value
                           , w1l => 1, w1c => -2 * ($nb_dig - 1), w1val => $partial_square->value);
    push(@action, $action);
    $remainder = $self->_embedded_sub(basic_level => 0, l_hi => 0, c_hi => -2 * ($nb_dig - 1), high => $partial_number
                                                      , l_lo => 1, c_lo => -2 * ($nb_dig - 1), low  => $partial_square
                                                      , l_re => 2, c_re => -2 * ($nb_dig - 1));
  }
  my Arithmetic::PaperAndPencil::Number $divisor = $partial_root + $partial_root;
  $col_first = $divisor->chars;
  $action = Arithmetic::PaperAndPencil::Action->new(level => 3, label => 'ADD01'
                  , val1  => $partial_root->value , val2  => $partial_root->value, val3 => $divisor->value
                  , r1l  => 0, r1c   => 1         , r1val => $partial_root->value
                  , w1l  => 1, w1c   => $col_first, w1val => $divisor->value
                );
  push(@action, $action);

  my $zero = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => 0);
  my $one  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => 1);
  my Arithmetic::PaperAndPencil::Number $divisor1;

  # next phase, division
  my $bot      = 2; # bottom line number of the vertical line
  my $line_rem = 1; # line number of the partial remainder or partial dividend
  my $line_div = 1; # line number of the divisor
  if ($mult_and_sub eq 'separate') {
    $line_rem = 2;
  }
  for my $i (1 .. $nb_dig - 1) {
    my $pos = 2 * ($nb_dig - $i);
    my $two_digits = substr($number->value, - $pos, 2);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 3        , label => 'DIV04'   , val1  => $two_digits
                                                     , r1l  => 0        , r1c   => 2 - $pos  , r1val => $two_digits
                                                     , w1l  => $line_rem, w1c   => 2 - $pos  , w1val => $two_digits
                                                     );
    push(@action, $action);
    $remainder .= $two_digits;

    $partial_number = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $remainder);
    my Arithmetic::PaperAndPencil::Number $part_dvr1 = $divisor->carry($divisor->chars - 1); # single-digit divisor to compute the quotient first candidate
    my Arithmetic::PaperAndPencil::Number $part_dvd1 = $partial_number->carry($i + $col_first - 1); # single-digit dividend or 2-digit dividend to compute the quotient first candidate
    my Arithmetic::PaperAndPencil::Number $theo_quo = $part_dvd1 / $part_dvr1; # theoretical quotient first candidate
    my Arithmetic::PaperAndPencil::Number $act_quo;                            # actual quotient first candidate and then all successive candidates
    my $label;
    if ($partial_number <= $divisor) {
      $theo_quo = $zero;
      $act_quo  = $zero;
      $divisor1 = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $divisor->value . '0');
    }
    elsif ($theo_quo->chars == 2) {
      $act_quo = max_unit($radix);
      $label   = 'DIV02';
    }
    else {
      $act_quo = $theo_quo;
    }
    my $too_much = 1; # we must loop with the next lower candidate
    if ($theo_quo->value eq '0') {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DIV01'
                                         , val1 => $part_dvd1->value, r1l => $line_rem, r1c => - $pos         , r1val => $part_dvd1->value
                                         , val2 => $part_dvr1->value, r2l => $line_div, r2c => 0              , r2val => $part_dvr1->value
                                         , val3 => '0'              , w1l => $line_div, w1c => $i + $col_first, w1val => '0');
      push(@action, $action);
      $too_much = 0; # no need to loop on candidate values, no need to execute the mult_and_sub routine
      $remainder = $partial_number->value;
    }
    elsif ($theo_quo->value eq $act_quo->value) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DIV01'
                                         , val1 => $part_dvd1->value, r1l => $line_rem     , r1c => - $pos         , r1val => $part_dvd1->value
                                         , val2 => $part_dvr1->value, r2l => $line_div     , r2c => 0              , r2val => $part_dvr1->value
                                         , val3 => $theo_quo->value , w1l => $line_div     , w1c => $i + $col_first, w1val => $act_quo  ->value
                                                                    , w2l  => $line_div + 1, w2c => $i + $col_first, w2val => $act_quo  ->value);
      push(@action, $action);
    }
    else {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'DIV01'
                                         , val1 => $part_dvd1->value, val2 => $part_dvr1->value, val3  => $theo_quo ->value
                                         , r1l  => $line_rem        , r1c  => - $pos           , r1val => $part_dvd1->value
                                         , r2l  => $line_div        , r2c  => 0                , r2val => $part_dvr1->value);
      push(@action, $action);
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => $label
                               , val1 => $act_quo->value, w1l => $line_div, w1c  => $i + $col_first, w1val => $act_quo->value
                               , w2l  => $line_div + 1  , w2c => $i + $col_first                   , w2val => $act_quo->value);
      push(@action, $action);
    }
    my $rem;
    my $l_re;
    while ($too_much) {
      if ($mult_and_sub eq 'separate') {
        $l_re = $line_rem + 2;
      }
      else {
        $l_re = $line_rem + 1;
      }
      if ($bot < $l_re) {
        $bot = $l_re;
        $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DRA01', w1l => 0, w1c => 0, w2l => $bot, w2c => 0);
        push(@action, $action);
      }
      $divisor1 = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $divisor->value . $act_quo->value);
      ($too_much, $rem) = $self->_mult_and_sub(l_dd => $line_rem    , c_dd => 2 - 2 * ($nb_dig - $i), dividend     => $partial_number
                                             , l_dr => $line_div    , c_dr => $i + $col_first       , divisor      => $divisor1
                                             , l_qu => $line_div + 1, c_qu => $i + $col_first       , quotient     => $act_quo
                                             , l_re => $l_re        , c_re => 2 - 2 * ($nb_dig - $i), basic_level  => 0
                                             , l_pr => $line_rem + 1, c_pr => 2 - 2 * ($nb_dig - $i), mult_and_sub => $mult_and_sub);
      if ($too_much) {
        $action[-1]->set_level(4);
        $act_quo -= $one;
        $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'ERA01'
                                                        , w1l   => $line_rem + 1, w1c => 0
                                                        , w2l   => $line_rem + 1, w2c => 1 - $number->chars);
        push(@action, $action);
        $action = Arithmetic::PaperAndPencil::Action->new(level => 4, label => 'DIV02', val1  => $act_quo->value
                                        , w1l => $line_div    , w1c => $i + $col_first, w1val => $act_quo->value
                                        , w2l => $line_div + 1, w2c => $i + $col_first, w2val => $act_quo->value);
        push(@action, $action);
      }
    }
    $action[-1]->set_level(4);

    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI04', val1  => $act_quo->value
                                                    , w1l   => 0, w1c   => $i + 1 , w1val => $act_quo->value);
    push(@action, $action);
    $root .= $act_quo->value;

    $divisor = $divisor1 + $act_quo;
    if ($act_quo->value eq '0') {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 3, label => 'ERA01'
                                  , w1l => $line_div + 1, w1c => $i + $col_first
                                  , w2l => $line_div + 1, w2c => $i + $col_first);
      push(@action, $action);
    }
    elsif ($i < $nb_dig - 1) {
      $remainder = $rem;
      $line_rem = $l_re;
      if ($bot < $line_div + 3) {
        $bot = $line_div + 3;
      }
      $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'DRA01', w1l => 0, w1c => 0, w2l => $bot, w2c => 0);
      push(@action, $action);
      $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'DRA02'
                                                      , w1l   => $line_div + 1, w1c => 1
                                                      , w2l   => $line_div + 1, w2c => $divisor->chars);
      push(@action, $action);
      $action = Arithmetic::PaperAndPencil::Action->new(level => 3, label => 'ADD01'
                                  , r1l => $line_div    , r1c => $i + $col_first, r1val => $divisor1->value, val1 => $divisor1->value
                                  , r2l => $line_div + 1, r2c => $i + $col_first, r2val => $act_quo ->value, val2 => $act_quo ->value
                                  , w1l => $line_div + 2, w1c => $i + $col_first, w1val => $divisor ->value, val3 => $divisor ->value);
      push(@action, $action);
      $line_div += 2;
    }
  }

  $action[-1]->set_level(0);
  return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $root);
}

method conversion(%param) {
  my $number       = $param{number};
  my $radix        = $param{radix};
  my $nb_op        = $param{nb_op}        // 0;
  my $type         = $param{type}         // 'mult';
  my $div_type     = $param{div_type}     // 'std';
  my $mult_and_sub = $param{mult_and_sub} // 'combined';
  if ($radix < 2 or $radix > 36) {
    die "Radix should be between 2 and 36, instead of $radix";
  }
  my $title = '';
  if    ($type eq 'mult'  ) { $title = 'TIT14' ; }
  elsif ($type eq 'Horner') { $title = 'TIT14' ; }
  elsif ($type eq 'div'   ) { $title = 'TIT16' ; }
  else                      { die "Conversion type '$type' unknown, should be 'mult', 'Horner' or 'div'"; }
  if ($type eq 'div' and $div_type ne 'std'
                     and $div_type ne 'cheating'
                     and $div_type ne 'prepared') {
    die "Division type '$div_type' unknown, should be 'std', 'cheating' or 'prepared'";
  }
  if ($type eq 'div' and $mult_and_sub ne 'combined'
                     and $mult_and_sub ne 'separate') {
    die "Mult and sub type '$mult_and_sub' unknown, should be 'combined' or 'separate'";
  }
  if ($type eq 'div' and $div_type eq 'std') {
    $mult_and_sub = 'combined';
  }
  if ($type eq 'div' and $div_type eq 'prepared') {
    $mult_and_sub = 'separate';
  }
  my Arithmetic::PaperAndPencil::Action $action;
  my $old_radix = $number->radix;

  $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => $title, val1 => $number->value, val2 => $old_radix, val3 => $radix);
  push(@action, $action);

  if ($radix == $old_radix or ($number->chars == 1 && $old_radix <= $radix)) {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => "CNV01", val1 => $number->value, val2 => $old_radix, val3 => $radix);
    push(@action, $action);
    return $number;
  }
  my %conv_cache;
  my Arithmetic::PaperAndPencil::Number $new_radix;
  my $zero  = Arithmetic::PaperAndPencil::Number->new(radix => $old_radix, value => '0');
  my %mult_cache;
  if ($type eq 'mult' || $type eq 'Horner') {
    $self->_prep_conv($old_radix, $radix, \%conv_cache, basic_level => 2);
  }
  else {
    %mult_cache = (0 => $zero, 1 => $new_radix);
    my %tmp_cache;
    $self->_prep_conv($radix, $old_radix, \%tmp_cache, basic_level => 2);
    $new_radix = $tmp_cache{10};
    for my $new (keys %tmp_cache) {
      my $old = $tmp_cache{$new};
      $conv_cache{$old->value} = $new;
    }
    if ($div_type eq 'prepared') {
      my %tmp_cache;
      $self->_preparation(factor => $new_radix, limit => 'Z', cache => \%mult_cache, basic_level => 2);
      $action[-2]->set_level(1); # * - 2 to update the action **before** action NXP01
      # the actual limit will be '9' for radix 10, 'F' for radix 16, etc. But 'Z' will give the same result
    }
    if ($div_type eq 'cheating') {
      my $dummy = Arithmetic::PaperAndPencil->new;
      $dummy->_preparation(factor => $new_radix, limit => 'Z', cache => \%mult_cache);
    }
  }

  my Arithmetic::PaperAndPencil::Number $result;
  if ($type eq 'mult' || $type eq 'Horner') {
    my $old_digit = substr($number->value, 0,1);
    $result   = $conv_cache{$old_digit};
    my $line  = 1;
    my $op    = 0;
    my $width = $conv_cache{10}->chars;
    $action = Arithmetic::PaperAndPencil::Action->new(level => 3, label => "CNV02", val1 => $old_digit, val2  => $result->value
                                                                , w1l   => $line  , w1c  => 0         , w1val => $result->value);
    push(@action, $action);
    for my $op1 (1 .. $number->chars - 1) {
      my $old_digit = substr($number->value, $op1, 1);
      # multiplication
      my $pos_sign =  max($conv_cache{10}->chars, $result->chars);
      ++$line;
      $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'WRI00'
                            , w1l => $line, w1c => 0              , w1val => $conv_cache{10}->value
                            , w2l => $line, w2c => - $pos_sign - 1, w2val => '×');
      push(@action, $action);
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DRA02', w1l => $line, w1c => 0
                                                                                    , w2l => $line, w2c => - $width);
      push(@action, $action);
      if ($conv_cache{10}->chars == 1) {
        $result = $self->_simple_mult(basic_level => 2
                                , l_md => $line - 1, c_md => 0, multiplicand => $result
                                , l_mr => $line    , c_mr => 0, multiplier   => $conv_cache{10}
                                , l_pd => $line + 1, c_pd => 0);
        $line++;
      }
      else {
        my %dummy_cache;
        $result = $self->_adv_mult(basic_level => 2
                                , l_md => $line - 1, c_md => 0, multiplicand => $result
                                , l_mr => $line    , c_mr => 0, multiplier   => $conv_cache{10}
                                , l_pd => $line + 1, c_pd => 0, cache        => \%dummy_cache);
        $line += $conv_cache{10}->chars + 1;
      }
      if ($width <= $result->chars) {
        $width = $result->chars;
      }
      # addition
      my $added = $conv_cache{$old_digit};
      if ($added->value eq '0') {
        $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => "CNV02", val1 => '0', val2  => '0');
        push(@action, $action);
      }
      else {
        $pos_sign = max( $conv_cache{10}->chars, $width);
        ++$line;
        $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => "CNV02"
                             , val1 => $old_digit                   , val2  => $added->value
                             , w1l  => $line, w1c => 0              , w1val => $added->value
                             , w2l  => $line, w2c => - $pos_sign - 1, w2val => '+');
        push(@action, $action);
        $action = Arithmetic::PaperAndPencil::Action->new(level => 5    , label => 'DRA02'
                                                         , w1l  => $line, w1c   => 0, w2l => $line, w2c => - $width);
        push(@action, $action);
        my @added;
        my @total;
        my @digit_list = reverse(split('', $result->value));
        for my $i (0 .. $#digit_list) {
          my $digit = $digit_list[$i];
          $added[$i][0] = { lin => $line - 1, col => - $i, val => $digit};
          $total[$i]    = { lin => $line + 1, col => - $i};
        }
        @digit_list = reverse(split('', $added->value));
        for my $i (0 .. $#digit_list) {
          my $digit = $digit_list[$i];
          $added[$i][1] = { lin => $line    , col => - $i, val => $digit};
          $total[$i]    = { lin => $line + 1, col => - $i};
        }
        $result = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $self->_adding(\@added, \@total, 2, $radix));
        $line++;
      }
      $action[-1]->set_level(3);
      # next step
      $op++;
      if ($op == $nb_op && $op1 != $number->chars - 1) {
        $action[-1]->set_level(1);
        $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'NXP01');
        push(@action, $action);
        $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'CNV03'
                                                        , val1  => $result->value, val2  => substr($number->value, $op1 + 1)
                                                        , w1l   => 1, w1c => 0   , w1val => $result->value);
        push(@action, $action);
        $op = 0;
        $line = 1;
      }
      if ($width <= $result->chars) {
        $width = $result->chars;
      }
    }
  }
  else {
    my $op   = 0;
    my $l_dd = 1;
    my $c_dd = 0;
    my $res  = '';
    $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'WRI00', w1l => $l_dd, w1c => $c_dd, w1val => $number->value);
    push(@action, $action);
    my Arithmetic::PaperAndPencil::Number $x;
    my Arithmetic::PaperAndPencil::Number $y;
    while ($new_radix <= $number) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'DRA02'
                                                      , w1l => $l_dd, w1c => $c_dd + 1
                                                      , w2l => $l_dd, w2c => $c_dd + $new_radix->chars);
      push(@action, $action);
      ($x, $y) = $self->_embedded_div(l_dd => $l_dd    , c_dd => $c_dd                    , dividend => $number
                                    , l_dr => $l_dd    , c_dr => $c_dd + $new_radix->chars, divisor  => $new_radix
                                    , l_qu => $l_dd + 1, c_qu => $c_dd + 1
                                    , basic_level => 3, type => $div_type, mult_and_sub => $mult_and_sub
                                    , mult_cache => \%mult_cache);
      $action[-1]->set_level(3);
      $res = $conv_cache{$y->value} . $res;
      $number = $x;
      $op++;
      $l_dd++;
      $c_dd += $number->chars;
      my $rewrite_dd = '';
      if ($op == $nb_op && $new_radix <= $number) {
        $action[-1]->set_level(1);
        $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'NXP01');
        push(@action, $action);
        $op   = 0;
        $l_dd = 1;
        $c_dd = 0;
        $rewrite_dd = $number->value;
      }
      if ($new_radix <= $number) {
        $action = Arithmetic::PaperAndPencil::Action->new(level => 9    , label => 'CNV03'
                                                        , val1  => $res , val2  => $number->value
                                                        , w1l   => $l_dd, w1c   => $c_dd, w1val => $rewrite_dd);
        push(@action, $action);
      }
    }
    $res = $conv_cache{$number->value} . $res;
    $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => 'CNV03', val1 => $res, val2 => '0');
    push(@action, $action);
    $result = Arithmetic::PaperAndPencil::Number->new(value => $res, radix => $radix);
  }

  $action[-1]->set_level(0);
  return $result;
}

method gcd(%param) {
  my $first        = $param{first};
  my $second       = $param{second};
  my $div_type     = $param{div_type}     // 'std';

  my Arithmetic::PaperAndPencil::Action $action;
  my $radix = $first->radix;
  if ($second->radix != $radix) {
    die "The two numbers have different bases: $radix != {$second->radix}";
  }
  if (@action) {
    $action[-1]->set_level(0);
  }
  if ($first < $second) {
    ($first, $second) = ($second, $first);
  }
  my $title = '';
  if    ($div_type eq 'std'     ) { $title = 'TIT17' ; }
  elsif ($div_type eq 'cheating') { $title = 'TIT18' ; }
  else  {
    die "Division type '$div_type' unknown";
  }
  $action = Arithmetic::PaperAndPencil::Action->new(level => 9
                                                  , label => $title
                                                  , val1  => $first->value
                                                  , val2  => $second->value
                                                  , val3  => $radix
                                                  );
  push(@action, $action);
  my Arithmetic::PaperAndPencil::Number $quo;
  my Arithmetic::PaperAndPencil::Number $rem;
  my %mult_cache;

  # set-up
  my $len2 = $second->chars;
  my $l_dd = 0;
  my $c_dd = 0;
  my $l_dr = 0;
  my $c_dr = $len2;
  my $l_qu = -1;
  my $c_qu =  1;
  $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'WRI00', w1l => $l_dd, w1c => $c_dd, w1val => $first->value);
  push(@action, $action);

  # computation
  while ($second->value ne '0') {
    if ($div_type eq 'cheating') {
      my Arithmetic::PaperAndPencil $dummy = Arithmetic::PaperAndPencil->new;
      $dummy->_preparation(factor => $second, limit => 'Z', cache => \%mult_cache);
    }
    $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'DRA02', w1l => $l_qu, w1c => $c_dr - $len2 + 1
                                                                                  , w2l => $l_qu, w2c => $c_dr);
    push(@action, $action);
    ($quo, $rem) = $self->_embedded_div(l_dd => $l_dd, c_dd => $c_dd, dividend => $first
                                      , l_dr => $l_dr, c_dr => $c_dr, divisor  => $second
                                      , l_qu => $l_qu, c_qu => $c_qu
                                      , basic_level => 3, type => $div_type, mult_and_sub => 'combined'
                                      , mult_cache => \%mult_cache);
    $action[-1]->set_level(3);
    $first  = $second;
    $second = $rem;
    $len2   = $rem->chars;
    $c_dd   = $c_dr;
    $c_qu  += max($quo->chars, $first->chars);
    $c_dr   = $c_qu + $len2 - 1;
  }
  $action[-1]->set_level(0);
  return $first;
}

method _adding($digits, $pos, $basic_level, $radix, $striking = 0) {
  my @digits = @$digits;
  my @pos    = @$pos;
  my $action;
  my $sum;
  my $result = '';
  my $carry  = 0;

  for my $i (0 .. $#digits) {
    my $l = $digits[$i];
    my @l = grep { $_ } @$l; # removing empty entries
    if (0+ @l == 0) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3, label => 'WRI04' , val1  => $carry
                                                       , w1l  => $pos[$i]{lin}, w1c => $pos[$i]{col}, w1val => $carry
                                                       );
      push(@action, $action);
      $result = $carry . $result;
    }
    elsif (0+ @l == 1 && $carry eq '0') {
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3
                          , label => 'WRI04'                          , val1  => $l[0]{val}
                          , r1l => $l[ 0  ]{lin}, r1c => $l[ 0  ]{col}, r1val => $l[0]{val}, r1str => $striking
                          , w1l => $pos[$i]{lin}, w1c => $pos[$i]{col}, w1val => $l[0]{val}
                          );
      push(@action, $action);
      $result = $l[0]{val} . $result;
    }
    else {
      my $first;
      $sum = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $l[0]{val});
      if ($carry eq '0') {
        $sum   += Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $l[1]{val});
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6
                            , label => 'ADD01' , val1  => $l[0]{val}, val2  => $l[1]{val}, val3  => $sum->value
                            , r1l => $l[0]{lin}, r1c   => $l[0]{col}, r1val => $l[0]{val}, r1str => $striking
                            , r2l => $l[1]{lin}, r2c   => $l[1]{col}, r2val => $l[1]{val}, r2str => $striking
                            );
        $first = 2;
      }
      else {
        $sum   += Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $carry);
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6
                            , label => 'ADD01'   , val1 => $l[0]{val}, val2  => $carry    , val3  => $sum->value
                            , r1l   => $l[0]{lin}, r1c  => $l[0]{col}, r1val => $l[0]{val}, r1str => $striking
                            );
        $first = 1;
      }
      push(@action, $action);
      for my $j ($first .. $#l) {
        $sum   += Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $l[$j]{val});
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6
                          , label => 'ADD02'    , val1 => $l[$j]{val}, val2  => $sum->value
                          , r1l   => $l[$j]{lin}, r1c  => $l[$j]{col}, r1val => $l[$j]{val}, r1str => $striking
                          );
        push(@action, $action);
      }
      if ($i == @digits - 1) {
        my $last_action = pop(@action);
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 2
                          , label => $last_action->label, val1  => $last_action->val1, val2   => $last_action->val2 , val3  => $last_action->val3
                          , r1l   => $last_action->r1l  , r1c   => $last_action->r1c , r1val  => $last_action->r1val, r1str => $striking
                          , r2l   => $last_action->r2l  , r2c   => $last_action->r2c , r2val  => $last_action->r2val, r2str => $striking
                          , w1l   => $pos[$i]{lin}      , w1c   => $pos[$i]{col}     ,  w1val => $sum->value
                          );
        push(@action, $action);
        $result = $sum->value . $result;
      }
      else {
        my $digit = $sum->unit->value;
        $carry    = $sum->carry->value;
        my $lin;
        my $col;
        my $code = 'WRI02';
        if ($carry eq '0') {
          $code = 'WRI03';
        }
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3
                            , label => $code        , val1 => $digit       , val2 => $carry
                            , w1l   => $pos[$i]{lin}, w1c  => $pos[$i]{col}, w1val => $digit
                             );
        push(@action, $action);
        $result = $digit . $result;
      }
    }
  }
  return $result;
}

method _embedded_sub(%param) {
  my $basic_level = $param{basic_level};
  my $l_hi        = $param{l_hi};
  my $c_hi        = $param{c_hi};
  my $high        = $param{high};
  my $l_lo        = $param{l_lo};
  my $c_lo        = $param{c_lo};
  my $low         = $param{low};
  my $l_re        = $param{l_re};
  my $c_re        = $param{c_re};

  my Arithmetic::PaperAndPencil::Action $action;
  my $radix = $high->radix;
  my $leng  = $high->chars;
  # set-up
  $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 2, label => 'DRA02', w1l => $l_lo, w1c => $c_lo - $leng + 1
                                                            , w2l => $l_lo, w2c => $c_lo);
  push(@action, $action);

  my $carry  = '0';
  my $result = '';
  my $label;

  # First subphase, looping over the low number's digits
  for my $i (0 .. $low->chars - 1) {
    my $high1 = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($high->value, $leng      - $i - 1, 1));
    my $low1  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($low->value, $low->chars - $i - 1, 1));
    my $adj1;
    my $res1;
    my $low2;
    if ($carry eq '0') {
      ($adj1, $res1) = adjust_sub($high1, $low1);
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'SUB01', val1  => $low1->value, val2 => $res1->value, val3 => $adj1->value
                   , r1l => $l_hi, r1c => $c_hi - $i, r1val => $high1->value
                   , r2l => $l_lo, r2c => $c_lo - $i, r2val => $low1->value
                   );
    }
    else {
      $low2 = $low1 + Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $carry);
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'ADD01'   , val1  => $low1->value, val2 => $carry, val3 => $low2->value
                   , r1l => $l_lo, r1c => $c_lo - $i, r1val => $low1->value
                   );
      push(@action, $action);
      ($adj1, $res1) = adjust_sub($high1, $low2);
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'SUB02'   , val1  => $res1->value, val2 => $adj1->value
                   , r1l => $l_hi, r1c => $c_hi - $i, r1val => $high1->value
                   );
    }
    push(@action, $action);
    $result = $res1->unit->value . $result;
    $carry  = $adj1->carry->value;
    if ($carry eq '0') {
      $label = 'WRI03';
    }
    else {
      $label = 'WRI02';
    }
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3, label => $label    , val1  => $res1->unit->value, val2 => $carry
                                                    , w1l   => $l_re           , w1c   => $c_re - $i, w1val => $res1->unit->value
                                                    );
    push(@action, $action);
  }
  # Second subphase, dealing with the carry
  my $pos = $low->chars;
  while ($carry ne '0') {
    my $high1   = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($high->value, $leng - $pos - 1, 1));
    my $carry1  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $carry);
    my $adj1;
    my $res1;
    ($adj1, $res1) = adjust_sub($high1, $carry1);
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'SUB01', val1  => $carry, val2 => $res1->value, val3 => $adj1->value
                 , r1l => $l_hi, r1c => $c_hi - $pos, r1val => $high1->value
                 );
    push(@action, $action);
    $result = $res1->unit->value . $result;
    $carry  = $adj1->carry->value;
    if ($carry eq '0') {
      $label = 'WRI03';
    }
    else {
      $label = 'WRI02';
    }
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3, label => $label      , val1  => $res1->unit->value, val2 => $carry
                                                    , w1l   => $l_re           , w1c   => $c_re - $pos, w1val => $res1->unit->value
                                                    );
    # no need to write the final zero if there is no carry
    if ($res1->unit->value ne '0' or $carry ne '0' or $pos < $leng - 1) {
      push(@action, $action);
    }
    $pos++;
  }
  # Third subphase, a single copy
  if ($pos < $leng) {
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level, label => 'WRI05'     , val1  => substr($high->value, 0, $leng - $pos)
                                                      , w1l   => $l_re       , w1c   => $c_re - $pos, w1val => substr($high->value, 0, $leng - $pos)
                                                    );
    push(@action, $action);
    $result = substr($high->value, 0, $leng - $pos) . $result;
  }

  return $result;
}

method _preparation(%param) {
  my $factor      = $param{factor};
  my $limit       = $param{limit};
  my $cache       = $param{cache};
  my $basic_level = $param{basic_level} // 0;

  my Arithmetic::PaperAndPencil::Action $action;
  my $one = Arithmetic::PaperAndPencil::Number->new(radix => $factor->radix, value => '1');
  my $radix = $factor->radix;
  my $col   = $factor->chars + 3;

  # cache first entry
  $cache->{1} = $factor;
  $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3, label => 'WRI00'
                                                    , w1l => 0, w1c => 0   , w1val => '1'
                                                    , w2l => 0, w2c => $col, w2val => $factor->value);
  push(@action, $action);

  my @digits; # storing the numbers' digits
  my @total;  # storing the total's digit positions
  my @digit_list = reverse(split('', $factor->value));
  for my $i (0 .. $#digit_list) {
    my $ch = $digit_list[$i];
    $digits[$i][0] = { lin => 0, col => $col - $i, val => $ch };
    $total[ $i]    = { lin => 1, col => $col - $i };
  }
  # in case the last partial products are longer than the factor
  $total[$factor->chars] = { lin => 1, col => $col - $factor->chars };

  my $result = $factor->value;
  my $lin    = 1;
  my Arithmetic::PaperAndPencil::Number $mul = $one + $one; # starting from 2; yet stopping immediately with a 2-digit $mul if $radix == 2
  while ($mul->value le $limit && $mul->chars == 1) {
    # displaying the line number
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 9, label => 'WRI00'
                                                    , w1l   => $lin,   w1c => 0, w1val => $mul->value);
    push(@action, $action);

    # computation
    my @digit_list = reverse(split('', $result));
    for my $i (0 .. $#digit_list) {
      my $ch = $digit_list[$i];
      $digits[$i][1]  = { lin => $lin - 1, col => $col - $i, val => $ch };
      $total[$i]{lin} = $lin;
    }
    $result = $self->_adding(\@digits, \@total, $basic_level + 1, $radix);
    $action[-1]->set_level($basic_level + 3);

    # storing into cache
    $cache->{$mul->value} = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);

    # loop iteration
    $lin++;
    $mul += $one;
  }

  $action = Arithmetic::PaperAndPencil::Action->new(level => 1, label => 'NXP01');
  push(@action, $action);
}

method _prep_conv($old_radix, $new_radix, $cache, %param) {
  my $basic_level = $param{basic_level} // 0;

  my Arithmetic::PaperAndPencil::Action $action;
  my $old_number = Arithmetic::PaperAndPencil::Number->new(value => '0', radix => $old_radix);
  my $new_number = Arithmetic::PaperAndPencil::Number->new(value => '0', radix => $new_radix);
  my $old_one    = Arithmetic::PaperAndPencil::Number->new(value => '1', radix => $old_radix);
  my $new_one    = Arithmetic::PaperAndPencil::Number->new(value => '1', radix => $new_radix);
  my $line = 1;
  while ($old_number->value ne '11') {
    $cache->{$old_number->value} = $new_number;
    if ($new_number->chars > 1) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'WRI00'
                             , w1l => $line, w1c =>  2, w1val => $old_number->value
                             , w2l => $line, w2c => 10, w2val => $new_number->value);
      push(@action, $action);
      $line++;
    }
    $old_number += $old_one;
    $new_number += $new_one;
  }
  if ($line != 1) {
    $action[-1]->set_level(1);
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 9, label => 'NXP01');
    push(@action, $action);
  }
}

method _adv_mult(%param) {
  my $basic_level  = $param{basic_level};
  my $type         = $param{type} // 'std';
  my $l_md         = $param{l_md}; # coordinates of the multiplicand
  my $c_md         = $param{c_md};
  my $l_mr         = $param{l_mr}; # coordinates of the multiplier
  my $c_mr         = $param{c_mr};
  my $l_pd         = $param{l_pd}; # coordinates of the product
  my $c_pd         = $param{c_pd};
  my %cache        = %{$param{cache}};
  my $multiplicand = $param{multiplicand};
  my $multiplier   = $param{multiplier};

  my Arithmetic::PaperAndPencil::Action $action;
  my $result     = '';
  my $radix      = $multiplier->radix;
  my $line       = $l_pd;
  my $pos        = $multiplier->chars - 1;
  my $shift      = 0;
  my $shift_char = '0';
  my @partial; # storing the partial products' digits
  my @final  ; # storing the final product's digit positions

  while ($pos >= 0) {
    # shifting the current simple multiplication because of embedded zeroes
    if (substr($multiplier->value, 0, $pos + 1) =~ /(0+)$/) {
      $shift += length($1);
      $pos   -= length($1);
    }
    if ($shift != 0) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5   , label => 'WRI00'
                                                      , w1l   => $line, w1c => $c_pd, w1val => $shift_char x $shift);
      push(@action, $action);
      if ($shift_char eq '0') {
        for my $i (0 .. $shift - 1) {
          push @{$partial[$i]}, { lin => $line, col => $c_pd - $i, val => '0'};
        }
      }
    }
    # computing the simple multiplication
    my $mul = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplier->value, $pos, 1));
    my Arithmetic::PaperAndPencil::Number $pdt;
    if ($type ne 'std' && defined $cache{$mul->value}) {
      $pdt = $cache{$mul->value};
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3, label => 'WRI05', val1 => $pdt->value
                                                             , w1l => $line, w1c => $c_pd - $shift, w1val => $pdt->value
                                                             );
      push(@action, $action);

    }
    else {
      $pdt = $self->_simple_mult(basic_level => $basic_level
                            , l_md => $l_md, c_md => $c_md         , multiplicand => $multiplicand
                            , l_mr => $l_mr, c_mr => $c_mr - $shift, multiplier   => $mul
                            , l_pd => $line, c_pd => $c_pd - $shift);
      # filling the cache
      $cache{$mul->value} = $pdt;
    }
    # storing the digits of $pdt
    my @digit_list = reverse(split('', $pdt->value));
    for my $i (0 .. $#digit_list) {
      my $x = $digit_list[$i];
      push @{$partial[$i + $shift]}, { lin => $line, col => $c_pd - $shift - $i, val => $x };
    }
    # shifting the next simple multiplication
    $pos--;
    $shift++;
    $shift_char = '.';
    $line++;
  }
  $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 2, label => 'DRA02'
               , w1l => $line - 1, w1c => $c_pd + 1 - $multiplicand->chars - $multiplier->chars
               , w2l => $line - 1, w2c => $c_pd);
  push(@action, $action);
  for my $i (0 .. $multiplicand->chars + $multiplier->chars) {
    $final[$i] = { lin => $line, col => $c_pd - $i };
  }
  $result = $self->_adding(\@partial, \@final, $basic_level, $radix);
  return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
}

method _simple_mult(%param) {
  my $basic_level  = $param{basic_level};
  my $l_md         = $param{l_md}; # coordinates of the multiplicand
  my $c_md         = $param{c_md};
  my $l_mr         = $param{l_mr}; # coordinates of the multiplier (single digit)
  my $c_mr         = $param{c_mr};
  my $l_pd         = $param{l_pd}; # coordinates of the product
  my $c_pd         = $param{c_pd};
  my $multiplicand = $param{multiplicand};
  my $multiplier   = $param{multiplier};
  my $result = '';
  my $radix  = $multiplier->radix;
  my $carry  = '0';
  my $len1   = $multiplicand->chars;
  my Arithmetic::PaperAndPencil::Action $action;
  my Arithmetic::PaperAndPencil::Number $pdt;
  for my $i (0 .. $len1 - 1) {
    my $mul = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplicand->value, $len1 - $i - 1, 1));
    $pdt = $multiplier * $mul;
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'MUL01'           , val3 => $pdt->value
                                              , r1l => $l_mr, r1c => $c_mr     , r1val => $multiplier->value, val1 => $multiplier->value
                                              , r2l => $l_md, r2c => $c_md - $i, r2val => $mul->value       , val2 => $mul->value
                                              );
    push(@action, $action);
    if ($carry ne '0') {
      $pdt += Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $carry);
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'ADD02', val1 => $carry, val2 => $pdt->value);
      push(@action, $action);
    }
    my $unit  = $pdt->unit->value;
    $carry    = $pdt->carry->value;
    my $code = 'WRI02';
    if ($carry eq '0') {
      $code = 'WRI03';
    }
    if ($i < $len1 - 1) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => $code, val1 => $unit, val2 => $carry
                   , w1l => $l_pd, w1c => $c_pd - $i, w1val => $unit
                     );
      push(@action, $action);
      $result = $unit . $result;
    }
  }
  $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3, label => 'WRI00'
               , w1l => $l_pd, w1c => $c_pd + 1 - $len1, w1val => $pdt->value
                 );
  push(@action, $action);
  return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $pdt->value . $result);
}

method _push_below($number, $col, $lines_below) {
  my Arithmetic::PaperAndPencil::Action $action;
  for my $digit (split('', reverse($number->value))) {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'WRI00', w1l => $lines_below->[$col]++, w1c => $col, w1val => $digit);
    push(@action, $action);
    $col--;
  }
  $action[- 1]->set_level(4);
}

method _push_above($number, $col, $lines_above, $addition, $bias) {
  my Arithmetic::PaperAndPencil::Action $action;
  for my $digit (split('', reverse($number->value))) {
    $addition->[$bias - $col][- $lines_above->[$col] ] = { lin => $lines_above->[$col], col => $col, val => $digit };
    $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'WRI00', w1l => $lines_above->[$col]--, w1c => $col, w1val => $digit);
    push(@action, $action);
    $col--;
  }
}

method _add_above($number, $col, $lines_above, $result) {
  my Arithmetic::PaperAndPencil::Action $action;
  my $radix = $number->radix;
  while ($number->value ne '0') {
    if ($lines_above->[$col] == -1) {
      my $code = 'WRI02';
      if ($number->chars == 1) {
        $code = 'WRI04';
      }
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => $code,  val1 => $number->unit->value, val2 => $number->carry->value
                                   , w1l   => $lines_above->[$col]--, w1c => $col , w1val => $number->unit->value);
      push(@action, $action);
      $result->[$col] = $number->unit->value;
      $number         = $number->carry;
    }
    else {
      my $already_there  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result->[$col]);
      my Arithmetic::PaperAndPencil::Number $sum = $number + $already_there;
      $action = Arithmetic::PaperAndPencil::Action->new(level => 6, label => 'ADD01', val1  => $number->value, val2  => $already_there->value, val3 => $sum->value
                                                   , r2l => $lines_above->[$col] + 1, r2c   => $col          , r2val => $already_there->value, r2str => 1
                                                   );
      push(@action, $action);
      my $code = 'WRI02';
      if ($sum->chars == 1) {
        $code = 'WRI03';
      }
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => $code, val1  => $sum->unit->value, val2 => $sum->carry->value
                                   , w1l => $lines_above->[$col]--, w1c   => $col , w1val => $sum->unit->value
                                   );
      push(@action, $action);
      $result->[$col] = $sum->unit->value;
      $number         = $sum->carry;
    }
    --$col;
  }
}

method _halving(%param) {
  my $l1           = $param{l1};
  my $c1           = $param{c1};
  my $l2           = $param{l2};
  my $c2           = $param{c2};
  my $number       = $param{number};
  my $basic_level  = $param{basic_level} // 0;

  my $radix = $number->radix;
  my $res   = '';
  my Arithmetic::PaperAndPencil::Action $action;
  if ($radix == 2) {
    if ($number->chars > 1) {
      $res = substr($number->value, 0, $number->chars - 1);
    }
    else {
      $res = '0';
    }
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 4, label => 'SHF01'
                            , r1l => $l1, r1c => $c1, r1val => $number->value  , val1  => $number->value
                            , w1l => $l2, w1c => $c2, w1val => $res            , val2  => $res
                 );
    push(@action, $action);
  }
  else {
    my $one = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '1');
    my $two = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '2');
    my $len = $number->chars;
    my $carry = 0;
    my @digit_list = split('', $number->value);
    for my $n (0 .. $#digit_list) {
      my $digit = $digit_list[$n];
      my Arithmetic::PaperAndPencil::Number $dividend;
      if ($carry == 0) {
        $dividend = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $digit);
      }
      else {
        $dividend = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '1' . $digit);
      }
      my Arithmetic::PaperAndPencil::Number $quotient = $dividend / $two;
      if ($dividend->is_odd) {
        $carry = 1;
      }
      else {
        $carry = 0;
      }
      $action = Arithmetic::PaperAndPencil::Action->new(   level  => $basic_level + 5, label => 'DIV07'
                   , val1 => $dividend->value             , val2  => $quotient->value, val3  => $carry
                   , r1l => $l1, r1c => $c1 -$len + $n + 1, r1val => $digit
                   , w1l => $l2, w1c => $c2 -$len + $n + 1, w1val => $quotient->value
                   );
      push(@action, $action);
      $res .= $quotient->value;
    }
  }
  return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $res);
}

method _doubling(%param) {
  my $l1           = $param{l1};
  my $c1           = $param{c1};
  my $l2           = $param{l2};
  my $c2           = $param{c2};
  my $number       = $param{number};
  my $basic_level  = $param{basic_level} // 0;

  my $radix = $number->radix;
  my $res   = '';
  my Arithmetic::PaperAndPencil::Action $action;
  if ($radix == 2) {
    $res = $number->value . '0';
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 4, label => 'SHF01'
                            , r1l => $l1, r1c => $c1, r1val => $number->value  , val1  => $number->value
                            , w1l => $l2, w1c => $c2, w1val => $res            , val2  => $res
                            );
    push(@action, $action);
  }
  else {
    my $carry  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '0');
    my $one    = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '1');
    my $two    = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '2');
    my @digit_list = split('', reverse($number->value));
    for my $n (0 .. $#digit_list) {
      my $digit   = $digit_list[$n];
      my $product = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $digit);
      $product *= $two;
      if ($carry->value eq '0') {
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'MUL01'
                         , val1 => '2', val2 => $digit  , val3  => $product->value
                         , r1l  => $l1, r1c  => $c1 - $n, r1val => $digit
                         , w1l  => $l2, w1c  => $c2 - $n, w1val => $product->value
                         );
        push(@action, $action);
      }
      else {
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'MUL01'
                         , val1 => '2', val2 => $digit  , val3  => $product->value
                         , r1l  => $l1, r1c  => $c1 - $n, r1val => $digit
                         );
        push(@action, $action);
        $product += $one;
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'ADD02'
                         , val1 => '1'                  , val2  => $product->value
                         , w1l  => $l2, w1c  => $c2 - $n, w1val => $product->value
                         );
        push(@action, $action);
      }
      $res = $product->unit->value . $res;
      $carry = $product->carry;
    }
    if ($carry->value eq '1') {
      $res = '1' . $res;
    }
  }
  return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $res);
}

method _mult_and_sub(%param) {
  my $l_dd         = $param{l_dd};
  my $c_dd         = $param{c_dd};
  my $dividend     = $param{dividend};
  my $l_dr         = $param{l_dr};
  my $c_dr         = $param{c_dr};
  my $divisor      = $param{divisor};
  my $l_qu         = $param{l_qu};
  my $c_qu         = $param{c_qu};
  my $quotient     = $param{quotient};
  my $l_re         = $param{l_re};
  my $c_re         = $param{c_re};
  my $basic_level  = $param{basic_level};
  my $l_pr         = $param{l_pr};
  my $c_pr         = $param{c_pr};
  my $mult_and_sub = $param{mult_and_sub}  // 'combined';

  my Arithmetic::PaperAndPencil::Action $action;
  my $radix    = $dividend->radix;
  my $carry    = '0';
  my $rem      = '';
  my $too_much = 0;

  if ($mult_and_sub eq 'separate') {
    my Arithmetic::PaperAndPencil::Number $pdt;
    $pdt = $self->_simple_mult(basic_level => $basic_level + 1
                         , l_md => $l_dr, c_md => $c_dr, multiplicand => $divisor
                         , l_mr => $l_qu, c_mr => $c_qu, multiplier   => $quotient
                         , l_pd => $l_pr, c_pd => $c_pr);
    if ($dividend < $pdt) {
      return (1, '');
    }
    $rem = $self->_embedded_sub(basic_level => $basic_level + 3
                      , l_hi => $l_dd, c_hi => $c_dd, high => $dividend
                      , l_lo => $l_pr, c_lo => $c_pr, low  => $pdt
                      , l_re => $l_re, c_re => $c_re);
    return (0, $rem);
  }
  for my $i (0 .. $divisor->chars - 1) {
    my $divisor_digit = substr($divisor->value, -$i - 1, 1);
    my $temp  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $divisor_digit);
    $temp *= $quotient;
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'MUL01', val3 => $temp->value
                   , r1l => $l_qu, r1c => $c_qu     , r1val => $quotient->value, val1  => $quotient->value
                   , r2l => $l_dr, r2c => $c_dr - $i, r2val => $divisor_digit  , val2  => $divisor_digit
                   );
    push(@action, $action);
    if ($carry ne '0') {
      $temp  += Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $carry);
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'ADD02', val1 => $carry, val2 => $temp->value);
      push(@action, $action);
    }
    my $dividend_digit = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($dividend->value, - $i - 1, 1));
    my Arithmetic::PaperAndPencil::Number $adjusted_dividend;
    my Arithmetic::PaperAndPencil::Number $rem_digit;
    ($adjusted_dividend, $rem_digit) = adjust_sub($dividend_digit, $temp);
    if ($i == $divisor->chars - 1) {
      if ($dividend->carry($i) < $adjusted_dividend) {
        $too_much = 1;
      }
      else {
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6      , label => 'SUB02'
                                                        , val1  => $rem_digit->value     , val2  => $adjusted_dividend->value
                                                        , r1l => $l_dd, r1c => $c_dd - $i, r1val => $adjusted_dividend->value
                                                        );
        push(@action, $action);
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'WRI04'   , val1  => $rem_digit->value
                                                        , w1l   => $l_re           , w1c   => $c_re - $i, w1val => $rem_digit->value
                     );
        push(@action, $action);
        $rem   = $rem_digit->value . $rem;
      }
    }
    else {
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6      , label => 'SUB02'
                                                      , val1  => $rem_digit->value     , val2  => $adjusted_dividend->value
                                                      , r1l => $l_dd, r1c => $c_dd - $i, r1val => $adjusted_dividend->value);
      push(@action, $action);
      my $label = 'WRI02';
      if ($adjusted_dividend->carry->value eq '0') {
        $label = 'WRI03';
      }
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => $label
                                       , val2 => $adjusted_dividend->carry->value, val1  => $rem_digit->value
                                                , w1l => $l_re, w1c => $c_re - $i, w1val => $rem_digit->value );
      push(@action, $action);
      $rem   = $rem_digit->value . $rem;
      $carry = $adjusted_dividend->carry->value;
    }
  }
  return ($too_much, $rem);
}

method _embedded_div(%param) {
  my $l_dd         = $param{l_dd};
  my $c_dd         = $param{c_dd};
  my $dividend     = $param{dividend};
  my $l_dr         = $param{l_dr};
  my $c_dr         = $param{c_dr};
  my $divisor      = $param{divisor};
  my $l_qu         = $param{l_qu};
  my $c_qu         = $param{c_qu};
  my $basic_level  = $param{basic_level};
  my $type         = $param{type};
  my $mult_and_sub = $param{mult_and_sub}  // 'combined';
  my $mult_cache   = $param{mult_cache};
  my $stand_alone  = $param{stand_alone};

  my Arithmetic::PaperAndPencil::Action $action;
  my $radix = $dividend->radix;
  my $zero  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '0');
  my $one   = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '1');
  my $len1  = $dividend->chars;
  my $len2  = $divisor ->chars;
  my $col_r = $len2;     # column for the successive partial dividends and remainders
  my $len_dvd1 = 1;      # length of the part of the dividend used to compute the first candidate digit
  # yes, string comparison or left-aligned comparison, to know if we need a short hook or a long hook
  if ($dividend lt $divisor) {
    $len_dvd1++;
    $col_r++;
  }
  my $bot      = $l_dd + 2;
  my $quotient = '';
  my $rem      = '';
  my $nb_dots  = $len1 - $col_r + 1;
  my $dots     = '.' x $nb_dots;
  $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'DRA01'
                                                  , w1l   => $l_dr, w1c => $c_dr - $len2
                                                  , w2l   => $bot , w2c => $c_dr - $len2);
  push(@action, $action);
  $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'WRI00'
                                                  , w1l   => $l_dr, w1c => $c_dr               , w1val => $divisor->value
                                                  , w2l   => $l_qu, w2c => $c_qu + $nb_dots - 1, w2val => $dots);
  push(@action, $action);
  $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 1, label => 'HOO01'
                                                  , w1l   => $l_dd, w1c => $c_dd - $len1 + 1
                                                  , w2l   => $l_dd, w2c => $c_dd - $len1 + $col_r);
  push(@action, $action);

  # computation
  if ($type eq 'std' || $type eq 'cheating') {
    my $lin_d = $l_dd;     # line of the partial dividend
    my $delta = $len2 - 1; # how long we must shorten the divisor and the partial dividend to compute the quotient first candidate
    my $part_dvr1 = $divisor->carry($delta); # single-digit divisor to compute the quotient first candidate
    my $part_dvd  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($dividend->value, 0, $col_r));
    while ($col_r <= $len1) {
      # single-digit dividend or 2-digit dividend to compute the quotient first candidate
      my Arithmetic::PaperAndPencil::Number $part_dvd1 = $part_dvd->carry($delta);
      my Arithmetic::PaperAndPencil::Number $theo_quo  = $part_dvd1 / $part_dvr1;  # theoretical quotient first candidate
      my Arithmetic::PaperAndPencil::Number $act_quo;                              # actual quotient first candidate
      my $label;
      if ($part_dvd < $divisor) {
        $theo_quo = $zero;
        $act_quo  = $zero;
      }
      elsif ($type eq 'cheating') {
        my $dig = max( grep { $mult_cache->{$_} <= $part_dvd } keys(%{$mult_cache}));
        $act_quo = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $dig);
        $label   = 'DIV03';
      }
      elsif ($theo_quo->chars == 2) {
        $act_quo  = max_unit($radix);
        $label    = 'DIV02';
      }
      else {
        $act_quo  = $theo_quo;
      }
      my $too_much = 1; # we must loop with the next lower candidate
      if ($theo_quo->value eq '0') {
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'DIV01'
                     , val1  => $part_dvd->value , r1l => $lin_d, r1c => $c_dd + $col_r   , r1val => $part_dvd->value
                     , val2  => $divisor ->value , r2l => $l_dr , r2c => $c_dr + $len2 - 1, r2val => $divisor->value
                     , val3  => '0'             , w1l => $l_qu , w1c => $c_qu            , w1val => '0');
        push(@action, $action);
        $too_much = 0; # no need to loop on candidate values, no need to execute the mult_and_sub routine
        $rem = $part_dvd->value;
      }
      elsif ($theo_quo->value eq $act_quo->value) {
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'DIV01'
                     , val1  => $part_dvd1->value, r1l => $lin_d, r1c => $c_dd - $len1 + $col_r - $delta, r1val => $part_dvd1->value
                     , val2  => $part_dvr1->value, r2l => $l_dr , r2c => $c_dr - $len2 + 1      - $delta, r2val => $part_dvr1->value
                     , val3  => $theo_quo ->value, w1l => $l_qu , w1c => $c_qu                          , w1val => $act_quo->value);
        push(@action, $action);
      }
      else {
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'DIV01'
                     , val1  => $part_dvd1->value, r1l => $lin_d, r1c => $c_dd - $len1 + $col_r - $delta, r1val => $part_dvd1->value
                     , val2  => $part_dvr1->value, r2l => $l_dr , r2c => $c_dr - $len2 + 1              , r2val => $part_dvr1->value
                     , val3  => $theo_quo ->value);
        push(@action, $action);
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => $label
                              , val1 => $act_quo->value, w1l => $l_qu, w1c => $c_qu, w1val => $act_quo->value);
        push(@action, $action);
      }
      my $l_re;
      while ($too_much) {
        if ($mult_and_sub eq 'separate') {
          $l_re = $lin_d + 2;
        }
        else {
          $l_re = $lin_d + 1;
        }
        if ($bot < $l_re) {
          $bot = $l_re;
          $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'DRA01'
                                                          , w1l   => $l_dd, w1c => $c_dr - $len2
                                                          , w2l   => $bot , w2c => $c_dr - $len2);
          push(@action, $action);
        }

        ($too_much, $rem) = $self->_mult_and_sub(l_dd => $lin_d    , c_dd => $c_dd - $len1 + $col_r, dividend     => $part_dvd
                                               , l_dr => $l_dr     , c_dr => $c_dr                 , divisor      => $divisor
                                               , l_qu => $l_qu     , c_qu => $c_qu                 , quotient     => $act_quo
                                               , l_re => $l_re     , c_re => $c_dd - $len1 + $col_r, basic_level  => $basic_level
                                               , l_pr => $lin_d + 1, c_pr => $c_dd - $len1 + $col_r, mult_and_sub => $mult_and_sub);
        if ($too_much) {
          $action[-1]->set_level($basic_level + 4);
          $act_quo -= $one;
          my $erased_column;
          if ($stand_alone) {
            $erased_column = $c_dd - $len1;
          }
          else {
            $erased_column = $c_dd - $len1 + 1;
          }
          $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'ERA01'
                                   , w1l => $lin_d + 1, w1c => $c_dd, w2l => $lin_d + 1, w2c => $erased_column);
          push(@action, $action);
          $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 4, label => 'DIV02'
                                , val1 => $act_quo->value, w1l => $l_qu, w1c => $c_qu, w1val => $act_quo->value);
          push(@action, $action);
        }
      }

      $quotient .= $act_quo->value;
      if ($act_quo->value ne '0') {
        $lin_d = $l_re;
      }
      $action[-1]->set_level($basic_level + 3);
      if ($col_r < $len1) {
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'DRA01'
                                                        , w1l   => $l_dr, w1c => $c_dr - $len2
                                                        , w2l   => $bot , w2c => $c_dr - $len2);
        push(@action, $action);
        my $new_digit = substr($dividend->value, $col_r, 1);
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3   , label => 'DIV04'   , val1  => $new_digit
                     , r1l => $l_dd , r1c => $c_dd - $len1 + $col_r  + 1, r1val => $new_digit
                     , w1l => $lin_d, w1c => $c_dd - $len1 + $col_r  + 1, w1val => $new_digit);
        push(@action, $action);
        $part_dvd = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $rem . $new_digit);
      }
      $col_r++;
      $c_qu++;
    }
    $action[-1]->set_level($basic_level);
  }
  if ($type eq 'prepared') {
    my $part_div  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($dividend->value, 0, $col_r));
    my $n = 0;
    my $lin_d = $l_dd;
    while ($col_r <= $len1) {
      my $part_quo = max( grep { $mult_cache->{$_} <= $part_div } keys(%{$mult_cache}));
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'DIV01'
                   , val1 => $part_div->value, r1l => $lin_d, r1c => $col_r       , r1val => $part_div->value
                   , val2 => $divisor->value , r2l => $l_dr , r2c => $c_dr        , r2val => $divisor->value
                   , val3 => $part_quo      , w1l => $l_qu , w1c => $c_qu + $n   , w1val => $part_quo);
      push(@action, $action);
      $quotient .= $part_quo;
      if ($part_quo eq '0') {
        $rem = $part_div->value;
      }
      else {
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'WRI05', val1 => $mult_cache->{$part_quo}->value);
        push(@action, $action);
        $bot += 2;
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 8, label => 'WRI00'
                     , w1l => $lin_d + 1, w1c => $c_dd - $len1 + $col_r, w1val => $mult_cache->{$part_quo}->value);
        push(@action, $action);
        $rem = $self->_embedded_sub(basic_level => $basic_level + 3
                     , l_hi => $lin_d    , c_hi => $c_dd - $len1 + $col_r, high => $part_div
                     , l_lo => $lin_d + 1, c_lo => $c_dd - $len1 + $col_r, low  => $mult_cache->{$part_quo}
                     , l_re => $lin_d + 2, c_re => $c_dd - $len1 + $col_r);
        $action[-1]->set_level($basic_level + 3);
        $lin_d += 2;
      }

      if ($col_r < $len1) {
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'DRA01'
                                                        , w1l => $l_dd, w1c => $c_dd
                                                        , w2l => $bot , w2c => $c_dd);
        push(@action, $action);
        my $new_digit = substr($dividend->value, $col_r, 1);
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3, label => 'DIV04', val1  => $new_digit
                                                  , r1l => $l_dd , r1c => $c_dd - $len1 + $col_r  + 1, r1val => $new_digit
                                                  , w1l => $lin_d, w1c => $c_dd - $len1 + $col_r  + 1, w1val => $new_digit);
        push(@action, $action);
        $part_div =  Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $rem . $new_digit);
      }
      ++$col_r;
      ++$n;
    }
  }
  return ( Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $quotient)
         , Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $rem));
}


'0 + 0 = (:-|)'; # End of Arithmetic::PaperAndPencil

=encoding utf8

=head1 NAME

Arithmetic::PaperAndPencil - simulating paper and pencil techniques for basic arithmetic operations

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Arithmetic::PaperAndPencil;

    my $operation = Arithmetic::PaperAndPencil->new;
    my $x = Arithmetic::PaperAndPencil::Number->new(value => '355000000');
    my $y = Arithmetic::PaperAndPencil::Number->new(value => '113');

    $operation->division(dividend => $x, divisor => $y);
    my $html = $operation->html(lang => 'fr', silent => 0, level => 3);
    open my $fh, '>', 'division.html' or die "opening file $!";
    print $fh $html;
    close $fh or die "closing file $!";

    $operation = Arithmetic::PaperAndPencil->new; # emptying previous content
    my $dead = Arithmetic::PaperAndPencil::Number->new(value => 'DEAD', radix => 16);
    my $beef = Arithmetic::PaperAndPencil::Number->new(value => 'BEEF', radix => 16);

    $operation.addition($dead, $beef);
    $html = $operation.html(lang => 'fr', silent => 0, level => 3);
    open  $fh, '>', 'addition.html' or die "opening file $!";
    print $fh $html;
    close $fh or die "closing file $!";

The first HTML file ends with

    355000000|113
    0160     |---
     0470    |3141592
      0180   |
       0670  |
        1050 |
         0330|
          104|

and the second one with

     DEAD
     BEEF
    -----
    19D9C


=head1 DESCRIPTION

Arithmetic::PaperAndPencil  is a  module which  allows simulating  the
paper  and  pencil  techniques  for  basic  arithmetic  operations  on
integers: addition, subtraction, multiplication and division, but also
square root extraction and conversion from a radix to another.

An  object  from  the C<Arithmetic::PaperAndPencil>  class  is  called
"paper  sheet", because  it  represents  a paper  sheet  on which  the
simulated human scribbles  his computations. In some  cases, the human
would use a wad of sheets instead of a single sheet. This is simulated
in the module, but we still call the object a "paper sheet".

=head2 Problems, known bugs and acceptable breaks from reality

Most  humans  can only  compute  in  radix  10.  Some persons  have  a
theoretical knowledge  of numeric bases  other than 10, and  a limited
practical skill  of using radix  2, radix 8  and radix 16.  The module
uses any radix from 2 to 36, without difference.

The module  can use numbers  of any length.  Human beings will  not be
able to  multiply two  100-digit numbers.  Or if  they try,  they will
spend much effort  and the result may be wrong.  The module can easily
multiply two 100-digit numbers. The  output may be lengthy and boring,
but it will be correct.

Humans can  detect situations where  the computation procedure  can be
amended,  such as  a  multiplication where  the  multiplicand and  the
multiplier contain many  "0" digits. The module does  not detect these
cases and still uses the unaltered computation procedure.

Human beings write their calculations on A4 paper (21 cm × 29,7 cm) or
letter paper (21,6  cm × 27,9 cm). The module  writes its calculations
on unlimited  sheets of paper. If  you want to compute  the product of
two 1000-digit numbers, the multiplication will have a 2000-char width
and a 1000-line height and still be on a single sheet of paper.

If you  ask for the  operations with  the "talking" formulas,  most of
these  formulas are  the traditional  sentences which  accompanies the
writing of the  computation. But in some cases, the  module displays a
non-standard sentence, to explain better what is happening.

=head1 EXPORT

None.

=head1 UTILITY METHODS

=head2 new

Creates an  empty paper sheet.  Or removes  the content of  an already
existing paper sheet.

=head2 from_csv

Creates  a  paper  sheet  containing  the  operations  listed  in  the
parameter CSV string.

=head2 csv

Generates a string with a CSV format and listing all operations stored
in the sheet  object. The opposite of C<from_csv>. This  string can be
printed into a CSV file for later retrieval.

=head2 html

Generates a string using the HTML format.

For a properly formatted HTML file, the module user should provide the
beginning of the file, from the C<< <html> >> tag until the C<< <body>
>> tag, and then  the end of the file, with  the C<< </body></html> >>
tags.

The parameters are the following:

=over 4

=item * C<lang>

The  language for  the titles  and messages.  The C<"fr">  language is
fully specified, and the C<"en"> language is still incomplete. For the
moment, there are no other languages.

=item * C<silent>

Boolean parameter controlling the display of the "spoken" messages. If
C<1>,  only  the titles  are  displayed.  It  C<0>, all  messages  are
displayed.

=item * C<level>

Integer parameter  controlling the  display of partial  operations. If
C<0>, only the final complete operation  is shown. If C<1>, each sheet
is displayed  upon switching  to another  sheet (when  using a  wad of
sheets). If C<2> or more, partial operations are displayed. The higher
the parameter, the more often the partial operations are displayed.

=item * C<css>

Overrides  the default  HTML formatting.  This is  a hash  table, with
entries among C<underline>, C<strike>,  C<write>, C<read> and C<talk>.
If  an entry  exists,  the default  format is  replaced  by C<<  <span
style='xxx'> >>. Exception: if the  C<talk> entry exists, the "spoken"
messages are formatted with C<< <p style='xxx'> >>.

=back

=head1 ARITHMETIC METHODS

All  these  methods   return  a  C<Arithmetic::PaperAndPencil::Number>
instance,  equal to  the  result of  the  operation. Unless  specified
otherwise,  all input  C<Arithmetic::PaperAndPencil::Number> instances
must have the same numeric radix.

=head2 addition

Simulates the addition  of two or more numbers. The  numbers are given
as a  list variable  C<@list> or  a list  of scalar  variables C<$nb1,
$nb2,  $nb3>.  This is  a  positional  parameter.  Each number  is  an
instance of the C<Arithmetic::PaperAndPencil::Number> class.

=head2 subtraction

Simulates   the  subtraction   of  two   numbers,  instances   of  the
C<Arithmetic::PaperAndPencil::Number> class. The  keywords are C<high>
and C<low>.  The C<high> number must  be greater than or  equal to the
C<low> number. Negative results are not allowed.

A third  keyword parameter  is C<type>. With  this parameter,  you can
choose  between  a  standard subtraction  (parameter  value  C<"std">,
default value) and a subtraction using the radix-complement of the low
number (parameter value C<"compl">).

Acceptable break from reality. When  using the C<"compl"> variant, the
module will write the extra digit  and then strike it, while the human
computer will stop before writing  this extra digit, especially in the
context of assembly programming, where  for example the registers hold
32 bits, not 33.

=head2 multiplication

Simulates the  multiplication of  two numbers. The  keyword parameters
are:

=over 4

=item * C<multiplicand>, C<multiplier>

The two numbers to be multiplied, instances of C<Arithmetic::PaperAndPencil::Number>.

=item * C<type>

Specifies the variant technique. This parameter is a string value. The
default  variant  is  C<'std'>.   Other  values  are  C<'jalousie-A'>,
C<'jalousie-B'>, C<'boat'> or C<'russian'> (see below).

=item * C<direction>

This  parameter  is  used  with the  C<'boat'>  type.  Value  C<'ltr'>
(default value)  specifies that the elementary  products are processed
left-to-right,  value  C<'rtl'>  specifies  that  these  products  are
processed  right-to-left.   This  applies   only  to   processing  the
multiplier's   digits.  Whatever   the  value,   the  digits   of  the
multiplicand are processed left-to-right.

This   parameter   has   no  use   with   C<'std'>,   C<'jalousie-A'>,
C<'jalousie-B'> and C<'russian'> types.

=item * C<mult-and-add>

This parameter  is used with  the C<'boat'> type.  Value C<'separate'>
(default value) means that in a first phase, the digits resulting from
the elementary multiplications are written  and that in a second phase
these  digits are  added together  to obtain  the final  result. Value
C<'combined'> means that as soon  as a elementary product is computed,
its digits  are added to the  running sum which will  become the final
full product at the end.

This   parameter   has   no  use   with   C<'std'>,   C<'jalousie-A'>,
C<'jalousie-B'> and C<'russian'> types.

=item * C<product>

This  parameter   is  used  with  the   C<"jalousie-*">  types.  Value
C<"L-shaped"> (default value) means that the product is written in two
parts,  an horizontal  one  at  the bottom  of  the  operation and  an
vertical one, on the left side of the operation for C<"jalousie-A"> or
on the right side for  C<"jalousie-B">. Value C<"straight"> means than
the product  is written horizontaly  on the  bottom line, even  if the
bottom line is wider than the rectangle of the operation.

This parameter  has no use  with C<'std'>, C<'boat'>  and C<'russian'>
types.

=back

The various types are

=over 4

=item * C<std>

The standard multiplication.

Acceptable break  from reality:  remember that the  successive partial
products  shifts by  one column.  These shifts  are materialised  with
dots. When  the multiplier contains  a digit  C<0>, the line  with all
zeroes is not printed and the shift  is more than one column, with the
corresponding number of dots. Example:

  .      628
  .      203
  .      ---
  .     1884
  .   1256..
  .   ------
  .   127484

The actual acceptable  break from reality happens  when the multiplier
contains zeroes on the right. In this case, are there dots in the very
first line? Or do we write zeroes? See below both cases.

  .      628          628
  .      230          230
  .      ---          ---
  .    1884.        18840
  .   1256..       1256..
  .   ------       ------
  .   144440       144440

The module uses the second possibility, writing zeroes on the first line.

=item * C<shortcut>

The standard multiplication, but  if the multiplier  contains repeated
digits, the  partial products  are computed only  once. When  the same
digit appears a second time in the multiplier, the  partial product is
copied from the first occurrence instead of being recomputed.

=item * C<prepared>

This  variant  is  inspired  from  the  C<prepared>  variant  for  the
division.  Before  starting  the multiplication  proper,  all  partial
products are  preemptively computed. Then, when  the multiplication is
computed, all partial products are  simply copied from the preparation
step.

Acceptable  break  from  reality:  there  is  no  evidence  that  this
technique  is taught  or used.  It is  just an  possible extension  to
multiplication of the prepared division technique.

=item * C<jalousie-A>

The partial products are written in rectangular form. The multiplicand
is  written  left-to-right on  the  top  side  of the  rectangle,  the
multiplier  is  written  top-to-bottom  on   the  right  side  of  the
rectangle, the  final product is  written first, top-to-bottom  on the
left side  of the  rectangle and second,  left-to-right on  the bottom
side of  the rectangle. For example,  the multiplication C<15 ×  823 =
12345>  gives  the following  result  (omitting  the interior  of  the
rectangle):

  .     823
  .    1   1
  .    2   5
  .     345

If the C<product> parameter is C<"straight">, then the operation final
aspect is:

  .     823
  .        1
  .        5
  .   12345

Acceptable break from reality: the  outlying digits should be centered
with respect  to the inner  grid. The module  writes them in  a skewed
fashion. In addition, the inner  vertical and horizontal lines are not
drawn. Below left, the theoretical  output, below right the simplified
output:

  .     8   2   3         8 2 3
  .   -------------      --------
  .   |0 /|0 /|0 /|      |0/0/0/|
  .  1| / | / | / |1    1|/8/2/3|1
  .   |/ 8|/ 2|/ 3|      |4/1/1/|
  .   -------------     2|/0/0/5|5
  .   |4 /|1 /|1 /|      --------
  .  2| / | / | / |5      3 4 5
  .   |/ 0|/ 0|/ 5|
  .   -------------
  .     3   4   5


=item * C<jalousie-B>

The partial products are written in rectangular form. The multiplicand
is  written  left-to-right on  the  top  side  of the  rectangle,  the
multiplier is written bottom-to-top on the left side of the rectangle,
the final product  is written first, left-to-right on  the bottom side
of the  rectangle and second, bottom-to-top  on the right side  of the
rectangle. For  example, the multiplication C<15 × 823 =  12345> gives
the following result (omitting the interior of the rectangle):

  .  823
  . 5   5
  . 1   4
  .  123

If the C<product> parameter is C<"straight">, then the operation final
aspect is:

  .  823
  . 5
  . 1
  .  12345

Acceptable break from reality: same as for C<'jalousie-A'>.

=item * C<boat>

The  multiplicand  is  written   between  two  horizontal  lines.  The
multiplier is written below the bottom line and stricken and rewritten
as  the multiplication  progresses. The  partial products  are written
above the  top line.  When the  partial products  are added,  they are
stricken and the final product is written above the partial products.

Acceptable  break from  reality: I  am not  sure the  explanation from
I<Number Words and  Number Symbols> is authoritative. So  I have added
two parameters, C<direction> and  C<mult-and-add>, to allow the module
user to choose which subvariant he prefers.

=item * C<russian>

Better known  as the "Russian peasant  multiplication". The multiplier
and  the multiplicand  are written  side-by-side. Then,  on each  line
below, the multiplier is halved and the multiplicand is doubled, until
the  multiplier  reaches C<1>.  On  some  lines, the  multiplicand  is
stricken and then the unstricken lines are added together, which gives
the final product.

=back

=head2 division

Simulates the division of two numbers. The keyword parameters are:

=over 4

=item * C<dividend>, C<divisor>

The two numbers to be divided, instances of C<Arithmetic::PaperAndPencil::Number>.

=item * C<type>

Specifies the variant technique. This parameter is a string value. The
default variant is C<"std">.

=item * C<result>

This string parameter  can be either C<"quotient">  (default value) or
C<"remainder">,  or  C<"both">.  It  controls  which  value  is  (are)
returned by the method to the main programme.

=item * C<mult-and-sub>

This string parameter  can be either C<"combined">  (default value) or
C<"separate">. It  controls the computation of  the successive partial
remainders with  a multiplication (quotient digit  times full divisor)
and a subtraction  (from the partial dividend).  If C<"combined">, the
multiplication and  the subtraction are  done at the same  time, digit
per digit. If C<"separate">, the multiplication is done first in full,
then the subtraction is done.

=back

The various types are

=over 4

=item * C<std>

The standard division.

=item * C<cheating>

This is the  standard division with a twist. The  standard division is
usually a  trial-and-error process  in which several  candidate digits
are  tried  for   each  quotient  digit.  With   this  technique,  the
trial-and-error process is cut short  and only the successful digit is
tried.

Acceptable break  from reality: This is  not a real method,  this is a
convenience  method  which gives  shorter  HTML  files than  what  the
C<"std"> type generates.

=item * C<prepared>

Before starting the division, the module computes the partial products
of the divisor with any  single-digit number. These when computing the
intermediate  remainders,   instead  of   doing  a   multiplication  -
subtraction combination,  the already known partial  product is simply
copied from  the preparation  list then  subtracted from  the previous
intermediate  remainder.  The  C<mult-and-sub> parameter  defaults  to
C<"separate"> for this division type.

=item * C<boat>

The  dividend is  written above  an  horizontal line.  The divisor  is
written below this  line. As the first partial  remainder is computed,
the  used digits  of the  dividend and  divisor are  stricken and  the
digits of  the partial remainder are  written above the digits  of the
dividend. When computing the next digits, the divisor is rewritten and
the computation of the next partial remainder again strikes the digits
of the  first partial remainder  and of  the second occurrence  of the
divider.

Acceptable  break  from   reality:  I  have  not   found  anywhere  an
explanation for this technique. The way it is implemented is just some
guesswork after some reverse engineering  attempt on a few examples. A
special point  is that it  seems to  require something similar  to the
C<cheating>  technique  above,  because  I  do  not  see  how  we  can
"unstrike"  the digits  that  were stricken  with  the previous  digit
candidate.

=back

=head2 square_root

Simulates the  extraction of the square  root of a number.  There is a
single     positional     parameter,     an    instance     of     the
C<Arithmetic::PaperAndPencil::Number> class.

There is  an optional keyword parameter,  C<mult-and-sub>. Its purpose
is the same as for division.  If set to C<'combined'> (default value),
the  computing  of the  product  (candidate  digit times  divisor)  is
combined with  the subtraction  from the partial  dividend. If  set to
C<'separate'>, the multiplication and  the subtraction are executed in
separate and successive phases.

=head2 conversion

Simulates the conversion  of a number from its current  radix to a new
radix.

The parameters are:

=over 4

=item * C<number>

The number to convert, instance of C<Arithmetic::PaperAndPencil::Number>.

=item * C<radix>

The destination  radix for the  conversion. This is a  native integer,
not an instance of C<Arithmetic::PaperAndPencil::Number>.

=item * C<nb-op>

The  number of  operations  on a  single page.  After  this number  is
reached, a  new page  is generated. This  allows keeping  the complete
operation sufficiently short.  This parameter is a  native integer. If
zero (default value), no new pages are generated.

=item * C<type>

A string  parameter specifying  which algorithm is  used to  convert a
number. Values  C<'mult'> and C<'Horner'>  are synonymous and  use the
cascading multiplication algorithm (or  Horner scheme). Value C<'div'>
uses the cascading division algorithm.

=item * C<div-type>

A string parameter specifying which kind of division is used: C<'std'>
(default value) uses  a standard division with  a full trial-and-error
processing  for  candidate  quotient   digits,  C<'cheating'>  uses  a
standard division  in which the trial-and-error  of candidate quotient
digits is  artificially reduced  to a single  iteration, C<'prepared'>
first computes the list of multiples  for the target radix and uses it
to openly and  accountably reduce the trial-and-error  processing to a
single iteration.

This parameter is  ignored if the conversion parameter  C<type> is not
C<'div'>.

See  the  C<type>  parameter  for the  C<division>  method.  Yet,  the
C<'boat'> value available for the C<type> parameter of the C<division>
method  is   not  allowed  for   the  C<div-type>  parameter   of  the
C<conversion> method.

=item * C<mult-and-sub>

This parameter  is similar  to the  C<mult-and-sub> parameter  for the
C<division> method, except that it is  useful only if the value of the
C<div-type> parameter is C<'cheating'>.

The  parameter  controls the  computation  of  the successive  partial
remainders with  a multiplication (quotient digit  times full divisor)
and a  subtraction (from  the partial  dividend). Possible  values are
C<'combined'> or  C<'separate'>. If C<'combined'>,  the multiplication
and the  subtraction are done  at the same  time, digit per  digit. If
C<'separate'>,  the multiplication  is done  first in  full, then  the
subtraction is done.

If  the  C<div-type> parameter  is  C<'prepared'>,  this parameter  is
ignored  and   the  multiplication   and  the  subtraction   are  done
separately.

If  the   C<div-type>  parameter  is  C<'std'>,   the  C<mult-and-sub>
parameter is  ignored and the  multiplication and the  subtraction are
combined. The  reason for  this behaviour  is to  by-pass a  bug which
would appear in cramped situations where several divisions are crammed
side by side.

=back

=head2 gcd

Simulates the computation of the  GCD (greatest common divisor) of two
numbers.

The parameters are:

=over 4

=item * C<first>

The first number used, instance of C<Arithmetic::PaperAndPencil::Number>.

=item * C<second>

The second number used, instance of C<Arithmetic::PaperAndPencil::Number>.

=item * C<div-type>

A string parameter specifying which kind of division is used: C<"std">
(default value) uses  a standard division with  a full trial-and-error
processing  for  candidate  quotient   digits,  C<"cheating">  uses  a
standard division  in which the trial-and-error  of candidate quotient
digits is artificially reduced to a single iteration.

See  the  C<type>  parameter  for the  C<division>  method.  Yet,  the
C<"boat"> and C<"prepared"> values available for the C<type> parameter
of  the  C<division>  method  are  not  allowed  for  the  C<div-type>
parameter of the C<gcd> method.

=back

=head1 BUGS, ISSUES AND ACCEPTABLE BREAKS FROM REALITY

For the  various arithmetical methods, not  all parameter combinations
are  used in  real life.  This includes  especially the  C<"cheating">
variants.

The  values  assigned  to  the   C<level>  attribute  are  not  always
consistent and  they may lead to  awkward listings, in which  a boring
part is  printed in whole  detail and  an interesting part  is printed
without enough detail.

=head1 SECURITY MATTERS

As said above, the numbers are not limited in length. The flip side is
that  the  user can  ask  for  the  multiplication of  two  1000-digit
numbers, which  means several millions of  basic actions (single-digit
multiplications, basic  additions, etc). This  can lead to  a DOS-like
situation: filled-up memory, clogged CPU for example.

Another issue is the initialisation of a C<Arithmetic::PaperAndPencil>
object with a  CSV file. The content  of the CSV file  is not checked.
This  can  result  is  line  and column  coordinates  ranging  in  the
thousands or  beyond. In this  case, the  C<html> method will  build a
huge string result.

=head1 SEE ALSO

The background of this module is extensively described in the Github repository
of the Raku module with the same name. See
L<https://github.com/jforget/raku-Arithmetic-PaperAndPencil/blob/master/doc/Description-en.md>
(or L<https://github.com/jforget/raku-Arithmetic-PaperAndPencil/blob/master/doc/Description-fr.md>
if you speak French).

Raku module similar to this one:
L<https://github.com/jforget/raku-Arithmetic-PaperAndPencil>

HP48 / HP49 programme dealing with divisions:
L<https://www.hpcalc.org/details/5303>

=head1 DEDICATION

This module is dedicated to my  primary school teachers, who taught me
the basics of arithmetics, and even  some advanced features, and to my
secondary  school math  teachers, who  taught me  other advanced  math
concepts and features.


=head1 AUTHOR

jforget, C<< <J2N-FORGET at orange.fr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-arithmetic-paperandpencil at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Arithmetic-PaperAndPencil>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Arithmetic::PaperAndPencil

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Arithmetic-PaperAndPencil>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Arithmetic-PaperAndPencil>

=item * Search CPAN

L<https://metacpan.org/release/Arithmetic-PaperAndPencil>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by jforget.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

