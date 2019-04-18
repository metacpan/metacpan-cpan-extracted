package # hide from PAUSE
App::DBBrowser::GetContent::ParseFile;

use warnings;
use strict;
use 5.008003;

use Encode qw( decode );

use Encode::Locale    qw();
#use Spreadsheet::Read qw( ReadData rows ); # required
#use String::Unescape  qw( unescape );      # required
#use Text::CSV         qw();                # required

use Term::Choose qw( choose );

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
    };
    bless $sf, $class;
}


sub __parse_file_Text_CSV { # 0
    my ( $sf, $sql, $fh ) = @_;
    local $SIG{INT} = sub { unlink $sf->{i}{f_tmp_copy_paste}; exit };
    delete $sf->{d}{sheet_name};
    my $waiting = 'Parsing file ... ';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql, $waiting );
    seek $fh, 0, 0;
    my $rows_of_cols = [];
    require Text::CSV;
    require String::Unescape;
    my $options = { map { $_ => String::Unescape::unescape( $sf->{o}{csv}{$_} ) } keys %{$sf->{o}{csv}} };
    my $csv = Text::CSV->new( $options ) or die Text::CSV->error_diag();
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
            choose(
                [ 'Press ENTER' ],
                { %{$sf->{i}{lyt_m}}, prompt => $message }
            );
            return;
        }
    } );
    while ( my $cols = $csv->getline( $fh ) ) {
        push @$rows_of_cols, $cols;
    }
    $sql->{insert_into_args} = $rows_of_cols;
    $ax->print_sql( $sql, $waiting );
    return 1;
}


sub __parse_file_split { # 1
    my ( $sf, $sql, $fh ) = @_;
    local $SIG{INT} = sub { unlink $sf->{i}{f_tmp_copy_paste}; exit };
    delete $sf->{d}{sheet_name};
    my $waiting = 'Parsing file ... ';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql, $waiting );
    my $rows_of_cols = [];
    local $/;
    seek $fh, 0, 0;
    my $record_lead  = $sf->{o}{split}{record_l_trim};
    my $record_trail = $sf->{o}{split}{record_r_trim};
    my $field_lead   = $sf->{o}{split}{field_l_trim};
    my $field_trail  = $sf->{o}{split}{field_r_trim};
    for my $row ( split /$sf->{o}{split}{record_sep}/, <$fh> ) {
        $row =~ s/^$record_lead//   if length $record_lead;
        $row =~ s/$record_trail\z// if length $record_trail;
        push @$rows_of_cols, [
            map {
                s/^$field_lead//   if length $field_lead;
                s/$field_trail\z// if length $field_trail;
                $_
            } split /$sf->{o}{split}{field_sep}/, $row, -1 ]; # negative LIMIT (-1) to preserve trailing empty fields
    }
    $sql->{insert_into_args} = $rows_of_cols;
    $ax->print_sql( $sql, $waiting );
    return 1;
}


sub __parse_file_Spreadsheet_Read { # 2
    my ( $sf, $sql, $file_ec, $book ) = @_;
    delete $sf->{d}{sheet_name};
    my $waiting = 'Parsing file ... ';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql, $waiting );
    require Spreadsheet::Read;
    if ( ! defined $book ) {
        $book = Spreadsheet::Read::ReadData( $file_ec, cells => 0, attr => 0, rc => 1, strip => 0 );
        if ( ! defined $book ) {
            choose(
                [ 'Press ENTER' ],
                { %{$sf->{i}{lyt_m}}, prompt => 'No Book in ' . decode( 'locale_fs', $file_ec ) . '!' }
            );
            return;
        }
    }
    my $sheet_count = @$book - 1; # first sheet in $book contains meta info
    if ( $sheet_count == 0 ) {
        choose(
            [ 'Press ENTER' ],
            { %{$sf->{i}{lyt_m}}, prompt => 'No Sheets in ' . decode( 'locale_fs', $file_ec ) . '!' }
        );
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
        $ENV{TC_RESET_AUTO_UP} = 0;
        # Choose
        $sheet_idx = choose( # m
            $choices,
            { %{$sf->{i}{lyt_stmt_v}}, index => 1, prompt => 'Choose a sheet', default => $sf->{i}{old_sheet_idx}, undef => '  <=' }
        );
        if ( ! defined $sheet_idx || ! defined $choices->[$sheet_idx] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $sf->{i}{old_sheet_idx} == $sheet_idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $sf->{i}{old_sheet_idx} = 0;
                return $book, $sheet_count;
            }
            else {
                $sf->{i}{old_sheet_idx} = $sheet_idx;
            }
        }
        delete $ENV{TC_RESET_AUTO_UP};
        $sheet_idx = $sheet_idx - @pre + 1;
    }
    if ( $book->[$sheet_idx]{maxrow} == 0 ) {
        my $sheet = length $book->[$sheet_idx]{label} ? $book->[$sheet_idx]{label} : 'sheet_' . $_;
        choose(
            [ 'Press ENTER' ],
            { %{$sf->{i}{lyt_m}}, prompt => $sheet . ': empty sheet!' }
        );
        return $book, $sheet_count;
    }
    $sql->{insert_into_args} = [ Spreadsheet::Read::rows( $book->[$sheet_idx] ) ];
    if ( ! -T $file_ec && length $book->[$sheet_idx]{label} ) {
        $sf->{d}{sheet_name} = $book->[$sheet_idx]{label};
    }
    return $book, $sheet_count;
}







1;


__END__
