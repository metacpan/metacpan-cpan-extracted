package Convert::AcrossLite;

use warnings;
use strict;
use Carp;
use vars qw($VERSION);

$VERSION = '0.10';

sub new {
  my $class = shift;
  my %conf = @_;

  my $self = {};
  $self->{in_file} = $conf{in_file} || 'Default.puz';
  $self->{is_parsed} = 0;

  bless($self, $class);
  return $self;
}

sub in_file {
  my($self) = shift;
  if(@_) { $self->{in_file} = shift }
  return $self->{in_file};
}

sub out_file {
  my($self) = shift;
  if(@_) { $self->{out_file} = shift }
  return $self->{out_file};
}

sub puz2text {
  my($self) = shift;
  my $text;

  # Parse puz file
  _parse_file($self) unless $self->{is_parsed};

  # Format across clues
  my @aclues = split("\n", $self->{aclues});
  foreach my $aclue(@aclues) {
    $aclue =~ s/\d+\s+-\s+//;
    $aclue = "\t$aclue";
  }
  $self->{aclues} = join("\n",@aclues);

  # Format down clues
  my @dclues = split("\n", $self->{dclues});
  foreach my $dclue(@dclues) {
    $dclue =~ s/\d+\s+-\s+//;
    $dclue = "\t$dclue";
  }
  $self->{dclues} = join("\n",@dclues);

  $text = "<ACROSS PUZZLE>\n"; 
  $text .= "<TITLE>\n";
  $text .= "\t$self->{title}\n";
  $text .= "<AUTHOR>\n";
  $text .= "\t$self->{author}\n";
  $text .= "<COPYRIGHT>\n";
  $text .= "\t$self->{copyright}\n";
  $text .= "<SIZE>\n";
  $text .= "\t$self->{rows}x$self->{columns}\n";
  $text .= "<GRID>\n";
  my $solref = $self->{solution};
  my @sol = @$solref;
  foreach my $sol (@sol) {
    $text .= "\t$sol\n";
  }
  $text .= "<ACROSS>\n";
  $text .= "$self->{aclues}\n";
  $text .= "<DOWN>\n";
  $text .= "$self->{dclues}\n";

  if( defined $self->out_file ) {
    my $PUZ_OUT = $self->out_file;

    open FH, ">$PUZ_OUT" or croak "Can't open $PUZ_OUT: $!";
    print FH $text;
    close FH;
  } else {
    return $text;
  }
}

sub get_across_down {
  my($self) = shift;
  my $across_hashref = get_across($self);
  my $down_hashref = get_down($self);

  return($across_hashref, $down_hashref);
}

sub get_across {
  my($self) = shift;
  _parse_file($self) unless $self->{is_parsed};

  ###################################################
  # _parse_file will set direction, number and clue #
  # as well as a two-dimension array for solution   # 
  ###################################################
  my $sol_two_ref = $self->{solution_two};
  my @sol_two = @$sol_two_ref;

  ### Get row, column, solution, length ###

  ###################################################
  # We're setting found squares to 1....
  # We need to set them to row and col so we can
  # do a "lookup" later. That is, given a row
  # and col number, we need to know what the clue
  # number is. Or maybe we need to make a key
  # that is row/col so we can look up clue num.
  ###################################################

  ######################################################
  # Determine which squares start with either 
  # an across word (%across_start_squares) 
  # or a down word (%down_start_squares). 
  ######################################################

  # Across
  my $square_num = 0;
  my %across_start_squares;
  my $diagram_ref = $self->{diagram};
  my @diagram = @$diagram_ref;
  for (my $j=0;$j<$self->{rows};$j++) { # height
    for(my $k=0;$k<$self->{columns};$k++) { # width
      # Check position for across number
      # Left edge non-black followed by non-black
      if( ($k == 0 &&
           substr($diagram[$j],$k,1) ne '.' &&    # Row $j, Col 0 (k)
           substr($diagram[$j],$k+1,1) ne '.') || # Row $j, Col 1 (k+1)
        # Previous black - nonblack - nonblack
          ( ($k+1)<$self->{columns} &&  # Not last col
            ($k-1)>=0 &&                # Not first col
            substr($diagram[$j],$k,1) ne '.' &&
            substr($diagram[$j],$k-1,1) eq '.' &&
            substr($diagram[$j],$k+1,1) ne '.' ) ) {

        $across_start_squares{$square_num}++;
        $square_num++
      } else {
        $square_num++
      }
    }
  }

  # Down
  my %down_start_squares;
  $square_num = 0;
  for(my $k=0;$k<$self->{columns};$k++) { # width
    for (my $j=0;$j<$self->{rows};$j++) { # height
    # Check position for down number
      if( ($j == 0 &&                              # Row 0
           substr($diagram[$j],$k,1) ne '.' &&
           substr($diagram[$j+1],$k,1) ne '.') ||
          # Black above - nonblack - nonblack below
          ( ($j-1)>=0 &&                           # Not first row
            ($j+1)<$self->{rows} &&                # Not last row
            substr($diagram[$j],$k,1) ne '.' &&
            substr($diagram[$j-1],$k,1) eq '.' &&
            substr($diagram[$j+1],$k,1) ne '.' ) ) {

        $down_start_squares{$square_num}++;
        if( $j >= $self->{rows}-1 ) {
          # Last row
          $square_num = $k+1; # col+1
        } else {
          # Not last row
          $square_num += $self->{columns};
        }
      } else {
        if( $j >= $self->{rows}-1 ) {
          # Last row
          $square_num = $k+1; # col+1
        } else {
          # Not last row
          $square_num += $self->{columns};
        }
      }
    }
  }

  ##########################################################
  # Go back through grid from square 0 to square 
  # (rows x cols - 1) and set the clue number on each 
  # square that is found in the across_start_squares and
  # down_start_square hashes from above.
  #
  # We create two versions....
  # 1) Row/Col - $clue_numbers[$row][$col] = $clue_number
  #    [0,0] to [14,14] for 15x15 ([0,0] to [rows-1,cols-1])
  # 2) Square Num  - $clue_numbers{$square} = $clue_number
  #    Square 0 to 224 for 15x15 (0 to row*cols-1)
  ###########################################################
  # Across
  my $counter = 0;
  my $clue_num = 1;
  my @clue_numbers;
  my %clue_numbers;
  for(my $row = 0; $row < $self->{rows}; $row++) {
    for(my $col = 0; $col < $self->{columns}; $col++) {
      if( $across_start_squares{$counter} || $down_start_squares{$counter} ) {
        # Hash - Square number
        $clue_numbers{$counter} = $clue_num;
        # Array - row/col
        $clue_numbers[$row][$col] = $clue_num;
        $clue_num++;
      }
      $counter++;
    }
  }

  # Now get data and set hash of hashes
  # Across
  my $start_row = 0;         # Square number - row
  my $start_col = 0;         # Square number - col
  my $start_square = 0; 
  my $length = 0;            # Length of current solution word
  my $square = 0;            # Grid square
  my $sol_word = '';         # Solution word
  my $last_square = '';      # Contents of last square visited
  my $last_square_two = '';  # Contents of two squares ago

  for(my $row = 0; $row < $self->{rows}; $row++) {
    for(my $col = 0; $col < $self->{columns}; $col++) {

      # If $sol_two[$row][$col] eq '.', then we *probably* want to
      # save our data...if $col == $self->{columns} - 1, then we
      # definitely want to.
      if ( $sol_two[$row][$col] eq '.' || $col >= $self->{columns} - 1 ) {

        # If this is first square and it contains '.',
        # don't save data. Just set a few vars and move on.
        if( $col == 0 && $sol_two[$row][$col] eq '.' ) {
          $square++;
          $last_square_two = $last_square;
          $last_square = '.';
          $start_col++;
          next;
        }

        # If this isn't first square in col, this square contains '.'  
        # and the previous square contains '.', don't save data.
        # Just set a few vars and move on.
        # NOTE: US crossword rules state clue must be at least three letters
        # We're checking the length is at least two, since some crosswords
        # are built that way...
        if( $sol_two[$row][$col] eq '.' && $col != 0 && $last_square eq '.' ) {
          if( $col == $self->{columns} - 1 ) {
            $start_row++;
            $start_col = 0;
          } else {
            $start_col++;
          } 
          $square++;
          $last_square_two = $last_square;
          $last_square = '.';
          next;
        }

        # Get last square of row
        if( $col == $self->{columns} - 1 ) {
          unless( $sol_two[$row][$col] eq '.' ) {
            $sol_word .= $sol_two[$row][$col];
            $length++;
          }
        }

        # NOTE: US crossword rules state clue must be at least three letters
        # We're checking the length is at least two, since some crosswords
        # are built that way...
        if( $length < 2 ) {
          # Reset variables
          $length = 0;
          $sol_word = '';
          if( $col >= $self->{columns} - 1 ) {
            $start_row++;
            $start_col = 0;
          } else {
            $start_col = $col + 1;
          }
          next;
        }

        # Get key and clue num
        my $clue_num = $clue_numbers[$start_row][$start_col];
        next unless defined $clue_num; 
        my $key = $clue_num;

        # Store info into puzzle hash
        $self->{across}{$key}{length} = $length;
        $self->{across}{$key}{solution} = $sol_word;
        $self->{across}{$key}{row} = $start_row + 1;
        $self->{across}{$key}{column} = $start_col + 1;
        $self->{across}{$key}{clue_number} = $clue_num;

        # Reset variables
        $length = 0;
        $sol_word = '';
        if( $col >= $self->{columns} - 1 ) {
          $start_row++;
          $start_col = 0;
        } else {
          $start_col = $col + 1;
        }
      } else {
        # TODO - might want to check if next square is '.'
        $sol_word .= $sol_two[$row][$col];
        $length++;
      }
      $square++;
      $last_square_two = $last_square;
      $last_square = $sol_two[$row][$col];
    }
  }

  # Return across hash 
  return ($self->{across});
}


sub get_down {
  my($self) = shift;
  _parse_file($self) unless $self->{is_parsed};

  ###################################################
  # _parse_file will set direction, number and clue #
  # as well as a two-dimension array for solution   # 
  ###################################################
  my $sol_two_ref = $self->{solution_two};
  my @sol_two = @$sol_two_ref;

  ### Get row, column, solution, length ###

  ###################################################
  # We're setting found squares to 1....
  # We need to set them to row and col so we can
  # do a "lookup" later. That is, given a row
  # and col number, we need to know what the clue
  # number is. Or maybe we need to make a key
  # that is row/col so we can look up clue num.
  ###################################################

  ######################################################
  # Determine which squares start with either 
  # an across word (%across_start_squares) 
  # or a down word (%down_start_squares). 
  ######################################################

  # Across
  my $square_num = 0;
  my %across_start_squares;
  my $diagram_ref = $self->{diagram};
  my @diagram = @$diagram_ref;
  for (my $j=0;$j<$self->{rows};$j++) { # height
    for(my $k=0;$k<$self->{columns};$k++) { # width
      # Check position for across number
      # Left edge non-black followed by non-black
      if( ($k == 0 &&
           substr($diagram[$j],$k,1) ne '.' &&    # Row $j, Col 0 (k)
           substr($diagram[$j],$k+1,1) ne '.') || # Row $j, Col 1 (k+1)
        # Previous black - nonblack - nonblack
          ( ($k+1)<$self->{columns} &&  # Not last col
            ($k-1)>=0 &&                # Not first col
            substr($diagram[$j],$k,1) ne '.' &&
            substr($diagram[$j],$k-1,1) eq '.' &&
            substr($diagram[$j],$k+1,1) ne '.' ) ) {

        $across_start_squares{$square_num}++;
        $square_num++
      } else {
        $square_num++
      }
    }
  }

  # Down
  my %down_start_squares;
  $square_num = 0;
  for(my $k=0;$k<$self->{columns};$k++) { # width
    for (my $j=0;$j<$self->{rows};$j++) { # height
    # Check position for down number
      if( ($j == 0 &&                              # Row 0
           substr($diagram[$j],$k,1) ne '.' &&
           substr($diagram[$j+1],$k,1) ne '.') ||
          # Black above - nonblack - nonblack below
          ( ($j-1)>=0 &&                           # Not first row
            ($j+1)<$self->{rows} &&                # Not last row
            substr($diagram[$j],$k,1) ne '.' &&
            substr($diagram[$j-1],$k,1) eq '.' &&
            substr($diagram[$j+1],$k,1) ne '.' ) ) {

        $down_start_squares{$square_num}++;
        if( $j >= $self->{rows}-1 ) {
          # Last row
          $square_num = $k+1; # col+1
        } else {
          # Not last row
          $square_num += $self->{columns};
        }
      } else {
        if( $j >= $self->{rows}-1 ) {
          # Last row
          $square_num = $k+1; # col+1
        } else {
          # Not last row
          $square_num += $self->{columns};
        }
      }
    }
  }

  ##########################################################
  # Go back through grid from square 0 to square 
  # (rows x cols - 1) and set the clue number on each 
  # sqaure that is found in the across_start_squares and
  # down_start_square hashes from above.
  #
  # We create two versions....
  # 1) Row/Col - $clue_numbers[$row][$col] = $clue_number
  #    [0,0] to [14,14] for 15x15 ([0,0] to [rows-1,cols-1])
  # 2) Square Num  - $clue_numbers{$square} = $clue_number
  #    Square 0 to 224 for 15x15 (0 to row*cols-1)
  ###########################################################
  # Across
  my $counter = 0;
  my $clue_num = 1;
  my @clue_numbers;
  my %clue_numbers;
  for(my $row = 0; $row < $self->{rows}; $row++) {
    for(my $col = 0; $col < $self->{columns}; $col++) {
      if( $across_start_squares{$counter} || $down_start_squares{$counter} ) {
        # Hash - Square number
        $clue_numbers{$counter} = $clue_num;
        # Array - row/col
        $clue_numbers[$row][$col] = $clue_num;
        $clue_num++;
      }
      $counter++;
    }
  }

  # Now get data and set hash of hashes
  # Down
  my $start_row = 0;        # Square number - row
  my $start_col = 0;        # Square number - col
  my $start_square = 0;
  my $length = 0;           # Length of current solution word
  my $square = 0;           # Grid square
  my $sol_word = '';        # Solution word
  my $last_square = '';     # Contents of last square visted
  my $last_square_two = ''; # Contents of two squares back
  for(my $col = 0; $col < $self->{columns}; $col++) {
    for(my $row = 0; $row < $self->{rows}; $row++) {

      # If $sol_two[$row][$col] eq '.', then we *probably* want to
      # save our data...if $row == $self->{rows} - 1, then we
      # definitely want to.
      if ( $sol_two[$row][$col] eq '.' || $row >= $self->{rows} - 1 ) {

        # If this is the first square and it contains '.',
        # don't save our data. Just set a few vars and move on.
        if( $sol_two[$row][$col] eq '.' && $row == 0 ) {
          $square++;
          $last_square_two = $last_square;
          $last_square = '.';
          $start_row++;
          next;
        }

        # If this isn't first square in row, this square contains '.'
        # and the previous square contains '.', don't save data.
        # Just set a few vars and move on.
        if( $sol_two[$row][$col] eq '.' && $row != 0 && $last_square eq '.' ) {
          if( $row == $self->{rows} - 1 ) {
            $start_col++;
            $start_row = 0;
          } else {
            $start_row++;
          } 
          $square++;
          $last_square_two = $last_square;
          $last_square = '.';
          next;
        }

        # Get last square of each column
        if( $row == $self->{rows} - 1 ) {
          # If last square is '.', don't add to solution
          unless( $sol_two[$row][$col] eq '.' ) {
            $sol_word .= $sol_two[$row][$col];
            $length++;
          }
        }

        # NOTE: US crossword rules state clue must be at least three letters
        # We're checking the length is at least two, since some crosswords
        # are built that way...
        if( $length < 2 ) {
          # Reset variables
          $length = 0;
          $sol_word = '';
          if($row >= $self->{rows} - 1 ) {
            $start_col++;
            $start_row = 0;
          } else {
            $start_row = $row + 1;
          }
          next;
        }

        # Get key and clue nem
        my $clue_num = $clue_numbers[$start_row][$start_col];
        next unless defined $clue_num;
        my $key = $clue_num;

        # Store info into puzzle hash
        $self->{down}{$key}{length} = $length;
        $self->{down}{$key}{solution} = $sol_word;
        $self->{down}{$key}{row} = $start_row + 1;
        $self->{down}{$key}{column} = $start_col + 1;
        $self->{down}{$key}{clue_number} = $clue_num;

        # Reset variables
        $length = 0;
        $sol_word = '';
        if($row >= $self->{rows} - 1 ) {
          $start_col++;
          $start_row = 0;
        } else {
          $start_row = $row + 1;
        }
      } else {
        $sol_word .= $sol_two[$row][$col];
        $length++;
      }
      $square++;
      $last_square_two = $last_square;
      $last_square = $sol_two[$row][$col];
    }
  }

  # Return down hash 
  return ($self->{down});
}


sub parse_file {
  my($self) = shift;
  _parse_file($self);
}

sub _parse_file {
  my($self) = shift;
  my($buf, $parse_word, $oe);
  my($aclues, $dclues);

  my $PUZ_IN = $self->{in_file};

  open FH, $PUZ_IN or croak "Can't open $PUZ_IN: $!";
  binmode(FH); # Be nice to windoz

  # Skip unneeded data
  seek(FH, 44, 0);

  # Width and Height
  read(FH, $buf, 2);
  my ($width, $height) = unpack "C C", $buf;
  $self->{rows} = $height;
  $self->{columns} = $width;

  # Skip more unneeded data
  read(FH, $buf, 6);

  # Solution
  my @solution;
  my @solution_two; # two-dimensional array
  for(my $j=0; $j<$height; $j++) {
    my $twodim_col = 0;
    read(FH, $solution[$j], $width);
    my @letters = split(//,$solution[$j]);
    foreach my $letter (@letters) {
      $solution_two[$j][$twodim_col] = $letter;
      $twodim_col++;
    }
  }
  $self->{solution} = \@solution;
  $self->{solution_two} = \@solution_two;

  # Diagram
  my @diagram;
  for(my $j=0;$j<$height;$j++) {
    read(FH, $diagram[$j], $width);
  }
  $self->{diagram} = \@diagram;

  # Title
  $oe = 0;
  while(1) {
    read(FH, $buf, 1) or last;
    my ($char) = unpack "C", $buf;
    last if $char == 0;
    $parse_word .= $buf;
  }
  if( defined $parse_word ) {
    $parse_word =~ s/^\s+//;
    $parse_word =~ s/\s+$//;
    $self->{title} = $parse_word;
  } else {
    $self->{title} = '';
  }

  # Author
  $parse_word = '';
  $oe = 0;
  while(1) {
    read(FH, $buf, 1) or last;
    my ($char) = unpack "C", $buf;
    last if $char == 0;
    $parse_word .= $buf;
  }
  if( defined $parse_word ) {
    $parse_word =~ s/^\s+//;
    $parse_word =~ s/\s+$//;
    $self->{author} = $parse_word;
  } else {
    $self->{author} = '';
  }

  # Copyright
  $parse_word = '';
  $oe = 0;
  while(1) {
    read(FH, $buf, 1) or last;
    my ($char) = unpack "C", $buf;
    last if $char == 0;
    $parse_word .= $buf;
  }
  if( defined $parse_word ) {
    $parse_word =~ s/^\s+//;
    $parse_word =~ s/\s+$//;
    $self->{copyright} = $parse_word;
  } else {
    $self->{copyright} = '';
  }

  my $ccount = 0;

  # Check position for across number
  for (my $j=0;$j<$height;$j++) {
    my $rowtext;
    for(my $k=0;$k<$width;$k++) {
      # Check position for across number
      # Left edge non-black followed by non-black
      my $anum = 0; # across number
      if( ($k == 0 &&
           substr($diagram[$j],$k,1) ne '.' &&    # Row $j, Col 0 (k)
           substr($diagram[$j],$k+1,1) ne '.') || # Row $j, Col 1 (k+1)
        # Previous black - nonblack - nonblack
          ( ($k+1)<$width &&  # Not last col
            ($k-1)>=0 &&      # Not first col
            substr($diagram[$j],$k,1) ne '.' &&
            substr($diagram[$j],$k-1,1) eq '.' &&
            substr($diagram[$j],$k+1,1) ne '.' ) ) {

        $ccount++;
        $anum = $ccount;
      }

      # Check position for down number
      my $dnum = 0;
      if( ($j == 0 &&                              # Row 0
           substr($diagram[$j],$k,1) eq '-' &&
           substr($diagram[$j+1],$k,1) eq '-') ||
          # Black above - nonblack - nonblack below
          ( ($j-1)>=0 &&                           # Not first row
            ($j+1)<$height &&                      # Not last row
            substr($diagram[$j],$k,1) eq '-' &&
            substr($diagram[$j-1],$k,1) eq '.' &&
            substr($diagram[$j+1],$k,1) eq '-' ) ) {

        # Don't double number the same space
        if( $anum == 0 ) {
          $ccount++;
        }
        $dnum = $ccount;
      }

      # Get clues
      # Across
      if( $anum != 0 ) {
        my $tmp;
        $parse_word = '';
        $oe = 0;
        while(1) {
          read(FH, $buf, 1) or last;
          my ($char) = unpack "C", $buf;
          last if $char == 0;
          $parse_word .= $buf;
        }
        $parse_word =~ s/^\s+//;
        $parse_word =~ s/\s+$//;
        $tmp = $parse_word;
        $aclues .= "$anum - $tmp\n";

        my $key = "$anum";
        $self->{across}{$key}{direction} = 'across';
        $self->{across}{$key}{clue_number} = $anum;
        $self->{across}{$key}{clue} = $tmp;
      }
 
      # Down
      if( $dnum != 0 ) {
        my $tmp;
        $parse_word = '';
        $oe = 0;
        while(1) {
          read(FH, $buf, 1) or last;
          my ($char) = unpack "C", $buf;
          last if $char == 0;
          $parse_word .= $buf;
        }
        $parse_word =~ s/^\s+//;
        $parse_word =~ s/\s+$//;
        $tmp = $parse_word;
        $dclues .= "$dnum - $tmp\n";

        my $key = "$dnum";
        $self->{down}{$key}{direction} = 'down';
        $self->{down}{$key}{clue_number} = $dnum;
        $self->{down}{$key}{clue} = $tmp;
      }
    }
  }

  close FH;
  $self->{aclues} = $aclues;
  $self->{dclues} = $dclues;
  $self->{is_parsed} = 1;

}

sub is_parsed { 
  my($self) = shift;
  return $self->{is_parsed};
}

sub get_rows {
  my($self) = shift;
  _parse_file($self) unless $self->{is_parsed}; 
  return $self->{rows};
}

sub get_columns {
  my($self) = shift;
  _parse_file($self) unless $self->{is_parsed}; 
  return $self->{columns};
}

sub get_solution {
  my($self) = shift;
  _parse_file($self) unless $self->{is_parsed}; 
  my $solref = $self->{solution};
  my @sol = @$solref;
  return @sol;
}

sub get_diagram {
  my($self) = shift;
  _parse_file($self) unless $self->{is_parsed}; 
  my $diagref = $self->{diagram};
  my @diag = @$diagref;
  return @diag;
}

sub get_title {
  my($self) = shift;
  _parse_file($self) unless $self->{is_parsed}; 
  return $self->{title};
}

sub get_author {
  my($self) = shift;
  _parse_file($self) unless $self->{is_parsed}; 
  return $self->{author};
}

sub get_copyright {
  my($self) = shift;
  _parse_file($self) unless $self->{is_parsed}; 
  return $self->{copyright};
}

sub get_across_clues {
  my($self) = shift;
  _parse_file($self) unless $self->{is_parsed}; 
  return $self->{aclues};
}

sub get_down_clues {
  my($self) = shift;
  _parse_file($self) unless $self->{is_parsed}; 
  return $self->{dclues};
}

1;

__END__

=head1 NAME

Convert::AcrossLite - Convert binary AcrossLite puzzle files to text.

=head1 SYNOPSIS

  use Convert::AcrossLite;

  my $ac = Convert::AcrossLite->new();
  $ac->in_file('/home/doug/puzzles/Easy.puz');
  $ac->out_file('/home/doug/puzzles/Easy.txt');
  $ac->puz2text;

  or

  use Convert::AcrossLite;

  my $ac = Convert::AcrossLite->new();
  $ac->in_file('/home/doug/puzzles/Easy.puz');
  my $text = $ac->puz2text;

  or

  use Convert::AcrossLite;

  my $ac = Convert::AcrossLite->new();
  $ac->in_file('/home/doug/puzzles/Easy.puz');
  my $ac->parse_file;
  my $title = $ac->get_title;
  my $author = $ac->get_author;
  my $copyright = $ac->get_copyright;
  my @solution = $ac->get_solution;
  my @diagram = $ac->get_diagram;
  my $across_clues = $ac->get_across_clues;
  my $down_clues = $ac->get_down_clues;

  or

  use Convert::AcrossLite;

  my $ac = Convert::AcrossLite->new();
  $ac->in_file('/home/doug/puzzles/Easy.puz');

  my($across_hashref, $down_hashref) = get_across_down;

  my %across= %$across_hashref;
  foreach my $key (sort { $a <=> $b } keys %across) {
      print "Direction: $across{$key}{direction}\n";
      print "Clue Number: $across{$key}{clue_number}\n";
      print "Row: $across{$key}{row}\n";
      print "Col: $across{$key}{column}\n";
      print "Clue: $across{$key}{clue}\n";
      print "Solution: $across{$key}{solution}\n";
      print "Length: $across{$key}{length}\n\n";
  }

  my %down= %$down_hashref;
  foreach my $key (sort { $a <=> $b } keys %down) {
      print "Direction: $down{$key}{direction}\n";
      print "Clue Number: $down{$key}{clue_number}\n";
      print "Row: $down{$key}{row}\n";
      print "Col: $down{$key}{column}\n";
      print "Clue: $down{$key}{clue}\n";
      print "Solution: $down{$key}{solution}\n";
      print "Length: $down{$key}{length}\n\n";
  }


=head1 DESCRIPTION

Convert::AcrossLite is used to convert binary AcrossLite puzzle files to text.

Convert::AcrossLite is loosely based on the C program written by Bob Newell (http://www.gtoal.com/wordgames/gene/AcrossLite).

=head1 CONSTRUCTOR

=head2 new

This is the contructor. You can pass the full path to the puzzle input file.

  my $ac = Convert::AcrossLite->new(in_file => '/home/doug/puzzles/Easy.puz');

The default value is 'Default.puz'.

=head1 METHODS

=head2 in_file

This method returns the current puzzle input path/filename. 

  my $in_filename = $ac->in_file;

You may also set the puzzle input file by passing the path/filename.

  $ac->in_file('/home/doug/puzzles/Easy.puz');

=head2 out_file

This method returns the current puzzle output path/filename. 

  my $out_filename = $ac->out_file;

You may also set the puzzle output file by passing the path/filename.

  $ac->out_file('/home/doug/puzzles/Easy.txt');


=head2 puz2text

This method will produce a basic text file in the same format as the easy.txt file provided with AcrossLite. This method will read the input file set by in_file and write to the file set by out_file. 

  $ac->puz2text;

If out_file is not set, then the text is returned.

  print $ac->puz2text;

  or

  my $text = $ac->puz2text;

=head2 get_across_down

This method will get all the information needed to build any type of output 
you may need(some info is set by parse_file): direction (across/down), 
clue_number, clue, solution, solution length, grid row and column. This method 
will return two hash references (across and down).

  my($across_hashref, $down_hashref) = get_across_down;

  my %across= %$across_hashref;
  foreach my $key (sort { $a <=> $b } keys %across) {
      print "Direction: $across{$key}{direction}\n";
      print "Clue Number: $across{$key}{clue_number}\n";
      print "Row: $across{$key}{row}\n";
      print "Col: $across{$key}{column}\n";
      print "Clue: $across{$key}{clue}\n";
      print "Solution: $across{$key}{solution}\n";
      print "Length: $across{$key}{length}\n\n";
  }

  my %down= %$down_hashref;
  foreach my $key (sort { $a <=> $b } keys %down) {
      print "Direction: $down{$key}{direction}\n";
      print "Clue Number: $down{$key}{clue_number}\n";
      print "Row: $down{$key}{row}\n";
      print "Col: $down{$key}{column}\n";
      print "Clue: $down{$key}{clue}\n";
      print "Solution: $down{$key}{solution}\n";
      print "Length: $down{$key}{length}\n\n";
  }

=head2 get_across

This method will return all the across information (some info is set by
parse_file): direction, clue_number, clue, solution, solution length, 
grid row and column. This method will return a hash reference.

  my $across_hashref = get_across;
 
  my %across= %$across_hashref;
  foreach my $key (sort { $a <=> $b } keys %across) {
      print "Direction: $across{$key}{direction}\n";
      print "Clue Number: $across{$key}{clue_number}\n";
      print "Row: $across{$key}{row}\n";
      print "Col: $across{$key}{column}\n";
      print "Clue: $across{$key}{clue}\n";
      print "Solution: $across{$key}{solution}\n";
      print "Length: $across{$key}{length}\n\n";
  }


=head2 get_down

This method will return all the down information (some info is set by
parse_file): direction, clue_number, clue, solution, solution length, 
grid row and column. This method will return a hash reference.

  my $down_hashref = get_down;

  my %down= %$down_hashref;
  foreach my $key (sort { $a <=> $b } keys %down) {
      print "Direction: $down{$key}{direction}\n";
      print "Clue Number: $down{$key}{clue_number}\n";
      print "Row: $down{$key}{row}\n";
      print "Col: $down{$key}{column}\n";
      print "Clue: $down{$key}{clue}\n";
      print "Solution: $down{$key}{solution}\n";
      print "Length: $down{$key}{length}\n\n";
  }

=head2 parse_file

This method will parse the puzzle file by calling _parse_file. 

=head2 is_parsed

This method returns file parse status: 0 if input file has not been parsed, 1 if input file has been parsed.

=head2 get_rows

This method returns the number of rows in puzzle.

  my $rows = $ac->get_rows;

=head2 get_columns

This method returns the number of columns in puzzle.

  my $columns = $ac->get_columns;

=head2 get_solution

This method returns the puzzle solution.

  my @solution = $ac->get_solution;

=head2 get_diagram

This method returns the puzzle solution diagram.

  my @solution = $ac->get_diagram;

=head2 get_title

This method returns the puzzle title.

  my $title = $ac->get_title;

=head2 get_author

This method returns the puzzle author.

  my $author = $ac->get_author;

=head2 get_copyright

This method returns the puzzle copyright.

  my $copyright = $ac->get_copyright;

=head2 get_across_clues

This method returns the puzzle across clues.

  my $across_clues = $ac->get_across_clues;

=head2 get_down_clues

This method returns the puzzle down clues.

  my $down_clues = $ac->get_down_clues;

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Convert::AcrossLite

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Convert-AcrossLite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Convert-AcrossLite>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Convert-AcrossLite>

=item * Search CPAN

L<http://search.cpan.org/dist/Convert-AcrossLite>

=back

=head1 ACKNOWLEDGEMENTS

Changed C<eq '-'> to C<ne '.'> so filled-in puzzles will parse
Patch from Ed Santiago

=head1 AUTHOR

Doug Sparling E<lt>F<doug@dougsparling.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 2006 Douglas Sparling. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
