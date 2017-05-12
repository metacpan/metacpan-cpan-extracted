################################################################
# AutoDIA - Automatic Dia XML.   (C)Copyright 2001 A Trevena   #
#                                                              #
# AutoDIA comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################
package Autodia::Handler::python;

require Exporter;

use strict;

use vars qw($VERSION @ISA @EXPORT);
use Autodia::Handler;

@ISA = qw(Autodia::Handler Exporter);

use Autodia::Diagram;
use Data::Dumper;

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

sub _parse {		# parses python source code
  my $self     = shift;
  my $fh       = shift;
  my $filename = shift;

  warn "_parse_file called with $self, $fh, $filename\n";

  my %config   = %{$self->{Config}};
  my $Diagram  = $self->{Diagram};

  # set up local variables for parsing
  $self->{in_comment} = 0;
  my $module_name = $filename;
  $module_name =~ s/^.*?\/?(\w+)\.py$/$1/;
  my $in_class = 0;
  my $current_class = $module_name;
  my $exit_depth = -1;

  my $Module = Autodia::Diagram::Class->new($module_name);
  my $exists = $Diagram->add_class($Module);
  my $Class = $Module = $exists if ($exists);

  my %aliases = ();

  # process file
  my $class_count = 0;
  foreach my $line (<$fh>) {
    next if  $self->_discard_line (\$line);
    # count spaces / tabs to see how deep indented
    my $depth = 0;
    foreach (split(//,$line)) {
      last if (/\S/);
      $depth++;
    }
    if ($depth == $exit_depth) {
      $in_class = 0;
      $current_class = $module_name;
      $Class = $Module;
    }

    # catch methods and subs
    if ( $line =~ m/^[\s\t]*def\s+(\S+)\s*\((.*)\):/ ) {
      my %method = ( "name" => $1, );
      $method{"visibility"} = ($method{"name"} =~ m/^\_/) ? 1 : 0;
      my $params = $2 || '';
      if ($params) {
	  foreach (split(/\s*,\s*/,$params)) {
	      push (@{$method{"Params"}},{Name => $_, Val => '',});
	  }
      }
      $Class->add_operation(\%method);
    }

    # catch class
    if ( $line =~ /^class\s+(\w+).*:/ ) {
      my $classname = $1;
      $current_class = "$module_name.$classname";
      last if ($self->skip($classname));
      $Class = Autodia::Diagram::Class->new("$module_name.$classname");
      my $exists = $Diagram->add_class($Class);
      $Class = $exists if ($exists);
      $aliases{$classname} = $Class;

      warn "got class name : $classname\n";
      warn " line : $line \n";
      if ( $line =~ /\((.*)\)/) {
	  my @superclasses = split(/[\,\s]/,$1);
	  foreach my $super (@superclasses) {
	      # create superclass
	      warn "have superclass : $super\n";
	      next unless ($super=~/\S/);
	      my $Superclass;
	      # check if superclass exists already
	      if ($aliases{$super}) {
		  $Superclass = $aliases{$super};
		  warn "found alias for superclass $super - ",$Superclass->Name , "\n";
	      } else {
		  $Superclass = Autodia::Diagram::Superclass->new($super);
		  # add superclass to diagram
		  my $exists_already = $Diagram->add_superclass($Superclass);
		  if (ref $exists_already) {
		      warn "superclass exists already";
		      $Superclass = $exists_already;
		  }
		  $aliases{$super} = $Superclass;
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
      $in_class = 1;
      $exit_depth = $depth;
    }

    # catch object attributes via self.foo or this.foo
    if ( $line =~ /(self|this)\.(\w+)\.?/ ) {
      my $attribute = $2;
      my $attribute_visibility = ( $attribute =~ m/^\_/ ) ? 1 : 0;
      $Class->add_attribute({
			     name => $attribute,
			     visibility => $attribute_visibility,
			     value => '',
			    });
    }
    if ( $line =~ /import/ ) {
      my $dependancy;
      if ($line =~ /from\s+(\w+)\s+import/) {
	$dependancy = $1;
      } elsif ($line =~ /\s*import\s+(\w+)/) {
	$dependancy = $1;
      } else {
	# not supported
      }
      if ($dependancy) {
	# create component
	my $Component = Autodia::Diagram::Component->new($dependancy);
	# add component to diagram
	my $exists = $Diagram->add_component($Component);
	# replace component if redundant
	if (ref $exists) {
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
    }
  }
}
##########################################


sub _discard_line
{
  my $self    = shift;
  my $line    = shift;
  my $discard = 0;

  SWITCH:
    {
	if ($$line =~ /"""/) # if line is a comment discard
	{
	  $$line =~ s/""".*"""//;
	  if ($self->{in_comment}) {
	    if ($$line =~ /"""(\s*\w[\w\s]*)/) {
	      $self->{in_comment} = 0;
	      $$line = $1;
	    } else {
	      $self->{in_comment} = 0;
	      $discard = 1;
	    }
	  } else {
	    if ($$line =~ /^(\s*[\w\s]*)"""/) {
	      $self->{in_comment} = 1;
	      $$line = $1;
	    } else {
	      $discard = 1;
	    }
	  }
	  last SWITCH;
	} else {
	  $discard = 1 if ($self->{in_comment});
	}

	if ($$line =~ /#/) {
	  if ($$line =~ /^(\s*\w[\w\s]*)#/) {
	    $$line = $1;
	  } else {
	    $discard = 1;
	  }
	  last SWITCH;
	}
    } # end SWITCH

  $discard = 1 if ($$line =~ m/^\s*$/); # if line is blank or white space discard
  return $discard;
}
