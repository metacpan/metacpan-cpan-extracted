package Class::DBI::Relationship::IsA;

=head1 NAME

Class::DBI::Relationship::IsA - A Class::DBI module for 'Is A' relationships

=head1 DESCRIPTION

Class::DBI::Relationship::IsA Provides an Is A relationship between Class::DBI classes/tables.

By using this module you can emulate some features of inheritance both within your database and classes through the Class::DBI API.

NOTE: This module is still experimental, several very nasty bugs have been found (and fixed) others may still be lurking - see CAVEATS AND BUGS below.

Warning Will Robinson!

=head1 SYNOPSIS

In your database (assuming mysql):

 create table person (
   personid int primary key auto_increment,
   firstname varchar(32),
   initials varchar(16),
   surname varchar(64),
   date_of_birth datetime
 );

 create table artist (
   artistid int primary key auto_increment,
   alias varchar(128),
   person int
 );


In your classes:

 package Music::DBI;
 use base 'Class::DBI';

 Music::DBI->connection('dbi:mysql:dbname', 'username', 'password');
 __PACKAGE__->add_relationship_type(is_a => 'Class::DBI::Relationship::IsA');

Superclass:

 package Music::Person;
 use base 'Music::DBI';

 Music::Person->table('person');
 Music::Person->columns(All => qw/personid firstname initials surname date_of_birth/);
 Music::Person->columns(Primary => qw/personid/); # Good practice, less likely to break IsA

Child class:

 package Music::Artist;
 use base 'Music::DBI';
 use Music::Person; # required for access to Music::Person methods

 Music::Artist->table('artist');
 Music::Artist->columns(All => qw/artistid alias/);
 Music::Person->columns(Primary => qw/personid/); # Good practice, less likely to break IsA
 Music::Artist->has_many(cds => 'Music::CD');
 Music::Artist->is_a(person => 'Person'); # Music::Artist inherits accessors from Music::Person

... elsewhere ...

 use Music::Artist;
 my $artist = Music::Artist->create( {firstname=>'Sarah', surname=>'Geller', alias=>'Buffy'});
 $artist->initials('M');
 $artist->update();

=cut

use strict;
our $VERSION = '0.05';

use warnings;
use base qw( Class::DBI::Relationship );
use Class::DBI::AbstractSearch;

use Data::Dumper;

sub remap_arguments {
    my $proto = shift;
    my $class = shift;
    $class->_invalid_object_method('is_a()') if ref $class;
    my $column = $class->find_column(shift)
	or return $class->_croak("is_a needs a valid column");
    my $f_class = shift
	or $class->_croak("$class $column needs an associated class");
    my %meths = @_;
    my @f_cols;
    foreach my $f_col ($f_class->all_columns) {
	push @f_cols, $f_col
	    unless $f_col eq $f_class->primary_column;
    }
    $class->__grouper->add_group(TEMP => map { $_->name } @f_cols);
    $class->__grouper->add_group(__INHERITED => map { $_->name } @f_cols);
    $class->mk_classdata('__isa_rels');
    $class->__isa_rels({ });
    return ($class, $column, $f_class, \%meths);
}

sub triggers {
    my $self = shift;
    $self->class->_require_class($self->foreign_class);
    my $column = $self->accessor;
    return (
	    select        => $self->_inflator,
	    before_create => $self->_creator,
            before_update => sub {
                if (my $f_obj = $_[0]->$column()) { $f_obj->update }
            },

    );
}

sub methods {
    my $self = shift;
    $self->class->_require_class($self->foreign_class);

    my $foreign_class = $self->foreign_class;
    my $class = $self->class;
    warn "foreign class : $foreign_class\n";

    warn "getting relationships..\n";


    my $parent_relation_fields = $self->_inject_inherited_relationships(class=>$class, foreign=>$foreign_class);

    my $forbidden_fields = "(id|${class}_?u?id";
    $forbidden_fields .= ($foreign_class->columns('Primary')) ? '|' . $foreign_class->columns('Primary') .')' : ')' ;
    warn "forbidden_fields : $forbidden_fields\n";

    my %methods;
    my $acc_name = $self->accessor->name;
    foreach my $f_col ($self->foreign_class->all_columns) {
        warn "f_col : $f_col, acc_name : $acc_name\n";
        next if ($f_col eq $acc_name or $f_col =~ /$forbidden_fields/i or $parent_relation_fields->{$f_col});
	if ($class->can('pure_accessor_name')) {
	    # provide seperate read/write accessor, read only accessor and write only mutator
	    $methods{ucfirst($class->pure_accessor_name($f_col))}
		= $methods{$class->pure_accessor_name($f_col)} = $self->_get_methods($acc_name, $f_col,'ro');
	    $methods{ucfirst($class->mutator_name($f_col))}
		= $methods{$class->mutator_name($f_col)} = $self->_get_methods($acc_name, $f_col,'wo');
	    $methods{ucfirst($class->accessor_name($f_col))}
		= $methods{$class->accessor_name($f_col)} = $self->_get_methods($acc_name, $f_col,'rw');
	} else {
	    if ( $class->mutator_name($f_col) eq $class->accessor_name($f_col) ) {
		# provide read/write accessor
		$methods{ucfirst($class->accessor_name($f_col))}
		    = $methods{$class->accessor_name($f_col)} = $self->_get_methods($acc_name, $f_col,'rw');
	    } else {
		# provide seperate read only accessor and write only mutator
		$methods{ucfirst($class->accessor_name($f_col))}
		    = $methods{$class->accessor_name($f_col)} = $self->_get_methods($acc_name, $f_col,'ro');
		$methods{ucfirst($class->mutator_name($f_col))}
		    = $methods{$class->mutator_name($f_col)} = $self->_get_methods($acc_name, $f_col,'wo');
	    }
	}
    }

    $methods{search_where} = $self->search_where if $self->class->can('search_where');

    return(
	   %methods,
	   search      => $self->search,
	   search_like => $self->search_like,
	   all_columns => $self->all_columns,
	  );
}

sub search {
    my $self = shift;
    my $SUPER = $self->foreign_class;
    my $col = $self->accessor;
    {
	no strict "refs";
	*{$self->class."::orig_search"} = \&{"Class::DBI::search"};
    }
    return sub {
        my ($self, %args) = (@_);
        my (%child, %parent);
        foreach my $key (keys %args) {
            $child{$key} = $args{$key} if $self->has_real_column($key);
            $parent{$key} = $args{$key} if $SUPER->has_real_column($key);
        }
        if(%parent) {
            return map { $self->orig_search($col => $_->id, %child)
			 } $SUPER->search(%parent);
	} else {
	    return $self->orig_search(%child);
	}
    };
}

sub search_like {
    my $self = shift;
    my $SUPER = $self->foreign_class;
    my $col = $self->accessor;
    {
	no strict "refs";
	*{$self->class."::orig_search_like"} = \&{"Class::DBI::search_like"};
    }
    return sub {
        my ($self, %args) = (@_);
        my (%child, %parent);
        foreach my $key (keys %args) {
            $child{$key} = $args{$key} if $self->has_real_column($key);
            $parent{$key} = $args{$key} if $SUPER->has_real_column($key);
        }
        if(%parent) {
            return map { $self->orig_search_like($col => $_->id, %child)
                       } $SUPER->search_like(%parent);
        } else {
            return $self->orig_search_like(%child);
        }
    };
}

sub search_where {
    my $self = shift;
    my $SUPER = $self->foreign_class;
    my $col = $self->accessor;
    {
        no strict "refs";
        *{$self->class."::orig_search_where"} = \&{"Class::DBI::AbstractSearch::search_where"};
    }

    return sub {
        my ($self, %args) = (@_);
        my (%child, %parent);
        foreach my $key (keys %args) {
            $child{$key} = $args{$key} if $self->has_real_column($key);
            $parent{$key} = $args{$key} if $SUPER->has_real_column($key);
        }
        if(%parent) {
            return map { $self->orig_search_where($col->name => $_->id, %child)
			 } $SUPER->search_where(%parent);
        } else {
            return $self->orig_search_where(%child);
        }
    };
}

sub all_columns {
    my $self = shift;
    my $SUPER = $self->foreign_class;
    my $col = $self->accessor;
    {
	no strict "refs";
	*{$self->class."::orig_all_columns"} = \&{"Class::DBI::all_columns"};
    }
    return sub {
	my $self = shift;
	return ($self->orig_all_columns, $self->columns('TEMP'));
    };
}


################################################################################

sub _inject_inherited_relationships {
  my ($self,%params) = @_;
  my $class = $params{class};
  my $foreign_class = $params{foreign};
  my $fields = {};

  my %current_relationships = ();

  if ($class->can('meta_info')) {
    warn "class has meta_info ";
    # warn Dumper($class->meta_info);
    my $meta_info = $class->meta_info;
    foreach my $relation_type ( keys %$meta_info ) {
      next if ($relation_type eq 'is_a');
      foreach my $relname (keys %{$meta_info->{$relation_type}}) {
	$current_relationships{$relname} = 1;
      }
    }
  }

  if ($foreign_class->can('meta_info')) {
    warn "foreign class has meta_info ";
    # warn Dumper($class->meta_info);
    my $meta_info = $foreign_class->meta_info;
    foreach my $relation_type ( keys %$meta_info ) {
      next if ($relation_type eq 'is_a');
      foreach my $relname (keys %{$meta_info->{$relation_type}}) {
	warn "adding new relationship : $relname \n";
	$fields->{$relname} = 1;
	$self->_inject_inherited_method($class, $relname);
      }
    }
  }
  return $fields;
}

sub _inject_inherited_method {
  my ($self,$class,$accessor_name) = @_;
  my $parent_accessor = $self->accessor;
  my $method = sub {
    warn "injected method $accessor_name , calling $accessor_name on parent via $parent_accessor \n";
    warn "..called with args ", join(', ',@_), "\n";
    my ($self, @args) = @_;
    $self->$parent_accessor->$accessor_name(@args);
  };
  {
    no strict "refs";
    *{"${class}::${accessor_name}"} = $method;
  }
}

sub _creator {
    my $proto = shift;
    my $col = $proto->accessor;

    return sub {
	my $self = shift;
	my $meta = $self->meta_info(is_a => $col);
	my $f_class = $meta->foreign_class;

	my $hash = { };

	foreach ($self->__grouper->group_cols('TEMP')) {
	    next unless defined($self->_attrs($_));
	    $hash->{$_} = $self->_attrs($_);
	}
	my $f_pk = $f_class->primary_column;
	if ($self->_attrs($f_pk)) {
	  $hash->{$f_pk} = $self->_attrs($f_pk);
	}

	my $f_obj = $f_class->create($hash);
	$proto->_import_column_values($self, $f_class, $f_obj);

	return $self->_attribute_store($col => $f_obj->id);
    };
}

sub _inflator {
    my $proto = shift;
    my $col = $proto->accessor;

    return sub {
	my $self = shift;
	my $value = $self->$col;
	my $meta = $self->meta_info(is_a => $col);
	my $f_class = $meta->foreign_class;

	return if ref($value) and $value->isa($f_class);

	$value = $f_class->_simple_bless($value);
	$proto->_import_column_values($self, $f_class, $value);

	return $self->_attribute_store($col => $value);
    };
}

sub _import_column_values {
    my ($self, $class, $f_class, $f_obj) = (@_);
    foreach ($f_class->all_columns) {
	$class->_attribute_store($_, $f_obj->$_)
	    unless $_->name eq $class->primary_column->name;
    }
}

sub _set_up_class_data {
        my $self = shift;
        $self->class->_extend_class_data(__isa_rels => $self->accessor =>
                        [ $self->foreign_class, %{ $self->args } ]);
        $self->SUPER::_set_up_class_data;
}


sub _get_methods {
    my ($self, $acc_name, $f_col, $mode) = @_;
    warn "_get_methods $acc_name, $f_col, $mode \n";
    warn join(', ',caller());
    my $method;
 MODE: {
	if ($mode eq 'rw') {
	    $method = sub {
	      warn "artificial method $acc_name/$f_col called with args ", join(', ',@_), "\n";
		my ($self, @args) = @_;
		if(@args) {
		  $self->$acc_name->$f_col(@args);
		  return;
		} else {
		  return $self->$acc_name->$f_col;
		}
	    };
	    last MODE;
	}
	if ($mode eq 'ro') {
	    $method = sub {
		my $self = shift;
		return $self->$acc_name->$f_col;
	    };
	    last MODE;
	}
	if ($mode eq 'wo') {
	    $method =  sub {
		my $self = shift;
		$self->$acc_name->$f_col(@_);
		return;
	    };
	    last MODE;
	}

	else {
	    die "can't get method for mode :$mode\n";
	}
    } # end of MODE
    return $method;
}

################################################################################

=head1 BUGS AND CAVEATS

* Multiple inheritance is not supported, this is unlikely to change for the forseable future

* is_a must be called after all other cdbi relationship methods otherwise inherited methods and 
accessors may be over-ridden or clash unexpectedly

* non Class::DBI attributes and methods are not inherited via this module

* The update method is called on the inherited object when the inhertiting object has update called

* Always specify the primary key using columns(Primary => qw/../) if you don't bad things could happen, think of the movies 'Tremors', 'Poltergeist' and 'Evil Dead' all rolled into one but without any heros.

* Very Bad Things can and may occur when using this module even if you use good practice and are cautious -- this includes but is not limited to infinite loops, memory leaks and data corruption.

=head1 DEPENDANCIES

L<Class::DBI::AbstractSearch>

=head1 SEE ALSO

L<perl>

L<Class::DBI>

L<Class::DBI::Relationship>

=head1 AUTHOR

Richard Hundt, E<lt>richard@webtk.org.ukE<gt>

=head1 MAINTAINER

Aaron Trevena E<lt>aaron.trevena@droogs.orgE<gt>

=head1 COPYRIGHT

Licensed for use, modification and distribution under the Artistic
and GNU GPL licenses.

Copyright (C) 2004 by Richard Hundt and Aaron Trevena

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut


################################################################################
################################################################################

1;

