package # hide from PAUSE
App::DBBrowser::Auxil;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.054';

use Encode qw( encode );

use Encode::Locale         qw();
use JSON                   qw( decode_json );
use List::MoreUtils        qw( any );
use Term::Choose           qw( choose );
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( term_width );

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';



sub new {
    my ( $class, $info ) = @_;
    bless { info => $info }, $class;
}


sub __print_sql_statement {
    my ( $self, $sql, $sql_type ) = @_;
    return if $sql_type eq 'Drop_table';
    my $db_plugin = $self->{info}{db_plugin};
    my $table = $sql->{print}{table};

    my $str = '';
    if ( $sql_type eq 'Create_table' ) {
        my @cols = @{$sql->{print}{insert_cols}};
        unshift @cols, $sql->{print}{id_pk_auto} if defined $sql->{print}{id_pk_auto};
        $str  = "CREATE TABLE $table (";
        if ( @cols ) {
            $str .= " " . join( ', ',  map { defined $_ ? $_ : '' } @cols ) . " ";
        }
        $str .= ")";
        $str .= "\n\n";
        $sql_type = 'Insert';
    }
    if ( $sql_type eq 'Insert' ) {
        my @cols = @{$sql->{print}{insert_cols}};
        $str .= "INSERT INTO $table (";
        if ( @cols ) {
            $str .= " " . join( ', ', map { defined $_ ? $_ : '' } @cols ) . " " ;
        }
        $str .= ")\n";
        $str .= "  VALUES(\n";
        for my $insert_row ( @{$sql->{quote}{insert_into_args}} ) {
            $str .= ( ' ' x 4 ) . join( ', ', map { defined $_ ? $_ : '' } @$insert_row ) . "\n";
        }
        $str .= "  )\n";
    }
    else {
        my %type_sql = (
            Select => "SELECT",
            Delete => "DELETE",
            Update => "UPDATE",
        );
        my $cols_sql;
        if ( $sql_type eq 'Select' ) {
            if ( $sql->{select_type} eq '*' ) {
                $cols_sql = ' *';
            }
            elsif ( $sql->{select_type} eq 'chosen_cols' ) {
                $cols_sql = ' ' . join( ', ', @{$sql->{print}{chosen_cols}} );
            }
            elsif ( @{$sql->{print}{aggr_cols}} || @{$sql->{print}{group_by_cols}} ) {
                $cols_sql = ' ' . join( ', ', @{$sql->{print}{group_by_cols}}, @{$sql->{print}{aggr_cols}} );
            }
            else {
                $cols_sql = ' *';
            }
        }
        $str = $type_sql{$sql_type};
        $str .= $sql->{print}{distinct_stmt}                   if $sql->{print}{distinct_stmt};
        $str .= $cols_sql                               . "\n" if $cols_sql;
        $str .= " FROM"                                        if $sql_type eq 'Select' || $sql_type eq 'Delete';
        $str .= " " . $table                            . "\n";
        $str .= ' '      . $sql->{print}{set_stmt}      . "\n" if $sql->{print}{set_stmt};
        $str .= ' '      . $sql->{print}{where_stmt}    . "\n" if $sql->{print}{where_stmt};
        $str .= ' '      . $sql->{print}{group_by_stmt} . "\n" if $sql->{print}{group_by_stmt};
        $str .= ' '      . $sql->{print}{having_stmt}   . "\n" if $sql->{print}{having_stmt};
        $str .= ' '      . $sql->{print}{order_by_stmt} . "\n" if $sql->{print}{order_by_stmt};
        $str .= ' '      . $sql->{print}{limit_stmt}    . "\n" if $sql->{print}{limit_stmt};
    }
    $str .= "\n";
    print $self->{info}{clear_screen};
    print line_fold( $str, term_width() - 2, '', ' ' x $self->{info}{stmt_init_tab} );
}


sub __print_error_message {
    my ( $self, $message, $title ) = @_;
    print "$title:\n" if $title;
    utf8::decode( $message );
    print $message;
    choose(
        [ 'Press ENTER to continue' ],
        { %{$self->{info}{lyt_stop}}, prompt => '' }
    );
}


sub __reset_sql {
    my ( $self, $sql ) = @_;
    my $backup = {};
    for my $x ( qw( print quote ) ) {
        for my $y ( qw( db schema table columns ) ) {
            $backup->{$x}{$y} = $sql->{$x}{$y} if exists $sql->{$x}{$y};
        }
    }
    map { delete $sql->{$_} } keys %$sql;
    my @strg_keys = ( qw( distinct_stmt set_stmt where_stmt group_by_stmt having_stmt order_by_stmt limit_stmt ) );
    my @list_keys = ( qw( chosen_cols set_args aggr_cols where_args group_by_cols having_args insert_cols insert_into_args ) );
    $sql->{print} = {};
    $sql->{quote} = {};
    @{ $sql->{print} }{ @strg_keys } = ( '' ) x  @strg_keys;
    @{ $sql->{quote} }{ @strg_keys } = ( '' ) x  @strg_keys;
    @{ $sql->{print} }{ @list_keys } = map{ [] } @list_keys;
    @{ $sql->{quote} }{ @list_keys } = map{ [] } @list_keys;
    $sql->{pr_col_with_scalar_func} = [];
    for my $x ( keys %$backup ) {
        for my $y ( keys %{$backup->{$x}} ) {
            $sql->{$x}{$y} = $backup->{$x}{$y};
        }
    }
    $sql->{select_type} = '*';
}


sub __unambiguous_key {
    my ( $self, $new_key, $keys ) = @_;
    while ( any { $new_key eq $_ } @$keys ) {
        $new_key .= '_';
    }
    return $new_key;
}


sub __write_json {
    my ( $self, $file, $h_ref ) = @_;
    my $json = JSON->new->utf8( 1 )->pretty->canonical->encode( $h_ref );
    open my $fh, '>', encode( 'locale_fs', $file ) or die $!;
    print $fh $json;
    close $fh;
}


sub __read_json {
    my ( $self, $file ) = @_;
    return {} if ! -f encode( 'locale_fs', $file );
    open my $fh, '<', encode( 'locale_fs', $file ) or die $!;
    my $json = do { local $/; <$fh> };
    close $fh;
    my $h_ref = {};
    if ( ! eval {
        $h_ref = decode_json( $json ) if $json;
        1 }
    ) {
        die "In '$file':\n$@";
    }
    return $h_ref;
}




1;

__END__
