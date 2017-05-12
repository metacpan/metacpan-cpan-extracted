package Class::PINT::DataTypes;

=head1 NAME

Class::PINT::DataTypes - Specifying Accessors for complex Class::PINT attributes

=head1 DESCRIPTION

This package provides accessors and mutators for Class::PINT attributes with compound or complex datatypes.

It provides the built-in datatypes of array, hash and boolean. It also allows you to add additional datatypes and methods.

=head1 SYNOPSIS

# Class

package Nautical::Course;

use base qw(Class::PINT);

__PACKAGE__->add_datatype('coordinate',{ get=>\sub { .. } }, .. );

# ...

__PACKAGE__->column_types(coordinate => qw/Point Position Destination/);

=cut

use strict;

use URI::Escape;
use Class::PINT::DataTypes::Bitmask;
use Data::Dumper;

use base qw(Class::Data::Inheritable);

my %default_methods = (
		       write => \sub { return $_[1]; },
		       read => \sub { return $_[1]; },
		       get => \sub {
				    my ($self,$column,@args) = @_;
				    die "read-only get accessor called on $column with new value(s)\n" if (@args);
				    return $self->{$column};
				   },
		       set => \sub {
				    my ($self,$column,@args) = @_;
				    die "write-only set mutator called on $column without new value(s)\n" unless (@args);
				    $self->{$column} = $args[0];
				    return;
				   },
		       getset => \sub {
				       my ($self,$column,@args) = @_;
				       if (@args) {
					   $self->{$column} = $args[0];
				       }
				       return $self->{$column};
				      },
		      );


# complex type/attributes
__PACKAGE__->mk_classdata("_complex_attributes");
__PACKAGE__->_complex_attributes({});
__PACKAGE__->mk_classdata("_complex_types");
__PACKAGE__->_complex_types(
			    {
			     ##############################################################
			     # array accessors

			     array => {
					read =>  sub {
					    my ($column,$value) = @_;
#					    warn "read called with column $column and value $value\n";
					    return [] unless (defined $value);
					    my $unencoded = [ map { uri_unescape($_) } split(/,/,$value) ];
					    return $unencoded;
					},
					write => sub {
#					    warn "write called \n";
						       my ($column,$value) = @_;
						       unless( ref $value)  {
							   return ( defined $value ) ? uri_escape($value) : '';
						       }
						       my $encoded = join(',',map { uri_escape($_) } @$value );
						       return $encoded;
						      },
					set => \sub {
#						     warn "set called\n";
						     my ($self,$column,@args) = @_;
						     my $newvalue = $self->{$column} || [];
						     if (scalar @args == 2) {
							 if ($args[0] > $#{$newvalue}) {
							     warn "WARNING : setting element ($args[0]) after current end of array (".
								 $#{$newvalue}.") did you mean to do that?\n";
							 }
							 $newvalue->[$args[0]] = $args[1];
						     } elsif (scalar @args == 1 and ref $args[0]) {
							 $newvalue = $args[0];
						     } else {
							 die "ambiguous set of array attribute $column called with ", join(',',@args), "\n";
						     }
						     $self->{$column} = $newvalue;
						     $self->_set_complex_attribute($column);
						     return $newvalue;
						    },
					get => \sub {
#						     warn "get called\n";
						     my ($self,$column,$index) = @_;
						     my $return = (defined $index) ? $self->{$column}[$index] : $self->{$column} ;
						     return (wantarray && ref $return) ? @$return : $return;
						    },
					getset => \sub {
#							warn "getset called \n";
							my ($self,$column,@args) = @_;
							my $newvalue = $self->{$column};
							unless (@args) {
							    return (wantarray) ? @$newvalue : $newvalue;
							}
							if (scalar @args == 2) {
							    if ($args[0] > $#{$self->{$column}}) {
								warn "WARNING : setting element ($args[0]) after current end of array (".
								    $#{$self->{$column}}.") did you mean to do that?\n";
							    }
							    $self->{lc $column}[$args[0]] = $args[1];
							    $self->_set_complex_attribute($column);
							} elsif (scalar @args == 1) {
							    if (ref $args[0]) {
								$self->{$column} = $args[0];
								$self->_set_complex_attribute($column);
								return $self->{$column};
							    } else {
								return $self->{$column}[$args[0]];
							    }
							} else  {
							    die "ambiguous set of array attribute $column called with ", join(',',@args), "\n";
							}
						       },

					insert => \sub {
							my ($self,$column,$position,$value,@args) = @_;
							my $newvalue = $self->{$column};
							my $end = $#$newvalue;
							my @array = @$newvalue;
							unless ($end) {
							    die "can't insert into an empty array, use set instead\n";
							}
							if (ref $value) {
							    my $size = $#$value;
							    @array[$position+$size .. $end+$size] = @array[$position .. $end];
							    @array[$position..$position+$size] = @$value;
							} else {
							    @array[$position+1 .. $end+1] = @array[$position .. $end];
							    $array[$position] = $value;
							}
							$self->{$column} = \@array;
							$self->_set_complex_attribute($column);
							return (wantarray) ? @array : \@array ;
						       },
					delete => \sub {
							my ($self,$column,$position,@args) = @_;
							my $newvalue = $self->{$column};
							my $end = $#$newvalue;
							my @array = @$newvalue;
							unless ($end) {
							    die "can't delete from an empty array, use set instead\n";
							}
							if (ref $position) {
							    foreach my $thispos (sort {$b <=> $a} @$position) {
								@array[$thispos .. $end -1] = @array[$thispos + 1 .. $end];
								$end--;
							    }
							    @array = @array[0..$end];
							} else {
							    @array = @array[0 .. $position -1, $position + 1 .. $end];
							}
							$self->{$column} = \@array;
							$self->_set_complex_attribute($column);
							return (wantarray) ? @array : \@array ;
						       },
					push => \sub {
						      my ($self,$column,@args) = @_;
						      my $newvalue = $self->{$column} || [];
						      foreach (@args) {
							  push (@$newvalue, ref($_) ? @$_ : $_ );
						      }
						      $self->{$column} = $newvalue;
						      $self->_set_complex_attribute($column);
						      return $newvalue;
						     },
					pop => \sub {
						     my ($self,$column,@args) = @_;
						     my $newvalue = $self->{$column} || [];
						     if (@args) {
							 my @popped;
							 foreach ($args[0] .. $#args) {
							     push(@popped,pop(@$newvalue));
							 }
							 $self->{$column} = $newvalue;
							 $self->_set_complex_attribute($column);
							 return (wantarray) ? @popped: \@popped;
						     } else {
							 my $popped = pop(@$newvalue);
							 $self->{$column} = $newvalue;
							 $self->_set_complex_attribute($column);
							 return $popped;
						     }
						    },
				       },

			      ##############################################################
			      # hash accessors

			      hash => {
				       read =>  sub {
						      my ($column,$value) = @_;
						      return {} unless (defined $value);
						      my $unencoded = { map { uri_unescape($_) } split(/,/,$value) };
						      return $unencoded;
						     },
				       write => sub {
						      my ($column,$value) = @_;
						      unless( ref $value)  {
							  return ( defined $value ) ? uri_escape($value) : '';
						      }
						      my $encoded = join(',',map { uri_escape($_) } (%$value) );
						      return $encoded;
						     },

					set => \sub {
						     my ($self,$column,@args) = @_;
						     die "write only set method for hash attribute $column called without value\n" unless (@args);
						     my $newvalue = $self->{$column} || {};
						     if (scalar @args > 1 and (!scalar @args % 2)) {
							 my %args = @args;
							 @{$self->{lc $column}}{keys %args} = @args{keys %args};
						     } elsif (ref $args[0] eq 'HASH') {
							 $newvalue->{$args[0]} = $args[1];
						     } elsif (scalar @args == 1 and ref $args[0]) {
							 $newvalue = $args[0];
						     } else {
							 die "ambiguous set of array attribute $column called with ", join(',',@args), "\n";
						     }
						     $self->{$column} = $newvalue;
						     $self->_set_complex_attribute($column);
						     return $newvalue;
						    },
				       get => \sub {
						    my ($self, $column, @index) = @_;
						    if (@index > 1) {
							my %hashslice = map {
							    $_ => $self->{$column}{$_}
							} grep (exists $self->{$column}{$_},@index);
							return (wantarray) ? %hashslice : \%hashslice;
						    } elsif (defined $index[0]) {
							return $self->{$column}{$index[0]};
						    } else {
							return (wantarray) ? %{$self->{$column}} : $self->{$column};
						    }
						    },
				       getset => \sub {
						       my ($self,$column,@args) = @_;
						       my $newvalue = $self->{$column};
						       unless (@args) {
							   return (wantarray) ? %$newvalue : $newvalue;
						       }
						       if (scalar @args > 1 and (!scalar @args % 2)) {
							   my %args = @args;
							   @{$self->{lc $column}}{keys %args} = @args{keys %args};
							   $self->_set_complex_attribute($column);
						       } elsif (scalar @args == 1) {
							   if (ref $args[0] eq 'HASH') {
							       $self->{$column} = $args[0];
							       $self->_set_complex_attribute($column);
							       return $self->{$column};
							   } elsif ( ! ref $args[0] )  {
							       return $self->{$column}{$args[0]};
							   }
						       } else  {
							   die "ambiguous getset for hash attribute $column, called with ",
							       join(',',@args), "\n";
						       }
						      },
				       insert => 'set', # alias insert to set
				       delete => \sub {
						       my ($self,$column,@args) = @_;
						       my $newvalue = $self->{$column} || {};
						       unless (@args) {
							   warn "delete method for hash attribute $column called without value, deleting everything\n";
							   $self->{$column} = {};
							   $self->_set_complex_attribute($column);
							   return;
						       }
						       foreach my $arg (@args) {
							   if (ref $arg) {
							       foreach (@$arg) {
								   delete $self->{$column}{$_};
							       }
							   } else {
							       delete $self->{$column}{$arg};
							   }
						       }
						       $self->_set_complex_attribute($column);
						       return;
						      },
				       Attribute_contains => \sub {
								   my ($self,$column,@args) = @_;
								   return defined $self->{$column}{$args[0]};
								  },
				       Attribute_keys => \sub {
							       my ($self,$column,@args) = @_;
							       return keys %{$self->{$column}};
							      },
				       Attribute_values => \sub {
								 my ($self,$column,@args) = @_;
								 return values %{$self->{$column}};
								},
				       validate => \sub { return 1; },
 				      },

			     ######################################################
			     # boolean accessors

			     boolean => {
					 write => sub { return $_[1]; },
					 read => sub { return $_[1]; },
					 get => \sub {
						      my ($self,$column,@args) = @_;
						      return $self->{$column};
						     },
					 set => \sub {
						      my ($self,$column,@args) = @_;
						      if (defined $args[0]) {
							  unless ($args[0] =~ m|^[10]$|) {
							      die "attribute ($column) is boolean and was passed $args[0]";
							  }
							  $self->{$column} = $args[0];
						      } else {
							  die "write-only method called on $column attribute\n";
						      }
						      $self->_set_complex_attribute($column);
						      return $self->{$column};
						     },
					 getset => \sub {
							 my ($self,$column,@args) = @_;
							 if (defined $args[0]) {
							     unless ($args[0] =~ m|[10]|) {
								 die "attribute ($column) is boolean and was passed $args[0]";
							     }
							     $self->{$column} = $args[0];
							     $self->_set_complex_attribute($column);
							 }
							 return $self->{$column};
							},
					 is => \sub {
						     my ($self,$column,@args) = @_;
						     return (defined $self->{$column} and $self->{$column} == 1 ) ? 1 : 0;
						    },
					 Attribute_is_true => 'is',
					 Attribute_is_false => \sub {
								     my ($self,$column) = @_;
								     return (defined $self->{$column} and $self->{$column} == 0) ? 1 : 0;
								    },
					 Attribute_is_defined => \sub {
								       my ($self,$column) = @_;
								       return defined $self->{$column};
								      },
					},

			     ######################################################
			     # bitmask accessors

			      bitmask => {
					  read => sub {
					      my ($column,$value) = @_;
					      return [] unless (defined $value);
					      my $bits = [split(//,_dec2bin($value,32))];
					      return $bits;
					  },

					  write => sub {
					      my ($column,$value) = @_;
					      return 0 unless (defined $value);
					      my $num = _list2dec($value);
					      return $num;
					  },

					  get => \sub {
						       my ($self,$column,$index) = @_;
						       my $return = (defined $index) ? $self->{$column}[$index] : $self->{$column} ;
						       return (wantarray && ref $return) ? @$return : $return;
						      },

					  set => \sub {
						       my ($self,$column,@args) = @_;
						       die "set_$column is write only and no value has been provided" unless (@args);
						       if (@args > 1) {
							   @{$self->{$column}}[@args] = split(//, 1 x @args);
						       } else {
							   if (ref $args[0]) {
							       my @indexes = @{$args[0]};
							       @{$self->{$column}}[@indexes] = split(//, 1 x @indexes);
							   } else {
							       $self->{$column}[$args[0]] = 1;
							   }
						       }
						       $self->_set_complex_attribute($column);
						       return;
						      },
					  getdec => \sub {
							  my ($self,$column) = @_;
							  return _list2dec($self->{$column});
							 },
					  getbin => \sub {
							  my ($self,$column) = @_;
							  return _list2bin($self->{$column});
							 },
					  setbin => \sub {
							  my ($self,$column,$value) = @_;
							  $self->{$column} = [split(//,$value)];
							  $self->_set_complex_attribute($column);
							  return;
							 },

					  setdec => \sub {
							  my ($self,$column,$value) = @_;
							  $self->{$column} = [split(//,_dec2bin($value,32))];
							  $self->_set_complex_attribute($column);
							  return;
							 },

					  getset => \sub {
							  my ($self,$column,@args) = @_;
							  # if provided with hashref then set, else get
							  if (@args) {
							      if (@args > 1) {
								  @{$self->{$column}}[@args] = split(//, 1 x @args);
							      } else {
								  if (ref $args[0]) {
								      my @indexes = @{$args[0]};
								      @{$self->{$column}}[@indexes] = split(//, 1 x @indexes);
								  } else {
								      $self->{$column}[$args[0]] = 1;
								  }
							      }
							      $self->_set_complex_attribute($column);
							      return;
							  } else {
							      return (wantarray) ? @{$self->{$column}} : $self->{$column};
							  }
							 },

					  Attribute_includes => \sub {
								      my ($self,$column,@args) = @_;
								      die "${column}_includes requires an argument\n";
								      my $compare_num;
								      if (ref $args[1]) {
									  $compare_num = _list2dec(@{$args[1]});
								      } else {
									  $compare_num = _list2dec($args[1]);
								      }
								      return ( $compare_num & _list2dec($self->{$column})) ? 1 : 0 ;
								     },

					  Attribute_excludes => \sub {
								      # FIXME: breaks DRY
								      # refactor to re-use code and not
								      # have to re-run _list2dec as often
								      my ($self,$column,@args) = @_;
								      die "${column}_includes requires an argument\n";
								      my $compare_num;
								      if (ref $args[1]) {
									  $compare_num = _list2dec(@{$args[1]});
								      } else {
									  $compare_num = _list2dec($args[1]);
								      }
								      return ( $compare_num & _list2dec($self->{$column})) ? 0 : 1 ;
								     },
					 },

			     ######################################################
			     # ref accessors
			     #  ... todo ...
			    },
			   );


=head1 CLASS METHODS

=head2 add_datatype

add_datatype is a class method that allows you to add a new datatype for attributes.

__PACKAGE__->add_datatype('coordinate',{ get=>\sub { .. } }, .. );

default actions are :

write => \sub { return $_[1]; },

read => \sub { return $_[1]; },

get => \sub {

 	     my ($self,$column,@args) = @_;

  	     die "read-only get accessor called on $column with new value(s)\n" if (@args);

	     return $self->{$column};

	    },

set => \sub {

            my ($self,$column,@args) = @_;

	    die "write-only set mutator called on $column without new value(s)\n" unless (@args);

	    $self->{$column} = $args[0];

	    return;

	    },

getset => \sub {

		my ($self,$column,@args) = @_;

		if (@args) {

		    $self->{$column} = $args[0];

		}

		return $self->{$column};

	       },

The read/write subs munge the attributes value on the way in/out of the database.

The set method is a write-only mutator that sets the attributes internal value.

The get method is a read-only accessor that gets the attributes value.

The getset method is an impure accessor that gets/sets the attributes value depending on how it is called.

The get,set and getset methods can get/set values that make up a compound attribute  such as a list or dictionary.

Additional actions can be added but read,write,get,set and getset are required, and defaults are provided - see the example below.

You can use an alias instead of a subref except for read,write and getset which  must be specified, this is done by setting the value of the action key to the  action it is an alias of, for example : another_name_for_get => 'get'.

You can specify the full name of a method as long as you include 'Attribute_' in the name, which will be replaced by the name of the Attribute, otherwise all methods are named as action_Attribute, i.e. get_Foo.

The read and write subs take 2 arguments : the column and then the value.

All other subs take at least 3 arguments: a reference to the class or object, the column and then any values

Any mutator sub should call _set_complex_attribute once it has made its changes, and only if it has made changes ( as doing so, may incur a database update, and refetching values from the database). See below for more details

=cut

sub add_datatype {
    my ($class,$datatype,$actions) = @_;
    my $types = __PACKAGE__->_complex_types();
    $types->{$datatype} = $actions;

    foreach my $default_action ( keys %default_methods ) {
	$types->{$datatype}{$default_action} = $default_methods{$default_action};
    }
    __PACKAGE__->_complex_types($types);
    return;
}

=head1 OBJECT METHODS

=head2 _set_complex_attribute

_set_complex_attribute ensures that persistance works for an attribute as PINT bypasses parts of Class::DBI's persistance code. Calling this function ensures that everything works as users and developers expects. It calls triggers, updates CDBI internal information, and ensures the database is kept up to date. See Class::DBI documentation for update and autoupdate for more details on how CDBI manages persistence.

This method takes the name of the column as its only argument :

$self->_set_complex_attribute($column);

This method is seen as an internal or private method and is only required when adding your own datatypes and their accessors, hence the underscore at the start of the name.

=cut

sub _set_complex_attribute {
    my ($self,$column) = @_;
    # handle trigger, inflate, etc
    eval { $self->call_trigger("after_set_$column") };
    if ($@) {
	    $self->_attribute_delete($column);
	    return $self->_croak("after_set_$column trigger error: $@", err => $@);
	}

    # flag for update
    $self->{__Changed}{$column}++;

    $self->update if $self->autoupdate;
    return 1;
}

################################################################################

=head1 SEE ALSO

L<perl>

Class::PINT

Class::DBI

Class::Tangram

=head1 AUTHOR

Aaron J. Trevena, E<lt>aaron@droogs.orgE<gt>

=head1 COPYRIGHT

Licensed for use, modification and distribution under the Artistic
and GNU GPL licenses.

Copyright (C) 2004 by Aaron J Trevena <aaron@droogs.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut


################################################################################
################################################################################

1;
