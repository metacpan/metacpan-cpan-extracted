#!/usr/bin/perl -w 


use strict;

use Getopt::Long;
use DB::Introspector;
use DBI;

use subs qw(
    main 
    render_table 
    print_with_indent 
    introspector 
);

my %params;
my %options = (
    "r" => \$params{recurse_children},
    "m" => \$params{recurse_foreign_keys},
    "f" => \$params{foreign_keys},
    "c" => \$params{columns},
    "a" => \$params{all_properties},
    "v" => \$params{verbose},
    "l=i" => \$params{max_length},
    "t=s" => \$params{table},
    "u=s" => \$params{username},
    "p=s" => \$params{password},
    "d=s" => \$params{datasource},
);

# Environment provided variables
use vars qw(%ENV);
use vars qw( $INTROSPECTOR %TRAVERSED_TABLES );

my $result = GetOptions(%options);

die("table not defined. use -t") unless($params{table});

$params{datasource} = $params{datasource} || $ENV{DBINTRO_DS} 
            || die("undefined datasource. use param -d or env DBINTRO_DS");

$params{username} = $params{username} || $ENV{DBINTRO_USER}
            || die("undefined username. use param -u or env DBINTRO_USER");

$params{password} = $params{password} || $ENV{DBINTRO_PW}
            || die("undefined username. use param -p or env DBINTRO_PW");

# properties that can be determined by other properties
$params{foreign_keys} = $params{foreign_keys} || $params{all_properties};
$params{columns} = $params{columns} || $params{all_properties};



&main;

sub main {
    my $table = introspector()->find_table($params{table})
        || die("$params{table} can't be found.");
    &render_table($table);
}

sub render_table {
    my $table = shift;
    my $levels = shift||0;

    my $indent = $levels * 5;


    return if( $TRAVERSED_TABLES{$table->name} );

    $TRAVERSED_TABLES{$table->name} = 1;

    &print_with_indent($indent, "Table: ".$table->name);
    if( $params{columns} ) {
        &print_with_indent($indent + 1, "Columns: ");
        foreach my $column ($table->columns) {
            &print_with_indent($indent + 2, $column->name."(".ref($column).")");
        }
    }

    if( $params{foreign_keys} ) {
        my @foreign_keys = $table->foreign_keys;
        &print_with_indent($indent + 1, "Foreign Keys: ") if(@foreign_keys);
        foreach my $foreign_key (@foreign_keys) {
            &print_with_indent($indent + 2, 
                "(".join(",", $foreign_key->local_column_names).") "
                .$foreign_key->foreign_table->name
                ."(".join(",",$foreign_key->foreign_column_names).")");
        }
    }

    if( $params{recurse_children} ) {
        if( !defined($params{max_length}) 
        || (defined $params{max_length} && ++$levels == $params{max_length})) {
            foreach my $foreign_key ($table->dependencies) {
                &render_table($foreign_key->local_table, $levels + 1);
            }
        }
    }


    if( $params{recurse_foreign_keys} ) {
        if( !defined($params{max_length}) 
        || (defined $params{max_length} && ++$levels == $params{max_length})) {
            print_with_indent(0,"\n");
            foreach my $foreign_key ($table->foreign_keys) {
                &render_table($foreign_key->foreign_table, $levels + 1);
            }
        }
    }


}

sub print_with_indent {
    my $levels = shift;
    my $string = shift;

    print " " x $levels;
    print "$string\n";
}


sub introspector {
    unless( $INTROSPECTOR ) {
        my $dbh = DBI->connect( $params{datasource}, 
                                $params{username}, $params{password});
        $INTROSPECTOR =  DB::Introspector->get_instance($dbh);
    }
    return $INTROSPECTOR || die("could not instantiate introspector");
}


__END__

=head1 NAME

table_info.pl

=head1 SYNOPSIS

table_info.pl [-m] [-f] [-c] [-a] [-u username] [-p password] [-d datasource] table_name

table_info.pl -u test -p testpw -d dbi:Pg:dbname=test -m -a -t users

=head1 DESCRIPTION

 table_info retrieves detailed information about the table, table_name,
 determined from the database metadata.  

=head1 FLAGS

=over 4

=item Recurse through foreign keys [-m]

=item Reveal foreign keys [-f]

=item Reveal column info [-c]

=item Show all properties [-a]

=item Verbose

=item Max traversal depth [-l integer]

=item Table name [-t table_name] 

=item Database username [-u username] 

=item Database password [-p password] 

=item Datasource connect string [-d datasource]

=back

=head1 AUTHOR

Masahji C. Stewart

=head1 SEE ALSO

L<DB::Introspector>


=head1 COPYRIGHT

The table_info script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
