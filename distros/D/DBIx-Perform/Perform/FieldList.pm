package DBIx::Perform::FieldList;

use strict;
use Data::Dumper;
use DBIx::Perform::UserInterface;
use DBIx::Perform::SimpleList;
use DBIx::Perform::Field;
use base 'Exporter';
use DBI;

our $VERSION = '0.693';

# debug: set (unset) in runtime env
$::TRACE      = $ENV{TRACE};
$::TRACE_DATA = $ENV{TRACE_DATA};

our @EXPORT_OK = qw(
  &new
  &is_empty
  &not_empty
  &is_first
  &is_last
  &reset
  &iterate_list
  &look_ahead
  &current_field
  &next_field
  &previous_field
  &add_field
  &list_cursor
  &remove_field
  &insert_field
  &replace_field
  &last_field
  &first_field
  &init_cursor
  &list_size
  &clear_list
  &clone_list
  &copy_self
  &dump_list
  &print_list
  &get_serial_field
  &get_columns
  &get_field_tags
  &get_field_tag
  &get_field_object
  &get_fields_by_field_tag
  &get_fields_by_table_and_column
  &create_subset
  &stuff_list
  &get_attribute_table_names
  &init_displayonly_table_names
  &display_defaults_to_screen
  &set_db_type_values
);

# Simple list operations
sub new {
    my $class = shift;

    my $list = new DBIx::Perform::SimpleList;

    bless my $self = { list => $list, } => ( ref $class || $class );

    return $self;
}

sub is_empty {
    my $self = shift;

    return $self->{list}->is_empty;
}

sub not_empty {
    my $self = shift;

    return $self->{list}->not_empty;
}

sub is_first {
    my $self = shift;

    return $self->{list}->is_first;
}

sub is_last {
    my $self = shift;

    return $self->{list}->is_last;
}

sub reset {
    my $self = shift;

    return $self->{list}->reset;
}

sub iterate_list {
    my $self = shift;

    return $self->{list}->iterate_list;
}

sub look_ahead {
    my $self = shift;

    return $self->{list}->look_ahead;
}

sub current_field {
    my $self = shift;

    return $self->{list}->current_row;
}

sub next_field {
    my $self = shift;

    return $self->{list}->next_row;
}

sub previous_field {
    my $self = shift;

    return $self->{list}->previous_row;
}

sub add_field {
    my $self  = shift;
    my $field = shift;

    return $self->{list}->add_row_to_end($field);
}

sub list_cursor {
    my $self = shift;

    return $self->{list}->list_cursor;
}

sub remove_field {
    my $self = shift;

    return $self->{list}->remove_row;
}

sub insert_field {
    my $self  = shift;
    my $field = shift;

    return $self->{list}->insert_row;
}

sub replace_field {
    my $self = shift;
    my $row  = shift;

    return $self->{list}->replace_row;
}

#sub last_field {
#    my $self = shift;
#
#    return $self->{list}->last_row;
#}

sub first_field {
    my $self = shift;

    $self->{iter} = 0;
    return $self->{list}->first_row;
}

sub init_cursor {
    my $self = shift;

    $self->{list}->{iter} = 0;
}

sub list_size {
    my $self = shift;

    return $self->{list}->list_size;
}

sub clear_list {
    my $self = shift;

    $self->{list}->clear_list;
}

# NOTE: the approach to cloning the list could be
# replaced by one that just creates a new iterator.
# This might give a slight runtime performance improvement
# The point in cloning is to ensure that nested iterating
# through the global field list won't confuse iterator value
# of the outer loop.  But, to my knowledge this hasn't been a 
# problem, due to careful design (heh heh).

sub clone_list {
    my $self = shift;

    my $list = $self->{list}->clone_list;
    my $rl   = new DBIx::Perform::FieldList;
    $rl->{list} = $list;

    return $rl;
}

sub copy_self {
    my $self = shift;

    my $ret = $self->clone_list;

    return $ret;
}

sub dump_list {
    my $self = shift;

    $self->{list}->dump_list;
}

sub print_list {
    my $self = shift;

    my $q = $self->clone_list;

    print STDERR "top: $q->{top}\n";
    print STDERR "iter: $q->{iter}\n";
    print STDERR "size: $q->{size}\n";
    print STDERR "rows array: \n";

    $q->reset;
    while ( my $fo = $q->iterate_list ) {
        $fo->print;
    }
}

# Field list support routines

# returns only one field
sub get_serial_field {
    my $self = shift;
    my $fl   = $self->clone_list;

    $fl->reset;
    while ( my $fo = $fl->iterate_list ) {
        if ( defined( $fo->is_serial ) ) {
            return $fo;
        }
    }
    return undef;
}

sub get_columns {
    my $self  = shift;
    my $table = shift;

    my $list    = $self->clone_list;
    my @columns = ();

    $list->reset;
    while ( my $field = $list->iterate_list ) {
        next if $field->{displayonly};
        my ( $tag, $tab, $col ) = $field->get_names;
        push( @columns, $col )
          if $tab eq $table && length $col > 0;
    }
    return @columns;
}

sub get_field_tags {
    my $self  = shift;
    my $table = shift;

    my $list = $self->clone_list;
    my @tags = ();

    $list->reset;
    while ( my $field = $list->iterate_list ) {
        my ( $tag, $tab, $col ) = $field->get_names;
        push( @tags, $tag ) if $tab eq $table;
    }
    return @tags;
}

sub get_field_tag {
    my $self   = shift;
    my $table  = shift;
    my $column = shift;

    my $list = $self->clone_list;
    my @tags = ();

    # routine can have single, "table.column" argument
    if ( !defined($column) ) {
        ( $table, $column ) = split /\./, $table;
    }
    if ( !defined($table) || !defined($column) ) {
        warn "invalid arguments to get_field_tag";
        return undef;
    }

    $list->reset;
    while ( my $fo = $list->iterate_list ) {

        my ( $tag, $tab, $col ) = $fo->get_names;
        return $fo if $table eq $tab && $column eq $col;
    }
    return undef;
}

sub get_field_object {
    my $self      = shift;
    my $table     = shift;
    my $field_tag = shift;

    warn "entering get_field_object :$table:$field_tag:\n" if $::TRACE;

    my $list = $self->clone_list;
    $list->reset;
    while ( my $field = $list->iterate_list ) {
        my ( $tag, $tab, $col ) = $field->get_names;
        if ( ( $tab eq $table ) && ( $tag eq $field_tag ) ) {
            warn "leaving get_field_object 1 :$table:$field_tag:\n"
              if $::TRACE;
            return $field;
        }
    }
    warn "TRACE: leaving get_field_object 2 :$table:$field_tag:\n" if $::TRACE;
    return undef;
}

sub get_fields_by_field_tag {
    my $self      = shift;
    my $field_tag = shift;

    if ( !$field_tag ) { return undef; }

    my @fields;
    my $list = $self->clone_list;
    $list->reset;

    while ( my $field = $list->iterate_list ) {
        if ( $field->{field_tag} eq $field_tag ) {
            push( @fields, $field );
        }
    }
    return \@fields;
}

sub get_fields_by_table_and_column {
    my $self   = shift;
    my $table  = shift;
    my $column = shift;

    if ( !$table || !$column ) { return undef; }

    my @fields;
    my $list = $self->clone_list;

    $list->reset;
    while ( my $fo = $list->iterate_list ) {
        if ( $fo->{table_name} eq $table ) {
            push( @fields, $fo )
              if $fo->{column_name} eq $column;
        }
    }
    return \@fields;
}

# each screeen has its own set of fields in its own order
# make a field list for a screen and return it
sub create_subset {
    my $self   = shift;
    my $fields = shift;

    die "no field parm!" unless defined($fields);
    my $return_q = new DBIx::Perform::FieldList;

    # make local copy
    my $q = $self->copy_self( $self->{list} );

    foreach my $fname (@$fields) {
        $q->reset;
        while ( my $fo = $q->iterate_list ) {
            my ( $field_tag, $table, $column ) = $fo->get_names;
            if ( $field_tag eq $fname ) {
                $return_q->add_field($fo);
            }
        }
    }
    return $return_q;
}

sub stuff_list {
    my $self   = shift;
    my $parser = shift;
    my $tables = shift;

    my $line;
    my $previous_tag;
    my $lines = '';
    while ( $line = $parser->read_line() ) {

        #        /(("([^"\\]|\\.)*")|('([^'\\]|\\')*')|[^{])*/
        chomp $line;
        $lines .= ' ' . $line;
        next unless $line =~ /;/;

        # strip out leading comments
        my ( $front, $back ) = split( /\*\/\}/, $lines );
        my $parsable = $front;    # no comments
        $parsable = $back if $back;    # comments present
        $lines = '';

        my $field = new DBIx::Perform::Field;
        if ( $field->parse_line($parsable) ) {

            if ( $field->{field_tag} eq "EMPTY_FIELD_TAG" ) {
                $field->{field_tag} = $previous_tag;
            }
            $self->add_field($field);
            $previous_tag = $field->{field_tag};
        }
    }
}

# Return an array of tables used in the per file
# in the order they show up in the attributes section
# doesn't returned "lookup" table names
sub get_attribute_table_names {
    my $self = shift;

    if ( $self->is_empty ) { return undef; }

    my @tables;
    my %tables;

    my $fl = $self->clone_list;

    $fl->reset;
    while ( my $fo = $fl->iterate_list ) {

        # skip fields derived from lookup attributes
        next if $fo->{join_table} || defined $fo->{displayonly};

        my $table_name = $fo->{table_name};
        if ( $tables{$table_name} != 1 ) {
            $tables{$table_name} = 1;    # treat hash as a set
            push( @tables, lc $table_name );
        }
    }
    return \@tables;
}

sub init_displayonly_table_names {

    my $self = shift;

    my $ui     = $DBIx::Perform::GlobalUi;
    my @tables = @{ $ui->{attribute_table_names} };

    $self->reset;
    while ( my $ft = $self->iterate_list ) {
        if ( $ft->{displayonly} ) {
            $ft->{table_name} = $tables[$#tables]
              if !defined $ft->{allowing_input};
        }
    }
}

# Displays default values for addmode start
sub display_defaults_to_screen {
    my $self = shift;
    my $ui   = shift;

    my $fl = $self->clone_list;

    $fl->reset;
    while ( my $fo = $fl->iterate_list ) {

        # general default handling
        my $value = $fo->{default};    # default values are set by parser
#        $value = '' if !defined($value);
        next if !defined($value);

        my ( $tag, $tab, $col ) = $fo->get_names;

        # handle SERIAL values
        if ( $fo->{db_type} eq 'SERIAL' ) {
#            $value          = 0;
            $fo->{noupdate} = 1;
            $fo->{noentry}  = 1;
        }

        # handle date format for TODAY
#        $value = POSIX::strftime( "%Y-%m-%d", localtime() )
        if (uc($value) eq 'TODAY') {
            my $date_format = lc($ENV{DBDATE} || "MDY4/"); #Informix specific?
            $date_format =~ s/^(.{4})$/$1\//;
            $date_format =~ s/0//;
            $date_format =~ s/y4/Y/;
            $date_format =~ s/y2/y/;
            $date_format =~ s/(\w)(\w)(\w)(.?)/%$1$4%$2$4%$3/;
            $value = POSIX::strftime( $date_format, localtime() )
        }

        $fo->set_value($value); # if !defined $fo->get_value;
        $fo->format_value_for_display( $fo->get_value );
        $ui->set_screen_value( $tag, $fo->get_value );
    }
    return undef;
}

# Sets database information for FieldList contents
sub set_db_type_values {
    my $self     = shift;
    my $database = shift;

    warn "entering set_db_types\n" if $::TRACE;

    my $ui = $DBIx::Perform::GlobalUi;

#    my @tables = @{ $ui->{attribute_table_names} };
    my @tables = @{ $ui->{defined_table_names} };
    my $driver = $database->{'Driver'}->{'Name'};

    my $fl = $self->clone_list;
    if ( $driver eq "Informix" ) {
        foreach my $table (@tables) {

            # get a statement handle for the metadata
            my $cname;
            my $type;
            my $query = "SELECT * FROM $table";
            my $sth   = $database->prepare($query);
            unless (defined $sth) {
                die "\n\nInitial query failed:\n$query\n";
            }

            my @db_cols = @{ $sth->{NAME} };    # Column names
            my @db_nulls =
              @{ $sth->{NULLABLE} };    # '1' if col accepts nulls or '0' if not
            my @db_type_names = @{ $sth->{ix_NativeTypeName} };    # Type name

            $fl->reset;
            while ( my $fo = $fl->iterate_list ) {
                my ( $tag, $tab, $col ) = $fo->get_names;

                # add database info to the field object
                my $limit = $#db_cols;
                for ( my $i = 0 ; $i <= $limit ; $i++ ) {

                    if ( ( $table eq $tab ) && ( $db_cols[$i] eq $col ) ) {
                        $fo->{db_type}    = uc $db_type_names[$i];
                        $fo->{db_null_ok} = $db_nulls[$i];
                        if ( $fo->{db_null_ok} == 0 ) {
                            undef $fo->{null_ok};
                            undef $fo->{db_null_ok};
                        }
                        if ( defined $fo->{include} ) {
                            undef $fo->{null_ok}
                              if $fo->{db_null_ok} == 0;
                        }
                    }
                }
            }
        }

        # refine type null and size values
        # using "logic" - oooo, spooky
        $fl->reset;
        while ( my $fo = $fl->iterate_list ) {
            $fo->set_field_null_ok;
            $fo->set_field_size;
            $fo->set_field_type;
        }
    }
    else {    # put Oracle solution here
        warn
          "subroutine \"set_db_type_values\" for $driver is not implemented.";
    }
    return undef;
}

1;
