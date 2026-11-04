package # hide from PAUSE
App::DBBrowser::Table::Extensions::RearrangeColumns;

use warnings;
use strict;
use 5.016;

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


sub rearrange_columns {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @bu_selected_cols = @{$sql->{selected_cols}};
    my @available_cols = @bu_selected_cols ? @bu_selected_cols : @{$sql->{columns}};
    $sql->{selected_cols} = [];
    my @pre = ( undef, $sf->{i}{ok} );
    my $menu = [ @pre, @available_cols ];

    COLUMNS: while ( 1 ) {
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my @idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => 'Rearragne columns:', meta_items => [ 0 .. $#pre - 1 ], no_spacebar => [ $#pre ],
            include_highlighted => 2, index => 1 }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx[0] ) {
            if ( @{$sql->{selected_cols}} ) {
                pop @{$sql->{selected_cols}};
                next COLUMNS;
            }
            $sql->{selected_cols} = [ @bu_selected_cols ];
            return;
        }
        if ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            if ( @idx ) {
                push @{$sql->{selected_cols}}, @{$menu}[@idx];
            }
            if ( ! @{$sql->{selected_cols}} ) {
                $sql->{selected_cols} = [ @bu_selected_cols ];
                return;
            }
            return 1;
        }
        push @{$sql->{selected_cols}}, @{$menu}[@idx];
    }
}



1

__END__
