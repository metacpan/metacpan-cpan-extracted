package # hide from PAUSE
App::DBBrowser::Table::Insert;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '1.056';

use Cwd        qw( realpath );
use Encode     qw( encode decode );
use File::Temp qw( tempfile );
use List::Util qw( all );

use List::MoreUtils    qw( first_index );
use Encode::Locale     qw();
#use Spreadsheet::Read  qw( ReadData rows ); # "require"d
use Term::Choose       qw();
use Term::Choose::Util qw( choose_a_number choose_a_file );
use Term::Form         qw();
use Text::CSV          qw();

use App::DBBrowser::Auxil;



sub new {
    my ( $class, $info, $opt ) = @_;
    bless { info => $info, opt => $opt }, $class;
}


sub __get_insert_columns {
    my ( $self, $sql, $sql_type ) = @_;
    my $auxil  = App::DBBrowser::Auxil->new( $self->{info} );
    my $stmt_h = Term::Choose->new( $self->{info}{lyt_stmt_h} );
    my $pr_columns = $sql->{print}{columns};
    my $qt_columns = $sql->{quote}{columns};
    $sql->{quote}{insert_cols} = [];
    $sql->{print}{insert_cols} = [];
    my @cols = ( @$pr_columns );

    COL_NAMES: while ( 1 ) {
        my @pre = ( $self->{info}{ok} );
        my $choices = [ @pre, @cols ];
        $auxil->__print_sql_statement( $sql, $sql_type );
        # Choose
        my @idx = $stmt_h->choose(
            $choices,
            { prompt => 'Columns:', index => 1, no_spacebar => [ 0 .. $#pre ] }
        );
        if ( ! defined $idx[0] || ! defined $choices->[$idx[0]] ) {
            return if ! @{$sql->{quote}{insert_cols}};
            $sql->{quote}{insert_cols} = [];
            $sql->{print}{insert_cols} = [];
            @cols = ( @$pr_columns );
            next COL_NAMES;
        }
        my $c = 0;
        for my $i ( @idx ) {
            last if ! @cols;
            my $ni = $i - ( @pre + $c );
            splice( @cols, $ni, 1 );
            ++$c;
        }
        my @print_col = map { $choices->[$_] } @idx;
        if ( $print_col[0] eq $self->{info}{ok} ) {
            shift @print_col;
            for my $print_col ( @print_col ) {
                push @{$sql->{quote}{insert_cols}}, $qt_columns->{$print_col};
                push @{$sql->{print}{insert_cols}}, $print_col;
            }
            if ( ! @{$sql->{quote}{insert_cols}} ) {
                @{$sql->{quote}{insert_cols}} = @{$qt_columns}{@$pr_columns};
                @{$sql->{print}{insert_cols}} = @$pr_columns;
            }
            last COL_NAMES;
        }
        for my $print_col ( @print_col ) {
            push @{$sql->{quote}{insert_cols}}, $qt_columns->{$print_col};
            push @{$sql->{print}{insert_cols}}, $print_col;
        }
    }
    return 1;
}


sub __get_insert_values {
    my ( $self, $sql, $sql_type ) = @_;
    my $auxil  = App::DBBrowser::Auxil->new( $self->{info} );
    my $stmt_h = Term::Choose->new( $self->{info}{lyt_stmt_h} );
    $sql->{quote}{insert_into_args} = [];
    my $trs = Term::Form->new();

    VALUES: while ( 1 ) {
        my $input_mode;
        if ( @{$self->{opt}{insert}{input_modes}} == 1 ) {
            $input_mode = $self->{opt}{insert}{input_modes}[0];
        }
        else {
            my $stmt_v = Term::Choose->new( $self->{info}{lyt_stmt_v} );
            $auxil->__print_sql_statement( $sql, $sql_type );
            # Choose
            $input_mode = $stmt_v->choose(
                [ undef, map( "- $_", @{$self->{opt}{insert}{input_modes}} ) ],
                { prompt => 'Input mode: ', justify => 0 }
            );
            if ( ! defined $input_mode ) {
                $sql->{quote}{insert_cols} = [];
                $sql->{print}{insert_cols} = [];
                return;
            }
            $input_mode =~ s/^-\ //;
        }
        if ( $input_mode =~ /^(?:Cols|Rows)\z/ ) {
            my @cols;
            if ( $input_mode eq 'Cols' ) {
                if ( $sql_type eq 'Create_table' ) {
                    $auxil->__print_sql_statement( $sql, $sql_type );
                    # Readline
                    my $nr_of_cols = choose_a_number( 3, { name => 'Number of columns:', current => 0 } );
                    next VALUES if ! $nr_of_cols;
                    @cols = map { 'Col_' . $_ } 1 .. $nr_of_cols;
                }
                else {
                    @cols = @{$sql->{print}{insert_cols}};
                }
            }

            ROWS: while ( 1 ) {
                if ( $input_mode eq 'Cols' ) {
                    my $input_row_idx = @{$sql->{quote}{insert_into_args}};
                    COLS: for my $col_name ( @cols ) {
                        $auxil->__print_sql_statement( $sql, $sql_type );
                        # Readline
                        my $col = $trs->readline( $col_name . ': ' );
                        push @{$sql->{quote}{insert_into_args}->[$input_row_idx]}, $col; # show $col immediately in "print_sql_statement"
                    }
                }
                elsif ( $input_mode eq 'Rows' ) {
                    my $csv = Text::CSV->new( { map { $_ => $self->{opt}{insert}{$_} } @{$self->{info}{csv_opt}} } );
                    $auxil->__print_sql_statement( $sql, $sql_type );
                    # Readline
                    my $row = $trs->readline( 'Row: ' );
                    if ( ! defined $row ) {
                        next VALUES if ! @{$sql->{quote}{insert_into_args}};
                        $#{$sql->{quote}{insert_into_args}}--;
                        next ROWS;
                    }
                    my $status = $csv->parse( $row );
                    push @{$sql->{quote}{insert_into_args}}, [ $csv->fields() ];
                }
                my $default = ( all { ! length } @{$sql->{quote}{insert_into_args}[-1]} ) ? 2 : 1;

                ASK: while ( 1 ) {
                    my ( $last, $add, $del ) = ( '-OK-', 'Add', 'Del' );
                    my $choices = [ $last, $add, $del ];
                    $auxil->__print_sql_statement( $sql, $sql_type );
                    # Choose
                    my $add_row = $stmt_h->choose(
                        $choices,
                        { prompt => '', default => $default }
                    );
                    if ( ! defined $add_row ) {
                        $sql->{quote}{insert_into_args} = [];
                        next VALUES;
                    }
                    elsif ( $add_row eq $last ) {
                        if ( ! @{$sql->{quote}{insert_into_args}} ) {
                            $sql->{quote}{insert_cols} = [];
                            $sql->{print}{insert_cols} = [];
                        }
                        last VALUES;
                    }
                    elsif ( $add_row eq $del ) {
                        next VALUES if ! @{$sql->{quote}{insert_into_args}};
                        $default = 0;
                        $#{$sql->{quote}{insert_into_args}}--;
                        next ASK;
                    }
                    last ASK;
                }
            }
        }
        else {
            if ( $input_mode eq 'Multi-row' ) {
                my ( $fh, $file ) = tempfile( DIR => $self->{info}{app_dir}, UNLINK => 1 , SUFFIX => '.csv' );
                binmode $fh, ':encoding(' . $self->{opt}{insert}{file_encoding} . ')' or die $!;
                $auxil->__print_sql_statement( $sql, $sql_type );
                # STDIN
                print 'Multi row: ' . "\n";
                while ( my $row = <STDIN> ) {
                    print $fh $row;
                }
                seek $fh, 0, 0;
                $self->__get_insert_into_args( $sql, $sql_type, $fh );
                if ( ! @{$sql->{quote}{insert_into_args}} ) {
                    if ( @{$self->{opt}{insert}{input_modes}} == 1 ) {
                        $sql->{quote}{insert_cols} = [];
                        $sql->{print}{insert_cols} = [];
                        return;
                    }
                    next VALUES;
                }
                last VALUES;
            }
            elsif ( $input_mode eq 'File' ) {
                my ( $file );
                FILE: while ( 1 ) {
                    my @files;
                    if ( $self->{opt}{insert}{max_files} && -e $self->{info}{input_files} ) {
                        open my $fh_in, '<:encoding(locale_fs)', $self->{info}{input_files} or die $!;
                        while ( my $fl = <$fh_in> ) {
                            chomp $fl;
                            next if ! -e $fl;
                            push @files, $fl;
                        }
                        close $fh_in;
                    }
                    my @files_sorted = sort map { decode 'locale_fs', $_ } @files;
                    if ( length $file ) {
                        my $i = first_index { decode( 'locale_fs', $file ) eq $_ } @files_sorted;
                        splice @files_sorted, $i, 1 if $i > -1;
                        unshift @files_sorted, decode 'locale_fs', $file;
                    }
                    my $add_file = 'New file';
                    if ( @files_sorted ) {
                        $auxil->__print_sql_statement( $sql, $sql_type );
                        # Choose
                        $file = $stmt_h->choose(
                            [ undef, '  ' . $add_file, map( "- $_", @files_sorted ) ],
                            { %{$self->{info}{lyt_stmt_v}} }
                        );
                        if ( ! defined $file ) {
                            if ( @{$self->{opt}{insert}{input_modes}} == 1 ) {
                                $sql->{quote}{insert_cols} = [];
                                $sql->{print}{insert_cols} = [];
                                return;
                            }
                            next VALUES;
                        }
                        $file =~ s/^.\s//;
                    }
                    if ( ! defined $file || $file eq $add_file ) {
                        $auxil->__print_sql_statement( $sql, $sql_type );
                        # Choose_a_file
                        $file = choose_a_file( { dir => $self->{opt}{insert}{files_dir} } );
                        if ( ! defined $file || ! length $file ) {
                            if ( @{$self->{opt}{insert}{input_modes}} == 1 ) {
                                $sql->{quote}{insert_cols} = [];
                                $sql->{print}{insert_cols} = [];
                                return;
                            }
                            next VALUES;
                        }
                        $file = realpath encode 'locale_fs', $file;
                        if ( $self->{opt}{insert}{max_files} ) {
                            my $i = first_index { $file eq $_ } @files;
                            splice @files, $i, 1 if $i > -1;
                            push @files, $file;
                            while ( @files > $self->{opt}{insert}{max_files} ) {
                                shift @files;
                            }
                            open my $fh_out, '>:encoding(locale_fs)', $self->{info}{input_files} or die $!; # '>:encoding(locale_fs)'
                            for my $fl ( @files ) {
                                print $fh_out $fl . "\n";
                            }
                            close $fh_out;
                        }
                    }
                    else {
                        $file = realpath encode 'locale_fs', $file;
                    }

                    if ( $self->{opt}{insert}{parse_mode} < 2 && -T $file ) {
                        open my $fh, '<:encoding(' . $self->{opt}{insert}{file_encoding} . ')', $file or die $!;
                        if ( -z $file ) {
                            my $cm = Term::Choose->new( { %{$self->{info}{lyt_stop}}, prompt => 'Press ENTER' } );
                            $cm->choose( [ 'empty file!' ] );
                            close $fh;
                            next FILE;
                        }
                        $self->__get_insert_into_args( $sql, $sql_type, $fh );
                        close $fh;
                    }
                    else {
                        $self->__get_insert_into_args( $sql, $sql_type, $file );
                    }
                    next FILE if ! @{$sql->{quote}{insert_into_args}}; #
                    last VALUES;
                }
            }
        }
    }
    return 1;
}


sub __get_insert_into_args {
    my ( $self, $sql, $sql_type, $file_or_fh ) = @_;
    my $auxil = App::DBBrowser::Auxil->new( $self->{info} );

    SHEET: while ( 1 ) {
        my ( $nr_of_sheets, $sheet_idx ) = $self->__parse_file( $sql, $sql_type, $file_or_fh );
        last SHEET if ! @{$sql->{quote}{insert_into_args}};
        my $stmt_h = Term::Choose->new( $self->{info}{lyt_stmt_h} );

        FILTER: while ( 1 ) {
            my @pre = ( undef, $self->{info}{ok} );
            my ( $input_cols, $input_rows_choose, $input_rows_range, $cols_to_rows, $reset ) = ( 'Columns', 'Rows-choose', 'Rows-range', 'Cols_to_Rows', 'Reset' );
            my $choices = [ @pre, $input_cols, $input_rows_choose, $input_rows_range, $cols_to_rows, $reset ];
            $auxil->__print_sql_statement( $sql, $sql_type );
            # Choose
            my $filter = $stmt_h->choose(
                $choices,
                { prompt => 'Filter:' }
            );
            if ( ! defined $filter ) {
                $sql->{quote}{insert_into_args} = [];
                last SHEET if ! $nr_of_sheets || $nr_of_sheets < 2;
                next SHEET;
            }
            elsif ( $filter eq $reset ) {
                $self->__parse_file( $sql, $sql_type, $file_or_fh, $sheet_idx );
                next FILTER
            }
            elsif ( $filter eq $self->{info}{ok} ) {
                last SHEET;
            }
            elsif ( $filter eq $input_cols  ) {
                my @col_idx;

                COLS: while ( 1 ) {
                    my @pre = ( $self->{info}{ok} );
                    my $choices = [ @pre, map { "col_$_" } 1 .. @{$sql->{quote}{insert_into_args}[0]} ];
                    my $prompt = 'Cols: ';
                    $prompt .= join ',', map { $_ + 1 } @col_idx if @col_idx;
                    $auxil->__print_sql_statement( $sql, $sql_type );
                    # Choose
                    my @chosen = $stmt_h->choose(
                        $choices,
                        { prompt => $prompt, no_spacebar => [ 0 .. $#pre ] }
                    );
                    if ( ! defined $chosen[0] ) {
                        if ( @col_idx ) {
                            @col_idx = ();
                            next COLS;
                        }
                        else {
                            next FILTER;
                        }
                    }
                    if ( $chosen[0] eq $self->{info}{ok} ) {
                        shift @chosen;
                        for my $col ( @chosen ) {
                            $col =~ s/^col_//;
                            push @col_idx, $col - 1;
                        }
                        if ( @col_idx ) {
                            my $tmp = [];
                            for my $row ( @{$sql->{quote}{insert_into_args}} ) {
                                push @$tmp, [ @{$row}[@col_idx] ];
                            }
                            $sql->{quote}{insert_into_args} = $tmp;
                        }
                        next FILTER;
                    }
                    for my $col ( @chosen ) {
                        $col =~ s/^col_//;
                        push @col_idx, $col - 1;
                    }
                }
            }
            elsif ( $filter eq $input_rows_range ) {
                my $stmt_v = Term::Choose->new( $self->{info}{lyt_stmt_v} );
                my @pre = ( undef );
                my $choices;
                {
                    no warnings 'uninitialized';
                    $choices = [ @pre, map { join ',', @$_ } @{$sql->{quote}{insert_into_args}} ];
                }
                $auxil->__print_sql_statement( $sql, $sql_type );
                # Choose
                my $first_idx = $stmt_v->choose(
                    $choices,
                    { prompt => "First row:\n", index => 1, undef => '<<' }
                );
                next FILTER if ! defined $first_idx || ! defined $choices->[$first_idx];
                my $first_row = $first_idx - @pre;
                next FILTER if $first_row < 0;
                $choices->[$first_row + @pre] = '* ' . $choices->[$first_row + @pre];
                $auxil->__print_sql_statement( $sql, $sql_type );
                # Choose
                my $last_idx = $stmt_v->choose(
                    $choices,
                    { prompt => "Last row:\n", default => $first_row, index => 1, undef => '<<' }
                );
                next FILTER if ! defined $last_idx || ! defined $choices->[$last_idx];
                my $last_row = $last_idx - @pre;
                next FILTER if $last_row < 0;
                if ( $last_row < $first_row ) {
                    $auxil->__print_sql_statement( $sql, $sql_type );
                    # Choose
                    $stmt_h->choose(
                        [ "Last row [$last_row] is less than First row [$first_row]!" ],
                        { %{$self->{info}{lyt_stop}}, prompt => 'Press ENTER' }
                    );
                    next FILTER;
                }
                $sql->{quote}{insert_into_args} = [ @{$sql->{quote}{insert_into_args}}[$first_row .. $last_row] ];
                next FILTER;
            }
            elsif ( $filter eq $input_rows_choose ) {
                my $stmt_v = Term::Choose->new( $self->{info}{lyt_stmt_v} );
                my @pre = ( undef );
                my $choices;
                {
                    no warnings 'uninitialized';
                    $choices = [ @pre, map { join ',', @$_ } @{$sql->{quote}{insert_into_args}} ];
                }
                $auxil->__print_sql_statement( $sql, $sql_type );
                # Choose
                my @idx = $stmt_v->choose(
                    $choices,
                    { prompt => 'Choose rows:', index => 1, no_spacebar => [ 0 .. $#pre ], undef => '<<' }
                );
                next FILTER if ! defined $idx[0] || ! defined $choices->[$idx[0]];
                my @row_idx = map{ $_ - @pre } @idx;
                $sql->{quote}{insert_into_args} = [ @{$sql->{quote}{insert_into_args}}[@row_idx] ];
                next FILTER;
            }
            elsif ( $filter eq $cols_to_rows ) {
                my $tmp = $sql->{quote}{insert_into_args};
                my $new = [];
                for my $i ( 0 .. $#$tmp ) {
                    for my $j ( 0 .. $#{$tmp->[$i]} ) {
                        $new->[$j][$i] = $tmp->[$i][$j];
                    }
                }
                $sql->{quote}{insert_into_args} = $new;
                next FILTER;
            }
        }
    }
}


sub __parse_file {
    my ( $self, $sql, $sql_type, $file_or_fh, $sheet_idx ) = @_;
    my $auxil = App::DBBrowser::Auxil->new( $self->{info} );
    $auxil->__print_sql_statement( $sql, $sql_type );
    if ( ref $file_or_fh eq 'GLOB' ) {
        my $fh = $file_or_fh;
        seek $fh, 0, 0;
        my $tmp = [];
        if ( $self->{opt}{insert}{parse_mode} == 0 ) {
            my $csv = Text::CSV->new( { map { $_ => $self->{opt}{insert}{$_} } @{$self->{info}{csv_opt}} } );
            while ( my $row = $csv->getline( $fh ) ) {
                push @$tmp, $row;
            }
        }
        else {
            local $/;
            push @$tmp, map { [ split /$self->{opt}{insert}{i_f_s}/ ] } split /$self->{opt}{insert}{i_r_s}/, <$fh>;
        }
        $sql->{quote}{insert_into_args} = $tmp;
        return;
    }
    else {
        my $file = $file_or_fh;
        my $cm = Term::Choose->new( { %{$self->{info}{lyt_stop}}, prompt => 'Press ENTER' } );
        my $file_dc = decode( 'locale_fs', $file );
        if ( ! -e $file ) {
            $cm->choose( [ $file_dc . ' : file not found!' ] );
            return;
        }
        if ( ! -s $file ) {
            $cm->choose( [ $file_dc . ' : empty file!' ] );
            return;
        }
        if ( ! -r $file ) {
            $cm->choose( [ $file_dc . ' : file not readable!' ] );
            return;
        }
        require Spreadsheet::Read;
        my $book = Spreadsheet::Read::ReadData( $file, cells => 0, attr => 0, rc => 1, strip => 0 );
        if ( ! defined $book ) {
            $cm->choose( [ $file_dc . ' : no book!' ] );
            return;
        }
        my $nr_of_sheets = @$book - 1; # first sheet in $book contains meta info
        if ( $nr_of_sheets == 0 ) {
            $cm->choose( [ $file_dc . ' : no sheets!' ] );
            return;
        }
        if ( $sheet_idx ) {
            $sheet_idx = $sheet_idx;
        }
        elsif ( @$book == 2 ) {
            $sheet_idx = 1;
        }
        else {
            my @sheets = map { '- ' . ( length $book->[$_]{label} ? $book->[$_]{label} : 'sheet_' . $_ ) } 1 .. $#$book;
            my $c_sheet = Term::Choose->new();
            my @pre = ( undef );
            my $choices = [ @pre, @sheets ];
            # Choose
            $sheet_idx = $c_sheet->choose(
                $choices,
                { %{$self->{info}{lyt_stmt_v}}, index => 1, prompt => 'Choose a sheet' }
            );
            if ( ! defined $sheet_idx || ! defined $choices->[$sheet_idx] ) {
                return;
            }
        }
        if ( $book->[$sheet_idx]{maxrow} == 0 ) {
            my $cm = Term::Choose->new( { %{$self->{info}{lyt_stop}}, prompt => 'Press ENTER' } );
            my $sheet = length $book->[$sheet_idx]{label} ? $book->[$sheet_idx]{label} : 'sheet_' . $_;
            $cm->choose( [ $sheet . ': empty sheet!' ] );
            return;
        }
        $sql->{quote}{insert_into_args} = [ Spreadsheet::Read::rows( $book->[$sheet_idx] ) ];
        return $nr_of_sheets, $sheet_idx;
    }
}




1;


__END__
