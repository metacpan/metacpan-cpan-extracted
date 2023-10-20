package # hide from PAUSE
App::DBBrowser::Table::Extensions::Maths;

use warnings;
use strict;
use 5.014;

use Term::Choose           qw();
use Term::Form::ReadLine   qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub maths {
    my ( $sf, $sql, $clause, $qt_cols, $opt ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my ( $num, $op ) = ( '[num]', '[op]' );
    my @pre = ( undef, $sf->{i}{ok}, $sf->{i}{menu_addition}, $num, $op );
    my $menu = [ @pre, @$qt_cols ];
    my $info = $opt->{info} // $ax->get_sql_info( $sql );
    my $items = [];
    my $prompt = $opt->{prompt} // 'Math:';
    my @bu;

    COLUMNS: while ( 1 ) { ##
        my $fill_string = join( ' ', @$items, '?' );
        $fill_string =~ s/\(\s/(/g;
        $fill_string =~ s/\s\)/)/g;
        my $tmp_info = $info . "\n" . $fill_string;
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $tmp_info, prompt => $prompt, index => 1 }
        );
        if ( ! $idx ) {
            if ( @bu ) {
                $items = pop @bu;
                next COLUMNS;
            }
            return;
        }
        if ( $menu->[$idx] eq $sf->{i}{ok} ) {
            if ( ! @$items ) {
                return;
            }
            my $result = join ' ', @$items;
            $result =~ s/\(\s/(/g;
            $result =~ s/\s\)/)/g;
            return '(' . $result . ')';
        }
        elsif ( $menu->[$idx] eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_col = $ext->column(
                $sql, $clause, {},
                { from => 'maths', info => $tmp_info }
            );
            if ( ! defined $complex_col ) {
                next COLUMNS;
            }
            push @bu, [ @$items ];
            push @$items, $complex_col;
        }
        elsif ( $menu->[$idx] eq $op ) {
            # Choose
            my $operator = $tc->choose(
                [ undef, ' + ',   ' - ', ' * ', ' / ', ' % ', ' ( ', ' ) ' ],
                { %{$sf->{i}{lyt_h}}, info => $tmp_info . "\n" . $prompt, prompt => '', undef => '<=' }
            );
            if ( ! defined $operator ) {
                next COLUMNS;
            }
            push @bu, [ @$items ];
            push @$items, $operator =~ s/^\s+|\s+\z//gr;
        }
        elsif ( $menu->[$idx] eq $num ) {
            my $number = $tr->readline(
                'Number: ',
                { info => $tmp_info . "\n" . $prompt }
            );
            if ( ! length $number ) {
                next COLUMNS;
            }
            push @bu, [ @$items ];
            push @$items, $number;
        }
        else {
            push @bu, [ @$items ];
            push @$items, $menu->[$idx];
        }
    }
}




1;


__END__
