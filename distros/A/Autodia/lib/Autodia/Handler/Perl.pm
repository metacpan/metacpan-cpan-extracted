package Autodia::Handler::Perl;
require Exporter;
use strict;

=head1 NAME

Autodia::Handler::Perl.pm - AutoDia handler for perl

=head1 DESCRIPTION

HandlerPerl parses files into a Diagram Object, which all handlers use. The role of the handler is to parse through the file extracting information such as Class names, attributes, methods and properties.

HandlerPerl parses files using simple perl rules. A possible alternative would be to write HandlerCPerl to handle C style perl or HandleHairyPerl to handle hairy perl.

HandlerPerl is registered in the Autodia.pm module, which contains a hash of language names and the name of their respective language - in this case:

%language_handlers = { .. , perl => "perlHandler", .. };

=cut

use Data::Dumper;

use vars qw($VERSION @ISA @EXPORT);
use Autodia::Handler;

@ISA = qw(Autodia::Handler Exporter);

use Autodia::Diagram;

=head1 METHODS

=head2 CONSTRUCTION METHOD

use Autodia::Handler::Perl;

my $handler = Autodia::Handler::Perl->New(\%Config);

This creates a new handler using the Configuration hash to provide rules selected at the command line.

=head2 ACCESSOR METHODS

$handler->Parse(filename); # where filename includes full or relative path.

This parses the named file and returns 1 if successful or 0 if the file could not be opened.

$handler->output(); # any arguments are ignored.

This outputs the Dia XML file according to the rules in the %Config hash passed at initialisation of the object.

=cut

sub find_files_by_packagename {
    my $config = shift;
    my $args = $config->{args};
    my @filenames = ();
    die "not implemented yet, sorry\n";
    my @incdirs = @INC;
    if ($config) {
      unshift (@incdirs, split(" ",$args->{'d'}));
    }

    my @regexen = map ( s|::|\/|g, split(" ",$args->{'i'}));
    find ( { wanted => sub {
	       unless (-d) {
		 foreach my $regex (@regexen) {
		   push @filenames, $File::Find::name
		     if ($File::Find::name =~ m/$regex/);
		 }
	       }
	     },
	     preprocess => sub {
	       my @return;
	       foreach (@_) {
		 push(@return,$_) unless (m/^.*\/?(CVS|RCS)$/ && $config->{skipcvs});
	       }
	       return @return;
	     },
	   },
	   @incdirs
	 );
    return @filenames;
}

#------------------------------------------------------------------------
# Access Methods

# parse_file inherited from Autodia::Handler

#-----------------------------------------------------------------------------
# Internal Methods

# _initialise inherited from Autodia::Handler

sub _parse {
    my $self     = shift;
    my $fh       = shift;
    my $filename = shift;
    my $Diagram  = $self->{Diagram};
    my $pkg_regexp = '[A-Za-z][\w:]+';
    my $Class;

    # Class::Tangram bits
    $self->{_superclasses} = {};
    $self->{_modules} = {};
    $self->{_is_tangram_class} = {};
    $self->{_in_tangram_class} = 0;
    $self->{_insideout_class} = 0;
    my $pat1 = '[\'\"]?\w+[\'\"]?\s*=>\s*\{.*?\}';
    my $pat2 = '[\'\"]?\w+[\'\"]?\s*=>\s*undef';

    # pod
    $self->{pod} = 0;

    # parse through file looking for stuff
    my $continue = {};
    my $last_sub;

    my $line_no = 0;
    foreach my $line (<$fh>) {
      $line_no++;
	chomp $line;
	if ($self->_discard_line($line)) {
#	    warn "discarded line : $line\n";
	    next;
	}

	# if line contains package name then parse for class name
	if ($line =~ /^\s*package\s+($pkg_regexp)?;?/ || $continue->{package}) {
	  $line =~ /^\s*($pkg_regexp);/ if($continue->{package});
	  if(!$1) {
	    warn "No package name! line $line_no : $line\n";
            $continue->{package} = 1;
            next;
	  }

	  $continue->{package} = 0;
	  my $className = $1;
	  last if ($self->skip($className));
	  # create new class with name
	  $Class = Autodia::Diagram::Class->new($className);
	  # add class to diagram
	  my $exists = $Diagram->add_class($Class);
	  $Class = $exists if ($exists);
	}

        my $continue_base = $continue->{base};
	if ($line =~ /^\s*use\s+(?:base|parent)\s+(?:q|qw|qq)?\s*([\'\"\(\{\/\#])\s*([^\'\"\)\}\/\#]*)\s*(\1|[\)\}])?/ or ($continue_base && $line =~ /$continue_base/)) {

	    my $superclass = $2;
	    my $end = $3 || '';

	    if ($continue_base) {
#		warn "continuing base\n";
		$continue_base =~ s/[\)\}\'\"]/\\1/;
#		warn "base ctd : $continue_base\n";
#               warn "superclass : " . ($superclass|| '') . "\n";

		if ( $line =~ /(.*)\s*$continue_base?/ ) {
		    $continue_base = 0;
		    $superclass = $1;
#		    warn "end of continued base\n";
		}
	    } else {
#		warn "start of base\n";
#		warn "superclass : $superclass\n";
		$continue_base = '[\)\}\'\"]';
		if ($end) {
		  $continue_base = 0;
#		  warn "base is only 1 line\n";
		}
#		warn "continue base : $continue_base\n";
	    }
#	    warn "superclass : $superclass\n";
	    $continue->{base} = $continue_base;
	    # check package exists before doing stuff
	    $self->_is_package(\$Class, $filename);

	    my @superclasses = split(/[\s*,]/, $superclass);

	    foreach my $super (@superclasses) # WHILE_SUPERCLASSES
		{
		    # discard if stopword
		    next if ($super =~ /(?:exporter|autoloader)/i);
		    # create superclass
		    my $Superclass = Autodia::Diagram::Superclass->new($super);
		    # add superclass to diagram
		    $self->{_superclasses}{$Class->Name}{$super} = 1;
		    if ($super =~ m/Class..Accessor\:*/) {
			$self->{_superclasses}{$Class->Name}{'Class::Accessor'} = 1;
		    }

		    $self->{_is_tangram_class}{$Class->Name} = {state=>0} if ($super eq 'Class::Tangram');

		    my $exists_already = $Diagram->add_superclass($Superclass);
		    #	  warn "already exists ? $exists_already \n";
		    if (ref $exists_already) {
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


	    if (grep (/DBIx::Class$/,@superclasses)) {
	      $self->{_dbix_class} = 1;
	    }
	    next;
	}

	# if line contains dependancy name then parse for module name
	if ($line =~ /^\s*(use|require)\s+($pkg_regexp)/) {
#	    warn "found a module being used/required : $2\n";
	    unless (ref $Class) {
		# create new class with name
		$Class = Autodia::Diagram::Class->new($filename);
		# add class to diagram
		my $exists = $Diagram->add_class($Class);
		$Class = $exists if ($exists);
	    }
	    my $componentName = $2;
	    # discard if stopword
	    next if ($componentName =~ /^(strict|vars|exporter|autoloader|warnings.*|constant.*|data::dumper|carp.*|overload|switch|\d|lib)$/i);

	    if ($componentName eq 'Class::XSAccessor') {
	      $self->{_class_xsaccessor} = 1;
	    }

	    if ($componentName eq 'Object::InsideOut') {
	      $self->{_insideout_class} = 1;
	      if ($line =~ /^\s*use\s+.*qw\((.*)\)/) {
		my @superclasses = split(/[\s+]/, $1);
		foreach my $super (@superclasses) {
		  my $Superclass = Autodia::Diagram::Superclass->new($super);
		  # add superclass to diagram
		  my $exists_already = $Diagram->add_superclass($Superclass);
		  #	  warn "already exists ? $exists_already \n";
		  if (ref $exists_already) {
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
	      next;
	    }

	    $self->{_modules}{$componentName} = 1;

	    # check package exists before doing stuff
	    $self->_is_package(\$Class, $filename);

	    my $continue_fields = $continue->{fields};
	    if ($line =~ /\s*use\s+(fields|private|public)\s+(?:q|qw|qq){0,1}\s*([\'\"\(\{\/\#])\s*(.*)\s*([\)\}\1]?)/ or $continue_fields) {
		my ($pragma,$fields) = ($1,$3);
#		warn "pragma : $pragma .. fields : $fields\n";
		if ($continue_fields) {
		    $continue_fields =~ s/[\)\}\'\"]/\\1/;
#		    warn "fields ctd : $continue_fields\n";
		    if ( $line =~ m/(.*)\s*$continue_fields?/ ) {
			$continue_fields = 0;
			$fields = $1;
		    }
		} else {
		    $continue_fields = '[\)\}\'\"]';
		    if ($fields =~ /(.*)([\)\}\1])/) {
			$continue_fields = 0;
			$fields = $1;
		    }
#		    warn "continue fields : $continue_fields\n";
		}
#		warn "fields : $fields\n";

		my @fields = split(/\s+/,$fields);
		foreach my $field (@fields) {
#		    warn "fields : $field\n";
		    my $attribute_visibility = ( $field =~ m/^\_/ ) ? 1 : 0;
		    unless ($pragma eq 'fields') {
			$attribute_visibility = ($pragma eq 'private' ) ? 1 : 0;
		    }
		    $Class->add_attribute({
					   name => $field,
					   visibility => $attribute_visibility,
					   Id => $Diagram->_object_count,
					  }) unless ($field =~ /^\$/);
		}
	    } else {
		# create component
		my $Component = Autodia::Diagram::Component->new($componentName);
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
		next;
	    }
	    $continue->{fields} = $continue_fields;
	}

	# if ISA in line then extract templates/superclasses
	if ($line =~ /^\s*\@(?:\w+\:\:)*ISA\s*\=\s*(?:q|qw){0,1}\((.*)\)/) {
	    my $superclass = $1;
	    $superclass =~ s/[\'\",]//g;

	    #      warn "handling superclasses $1 with \@ISA\n";
	    #      warn "superclass line : $line \n";
	    if ($superclass) {
		# check package exists before doing stuff
		$self->_is_package(\$Class, $filename);

		my @superclasses = split(" ", $superclass);

		foreach my $super (@superclasses) # WHILE_SUPERCLASSES
		    {
			# discard if stopword
			next if ($super =~ /(?:exporter|autoloader)/i || !$super);
			# create superclass
			my $Superclass = Autodia::Diagram::Superclass->new($super);
			# add superclass to diagram
			my $exists_already = $Diagram->add_superclass($Superclass);
			#	      warn "already exists ? $exists_already \n";
			if (ref $exists_already) {
			    $Superclass = $exists_already;
			}
			$self->{_superclasses}{$Class->Name}{$super} = 1;
			$self->{_is_tangram_class}{$Class->Name} = {state=>0} if ($super eq 'Class::Tangram');
			# create new inheritance
			#	      warn "creating inheritance from superclass : $super\n";
			my $Inheritance = Autodia::Diagram::Inheritance->new($Class, $Superclass);
			# add inheritance to superclass
			$Superclass->add_inheritance($Inheritance);
			# add inheritance to class
			$Class->add_inheritance($Inheritance);
			# add inheritance to diagram
			$Diagram->add_inheritance($Inheritance);
		    }
	    } else {
		warn "ignoring empty \@ISA line $line_no \n";
	    }
	}

      if ($self->{_modules}{Moose} && $line =~ m/extends (?:q|qw|qq)?\s*([\'\"\(\{\/\#])\s*([^\'\"\)\}\/\#]*)\s*(\1|[\)\}])?/ ) {
	  my $superclass = $2;
	  my @superclasses = split(/[\s*,]/, $superclass);

	  foreach my $super (@superclasses) # WHILE_SUPERCLASSES
	    {
		my $Superclass = Autodia::Diagram::Superclass->new($super);
		# add superclass to diagram
		$self->{_superclasses}{$Class->Name}{$super} = 1;
		my $exists_already = $Diagram->add_superclass($Superclass);
		#	  warn "already exists ? $exists_already \n";
		if (ref $exists_already) {
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

	# Handle Class::Tangram classes
	if (ref $self) {
	    if ($line =~ /^\s*(?:our|my)?\s+\$fields\s(.*)$/ and defined $self->{_is_tangram_class}{$Class->Name}) {
		$self->{_field_string} = '';
#		warn "tangram parser : found start of fields for ",$Class->Name,"\n";
		$self->{_field_string} = $1;
#		warn "field_string : $self->{_field_string}\n";
		$self->{_in_tangram_class} = 1;
		if ( $line =~ /^(.*\}\s*;)/) {
#		    warn "found end of fields for  ",$Class->Name,"\n";
		    $self->{_in_tangram_class} = 2;
		}
	    }
	    if ($self->{_in_tangram_class}) {

		if ( $line =~ /^(.*\}\s*;)/ && $self->{_in_tangram_class} == 1) {
#		    warn "found end of fields for  ",$Class->Name,"\n";
		    $self->{_field_string} .= $1;
		    $self->{_in_tangram_class} = 2;
		} else {
#		    warn "adding line to fields for  ",$Class->Name,"\n";
		    $self->{_field_string} .= $line unless ($self->{_in_tangram_class} == 2);
		}
		if ($self->{_in_tangram_class} == 2) {
#		    warn "processing fields for ",$Class->Name,"\n";
		    $_ = $self->{_field_string};
		    s/^\s*\=\s*\{\s//;
		    s/\}\s*;$//;
		    s/[\s\n]+/ /g;
#		    warn "fields : $_\n";
		    my %field_types = m/(\w+)\s*=>\s*[\{\[]\s*($pat1|$pat2|qw\([\w\s]+\))[\s,]*[\}\]]\s*,?\s*/g;

#		    warn Dumper(field_types=>%field_types);
		    foreach my $field_type (keys %field_types) {
#			warn "handling $field_type..\n";
			$_ = $field_types{$field_type};
			my $pat1 = '\'\w+\'\s*=>\s*\{.*?\}';
			my $pat2 = '\'\w+\'\s*=>\s*undef';
			my %fields;
			if (/qw\((.*)\)/) {
			    my $fields = $1;
#			    warn "qw fields : $fields\n";
			    my @fields = split(/\s+/,$fields);
			    @fields{@fields} = @fields;
			} else {
			    %fields = m/[\'\"]?(\w+)[\'\"]?\s*=>\s*([\{\[].*?[\}\]]|undef)/g;
			}
#			warn Dumper(fields=>%fields);
			foreach my $field (keys %fields) {
#			    warn "found field : '$field' of type '$field_type' in (class ",$Class->Name,") : \n";
			    my $attribute = { name=>$field, type=>$field_type, Id => $Diagram->_object_count, };
			    if ($fields{$field} =~ /class\s*=>\s*[\'\"](.*?)[\'\"]/) {
				$attribute->{type} = $1;
			    }
			    if ($fields{$field} =~ /init_default\s*=>\s*[\'\"](.*?)[\'\"]/) {
				$attribute->{default} = $1;
				# FIXME : attribute default values unsupported ?
			    }
			    $attribute->{visibility} = ( $attribute->{name} =~ m/^\_/ ) ? 1 : 0;

			    $Class->add_attribute($attribute);
			}

		    }
		    $self->{_in_tangram_class} = 0;
		}
	    }

	}

	# handle Class::DBI/Ima::DBI
	if ($line =~ /->columns\(\s*All\s*=>\s*(.*)$/) {
	  my $columns = $1;
	  my @cols;
	  if ($columns =~ s/^qw(.)//) {
	    $columns =~ s/\s*[\)\]\}\/\#\|]\s*\)\s*;\s*(#.*)?$//;
	    @cols = split(/\s+/,$columns);
	  } elsif ($columns =~ /'.+'/) {
	    @cols =  map( /'(.*)'/ ,split(/\s*,\s*/,$columns));
	  } else {
	    warn "can't parse CDBI style columns line $line_no\n";
	    next;
	  }

	  foreach my $col ( @cols ) {
	    # add attribute
	    my $visibility = ( $col =~ m/^\_/ ) ? 1 : 0;
	    $Class->add_attribute({
				   name => $col,
				   visibility => $visibility,
				   Id => $Diagram->_object_count,
				  });
	    # add accessor
	    $Class->add_operation({ name => $col, visibility => $visibility, Id => $Diagram->_object_count() } );
	  }

	  $continue->{cdbi_cols} = 1 unless $line =~ s/(.*)\)\s*;(#.*)?\s*$/$1/;
	  next;
	}

      # handle Class::Data::Inheritable
      #	  Stuff->mk_classdata(
      if ( $Class && $self->{_superclasses}{$Class->Name}{'Class::Data::Inheritable'} ) {
	  if ($line =~ /->mk_classdata\((\w+)/) {
	      my $attribute = $1;
	      my $visibility = ( $attribute =~ m/^\_/ ) ? 1 : 0;
	      $Class->add_attribute({
				     name => $attribute,
				     visibility => $visibility,
				     Id => $Diagram->_object_count,
				    });
	      # add accessor
	      $Class->add_operation({ name => $attribute, visibility => $visibility, Id => $Diagram->_object_count() } );
	  }
      }

      if ( $Class && $self->{_superclasses}{$Class->Name}{'Class::Accessor'} ) {
	# handle Class::Accessor
	if ($line =~ /->mk_accessors\s*\(\s*(.*)$/) {
	  my $attributes = $1;
	  my @attributes;
	  if ($attributes =~ s/^qw(.)//) {
	    $attributes =~ s/\s*[\)\]\}\/\#\|]\s*\)\s*;\s*(#.*)?$//;
	    @attributes = split(/\s+/,$attributes);
	  } elsif ($attributes =~ /'.+'/) {
	    @attributes =  map( /'(.*)'/ ,split(/\s*,\s*/,$attributes));
	  } else {
	    warn "can't parse CDBI style attributes line $line_no\n";
	    next;
	  }

	  foreach my $attribute ( @attributes ) {
	    # add attribute
	      next unless ($attribute =~ m/\w+/);
	    my $visibility = ( $attribute =~ m/^\_/ ) ? 1 : 0;
	    $Class->add_attribute({
				   name => $attribute,
				   visibility => $visibility,
				   Id => $Diagram->_object_count,
				  });
	      # add accessor if not already present
	      unless ($Class->get_operation($attribute)) {
		  $Class->add_operation({ name => $attribute, visibility => $visibility, Id => $Diagram->_object_count() } );
	      }
	  }

	  $continue->{class_accessor_attributes} = 1 unless $line =~ s/(.*)\)\s*;(#.*)?\s*$/$1/;
	  next;
	}
    }


      if ($continue->{class_accessor_attributes}) {
	  my @attributes;
	  $continue->{class_accessor_attributes} = 0 if $line =~ s/(.*)\)\s*;(#.*)?\s*$/$1/;
	  if ($line =~ /'.+'/) {
	      $line =~ s/\s*[\)\]\}\/\#\|]\s*$//;
	      @attributes =  map( /'(.*)'/ ,split(/\s*,\s*/,$line));
	  } else {
	      @attributes = split(/\s+/,$line);
	  }
	  foreach my $attribute ( @attributes ) {
	      next unless ($attribute =~ m/\w+/);
	      # add attribute
	      my $visibility = ( $attribute =~ m/^\_/ ) ? 1 : 0;
	      $Class->add_attribute({
				     name => $attribute,
				     visibility => $visibility,
				     Id => $Diagram->_object_count,
				    });

	      # add accessor if not already present
	      unless ($Class->get_operation($attribute)) {
		  $Class->add_operation({ name => $attribute, visibility => $visibility, Id => $Diagram->_object_count() } );
	      }
	  }
      }


      # handle Params::Validate
      if ($last_sub && $self->{_modules}{'Params::Validate'} && ( $line =~ m/validate(_pos)?\s*\(/ or $self->{_in_params_validate_arguments} )) {
	  my $found_end = 0;
#	  warn "found params::validate for sub $last_sub \n line : $line\n";
	  $self->{_in_params_validate_arguments} = 1;
	  $self->{_in_params_validate_positional_arguments} = 1 if $line =~ m/validate_pos/ ;
	  if ($line =~ m|\)\s*;|) {
	      $found_end = 1;
	      $line =~ s/\)\s*;.*//;
#	      warn "found end \n";
	  } 
	  $self->{_params_validate_arguments} .= $line;

	  if ($found_end) { 
	      my $validate_text = $self->{_params_validate_arguments};
#	      warn "found params::validate text : $validate_text\n";

	      # process with eval ala data::dumper
	      $validate_text =~ s/.*validate\w*\s*\(\s*\@_\s*,//;
#	      warn "evaluating params::validate text : $validate_text\n";
	      my $params = eval $validate_text;
#	      warn Dumper $params;
	      my $parameters = [];
	      push (@$parameters, { Name => "(HASHREF)" }) unless ( $self->{_in_params_validate_positional_arguments} );
	      foreach my $param_name (keys %$params) {
		  my $parameter = { Name => $param_name };
		  if (ref $params->{$param_name} && ( $params->{type} || $params->{isa} ) ) {
		      $parameter->{Type} = $params->{type} || $params->{isa};
		  }
		  push (@$parameters, $parameter);
	      }
	      if (scalar @$parameters) {
		  my $operation = $Class->get_operation($last_sub);
		  $operation->{Params} ||= [];
		  push (@{$operation->{Params}}, @$parameters);
		  $Class->update_operation($operation);
	      }
	      
	      delete $self->{_params_validate_arguments};
	      $self->{_in_params_validate_arguments} = 0;
	      $self->{_in_params_validate_positional_arguments} = 0;
	  }
      }

      
      # handle DBIx::Class
      if ($self->{_dbix_class_columns}) {
	my $found_end = 0;
	$line =~ s/#.*$//;
	if ($line =~ m|\);|) {
	  $found_end = 1;
	  $line =~ s/\);.*//;
	}
	$self->{_dbix_class_columns} .= $line;
	if ($found_end) { 
	  my $columns_text = $self->{_dbix_class_columns} . '}';
#	  warn "class : , ", $Class->Name, "\n";
#	  warn "columns text : $columns_text \n";
	  # process with eval ala data::dumper
	  my $columns = eval $columns_text;
#	  warn Dumper $columns;
	  foreach my $attr_name (keys %$columns) {
	    $Class->add_attribute({
				   name => $attr_name,
				   visibility => 0,
				   Id => $Diagram->_object_count,
				   type => $columns->{$attr_name}{data_type},
				  });
	  }

	  delete $self->{_dbix_class_columns};
	  $self->{_dbix_class} = 0;
	}

      }

      # if line is DBIx::Class relationship then parse out
      if ($self->{_dbix_class_relation} or $line =~ /\-\>has_(many|one)\s*\((.*)/ or $line =~ /\-\>(belongs_to)\s*\((.*)/) {
	  my $found_end = 0;
	  $line =~ s/#.*$//;
	  if ($line =~ m|\);|) {
	      $found_end = 1;
	      $line =~ s/\);.*//;
	  }

	  if ($line =~ /\-\>has_(many|one)\s*\((.*)/ or $line =~ /\-\>(belongs_to)\s*\((.*)/) {
	      my ($rel_type, $rel_data) = ($1,$2);
	      $rel_data =~ s/#.*$//;
	      $self->{_dbix_class_relation}{rel_data} = "{ $rel_data ";
	      $self->{_dbix_class_relation}{rel_type} = $rel_type;
	  } else {
	      $self->{_dbix_class_relation}{rel_data} .= $line;
	  }

	  if ($found_end) {
	      my $reldata = $self->{_dbix_class_relation}{rel_data} . '}';
	      my ($rel_name,$related_classname) = split(/\s*(?:\=\>|,)\s*/,$reldata);
	      $related_classname =~ s/['"]//g;
	      $rel_name =~ s/^\W+//;
	      $rel_name =~ s/['"]//g;

	      unless ($related_classname) {
		  warn "no related class in relation data : $reldata\n";
		  next;
	      }

#	      warn "creating relation : $rel_name to $related_classname\n";

	      my $Superclass = Autodia::Diagram::Superclass->new($related_classname);
	      my $exists_already = $self->{Diagram}->add_superclass($Superclass);
	      $Superclass = $exists_already if (ref $exists_already);

	      # create new relationship
	      my $Relationship = Autodia::Diagram::Relation->new($Class, $Superclass);
	      # add Relationship to superclass
	      $Superclass->add_relation($Relationship);
	      # add Relationship to class
	      $Class->add_relation($Relationship);
	      # add Relationship to diagram
	      $self->{Diagram}->add_relation($Relationship);
	      $Class->add_operation({ name => $rel_name, visibility => 0, Id => $Diagram->_object_count() } );

	  }
	  delete $self->{_dbix_class_relation};
      }

      # if line is DBIx::Class column metadata then parse out
      if ($self->{_dbix_class} && $line =~ m/add_columns\s*\((.*)/) {
	my $field_data = $1;
	$field_data =~ s/#.*$//;
	$self->{_dbix_class_columns} = "{ $field_data ";
      }

      # if line is DBIx::Class component, then treat as superclass
      if ($line =~ m/->load_components\s*\(\s*(?:q|qw|qq)?\s*([\'\"\(\{\/\#])\s*([^\'\"\)\}\/\#]*)\s*(\1|[\)\}])?/ ) {
	my $component_string = $2;
	foreach my $component_name (grep (/^\+/ , split(/[\s,]+/, $component_string ))) {
	    $component_name =~ s/['"+]//g;
	    my $Superclass = Autodia::Diagram::Superclass->new($component_name);
	    my $exists_already = $self->{Diagram}->add_superclass($Superclass);
	    $Superclass = $exists_already if (ref $exists_already);
	    # create new inheritance
	    my $Inheritance = Autodia::Diagram::Inheritance->new($Class, $Superclass);
	    $Superclass->add_inheritance($Inheritance);
	    # add inheritance to class
	    $Class->add_inheritance($Inheritance);
	    # add inheritance to diagram
	    $self->{Diagram}->add_inheritance($Inheritance);
	}
      }


      # add Moose attributes
      if ($self->{_modules}{Moose} && $line =~ /^\s*has\s+'?(\w+)'?/) {
	  my $attr_name = $1;
	  $Class->add_attribute({
				 name => $attr_name,
				 visibility => 0,
				 Id => $Diagram->_object_count,
				});
      }


      if ( $self->{_class_xsaccessor} ) {

      }

      # if line is Object::InsideOut metadata then parse out
      if ($self->{_insideout_class} && $line =~ /^\s*my\s+\@\w+\s+\:FIELD\s*\((.*)\)/) {
	my $field_data = $1;
	$field_data =~ s/['"\s]//g;
	my %field_data = split( /\s*(?:=>|,)\s*/, $field_data);
	(my $col = $field_data{Get} ) =~ s/get_//;
	$Class->add_attribute({
			       name => $col,
			       visibility => 0,
			       Id => $Diagram->_object_count,
				});
	foreach my $key ( keys %field_data ) {
	  # add accessor/mutator
	  if ($key =~ m/(Get|Set|Acc|Mut|Com)/) {
	    $Class->add_operation({ name => $field_data{$key}, visibility => 0, Id => $Diagram->_object_count() } );
	  }
	}

      }

	# if line contains sub then parse for method data
	if ($line =~ /^\s*sub\s+?(\w+)/) {
	    my $subname = $1;

	    # check package exists before doing stuff
	    $self->_is_package(\$Class, $filename);

	    $subname =~ s/^(.*?)['"]\..*$/${1}_xxxx/;

	    $last_sub = $subname;

	    my %subroutine = ( "name" => $subname, );
	    $subroutine{"visibility"} = ($subroutine{"name"} =~ m/^\_/) ? 1 : 0;
	    $subroutine{"Id"} = $Diagram->_object_count();
	    # NOTE : perl doesn't provide named parameters
	    # if we wanted to be clever we could count the parameters
	    # see Autodia::Handler::PHP for an example of parameter handling

	    unless ($Class->get_operation($subname)) {
		$Class->add_operation(\%subroutine);
	    }

	}

	# if line contains object attributes parse add to class
	if ($line =~ m/\$(class|self|this)\-\>\{['"]*(.*?)["']*}/) {
	    my $attribute_name = $2;
	    $attribute_name =~ s/^(.*?)['"]\..*$/${1}_xxxx/;
	    $attribute_name =~ s/['"\}\{\]\[]//g; # remove nasty badness
	    my $attribute_visibility = ( $attribute_name =~ m/^\_/ ) ? 1 : 0;

	    $Class->add_attribute({
				   name => $attribute_name,
				   visibility => $attribute_visibility,
				   Id => $Diagram->_object_count,
				  }) unless ($attribute_name =~ /^\$/);
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

	if ($line =~ /^\s*\#/) # if line is a comment discard
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


###############################################################################

=head1 SEE ALSO

Autodia::Handler

Autodia::Diagram

=head1 AUTHOR

Aaron Trevena, E<lt>aaron.trevena@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001-2007 by Aaron Trevena

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;





