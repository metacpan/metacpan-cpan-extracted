package AlignDB::ToXLSX;
use Moose;
use Carp;
use YAML::Syck;

use Excel::Writer::XLSX;
use Statistics::Descriptive;
use Chart::Math::Axis;
use List::Util qw();
use List::MoreUtils qw();

our $VERSION = '1.2.1';

# Mysql dbh
has dbh => ( is => 'ro', isa => 'Object' );

# outfiles
has outfile  => ( is => 'ro', isa => 'Str' );        # output file, autogenerable
has workbook => ( is => 'ro', isa => 'Object' );     # excel workbook object
has format   => ( is => 'ro', isa => 'HashRef' );    # excel formats

# worksheet cursor
has row    => ( is => 'rw', isa => 'Num', default => sub {0}, );
has column => ( is => 'rw', isa => 'Num', default => sub {0}, );

# charts
has font_name => ( is => 'rw', isa => 'Str', default => sub {'Arial'}, );
has font_size => ( is => 'rw', isa => 'Num', default => sub {10}, );
has width     => ( is => 'rw', isa => 'Num', default => sub {320}, );
has height    => ( is => 'rw', isa => 'Num', default => sub {320}, );
has max_ticks => ( is => 'rw', isa => 'Int', default => sub {6} );

# Replace texts in titles
has replace => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub BUILD {
    my $self = shift;

    # set outfile
    unless ( $self->{outfile} ) {
        $self->{outfile} = "auto.xlsx";
    }

    # Create $workbook object
    my $workbook;
    unless ( $workbook = Excel::Writer::XLSX->new( $self->{outfile} ) ) {
        confess "Cannot create Excel file.\n";
        return;
    }
    $self->{workbook} = $workbook;

    # set $workbook format
    my %font = (
        font => $self->{font_name},
        size => $self->{font_size},
    );
    my %header = (
        align    => 'center',
        bg_color => 42,
        bold     => 1,
        bottom   => 2,
    );
    my $format = {
        HEADER => $workbook->add_format( %header, %font, ),
        HIGHLIGHT => $workbook->add_format( color => 'blue',  %font, ),
        NORMAL    => $workbook->add_format( color => 'black', %font, ),
        NAME      => $workbook->add_format( bold  => 1,       color => 57, %font, ),
        TOTAL     => $workbook->add_format( bold  => 1,       top => 2, %font, ),
        DATE => $workbook->add_format(
            align      => 'left',
            bg_color   => 42,
            bold       => 1,
            num_format => 'yyyy-mm-dd hh:mm',
            %font,
        ),
        URL       => $workbook->add_format( color => 'blue', underline => 1, %font, ),
        URLHEADER => $workbook->add_format( color => 'blue', underline => 1, %header, %font, ),
    };
    $self->{format} = $format;

    return;
}

sub increase_row {
    my $self = shift;
    my $step = shift || 1;

    $self->{row} += $step;
}

sub increase_column {
    my $self = shift;
    my $step = shift || 1;

    $self->{column} += $step;
}

#@returns Excel::Writer::XLSX::Worksheet
sub write_header {
    my $self       = shift;
    my $sheet_name = shift;
    my $opt        = shift;

    # init
    #@type Excel::Writer::XLSX::Workbook
    my $workbook = $self->{workbook};

    #@type Excel::Writer::XLSX::Worksheet
    my $sheet  = $workbook->add_worksheet($sheet_name);
    my $format = $self->{format};

    my $header     = $opt->{header};
    my $query_name = $opt->{query_name};

    # create table header
    for ( my $i = 0; $i < $self->{column}; $i++ ) {
        $sheet->write( $self->{row}, $i, $query_name, $format->{HEADER} );
    }
    for ( my $i = 0; $i < scalar @{$header}; $i++ ) {
        $sheet->write( $self->{row}, $i + $self->{column}, $header->[$i], $format->{HEADER} );
    }
    $sheet->freeze_panes( 1, 0 );    # freeze table

    $self->increase_row;
    return $sheet;
}

sub sql2names {
    my $self = shift;
    my $sql  = shift;
    my $opt  = shift;

    # bind value
    my $bind_value = $opt->{bind_value};
    if ( !defined $bind_value ) {
        $bind_value = [];
    }

    #@type DBI
    my $dbh = $self->{dbh};

    #@type DBI
    my $sth = $dbh->prepare($sql);
    $sth->execute( @{$bind_value} );
    my @names = @{ $sth->{'NAME'} };

    return @names;
}

sub write_row {
    my $self = shift;

    #@type Excel::Writer::XLSX::Worksheet
    my $sheet = shift;
    my $opt   = shift;

    # init
    my $format = $self->{format};

    # query name
    my $query_name = $opt->{query_name};
    if ( defined $query_name ) {
        $sheet->write( $self->{row}, $self->{column} - 1, $query_name, $format->{NAME} );
    }

    # array_ref
    my $row = $opt->{row};

    # insert table
    for ( my $i = 0; $i < scalar @$row; $i++ ) {
        $sheet->write( $self->{row}, $i + $self->{column}, $row->[$i], $format->{NORMAL} );
    }

    $self->increase_row;
    return;
}

sub write_column {
    my $self = shift;

    #@type Excel::Writer::XLSX::Worksheet
    my $sheet = shift;
    my $opt   = shift;

    # init
    my $format = $self->{format};

    # query name
    my $query_name = $opt->{query_name};
    if ( defined $query_name ) {
        $sheet->write( $self->{row} - 1, $self->{column}, $query_name, $format->{NAME} );
    }

    # array_ref
    my $column = $opt->{column};

    # insert table
    $sheet->write( $self->{row}, $self->{column}, [$column], $format->{NORMAL} );

    $self->increase_column;
    return;
}

sub write_sql {
    my $self = shift;

    #@type Excel::Writer::XLSX::Worksheet
    my $sheet = shift;
    my $opt   = shift;

    # init
    my $format = $self->{format};

    # query name
    my $query_name = $opt->{query_name};
    if ( defined $query_name ) {
        $sheet->write( $self->{row}, $self->{column} - 1, $query_name, $format->{NAME} );
    }

    # bind value
    my $bind_value = $opt->{bind_value};
    if ( !defined $bind_value ) {
        $bind_value = [];
    }

    # init DBI query
    my $sql_query = $opt->{sql_query};

    #@type DBI
    my $dbh = $self->{dbh};

    #@type DBI
    my $sth = $dbh->prepare($sql_query);
    $sth->execute( @{$bind_value} );

    # init $data
    my $data;
    if ( exists $opt->{data} ) {
        if ( defined $opt->{data} and ref( $opt->{data} ) eq 'ARRAY' ) {
            $data = $opt->{data};
        }
        else {
            $data = [];
            push @{$data}, [] for @{ $sth->{'NAME'} };
        }
    }

    # insert table rows
    while ( my @row = $sth->fetchrow_array ) {
        for ( my $i = 0; $i < scalar @row; $i++ ) {
            if ( exists $opt->{data} ) {
                push @{ $data->[$i] }, $row[$i];
            }
            $sheet->write( $self->{row}, $i + $self->{column}, $row[$i], $format->{NORMAL} );
        }
        $self->increase_row;
    }

    return $data;
}

sub make_combine {
    my $self = shift;
    my $opt  = shift;

    # init parameters
    my $sql_query  = $opt->{sql_query};
    my $threshold  = $opt->{threshold};
    my $standalone = $opt->{standalone};

    # bind value
    my $bind_value = $opt->{bind_value};
    unless ( defined $bind_value ) {
        $bind_value = [];
    }

    # merge_last
    my $merge_last = $opt->{merge_last};
    unless ( defined $merge_last ) {
        $merge_last = 0;
    }

    # init DBI query
    #@type DBI
    my $dbh = $self->{dbh};

    #@type DBI
    my $sth = $dbh->prepare($sql_query);
    $sth->execute(@$bind_value);

    my @row_count = ();
    while ( my @row = $sth->fetchrow_array ) {
        push @row_count, \@row;
    }

    my @combined;    # return these
    my @temp_combined = ();
    my $temp_count    = 0;
    foreach my $row_ref (@row_count) {
        if ( List::MoreUtils::PP::any { $_ eq $row_ref->[0] } @{$standalone} ) {
            push @combined, [ $row_ref->[0] ];
        }
        elsif ( $temp_count < $threshold ) {
            push @temp_combined, $row_ref->[0];
            $temp_count += $row_ref->[1];

            if ( $temp_count < $threshold ) {
                next;
            }
            else {
                push @combined, [@temp_combined];
                @temp_combined = ();
                $temp_count    = 0;
            }
        }
        else {
            warn "Errors occured in calculating combined distance.\n";
        }
    }

    # Write the last weighted row which COUNT might
    #   be smaller than $threshold
    if ( $temp_count > 0 ) {
        if ($merge_last) {
            if ( @combined == 0 ) {
                @combined = ( [] );
            }
            push @{ $combined[-1] }, @temp_combined;
        }
        else {
            push @combined, [@temp_combined];
        }
    }

    return \@combined;
}

sub make_combine_piece {
    my ( $self, $opt ) = @_;

    #@type DBI
    my $dbh = $self->{dbh};

    # init parameters
    my $sql_query = $opt->{sql_query};
    my $piece     = $opt->{piece};

    # bind value
    my $bind_value = $opt->{bind_value};
    unless ( defined $bind_value ) {
        $bind_value = [];
    }

    # init DBI query
    #@type DBI
    my $sth = $dbh->prepare($sql_query);
    $sth->execute(@$bind_value);

    my @row_count = ();
    while ( my @row = $sth->fetchrow_array ) {
        push @row_count, \@row;
    }

    my $sum;
    $sum += $_->[1] for @row_count;
    my $small_chunk = $sum / $piece;

    my @combined;    # return these
    my @temp_combined = ();
    my $temp_count    = 0;
    for my $row_ref (@row_count) {
        if ( $temp_count < $small_chunk ) {
            push @temp_combined, $row_ref->[0];
            $temp_count += $row_ref->[1];

            if ( $temp_count >= $small_chunk ) {
                push @combined, [@temp_combined];
                @temp_combined = ();
                $temp_count    = 0;
            }
        }
        else {
            warn "Errors occured in calculating combined distance.\n";
        }
    }

    # Write the last weighted row which COUNT might
    #   be smaller than $threshold
    if ( $temp_count > 0 ) {
        push @combined, [@temp_combined];
    }

    return \@combined;
}

sub make_last_portion {
    my ( $self, $opt ) = @_;

    #@type DBI
    my $dbh = $self->{dbh};

    # init parameters
    my $sql_query = $opt->{sql_query};
    my $portion   = $opt->{portion};

    # init DBI query
    #@type DBI
    my $sth = $dbh->prepare($sql_query);
    $sth->execute;

    my @row_count = ();
    while ( my @row = $sth->fetchrow_array ) {
        push @row_count, \@row;
    }

    my @last_portion;    # return @last_portion
    my $all_length = 0;  # return $all_length
    foreach (@row_count) {
        $all_length += $_->[2];
    }
    my @rev_row_count = reverse @row_count;
    my $temp_length   = 0;
    foreach (@rev_row_count) {
        push @last_portion, $_->[0];
        $temp_length += $_->[2];
        if ( $temp_length >= $all_length * $portion ) {
            last;
        }
    }

    return ( $all_length, \@last_portion );
}

sub excute_sql {
    my ( $self, $opt ) = @_;

    # bind value
    my $bind_value = $opt->{bind_value};
    unless ( defined $bind_value ) {
        $bind_value = [];
    }

    # init DBI query
    my $sql_query = $opt->{sql_query};

    #@type DBI
    my $dbh = $self->{dbh};

    #@type DBI
    my $sth = $dbh->prepare($sql_query);
    $sth->execute( @{$bind_value} );
}

sub check_column {
    my ( $self, $table, $column ) = @_;

    # init
    #@type DBI
    my $dbh = $self->{dbh};

    {    # check table existing
        my @table_names = $dbh->tables( '', '', '' );

        # table names are quoted by ` (back-quotes) which is the
        #   quote_identifier
        my $table_name = "`$table`";
        unless ( List::MoreUtils::PP::any { $_ =~ /$table_name/i } @table_names ) {
            print " " x 4, "Table $table does not exist\n";
            return 0;
        }
    }

    {    # check column existing
        my $sql_query = qq{
            SHOW FIELDS
            FROM $table
            LIKE "$column"
        };

        #@type DBI
        my $sth = $dbh->prepare($sql_query);
        $sth->execute();
        my ($field) = $sth->fetchrow_array;

        if ( not $field ) {
            print " " x 4, "Column $column does not exist\n";
            return 0;
        }
    }

    {    # check values in column
        my $sql_query = qq{
            SELECT COUNT($column)
            FROM $table
        };

        #@type DBI
        my $sth = $dbh->prepare($sql_query);
        $sth->execute;
        my ($count) = $sth->fetchrow_array;

        if ( not $count ) {
            print " " x 4, "Column $column has no records\n";
        }

        return $count;
    }
}

sub quantile {
    my ( $self, $data, $part_number ) = @_;

    my $stat = Statistics::Descriptive::Full->new();

    $stat->add_data(@$data);

    my $min = $stat->min;
    my @quantiles;
    my $base = 100 / $part_number;
    for ( 1 .. $part_number - 1 ) {
        my $percentile = $stat->percentile( $_ * $base );
        push @quantiles, $percentile;
    }
    my $max = $stat->max;

    return [ $min, @quantiles, $max, ];
}

sub quantile_sql {
    my ( $self, $opt, $part_number ) = @_;

    #@type DBI
    my $dbh = $self->{dbh};

    # bind value
    my $bind_value = $opt->{bind_value};
    unless ( defined $bind_value ) {
        $bind_value = [];
    }

    # init DBI query
    my $sql_query = $opt->{sql_query};

    #@type DBI
    my $sth = $dbh->prepare($sql_query);
    $sth->execute(@$bind_value);

    my @data;

    while ( my @row = $sth->fetchrow_array ) {
        push @data, $row[0];
    }

    return $self->quantile( \@data, $part_number );
}

sub calc_threshold {
    my $self = shift;

    my ( $combine, $piece );

    #@type DBI
    my $dbh = $self->{dbh};

    #@type DBI
    my $sth = $dbh->prepare(
        q{
        SELECT SUM(FLOOR(align_comparables / 500) * 500)
        FROM align
        }
    );
    $sth->execute;
    my ($total_length) = $sth->fetchrow_array;

    if ( $total_length <= 5_000_000 ) {
        $piece = 10;
    }
    elsif ( $total_length <= 10_000_000 ) {
        $piece = 10;
    }
    elsif ( $total_length <= 100_000_000 ) {
        $piece = 20;
    }
    elsif ( $total_length <= 1_000_000_000 ) {
        $piece = 50;
    }
    else {
        $piece = 100;
    }

    if ( $total_length <= 1_000_000 ) {
        $combine = 100;
    }
    elsif ( $total_length <= 5_000_000 ) {
        $combine = 500;
    }
    else {
        $combine = 1000;
    }

    return ( $combine, $piece );
}

# See HACK #7 in OReilly.Excel.Hacks.2nd.Edition.
sub add_index_sheet {
    my $self = shift;

    #@type Excel::Writer::XLSX::Workbook
    my $workbook = $self->{workbook};
    my $format   = $self->{format};

    # existing sheets
    my @sheets = $workbook->sheets();

    # create a new worksheet named "INDEX"
    my $sheet_name = "INDEX";

    #@type Excel::Writer::XLSX::Worksheet
    my $index_sheet = $workbook->add_worksheet($sheet_name);

    # set hyperlink column with large width
    $index_sheet->set_column( 'A:A', 20 );

    #   0    1    2     3     4    5     6     7     8
    #($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
    #                                            localtime(time);
    my $date = sprintf "%4d-%02d-%02dT%02d:%02d", (localtime)[5] + 1900, (localtime)[4] + 1,
        (localtime)[ 3, 2, 1 ];
    $index_sheet->write_date_time( 'A1', $date, $format->{DATE} );

    for my $i ( 0 .. $#sheets ) {

        #@type Excel::Writer::XLSX::Worksheet
        my $cur_sheet = $sheets[$i];
        my $cur_name  = $cur_sheet->get_name;

        # $worksheet->write_url( $row, $col, $url, $format, $label )
        $index_sheet->write_url( $i + 1, 0, "internal:$cur_name!A1", $format->{URL}, $cur_name );

        $cur_sheet->write_url( "A1", "internal:INDEX!A" . ( $i + 2 ),
            $format->{URLHEADER}, "INDEX" );
    }

    return;
}

sub draw_y {
    my $self = shift;

    #@type Excel::Writer::XLSX::Worksheet
    my $sheet = shift;
    my $opt   = shift;

    #@type Excel::Writer::XLSX::Workbook
    my $workbook   = $self->{workbook};
    my $sheet_name = $sheet->get_name;

    my $font_name = $opt->{font_name} || $self->{font_name};
    my $font_size = $opt->{font_size} || $self->{font_size};
    my $height    = $opt->{height}    || $self->{height};
    my $width     = $opt->{width}     || $self->{width};

    # E2
    my $top  = $opt->{top}  || 1;
    my $left = $opt->{left} || 4;

    # 0 based
    my $first_row     = $opt->{first_row};
    my $last_row      = $opt->{last_row};
    my $x_column      = $opt->{x_column};
    my $y_column      = $opt->{y_column};
    my $y_last_column = $opt->{y_last_column};
    unless ( defined $y_last_column ) {
        $y_last_column = $y_column;
    }

    # Set axes' scale
    my $x_max_scale = $opt->{x_max_scale};
    my $x_min_scale = $opt->{x_min_scale};
    if ( !defined $x_min_scale ) {
        $x_min_scale = 0;
    }
    if ( !defined $x_max_scale and exists $opt->{x_scale_unit} ) {
        my $x_scale_unit = $opt->{x_scale_unit};
        my $x_min_value  = List::Util::min( @{ $opt->{x_data} } );
        my $x_max_value  = List::Util::max( @{ $opt->{x_data} } );
        $x_min_scale = int( $x_min_value / $x_scale_unit ) * $x_scale_unit;
        $x_max_scale = ( int( $x_max_value / $x_scale_unit ) + 1 ) * $x_scale_unit;
    }

    my $y_scale;
    if ( exists $opt->{y_data} ) {
        $y_scale = $self->_find_scale( $opt->{y_data}, $first_row, $last_row );
    }

    #@type Excel::Writer::XLSX::Chart
    my $chart = $workbook->add_chart(
        type     => 'scatter',
        subtype  => 'straight_with_markers',
        embedded => 1
    );

    # [ $sheetname, $row_start, $row_end, $col_start, $col_end ]
    #  #"=$sheetname" . '!$A$2:$A$7',
    for my $y_col ( $y_column .. $y_last_column ) {
        $chart->add_series(
            categories => [ $sheet_name, $first_row, $last_row, $x_column, $x_column ],
            values     => [ $sheet_name, $first_row, $last_row, $y_col,    $y_col ],
        );
    }
    $chart->set_size( width => $width, height => $height );

    # Remove title and legend
    $chart->set_title( none => 1 );
    $chart->set_legend( none => 1 );

    # Blank data is shown as a gap
    $chart->show_blanks_as('gap');

    # set axis
    $chart->set_x_axis(
        name      => $self->_replace_text( $opt->{x_title} ),
        name_font => { name => $font_name, size => $font_size, },
        num_font  => { name => $font_name, size => $font_size, },
        line            => { color   => 'black', },
        major_gridlines => { visible => 0, },
        minor_gridlines => { visible => 0, },
        major_tick_mark => 'inside',
        min             => $x_min_scale,
        max             => $x_max_scale,
        exists $opt->{cross} ? ( crossing => $opt->{cross}, ) : (),
    );
    $chart->set_y_axis(
        name      => $self->_replace_text( $opt->{y_title} ),
        name_font => { name => $font_name, size => $font_size, },
        num_font  => { name => $font_name, size => $font_size, },
        line            => { color   => 'black', },
        major_gridlines => { visible => 0, },
        minor_gridlines => { visible => 0, },
        major_tick_mark => 'inside',
        defined $y_scale
        ? ( min => $y_scale->{min}, max => $y_scale->{max}, major_unit => $y_scale->{unit}, )
        : (),
    );

    # plorarea
    $chart->set_plotarea( border => { color => 'black', }, );

    $sheet->insert_chart( $top, $left, $chart );

    return;
}

sub draw_2y {
    my $self = shift;

    #@type Excel::Writer::XLSX::Worksheet
    my $sheet = shift;
    my $opt   = shift;

    #@type Excel::Writer::XLSX::Workbook
    my $workbook   = $self->{workbook};
    my $sheet_name = $sheet->get_name;

    my $font_name = $opt->{font_name} || $self->{font_name};
    my $font_size = $opt->{font_size} || $self->{font_size};
    my $height    = $opt->{height}    || $self->{height};
    my $width     = $opt->{width}     || $self->{width};

    # E2
    my $top  = $opt->{top}  || 1;
    my $left = $opt->{left} || 4;

    # 0 based
    my $first_row = $opt->{first_row};
    my $last_row  = $opt->{last_row};
    my $x_column  = $opt->{x_column};
    my $y_column  = $opt->{y_column};
    my $y2_column = $opt->{y2_column};

    # Set axes' scale
    my $x_max_scale = $opt->{x_max_scale};
    my $x_min_scale = $opt->{x_min_scale};
    if ( !defined $x_min_scale ) {
        $x_min_scale = 0;
    }
    if ( !defined $x_max_scale and exists $opt->{x_scale_unit} ) {
        my $x_scale_unit = $opt->{x_scale_unit};
        my $x_min_value  = List::Util::min( @{ $opt->{x_data} } );
        my $x_max_value  = List::Util::max( @{ $opt->{x_data} } );
        $x_min_scale = int( $x_min_value / $x_scale_unit ) * $x_scale_unit;
        $x_max_scale = ( int( $x_max_value / $x_scale_unit ) + 1 ) * $x_scale_unit;
    }

    my $y_scale;
    if ( exists $opt->{y_data} ) {
        $y_scale = $self->_find_scale( $opt->{y_data}, $first_row, $last_row );
    }

    my $y2_scale;
    if ( exists $opt->{y2_data} ) {
        $y2_scale = $self->_find_scale( $opt->{y2_data}, $first_row, $last_row );
    }

    #@type Excel::Writer::XLSX::Chart
    my $chart = $workbook->add_chart(
        type     => 'scatter',
        subtype  => 'straight_with_markers',
        embedded => 1
    );

    # [ $sheetname, $row_start, $row_end, $col_start, $col_end ]
    #  #"=$sheetname" . '!$A$2:$A$7',
    $chart->add_series(
        categories => [ $sheet_name, $first_row, $last_row, $x_column, $x_column ],
        values     => [ $sheet_name, $first_row, $last_row, $y_column, $y_column ],
    );

    # second Y axis
    $chart->add_series(
        categories => [ $sheet_name, $first_row, $last_row, $x_column,  $x_column ],
        values     => [ $sheet_name, $first_row, $last_row, $y2_column, $y2_column ],
        marker  => { type => 'square', size => 6, fill => { color => 'white', }, },
        y2_axis => 1,
    );
    $chart->set_size( width => $width, height => $height );

    # Remove title and legend
    $chart->set_title( none => 1 );
    $chart->set_legend( none => 1 );

    # Blank data is shown as a gap
    $chart->show_blanks_as('gap');

    # set axis
    $chart->set_x_axis(
        name      => $self->_replace_text( $opt->{x_title} ),
        name_font => { name => $font_name, size => $font_size, },
        num_font  => { name => $font_name, size => $font_size, },
        line            => { color   => 'black', },
        major_gridlines => { visible => 0, },
        minor_gridlines => { visible => 0, },
        major_tick_mark => 'inside',
        min             => $x_min_scale,
        max             => $x_max_scale,
    );
    $chart->set_y_axis(
        name      => $self->_replace_text( $opt->{y_title} ),
        name_font => { name => $font_name, size => $font_size, },
        num_font  => { name => $font_name, size => $font_size, },
        line            => { color   => 'black', },
        major_gridlines => { visible => 0, },
        minor_gridlines => { visible => 0, },
        major_tick_mark => 'inside',
        defined $y_scale
        ? ( min => $y_scale->{min}, max => $y_scale->{max}, major_unit => $y_scale->{unit}, )
        : (),
    );
    $chart->set_y2_axis(
        name      => $self->_replace_text( $opt->{y2_title} ),
        name_font => { name => $font_name, size => $font_size, },
        num_font  => { name => $font_name, size => $font_size, },
        line            => { color   => 'black', },
        major_gridlines => { visible => 0, },
        minor_gridlines => { visible => 0, },
        major_tick_mark => 'inside',
        defined $y2_scale
        ? ( min => $y2_scale->{min}, max => $y2_scale->{max}, major_unit => $y2_scale->{unit}, )
        : (),
    );

    # plorarea
    $chart->set_plotarea( border => { color => 'black', }, );

    $sheet->insert_chart( $top, $left, $chart );

    return;
}

sub draw_xy {
    my $self = shift;

    #@type Excel::Writer::XLSX::Worksheet
    my $sheet = shift;
    my $opt   = shift;

    #@type Excel::Writer::XLSX::Workbook
    my $workbook   = $self->{workbook};
    my $sheet_name = $sheet->get_name;

    my $font_name = $opt->{font_name} || $self->{font_name};
    my $font_size = $opt->{font_size} || $self->{font_size};
    my $height    = $opt->{height}    || $self->{height};
    my $width     = $opt->{width}     || $self->{width};

    # trendline
    my $add_trend = $opt->{add_trend};

    # E2
    my $top  = $opt->{top}  || 1;
    my $left = $opt->{left} || 4;

    # 0 based
    my $first_row = $opt->{first_row};
    my $last_row  = $opt->{last_row};
    my $x_column  = $opt->{x_column};
    my $y_column  = $opt->{y_column};

    my $x_scale;
    if ( exists $opt->{x_data} ) {
        $x_scale = $self->_find_scale( $opt->{x_data}, $first_row, $last_row );

    }
    my $y_scale;
    if ( exists $opt->{y_data} ) {
        $y_scale = $self->_find_scale( $opt->{y_data}, $first_row, $last_row );
    }

    #@type Excel::Writer::XLSX::Chart
    my $chart = $workbook->add_chart( type => 'scatter', embedded => 1 );

    # [ $sheetname, $row_start, $row_end, $col_start, $col_end ]
    #  #"=$sheetname" . '!$A$2:$A$7',
    $chart->add_series(
        categories => [ $sheet_name, $first_row, $last_row, $x_column, $x_column ],
        values     => [ $sheet_name, $first_row, $last_row, $y_column, $y_column ],
        marker => { type => 'diamond' },
        $add_trend
        ? ( trendline => {
                type => 'linear',
                name => 'Linear Trend',
            }
            )
        : (),
    );
    $chart->set_size( width => $width, height => $height );

    # Remove title and legend
    $chart->set_title( none => 1 );
    $chart->set_legend( none => 1 );

    # Blank data is shown as a gap
    $chart->show_blanks_as('gap');

    # set axis
    $chart->set_x_axis(
        name      => $self->_replace_text( $opt->{x_title} ),
        name_font => { name => $font_name, size => $font_size, },
        num_font  => { name => $font_name, size => $font_size, },
        line            => { color   => 'black', },
        major_gridlines => { visible => 0, },
        minor_gridlines => { visible => 0, },
        major_tick_mark => 'inside',
        defined $x_scale
        ? ( min => $x_scale->{min}, max => $x_scale->{max}, major_unit => $x_scale->{unit}, )
        : (),
    );
    $chart->set_y_axis(
        name      => $self->_replace_text( $opt->{y_title} ),
        name_font => { name => $font_name, size => $font_size, },
        num_font  => { name => $font_name, size => $font_size, },
        line            => { color   => 'black', },
        major_gridlines => { visible => 0, },
        minor_gridlines => { visible => 0, },
        major_tick_mark => 'inside',
        defined $y_scale
        ? ( min => $y_scale->{min}, max => $y_scale->{max}, major_unit => $y_scale->{unit}, )
        : (),
    );

    # plorarea
    $chart->set_plotarea( border => { color => 'black', }, );

    $sheet->insert_chart( $top, $left, $chart );

    return;
}

sub draw_dd {
    my $self = shift;

    #@type Excel::Writer::XLSX::Worksheet
    my $sheet = shift;
    my $opt   = shift;

    #@type Excel::Writer::XLSX::Workbook
    my $workbook   = $self->{workbook};
    my $sheet_name = $sheet->get_name;

    my $font_name = $opt->{font_name} || $self->{font_name};
    my $font_size = $opt->{font_size} || $self->{font_size};
    my $height    = $opt->{height}    || $self->{height};
    my $width     = $opt->{width}     || $self->{width};

    # E2
    my $top  = $opt->{top}  || 1;
    my $left = $opt->{left} || 4;

    # 0 based
    my $first_row     = $opt->{first_row};
    my $last_row      = $opt->{last_row};
    my $x_column      = $opt->{x_column};
    my $y_column      = $opt->{y_column};
    my $y_last_column = $opt->{y_last_column};
    unless ( defined $y_last_column ) {
        $y_last_column = $y_column;
    }

    # Set axes' scale
    my $x_max_scale = $opt->{x_max_scale};
    my $x_min_scale = $opt->{x_min_scale};
    if ( !defined $x_min_scale ) {
        $x_min_scale = 0;
    }
    if ( !defined $x_max_scale and exists $opt->{x_scale_unit} ) {
        my $x_scale_unit = $opt->{x_scale_unit};
        my $x_min_value  = List::Util::min( @{ $opt->{x_data} } );
        my $x_max_value  = List::Util::max( @{ $opt->{x_data} } );
        $x_min_scale = int( $x_min_value / $x_scale_unit ) * $x_scale_unit;
        $x_max_scale = ( int( $x_max_value / $x_scale_unit ) + 1 ) * $x_scale_unit;
    }

    my $y_scale;
    if ( exists $opt->{y_data} ) {
        $y_scale = $self->_find_scale( $opt->{y_data} );
    }

    #@type Excel::Writer::XLSX::Chart
    my $chart = $workbook->add_chart(
        type     => 'line',
        embedded => 1
    );

    # [ $sheetname, $row_start, $row_end, $col_start, $col_end ]
    #  #"=$sheetname" . '!$A$2:$A$7',
    for my $y_col ( $y_column .. $y_last_column ) {
        $chart->add_series(
            categories => [ $sheet_name, $first_row, $last_row, $x_column, $x_column ],
            values     => [ $sheet_name, $first_row, $last_row, $y_col,    $y_col ],
        );
    }
    $chart->set_size( width => $width, height => $height );

    # Remove title and legend
    $chart->set_title( none => 1 );
    $chart->set_legend( none => 1 );

    # Blank data is shown as a gap
    $chart->show_blanks_as('gap');

    # set axis
    $chart->set_x_axis(
        name      => $self->_replace_text( $opt->{x_title} ),
        name_font => { name => $font_name, size => $font_size, },
        num_font  => { name => $font_name, size => $font_size, },
        line            => { color   => 'black', },
        major_gridlines => { visible => 0, },
        minor_gridlines => { visible => 0, },
        major_tick_mark => 'inside',
        min             => $x_min_scale,
        max             => $x_max_scale,
        exists $opt->{cross} ? ( crossing => $opt->{cross}, ) : (),
    );
    $chart->set_y_axis(
        name      => $self->_replace_text( $opt->{y_title} ),
        name_font => { name => $font_name, size => $font_size, },
        num_font  => { name => $font_name, size => $font_size, },
        line            => { color   => 'black', },
        major_gridlines => { visible => 0, },
        minor_gridlines => { visible => 0, },
        major_tick_mark => 'inside',
        defined $y_scale
        ? ( min => $y_scale->{min}, max => $y_scale->{max}, major_unit => $y_scale->{unit}, )
        : (),
    );

    # plorarea
    $chart->set_plotarea( border => { color => 'black', }, );

    $sheet->insert_chart( $top, $left, $chart );

    return;
}

sub _find_scale {
    my $self      = shift;
    my $dataset   = shift;
    my $first_row = shift;
    my $last_row  = shift;

    my $axis = Chart::Math::Axis->new;

    my @data;
    if ( !defined $first_row ) {
        if ( ref $dataset->[0] eq 'ARRAY' ) {
            for ( @{$dataset} ) {
                push @data, @{$_};
            }
        }
        else {
            push @data, @{$dataset};
        }
    }
    else {
        if ( ref $dataset->[0] eq 'ARRAY' ) {
            for ( @{$dataset} ) {
                my @copy = @{$_};
                push @data, splice( @copy, $first_row - 1, $last_row - $first_row + 1 );
            }
        }
        else {
            my @copy = @{$dataset};
            push @data, splice( @copy, $first_row - 1, $last_row - $first_row + 1 );
        }
    }

    $axis->add_data(@data);
    $axis->set_maximum_intervals( $self->{max_ticks} );

    return {
        max  => $axis->top,
        min  => $axis->bottom,
        unit => $axis->interval_size,
    };
}

sub _replace_text {
    my $self    = shift;
    my $text    = shift;
    my $replace = $self->{replace};

    for my $key ( keys %$replace ) {
        my $value = $replace->{$key};
        $text =~ s/$key/$value/gi;
    }

    return $text;
}

# instance destructor
# invoked only as object method
sub DESTROY {
    my $self = shift;

    # close excel objects
    #@type Excel::Writer::XLSX::Workbook
    my $workbook = $self->{workbook};
    $workbook->close if $workbook;

    # close dbh
    #@type DBI
    my $dbh = $self->{dbh};
    $dbh->disconnect if $dbh;

    return;
}

1;

__END__

=head1 NAME

AlignDB::ToXLSX - Create xlsx files from arrays or SQL queries.

=head1 SYNOPSIS

    # Mysql
    my $write_obj = AlignDB::ToXLSX->new(
        outfile => $outfile,
        dbh     => $dbh,
    );

    # MongoDB
    my $write_obj = AlignDB::ToXLSX->new(
        outfile => $outfile,
    );

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
