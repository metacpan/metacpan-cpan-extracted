################################################################
# AutoDIA - Automatic Dia XML.   (C)Copyright 2001 A Trevena   #
#                                                              #
# AutoDIA comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
#                                                              #
# Created by Gnavicks                                          #
# Version 1.0                                                  #
# February 11, 2010                                            #
################################################################
package Autodia::Handler::ASP;

require Exporter;

use strict; # requires 'my' keyword on variables

use vars qw($VERSION @ISA @EXPORT);
use Autodia::Handler;
use Data::Dumper; # enables the Dumper method

@ISA = qw(Autodia::Handler Exporter);

use Autodia::Diagram;

#---------------------------------------------------------------

#####################
# Constructor Methods

# new inherited from Handler

#------------------------------------------------------------------------
# Access Methods

# parse_file inherited from Handler

#-----------------------------------------------------------------------------
# Internal Methods

# _initialise inherited from Handler

sub _parse
{
    my $self     = shift;
    my $fh       = shift;
    my $filename = shift;
    my $Diagram  = $self->{Diagram};
    my $Class;

    $self->{pod} = 0;

	# create 'this' file
	my @newclass = reverse split (/\//, $filename);
	$Class = Autodia::Diagram::Class->new($newclass[0]);
	# add component to diagram
	my $classExists = $Diagram->add_class($Class);
	# replace component if redundant
	if (ref $classExists)
	{
		$Class = $classExists;
	}

    # parse through file looking for stuff
    foreach my $line (<$fh>)
    {
	    chomp $line;
	    if ($self->_discard_line($line)) { next; }

		# removes trailing single line comment of (') type
		if($line !~ /\(\s*\'.*\'\s*\).*$/) { # if not a javascript call
		    $line =~ s/\'.*$//;	
		}
		$line =~ s/\\\\.*$//; # removes trailing single line comment of (//) type

		# finds all the ASP includes like <!-- #include file="includes/version.asp"--> 
		if ($line =~ /.*\#include.+["'](.+)["']/i) {
		    my $componentName = $1;

#           print "componentname: $componentName matched on:\n$line\n";

			# create component
			my @newComponent = reverse split (/\//, $componentName);
			my $Component = Autodia::Diagram::Class->new($newComponent[0]);
			# add component to diagram
			my $exists = $Diagram->add_class($Component);

		    # replace component if redundant
		    if (ref $exists)
			{
			    $Component = $exists;
			}

			# create new relation (association)
			my $Relation = Autodia::Diagram::Relation->new($Class, $Component);
			# add relation to diagram
			$Diagram->add_relation($Relation);
			# add relation to class
			$Class->add_relation($Relation);
			# add relation to component
			$Component->add_relation($Relation);

			next;
        } # end if

		# finds all the JavaScript file includes like <script LANGUAGE="JavaScript" SRC="javascript/overlib.js"></script>
		if ($line =~ /.*JavaScript.+SRC\=\"(.+)\"\>/i) {
		    my $componentName = $1;

#	        print "componentname: $componentName matched on:\n$line\n";

		    # create component
		    my @newComponent = reverse split (/\//, $componentName);
		    my $Component = Autodia::Diagram::Class->new($newComponent[0]);
		    # add component to diagram
		    my $exists = $Diagram->add_class($Component);

		    # replace component if redundant
		    if (ref $exists)
			{
			    $Component = $exists;
			}

		    # create new relation (association)
		    my $Relation = Autodia::Diagram::Relation->new($Class, $Component);
		    # add relation to diagram
		    $Diagram->add_relation($Relation);
		    # add relation to class
		    $Class->add_relation($Relation);
		    # add relation to component
		    $Component->add_relation($Relation);

			next;
		} # end if

		# finds all the CSS StyleSheet file includes <link REL="stylesheet" TYPE="text/css" HREF="RMT.css">
		if ($line =~ /.*stylesheet.+HREF\=\"(.+)\"\>/i) {
		    my $componentName = $1;

#	        print "componentname: $componentName matched on:\n$line\n";

		    # create component
		    my @newComponent = reverse split (/\//, $componentName);
		    my $Component = Autodia::Diagram::Class->new($newComponent[0]);
		    # add component to diagram
		    my $exists = $Diagram->add_class($Component);

		    # replace component if redundant
		    if (ref $exists)
			{
			    $Component = $exists;
			}

		    # create new relation (association)
		    my $Relation = Autodia::Diagram::Relation->new($Class, $Component);
		    # add relation to diagram
		    $Diagram->add_relation($Relation);
		    # add relation to class
		    $Class->add_relation($Relation);
		    # add relation to component
		    $Component->add_relation($Relation);

			next;
		} # end if

        # finds all "new" dependancies
	    if ($line =~ /^.*=\s*new\s+([^\s\(\)\{\}\;]+)/ || $line =~ /(\w+)::/) {
	        my $componentName = $1;

#	        print "componentname: $componentName matched on:\n$line\n";

	        # create component
	        my $Component = Autodia::Diagram::Component->new($componentName);
	        # add component to diagram
	        my $exists = $Diagram->add_component($Component);

	        # replace component if redundant
	        if (ref $exists)
	        {
	            $Component = $exists;
	        }

	        # create new dependancy
	        my $Dependancy = Autodia::Diagram::Dependancy->new($Class, $Component);
	        # add dependancy to diagram
	        $Diagram->add_dependancy($Dependancy);
	        # add dependancy to class
	        $Class->add_dependancy($Dependancy);
	        # add dependancy to component
	        $Component->add_dependancy($Dependancy);
	    } # end if

		# if line contains an attribute then parse for it
		if ($line =~ /^\s*const\s+([^\s=\{\}\(\)]+)/i) {
		    my $attribute_name = $1;

#	        print "Attr found: $attribute_name\n$line\n";

			$Class->add_attribute({
				name => $attribute_name,
				visibility => 0,
			});
		} # end if

		# if line contains a function or sub then parse for method data
		if ($line =~ /([^\s\<\%]*.*)(function|sub)\s+([^\s\(\)\%\>]+)/i) {
			my $subname = $3;

#			print "Function found: $subname\n$line\n";

			my $method_modifier = $1;
			if(not defined $method_modifier) {
				$method_modifier = "";
			}

			my %subroutine = ( "name" => $subname, );
			$subroutine{"visibility"} = ($method_modifier =~ m/private/i) ? 1 : ($method_modifier =~ m/protected/i) ? 2 : ($subroutine{"name"} =~ m/^\_/) ? 1 : 0;

			# check for explicit parameters
			if ($line =~ /(function|sub)\s+(\S+)\s*\((.+?)\)/i) 
			{
				my $parameter_string = $3;
				$parameter_string =~ s/\s*//g;

#				print "Params: $parameter_string\n";

				my @parameters1 = split(",",$parameter_string);
				my @parameters;

				foreach my $par (@parameters1) 
				{
					$par =~ s/^\s+|\s+$//g;

					push @parameters, { 
						Name  => $par,
					};
				} # end foreach

				$subroutine{"Params"} = \@parameters;
			} # end if

#			print Dumper(\%subroutine);

			$Class->add_operation(\%subroutine);

		} # end if

		# finds all the misc objects and relates them by dependancy
		if ($line =~ /([^\s\\\/\'\"\(\=]+)\.(asp|mdb|gif|jpg|htm|html|zip|java|class|js)[^a-z]/i) {
			my $componentName = $1;
			my $fileExt = $2;

#			print "componentname: $componentName.$fileExt matched on:\n$line\n";

			# create component
			my $Component = Autodia::Diagram::Class->new($componentName.".".$fileExt);
			# add component to diagram
			my $exists = $Diagram->add_class($Component);

			# replace component if redundant
		    if (ref $exists)
			{
				$Component = $exists;
			}

			# create new dependancy
			my $Dependancy = Autodia::Diagram::Dependancy->new($Class, $Component);
			# add dependancy to diagram
			$Diagram->add_dependancy($Dependancy);
			# add dependancy to class
			$Class->add_dependancy($Dependancy);
			# add dependancy to component
			$Component->add_dependancy($Dependancy);
		} # end if

	} # end main foreach

	$self->{Diagram} = $Diagram;
    return;

} # end _parse()

####-----

sub _discard_line
{
	my $self    = shift;
	my $line    = shift;
	my $discard = 0;

    SWITCH:
    {
		# if line is blank or white space discard
		if ($line =~ m/^\s*$/)
		{
			$discard = 1;
			last SWITCH;
		}
		
		# if line is a comment (') discard
		if ($line =~ /^\s*\'/) 
		{
			$discard = 1;
			last SWITCH;
		}
		
		 # if line is a comment (//) discard
		if ($line =~ /^\s*\/\//)
		{
			$discard = 1;
			last SWITCH;
		}
	
		# if line starts with pod start syntax discard and flag with $pod
		if ($line =~ /^\s*\=pod/)
		{
			$self->{pod} = 1;
			$discard = 1;
			last SWITCH;
		}

		# if line starts with pod start syntax discard and flag with $pod
		if ($line =~ /^\s*\=head/)
		{
			$self->{pod} = 1;
			$discard = 1;
			last SWITCH;
		}

		# if line starts with pod end syntax then unflag and discard
		if ($line =~ /^\s*\=cut/)
		{
			$self->{pod} = 0;
			$discard = 1;
			last SWITCH;
		}


		# if line starts with HTML start comment syntax then discard and flag with $pod (avoids ignoring ASP includes)
		if ($line =~ /^\s*\<\!\-\-/ && $line !~ /.*\#include/i)
		{
			# if same line ends with the HTML end comment syntax then unflag and discard
			if ($line =~ /\s*\-\-\>\s*$/ || $line =~ /\s*\/\/s*$/) { 
				$self->{pod} = 0;
				$discard = 1;
				last SWITCH;
			} else { # otherwise we are in pod
				$self->{pod} = 1;
				$discard = 1;
				last SWITCH;
			}
		}

		# if line ends with the HTML comment syntax then unflag and discard (avoids ignoring ASP includes)
		if ($line =~ /\s*\-\-\>\s*$/ && $line !~ /.*\#include/i) 
		{
			$self->{pod} = 0;
			$discard = 1;
			last SWITCH;
		}

		# if line is part of pod or HTML comment then discard
		if ($self->{pod} == 1)
		{
			$discard = 1;
			last SWITCH;
		}

	} # end switch

    return $discard;
} # end _discard_line()

####-----

1;

###############################################################################

=head1 NAME

Autodia::Handler::ASP - AutoDia handler for ASP

=head1 INTRODUCTION

Autodia::Handler::ASP is registered in the Autodia.pm module, which contains a hash of language names and the name of their respective language - in this case:

%language_handlers = ( .. ,
		       asp => "Autodia::Handler::ASP",
		       .. );

%patterns = ( .. ,
	      asp => \%asp,
              .. );

my %asp    = ( regex   => '\w+.asp',
		 wildcards => ['asp'],
		);


=head1 CONSTRUCTION METHOD

use Autodia::Handler::ASP;

my $handler = Autodia::Handler::ASP->New(\%Config);

This creates a new handler using the Configuration hash to provide rules selected at the command line.

=head1 ACCESS METHODS

$handler->Parse(filename); # where filename includes full or relative path.

This parses the named file and returns 1 if successful or 0 if the file could not be opened.

$handler->output(); # any arguments are ignored.

This outputs the output file according to the rules in the %Config hash passed at initialisation of the object and the template.

=cut