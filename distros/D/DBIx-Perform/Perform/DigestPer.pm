=head1 NAME

DBIx::Perform::DigestPer  -  "Perform" screen file digester

Digests an Informixoid .per file and make a string suitable for
writing to a file or just eval'ing.

The manual used as reference for the Perform scripting language is:

INFORMIX-SQL Reference, INFORMIX-SQL Version 6.0, April 1994,
Part No. 000-7607

=head1 MODULE VERSION

0.04

=head1 SYNOPSIS

    use DBIx::Perform::DigestPer;
    $desc = digest(*INFILE_HANDLE);
    # now do the right thing with $desc

    shell>  perl -MDBIx::Perform::DigestPer -e'digest_file("foo.per")'
    # writes file foo.pps or named in 2nd argument.
    # now read and do the right thing with foo.pps

=head1 REQUIREMENTS

Data::Dumper

=head1 DESCRIPTION

Digests an Informix "Perform" screen descriptor file into a form usable by 
the Perform emulator B<Perform.pm>.  May be used inline or to write a file.

Among other things, it digests the screen layout into a series of Curses 
widget specs, as either Label or TextField types.

The output string/file is evaluable Perl source code, which 
sets four variables:

$db: name of database

$screen: screen descriptor, a hash including a Curses::Forms spec.
	Form fields' widgets are named as labelled (e.g. 'f000').

$tables: array of table names.

$attrs:  hash of field names to [table column attributes] .
	The 'attributes' string is unparsed.



CHANGES from version 0.05:
Total rewrite of the parsing of the "attribute" section,
greatly expanded parsing of the "instructions" section.

User creates an intermediate file in YAML with "convert_per_to_yml" sub.

User runs DBIx::Perform on the .yml file.

Brenton Chapin, Martin Baer, et. al...
Valtech (www.valtech.com)
=cut

package DBIx::Perform::DigestPer;
use strict;
use base 'Exporter';

use vars qw(@EXPORT_OK $VERSION %HEADING_WORDS);

BEGIN {
    @EXPORT_OK = qw(digest digest_file convert_per_to_xml convert_per_to_yml );
    $VERSION   = '0.695';

    %HEADING_WORDS =
      map { ( $_, 1 ) } qw(screen tables attributes instructions end);

}

# debug: set (unset) in runtime env
$::TRACE      = $ENV{TRACE};
$::TRACE_DATA = $ENV{TRACE_DATA};

#use DBIxPerformCFuncs;
#use XML::Dumper;
use YAML;
use Data::Dumper;
use DBIx::Perform::FieldList;

=head2  digest

   digest (IOHandle_Ref)

Digests an Informix .per file into a string that evaluates to a Perform
descriptor.

=cut

our $VER_DATE = '2007-10-17';

our $TABLES;
our $FieldList;
our $DB;

sub digest {
    shift if ( $_[0] eq __PACKAGE__ );
    my $ioh = shift;

    warn "TRACE: entering digest\n" if $::TRACE;

    my $parser = new DBIx::Perform::DigestPer::Parser($ioh);
    my $word;
    my ( $db, $tables, $atts, $instrs );
    my $screens = [];
    local $TABLES;    # for attributes parser to check
    my $connected = 0;
    while ( $word = $parser->read_token('true') ) {
        if ( $word eq 'database' && !$connected ) {
            $connected = 1;
            $db = read_database($parser);
        }
        elsif ( $word eq 'screen' ) {
            push( @$screens, read_screen($parser) );    # might return many
        }
        elsif ( $word eq 'tables' ) {
            $TABLES = $tables = read_tables($parser);
        }
        elsif ( $word eq 'attributes' ) {
            read_attributes($parser);    # fills global $FieldList
            $FieldList->print_list if $::TRACE_DATA;
        }
        elsif ( $word eq 'instructions' ) {
            $instrs = read_instructions($parser);
        }
    }
    my $str = output_string( $db, $screens, $tables, $instrs, $VER_DATE );
    my @ret = ( $str, $FieldList );

    # need to close the database?

    return \@ret;
}

sub read_database {
    my $parser = shift;

    warn "TRACE: entering read_database \n" if $::TRACE;

    my $db_name = $parser->read_token();    # just the name.
    $DB = DBIx::Perform::DButils::open_db($db_name);

    warn "TRACE: leaving read_database \n" if $::TRACE;

    return $db_name;
}

sub read_screen {
    warn "TRACE: entering read_screen\n" if $::TRACE;
    my @screens;
    my $parser = shift;

    my $result = {};
    my $word;

    #default height,width.  Page 2-10 of the manual
    my $height = 20;
    my $width  = 80;
    while ( $word = $parser->read_token() ) {
        if ( $word eq 'size' ) {

            # read size...
            $height = 0 + $parser->read_token();
	    $height = 20 if $height > 20;
            my $by = $parser->read_token();
            $width = 0 + $parser->read_token();
            die "Expected 'by' but got '$by'"
              if ( $by ne 'by' );
            $result->{'MINSIZE'} = [ $width, $height ];
        }
        elsif ( $word eq '{' ) {

            # read screen format
            my $widgets = {};
            my $line;
            my $lineno  = 0;
            my $labelno = '000';
            my @fields  = ();
            my $more    = 1;
            while ($more) {
                $line = $parser->read_line();
                if ( $line =~ /(^|[^\\]|(\\\\)+)\}/ ) {
                    $line = $1;
                    $more = 0;
                    last if $line eq '';
                }
                if ( $lineno >= $height ) {
                    push(
                        @screens,
                        {
                            WIDGETS => $widgets,
                            FIELDS  => [@fields],
                            LINES   => $lineno,
                        }
                    );
                    $widgets = {};
                    @fields  = ();
                    $lineno  = 0;
                }
                my $x = 0;
                while ( $line =~ s/\t/' ' x (8-pos($line)%8)/e ) { }
                $line =~ s/\\(.)/$1/;
                while ( $line =~ /(\s*)(\[\s*(\w+)\s*\]|[^\s[][^[]*)/g ) {
                    my $pre   = $1;
                    my $match = $2;
                    my $id    = $3;
                    $x += length($pre);
                    my $cols = length($match);
                    if ($id) {

                        # it\'s a field
                        # Note, the OnEnter/OnExit subs must be supplied
                        # by the Perform emulator.
                        $widgets->{$id} = {
                            TYPE    => 'TextField',
                            COLUMNS => $cols - 2,
                            Y       => $lineno,
                            X       => $x + 1,
                            BORDER  => 0
                        };
                        push( @fields, $id );
                    }
                    else {

                        # it\'s a label
                        $match =~ s/\s$//;    # ignore trailing whitespace
                        $widgets->{"label_$labelno"} = {
                            TYPE    => 'Label',
                            COLUMNS => $cols,
                            Y       => $lineno,
                            X       => $x,
                            VALUE   => $match
                        };
                        $labelno++;
                    }
                    $x += $cols;
                }
                $lineno++;
            }
            push(
                @screens,
                {
                    WIDGETS => $widgets,
                    FIELDS  => [@fields],
                    LINES   => $lineno
                }
            );
        }
        elsif ( lc($word) eq 'end' ) {
            return @screens;
        }
        else {
            die "Unknown screen section directive '$word'";
        }
    }
    return @screens;
}

sub read_tables {
    my $parser = shift;

    warn "TRACE: entering read_tables\n" if $::TRACE;

    my $line;
    my @tables;
    my $in_comment = undef;
    my $builder    = undef;

    while ( $line = $parser->read_line() ) {
        chomp $line;
        undef $builder;

        # scrub the line for comments
        my @line = split //, $line;
        for ( my $i = 0 ; $i <= $#line ; $i++ ) {
            my $c = $line[$i];
            if ( $c eq '{' ) {
                $in_comment = 1;
                $i++;    # skipt it
                $builder .= ' ' if $i != $#line;
            }
            if ( $c eq '}' ) {
                undef $in_comment;
                $i++;    # skipt it
            }
            $builder .= $line[$i] if !defined $in_comment;
        }
        push( @tables, $builder =~ /(\w+)/g );
    }
    warn "TRACE: leaving read_tables\n" if $::TRACE;
    return [@tables];
}

# POST PROCESSING

# There are a few "post" files below.
# The basic idea is that the attribute parsing
# gathers up the information for each line (ends with ";")
# and the post processing, handles issues that span lines
# or generate new field list elements ( like lookup field objects).
# Botton line:  post processing occurs in "post" subroutines

# Displayonly post processing
sub displayonly_post_processing {
    my $field = shift;

    # displayonly fields are "virtual" (they don't exist in the DB)
    # the column name has the value of the field tag
    if ( defined( $field->{displayonly} ) ) {
        $field->{column_name} = $field->{field_tag};
        $field->{table_name}  = "displaytable";
    }
    return $field;
}

# Tables post processing ( not related to read_tables )
sub table_post_processing {
    my $field = shift;

    my @tables = @{$TABLES};
    my $previous_table;
    if ( $#tables == 0 ) {
        $previous_table = $tables[0];
    }
    if ( $field->{table_name} eq '' ) {

        # go to the db and get the table name
        # look for the column in each table
        # fails if there is a dup across tables

        my $column   = $field->{column_name};
        my $database = $DB;
        my $driver   = $database->{'Driver'}->{'Name'};

        if ( $driver eq "Informix" ) {
            foreach my $table (@tables) {
                my $cname;
                my $type;

                my $query   = "SELECT * FROM $table";
                my $sth     = $database->prepare($query);
		if ($sth) {
                    my @db_cols = @{ $sth->{NAME} };             # Column names
                    my @res     = grep( /$column/, @db_cols );
                    if ( defined(@res) ) {
                        $field->{table_name} = $table;
                        last;
		    }
                }
            }
        }
        else {    # put Oracle solution here
            die
"subroutine \"table_post_processing\" for $driver is not implemented.";
        }
    }
    if ( uc $field->{table_name} eq uc $field->{column_name} ) {
        $field->{table_name} = $previous_table;
    }

    return $field;
}

# Field tag joins postprocessing
sub field_tag_joins_post {
    my $field          = shift;
    my $previous_field = shift;

    return $field
      if defined( $field->{display_only} );

    # here are the primary examples of these joins:
    # 1:     field_tag = tab1.col = tab2.col, attributes;
    # 2:               = tab1.col, attributes;

    my $previous_tag   = '';
    my $previous_table = '';
    my $previous_col   = '';

    if ( defined($previous_field) ) {
        ( $previous_tag, $previous_table, $previous_col ) =
          $previous_field->get_names;
    }

    # this takes care of #2
    if ( uc( $field->{field_tag} ) eq "EMPTY_FIELD_TAG" ) {
        $field->{field_tag} = $previous_tag;
    }
    {
        my $tbl = $field->{table_name};
        my $col = $field->{column_name};
        $field->{verify} = 1 if
          $field->{line} =~ /\*\s*$tbl\.$col(\W|$)/;
    }

    # adding the top-level field object for this itteration
    $FieldList->add_field($field);

    # this takes care of #1 - new field for each tab.col
    if ( defined( $field->{field_tag_join_hash} ) ) {
        my %join = %{ $field->{field_tag_join_hash} };

        my $size  = 0;
        my $index = 0;
        $size += keys %join;

        while ( $index < $size ) {

            my $join_table  = $join{$index}->{join_table};
            my $join_column = $join{$index}->{join_column};

            my $new_field = $field->duplicate;
            delete $new_field->{verify};
            delete $new_field->{line};
#            $new_field->{field_tag_join_hash} = undef;
            $new_field->{table_name}          = $join_table;
            $new_field->{column_name}         = $join_column;
            $new_field->{verify} = 1 if
               ($field->{line} =~ /\*\s*$join_table\.$join_column(\W|$)/);

            # expand lookup attributes (if any)  for the new field
            lookup_attributes_post($new_field);

            # add new field
            $FieldList->add_field($new_field);

            $index++;
        }
    }
    warn Data::Dumper->Dump( [$field], ['field in digest'] ) if $::TRACE_DATA;

    return $field;
}

# Lookup attribute postprocessing
sub lookup_attributes_post {
    my $field = shift;

    # if field contains a lookup statement, expand the
    # embedded field_tags into new objects & add to FieldList
    # new fields can (currently always do) have the attribute
    # of the parent.  Currently ordered as they appear in the
    # .per file

    my %instances = %{ $field->{lookup_hash} }
      if defined( $field->{lookup_hash} );

    if ( defined(%instances) ) {
        my ( $size, $index, $join_table, $join_column, $verify );
        my $index = 0;
        my $size  = 0;
        $size += keys %instances;

        while ( $index < $size ) {

            #warn Data::Dumper->Dump([%instances], ['instances in digest']);

            my %lookup = %{ $instances{$index} };

            # capture  the join table and column
            $join_table = $join_column = $verify = undef;

            foreach my $k ( keys(%lookup) ) {
                my %h = %{ $lookup{$k} };
                my $t = lc $h{join_table};
                my $c = lc $h{join_column};
                my $v = $h{verify};

                $t = undef if $t eq '';
                $c = undef if $c eq '';
                $v = undef if $v eq '';

                $join_table  = $t if defined($t);
                $join_column = $c if defined($c);
                $verify      = $v if defined($v);
            }

            my @join_order;
            $#join_order = 1000;
            foreach my $k ( keys(%lookup) ) {
                warn Data::Dumper->Dump( [%lookup], ['lookup in digest'] )
                  if $::TRACE_DATA;

                my $new_field = new DBIx::Perform::Field;

#                $new_field->{lookup_hash}         = undef;
#                $new_field->{field_tag_join_hash} = undef;

                $new_field->{field_tag} = lc $k;
#                $new_field->{line}      = "Lookup Field";

                my %h = %{ $lookup{$k} };
                foreach my $l ( keys(%h) ) {
                    $new_field->{$l} = lc $h{$l};
                }
                $new_field->{join_table}  = $join_table;
                $new_field->{join_column} = $join_column;
                $new_field->{verify}      = $verify if $verify;

                # lookups only "display" field values
                # and only on a match between them

## not sure that the above comment is true at runtime
#                $new_field->{noentry}  = 1;
#                $new_field->{noupdate} = 1;

                if ( uc $new_field->{table_name} eq "EMPTY_TABLE_NAME" ) {
#                    $new_field->{table_name} = $field->{table_name};
                    $new_field->{table_name} = $join_table;
                }

                $new_field->{active_tabcol} =
                  $field->{table_name} . "." . $field->{column_name};

                # add the new field
                # FIX: currently lookup fields in the same instance
                # are unordered.  This will affect taborder - may not matter
                # so this is now an attempt to order these guys....
                my $jindex = $new_field->{join_index};
                @join_order[$jindex] = $new_field;
            }

            # add new fields in the order they were parsed
            foreach my $new_field (@join_order) {
                $FieldList->add_field($new_field) if defined $new_field;
            }

            $index++;
        }
    }
    return $field;
}

# Include attribute post processing
sub include_post_processing {
    my $field = shift;

    $field->{include} = 1
      if defined( $field->{range} );
    $field->{include} = 1
      if defined( $field->{include_values} );

    return $field;
}

# Creates field objects after compling a line of the parse
# to hold the line information returned from the parser
sub make_field_obj {
    my $line           = shift;
    my $previous_field = shift;
    my $gparser        = shift;

    # strip out comments { ... } FIX: needs regex for "xxx { {...} } yyy;"
    my @text = split( /\{.*\}/, $line );
    my $parsable = $#text > 0 ? @text[$#text] : $text[0];

    my $field = new DBIx::Perform::Field;

    if ( $field->parse_line($parsable, $gparser) ) {
        $field = table_post_processing($field);
        $field = field_tag_joins_post( $field, $previous_field );
        $field = lookup_attributes_post($field);
        $field = displayonly_post_processing($field);
        $field = include_post_processing($field);
    }
    delete $field->{line};
    return $field;
}

# Reads and processes the attributes section of a "per" file
sub read_attributes {
    my $parser = shift;

    warn "TRACE: entering read_attributes\n" if $::TRACE;

    my $line;
    my $lines = '';

    my $previous_field = undef;
    $FieldList = new DBIx::Perform::FieldList;

    my $in_comment = undef;
    my $builder    = undef;

    my $grammar = DBIx::Perform::AttributeGrammar::get_grammar;
    my $gparser = Parse::RecDescent->new($grammar);

    while ( $line = $parser->read_line() ) {
        chomp $line;
        undef $builder;

        # scrub the line for comments
        my @line = split //, $line;
        for ( my $i = 0 ; $i <= $#line ; $i++ ) {
            my $c = $line[$i];
            if ( $c eq '{' ) {
                $in_comment = 1;
                $i++;    # skipt it
                $builder .= ' ' if $i != $#line;
            }
            if ( $c eq '}' ) {
                undef $in_comment;
                $i++;    # skipt it
            }
            $builder .= $line[$i] if !defined $in_comment;
        }
        $lines .= ' ' . $builder;

        return if $builder =~ /^\s*end\s*$/i;
        next unless $builder =~ /;/;

        my $tmp_line = $lines;
        my $field = make_field_obj( $tmp_line, $previous_field, $gparser );

        $previous_field = $field;
        $lines          = '';
    }
    warn "TRACE: leaving read_attributes\n" if $::TRACE;
    warn "done parsing attributes"          if $::TRACE;
}

sub read_instructions {
    my $parser = shift;

    my $line;
    my $instrs     = {};
    my $got_a_line = 0;
    my $lcomment   = 0;
    my $csm        = 0;
    my @cjcols;
    my $cjverify = 0;
    my %current_cj;

    while ( $got_a_line ? 1 : { $line = $parser->read_line() } ) {
        $got_a_line = 0;
        last if !defined $line;

        #        warn "instruction = :$line:\n";
        if ($lcomment) {
            $line =~ s/[^}]*//;
            if ( $line =~ s/}// ) {
                $lcomment = 0;
            }
        }
        $line =~ s/^\s*{[^}]*}//;
        if ( $line =~ s/^\s*{.*?// ) {
            $lcomment = 1;
            next;
        }
        next if $line =~ /^\s*$/;
        last if $line =~ /^\s*end\s*$/i;
        if ( $line =~ /^\s*(\w+)\s+master\s+of\s+(\w+)/i ) {
            push( @{ $$instrs{MASTERS} }, [ $1, $2 ] );
        }
        elsif ( $line =~ s/composites//i || $csm ) {

       #The "composites" instruction seems to be useless.
       #If 2 or more columns of 2 tables are joined, they must be
       #  a) joined in the attributes section
       #  b) and listed in a "composites" instruction.
       #From page 2-57:
       #  "Each column included in a composite join must also be individually
       #  joined in the ATTRIBUTES section of the form specification."
       #and
       #  "There can be no additional joins between columns of the two tables
       #   that are not included in the composite join"
       #In other words, having a "composites" instruction to
       #join 2+ columns of 2 tables without joining them in the attributes
       #section is, according to the manual, not allowed.
       #However, sformbld only generates a warning in this case.
       #In the other way around, having 2+ columns of 2 tables joined in
       #the attributes section without a "composites" instruction,
       #sformbld will produce an error.
       #So, checking for joins in the "attributes" section and treating any
       #joins after the first one between two tables as part of a composite join
       #should cover this situation, without needing to check for a "composites"
       #instruction.  So all we will do here is parse the instruction.
       #We won't bother issuing an error if it doesn't match what was already
       #completely specified in the "attributes" section.
       #During execution, this instruction is used for
       #verification of composite joins.
            if ( $csm == 0 ) {
                %current_cj = ();
                $csm        = 1;
            }
            $cjverify = 1 if $line =~ s/^\s*\*// && $csm == 11;
            $csm++ if ( $line =~ s/^\s*\<// && ( $csm == 1 || $csm == 11 ) );

            do {
                do {
                    if (
                        $line =~ s/^\s*([A-Za-z]\w*)//
                        && (   $csm == 2
                            || $csm == 12
                            || $csm == 3
                            || $csm == 13 )
                      )
                    {
                        if ( $csm == 2 ) {
                            $current_cj{TBL1} = $1;
                            $csm++;
                        }
                        if ( $csm == 12 ) {
                            $current_cj{TBL2} = $1;
                            $current_cj{VFY2} = $cjverify ? '*' : '';
                            $cjverify         = 0;
                            $csm++;
                        }
                        $csm++;
                    }
                    $csm++
                      if $line =~ s/^\s*\.// && ( $csm == 4 || $csm == 14 );
                    if ( $line =~ s/^\s*([A-Za-z]\w*)//
                        && ( $csm == 5 || $csm == 15 ) )
                    {
                        push @cjcols, $1;
                        $csm++;
                    }
                    $csm -= 3 if $line =~ s/^\s*\,//;
                    next if ( $line =~ /^\s*$/ );
                } while ( $csm == 3 || $csm == 13 );

                $csm++ if $line =~ s/^\s*\>// && ( $csm == 6 || $csm == 16 );
                if ( $csm == 7 ) {
                    push @{ $current_cj{COLS1} }, @cjcols;
                    @cjcols = ();
                    $csm    = 11;
                }
                if ( $csm == 17 ) {
                    push @{ $current_cj{COLS2} }, @cjcols;
                    push( @{ $$instrs{COMPOSITES} }, \%current_cj );
                    @cjcols = ();
                    $csm    = 0;
                }
                next if ( $line =~ /^\s*$/ );
            } while ($csm);
        }
        elsif ( $line =~ /delimiters/i ) {
            warn "'delimiters' instruction not implemented\n";
        }
        elsif ( $line =~
/(before|after)\s+(((editadd|editupdate|remove|add|update|query|display)\s+)+)of\s+(([\w.]+)(\s*,\s*[\w.]+)*)\s*/gi
          )
        {

            #my $action = substr($line,pos($line));
            # control block
            my $when = $1;
            my $ops  = $2;
            my $col  = $5;
            $line =~ /\G(.*)/;
            my $action = $1;
            if ( !$action || $action =~ /^\s*$/ ) {
                $action = $parser->read_line();
            }
            my $ifsm = 0;    #holds state machine value for "if" statements
            my @ifstk;       #stack for state machine for "if" statements

            # states are:  0 if 1 then 2 begin 4 end 5 else 6 begin 8 end 0
            my @ifact;       #stack for actions within "if" statements
            my $comment = 0;
            do {
                my @action;
                my $actionref;

             #FIX: don't want the reserved words acted on if in a string literal
                $action =~ /\A\s*(.*?)\s*\z/;
                $action = $1;
                my ( $updateif, $newif ) = ( 0, 0 );

                #                warn "  action = :$ifsm:$action:\n";
                if ( length $action > 0 && !$comment ) {
                    if ( $action =~ s/^nextfield\s*=\s*(\w+)//i ) {
                        $actionref = [ "nextfield", $1 ];
                        $updateif = 1;
                    }
                    elsif ( $action =~ s/^abort//i ) {
                        $actionref = ["abort"];
                        $updateif  = 1;
                    }
                    elsif ( $action =~ s/^let\s+(\w+)\s*=\s*//i ) {
                        my $perfname = $1;

                        #my $perfexpr = $action =~ /\G(.*)/;
                        $action =~ s/;\s*$//;
                        $action    = convert_perform_logic_to_perl($action);
                        $actionref = [ "let", $perfname, $action ];
                        $action    = "";
                        $updateif  = 1;
                    }
                    elsif ( $action =~
                        s/^call\s+(\w+)\s*\((([^"\)]*|"([^\\"]|\\.)*")*)\)//i )
                    {

                        #call_extern_C_func($1, $2);
                        my $parms = convert_perform_logic_to_perl($2);
                        $actionref = [ "call", $1, $parms ];
                        $updateif = 1;
                    }
                    elsif ( $action =~
                        s/^comments\s+((bell\s+|reverse\s+){0,2})//i )
                    {
                        my $bellrev = $1;
                        $action =~ s/^\s*"(.*?)"\s*$/$1/;
                        $actionref = [ "comments", $bellrev, $action ];
                        $action = "";
                    }
                    elsif ( $action =~ s/^if[\s(]//i ) {
                        if ( $ifsm == 1 ) {
                            warn "ERROR: if if (shouldn't reach this msg)\n";
                        }
                        elsif ( $ifsm == 2 ) {
                            $ifsm = 5;
                        }
                        elsif ( $ifsm == 5 ) {
                            $ifsm = pop @ifstk;
                            pop @ifact;
                        }
                        push @ifstk, $ifsm;
                        my $condition;
                        ( $condition, $ifsm, $action ) =
                          get_if_condition( $parser, $action );
                        $actionref = [ "if", $condition, [], [] ];
                        $newif = 1;
                        push @ifact, $actionref;

              #                        warn "if :$condition:\nrest :$action:\n";
                    }
                    elsif ( $action =~ s/^else(\s|$)//i ) {
                        if ( $ifsm == 5 ) {
                            $ifsm = 6;
                        }
                        else {
                            warn "ERROR: illegal 'else'\n";
                        }
                    }
                    elsif ( $action =~ s/^begin(\s|;|$)//i ) {
                        if ( $ifsm == 2 || $ifsm == 6 ) {
                            $ifsm += 2;
                        }
                        else {
                            warn "ERROR: illegal 'begin'\n";
                        }
                    }
                    elsif (
                        $action =~ /^end(\s|;|$)/i

                    #                           && ($ifsm == 4 || $ifsm == 8)) {
                        && ( @ifstk > 0 )
                      )
                    {
                        $action =~ s/^end//;

                    #                foreach my $ist (@ifstk) { warn "$ist\n"; }
                        while ( $ifsm != 4 && $ifsm != 8 && @ifstk > 0 ) {
                            $ifsm = pop @ifstk;
                            pop @ifact;
                        }
                        if ( @ifstk == 0 ) {
                            $got_a_line = 1;
                            $line       = "end";
                            next;
                        }
                        if ( $ifsm == 4 ) {
                            $ifsm = 5;
                        }
                        else {
                            $ifsm = pop @ifstk;
                            pop @ifact;
                        }
                    }
                    elsif ( $action =~ s/{// ) {
                        $comment = 1;
                    }
                    else {
                        if ( $action =~
/^(before|after|on beginning|on ending|\w+\s+master of|composites|delimiters|end)/i
                          )
                        {
                            if ( $ifsm == 4 || $ifsm == 8 ) {
                                warn "ERROR: instruction inside block  $1\n";
                            }
                            $got_a_line = 1;
                            $line       = $action;
                            next;
                        }
                        elsif ( $action =~
                            s/(\w+)\s*\((([^"\)]*|"([^\\"]|\\.)*")*)\)//i )
                        {

                            #else it should be a call to a C function
                            $actionref = [ "call", $1, $2 ];
                            $updateif = 1;
                        }
                        else {
                            warn "ERROR: no such action  $action\n";
                            $action = "";
                        }
                    }
                    if ( ( $updateif || $ifsm ) && length $actionref > 0 ) {
                        my $stacktop =
                          $newif ? $ifact[ $#ifact - 1 ] : $ifact[$#ifact];
                        my $prvst = $ifsm;
                        $prvst = $ifstk[$#ifstk] if $newif;
                        $newif = 0;

                        #    warn "state: $prvst,$ifsm\n";
                        if ( $prvst == 2 || $prvst == 4 ) {
                            push @{ $$stacktop[2] }, $actionref;
                            $actionref = "";
                        }
                        elsif ( $prvst == 6 || $prvst == 8 ) {
                            push @{ $$stacktop[3] }, $actionref;
                            $actionref = "";
                        }
                    }
                    if ($updateif) {
                        $updateif = 0;
                        if ( $ifsm == 2 ) {
                            $ifsm = 5;
                        }
                        elsif ( $ifsm == 5 || $ifsm == 6 ) {
                            $ifsm = pop @ifstk;
                            pop @ifact;
                        }
                    }
                    if ( length $actionref > 0 ) {
                        while ( $ops =~ /(\w+)/g ) {
                            my $op = $1;
                            push(
                                @{ $$instrs{CONTROLS}{$col}{$op}{$when} },
                                $actionref
                            );
                        }
                    }
                }
                if ($comment) {
                    $action =~ s/[^}]*//;
                    if ( $action =~ s/}// ) {
                        $comment = 0;
                    }
                }
                $action =~ /\A\s*(.*?)\s*\z/;
                $action = $1;
                $action =~ s/^;$//;
                if ( length $action == 0 ) {
                    $action = $parser->read_line();
                }

                # Perl squirreliness: "last", "next" ignore "do while" blocks
            } while ($action);
        }
        else {
            warn "Unrecognized instruction line:\n$line\n";
        }
    }
    return $instrs;
}

sub get_if_condition {
    my $parser = shift;
    my $action = shift;

    #    $action =~ s/^if//;
    my $condition = "";
    my $q         = 0;

    while (1) {
        my $actunstrung = $action;
        $actunstrung =~ s/\\./xx/g;    #remove \" by removing all \.
        $actunstrung = ' ' . $actunstrung . ' ';
        my $i = 0;
        my $j = length $actunstrung;
        while ( $i < $j ) {
            while ( !$q && $i < $j ) {
                if ( substr( $actunstrung, $i, 6 ) =~ /[\s)](then|else)\s/i ) {
                    my $which = $1;
                    my $acttrim = substr( $action, 0, $i );
                    $acttrim =~ s/^\s+/ /;
                    $condition .= $acttrim;
                    $condition = convert_perform_logic_to_perl($condition);
                    return (
                        $condition,
                        $which =~ /then/i ? 2 : 6,
                        substr( $action, $i + 5 )
                    );
                }
                if ( substr( $actunstrung, $i, 7 ) =~ /[\s)](if|begin|end)\s/i )
                {
                    warn "ERROR: 'if' cannot be followed by $1\n";
                }
                $q = 1 if substr( $actunstrung, $i, 1 ) eq '"';
                $i++;
            }
            if ( $i >= $j ) {
                last;
            }
            while ( $q && $i < $j ) {
                $q = 0 if substr( $actunstrung, $i, 1 ) eq '"';
                $i++;
            }
        }
        $action =~ s/^\s+/ /;    #need to do much more than trim space
        $condition .= $action;
        if ( $action = $parser->read_line() ) { }
        else {
            warn "ERROR: premature end of file\n";
            return ( "", "", "" );
        }
    }
}

#removes all string literals to an array, and remove all comments.
#  leaves " in place of each string
sub pull_strings {
    my $strung = shift;
    my @strs;
    my $unstrung = $strung;

    #remove \" by removing all \.
    $unstrung =~ s/\\./xx/g;

    my $e = length $strung;

    # $i is index into the string, $q = 1 (q for "quote") if inside
    # a string literal, and $r = 1 (r for "remark") if inside a comment
    my ( $i, $j, $q, $r ) = ( 0, 0, 0, 0 );
    my @so = split //, $strung;
    my @su = split //, $unstrung;
    my @cb;
    my ( $co, $c );
    my $strb;
    for ( $i = 0 ; $i < $e ; $i++ ) {
        $co = $so[$i];
        $c  = $su[$i];
        $r  = 1 if ( $c eq '{' && !$q );
        if ( $c eq '"' && !$r ) {

            #entering or leaving a string literal (and not inside a comment)
            $q ^= 1;
            if ($q) {
                $strb = $i + 1;
                $cb[ $j++ ] = '"';
            }
            else {
                $su[$i] = 'x';
                push @strs, substr( $strung, $strb, $i - $strb );
            }
        }
        else {
            if ( $q || $r ) {
                $su[$i] = 'x';
            }
            else {
                $cb[ $j++ ] = $co;
            }
        }
        $r = 0 if ( $c eq '}' && $r );
    }
    if ($q) {
        warn "ERROR:  no ending \" for string literal\n";
    }
    $unstrung = join '', @cb;
    return ( $unstrung, @strs );
}

#pull all field tags and replace them with 'v' (v is for variable)
#return the string with all field tags removed, and an array of field_tags
#Expects input that has already had string literals and comments removed
#as done by the subroutine "pull_strings"
sub pull_field_tags {
    my $tagged = shift;
    my @field_tags;

    #manual, page 2-12: First character (of a field-tag) must be a letter;
    #the rest of the tag can include letters, numbers, and underscores.
    while ( $tagged =~ s/([A-Za-z]\w*)/\#/ ) {
        push @field_tags, $1;
    }
    $tagged =~ s/#\s*\(/c\(/g;    #distinguish function names from field-tags
    $tagged =~ tr/#/v/;
    return ( $tagged, @field_tags );
}

#convert regexs for SQL sytle "matches" to Perl style =~
sub convert_SQL_matches_to_perl {
    my $m = shift;

    $m =~ s/\./\\./g;             #escape .  (prob: what if . already escaped?)
    $m =~ s/\?/./g;               #change ? to .
    $m =~ s/\*/.*?/g;             #change * to .*?

    #another prob: what if ? . * are inside [ ]  ?
    $m = '^\s*' . $m . '\s*$';
    return $m;
}

sub convert_perform_logic_to_perl {
    my $cond = shift;
    warn "logic :$cond:\n" if $::TRACE_DATA;
    my ( $condunstrung, @strs ) = pull_strings($cond);

    #Now that all "and"s etc. in strings and comments are gone, can convert.
    #Pad with spaces at the ends
    #    $condunstrung = ' ' . $condunstrung . ' ';

    #Perl understands "and", "or", "not" as well as &&, ||, !, so may not need
    $condunstrung =~ s/([\s)"])and([\s("])/$1&& $2/gi;
    $condunstrung =~ s/([\s)"])or([\s("])/$1||$2/gi;

    $condunstrung =~ s/<>/!=/g;

    #want to go from "is null" to "eq ''", but don't want letters (such as "eq")
    #so go to a made up intermediate form, which is '$' in front of the operator
    $condunstrung =~ s/\sis\s+not\s+null(([\s)])|$)/ \$!= ''$2/gi;
    $condunstrung =~ s/\sis\s+null(([\s)])|$)/ \$== ''$2/gi;
    $condunstrung =~ s/((\W)|^)null(([\s)])|$)/$2''$4/gi;

    $condunstrung =~ s/([\s(])not([\s("])/$1 ! $2/gi;
    $condunstrung =~ s/([^=!><])=([^=])/$1==$2/g;

    #convert "matches" to Perl style =~
    #FIX: should we also handle ANSI "like"?
    my @ca = split /"/, $condunstrung, -1;
    my $i = 0;
    for ( $i = 0 ; $i < $#ca ; $i++ ) {
        if ( $ca[$i] =~ s/\smatches\s+$/ =~ / ) {
            $strs[$i] = '/' . convert_SQL_matches_to_perl( $strs[$i] ) . '/';
        }
        else {
            $strs[$i] = "'" . $strs[$i] . "'" unless is_number( $strs[$i] );
        }
    }
    $condunstrung = join '"', @ca;

   #"not matches" will have been changed to ! =~ at this point.  Make it into !~
    $condunstrung =~ s/!\s*=~/!~/g;

    #now all remaining letters should be field-tags
    my @field_tags;
    ( $condunstrung, @field_tags ) = pull_field_tags($condunstrung);

    #go from intermediate form to Perl syntax
    $condunstrung =~ s/\$!=/ne/g;
    $condunstrung =~ s/\$==/eq/g;

    #for string comparisons, use eq,ne, etc. instead of ==, !=
    $condunstrung =~ s/==(\s*)"/eq$1"/g;
    $condunstrung =~ s/"(\s*)==/"$1eq/g;
    $condunstrung =~ s/!=(\s*)"/ne$1"/g;
    $condunstrung =~ s/"(\s*)!=/"$1ne/g;
    $condunstrung =~ s/>=(\s*)"/ge$1"/g;
    $condunstrung =~ s/"(\s*)>=/"$1ge/g;
    $condunstrung =~ s/<=(\s*)"/le$1"/g;
    $condunstrung =~ s/"(\s*)<=/"$1le/g;

    $condunstrung =~ s/>\s*"/gt "/g;
    $condunstrung =~ s/"\s*>/" gt/g;
    $condunstrung =~ s/<\s*"/lt "/g;
    $condunstrung =~ s/"\s*</" lt/g;

    return [ $condunstrung, [@strs], [@field_tags] ];
}

sub is_number {
    my $val = shift;
    return $val =~ /^(\+|-)?(\d+\.?\d*|\d*\.?\d+)((e|E)\d+)?$/;
}

sub output_string {
    my $db      = shift;
    my $screens = shift;
    my $tables  = shift;

    #    my $attrs = shift;
    my $instrs = shift;
    my $ver    = shift;

    my $form = {
        db      => $db,
        screens => $screens,
        tables  => $tables,

        #                 attrs => $attrs,
        instrs => $instrs,
        ver    => $ver
    };
    my @strs = Data::Dumper->Dump( [$form], ['form'] );
    return join( $/, 'our $form;', @strs );
}

=head2 digest_file

digest_file  input_filename  [output_filename]

Reads the perform spec file, and writes a Perl Perform Spec file 
with the same basename but extension .pps unless an output filename
is explicitly provided.  Calls "digest" in this package to do the
work.

It\'s a little clumsy, but one can do a command-line "digestion" by:
 perl -MDBIx::Perform::DigestPer -e'digest_file "foo.per"' .
Maybe a top-level Perl or shell script should be made for this purpose.

=cut

sub digest_file {
    my $infile  = shift;
    my $outfile = shift;

    unless ($outfile) {
        $outfile = $infile;
        $outfile .= ".pps"
          unless $outfile =~ s/\..*$/.pps/;
    }

    open( IN, "< $infile" )
      or die "Couldn't open '$infile' for reading: $!";
    open( OUT, "> $outfile" )
      or die "Couldn't open '$outfile' for writing: $!";

    my ($str) = digest(*IN);
    print OUT $str;
    print OUT "\n1;\n";    # let it be require'd
    close(OUT);
}

sub convert_per_to_xml {
    warn "TRACE: entering convert_perl_to_xml\n" if $::TRACE;
    shift if ( $_[0] eq __PACKAGE__ );

    my $filename = shift;

    if ( !( $filename =~ /\.per$/ ) ) {
        die "Unknown file name extension on '$filename'";
    }
    open( PER_IN, "< $filename" )
      || die "Unable to open '$filename' for reading: $!";
    require "DBIx/Perform/DigestPer.pm";

    my @ret = digest( \*PER_IN );

    my @test = @{ $ret[0] };

    #die "File did not digest to a Perl Perform Spec"
    #    unless @test =~ /\$form\s*=/;

    my ($outfile) = split( /\.per/, $filename );
    $outfile .= ".xml";
    dump_to_xml_file( \@ret, $outfile );
}

sub convert_per_to_yml {
    warn "TRACE: entering convert_perl_to_yml\n" if $::TRACE;
    shift if ( $_[0] eq __PACKAGE__ );

    my $filename = shift;

    $filename .= '.per' if  !( $filename =~ /\.per$/i );

    open( PER_IN, "< $filename" )
      || die "Unable to open '$filename' for reading: $!";
    require "DBIx/Perform/DigestPer.pm";

    my @ret = digest( \*PER_IN );

    my @test = @{ $ret[0] };

    #die "File did not digest to a Perl Perform Spec"
    #    unless @test =~ /\$form\s*=/;

    my ($outfile) = split( /\.per/, $filename );
    $outfile .= ".yml";
    dump_to_yml_file( \@ret, $outfile );
}

sub digest_xml_file {
    shift if ( $_[0] eq __PACKAGE__ );

    my $filename = shift;
    my $dump     = new XML::Dumper;

    return $dump->xml2pl($filename);

    #    open (FILE, "< $filename") or die "can't open $filename\n";
    #    my $yamldata = join('', <FILE>);
    #    close FILE;
    #    return YAML::Load( $yamldata );
}

sub digest_yml_file {
    shift if ( $_[0] eq __PACKAGE__ );

    my $filename = shift;

    open( FILE, "< $filename" ) or die "can't open $filename\n";
    my $yamldata = join( '', <FILE> );
    close FILE;
    return YAML::Load($yamldata);
}

sub dump_to_xml_file {
    shift if ( $_[0] eq __PACKAGE__ );

    my @out_string = shift;
    my $filename   = shift;

    my $dump = new XML::Dumper;

    return $dump->pl2xml( @out_string, $filename );
}

sub dump_to_yml_file {
    shift if ( $_[0] eq __PACKAGE__ );

    my @out_string = shift;
    my $filename   = shift;

    #    my $dump	= new XML::Dumper;

    #    return $dump->pl2xml( @out_string, $filename );
    open( FILE, "> $filename" ) or die "can't open $filename\n";
    print FILE YAML::Dump(@out_string);
    close FILE;
}

#  Our little word muncher...
package DBIx::Perform::DigestPer::Parser;

sub new {
    my $class = shift;
    my $ioh   = shift;

    my $self = bless {}, $class;
    $self->{'ioh'}  = $ioh;
    $self->{'tail'} = '';
    return $self;
}

sub read_token {
    my $self               = shift;
    my $accept_header_word = shift;

    my ( $ioh, $tail ) = @$self{ 'ioh', 'tail' };

    do {
        my ($word) = $tail =~ /(\w+|[^\w\s]+)/;
        if ($word) {
            return undef
              if $DBIx::Perform::DigestPer::HEADING_WORDS{ lc($word) }
              && lc($word) ne 'end'
              && !$accept_header_word;
            $self->{'tail'} = $';    #'
            return $word;
        }
        $tail = <$ioh>;
        chomp $tail;
        $self->{'tail'} = $tail;
    } while ( defined($tail) );
    return undef;
}

sub unread_token {
    my $self = shift;
    my $word = shift;

    $self->{'tail'} = $word . $self->{'tail'};
}

sub read_line {
    my $self                = shift;
    my $accept_heading_word = shift;

    my $tail = $self->{'tail'};
    return undef
      if $tail =~ /^\s*(\w+)\s*$/
      && $DBIx::Perform::DigestPer::HEADING_WORDS{ lc($1) }
      && lc($1) ne 'end'
      && !$accept_heading_word;
    $self->{'tail'} = '';
    return $tail if ( $tail =~ /\S/ );
    my $ioh  = $self->{'ioh'};
    my $line = <$ioh>;
    return undef unless defined($line);
    chomp $line;
    return ( ( $self->{'tail'} = $line ) && undef )
      if $line =~ /^\s*(\w+)\s*$/
      && $DBIx::Perform::DigestPer::HEADING_WORDS{ lc($1) }
      && lc($1) ne 'end'
      && !$accept_heading_word;
    return $line eq '' ? ' ' : $line;
}

1;

