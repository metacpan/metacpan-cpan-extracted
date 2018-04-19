package # hide from PAUSE
App::DBBrowser::Table::Insert;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '2.013';

use Cwd                   qw( realpath );
use Encode                qw( encode decode );
use File::Basename        qw( dirname );
use File::Spec::Functions qw( catfile );
use List::Util            qw( all );

use List::MoreUtils   qw( first_index any );
use Encode::Locale    qw();
#use Spreadsheet::Read qw( ReadData rows ); # "require"d
#use Text::CSV         qw();                # "require"d

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_file choose_a_subset );
use Term::Form         qw();

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';

use App::DBBrowser::Auxil;
use App::DBBrowser::Opt;

use open ':encoding(locale)';


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
        tmp_copy_paste => catfile( $info->{app_dir}, 'Copy_and_Paste_tmp_file.csv' ),
        input_files    => catfile( $info->{app_dir}, 'file_history.txt' )
    };
    bless $sf, $class;
}


sub __insert_into_stmt_cols {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax  = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sql->{insert_into_cols} = [];
    my @cols = ( @{$sql->{cols}} );
        if ( $sf->{d}{driver} eq 'SQLite' ) {
        my ( $row ) = $sf->{d}{dbh}->selectrow_array( "SELECT sql FROM sqlite_master WHERE name = ?", {}, $sf->{d}{table} );
        my $qt_col   = $sf->{d}{dbh}->quote_identifier( $sf->{d}{cols}[0] );
        my $qt_table = $sf->{d}{dbh}->quote_identifier( $sf->{d}{table} );
        if ( $row =~ /^\s*CREATE\s+TABLE\s+(?:\Q$sf->{d}{table}\E|\Q$qt_table\E)\s+\(
                                \s*(?:\Q$sf->{d}{cols}[0]\E|\Q$qt_col\E)\s+INTEGER\s+PRIMARY\s+KEY\s*,/ix ) {
            shift @cols;
        }
    }
    my $bu_cols = [ @cols ];

    COL_NAMES: while ( 1 ) {
        my @pre = ( undef, $sf->{i}{ok} );
        my $choices = [ @pre, @cols ];
        $ax->print_sql( $sql, $stmt_typeS );
        # Choose
        my @idx = choose(
            $choices,
            { %{$sf->{i}{lyt_stmt_h}}, prompt => 'Columns:', index => 1, no_spacebar => [ 0 .. $#pre ] }
        );
        if ( ! defined $idx[0] || ! defined $choices->[$idx[0]] ) {
            return if ! @{$sql->{insert_into_cols}};
            $sql->{insert_into_cols} = [];
            @cols = ( @{$sql->{cols}} );
            next COL_NAMES;
        }
        my $confirmed;
        if ( $idx[0] == first_index { $sf->{i}{ok} eq $_ } @pre ) {
            $confirmed = 1;
            shift @idx;
        }
        for my $col ( map { $choices->[$_] } @idx ) {
            push @{$sql->{insert_into_cols}}, $col;
        }
        if ( $confirmed ) {
            if ( ! @{$sql->{insert_into_cols}} ) {
                $sql->{insert_into_cols} = $bu_cols;
            }
            return 1;
        }
        my $c = 0;
        for my $i ( @idx ) {
            last if ! @cols;
            my $ni = $i - ( @pre + $c );
            splice( @cols, $ni, 1 );
            ++$c;
        }
    }
}


sub build_insert_stmt {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    $ax->reset_sql( $sql );
    my @cu_keys = ( qw/insert_col insert_copy insert_file settings/ );
    my %cu = (
        insert_col  => '- plain',
        insert_copy => '- Copy & Paste',
        insert_file => '- From File',
        settings    => '  Settings'
    );
    my $old_idx = 0;

    MENU: while ( 1 ) {
        my $choices = [ undef, @cu{@cu_keys} ];
        # Choose
        $ENV{TC_RESET_AUTO_UP} = 0;
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_3}}, index => 1, default => $old_idx, prompt => 'Choose:' }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            return;
        }
        my $custom = $choices->[$idx];
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next MENU;
            }
            else {
                $old_idx = $idx;
            }
        }
        delete $ENV{TC_RESET_AUTO_UP};
        if ( $custom eq $cu{settings} ) {
            my $opt = App::DBBrowser::Opt->new( $sf->{i}, $sf->{o} );
            $opt->config_insert;
            next MENU;
        }
        my $cols_ok = $sf->__insert_into_stmt_cols( $sql, $stmt_typeS );
        if ( ! $cols_ok ) {
            next MENU;
        }
        my $insert_ok;
        if ( $custom eq $cu{insert_col} ) {
            $insert_ok = $sf->__from_col_by_col( $sql, $stmt_typeS );
        }
        elsif ( $custom eq $cu{insert_copy} ) {
            $insert_ok = $sf->from_copy_and_paste( $sql, $stmt_typeS );
        }
        elsif ( $custom eq $cu{insert_file} ) {
            $insert_ok = $sf->from_file( $sql, $stmt_typeS );
        }
        if ( ! $insert_ok ) {
            next MENU;
        }
        return 1
    }
}


sub __from_col_by_col {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax  = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sql->{insert_into_args} = [];
    my $trs = Term::Form->new();

    ROWS: while ( 1 ) {
        my $row_idx = @{$sql->{insert_into_args}};

        COLS: for my $col_name ( @{$sql->{insert_into_cols}} ) {
            $ax->print_sql( $sql, $stmt_typeS );
            # Readline
            my $col = $trs->readline( $col_name . ': ' );
            # push $col to show $col immediately in "print_sql"
            push @{$sql->{insert_into_args}->[$row_idx]}, $col;
        }
        my $default = ( all { ! length } @{$sql->{insert_into_args}[-1]} ) ? 3 : 2;

        ASK: while ( 1 ) {
            my ( $add, $del ) = ( 'Add', 'Del' );
            my @pre = ( undef, $sf->{i}{ok} );
            my $choices = [ @pre, $add, $del ];
            $ax->print_sql( $sql, $stmt_typeS );
            # Choose
            my $add_row = choose(
                $choices,
                { %{$sf->{i}{lyt_stmt_h}}, prompt => '', default => $default }
            );
            if ( ! defined $add_row ) {
                if ( @{$sql->{insert_into_args}} ) {
                    $sql->{insert_into_args} = [];
                    next ASK;
                }
                $sql->{insert_into_cols} = [];
                $sql->{insert_into_args} = [];
                return;
            }
            elsif ( $add_row eq $sf->{i}{ok} ) {
                if ( ! @{$sql->{insert_into_args}} ) {
                    $sql->{insert_into_cols} = [];
                    return;
                }
                return 1;
            }
            elsif ( $add_row eq $del ) {
                return if ! @{$sql->{insert_into_args}};
                $default = 0;
                $#{$sql->{insert_into_args}}--;
                next ASK;
            }
            last ASK;
        }
    }
    return 1;
}


sub __file_name {
    my ( $sf, $sql ) = @_;

    FILE: while ( 1 ) {
        my @files;
        if ( $sf->{o}{insert}{max_files} && -e $sf->{input_files} ) {
            open my $fh_in, '<', $sf->{input_files} or die $!;
            while ( my $fl = <$fh_in> ) {
                chomp $fl;
                next if ! -e $fl;
                push @files, $fl;
            }
            close $fh_in;
        }
        my $add_file = '  NEW file';
        my $del_file = '  Remove file';
        my $prompt = sprintf "Choose a file  %s:", $sf->__parse_setting( 'file' );
        # Choose
        my $file = choose(
            [ undef, $add_file, map( '  ' . decode( 'locale_fs', $_ ), @files ), $del_file ],
            { %{$sf->{i}{lyt_stmt_v}}, clear_screen => 1, prompt => $prompt, undef => $sf->{i}{back_config} }
        );
        if ( ! defined $file ) {
            return;
        }
        if ( $file eq $add_file ) {
            my $prompt = sprintf "%s", $sf->__parse_setting( 'file' );
            my $dir = $sf->{i}{tmp_files_dir} || $sf->{i}{home_dir};
            # Choose_a_file
            $file = choose_a_file( { dir => $dir, mouse => $sf->{o}{table}{mouse} } );
            if ( ! defined $file || ! length $file ) {
                next FILE;
            }
            if ( $sf->{o}{insert}{max_files} ) {
                my $i = first_index { $file eq $_ } @files; ##
                splice @files, $i, 1 if $i > -1;
                push @files, $file;
                while ( @files > $sf->{o}{insert}{max_files} ) {
                    shift @files;
                }
                open my $fh_out, '>', $sf->{input_files} or die $!;
                for my $fl ( @files ) {
                    print $fh_out $fl . "\n";
                }
                close $fh_out;
            }
            $sf->{i}{tmp_files_dir} = dirname $file;
            return $file;
        }
        elsif ( $file eq $del_file ) {
            $file = undef;
            my @pre = [ undef, $sf->{i}{ok} ];
            my $idx = choose_a_subset(
                [ map { decode 'locale_fs', $_ } @files ],
                { mouse => $sf->{o}{table}{mouse}, prefix => '  ', info => 'Files to remove:',
                 no_spacebar => [ @pre ], index => 1, fmt_chosen => 1, remove_chosen => 1, clear_screen => 1 }
            );
            if ( ! defined $idx || ! @$idx ) {
                next FILE;
            }
            open my $fh_out, '>', $sf->{input_files} or die $!; # file_name
            for my $i ( 0 .. $#files ) {
                if ( any { $i == $_ } @$idx ) {
                    next;
                }
                print $fh_out $files[$i] . "\n";
            }
            close $fh_out;
            next FILE;
        }
        $file =~ s/\s\s//;
        return realpath encode 'locale_fs', $file;
    }
}


sub __parse_setting {
    my ( $sf, $type ) = @_;
    my $i = $sf->{o}{insert}{$type eq 'file' ? 'file_parse_mode' : 'copy_parse_mode'};
    my $parse_mode = ( 'Text::CSV', 'split', 'Spreadsheet::Read' )[$i]; #
    my $sep;
    if ( $i == 0 ) {
        $sep = $sf->{o}{csv}{sep_char};
    }
    elsif ( $i == 1 ) {
        $sep = $sf->{o}{split}{i_f_s};
    }
    my $str = "($parse_mode";
    $str .= " - sep[$sep]" if defined $sep;
    $str .= ")";
    return $str;
}


sub from_copy_and_paste {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax  = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql, $stmt_typeS );
    my $prompt = sprintf "Mulit row  %s:\n", $sf->__parse_setting( 'copy_and_paste' );
    print $prompt;
    my $file = $sf->{tmp_copy_paste};
    local $SIG{INT} = sub { unlink $file; exit };
    if ( ! eval {
        open my $fh_in, '>', $file or die $!;
        # STDIN
        while ( my $row = <STDIN> ) {
            print $fh_in $row;
        }
        close $fh_in;
        die "No input!" if ! -s $file;
        open my $fh, '<', $file or die $!;
        $sql->{insert_into_args} = [];
        my $ok = $sf->__parse_file( $sql, $stmt_typeS, $file, $fh, $sf->{o}{insert}{copy_parse_mode} );
        close $fh;
        unlink $file or die $!;
        die "Error __parse_file!" if ! $ok;
        1 }
    ) {
        $ax->print_error_message( $@, join ', ', @$stmt_typeS, 'copy & paste' );
        unlink $file or warn $!;
        return;
    }
    #return if ! @{$sql->{insert_into_args}};
    my $ok = $sf->__input_filter( $sql, $stmt_typeS );
    return if ! $ok;
    return 1;
}


sub from_file {
    my ( $sf, $sql, $stmt_typeS ) = @_;

    FILE: while ( 1 ) {
        my $file = $sf->__file_name( $sql );
        my $fh;
        if ( ! defined $file ) {
            return;
        }
        if ( $sf->{o}{insert}{file_parse_mode} < 2 && -T $file ) {
            open $fh, '<:encoding(' . $sf->{o}{insert}{file_encoding} . ')', $file or die $!;
            if ( -z $file ) {
                choose( [ 'empty file!' ], { %{$sf->{i}{lyt_m}}, prompt => 'Press ENTER' } );
                close $fh;
                next FILE;
            }
            my $parse_mode = $sf->{o}{insert}{file_parse_mode};
            my $ok = $sf->__parse_file( $sql, $stmt_typeS, $file, $fh, $parse_mode );
            if ( ! $ok ) {
                next FILE;
            }
            #next if ! @{$sql->{insert_into_args}};
            $ok = $sf->__input_filter( $sql, $stmt_typeS );
            if ( ! $ok ) {
                next FILE;
            }
            return $file;
        }
        else {
            my $parse_mode = 2;
            my ( $sheet_count, $sheet_idx );
            SHEET: while ( 1 ) {
                $sql->{insert_into_args} = [];
                $sheet_count = $sf->__parse_file( $sql, $stmt_typeS, $file, $fh, $parse_mode );
                if ( ! $sheet_count ) {
                    next FILE;
                }
                if ( ! @{$sql->{insert_into_args}} ) { #
                    next SHEET if $sheet_count >= 2;
                    next FILE;
                }
                my $ok = $sf->__input_filter( $sql, $stmt_typeS );
                if ( ! $ok ) {
                    next SHEET if $sheet_count >= 2;
                    next FILE;
                }
                return $file;
            }
        }
    }
}


sub __parse_file {
    my ( $sf, $sql, $stmt_typeS, $file, $fh, $parse_mode ) = @_;
    local $SIG{INT} = sub { unlink $sf->{tmp_copy_paste}; exit };
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql, $stmt_typeS );
    print 'Parsing file ...', "\n";
    if ( $parse_mode == 0 ) {
        seek $fh, 0, 0;
        my $tmp = [];
        require Text::CSV;
        my $csv = Text::CSV->new( { map { $_ => $sf->{o}{csv}{$_} } keys %{$sf->{o}{csv}} } ) or die Text::CSV->error_diag();
        $csv->callbacks( error => sub {
            my ( $code, $str, $pos, $rec, $fld ) = @_;
            if ( $code == 2012 ) { # ignore this error
                Text::CSV->SetDiag (0);
            }
            else {
                my $error_inpunt = $csv->error_input();
                my $message =  "Text::CSV:\n";
                $message .= "Input: $error_inpunt" if defined $error_inpunt;
                $message .= "$code $str - pos:$pos rec:$rec fld:$fld";
                die $message;
            }
        } );
        while ( my $row = $csv->getline( $fh ) ) {
            push @$tmp, $row;
        }
        $ax->print_sql( $sql, $stmt_typeS );
        $sql->{insert_into_args} = $tmp;
        return 1;
    }
    elsif ( $parse_mode == 1 ) {
        my $tmp = [];
        local $/;
        seek $fh, 0, 0;
        my $lead  = $sf->{o}{split}{trim_leading};
        my $trail = $sf->{o}{split}{trim_trailing};
        for my $row ( split /$sf->{o}{split}{i_r_s}/, <$fh> ) {
            push @$tmp, [ map {
                s/^$lead//   if length $lead;
                s/$trail\z// if length $trail;
                $_
            } split /$sf->{o}{split}{i_f_s}/, $row ]; ## docu
        }
        $ax->print_sql( $sql, $stmt_typeS );
        $sql->{insert_into_args} = $tmp;
        return 1;
    }
    else {
        require Spreadsheet::Read;
        my $cm = Term::Choose->new( $sf->{i}{lyt_m} );
        my $book = Spreadsheet::Read::ReadData( $file, cells => 0, attr => 0, rc => 1, strip => 0 );
        $ax->print_sql( $sql, $stmt_typeS );
        my $file_dc = decode( 'locale_fs', $file );
        if ( ! defined $book ) {
            $cm->choose( [ 'Press ENTER' ], { prompt => 'No Book in ' . $file_dc .'!' } );
            return;
        }
        my $sheet_count = @$book - 1; # first sheet in $book contains meta info
        if ( $sheet_count == 0 ) {
            $cm->choose( [ 'Press ENTER' ], { prompt => 'No Sheets in ' . $file_dc . '!' } );
            return;
        }
        my $sheet_idx;
        if ( $sheet_count == 1 ) {
            $sheet_idx = 1;
        }
        else {
            my @sheets = map { '- ' . ( length $book->[$_]{label} ? $book->[$_]{label} : 'sheet_' . $_ ) } 1 .. $#$book;
            my @pre = ( undef );
            my $choices = [ @pre, @sheets ];
            # Choose
            $sheet_idx = choose( # m
                $choices,
                { %{$sf->{i}{lyt_stmt_v}}, index => 1, prompt => 'Choose a sheet' }
            );
            if ( ! defined $sheet_idx || ! defined $choices->[$sheet_idx] ) {
                return;
            }
        }
        if ( $book->[$sheet_idx]{maxrow} == 0 ) {
            my $sheet = length $book->[$sheet_idx]{label} ? $book->[$sheet_idx]{label} : 'sheet_' . $_;
            $cm->choose( [ 'Press ENTER' ], { prompt => $sheet . ': empty sheet!' } );
            return $sheet_count;
        }
        $sql->{insert_into_args} = [ Spreadsheet::Read::rows( $book->[$sheet_idx] ) ];
        return $sheet_count;
    }
}

sub __input_filter {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $r2c = 0;
    my $backup = [];
    for my $i ( 0 .. $#{$sql->{insert_into_args}} ) {
        for my $j ( 0 .. $#{$sql->{insert_into_args}[0]} ) {
            $backup->[$i][$j] = $sql->{insert_into_args}[$i][$j];
        }
    }

    FILTER: while ( 1 ) {
        my @pre = ( undef, $sf->{i}{ok} );
        my $input_cols       = 'Choose Columns';
        my $input_rows       = 'Choose Rows';
        my $input_rows_range = 'Choose Row-range';
        my $cols_to_rows     = $r2c ? 'Cols_to_Rows' : 'Rows_to_Cols';
        my $reset            = 'Reset';
        my $choices = [ @pre, $input_cols, $input_rows, $input_rows_range, $cols_to_rows, $reset ];
        $ax->print_sql( $sql, $stmt_typeS );
        # Choose
        my $filter = $stmt_h->choose(
            $choices,
            { prompt => 'Filter:' }
        );
        if ( ! defined $filter ) {
            $sql->{insert_into_args} = [];
            return;
        }
        elsif ( $filter eq $reset ) {
            $sql->{insert_into_args} = $backup;
            $r2c = 0;
            next FILTER
        }
        elsif ( $filter eq $sf->{i}{ok} ) {
            return 1;
        }
        elsif ( $filter eq $input_cols  ) {
            my $aoa = $sql->{insert_into_args};
            my @empty = ( 0 ) x @{$aoa->[0]};
            COL: for my $c ( 0 .. $#{$aoa->[0]} ) {
                for my $r ( 0 .. $#$aoa ) {
                    next COL if length $aoa->[$r][$c];
                    $empty[$c]++;
                }
            }
            my $mark = [ grep { $empty[$_] < @$aoa } 0 .. $#empty ];
            $mark = undef if scalar( @$mark ) == scalar( @{$aoa->[0]} );
            $ax->print_sql( $sql, $stmt_typeS );
            my $col_idx = choose_a_subset(
                \@{$aoa->[0]},
                { back => '<<', confirm => $sf->{i}{ok}, index => 1, mark => $mark, layout => 0,
                    name => 'Cols: ', clear_screen => 0, mouse => $sf->{o}{table}{mouse} } #
            );
            if ( defined $col_idx && @$col_idx ) {
                $sql->{insert_into_args} = [ map { [ @{$_}[@$col_idx] ] } @$aoa ];
            }
            next FILTER;
        }
        elsif ( $filter eq $input_rows_range ) {
            my $aoa = $sql->{insert_into_args};
            my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
            my @pre = ( undef );
            my $choices;
            {
                no warnings 'uninitialized';
                $choices = [ @pre, map { join ',', @$_ } @$aoa ];
            }
            $ax->print_sql( $sql, $stmt_typeS );
            # Choose
            my $first_idx = $stmt_v->choose(
                $choices,
                { prompt => "Choose FIRST ROW:", index => 1, undef => '<<' }
            );
            next FILTER if ! defined $first_idx || ! defined $choices->[$first_idx];
            my $first_row = $first_idx - @pre;
            next FILTER if $first_row < 0;
            $choices->[$first_row + @pre] = '* ' . $choices->[$first_row + @pre];
            $ax->print_sql( $sql, $stmt_typeS );
            # Choose
            my $last_idx = $stmt_v->choose(
                $choices,
                { prompt => "Choose LAST ROW:", default => $first_row, index => 1, undef => '<<' }
            );
            next FILTER if ! defined $last_idx || ! defined $choices->[$last_idx];
            my $last_row = $last_idx - @pre;
            next FILTER if $last_row < 0;
            if ( $last_row < $first_row ) {
                $ax->print_sql( $sql, $stmt_typeS );
                # Choose
                choose(
                    [ "Last row [$last_row] is less than First row [$first_row]!" ],
                    { %{$sf->{i}{lyt_m}}, prompt => 'Press ENTER' }
                );
                next FILTER;
            }
            $sql->{insert_into_args} = [ @{$aoa}[$first_row .. $last_row] ];
            next FILTER;
        }
        elsif ( $filter eq $input_rows ) {
            my $aoa = $sql->{insert_into_args};
            my %hash;
            for my $i ( 0 .. $#$aoa ) {
                push @{$hash{ scalar @{$aoa->[$i]} }}, $i;
            }
            my @keys = sort { scalar( @{$hash{$b}} ) <=> scalar( @{$hash{$a}} ) } keys %hash;
            my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
            my @pre = ( undef, $sf->{i}{ok} );
            my $mark = ( @keys > 1 ) ? [ map { $_ + @pre } @{$hash{$keys[0]}} ] : undef; # copy only ?
            my $choices;
            {
                no warnings 'uninitialized';
                $choices = [ @pre, map { join ',', @$_ } @$aoa ];
            }
            $ax->print_sql( $sql, $stmt_typeS );
            # Choose
            my @idx = $stmt_v->choose(
                $choices,
                { prompt => 'Choose rows:', index => 1, no_spacebar => [ 0 .. $#pre ], undef => '<<', mark => $mark }
            );
            if ( ! defined $idx[0] || ! defined $choices->[$idx[0]] ) {
                next FILTER;
            }
            elsif ( $choices->[$idx[0]] eq $sf->{i}{ok} ) {
                shift @idx;
            }
            if ( ! @idx ) {
                next FILTER; # ###
            }
            my $tmp_aoa = [];
            {
                no warnings 'uninitialized';
                for my $i ( @idx ) {
                    $i -= @pre;
                    push @$tmp_aoa, [ @{$aoa->[$i]} ];
                }
            }
            $sql->{insert_into_args} = $tmp_aoa;
            next FILTER;
        }
        elsif ( $filter eq $cols_to_rows ) {
            my $aoa = $sql->{insert_into_args};
            my $tmp_aoa = []; # name
            for my $i ( 0 .. $#$aoa ) {
                for my $j ( 0 .. $#{$aoa->[$i]} ) {
                    $tmp_aoa->[$j][$i] = $aoa->[$i][$j];
                }
            }
                $sql->{insert_into_args} = $tmp_aoa;
                $r2c = ! $r2c;
            next FILTER;
        }
    }
}



1;


__END__
