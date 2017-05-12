package Class::DBI::Relationship::HasManyOrdered;

use strict;
use warnings;

our $VERSION = '0.03';

use base qw(Class::DBI::Relationship::HasMany);

##########
# over-ridden Class::DBI::Relationship methods

sub methods {
    my $self     = shift;
    my $accessor = $self->accessor;
    return (
	    $accessor => $self->_has_many_ordered_method,
	    "${accessor}_asIndex" => $self->_has_many_ordered_asindex_method,
	    "append_to_$accessor" => $self->_method_insert('append'),
	    "prepend_to_$accessor" => $self->_method_insert('prepend'),
	    "append_$accessor" => $self->_method_insert('append'),
	    "prepend_$accessor" => $self->_method_insert('prepend'),
	    "insert_$accessor" => $self->_method_insert,
	    "delete_$accessor" => $self->_method_delete,
	    "replace_$accessor" => $self->_method_replace,
	   );
}

sub triggers {
	my $self = shift;
	my $accessor = $self->accessor;
	return (
		before_delete => sub {
		    my $self = shift;
		    my $meta = ref($self)->meta_info(has_many => $accessor);
		    my ($f_class, $f_key, $args) =
			($meta->foreign_class, $meta->args->{foreign_key}, $meta->args);
		    if ($meta->args->{map}) {
			my $pk = $self->columns('Primary');
			my $sth = $self->db_Main->prepare("delete from ".$meta->args->{map}." where $pk = ?");
			my $rv = $sth->execute($self->id);
		    } else {
			return if $self->args->{no_cascade_delete};    # undocumented and untested!
			$f_class->search($f_key => $self->id)->delete_all;
		    }
		});
}

###########

sub _method_insert {
    my $self = shift;
    my $mode = shift;
    my $accessor = $self->accessor;
    my $methodname = ($mode) ? "${mode}_to_$accessor" :  "insert_$accessor" ;
    return sub {
	my ($self, $data,$position) = @_;
	$mode = 'append' unless (defined $position || $mode);
	$position = 0 if ($mode eq 'prepend');
	my $class = ref $self
	    or return $self->_croak("$methodname called as class method");
	return $self->_croak("$methodname needs data")
	    unless defined $data;

	my $meta = $class->meta_info(has_many_ordered => $accessor);
	my $order_column = $meta->args->{order_by};
	my $pk = $self->columns('Primary');
	my ($f_class, $f_key) = ($meta->foreign_class, $meta->foreign_class->columns('Primary'));

	if ($mode eq 'append') {
	    my $sql = ($meta->args->{map}) ? "select max($order_column) + 1 from ".$meta->args->{map} ." where $pk = ?" : "select max($order_column) + 1 from ".$self->table." where $f_key = ?";
	    my $sth = $self->db_Main->prepare($sql);
	    my $rv = $sth->execute($self->id);
	    if ($rv) {
		($position) = $sth->fetchrow_array();
	    }
	}
	$position ||= 0;
	my $maptable = $meta->args->{map} || '';
	my $orderby = $meta->args->{order_by};
	my $fclass_table = $f_class->table;

	my @objects = ((ref $data eq 'ARRAY') ? @$data : $data);
	foreach my $data (@objects) {
	    # check if data is one of string (must be id), object, hash or array of either
	    my $f_object;
	    my $f_object_id;
	    if (ref $data eq 'HASH') {
		# create new object
		$f_object = $f_class->create($data);
		$f_object_id = $f_object->id;
	    } elsif (ref $data eq $f_class) { # data is object of foreign class
		$f_object = $data;
		$f_object_id = $f_object->id;
	    } else { # data is object id
		if (ref $data) { # check is scalar
		    warn "got ",ref $data," expected $f_class \n";
		    die "$methodname requires one or more valid object ids, objects, or hashes - got an unexpected reference";
		}
 		$data =~ s/\s//g;
		if ($data =~ /\D/) { # check is numeric
		    die "$methodname requires one or more valid object ids, objects, or hashes - got an unexpected value";
		}
		$f_object_id = $data;
	    }

	    if ($maptable) {
		# reset positions
		unless ($mode eq 'append') {
		    my $query = "update $maptable set $orderby = $orderby + 1 where $orderby >= ? and $pk = ?";
		    my $sth = $self->db_Main->prepare($query);
		    my $rv = $sth->execute($position,$self->id);
		}

		# insert new side-table entry
		my $sth = $self->db_Main->prepare("insert into $maptable ($pk, $f_key, $orderby) values ( ?, ?, ? )");
		my $rv = $sth->execute($self->id, $f_object_id ,$position);
	    } else {
		unless ($mode eq 'append') {
		    my $query = "update $fclass_table set $orderby =  $orderby + 1 where $orderby >= ? and $pk = ?";
		    my $sth = $self->db_Main->prepare($query);
		    my $rv = $sth->execute($position,$self->id);
		}
		$f_object = $f_class->retrieve($f_object_id) unless (ref $f_object eq $f_class);
		$f_object->{$f_key} = $self->id;
		$f_object->{$orderby} = $position;
		$f_object->update();
	    }
	    $position++;
	}
	return scalar @objects;
    };
}


sub _method_delete {
    my $self = shift;
    my $accessor = $self->accessor;
    my $methodname = "delete_$accessor";
    return sub {
	my ($self, @args) = @_;
	my $class = ref $self
	    or return $self->_croak("$methodname called as class method");
	return $self->_croak("$methodname needs position or objects")
	    unless defined $args[0];
	my $meta = $class->meta_info(has_many_ordered => $accessor);
	my $pk = $self->columns('Primary');
	my ($f_class, $f_key) = ($meta->foreign_class, $meta->foreign_class->columns('Primary'));
	my $fclass_table = $f_class->table;

	if ($args[0] =~ /object/) {
	    # data must be one of string (must be id) or object or array of either
	    my $data = $args[1];
	    my @objects = ((ref $data eq 'ARRAY') ? @$data : $data);
	    foreach my $data (@objects) {
		if (ref $data eq $f_class) { # is object of foreign class
		    if ($meta->args->{map}) { # check if using mapping table
			my $sth = $self->db_Main->prepare("delete from ".$meta->args->{map}." where $pk = ? and $f_key = ?");
			my $rv = $sth->execute($self->id, $data->id);
		    } else {
			$data->{$f_key} = $self->id; # FIXME: may not work for inherited relationships
			$data->delete();
		    }
		} else {	# is object id
		    if (ref $data) { # check is scalar
			die "$methodname requires one or more valid object ids, objects, or hashes - got an unexpected reference";
		    }

		    if ($data =~ /\D/) { # check is numeric
			die "$methodname requires one or more valid object ids, objects, or hashes - got an unexpected value";
		    }

		    if ($meta->args->{map}) { # check if using mapping table
			my $sth = $self->db_Main->prepare("delete from ".$meta->args->{map}." where $pk = ? and $f_key = ?");
			my $rv = $sth->execute($self->id, $data);
		    } else {
			my $f_object = $f_class->retrieve($data);
			unless ($f_object) {
			    die "$data is not a valid id for ".$f_class->table." in $methodname\n";
			}
			$f_object->delete();
		    }
		}
	    }
	} else {
	    my @elements = ((ref $args[0] eq 'ARRAY') ? @{$args[0]} : @args);
	    my $placeholder = join(',',map( '?',@elements));
	    my $orderby = $meta->args->{order_by};
	    if ($meta->args->{map}) { # check if using mapping table
		my $sth = $self->db_Main->prepare("delete from ".$meta->args->{map}." where $pk = ? and $orderby IN ($placeholder)");
		my $rv = $sth->execute($self->id, @elements);
	    } else {
		my $query = "select $f_key as PK from $fclass_table where $pk = ? and $orderby in ($placeholder)";
		my $sth = $self->db_Main->prepare($query);
		my $rv = $sth->execute(@elements);
		my @ids = keys %{$sth->fetchall_hashref( 'PK' )};
		foreach (@ids) {
		    my $f_object = $f_class->retrieve($_);
		    $f_object->delete();
		}
	    }
	}
    };
}

sub _method_replace {
    my $self = shift;
    my $accessor = $self->accessor;
    my $methodname = "replace_$accessor";
    my $deletemethod = "delete_$accessor";
    my $insertmethod = "insert_$accessor";
    return sub {
	my ($self, $data) = @_;
	my $class = ref $self
	    or return $self->_croak("$methodname called as class method");
	return $self->_croak("$methodname needs objects or id's")
	    unless defined $data;
	# remove current object
	$self->$deletemethod($self->$accessor);
	# insert new objects
	return $self->$insertmethod($data);
    };
}

sub _has_many_ordered_asindex_method {
    my $self = shift;
    my $accessor = $self->accessor;
    return sub {
	my ($self,$id_field,$title_field) = @_;
	my $meta = ref($self)->meta_info(has_many_ordered => $accessor);
	my $pk = $self->columns('Primary');
	my ($f_class, $f_key) = ($meta->foreign_class, $meta->foreign_class->columns('Primary'));
	$id_field ||=  $f_key;
	if (ref $self) {
	    $title_field ||= $self->{"_${accessor}_index"} ||
		($self->{"_${accessor}_index"} = (grep(/(name|title)/i, sort($f_class->columns('All'))))[0]) ;
	} else {
	    $title_field ||= (grep(/(name|title)/i, sort($f_class->columns('All'))))[0];
	}
	die unless ($title_field);

	my $maptable = $meta->args->{map};
	my $orderby = $meta->args->{order_by};
	my $f_table = $f_class->table;
	# FIXME: probably doesn't handle inherited fields in id or title fields
	my @args = ();
	my $query = "select $id_field, $title_field from $f_table where $pk = ? order by $orderby";
	if ($maptable) {
	    $query = "select ${f_table}.${id_field}, ${f_table}.$title_field from ${f_table}, $maptable " .
		     "where ${maptable}.$f_key = ${f_table}.$f_key and ${maptable}.$pk = ? order by $orderby";
	}
	my $sth = $f_class->db_Main->prepare($query);
	my $rv = $sth->execute($self->id);
	return $sth->fetchall_arrayref();
    };
}

sub _has_many_ordered_method {
    my $self       = shift;
    my $accessor = $self->accessor;
    return sub {
	my ($self,$key,$value) = @_;
	my $meta = ref($self)->meta_info(has_many_ordered => $accessor);
	my $pk = $self->columns('Primary');
	my ($f_class, $f_key) = ($meta->foreign_class, $meta->foreign_class->columns('Primary'));
	my $maptable = $meta->args->{map};
	my $orderby = $meta->args->{order_by};

	if ($maptable) {
	    my $f_table = $f_class->table;
	    my @columns = ( $f_class->columns('Essential') ) ? $f_class->columns('Essential') : $f_class->columns('All');
	    my $query = 'SELECT '. join(', ',map { s/$f_key/$f_table.$f_key/i; $_; } @columns). " FROM $maptable, $f_table WHERE " .
		"${maptable}.$f_key = ${f_table}.$f_key and ${maptable}.$pk = ? order by ${maptable}.$orderby";
	    my $sth = $f_class->db_Main->prepare($query);
	    my $rv = $sth->execute($self->id);
	    return $f_class->sth_to_objects($sth);
	} else {
	    my @args = ($f_key => $self->id);
	    if ($key && defined $value) {
		push(@args,($key => $value));
	    } elsif (defined $key) {
		push(@args,($orderby => $key));
	    }
	    return $f_class->search(@args);
	}
    };
}

#

1;

__END__

=head1 NAME

Class::DBI::Relationship::HasManyOrdered - A Class::DBI module for Ordered 'Has Many' relationships

=head1 SYNOPSIS

In your classes:

 package ContentManager::DBI;
 use base 'Class::DBI';

 ContentManager::DBI->connection('dbi:mysql:dbname', 'username', 'password');
 __PACKAGE__->add_relationship_type(has_many_ordered => 'Class::DBI::Relationship::IsA');

 ...

 package ContentManager::Image;
 use base 'ContentManager::DBI';

 ContentManager::Image->table('images');
 ContentManager::Image->columns(All => qw/image_id name position filename/);

 ...

 package ContentManager::Page;
 use base 'ContentManager::DBI';

 ContentManager::Page->table('pages');
 ContentManager::Page->columns(All => qw/page_id title date_to_publish date_to_archive/);
 Page->has_a(category => Category);
 Page->has_many(authors => Authors);
 Page->has_many_ordered(paragraphs => Paragraphs => {sort => 'position', map => 'PageParagraphs'});
 Page->has_many_ordered(images => Images => {sort => 'position', map => 'PageImages'});

In your application  ...

 use ContentManager::Page;
 my $page = ContentManager::Page->create( {title=>'Extending Class::DBI', date_to_publish=>'dd/mm/yyyy'});


 my $image1 = Image->search(name=>'Class::DBI logo');
 my @figures = Image->search(name=>'Class Diagram (CDBI)', order_by => 'filename');
 my $author_image = Image->search(name=>'Aaron Trevena - portrait');

 $page->insert_Images(@figures); # inserts figures into next/last available positions, sets positions

 ...

 $page->prepend_Images($image1); # inserts image into first position, resets other image positions

 $page->append_Images($author_image); # appends image to last position

 ...

 $page->update();


=head1 DESCRIPTION

Class::DBI::Relationship::HasManyOrdered Provides an ordered 'Has Many' relationship between Class::DBI classes.
This relationship enhances the HasMany relationship already provided in Class::DBI to allow you to quickly and
easily deal with ordered 'One to Many' or 'Many to Many' relationships without additional handcoding  while
preserving as much of the original behaviour and syntax as possible.

For more information See Class::DBI and Class::DBI::Relationship.


=head1 CLASS METHODS

=head1 has_many_ordered

Page->has_many_ordered(paragraphs => Paragraphs => {sort => 'position', map => 'PageParagraphs'});

has_many_ordered is a class method which takes the accessor name, followed by the foreign class name, and a hashref of arguments.
the hashref arguments self explainatory but the map argument refers to the mapping table rather than class, this differs from standard C::DBI practice but avoids the necessity of having a joining class where you would have to specify the tablename anyway

=head2 EXPORT

None.

=head1 SEE ALSO

L<perl>

L<Class::DBI>

L<Class::DBI::Relationship>

=head1 AUTHOR

Aaron Trevena, E<lt>teejay@droogs.orgE<gt>

Based on Class::DBI::Relationship::HasMany.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Aaron Trevena

Class::DBI::Relationship::HasMany code, etc Copyright (C) its respective authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
