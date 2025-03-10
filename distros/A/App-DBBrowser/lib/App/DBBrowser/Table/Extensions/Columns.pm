package # hide from PAUSE
App::DBBrowser::Table::Extensions::Columns;

use warnings;
use strict;
use 5.014;

use Term::Choose qw();

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub columns {
    my ( $sf, $sql, $cols, $ext_info ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @avail_cols = @$cols;

    COLUMN: while ( 1 ) {
        my $change_table = '%%';
        my @pre = ( undef, $change_table );
        my $menu = [ @pre, @avail_cols ];
        my $info = $ext_info || $ax->get_sql_info( $sql );
        # Choose
        my $column = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $info, undef => '<<' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $column ) {
            return;
        }
        if ( $column eq $change_table ) {
            my $stmt = $ax->get_sql_info( $sql );
            my $norm_stmt = $ax->normalize_space_in_stmt( $stmt );
            my @identifier_alias;
            for my $table ( keys %{$sf->{d}{table_aliases}} ) {
                my ( $tmp_table, $tmp_stmt );
                if ( $table =~ /^\s*\(/ ) {
                    $tmp_table = $ax->normalize_space_in_stmt( $table );
                    $tmp_stmt = $norm_stmt;
                }
                else {
                    $tmp_table = $table;
                    $tmp_stmt = $stmt;
                }
                for my $alias ( @{$sf->{d}{table_aliases}{$table}} ) {
                    if ( $tmp_stmt =~ /\Q$tmp_table\E\s+\Q$alias\E(?:\W|\z)/ ) {
                        push @identifier_alias, [ $alias, "$table $alias" ];
                    }
                }
            }
            @identifier_alias = sort { $a->[0] cmp $b->[0] } @identifier_alias;
            my @table_key;
            my $user_table_keys = $sf->{d}{user_table_keys};
            my $sys_table_keys = $sf->{d}{sys_table_keys};
            if ( $sf->{o}{G}{metadata} ) {
                my $sys_prefix = $sf->{d}{is_system_schema} ? '- ' : '  ';
                @table_key = ( map( "- $_", @$user_table_keys ), map( $sys_prefix . $_, @$sys_table_keys ) );
            }
            else {
                @table_key = ( map( "- $_", @$user_table_keys ) );
            }
            my $local_table = '  Local table';
            my @pre = ( undef, $local_table );
            my @tmp_id_alias = map { '- ' . $ax->unquote_identifier( $_->[0] ) } @identifier_alias;
            my $menu_tables = [ @pre, @tmp_id_alias, @table_key ];
            my $info = $ax->get_sql_info( $sql );
            # Choose
            my $idx = $tc->choose(
                $menu_tables,
                { %{$sf->{i}{lyt_v}}, prompt => 'Column from:', info => $info, undef => '<<', index => 1 }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $idx || ! defined $menu_tables->[$idx] ) {
                next COLUMN;
            }
            elsif ( $menu_tables->[$idx] eq $local_table ) {
                @avail_cols = @$cols;
                next COLUMN;
            }
            else {
                $idx -= @pre;
                my ( $table, $identifier );
                if ( $idx < @identifier_alias ) {
                    ( my $alias, $table ) = @{$identifier_alias[$idx]};
                    $identifier = $alias;
                }
                else {
                    $idx -= @identifier_alias;
                    my $table_key = $table_key[$idx] =~ s/^[-\ ]\ //r;
                    $table = $ax->qq_table( $sf->{d}{tables_info}{$table_key} );
                    $identifier = $ax->quote_table( $sf->{d}{tables_info}{$table_key}[2] ); # quoted but not qualified
                }
                my ( $column_names, undef ) = $ax->column_names_and_types( $table );
                @avail_cols = ();
                for my $col ( @$column_names ) {
                    push @avail_cols, $ax->qualified_identifier( $identifier, $col );
                }
                next COLUMN;
            }
        }
        else {
            return $column;
        }
    }
}




1

__END__
