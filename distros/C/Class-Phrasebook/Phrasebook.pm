package Class::Phrasebook;

use strict;

our $VERSION = '0.88';


use Term::ANSIColor 1.03 qw(:constants);
use strict;
use XML::Parser 2.30;
use Log::NullLogLite 0.2;
use bytes;
# reset to normal at the end of each line.
$Term::ANSIColor::AUTORESET = 1;

my $Dictionaries_cache;
my $Clean_out_of_scope_dictionaries = 1;

#############################################################
# new($log, $file_path)
#############################################################
# the constructor
sub new {
    my $proto = shift; # get the class name
    my $class = ref($proto) || $proto;
    my $self  = {};

    $self->{LOG} = shift || new Log::NullLogLite;
    $self->{FILE_PATH} = shift || "";
    
    # we bless already so we can use the method get_xml_path
    bless ($self, $class);

    # check that we can find this file
    $self->{FILE_PATH} = $self->get_xml_path($self->{FILE_PATH});
    unless ($self->{FILE_PATH}) {
	return undef;
    }    

    # get the file name for using as part of the key of the dictionary
    $self->{FILE_PATH} =~ /[^\/]+$/;
    $self->{FILE_NAME} = $&;
    # dictionary key holds a representative key for the dictionary that is 
    # loaded.
    $self->{DICTIONARY_KEY} = "";
    $self->{PHRASES} = {};
    # defaults
    if (defined($ENV{PHRASEBOOK_AS_IS_BETWEEN_TAGS})) {
	$self->{AS_IS_BETWEEN_TAGS} = $ENV{PHRASEBOOK_AS_IS_BETWEEN_TAGS};
    }
    else {
	$self->{AS_IS_BETWEEN_TAGS} = 1; # set by default
    }
    $self->{REMOVE_NEW_LINES} = 0;
    return $self;
} # of new

##############################
# Dictionaries_names_in_cache
##############################
sub Dictionaries_names_in_cache {    
    return keys ( % { $Dictionaries_cache } );
} # of Dictionaries_names_in_cache

###############
# DESTROY
###############
sub DESTROY {
    my $self = shift;
    if ($self->{DICTIONARY_KEY}) {	
	$Dictionaries_cache->{$self->{DICTIONARY_KEY}}{COUNTER}--;
	# clean that dictionary from the cache if needed.
	if ($Dictionaries_cache->{$self->{DICTIONARY_KEY}}{COUNTER} == 0) {
	    if ($Clean_out_of_scope_dictionaries) {
		delete($Dictionaries_cache->{$self->{DICTIONARY_KEY}});
	    }
	}
    }

} # of DESTROY

#################
# file_path
#################
sub file_path {
    my $self = shift;
    if (@_) { 
	$self->{FILE_PATH} = shift;

        # check that we can find this file
	$self->{FILE_PATH} = $self->get_xml_path($self->{FILE_PATH});
	unless ($self->{FILE_PATH}) {
	    return undef;
	}
    }
    return $self->{FILE_PATH};
} # of file_path

#################
# log
#################
sub log {
    my $self = shift;
    if (@_) { $self->{LOG} = shift }
    return $self->{LOG};
} # of log

###################################
# clean_out_of_scope_dictionaries
###################################
sub clean_out_of_scope_dictionaries {
    my $proto = shift; # get the class name
    $Clean_out_of_scope_dictionaries = shift;
    return $Clean_out_of_scope_dictionaries;
} # of clean_out_of_scope_dictionaries

#################
# dictionary_name
#################
sub dictionary_name {
    my $self = shift;
    if (@_) { $self->{DICTIONARY_NAME} = shift }
    return $self->{DICTIONARY_NAME};
} # of dictionary_name

####################
# remove_new_lines
####################
sub remove_new_lines {
    my $self = shift;
    if (@_) { $self->{REMOVE_NEW_LINES} = shift }
    return $self->{REMOVE_NEW_LINES};
} # of remove_new_lines

#####################
# as_is_between_tags
#####################
sub as_is_between_tags {
    my $self = shift;
    if (@_) { $self->{AS_IS_BETWEEN_TAGS} = shift }
    return $self->{AS_IS_BETWEEN_TAGS};
} # of as_is_between_tags

####################################
# load($dictionary_name)
####################################
sub load {
    my $self = shift;
    my $requested_dictionary_name = shift || "";
    # get a unique key that represents this dictionary of that file.
    my $dictionary_key = 
	$self->{FILE_NAME}."/".$requested_dictionary_name;
    # if the object already loaded a dictionary, and now it loads other 
    # dictionary, we should reduce the counter of the dictionary that was
    # loaded till now.
    if ($self->{DICTIONARY_KEY} && 
	$self->{DICTIONARY_KEY} ne $dictionary_key) {
	$Dictionaries_cache->{$self->{DICTIONARY_KEY}}{COUNTER}--;

	# clean that dictionary from the cache if needed.
	if ($Dictionaries_cache->{$self->{DICTIONARY_KEY}}{COUNTER} == 0) {
	    if ($Clean_out_of_scope_dictionaries) {
		delete($Dictionaries_cache->{$self->{DICTIONARY_KEY}});
	    }
	}
    }
    # zero the cache counter for that dictionary if this is the first time
    # that this dictionary is loaded
    if (!defined($Dictionaries_cache->{$dictionary_key}) ||
	!defined($Dictionaries_cache->{$dictionary_key}{COUNTER})) {
	$Dictionaries_cache->{$dictionary_key}{COUNTER} = 0;
    }
    # keep the dictionary key
    $self->{DICTIONARY_KEY} = $dictionary_key;
    # and increment the counter of this dictionary
    $Dictionaries_cache->{$self->{DICTIONARY_KEY}}{COUNTER}++;
    # the the dictionaries cache keeps the phrases of all the dictionaries
    if (defined($Dictionaries_cache->{$self->{DICTIONARY_KEY}}) &&
	defined($Dictionaries_cache->{$self->{DICTIONARY_KEY}}{PHRASES}) &&
	ref($Dictionaries_cache->{$self->{DICTIONARY_KEY}}{PHRASES}) 
	eq "HASH") {
	$self->{PHRASES} = 
	    $Dictionaries_cache->{$self->{DICTIONARY_KEY}}{PHRASES};
	return 1;
    }
    
    # the load may set the data member DICTIONARY_NAME. On the other hand
    # if the requested_dictionary_name is not defined, we will try to use
    # the data member.
    if ($requested_dictionary_name) {
	$self->{DICTIONARY_NAME} = $requested_dictionary_name;
    }
    else {
	$requested_dictionary_name = $self->{DICTIONARY_NAME} || "";
    }

    my $phrases; # a reference to anonymous hash that will hold all the 
                 # phrases
    my $phrase_name; # the name of the current phrase.
    my $phrase_value; # the string of the phrase. 

    # the first dictionary is the default one and should be read. this flag
    # will tell if it was read.
    my $default_was_read = 0;
    
    # this flag will be set to zero after the default dictionary was read. then
    # it will be set to one when the requested dictionary should be read.
    my $read_on = 1;

    # create the XML parser object
    my $parser = new XML::Parser(ErrorContext => 2);
    $parser->setHandlers(
        Start => sub {
            my $expat = shift;
            my $element = shift;
            my %attributes = (@_);	    
	    
            # deal with the dictionary element
            if ($element =~ /dictionary/) {
		my $dictionary_name = $attributes{name};
                unless (defined($dictionary_name)) {
                    $self->log()->write("The dictionary element must".
					" have the name attribute", 4);
                    return 0; # we must have name
                }
		# if the default was already read, and the dictionary name
		# is not the requested one, we should not read on.
                if ($default_was_read && 
		    $dictionary_name ne $requested_dictionary_name) {
		    $read_on = 0;
		}
		# in any other case we should read on
		else {
		    $read_on = 1;
		}
            }

            # deal with the phrase element
            if ($element =~ /^phrase$/) {
                $phrase_name = $attributes{name};
                unless (defined($phrase_name)) {
                    $self->log()->write("The phrase element must".
					" have the name attribute", 4);
                    return 0; # we must have name
                }
            }
	    if ($self->{AS_IS_BETWEEN_TAGS}) {
		# we should clean the $phrase_value after the start of the tag
		# so in the phrase we will have only the text that is between
		# the phrase tags.
		$phrase_value = "";
	    }	    
        }, # of Start
	
        End => sub {
            my $expat = shift;
            my $element = shift;
	    if ($element =~ /^dictionary$/i) {
		$default_was_read = 1;
	    }
	    
            if ($element =~ /^phrase$/i) {
		if ($read_on) {
		    $phrases->{$phrase_name} = $phrase_value;
		    $phrase_value = "";
		}
            }
        }, # of End
	
        Char => sub {
            my $expat = shift;
            my $string = shift;
	    # if $read_on flag is true and the string is not empty we set the 
	    # value of the phrase.
	    if ($self->{AS_IS_BETWEEN_TAGS}) {
		if ($read_on && length($string)) {
		    $phrase_value .= $string;
		}		
	    }
	    else { # this block is here for legacy reasons.
		if ($read_on && $string =~ /[\S]/) { 
		    # if we have already $phrase_value, we should add a 
		    # new line to it, before we add the next line.
		    $phrase_value .= "\n" if ($phrase_value);
		    $phrase_value .= $string;
		}
	    }
        } # of Char
    ); # of the parser setHandlers class

    # open the xml file as a locked file and parse it
    my $fh = new IO::LockedFile("<".$self->{FILE_PATH});
    unless ($fh) {
        $self->log()->write("Could not open ".$self->{FILE_PATH}.
			    " to read.", 4);
	return 0;
    }
    eval { $parser->parse($fh) }; # I use eval because the parse function dies
                                  # on parsing error.
    if ($@) {
        $self->log()->write("Could not parse the ".$self->{FILE_PATH}.
			    " file: ".$@, 4);
        return 0; # there was an error in parsing the XML.
    }

    $self->{PHRASES} = $phrases;
    # keep the phrases 
    $Dictionaries_cache->{$self->{DICTIONARY_KEY}}{PHRASES} = $self->{PHRASES};

    return 1; # success 
} # of load

###################################################################
# $phrase = get($key, { var1 => $value1, var2 => value2 ... })
#   where $key will be the key to certain phrase, and var1, var2
#   and so on will be $var1 and $var2 in the definition of that 
#   phrase in the load method above.
###################################################################
sub get {
    my $self = shift;
    my $key = shift;
    my $variables = shift;
    
    # the DEBUG_PRINTS is controlled by an environment.
    my $debug_prints = lc($ENV{PHRASEBOOK_DEBUG_PRINTS}) || "";
    
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
    }

    my $phrase = $self->{PHRASES}{$key};
    unless (defined($phrase)) {        
	if ($debug_prints) {
	    if ($debug_prints eq "color") {
		print RED "No phrase for $key\n";
	    }
	    elsif ($debug_prints eq "html") {
		print "<pre><font color=red>No phrase for $key".
		    "</font></pre>\n";
	    }
	    elsif ($debug_prints eq "text") {
		print "No phrase for $key\n";
	    }
	} 
	$self->{LOG}->write ("No phrase for ".$key."\n", 3);
        return undef;
    }

    # process the placeholders 
    if ($debug_prints) {
	$phrase =~ 
	    s/\$([a-zA-Z0-9_]+)/debug_print_variable($1, $variables)/ge;
	$phrase =~ 
	    s/\$\(([a-zA-Z0-9_]+)\)/debug_print_variable($1, $variables)/ge;
    }
    $phrase =~ s/\$([a-zA-Z0-9_]+)/$variables->{$1}/g;
    # also process variables in $(var_name) format.
    $phrase =~ s/\$\(([a-zA-Z0-9_]+)\)/$variables->{$1}/g;

    # remove new lines if needed
    if ($self->{REMOVE_NEW_LINES}) {
	$phrase =~ s/\n//g; 
    }

    if ($debug_prints) {
	if ($debug_prints eq "color") {
	    print "[";
	    print GREEN called_by();
	    print "]";
	    print RED "[";
	    print BLUE $key;
	    print RED "]\n";
	    print $phrase."\n";
	}
	elsif ($debug_prints eq "html") {
	    print "<pre>[";
	    print "<font color=darkgreen>".called_by()."</font>";
	    print "]";
	    print "<font color=red>[</font>";
	    print "<font color=blue>$key</font>";
	    print "<font color=red>]</font>\n";
	    print $phrase."</pre>\n";
	}
	elsif ($debug_prints eq "text") {
	    print "[";
	    print called_by();
	    print "]";
	    print "[";
	    print $key;
	    print "]\n";
	    print $phrase."\n";	    
	}
    }
    
    unless ($phrase) {
	if ($debug_prints) {
	    if ($debug_prints eq "color") {
		print RED "Oops - no phrase for $key !!!\n";
	    }
	    elsif ($debug_prints eq "html") {
		print "<pre><font color=red>Oops - no phrase for $key".
		    "</font></pre>\n";
	    }
	    elsif ($debug_prints eq "text") {
		print "Oops - no phrase for $key !!!\n";
	    }
	}
    }
    return $phrase;
} # of get

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

#######################################################
# is_variables_defined_in_this_line($line, $variables)
#######################################################
sub is_variables_defined_in_this_line {
    my $line = shift;
    my $variables = shift;
    while ($line =~ /\$([a-zA-Z0-9_]+)/ ) {
	unless (defined($variables->{$1})) {
	    return 0;
	}
	$line = $';
    }
    return 1;
} # of is_variables_defined_in_this_line

##################
# to_string()
##################
sub to_string {
    my $self = shift;
    my $string = "";
    foreach my $key (keys(% { $self->{PHRASES} } )) {
	my $phrase = $self->{PHRASES}{$key};
	$string .= $key." => \n".$phrase."\n\n";
    }
    return $string;
} # of to_string

#######################
# get_xml_path()
#######################
sub get_xml_path {
    my $self = shift;
    my $file = $self->{FILE_PATH};

    # first deal with absolute path
    if (is_absolute_path($file)) {
	if (-e $file) {
	    return $file;
	}
	else {
	    $self->{LOG}->write("Cannot find the XML file ".
				$self->{FILE_PATH}, 4);
	    return undef;
	}
    }
    else {
	my @dirs = (".", "./lib", "../lib", @INC);
	
	foreach my $dir (@dirs) {
	    my $path = $dir."/".$file;
	    if (-e $path) {
		return $path;
	    }
	}	    
	
	# we could not find that file, announce it.
	$self->{LOG}->write("Cannot find the XML file ".
			    $file." in tghe directories: (".
			    join(", ", @INC).")", 4);
	
	return undef;
    }
} # of get_xml_path

######################
# is_absolute_path
######################
sub is_absolute_path {
    my $path = shift;

    unless (defined($path)) {
        return 0;
    }
    # the different Operating Systems
    my %operating_systems = ( "mswin32"  => '^(?:[a-zA-Z]:)?[\\\/]+',
			      "cygwin"   => '^([A-Za-z]:)|^(\/)',
                              "linux"    => '^\/');    
    my $os = lc($^O);
    my $reg_expression = $operating_systems{$os} || 
        $operating_systems{'linux'};
    return $path =~ /$reg_expression/;
} # is_absolute_path

#########################
# debug_print_variable
#########################
sub debug_print_variable {
    my $key = shift;
    my $variables = shift;
    my $value = $variables->{$key};
    my $debug_prints = lc($ENV{PHRASEBOOK_DEBUG_PRINTS}) || "";
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

1; # make perl happy

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Class::Phrasebook - Implements the Phrasebook pattern

=head1 SYNOPSIS

  use Class::Phrasebook;
  my $pb = new Class::Phrasebook($log, "test.xml");
  $pb->load("NL"); # using Dutch as the language
  $phrase = $pb->get("ADDRESS", 
		     { street => "Chaim Levanon",
		       number => 88,
		       city   => "Tel Aviv" } );

=head1 DESCRIPTION

This class implements the Phrasebook pattern. It lets us create dictionaries 
of phrases. Each phrase can be accessed by a unique key. Each phrase may have
placeholders. Group of phrases are kept in a dictionary. The first dictionary 
is the default one - which means that it will always be read. One of the 
dictionaries might be used to override the default one. The phrases are kept
in an XML document.
  
The XML document type definition is as followed:

 <?xml version="1.0"?>
 <!DOCTYPE phrasebook [
	       <!ELEMENT phrasebook (dictionary)*>              
	       <!ELEMENT dictionary (phrase)*>
               <!ATTLIST dictionary name CDATA #REQUIRED>
               <!ELEMENT phrase (#PCDATA)>
               <!ATTLIST phrase name CDATA #REQUIRED>
 ]>

Example for XML file:

 <?xml version="1.0"?>
 <!DOCTYPE phrasebook [
	       <!ELEMENT phrasebook (dictionary)*>              
	       <!ELEMENT dictionary (phrase)*>
               <!ATTLIST dictionary name CDATA #REQUIRED>
               <!ELEMENT phrase (#PCDATA)>
               <!ATTLIST phrase name CDATA #REQUIRED>
 ]>
 <phrasebook>
 <dictionary name="EN">

 <phrase name="HELLO_WORLD">
            Hello World!!!
 </phrase>

 <phrase name="THE_HOUR">
            The time now is $hour. 
 </phrase>

 <phrase name="ADDITION">
            add $a and $b and you get $c
 </phrase>


 <!-- my name is the same in English Dutch and French. -->
 <phrase name="THE_AUTHOR">
            Rani Pinchuk
 </phrase>
 </dictionary>

 <dictionary name="FR">
 <phrase name="HELLO_WORLD">
            Bonjour le Monde!!!
 </phrase>

 <phrase name="THE_HOUR">
            Il est maintenant $hour. 
 </phrase>

 <phrase name="ADDITION">
            $a + $b = $c
 </phrase>

 </dictionary>

 <dictionary name="NL">
 <phrase name="HELLO_WORLD">
            Hallo Werld!!!
 </phrase>

 <phrase name="THE_HOUR">
            Het is nu $hour. 
 </phrase>

 <phrase name="ADDITION">
            $a + $b = $c
 </phrase>

 </dictionary>

 </phrasebook>

Each phrase should have a unique name. Within the phrase text we can 
place placeholders. When get method is called, those placeholders will be 
replaced by their value.

The dictionaries that are loaded by object of this class, are cached in 
a class member. This means that if you use this class within other class, 
and you produce many objects of that other class, you will not have in 
memory many copies of the loaded dictionaries of those objects. Actually you 
will have one copy in memory for each dictionary that is loaded, no matter how 
many objects load it. This copy will be deleted when all the objects that 
refer to it go out of scope (like the Perl references). You can fix that 
any loaded dictionary will never go out of scope (till the process ends). 
You do that by calling the class method B<clean_out_of_scope_dictionaries>
with 0 as its argument.

Beside being happy with the fact that you can use the Class::Phrasebook 
within other objects without poluting the memory, you should know about 
one possible flow in that caching - if the dictionary is changed but its 
name and the name of the XML file that holds it remain the same, the 
new dictionary will not be loaded even if the B<load> method is called.

Because it is not the intention to have this kind of situation (changing 
the dictionary while the program is already running), the one that is 
crazy enough to have this kind of need, invited to email the author, and 
a B<force_load> method might be added to this class.

=head1 CONSTRUCTOR

=over 4

=item new ( [ LOG ], FILEPATH )

The constructor. FILEPATH can be the absolute path of the XML file. But it
can be also just a name of the file, or relative path to the file. In that
case, that file will be searched in the following places: 
   * The current directory.
   * The directory ./lib in the current directory.
   * The directory ../lib in the current directory.
   * The directories that are in @INC.

LOG is a Log object. If LOG is undef, NullLog object will be used. 
If it is provided, the class will use the Log facilities to log unusual events.
Returns the new object, or undef on failure.

=back

=head1 CLASS METHODS

=over 4

=item clean_out_of_scope_dictionaries( BOOLEAN )

This method takes one argument. If it is 1 (TRUE), dictionaries will 
be deleted from the cache when they go out of scope. If it is 0 (FALSE),
the dictionaries will stay in the cache (till the program ends). 
The default behaviour is that the dictionaries are deleted when they go
out of scope (so 1).

=back

=head1 METHODS

=over 4

=item load( DICTIONARY_NAME )

Will load the phrases of certain dictionary from the file. If the dictionary
that is requested is not the first one (in the XML file), the first dictionary
will be loaded first, and then the requested dictionary phrases will be loaded.
That way, the first dictionary play the role of the default dictionary.

The DICTIONARY_NAME data member will be set to the parameter that is sent 
to this method. Yet, if nothing is sent to the method, the method will use 
the value of the DICTIONARY_NAME data member to load the right dictionary.
If the data member is not defined as well, the default dictionary will be 
loaded.
 
Returns 1 on success, 0 on failure.

=item get(KEY [, REFERENCE_TO_ANONYMOUS_HASH ])
Will return the phrase that fits to the KEY. If a reference to 
anonymous has is sent, it will be used to define the parameters in the 
phrase.

=item dictionary_name( DICTIONARY_NAME ) 

Access method to the DICTIONARY_NAME data member. See I<load> method above.

=item remove_new_lines ( BOOLEAN )

Access method to the data member REMOVE_NEW_LINES flag. If this data member 
is 1 (TRUE), then new lines will be removed from the phrase that a is 
returned by the method I<get>. Unset by default.
Returns the value of the data member REMOVE_NEW_LINES flag.

=item as_is_between_tags ( BOOLEAN )

Access method to the data member AS_IS_BETWEEN_TAGS flag. Set by default.
In the past releases, the class did not deal correctly with spaces and 
new lines. When this flag is unset, the class will continue in its old 
behavior. So if the new - correct - behavior breaks your code, you can go
back to the old behavior. See also the environment variable 
PHRASEBOOK_AS_IS_BETWEEN_TAGS.
Returns the value of the data member AS_IS_BETWEEN_TAGS flag.

=back

=head1 ACCESS METHODS

=over 4

=item get_xml_path ( FILE )

Will return the path of the xml file with that name. It will look for this
file in the current directory, in ./lib ../lib and in all the directories 
in @INC.
If it is not found, NULL will be returned.

=item file_path( FILEPATH ) 

Access method to the FILE_PATH data member. FILEPATH can be the absolute 
path of the XML file. But it can be also just a name of the file, or 
relative path to the file. In that case, that file will be searched in 
the following places: 
   * The current directory.
   * The directory ./lib below the current directory.
   * The directory ../lib below the current directory.
   * The directories that are in @INC.

=item log( LOG ) 

Access method to the LOG data member. 

=back

=head1 ENVIRONMENTS

=over 4

=item PHRASEBOOK_DEBUG_PRINTS

If this environment is set to "COLOR", the get method will print the 
phrases it gets, with some extra information in color screen output 
using ANSI escape sequences. If the environment is set to "HTML", the 
information will be printed in HTML format. If the environment is set to 
"TEXT" - the information will be printed as simple text. If the environment 
is not set, or empty - nothing will be printed. This feature comes to help
debugging the phrases that we get from the object of this class.

=item PHRASEBOOK_AS_IS_BETWEEN_TAGS

This environment variable control the default setting of the data member 
AS_IS_BETWEEN_TAGS. If it is unset, that data member is 1 by default. 
See the method B<as_is_between_tags> for more information.

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
L<Log::LogLite(3)>,
L<Log::NullLogLite(3)>,
The Phrasebook Pattern - Yonat Sharon & Rani Pinchuk - PLoP2K -
http://jerry.cs.uiuc.edu/~plop/plop2k/proceedings/Pinchuk/Pinchuk.pdf


=cut
