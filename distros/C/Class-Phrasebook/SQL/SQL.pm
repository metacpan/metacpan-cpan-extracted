package Class::Phrasebook::SQL;
use Class::Phrasebook;

our @ISA = qw (Class::Phrasebook);

use strict;
use Term::ANSIColor qw(:constants);
use bytes;
# reset to normal at the end of each line.
$Term::ANSIColor::AUTORESET = 1;

our $VERSION = '0.87';

####################
# new
####################
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->{PLACE_HOLDERS_CONATAIN_DOLLARS} = 0;
    bless ($self, $class); # reconsecrate
    return $self;
} # of new

###################################################################
# $statement = get($key, { var1 => $value1, var2 => value2 ... })
#   where $key will be the key to certain statement, and var1, var2
#   and so on will be $var1 and $var2 in the definition of that 
#   statement in the load method above.
###################################################################
sub get {
    my $self = shift;
    my $key = shift;
    my $variables = shift;

    # the DEBUG_PRINTS is controlled by an environment.
    my $debug_prints = lc($ENV{PHRASEBOOK_SQL_DEBUG_PRINTS}) || "";
    
    # the SAVE_STATEMENTS_FILE_PATH might be controlled by an environment
    if ($ENV{PHRASEBOOK_SQL_SAVE_STATEMENTS_FILE_PATH}) {
	$self->{SAVE_STATEMENTS_FILE_PATH} = 
	    $ENV{PHRASEBOOK_SQL_SAVE_STATEMENTS_FILE_PATH};
    }

    if ($self->{PLACE_HOLDERS_CONATAIN_DOLLARS}) {
	foreach my $key (keys(%$variables)) {	
	    $variables->{$key} =~ s/\$/__DOLLAR__/g;
	}
    }

    if ($debug_prints) {
	if ($debug_prints eq "color") {
	    # check that all the variables defined in $variables
	    foreach my $key (keys(%$variables)) {	
		unless (defined($variables->{$key})) {
		    print "[";
		    print GREEN called_by();
		    print "]";
		    print BLUE "[";
		    print RED "$key is not defined";
		    print BLUE "]\n";
		}
	    }
	}
	elsif ($debug_prints eq "html") {
	    # check that all the variables defined in $variables
	    foreach my $key (keys(%$variables)) {	
		unless (defined($variables->{$key})) {
		    print "<pre>[<font color=darkgreen>";
		    print called_by();
		    print "</font>]";
		    print "<font color=blue>[</font>";
		    print "<font color=red>$key is not defined</font>";
		    print "<font color=blue>]</font></pre>\n";
		}
	    }
	}
	elsif ($debug_prints eq "text") {
	    # check that all the variables defined in $variables
	    foreach my $key (keys(%$variables)) {	
		unless (defined($variables->{$key})) {
		    print "[";
		    print called_by();
		    print "]";
		    print "[";
		    print "$key is not defined";
		    print "]\n";
		}
	    }
	}
    } # of if ($debug_prints)

    my $statement = $self->{PHRASES}{$key};
    unless (defined($statement)) {        
	if ($debug_prints) {
	    if ($debug_prints eq "color") {
		print RED "No statement for $key\n";
	    }
	    elsif ($debug_prints eq "html") {
		print "<pre><font color=red>No statement for $key".
		    "</font></pre>\n";
	    }
	    elsif ($debug_prints eq "text") {
		print "No statement for $key\n";
	    }
	} 
	$self->{LOG}->write ("No statement for ".$key."\n", 3);
        return undef;
    }

    # deal with statments that are not update:
    if ($statement !~ /^\s*update/i) {
	# process the placeholders 
	if ($debug_prints) {
	    $statement =~ 
		s/\$([a-zA-Z0-9_]+)/debug_print_variable($1, $variables)/ge;
	    $statement =~ 
		s/\$\(([a-zA-Z0-9_]+)\)/debug_print_variable($1, 
							     $variables)/ge;
	}
	# if the variable is inside quotes - escape quotes inside the variable
	$statement =~ s/(\'\s*)\$([a-zA-Z0-9_]+)(\s*\')/escape_quotes($self, 
						 $1, $variables->{$2}, $3)/ge;
	# deal with the rest of the variables without escaping the quotes
	$statement =~ s/\$([a-zA-Z0-9_]+)/$variables->{$1}/g;
	# also process variables in $(var_name) format.
	$statement =~ s/\$\(([a-zA-Z0-9_]+)\)/$variables->{$1}/g;
    }
    else {
	# deal with updates in the following way:
	# devide the statement to before the set, after the where and the rest
	$statement =~ /(\sset\s)/i;
	my $statement_before_set = $`.$&; # till and include the set
	my $pairs = $'; # the rest
	my $statement_after_where;
	if ($pairs =~ /(\swhere\s)/i) { # if there is where
	    $statement_after_where = $&.$'; # holds the where and anything
	                                    # after it
	    $pairs = $`; # holds only the pairs
	}

	# now $statement holds only the pairs we set. for each line, if 
	# one of the variables is not defined, we remove that line.
	my @lines = split(/\n/, $pairs);
	my @lefted_lines = 
	    grep ( is_variables_defined_in_this_line($_, $variables), @lines);

	# join the lines
	$pairs = join("", @lefted_lines);

	# clean the last comma 
	$pairs =~ s/\,\s*$//;
	# join the parts of the statement again
	$statement = $statement_before_set.$pairs.$statement_after_where;

	# if the variable is inside quotes - escape quotes inside the variable
	$statement =~ s/(\'\s*)\$([a-zA-Z0-9_]+)(\s*\')/escape_quotes($self, 
						 $1, $variables->{$2}, $3)/ge;
	# replace the variables with their values
        $statement =~ s/\$([a-zA-Z0-9_]+)/$variables->{$1}/g;
	$statement =~ s/\$\(([a-zA-Z0-9_]+)\)/$variables->{$1}/g;
    }
    
    # now deal with empty brackets of IN - just put instead of that expression
    # the word TRUE.
    $statement =~ s/[a-zA-Z0-9_\.]+\s+in\s*\(\s*\)/TRUE/ig;
    
    # deal with "= NULL"
    if ($self->{USE_IS_NULL}) {
	$statement =~ s/\= *NULL/is NULL/ig;
    }

    if ($self->{PLACE_HOLDERS_CONATAIN_DOLLARS}) {
	$statement =~ s/__DOLLAR__/\$/g;
    }

    # remove new lines if needed
    if ($self->{REMOVE_NEW_LINES}) {
	$statement =~ s/\n//g; 
    }
    
    # debug prints
    if ($debug_prints) {
	if ($debug_prints eq "color") {
	    print "[";
	    print GREEN called_by();
	    print "]";
	    print RED "[";
	    print BLUE $key;
	    print RED "]\n";
	    print $statement."\n";
	}
	elsif ($debug_prints eq "html") {
	    print "<pre>[";
	    print "<font color=darkgreen>".called_by()."</font>";
	    print "]";
	    print "<font color=red>[</font>";
	    print "<font color=blue>$key</font>";
	    print "<font color=red>]</font>\n";
	    print $statement."</pre>\n";
	}
	elsif ($debug_prints eq "text") {
	    print "[";
	    print called_by();
	    print "]";
	    print "[";
	    print $key;
	    print "]\n";
	    print $statement."\n";	    
	}
    } # of if ($debug_prints)

    # save the statement in a file if the path of such a file is defined.
    if ($self->{SAVE_STATEMENTS_FILE_PATH}) {
	open(TMP, ">>".$self->{SAVE_STATEMENTS_FILE_PATH});
	my $saved_statement = $statement;
	$saved_statement =~ s/[\s\n]+/ /g;
	print TMP $saved_statement.";\n";
	close(TMP);
    }
    unless ($statement) {
	if ($debug_prints) {
	    if ($debug_prints eq "color") {
		print RED "Oops - no statement for $key !!!\n";
	    }
	    elsif ($debug_prints eq "html") {
		print "<pre><font color=red>Oops - no statement for $key".
		    "</font></pre>\n";
	    }
	    elsif ($debug_prints eq "text") {
		print "Oops - no statement for $key !!!\n";
	    }
	}
    }
    return $statement;
} # of get

###########################
# escape_quotes
###########################
# escape ' in the variables
sub escape_quotes {
    my $self = shift;
    my $quote1 = shift;
    my $variable = shift;
    my $quote2 = shift;

    my $escaped_quote = defined($self->{ESCAPED_QUOTE}) ? 
	$self->{ESCAPED_QUOTE} : "\'\'";
    $variable =~ s/\'/$escaped_quote/g;
    return $quote1.$variable.$quote2;
} # of escape_quotes

#################
# escaped_quote
#################
sub escaped_quote {
    my $self = shift;
    if (@_) { $self->{ESCAPED_QUOTE} = shift || "\'\'" }
    return $self->{ESCAPED_QUOTE};
} # of escaped_quote

#################
# use_is_null
#################
sub use_is_null {
    my $self = shift;
    if (@_) { $self->{USE_IS_NULL} = shift }
    return $self->{USE_IS_NULL};
} # of use_is_null

##############################
# save_statements_file_path
##############################
sub save_statements_file_path {
    my $self = shift;
    if (@_) { $self->{SAVE_STATEMENTS_FILE_PATH} = shift }
    return $self->{SAVE_STATEMENTS_FILE_PATH};
} # of save_statements_file_path

#################################
# place_holders_conatain_dollars
#################################
sub place_holders_conatain_dollars {
    my $self = shift;
    if (@_) {
        $self->{PLACE_HOLDERS_CONATAIN_DOLLARS} = shift;
    }
    return $self->{PLACE_HOLDERS_CONATAIN_DOLLARS};
} # of place_holders_conatain_dollars

#######################################################
# is_variables_defined_in_this_line($line, $variables)
#######################################################
# helper function
# gets a a string (line) and reference to hash (that holds the pairs that are
# the placeholders. return 1 if all the variables in the string are defined
# in the hash.
sub is_variables_defined_in_this_line {
    my $line = shift;
    my $variables = shift;
    my $line_tmp = $line;
    while ($line_tmp =~ /\$([a-zA-Z0-9_]+)/) {
	unless (defined($variables->{$1})) {
	    return 0;
	}
	$line_tmp = $';
    }
    $line_tmp = $line;
    while ($line_tmp =~ /\$\(([a-zA-Z0-9_]+)\)/) {
	unless (defined($variables->{$1})) {
	    return 0;
	}
	$line_tmp = $';
    }
    return 1;
} # of is_variables_defined_in_this_line

#########################
# debug_print_variable
#########################
# helper function
sub debug_print_variable {
    my $key = shift;
    my $variables = shift;
    my $value = $variables->{$key};
    my $debug_prints = lc($ENV{PHRASEBOOK_SQL_DEBUG_PRINTS}) || "";
    if ($debug_prints eq "color") {
	print MAGENTA "$key = ";
	if (defined($value)) {
	    print MAGENTA "$value\n";
	}
	else {
	    print RED "undef\n";
	}
    }
    elsif ($debug_prints eq "html") {
	print "<pre><font color=magenta> $key = </font>";
	if (defined($value)) {
	    print "<font color=magenta>$value</font></pre>\n";
	}
	else {
	    print "<font color=red>undef</font></pre>\n";
	}	
    }
    elsif ($debug_prints eq "text") {
	print "$key = ";
	if (defined($value)) {
	    print "$value\n";
	}
	else {
	    print "undef\n";
	}
    }
    return "\$".$key;
} # of debug_print_varibale

#######################
# called_by
#######################
sub called_by {
    my $depth = 2;
    my $args; 
    my $pack; 
    my $file; 
    my $line; 
    my $subr; 
    my $has_args;
    my $wantarray;
    my $evaltext; 
    my $is_require; 
    my $hints; 
    my $bitmask;
    my @subr;
    my $str = "";
    while ($depth < 7) {
	($pack, $file, $line, $subr, $has_args, $wantarray, 
	 $evaltext, $is_require, $hints, $bitmask) = caller($depth);
        unless (defined($subr)) {
            last;
        }
        $depth++;       	
        $line = "$file:".$line."-->";
	push(@subr, $line.$subr);
    }
    @subr = reverse(@subr);
    foreach $subr (@subr) {
        $str .= $subr;
        $str .= " > ";
    }
    $str =~ s/ > $/: /;
    return $str;
} # of called_by


__END__

=head1 NAME

Class::Phrasebook::SQL - Implements the Phrasebook pattern for SQL statements.

=head1 SYNOPSIS

  use Class::Phrasebook::SQL;
  my $sql = new Class::Phrasebook::SQL($log, "test.xml");
  $sql->load("Pg");
  $statement = $sql->get("INSERT_INTO_CONFIG_ROW", 
		       { id => 88,
			 parent => 77,
			 level => 5 });

=head1 DESCRIPTION

This class inherits from Class::Phrasebook and let us manage all the SQL 
code we have in a project, in one file. The is done by placing all the 
SQL statements as phrases in the XML file of the Class::Phrasebook. 
See I<Phrasebook> for details about that file format.

=head1 METHODS

=over 4

=item get(KEY [, REFERENCE_TO_ANONYMOUS_HASH ])

Will return the SQL statement that fits to the KEY. If a reference to 
anonymous has is sent, it will be used to define the parameters in the 
SQL statement.

For example, if the following statement is defined in the XML file:
   <statement name="INSERT_INTO_CONFIG_ROW">
               insert into t_config (id, parent_id, level)
                      values($id, $parent, $level)
   </statement>
We usually will call get method to get this statement in the following way:
   $statement = $sql->get("INSERT_INTO_CONFIG_ROW", 
                          { id => 88,
                            parent => 77,
                            level => 5 });

Special case are the SQL update instructions. Most of the time, when we 
call update, we would like to update only part of the columns in a row.
Yet, we usually prefer to avoid from writing all the possible update 
combinations. For example if we have the following update call:

   update t_account set
                         login = '$login',
                         description = '$description', 
                         dates_id = $dates_id, 
                         groups = $groups,
                         owners = $owners
                                     where id = $id

We do not want to write special update for each case like:

   update t_account set
                         owners = $owners
                                     where id = $id

or 

   update t_account set
                         login = '$login',
                         owners = $owners
                                     where id = $id

In order to solve this, the get method will delete the "set" lines of 
the update method where the were the parameter value is udefined.
Because of that we should write the update statements were the pairs of 
<column name> = <parameter> are in separate lines from the rest of the 
statement. Note that the get method will also fix comma problems between 
the pairs (so if the last pair is deleted we will not have extra comma).
The method returns the SQL statement, or undef if there is no SQL statement 
for the sent KEY.

=item escaped_quote ( STRING )

An access method to the data memeber ESCAPED_QUOTE. The default way to escape
a quote is to have two quotes (''). This will work on Postgres and on MSQL. 
Yet, if this default is not working with your database of choice, you can 
change it by seting the ESCAPE_QUOTE data member using this method. 

=item use_is_null( BOOLEAN ) 

Sometimes, when we have an argument in SQL statement, we will want to change 
the equal sign to 'is'. For example:
 
		   select * from my_table where my_id = $id

If $id is NULL, we sometimes want to have 'my_id is NULL'.
We can have that by sending to this method 1. This will promis that where 
ever we have the pattern '= NULL' it will become 'is NULL'. The default
is not to use the 'is' (thus 0).

=item save_statements_file_path ( [ FILE_PATH ] )

Access method to the SAVE_STATEMENTS_FILE_PATH data member. If this data
member is set, for each call to the I<get> method, the statement that 
is returned also will be appended to that file. This might be useful while
debugging big projects - it will let the user have a full log of all the 
statemnets that were generated by the I<get> method.

=item place_holders_conatain_dollars ( [ BOOLEAN ] )

Access method to the PLACE_HOLDERS_CONATAIN_DOLLARS data member. 

If a place holder value contains dollar sign, it will be processed
wrongly, and the class will try to replace the dollar sign and the 
text that follows it with the value of a variable in that name.

If this data member is set to 1 (TRUE), dollar signes are replaced 
by the string '__DOLLAR__', and later those strings are changed back 
to dollar signes. 

Because of that overhead, and because I believe that usually
dollar signes are not included in the place holder values, 
the PLACE_HOLDERS_CONATAIN_DOLLARS data member is 0 (FALSE) by 
default.

=back

=head1 ENVIRONMENTS

=over 4

=item PHRASEBOOK_SQL_DEBUG_PRINTS

If this environment is set to "COLOR", the get method will print the 
statements it gets, with some extra information in color screen output 
using ANSI escape sequences. If the environment is set to "HTML", the 
information will be printed in HTML format. If the environment is set to 
"TEXT" - the information will be printed as simple text. If the environment 
is not set, or empty - nothing will be printed. This feature comes to help
debugging the SQL statements that we get from the object of this class.

=item PHRASEBOOK_SQL_SAVE_STATEMENTS_FILE_PATH

Another way to set the SAVE_STATEMENTS_FILE_PATH data member is by setting 
this environment variable.

=back

=head1 AUTHOR

Rani Pinchuk, rani@cpan.org

=head1 COPYRIGHT

Copyright (c) 2001-2002 Ockham Technology N.V. & Rani Pinchuk. 
All rights reserved.  
This package is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::Parser(3)>,
L<Class::Phrasebook(3)>,
L<Log::LogLite(3)>,
L<Log::NullLogLite(3)>

=cut
