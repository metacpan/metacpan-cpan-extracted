package # hide from PAUSE
App::DBBrowser::Table::Functions;

use warnings;
use strict;
use 5.010001;

use Term::Choose       qw();
use Term::Choose::Util qw();
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
    my $functions_col_count = {
        Bit_Length          => 1,
        Char_Length         => 1,
        Concat              => 9, # Concatenate
        Epoch_to_Date       => 1,
        Epoch_to_DateTime   => 1,
        Replace             => 1,
        Round               => 1,
        Truncate            => 1,
    };
    my @functions_sorted = qw( Bit_Length Char_Length Concat Epoch_to_Date Epoch_to_DateTime Replace Round Truncate );

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
        my $col_count = $functions_col_count->{$function};
        my $col = $sf->__choose_columns( $sql, $function, $col_count, $cols ); # cols - col
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
    my ( $sf, $sql, $function, $col_count, $cols ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    if ( ! $col_count ) {
        return;
    }
    elsif ( $col_count == 1 ) {
        # Choose
        return $tc->choose(
            [ undef, @$cols ],
            { %{$sf->{i}{lyt_h}}, prompt => $function . ': ' }
        );
    }
    else {
        # Choose
        my $subset = $tu->choose_a_subset(
            $cols,
            { cs_label => $function . ': ', layout => 1, cs_separator => ',', keep_chosen => 1 }
        );
        if ( ! defined $subset || ! @$subset ) {
            return;
        }
        return $subset;
    }
}


sub __prepare_col_func {
    my ( $sf, $func, $qt_col ) = @_; # $qt_col -> $arg
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $quote_f;
    if ( $func eq 'Bit_Length' ) {
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
    elsif ( $func =~ /^Epoch_to_Date(?:Time)?\z/ ) {
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
    elsif ( $func eq 'Replace' ) {
        my $info = $func . '(' . $qt_col . ', from_str, to_str)';
        my $tf = Term::Form->new( $sf->{i}{tf_default} );
        my $fields = [
            [ ' from str', ],
            [ '   to str', ],
        ];
        my $form = $tf->fill_form(
            $fields,
            { info => $info, prompt => '', auto_up => 2,
              confirm => '  OK', back => '  <<' }
        );
        if ( ! $form ) {
            return;
        }
        my $string_to_replace =  $sf->{d}{dbh}->quote( $form->[0][1] );
        my $replacement_string = $sf->{d}{dbh}->quote( $form->[1][1] );
        #return if ! ...;
        $quote_f = $plui->replace( $qt_col, $string_to_replace, $replacement_string  );
    }
    elsif ( $func eq 'Round' ) {
        my $info = $func . ': ' . $qt_col;
        my $name = "Decimal places: ";
        my $precision = $tu->choose_a_number( 2,
            { cs_label => $name, info => $info, small_first => 1 }
        );
        return if ! defined $precision;
        my $positive_precision = 'ROUND(' . $qt_col . ',  ' . $precision . ')';
        my $negative_precision = 'ROUND(' . $qt_col . ', -' . $precision . ')';
        my $choice = $tc->choose(
            [ undef, $positive_precision, $negative_precision ],
            { layout => 3, undef => '<<', prompt => 'Choose sign:' }
        );
        return if ! defined $choice;
        if ( $choice eq $negative_precision  ) {
            $precision = -$precision;
        }
        $quote_f = $plui->round( $qt_col, $precision );
    }
    elsif ( $func eq 'Truncate' ) {
        my $info = $func . ': ' . $qt_col;
        my $name = "Decimal places: ";
        my $precision = $tu->choose_a_number( 2,
            { cs_label => $name, info => $info, small_first => 1 }
        );
        return if ! defined $precision;
        $quote_f = $plui->truncate( $qt_col, $precision );
    }
    return $quote_f;
}





1;


__END__
