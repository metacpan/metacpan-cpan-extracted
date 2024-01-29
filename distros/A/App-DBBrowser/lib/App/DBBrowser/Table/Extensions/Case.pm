package # hide from PAUSE
App::DBBrowser::Table::Extensions::Case;

use warnings;
use strict;
use 5.014;

use Clone qw( clone );

use Term::Choose         qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Subqueries;
use App::DBBrowser::Table::Extensions::ScalarFunctions;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub case {
    my ( $sf, $sql, $clause, $qt_cols, $r_data, $opt ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    if ( ! defined $r_data->{case} ) {
        # reset recursion data other than case at the first call of case
        # set 'case_info' only at the first call of case (don't reset it in recursive calls)
        $r_data = {
            case => [],
            case_info => $opt->{info} // $ax->get_sql_info( $sql )
        };
    }
    my $tmp_sql = clone( $sql );
    $tmp_sql->{case_stmt} = $r_data->{case}[-1] // '';
    $tmp_sql->{case_info} = $r_data->{case_info};
    my $in = ' ' x $sf->{o}{G}{base_indent};
    my $count = @{$r_data->{case}};
    my $pad1;
    my $pad2;
    if ( ! $count ) {
        $pad1 = '';
        $pad2 = $in x 2;
    }
    else {
        my $d = $count * 4;
        $pad1 = $in x $d;
        $pad2 = $in x ( $d + 2);
    }
    $pad1 .= $in;
    $pad2 .= $in;
    my $preceding_stmt = $tmp_sql->{case_stmt};
    if ( $preceding_stmt ) {
        $tmp_sql->{case_stmt} .= "\n${pad1}CASE";
    }
    else {
        $tmp_sql->{case_stmt} .= "${pad1}CASE";
    }
    my @bu;
    my $else_on = 0;

    SUBSTMT: while ( 1 ) {
        my ( $when, $else, $end ) = ( '  WHEN', '  ELSE', '  END' );
        my @pre = ( undef );
        my $menu;
        if ( $else_on ) {
             $menu = [ @pre, $end ];
        }
        else {
            $menu = [ @pre, $when, $else, $end ];
        }
        my $info = $ax->get_sql_info( $tmp_sql );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Your choice:', index => 1, undef => '  <=' } ##
        );
        $ax->print_sql_info( $info );
        if ( ! $idx ) {
            if ( @bu ) {
                $tmp_sql->{case_stmt} = pop @bu;
                $else_on = 0;
                next SUBSTMT;
            }
            delete $tmp_sql->{case_stmt};
            return;
        }
        push @bu, $tmp_sql->{case_stmt};
        my $operator= '=';
        if ( $menu->[$idx] eq $end ) {
            $tmp_sql->{case_stmt} .= "\n${pad1}END";
            my $case_stmt = delete $tmp_sql->{case_stmt};
            if ( $preceding_stmt ) {
                $case_stmt =~ s/^\Q$preceding_stmt\E//;
            }
            else {
                $case_stmt = "\n" . $case_stmt;
            }
            return $case_stmt;
        }
        elsif ( $menu->[$idx] eq $when ) {
            my $substmt_type = "${pad2}WHEN";
            my $ret = $sb->__add_condition( $tmp_sql, $clause, $substmt_type, $qt_cols );

            if ( ! defined $ret ) {
                delete $tmp_sql->{when_stmt};
                $tmp_sql->{case_stmt} = pop @bu;
                next SUBSTMT;
            }
            $tmp_sql->{case_stmt} .= "\n" . delete $tmp_sql->{when_stmt};
            $tmp_sql->{case_stmt} .= " THEN";
            push @{$r_data->{case}}, $tmp_sql->{case_stmt};
            my $value = $ext->value( $tmp_sql, $clause, $r_data, $operator);
            pop @{$r_data->{case}};
            if ( ! defined $value ) {
                $tmp_sql->{case_stmt} = pop @bu;
                next SUBSTMT;
            }
            $tmp_sql->{case_stmt} .= ' ' . $value;
        }
        elsif ( $menu->[$idx] eq $else ) {
            $tmp_sql->{case_stmt} .= "\n${pad2}ELSE";
            push @{$r_data->{case}}, $tmp_sql->{case_stmt};
            my $value = $ext->value( $tmp_sql, $clause, $r_data, $operator);
            pop @{$r_data->{case}};
            if ( ! defined $value ) {
                $tmp_sql->{case_stmt} = pop @bu;
                next SUBSTMT;
            }
            $tmp_sql->{case_stmt} .= ' ' . $value;
            $else_on = 1;

        }
    }
}





1
__END__
