package Bio::Gonzales::Matrix::IO;

use warnings;
use strict;
use Carp;
use Data::Dumper;
use List::MoreUtils qw/uniq zip/;
use Bio::Gonzales::Util qw/flatten/;
use Text::CSV_XS qw/csv/;

use Bio::Gonzales::Matrix::Util qw/uniq_rows/;

use 5.010;

use List::Util qw/max/;
use Bio::Gonzales::Util::File qw/open_on_demand slurpc expand_home/;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.062'; # VERSION

@EXPORT      = qw(mslurp mspew lslurp miterate lspew dict_slurp dict_spew xcsv_slurp miterate_hash);
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(lspew xlsx_slurp xlsx_spew);
my $COMMENT_RE = qr/^\s*#/;

sub dict_slurp {
  my ( $src, $cc ) = @_;
  croak "you have not specified key_idx"
    unless ( $cc && exists( $cc->{key_idx} ) );

  $cc //= {};
  my %c = (
    sep              => qr/\t/,
    header           => undef,
    skip             => -1,
    comment          => $COMMENT_RE,
    key_idx          => 0,
    record_filter    => undef,
    commented_header => undef,
    concat_keys      => 1,
    sort_keys        => 0,
    strict           => 0,
    %$cc
  );

  $c{header} //= $c{commented_header};

  my $is_strict     = $c{strict};
  my $record_filter = $c{record_filter};

  # concatenate keys to a big string
  my @kidcs;
  if ( $c{concat_keys} || !ref( $c{key_idx} ) ) {
    @kidcs = ( $c{key_idx} );
  } else {
    # or treat them separately
    @kidcs = @{ $c{key_idx} };
  }

  my $vidx = $c{val_idx};
  # make an array from it

  my $uniq = $c{uniq} // $c{uniq_vals} // $c{unique} // 0;

  my ( $fh, $fh_was_open ) = open_on_demand( $src, '<' );

  my @header;
  if ( $c{header} ) {
    while ( my $raw_row = <$fh> ) {
      if ( $c{comment} && $raw_row =~ /$c{comment}/ ) {
        if ( $c{commented_header} ) {
          $raw_row =~ s/$c{comment}//;
        } else {
          next;
        }
      }
      $raw_row =~ s/\r$//;
      chomp $raw_row;
      @header = split /$c{sep}/, $raw_row;
      @header = ref $vidx ? @header[@$vidx] : ( $header[$vidx] ) if ( defined $vidx && $vidx ne 'all' );
      last;
    }
  }

  my %map;
  my $lnum = 0;
  while (<$fh>) {
    next if ( $lnum++ <= $c{skip} );
    next if ( $c{comment} && /$c{comment}/ );
    s/\r$//;
    chomp;
    next if (/^\s*$/);

    next if ( $record_filter && !$record_filter->($_) );

    my @r = split /$c{sep}/;

    for my $kidx (@kidcs) {

      my @k = ( ref $kidx ? @r[@$kidx] : $r[$kidx] );
      @k = map { $_ // '' } @k;
      @k = sort @k if ( $c{sort_keys} );
      my $k = join( $;, @k ) // '';

      if ( $uniq && !defined($vidx) ) {
        $map{$k} = 1;
      } elsif ( not defined $vidx ) {
        $map{$k}++;
      } elsif ($uniq) {
        confess "strict mode: two times the same key $k" if ( $is_strict && defined( $map{$k} ) );
        $map{$k} = ( ref $vidx ? [ @r[@$vidx] ] : ( $vidx eq 'all' ? \@r : $r[$vidx] ) );
      } else {
        $map{$k} //= [];
        push @{ $map{$k} }, ( ref $vidx ? [ @r[@$vidx] ] : ( $vidx eq 'all' ? \@r : $r[$vidx] ) );
      }
    }
  }

  $fh->close unless ($fh_was_open);
  return wantarray ? ( \%map, \@header ) : \%map;
}

sub dict_spew {
  my ( $dest, $m, $c ) = @_;

  my $uniq = $c->{uniq} // $c->{uniq_vals} // 0;

  my @flat;
  while ( my ( $k, $vv ) = each %$m ) {
    # $v => [ a, b, c] or $v => a or $v => [ [ a, b ], [c, d], ...]
    $vv = [$vv] unless ( ref $vv );
    my $vals = [ map { ref $_ ? $_ : [$_] } @$vv ];
    $vals = uniq_rows($vals) if ($uniq);
    for my $v (@$vals) {
      push @flat, [ $k, @$v ];
    }
  }
  return mspew( $dest, \@flat, $c );
}

sub mslurp {
  my ( $src, $cc ) = @_;
  my @m;

  my ( $fh, $fh_was_open ) = open_on_demand( $src, '<' );

  $cc //= {};
  my %c = (
    sep              => qr/\t/,
    header           => 0,
    skip             => -1,
    row_names        => 0,
    comment          => $COMMENT_RE,
    commented_header => undef,
    record_filter    => undef,
    col_idx          => undef,
    %$cc
  );

  my $record_filter = $c{record_filter};

  my @col_idx;
  @col_idx = @{ $c{col_idx} } if ( $c{col_idx} && ref $c{col_idx} eq 'ARRAY' );
  my @header;
  my @row_names;

  if ( $c{header} ) {
    while ( my $raw_row = <$fh> ) {
      if ( $c{comment} && $raw_row =~ /$c{comment}/ ) {
        if ( $c{commented_header} ) {
          $raw_row =~ s/$c{comment}//;
        } else {
          next;
        }
      }

      $raw_row =~ s/\r\n/\n/;
      chomp $raw_row;
      @header = split /$c{sep}/, $raw_row;
      last;
    }
  }

  my $lnum = 0;
  while (<$fh>) {
    next if ( $lnum++ <= $c{skip} );
    next if ( $c{comment} && /$c{comment}/ );
    s/\r\n/\n/;
    chomp;
    next if (/^\s*$/);

    next if ( $record_filter && !$record_filter->($_) );

    my @row = split /$c{sep}/;

    push @row_names, shift @row if ( $c{row_names} );

    push @m, ( @col_idx ? [ @row[@col_idx] ] : \@row );
  }
  $fh->close unless ($fh_was_open);

  #remove first empty element of a header if same number of elements as first matrix element.
  shift @header if ( $c{row_names} && $c{header} && @m > 0 && @{ $m[0] } == @header && !$header[0] );

  if (wantarray) {
    return ( \@m, ( @header ? \@header : undef ), ( @row_names ? \@row_names : undef ) );
  } else {
    return \@m;
  }
}

sub xcsv_slurp {
  my ( $src, $c ) = @_;

  my ( $fh, $fh_was_open ) = open_on_demand( $src, '<' );

  my $data = do { local $/; <$fh> }
    or confess "No data to analyze\n";
  $fh->close unless ($fh_was_open);

  $c->{sep} //=
      $data =~ m/["\d],["\d,]/ ? ","
    : $data =~ m/["\d];["\d;]/ ? ";"
    : $data =~ m/["\d]\t["\d]/ ? "\t"
    :
    # If neither, then for unquoted strings
      $data =~ m/\w,[\w,]/ ? ","
    : $data =~ m/\w;[\w;]/ ? ";"
    : $data =~ m/\w\t[\w]/ ? "\t"
    :                        ",";
  open my $dfh, '<', \$data or die "Can't open filehandle: $!";
  my $aoa = csv( in => $dfh, sep_char => $c->{sep}, quote_char => '"', escape_char => '"' );
  close $dfh;
  return $aoa;
}

sub miterate {
  my ( $src, $cc ) = @_;
  my ( $fh, $fh_was_open ) = open_on_demand( $src, '<' );

  $cc //= {};
  my %c = (
    sep           => qr/\t/,
    skip          => 0,
    comment       => $COMMENT_RE,
    record_filter => undef,
    %$cc
  );

  my $record_filter = $c{record_filter};

  return sub {
    while (<$fh>) {

      next if ( --$c{skip} >= 0 );

      next if ( $c{comment} && /$c{comment}/ );
      s/\r\n/\n/;
      chomp;
      next if (/^\s*$/);
      next if ( $record_filter && !$record_filter->($_) );

      my @row = split /$c{sep}/;
      return \@row;

    }
    $fh->close unless ($fh_was_open);
    return;
  };
}

sub miterate_hash {
  my $mit = miterate(@_);

  my $header = $mit->();

  return sub {
    my ( $from_idx, $to_idx ) = @_;

    my $row = $mit->();
    return unless ($row);

    if ( defined($from_idx) && defined($to_idx) ) {
      my @h = @{$header}[ $from_idx .. $to_idx ];
      my @r = @{$row}[ $from_idx .. $to_idx ];
      return { zip @h, @r };
    } else {
      return { zip @$header, @$row };
    }

  }, $header;
}

sub lspew {
  my ( $dest, $l, $c ) = @_;
  my $delim = $c->{sep} // $c->{delim} // "\t";
  my $header = $c->{header} // $c->{ids};
  my ( $fh, $fh_was_open ) = open_on_demand( $dest, '>' );

  say $fh join( $delim, @$header ) if ( $header && @$header > 0 );

  if ( ref $l eq 'HASH' ) {
    while ( my ( $k, $v ) = each %$l ) {
      if ( ref $v eq 'ARRAY' ) {
        say $fh join $delim, ( $k, @$v );
      } else {
        say $fh join $delim, ( $k, $v );
      }
    }
  } elsif ( ref $l eq 'ARRAY' ) {
    for my $v (@$l) {
      if ( ref $v eq 'ARRAY' ) {
        say $fh join $delim, @$v;
      } else {
        say $fh $v;
      }
    }

  } else {
    confess "need a reference for the list argument";
  }
  $fh->close unless ($fh_was_open);

  return;
}

sub lslurp {
  my ($file) = @_;

  my @lines = slurpc($file);
  return \@lines;
}

sub mspew {
  my ( $dest, $m, $c ) = @_;

  confess "no matrix, you need to supply a matrix of the form [ [ 1,2,3 ], [ 4,5,6 ], ... ]"
    unless ($m);

  my $header    = $c->{header}    // $c->{ids};
  my $rownames  = $c->{row_names} // $c->{rownames};
  my $square    = $c->{square};
  my $fill_rows = $c->{fill_rows} // 1;
  my $sep       = $c->{sep}       // "\t";
  my $na_value  = $c->{missing}   // $c->{na_value} // 'NA';
  my $quote_is_on = $c->{quote};

  # get the number of rows
  my $num_rows = scalar @$m;
  # find the longest column
  my $num_cols = max - 1, map { defined $_ ? scalar @$_ : -1 } @$m;

  # if the header is longer, it defines the number of cols
  $num_cols = max $num_cols, scalar @$header if ( $header && @$header > 0 );

  $rownames = $header
    if ( $header && @$header > 0 && $rownames && !ref $rownames && @$header >= @$m );

  # adjust num rows if rownames are longer than the
  $num_rows = scalar @$rownames if ( ref $rownames eq 'ARRAY' && @$rownames > $num_rows );

  if ($square) {
    $num_rows = $num_cols if ( $num_cols > $num_rows );
    $num_cols = $num_rows if ( $num_rows > $num_cols );
    #add one for the id in the first row
    $num_cols++ if ($rownames);
  }

  confess "error with rownames: not an array"
    if ( $rownames && !( ref $rownames eq 'ARRAY' && @$rownames >= @$m ) );
  confess "no matrix" unless ( defined $m );

  my ( $fh, $fh_was_open ) = open_on_demand( $dest, '>' );

  #print header if we have header
  if ($header) {
    my @qhead = @{ _quote( $header, $quote_is_on, $na_value ) };
    unshift @qhead, '' if ( $rownames && !$c->{r_style_header} );
    say $fh join $sep, @qhead;
  }

  #iterate through rows
  for ( my $i = 0; $i < $num_rows; $i++ ) {
    my @r;
    #add rowname as first column if desired
    push @r, ( $rownames->[$i] // "no_name" ) if ($rownames);
    #add the values
    push @r, @{ $m->[$i] // [] } if ( $i < @$m );
    #fill the square if desired
    if ( $square || $fill_rows ) {
      my $missing = $num_cols - @r;
      push @r, (undef) x $missing;
    }
    #print row
    say $fh join $sep, @{ _quote( \@r, $quote_is_on, $na_value ) };
  }
  $fh->close unless ($fh_was_open);
  return;
}

sub _quote {
  my ( $f, $q, $na ) = @_;
  $na = "$na" if ( $q && defined $na );
  my @fields = map {
    if ( !defined ) {
      $na;
    } elsif ( !$q || /^\d+$/ ) {
      $_;
    } else {
      ( my $str = $_ ) =~ s/"/""/g;
      qq{"$str"};
    }
  } @$f;
  return \@fields;
}

sub xlsx_spew {
  my ( $dest, $m, $c ) = @_;
  #eval "use Excel::Writer::XLSX";
  #die "could not load Excel::Writer::XLSX $@" if ($@);
  eval "use Excel::Writer::XLSX; 1" or confess "could not load Excel::Writer::XLSX";

  my $header   = $c->{header}    // $c->{ids};
  my $rownames = $c->{row_names} // $c->{rownames};
  my $sep      = $c->{sep}       // "\t";
  my $na_value = $c->{missing}   // $c->{na_value} // 'NA';

  $rownames = $header
    if ( $header && @$header > 0 && $rownames && !ref $rownames && @$header == @$m );

  my @table;
  #print header if we have header
  if ($header) {
    my @qhead = @$header;
    unshift @qhead, '' if ($rownames);
    push @table, \@qhead;
  }

  #iterate through rows
  for ( my $i = 0; $i < @$m; $i++ ) {
    my @r;
    #add rowname as first column if desired
    push @r, $rownames->[$i] if ($rownames);
    #add the values
    push @r, @{ $m->[$i] };
    #fill the square if desired

    #print row
    push @table, [ map { $_ // $na_value } @r ];
  }

  my ( $fh, $fh_was_open ) = open_on_demand( $dest, '>' );

  my $workbook  = Excel::Writer::XLSX->new($fh);
  my $worksheet = $workbook->add_worksheet();
  $worksheet->keep_leading_zeros() if ( $c->{keep_leading_zeros} );
  $worksheet->write_col( 'A1', \@table );
  $workbook->close;
  $fh->close unless ($fh_was_open);
  return;
}

sub xlsx_slurp {
  my ( $src, $cc ) = @_;
  #my @m;
  #my ( $fh, $fh_was_open ) = open_on_demand( $src, '<' );

  eval "use Spreadsheet::ParseXLSX; 1" or confess "could not load Spreadsheet::ParseXLSX";

  $src = expand_home($src) if ( !ref($src) );

  my $parser   = Spreadsheet::ParseXLSX->new;
  my $workbook = $parser->parse($src);
  if ( !defined $workbook ) {
    confess $parser->error(), ".\n";
  }

  my @ws;
  for my $worksheet ( $workbook->worksheets() ) {
    my @w;
    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();
    for ( my $i = $row_min; $i <= $row_max; $i++ ) {
      my @r;
      for ( my $j = $col_min; $j <= $col_max; $j++ ) {
        my $e = $worksheet->get_cell( $i, $j );
        push @r, ( defined($e) ? $e->unformatted : undef );
      }
      push @w, \@r;
    }
    push @ws, \@w;
  }
  return \@ws;
}

1;

__END__

=head1 NAME

Bio::Gonzales::Matrix::IO - Library for simple matrix IO


=head1 SYNOPSIS

    use Bio::Gonzales::Matrix::IO qw(lspew mslurp lslurp mspew);

=head1 DESCRIPTION

Provides functions for common matrix/list IO.

=head1 SUBROUTINES

=over 4

=item B<< dict_slurp($filename, \%options) >>

  %options = (
    sep     => qr/\t/,
    header  => 0,
    skip    => -1,
    comment => qr/^\s*#/,
    key_idx => 0,
    val_idx => undef,
    uniq    => 0,
    record_filter => undef,
    concat_keys => 1,
    strict => 0
  );

Setups:

=over 4

=item uniq = 1 && no val_idx => read in key_idx as hash and set values to 1

=item uniq = 0 && no val_idx => read in key_idx as hash and set values to the count of keys

=item uniq = 1 && val_idx    =>  read into ( key => [ @values ], ...)

=item uniq = 0 && val_idx    =>  read into ( key => [ [ @values ], [ @more_values ] ], ...)

=item concat_keys

Concatenate the keys by C<< $; >>. If set to 0, key columns are taken in a
serial fashion and are merged to one big column.

=item uniq = 1 && strict = 1 => confess if two times the same key occurs in the data.

=back

If key_idx is an array, the keys columns are joined by C<$;> to build the hash key.



=item B<< mspew($filename, \@matrix, \%options) >>

=item B<< mspew($filehandle, \@matrix, \%options) >>

Save the values in C<@matrix> to a C<$filename> or C<$filehandle>. C<@matrix>
is an array of arrayrefs:

    @matrix = (
        [ l11, l12, l13 ],
        [ l21, l22, l23 ],
        [ l31, l32, l33 ]
    );

Options:

=over 4

=item header / ids

Supply a header. Same as 

     mspew($file, [ \@header, @matrix ])

=item row_names

Supply row names or if not an array but true, use the header as row names

    mspew( $file, $matrix, { row_names => 1 } );                            #use header
    mspew( $file, $matrix, { row_names => [ 'row1', '...', 'rown' ] } );    #use supplied row names


=item fill_missing_cols

If a row has less columns than the longest row of the matrix, fill it up with empty strings.

=item na_value

Use this value in case undefined values are found. Default is 'NA'.

=item sep

Set a separator for the output file

=item square (default 1)

Add empty columns to fill up to a square.

=back

=item B<< $matrix_ref = mslurp($file, \%config) >>

=item B<< ($matrix_ref, $header_ref, $row_names_ref) = mslurp($file, \%config) >>

Reads in the contents of C<$file> and puts it in a array of arrayrefs.

You can set the delimiter via the configuration by supplying C<< { sep => qr/\t/ } >> as config hash.

Further options with defaults:

    %config = (
        sep => qr/\t/, # set column separator
        header => 0, # parse header
        skip => 0, # skip the first N lines (without header)
        row_names => 0, # parse row names
        comment => qr/^\s*#/ # the comment character
        record_filter => undef # set a function to filter records
    );
    
=item B<< lspew($fh_or_filename, $list, $config_options) >>

spews out a list of values to a file. It can handle filenames and filehandles,
but if you supply a handle, you have to close it on your own. The C<$list> can
be a 

=over 4

=item hash ref of array refs

results in
    keya    avalue0 avalue1
    keyb    bvalue0 bvalue1
    ...

=item hash ref

results in
    keya    valuea
    keyb    valueb
    ...

=item array ref

results in
    value0
    value1
    ...

=back

C<$config_options> is a hash ref. It can take the options:

    $config_options = {
        delim => "\t",
    };


=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
