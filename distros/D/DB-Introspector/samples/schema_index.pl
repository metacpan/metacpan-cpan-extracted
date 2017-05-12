#!/usr/bin/perl -w

use strict;
use warnings;
use constant DEBUG => 1;



use Getopt::Long qw( :config no_ignore_case bundling );
use Pod::Usage;

use vars qw( $VERBOSE $HELP $MAN %COMMAND_LINE @CONNECT_INFO );

use IO::File;
STDOUT->autoflush(1);

my %queue_constraints;

GetOptions(
    'f=i'       => \$COMMAND_LINE{filter_out},
    'h|help'    => \$HELP,
    'm|man'     => \$MAN,
    'v|verbose' => \$VERBOSE
);

@CONNECT_INFO = @ARGV;

# defaults
pod2usage(-exitstatus => 0, -verbose => 2) if $MAN;
pod2usage(0) if $HELP || @ARGV != 3;


=head1 NAME

schema_index.pl - Prints out a list (in alphabetical order) of tables, their columns, their foriegn keys and dependencies.

=head1 SYNOPSIS

schema_index.pl [options] datasource username password

 Options:
   -f [0|1]         open up stdin to filter out a list of tables (1) 
                    or filter them in (1)
   -h               print out help
   -m               reveal a man page
   -v               verbose

=head1 OPTIONS

=over 8

=item B<-f 0 | 1>

Opens up STDIN to filter out a list of table_names from the index. If 1 then filter out a list of table names passed into STDIN. If 0 then include only the tables passed into STDIN. If this option is omitted then this script assumes that you can include all tables in the schema.


=back


=head1 EXAMPLES

Print an schema index of the entire schema logged into

    schema_index.pl dbi:Oracle:somedb username password

Print an schema index and list only the tables in the table_list file.

    cat table_list | schema_index.pl -f 0 dbi:Oracle:somedb username password

Print an schema index and omit the tables in the table_list file.

    cat table_list | schema_index.pl -f 1 dbi:Oracle:somedb username password

If you want to print to your local printer you can pass the output to enscript

    cat table_list | schema_index.pl -f 1 dbi:Oracle:somedb username password > schema.txt

    # Prints in landscape mode (-r) with two pages per page using size 8 Arial font.
    enscript -r2 -fArial8 schema.txt

=head1 DESCRIPTION
                                                                                
TODO
                                                                                
=head1 VERSION
                                                                                
1.0
                                                                                
=head1 SEE ALSO

DB::Introspector

=head1 AUTHOR
                                                                                
Masahji C. Stewart
                                                                                
=cut


use DB::Introspector;
use constant INDENT => '    ';


my $dbh = DBI->connect(@CONNECT_INFO) || die();
my $introspector = DB::Introspector->get_instance($dbh);

my %filtered_tables;
if( defined $COMMAND_LINE{filter_out} ) {
    while(my $table_name = <STDIN>) {
        chop $table_name;
        $filtered_tables{$table_name} = $COMMAND_LINE{filter_out};
    }
}

my @ordered_tables = sort { $a->name cmp $b->name; }
                     grep {
                        if( defined $COMMAND_LINE{filter_out} ) {
                            if( $COMMAND_LINE{filter_out} ) {
                                !defined($filtered_tables{$_->name});
                            } else {
                                defined($filtered_tables{$_->name});
                            }
                        } else {
                            1;
                        }
                     } $introspector->find_all_tables();


print "$0: $CONNECT_INFO[1]\@$CONNECT_INFO[0]\n\n";


foreach my $table (@ordered_tables) {
    my $indent = 0;
    print $table->name."\n";
    $indent++;

    print (INDENT() x $indent);
    print "COLUMNS:\n";

    $indent++;
    foreach my $column ($table->columns) {
        print (INDENT() x $indent);
        my $column_type = ref($column);
        $column_type =~ s/.*:://g;
        print $column->name.":\t $column_type";
        print '('.$column->real_type.')' 
           if(UNIVERSAL::isa($column, 'DB::Introspector::Base::SpecialColumn'));
        print "\n";
    }
    $indent--;

    print (INDENT() x $indent);
    print "PRIMARY KEY: (".join(",", map { $_->name; } $table->primary_key).")\n";

    if( $table->indexes ) {
        print (INDENT() x $indent);
        print "INDEXES:\n";
        
        $indent++;
        foreach my $index ($table->indexes) {
            print (INDENT() x $indent);
            print $index->name;
            print ': (' .join(",", $index->column_names) .') ';
            print $index->unique ? 'UNIQUE' : 'NOT UNIQUE';
            print "\n";
        }
        $indent--;
    }

    if( $table->foreign_keys ) {
        print (INDENT() x $indent);
        print "FOREIGN KEYS:\n";
        
        $indent++;
        foreach my $foreign_key ($table->foreign_keys) {
            print (INDENT() x $indent);
            print $foreign_key->name.": " if( defined $foreign_key->name );
            print '('
                        .join(",", $foreign_key->local_column_names)
                 .')' .'->'
                . $foreign_key->foreign_table->name.'('
                        .join(",", $foreign_key->foreign_column_names)
                 .')';
            print "\n";
        }
        $indent--;
    }

    if( $table->dependencies ) {
        print (INDENT() x $indent);
        print "DEPENDENCIES:\n";
        
        $indent++;
        foreach my $foreign_key ($table->dependencies) {
            print (INDENT() x $indent);
            print $foreign_key->name.": " if( defined $foreign_key->name );
            print $foreign_key->local_table->name.'('
                        .join(",", $foreign_key->local_column_names)
                 .')' .'->'
                . '(' .join(",", $foreign_key->foreign_column_names) .')';
            print "\n";
        }
        $indent--;
    }

    print "\n\n";
}

1;
