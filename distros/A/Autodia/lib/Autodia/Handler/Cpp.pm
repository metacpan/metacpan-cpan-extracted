################################################################
# AutoDIA - Automatic Dia XML.   (C)Copyright 2001 A Trevena   #
#                                                              #
# AutoDIA comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################

#  Now actually works (ish) thanks to Ekkehard ! significant   #
#   amounts of  this code contributed by Ekkehard Goerlach     #

package Autodia::Handler::Cpp;

require Exporter;

use strict;

use vars qw($VERSION @ISA @EXPORT);
use Autodia::Handler;

@ISA = qw(Autodia::Handler Exporter);

use Autodia::Diagram;

#---------------------------------------------------------------

#####################
# Constructor Methods

# new inherited from Autodia::Handler

#------------------------------------------------------------------------
# Access Methods

# parse_file inherited from Autodia::Handler

#-----------------------------------------------------------------------------
# Internal Methods

# _initialise inherited from Autodia::Handler

sub _parse
  {
    my $self     = shift;
    my $fh       = shift;
    my $filename = shift;
    my $Diagram  = $self->{Diagram};

#    print "processing file : $filename \n";

    my $Class;

    $self->{current_package} = $filename;
    $self->{privacy}         = 0;
    $self->{comment}         = 0;
    $self->{in_class}        = 0;
    $self->{in_declaration}  = 0;
    $self->{in_method}       = 0;
    $self->{brace_depth}     = 0;

    my $i = 0;

    # parse through file looking for stuff
    while (<$fh>)
      {
      LINE:
	{
	  chomp(my $line=$_);
	  if ($self->_discard_line($line)) { last LINE; }

#	  print "line $i : $line \n";
	  $i++;

	  # check for class declaration
	  if ($line =~ m/^\s*class\s+(\w+)/)
	    {

#	      print "found class : $line \n";

	      my $classname = $1;
	      $self->{in_class} = 1;
	      $self->{privacy} = "private";
	      $self->{visibility} = 1;
	      $classname =~ s/[\{\}]//g;
	      last if ($self->skip($classname));
	      $Class = Autodia::Diagram::Class->new($classname);
	      my $exists = $Diagram->add_class($Class);
	      $Class = $exists if ($exists);

	      # handle superclass(es)
	      if ($line =~ m/^\s*class\s+\w+\s*\:\s*([^{]+)\s*/)
		{
		  my $superclasses = $1;
		  $superclasses =~ s/public\s*//i;
		  warn "found superclasses : $superclasses\n";
		  my @superclasses = split (/\s*,\s*/, $superclasses);
		  foreach my $super (@superclasses) {
		      $super =~ s/\s*//ig;
#		      warn "superclass : $super\n";
		      $super =~ s/^\s*(\w+\s+)?([A-Za-z0-9\_]+)\s*$/$2/;
#		      warn "superclass : $super\n";
		      my $Superclass = Autodia::Diagram::Superclass->new($super);
		      my $exists_already = $Diagram->add_superclass($Superclass);
		      if (ref $exists_already) {
			  $Superclass = $exists_already;
		      }
		      my $Inheritance = Autodia::Diagram::Inheritance->new($Class, $Superclass);
		      $Superclass->add_inheritance($Inheritance);
		      $Class->add_inheritance($Inheritance);
		      $Diagram->add_inheritance($Inheritance);
		  }
		}
	      last LINE;
	    }

	  # check for end of class declaration
	  if ($self->{in_class} && ($line =~ m|^\s*\}\;|))
	    {
#	      print "found end of class\n";
	      $self->{in_class} = 0;
	      $self->{privacy} = 0;
	      last LINE;
	    }

	  # check for abstraction/data hiding
	  if ($self->{in_class})
	    {
	      if ($line =~ m/^\s*protected\s*\:/)
		{
#		  print "found protected variables/classes\n";
		  $self->{privacy} = "protected";
		  $self->{visibility} = 2;
		  $self->_parse_private_things($line,$Class);
		  last LINE;
		}

	      if ($line =~ m/^\s*private\s*\w*\:/)
		{
#		  print "found private variables/classes\n";
		  $self->{privacy} = "private";
		  $self->{visibility} = 1;

		  # check for attributes and methods
		  $self->_parse_private_things($line,$Class);

		  last LINE;
		}

	      if ($line =~ m/^\s*public\s*\w*\:/)
		{
#		  print "found public variables/classes\n";
		  $self->{privacy} = "public";
		  $self->{visibility} = 0;
		  $self->_parse_private_things($line,$Class);
		  last LINE;
		}

	      if ($line =~ m/operator/)
		{
#		  print "found overloaded operator\n";
		  last LINE if $line =~ /;/;

		  while ($line !~ /{/)
		    {
		      $line = <$fh>;
#		      print "waiting for start of overload def: $line\n";
		    }
		  my $start_brace_cnt = $line =~ tr/{/{/ ;
		  my $end_brace_cnt   = $line =~ tr/}/}/ ;

		  $self->{brace_depth} = $start_brace_cnt - $end_brace_cnt;
		  $self->{in_method}   = 1 unless $self->{brace_depth}  == 0;
#		  print "OvStart: ",$start_brace_cnt, $end_brace_cnt, $self->{brace_depth}, $self->{in_method} ,"\n";

		  last LINE;
		}

	      # if inside a class method then discard line
	      if ($self->{in_method})
		{
		  # count number of braces and increment decrement depth accordingly
		  # if depth = 0 then reset in_method and next;
		  # else next;
		  my $start_brace_cnt = $line =~ tr/{/{/ ;
		  my $end_brace_cnt   = $line =~ tr/}/}/ ;

		  $self->{brace_depth} = $self->{brace_depth} + $start_brace_cnt - $end_brace_cnt;
		  $self->{in_method}   = $self->{brace_depth}  == 0 ? 0 : 1;

#		  print "In method: ",$start_brace_cnt, $end_brace_cnt, $self->{brace_depth}, $self->{in_method} ,"\n";
		  last LINE;
		}

		  # check for simple declarations
		  # space* const? space+ (namespace::)* type space* modifier? space+ name;

		  if ($line =~ m/^\s*\w*?\s*((\w+\s*::\s*)*[\w<>]+\s*[\*&]?)\s*(\w+)\s*\;.*$/)        # Added support for pointers/refs/namespaces
		{
		  my $name = $3;
		  my $type = $1;
#		  print "found simple variable declaration : name = $name, type = $type\n";

		  #my $visibility = ( $name =~ m/^\_/ ) ? 1 : 0;

		  $Class->add_attribute({
					 name => $name,
					 visibility => $self->{visibility},  #was: $visibility,
					 type => $type,
					});

		  last LINE;
	      }

	      # check for simple sub
	      if ($line =~ m/^                       # start of line
                            \s*                      # whitespace
                            (\w*?\s*?(\w+\s*::\s*)*[\w<>]*?\s*[\*&]?) # type of the method: $1. Added support for namespaces
                            \s*                      # whitespace
                            (~?\w+)                  # name of the method: $3
                            \s*                      # whitespace
                            \(\s*                    # start of parameter list
                            ([:\w\,\s\*=&\"<>\\\d\-]*)  # all parameters: $4
                            (\)?)                    # may be an ending bracket: $5
                            [\w\s=]*(;?)             # possibly end of signature $6
                            .*$/x
		 )
		{
		  my $name = $3;
		  my $type = $1 || "void";
		  my $params = $4;
		  my $end_bracket = $5;
		  my $end_semicolon = $6;

		  my $have_continuation = 0;
		  my $have_end_semicolon= 0;

		  if ($name eq $Class->{"name"})
		    {
#		      print "found constructor declaration : name = $name\n";
		      $type = "";
		    }
		  else
		    {
		      if ($name eq "~".$Class->{"name"})
			{
#			  print "found destructor declaration : name = $name\n";
			  $type = "";
			}
		      else
			{
#			  print "found simple function declaration : name = $name, type = $type\n";
			}
		    }

		  $have_continuation  = 1 unless $end_bracket    eq ")";
		  $have_end_semicolon = 1 if     $end_semicolon  eq ";";

#		  print $have_continuation  ? "no ":"with " ,"end bracket : $end_bracket\n";
#		  print $have_end_semicolon ? "with ":"no " ,"end semicolon : $end_semicolon\n";

		  $params    =~ s|\s+$||;
		  my @params = split(",",$params);
		  my $pc = 0; # parameter count

		  my %subroutine = (
				    name       => $name,
				    type       => $type,
				    visibility => $self->{visibility},
				   );

		  # If we have continuation lines for the parameters get them all
		  while ($have_continuation)
		    {
		      my $line = <$fh>;
		      last unless ($line);
		      chomp $line;

		      if ($line =~ m/^                        # start of line
                                     \s*                      # whitespace
			             ([:\w\,\|\s\*=&\"<>\\]*) # all parameters: $1
                                     (\)?)                    # may be an ending bracket: $2
                                     [\w\s=]*(;?)             # possibly end of signature $3
                                     .*$/x)
			{
			  my $cparams     = $1;
			  $end_bracket    = $2;
			  $end_semicolon  = $3;

			  $cparams =~ s|\s+$||;
			  my @cparams = split(",",$cparams);
			  push @params, @cparams;

#			  print "More parameters: >$cparams<\n";

			  $have_continuation  = 0 if ($end_bracket   eq ")");
			  $have_end_semicolon = 1 if ($end_semicolon eq ";");

#			  print $have_continuation ? "no ":"with " ,"end bracket : $end_bracket\n";
#			  print $have_end_semicolon ? "with ":"no " ,"end semicolon : $end_semicolon\n";
			}
		    }


		  # then get parameters and types
		  my @parameters = ();
#		  print "All parameters: ",join(';',@params),"\n";
		  foreach my $parameter (@params)
		    {
		      $parameter =~ s/const\s+//;
		      $parameter =~ m/\s*((\w+::)*[\w<>]+\s*[\*|\&]?)\s*(\w+)/ ;
		      my ($type, $name) = ($1,$3);

		      $type =~ s/\s//g;
		      $name =~ s/\s//g;

		      $parameters[$pc] = {
					  Name => $name,
					  Type => $type,
					 };
		      $pc++;
		    }

		  $subroutine{"Params"} = \@parameters;
		  $Class->add_operation(\%subroutine);

		  # Now finished with parameters.  If there was no end
		  # semicolon we have an inline method: we read on until we
		  # see the start of the method. This deals with (multi-line)
		  # constructor initialization lists as well.
                  last LINE if $have_end_semicolon;

		  while ($line !~ /{/)
		    {
		      $line = <$fh>;
		      print "waiting for start of method def: $line\n";
		    }
		  my $start_brace_cnt = $line =~ tr/{/{/ ;
		  my $end_brace_cnt   = $line =~ tr/}/}/ ;

		  $self->{brace_depth} = $start_brace_cnt - $end_brace_cnt;
		  $self->{in_method}   = 1 unless $self->{brace_depth}  == 0;
#		  print "Start: ",$start_brace_cnt, $end_brace_cnt, $self->{brace_depth}, $self->{in_method} ,"\n";

		  last LINE;
		}

	      # if line starts with word,space,word then its a declaration (probably)
	      # Broken.
	      if ($line =~ m/\s*[\w<>]+\s+(\w+\s*::\s*)*[\w<>]+/i)
		{
#		  print " probably found a declaration : $line\n";
		  my @words = m/^(\w+)\s*[\(\,\;].*$/g;
		  my $name = $&;
		  my $rest = $';#' to placate some syntax highlighters
		  my $type = '';

		  my $pc = 0; # point count (ie location in array)
		  foreach my $start_point (@-)
		    {
		      my $start = $start_point;
		      my $end = $+[$pc];
		      $type .= substr($line, $start, ($end - $start));
		      $pc++;
		    }

		  # if next character is a ( then the line is a function declaration
		  if ($rest =~ m|^\(([\w<>]+)\(.*(\;?)\s*$|)
		    {
#		      print "probably found a function : $line \n";
		      my $params = $1;
		      my @params = split(",",$params);

		      my $declaration = 0;
		      if (defined $2) # if line ends with ";" then its a declaration
			{
			  $declaration = 1;
			  my @parameters = ();
			  my $pc = 0; # parameter count
			  my %subroutine = (
					    name       => $name,
					    type       => $type,
					    visibility => $self->visibility,
					   );

			  # then get parameters and types
			  foreach my $parameter (@params)
			    {
			      my ($type, $name) = split(" ",$parameter);

			      $type =~ s/\s//g;
			      $name =~ s/\s//g;

			      $parameters[$pc] = {
						  name => $name,
						  type => $type,
						 };
			      $pc++;
			    }

			  $subroutine{param} = \@parameters;
			  $Class->add_operation(\%subroutine);
			}
		      else
			{
			  my @attributes = ();
			  # else next character is , or ; 
			  # the line's a variable declaration
			  $Class->add_attribute ({
						  name       => $name,
						  type       => $type,
						  visibility => $self->{visibility},
						 });
			  my %attribute = { name => $name , type => $type };
			  $attributes[0] = \%attribute;
			  if ($rest =~ m/^\,.*\;/)
			    {
			      my @atts = split (",");
			      foreach my $attribute (@atts)
				{
				my @attribute_parts = split(" ", $attribute);
				my $n = scalar @attribute_parts;
				my $name = $attribute_parts[$n];
				my $type = join(" ",$attribute_parts[0...$n-1]);
				$Class->add_attribute ( {
							 name       => $name,
							 type       => $type,
							 visibility => $self->{visibility},
							});
				#
			      }
			      #
			    }
			  #
		      }
		      # 
		    }
		  #
		}
	    #
	  }
	}
      }

    $self->{Diagram} = $Diagram;
    close $fh;
    return;
  }

sub _discard_line
{
  my $self    = shift;
  my $line    = shift;
  my $discard = 0;

  SWITCH:
    {
	if ($line =~ m/^\s*$/) # if line is blank or white space discard
	{
	    $discard = 1;
	    last SWITCH;
	}

	if ($line =~ /^\s*\/\//) # if line is a comment discard
	{
	    $discard = 1;
	    last SWITCH;
	}

	 # if line is a comment discard
        if ($line =~ m!^\s*/\*.*\*/!)
        {
            $discard = 1;
            last SWITCH;
        }

	# if line starts with multiline comment syntax discard and set flag
	if ($line =~ /^\s*\/\*/)
	{
	    $self->{comment} = 1;
	    $discard = 1;
	    last SWITCH;
	}

	if ($line =~ /^.*\*\/\s*$/)
	  {
	    $self->{comment} = 0;
	  }
	if ($self->{comment} == 1) # if currently inside a multiline comment
	  {
	    # if line starts with comment end syntax then unflag and discard
	    if ($line =~ /^.*\*\/\s*$/)
	      {
		$self->{comment} = 0;
		$discard = 1;
		last SWITCH;
	      }

	    $discard = 1;
	    last SWITCH;
	}
    }
    return $discard;
}

####-----

sub _parse_private_things {
    my $self = shift;
    my $line = shift;
    my $Class = shift;

    return unless ($line =~ m/^\s*private\s*\w*:\s*(\w.*)$/);
    #  print "found private/public things\n";
    my @private_things = split(";",$1);
    foreach my $private_thing (@private_things) {
	print "- private/public thing : $private_thing\n";
	# FIXME : Next line type definition seems erroneous. Any C++ hackers care to check it?
	$private_thing =~ m/^\s*(public|private)?:?\s*(static|virtual)\s*(\w+\s*\*?)\s*(\w+\(?[\w\s]*\)?)\s*\w*\s*\w*.*$/;
	my $name = $4;
	my $type = "$2 $3";
	my $vis = $1 || $self->{visibility};
	#    print "- found declaration : name = $name, type = $type\n";

	if ($name =~ /\(/) {
	    #      print "-- declaration is a method \n";
	    # check for simple sub
	    if ($private_thing =~ m/^                       # start of line
                             \s*                      # whitespace
                             (?:public|private)?:?\s*
                             (\w*?\s*?(\w+\s*::\s*)*\w*?\*?)        # type of the method: $1
			     \s*                      # whitespace
                             (~?\w+)                  # name of the method: $2
                             \s*                      # whitespace
                             \(\s*                    # start of parameter list
                             ([:\w\,\s\*=&\"]*)        # all parameters: $3
			     (\)?) # may be an ending bracket: $4
			     [\w\s=]*(;?)             # possibly end of signature $5
                             .*$/x
	       ) {
		my $name = $3;
		my $type = $1 || "void";
		my $params = $4;
		my $end_bracket = $5;
		my $end_semicolon = $6;

		my $have_continuation = 0;
		my $have_end_semicolon= 1;

		$params    =~ s|\s+$||;
		my @params = split(",",$params);
		my $pc = 0;	# parameter count

		my %subroutine = (
				  name       => $name,
				  type       => $type,
				  visibility => $self->{visibility},
				 );


		# then get parameters and types
		my @parameters = ();
		#	print "All parameters: ",join(';',@params),"\n";
		foreach my $parameter (@params) {
		    $parameter =~ s/const\s+//;

		    my ($type, $name) = split(" ",$parameter);

		    $type =~ s/\s//g;
		    $name =~ s/\s//g;

		    $parameters[$pc] = {
					name => $name,
					type => $type,
				       };
		    $pc++;
		}

		$subroutine{param} = \@parameters;
		$Class->add_operation(\%subroutine);
	    }
	} else {
	    #     print "-- declaration is an attribute \n";
	    $Class->add_attribute({
				   name => $name,
				   visibility => $vis,
				   type => $type,
				  });
	}
    }
    return;
}

sub _is_package
  {
    my $self    = shift;
    my $package = shift;
    my $Diagram = $self->{Diagram};

    unless(ref $$package)
       {
	 my $filename = shift;
	 # create new class with name
	 $$package = Autodia::Diagram::Class->new($filename);
	 # add class to diagram
	 $Diagram->add_class($$package);
       }

    return;
  }

####-----

1;

###############################################################################

=head1 NAME

Autodia::Handler::Cpp - AutoDia handler for C++

=head1 INTRODUCTION

This module parses files into a Diagram Object, which all handlers use. The role of the handler is to parse through the file extracting information such as Class names, attributes, methods and properties.

HandlerPerl parses files using simple perl rules. A possible alternative would be to write HandlerCPerl to handle C style perl or HandleHairyPerl to handle hairy perl.

HandlerPerl is registered in the Autodia.pm module, which contains a hash of language names and the name of their respective language - in this case:

%language_handlers = { .. , cpp => "Autodia::Handler::Cpp", .. };

=head1 CONSTRUCTION METHOD

use Autodia::Handler::Cpp;

my $handler = Autodia::Handler::Cpp->New(\%Config);

This creates a new handler using the Configuration hash to provide rules selected at the command line.

=head1 ACCESS METHODS

This parses the named file and returns 1 if successful or 0 if the file could not be opened.

$handler->output_xml(); # interpolates values into an xml or html template

$handler->output_graphviz(); # generates a gif file via graphviz

=cut
