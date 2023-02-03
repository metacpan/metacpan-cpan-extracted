package # hide from PAUSE
App::DBBrowser::CreateDropAttach::DropTable;

use warnings;
use strict;
use 5.014;

use Term::Choose       qw();
use Term::Choose::Util qw( insert_sep );
use Term::TablePrint   qw();

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub drop_table {
    my ( $sf ) = @_;
    return $sf->__choose_drop_item( 'table' );
}


sub drop_view {
    my ( $sf ) = @_;
    return $sf->__choose_drop_item( 'view' );
}


sub __choose_drop_item {
    my ( $sf, $type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    if ( ! @{$sf->{d}{user_table_keys}} ) {
        my $info = $sf->{d}{db_string};
        my $prompt = sprintf 'No %ss.', $type;
        my $table = $tc->choose(
            [ undef ],
            { info => $info, prompt => $prompt, undef => '<<' }
        );
        return;
    }
    my $sql = {};
    $ax->reset_sql( $sql );
    my $tables = [ grep { $sf->{d}{tables_info}{$_}[3] eq uc $type } @{$sf->{d}{user_table_keys}} ];
    my $prompt = $sf->{d}{db_string} . "\n" . 'Drop ' . $type;
    # Choose
    my $table = $tc->choose(
        [ undef, map { "- $_" } sort @$tables ],
        { %{$sf->{i}{lyt_v}}, prompt => $prompt, undef => '  <=' }
    );
    if ( ! defined $table || ! length $table ) {
        return;
    }
    $table =~ s/\-\s//;
    my $drop_ok = $sf->__drop( $sql, $type, $table );
    return $drop_ok;
}


sub __drop {
    my ( $sf, $sql, $type, $table ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    if ( $type ne 'view' ) {
        $type = 'table';
    }
    $sql->{table} = $ax->quote_table( $sf->{d}{tables_info}{$table} );
    my $stmt_type = 'Drop_' . $type;
    $sf->{d}{stmt_types} = [ $stmt_type ];
    my $info = $ax->get_sql_info( $sql );
    # Choose
    my $ok = $tc->choose(
        [ undef, $sf->{i}{_confirm} . ' Stmt'],
        { %{$sf->{i}{lyt_v}}, info => $info }
    );
    $ax->print_sql_info( $info );
    if ( ! $ok ) {
        return;
    }
    my $row_count;
    if ( ! eval {
        my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $sql->{table} );
        $sth->execute();
        my $col_names = $sth->{NAME}; # mysql: $sth->{NAME} before fetchall_arrayref
        my $all_arrayref = $sth->fetchall_arrayref;
        $row_count = @$all_arrayref;
        unshift @$all_arrayref, $col_names;
        my $prompt_pt = sprintf "DROP %s %s     (on last look at the %s)\n", uc $type, $sql->{table}, $type;
        my $tp = Term::TablePrint->new( $sf->{o}{table} );
        $tp->print_table(
            $all_arrayref,
            { prompt => $prompt_pt, footer => "     '" . $table . "'     " }
        );
        1; }
    ) {
        $ax->print_error_message( $@ );
    }
    if ( $row_count ) {
        chomp $info;
        $info .= sprintf "  (%s %s)\n", insert_sep( $row_count, $sf->{i}{info_thsd_sep} ), $row_count == 1 ? 'row' : 'rows';
    }
    my $prompt = "CONFIRM:";
    # Choose
    my $choice = $tc->choose(
        [ undef, 'YES' ],
        { info => $info, prompt => $prompt, undef => 'NO', clear_screen => 1 }
    );
    $ax->print_sql_info( $info );
    if ( defined $choice && $choice eq 'YES' ) {
        my $stmt = $ax->get_stmt( $sql, $stmt_type, 'prepare' );
        $sf->{d}{dbh}->do( $stmt ) or die "$stmt failed!";
        return 1;
    }
    return;
}





1;

__END__
