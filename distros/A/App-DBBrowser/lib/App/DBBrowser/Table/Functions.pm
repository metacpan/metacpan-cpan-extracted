package # hide from PAUSE
App::DBBrowser::Table::Functions;

use warnings;
use strict;
use 5.010001;

use Term::Choose       qw();
use Term::Choose::Util qw( choose_a_number choose_a_subset );
use Term::Form         qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
    }, $class;
}


sub col_function {
    my ( $sf, $sql, $clause ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $changed = 0;
    my $cols;
    if ( $clause eq 'select' && ( @{$sql->{group_by_cols}} || @{$sql->{aggr_cols}} ) ) {
        $cols = [ @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} ];
    }
    elsif ( $clause eq 'having' ) {
        $cols = [ @{$sql->{aggr_cols}} ];
    }
    else {
        $cols = [ @{$sql->{cols}} ];
    }
    my $functions_args = {
        Bit_Length          => 1,
        Char_Length         => 1,
        Concat              => 9, # Concatenate
        Epoch_to_Date       => 1,
        Epoch_to_DateTime   => 1,
        Truncate            => 1,
    };
    my @functions_sorted = qw( Concat Truncate Bit_Length Char_Length Epoch_to_Date Epoch_to_DateTime );

    SCALAR_FUNC: while ( 1 ) {
        # Choose
        my $function = $tc->choose(
            [ undef, map( "  $_", @functions_sorted ) ],
            { %{$sf->{i}{lyt_v}}, prompt => 'Function:', undef => '  <=' } # <= BACK
        );
        if ( ! defined $function ) {
            return;
        }
        $function =~ s/^\s\s//;
        my $arg_count = $functions_args->{$function};
        my $col = $sf->__choose_columns( $sql, $function, $arg_count, $cols ); # cols - col
        if ( ! defined $col ) {
            next SCALAR_FUNC;
        }
        my $col_with_func = $sf->__prepare_col_func( $function, $col );
        if ( ! defined $col_with_func ) {
            next SCALAR_FUNC;
        }
        return $col_with_func;
    }
}

sub __choose_columns {
    my ( $sf, $sql, $function, $arg_count, $cols ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    if ( ! $arg_count ) {
        return;
    }
    elsif ( $arg_count == 1 ) {
        # Choose
        return $tc->choose(
            [ undef, @$cols ],
            { %{$sf->{i}{lyt_h}}, prompt => $function . ': ' }
        );
    }
    else {
        # Choose
        return choose_a_subset(
            $cols,
            { name => $function . ': ', layout => 1, sofar_separator => ',', mouse => $sf->{o}{table}{mouse},
              keep_chosen => 1, hide_cursor => 0 }
        );
    }
}


sub __prepare_col_func {
    my ( $sf, $func, $qt_col ) = @_; # $qt_col -> $arg
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $quote_f;
    if ( $func =~ /^Epoch_to_Date(?:Time)?\z/ ) {
        my $prompt = $func eq 'Epoch_to_Date' ? 'DATE' : 'DATETIME';
        $prompt .= "($qt_col)\nInterval:";
        my ( $microseconds, $milliseconds, $seconds ) = (
            '  ****************   Micro-Second',
            '  *************      Milli-Second',
            '  **********               Second' );
        my $choices = [ undef, $microseconds, $milliseconds, $seconds ];
        # Choose
        my $interval = $tc->choose(
            $choices,
            { %{$sf->{i}{lyt_v}}, prompt => $prompt }
        );
        return if ! defined $interval;
        my $div = $interval eq $microseconds ? 1000000 :
                  $interval eq $milliseconds ? 1000 : 1;
        if ( $func eq 'Epoch_to_DateTime' ) {
            $quote_f = $plui->epoch_to_datetime( $qt_col, $div );
        }
        else {
            $quote_f = $plui->epoch_to_date( $qt_col, $div );
        }
    }
    elsif ( $func eq 'Truncate' ) {
        my $info = $func . ': ' . $qt_col;
        my $name = "Decimal places: ";
        my $precision = choose_a_number( 2,
            { name => $name, info => $info, small_first => 1, mouse => $sf->{o}{table}{mouse}, clear_screen => 0, hide_cursor => 0 }
        );
        return if ! defined $precision;
        $quote_f = $plui->truncate( $qt_col, $precision );
    }
    elsif ( $func eq 'Bit_Length' ) {
        $quote_f = $plui->bit_length( $qt_col );
    }
    elsif ( $func eq 'Char_Length' ) {
        $quote_f = $plui->char_length( $qt_col );
    }
    elsif ( $func eq 'Concat' ) {
        my $info = "\n" . 'Concat( ' . join( ',', @$qt_col ) . ' )';
        my $tf = Term::Form->new( $sf->{i}{tf_default} );
        my $sep = $tf->readline( 'Separator: ',
            { info => $info }
        );
        return if ! defined $sep;
        $quote_f = $plui->concatenate( $qt_col, $sep );
    }
    return $quote_f;
}





1;


__END__
