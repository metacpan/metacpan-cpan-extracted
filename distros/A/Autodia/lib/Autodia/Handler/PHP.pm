################################################################
# AutoDIA - Automatic Dia XML.   (C)Copyright 2001 A Trevena   #
#                                                              #
# AutoDIA comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################
package Autodia::Handler::PHP;

require Exporter;

use strict;

use vars qw($VERSION @ISA @EXPORT);
use Autodia::Handler;
use Data::Dumper;

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
    my $incode = 0;
    my $inclass = 0;
    my $infunc = 0;
    my $inclassparen = 0;
    my $infuncparen = 0;
    my $incommentcount = 0;
    my $incomment = 0;

    my $Class;

    $self->{pod} = 0;

    # parse through file looking for stuff
    foreach my $line (<$fh>)
      {
	chomp $line;
	if ($self->_discard_line($line)) { next; }

	my $commentup = $line =~ tr/\/\*/\/\*/;
	my $commentdown = $line =~ tr/\*\//\*\//;
	$incommentcount = $commentup - $commentdown;
	if ($incommentcount > 0) {
	  $incomment = 1;
	} else {
	  $incomment = 0;
	}
	next if $incomment;
	$line =~ s|\/\/.*$||;

	my $up = $line =~ tr/\{/\{/;
	my $down = $line =~ tr/\}/\}/;
        $inclassparen = $inclassparen + $up - $down if ($inclass > 0);
	$infuncparen = $infuncparen + $up - $down if ($infunc > 0);
	$inclass = 0 if ($inclassparen < 1);
	$infunc = 0 if ($infuncparen < 1);

#	print "$inclassparen : $inclass $infuncparen : $infunc \n";
	if ($line =~ /.*class\s+([^\s\(\)\{\}]+)/) {
	  my $className = $1;
	  $inclass = 1;
	  $inclassparen = $up - $down;
#	  print "Classname: $className matched on:\n$line\n";
	  last if ($self->skip($className));
	  $Class = Autodia::Diagram::Class->new($className);
	  # add to diagram
	  my $exists = $Diagram->add_class($Class);
	  $Class = $exists if ($exists);
	  if ($line =~ /.*extends\s+(\S+)/) {
	    my $superclass = $1;
	    $self->_is_package(\$Class, $filename);
	    my @superclasses = split(" ", $superclass);

	    foreach my $super (@superclasses) # WHILE_SUPERCLASSES
	      {
		# discard if stopword
		next if ($super =~ /(?:exporter|autoloader)/i);
		# create superclass
		my $Superclass = Autodia::Diagram::Superclass->new($super);
		# add superclass to diagram
		my $exists_already = $Diagram->add_superclass($Superclass);
		if (ref $exists_already)
		  {
		    $Superclass = $exists_already;
		  }
		# create new inheritance
		my $Inheritance = Autodia::Diagram::Inheritance->new($Class, $Superclass);
		# add inheritance to superclass
		$Superclass->add_inheritance($Inheritance);
		# add inheritance to class
		$Class->add_inheritance($Inheritance);
		# add inheritance to diagram
		$Diagram->add_inheritance($Inheritance);
	      }
	  }

	}

	if ($line =~ /^\s*(include|require|include_once|require_once)\s+\(*["']?([^\"\'\)]+)["']?\)*/) {
	  my $componentName = $2;

#	  print "componentname: $componentName matched on:\n$line\n";
	  # discard if stopword
	  next if ($componentName =~ /(strict|vars|exporter|autoloader|data::dumper)/i);

	  # check package exists before doing stuff
	  $self->_is_package(\$Class, $filename);

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
	}

	if ($line =~ /^.*=\s*new\s+([^\s\(\)\{\}\;]+)/ || $line =~ /(\w+)::/) {
	  my $componentName = $1;

#	  print "componentname: $componentName matched on:\n$line\n";
	  # discard if stopword
	  next if ($componentName =~ /(self|parent|strict|vars|exporter|autoloader|data::dumper)/i);

	  # check package exists before doing stuff
	  $self->_is_package(\$Class, $filename);

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
	}

	if ($line =~ /^\s*((((static|var|public|private|protected)\s+)+)\$|const\s+)([^\s=\{\}\(\)]+)/) {
	    last unless $inclass;
	    my $default;
           my $attribute_name = $5;
           my $class_modifier = $1;
           my $comment = ($class_modifier =~ m/static/) ? "static ": "";
           $comment .= ($class_modifier =~ m/const/) ? "const": "";

           my $attribute_visibility = ($class_modifier =~ m/(var|public|const)/) ? 0 : ($class_modifier =~ m/(protected)/) ? 2 : 1;


           $attribute_name =~ s/(.*);/$1/;
           if($attribute_name =~  m/^\_/ && $class_modifier =~ m/var/) {
                $attribute_visibility = 1;
           }

           if ($line =~ /^\s*((((static|var|public|private|protected)\s+)+)\$|const\s+)(\S+)\s*=\s*(.*)/) {
              $default = $6;
	      $default =~ s/(.*);/$1/;
	      $default =~ s/(.*)\/\/.*/$1/;
	      $default =~ s/(.*)\/\*.*/$1/;
	    }
#	    print "Attr found: $attribute_name = $default\n$line\n";
	    $Class->add_attribute({
				   name => $attribute_name,
				   visibility => $attribute_visibility,
				   value => $default,
				  });

	}


	# if line contains sub then parse for method data
	if ($line =~ /([^\s]*)\s*function\s+&?(\w+)/) {
	  unless ($inclass) {
	      my @newclass = reverse split (/\//, $filename);
	      $Class = Autodia::Diagram::Class->new($newclass[0]);
	      # add to diagram
	      my $exists = $Diagram->add_class($Class);
	      $Class = $exists if ($exists);
	      $inclass = 1;
	      $inclassparen = $up - $down;
	  }
	  my $subname = $2;
	  my $method_modifier = $1;

	  $infunc = 1;
	  $infuncparen = $up - $down;
	  print "Function found: $subname\n$line\n";
	  my %subroutine = ( "name" => $subname, );
	  $subroutine{"visibility"} = ($method_modifier =~ m/private/) ? 1 : ($method_modifier =~ m/protected/) ? 2 : ($subroutine{"name"} =~ m/^\_/) ? 1 : 0;
	  $subroutine{"inheritance_type"} = ($method_modifier =~ m/abstract/) ? 0 : ($method_modifier =~ m/final/) ? 2 : 1;

	      # check for explicit parameters
	      if ($line =~ /function\s+(\S+)\s*\((.+?)\)/) 
	      {
		  my $parameter_string = $2;

		  $parameter_string =~ s/\s*//g;
		  $parameter_string =~ s/\$//g;
#		  print "Params: $parameter_string\n";
		  my @parameters1 = split(",",$parameter_string);
		  my @parameters;
		  foreach my $par (@parameters1) {
		    my ($name, $val) = split (/=/, $par);
		    $val =~ s/["']//g if (defined $val);
		    $name =~ s/^\s+|\s+$//g;
		    my $kind;
		    if($name =~ m/&/) {
			$name =~ s/&//g;
			$kind = 3;
		    } else {
			$kind = 1;
		    }

		    my %temphash = (
				    Name => $name,
				    Val => $val,
				    Kind => $kind,
				);
		    push @parameters, \%temphash;

		  }
		  $subroutine{"Params"} = \@parameters;
		}
#	    print Dumper(\%subroutine);
	    $Class->add_operation(\%subroutine);
	  }

   }

    $self->{Diagram} = $Diagram;

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

	if ($line =~ /^\s*\=head/) # if line starts with pod syntax discard and flag with $pod
	{
	    $self->{pod} = 1;
	    $discard = 1;
	    last SWITCH;
	}

	if ($line =~ /^\s*\=cut/) # if line starts with pod end syntax then unflag and discard
	{
	    $self->{pod} = 0;
	    $discard = 1;
	    last SWITCH;
	}

	if ($self->{pod} == 1) # if line is part of pod then discard
	{
	    $discard = 1;
	    last SWITCH;
	}
    }
    return $discard;
}

####-----

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

Autodia::Handler::PHP - AutoDia handler for PHP

=head1 INTRODUCTION

Autodia::Handler::PHP is registered in the Autodia.pm module, which contains a hash of language names and the name of their respective language - in this case:

%language_handlers = ( .. ,
		       php => "Autodia::Handler::PHP",
		       .. );

%patterns = ( .. ,
	      php => \%php,
              .. );

my %php = (
             regex      => '\w+\.php$',
             wildcards => [
                        "php","php3","php4"
                           ],
                        );


=head1 CONSTRUCTION METHOD

use Autodia::Handler::PHP;

my $handler = Autodia::Handler::PHP->New(\%Config);

This creates a new handler using the Configuration hash to provide rules selected at the command line.

=head1 ACCESS METHODS

$handler->Parse(filename); # where filename includes full or relative path.

This parses the named file and returns 1 if successful or 0 if the file could not be opened.

$handler->output(); # any arguments are ignored.

This outputs the output file according to the rules in the %Config hash passed at initialisation of the object and the template.

=cut

