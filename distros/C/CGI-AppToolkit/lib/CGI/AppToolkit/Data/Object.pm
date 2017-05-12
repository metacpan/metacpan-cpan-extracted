package CGI::AppToolkit::Data::Object;

# Copyright 2002 Robert Giseburt. All rights reserved.
# This library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# Email: rob@heavyhosting.net

$CGI::AppToolkit::Data::Object::VERSION = '0.05';

use Carp;
use strict;
use vars qw/$AUTOLOAD/;

#-------------------------------------#
# OO Custructor                       #
#-------------------------------------#


sub new {
	my $type = shift;
	my $self = bless _clean_vars(@_), $type;
	
	if ($self->can('preinit')) {
		$self->preinit()
	}
	$self->init() || return undef;
	
	$self
}


#-------------------------------------#
# OO Methods                          #
#-------------------------------------#

# prefetch -- return a [$sth, $order] and {$values}


sub init {
	my $self = shift;
	
	#set:
	# table
	
	1; # MUST return true
}


#-------------------------------------#

# fetch some objects
sub fetch {
	my $self = shift;
	my $args = ref $_[0] eq 'HASH' ? shift : {@_};
	
	
}

#-------------------------------------#

# fetch an object
sub fetch_one {
	my $self = shift;
	my $args = ref $_[0] eq 'HASH' ? shift : {@_};

	$args->{'-one'} = 1;
	
	$self->fetch($args);	
}
*fetch_row = \&fetch_one;

#-------------------------------------#

# store an object
sub store {
	my $self = shift;

}


#-------------------------------------#

# update an object
sub update {
	my $self = shift;

}


#-------------------------------------#

# delete an object
sub delete {
	my $self = shift;

}


#-------------------------------------#

# cleanup an object
sub cleanup {
	my $self = shift;
	
	return shift;
}


#-------------------------------------#

# get a prepared db statement
sub db_statement {
	my $self = shift;
	my $name = shift;

}


#-------------------------------------#

# AUTOLOAD
sub AUTOLOAD {
	#my $self = shift;

	my $name = $AUTOLOAD;
	$name =~ s/.*://;	# strip fully-qualified portion
	
	return if $name eq 'DESTROY';

	my $name_lc = lc $name;
	if ($name_lc =~ /^get_(.*)/) {
		$name_lc = $1;
		eval <<"END_SUB" || croak "AUTOLOAD '$AUTOLOAD' failed: \"$@\"";
			sub $name {
				my \$self = shift;
				return \$self->{'$name_lc'} || undef;
			}
			1;
END_SUB
	} elsif ($name_lc =~ /^set_(.*)/) {
		$name_lc = $1;
		eval <<"END_SUB" || croak "AUTOLOAD '$AUTOLOAD' failed: \"$@\"";
			sub $name {
				my \$self = shift;
				if (\@_) {
					return \$self->{'$name_lc'} = shift;
				}
			}
			1;
END_SUB
	}
	
	no strict 'refs';
	goto &{$name};
}


#-------------------------------------#
# Inherited Non-Interface Methods     #
#-------------------------------------#


sub _new_error {
	shift; # ditch $self
	return CGI::AppToolkit::Data::Object::Error->new();
}


#-------------------------------------#
# Non-OO Methods                      #
#-------------------------------------#


sub _clean_vars {
	my $vars = ref $_[0] eq 'HASH' ? shift : {@_};
	
	foreach my $key (keys %$vars) {
		my $oldkey = $key;
		$key =~ s/^-//;
		$key = lc $key;
		$vars->{$key} = delete $vars->{$oldkey} if $key ne $oldkey;
	}
	
	return $vars;
}

1;

package CGI::AppToolkit::Data::Object::Error;

#-------------------------------------#
# OO Custructor                       #
#-------------------------------------#


sub new {
	my $type = shift;
	my $self = bless CGI::AppToolkit::Data::Object::_clean_vars(@_), $type;
	
	$self->{'errors'} = [];
	$self->{'wrong'} = [];
	$self->{'missing'} = [];	
	
	$self
}


#-------------------------------------#
# OO Methods                          #
#-------------------------------------#


sub error {
	my $self = shift;
	my $error = shift;
	
	push @{$self->{'errors'}}, {'text' => $error};
}


#-------------------------------------#


sub wrong {
	my $self = shift;
	my $wrong = shift;
	
	push @{$self->{'wrong'}}, $wrong;
}


#-------------------------------------#


sub missing {
	my $self = shift;
	my $missing = shift;
	
	push @{$self->{'missing'}}, $missing;
}


#-------------------------------------#


sub has_errors {
	my $self = shift;
	
	scalar @{$self->{'errors'}} || scalar @{$self->{'missing'}} || scalar @{$self->{'wrong'}}
}


#-------------------------------------#


sub get {
	my $self = shift;
	
	($self->{'errors'}, $self->{'wrong'}, $self->{'missing'})
}

1;

__DATA__

=head1 NAME

B<CGI::AppToolkit::Data::Object> - A data source component of L<B<CGI::AppToolkit>|CGI::AppToolkit>

=head1 DESCRIPTION

B<CGI::AppToolkit::Data::Object>s provide a common interface to multiple data sources. The data sources are provided by B<CGI::AppToolkit::Data::Object> decendants that you create, generally on a per-project basis. Providing a data source requires creating an object in the B<CGI::AppToolkit::Data::> namespace that inherits from B<CGI::AppToolkit::Data::Object>.

You B<do not> C<use> this module or it's descendants in your code directly, but instead call B<CGI::AppToolkit-E<gt>data()> to load it for you.

=head2 USAGE

For a B<Person> object, you might start the module like this:

  package CGI::AppToolkit::Data::Person;
  
  use CGI::AppToolkit::Data::Object;
  use strict;
  
  @CGI::AppToolkit::Data::Person::ISA = qw/CGI::AppToolkit::Data::Object/;

After that, you simply have to override four subroutines: B<fetch>, B<store>, B<delete>, and B<update>. All of these are called with two parameters: the object, of course, and the arguments. The arguments are passed in a single parameter which is usually a hashref.

  sub store { # or fetch, update, or delete
    my $self = shift;
    my $args = shift;
    
	# args is usually a hashref, so you would use it like this
	my $id = $args->{'id'};
	
	#... do the actual storing and such here
  }

There is nothing forcing you to implement all of these subroutines. For example, if you are implementing a read-only object, then you could override only B<fetch>. 

Conventionally a relational database is used, but there's nothing forcing you to that either. The data can come from any source at all. However, if you data I<is> coming from a DBI accessed RDBMS that uses SQL, then you should take a look at L<B<CGI::AppToolkit::Data::SQLObject>|CGI::AppToolkit::Data::SQLObject> and L<B<CGI::AppToolkit::Data::Automorph>|CGI::AppToolkit::Data::Automorph>. B<CGI::AppToolkit::Data::SQLObject> handles a few of the common DBI tasks for you, and it's descendant B<CGI::AppToolkit::Data::Automorph> attempts to handle the rest of them.

=head2 METHODS

B<CGI::AppToolkit::Data::Object> provides several convenience methods to inherit.

=over 4

=item B<get_kit()>

Returns the creating B<CGI::AppToolkit> object. This can be used to retrieve required data.

  my $dbi = $self->get_kit()->get_dbi();

The B<CGI::AppToolkit> object has an autoload mechanism that provides all variables that are passed to it's B<new()> method as method calls, with B<get_> or B<set_> added to the beginning to retrieve or set the value, repectively.

In particular, B<CGI::AppToolkit-E<gt>get_dbi()> retrieves the DBI object stored from a call to B<CGI::AppToolkit-E<gt>connect()>.

=item B<_new_error()>

Returns a new, empty L<B<CGI::AppToolkit::Data::Object::Error>|"CGI::AppToolkit::Data::Object::Error"> object, as described in detail below.

=item B<AUTOLOAD>

Using the built-in AUTOLOAD mechanism, you can retrieve and set object variables with named method calls. These method names are B<not> case sensitive.

  # setting
  $self->set_wierd_variable($value);
  
  # retrieving
  my $value = $self->get_wierd_variable();

=back

=head1 CGI::AppToolkit::Data::Object::Error

=head2 DESCRIPTION

CGI::AppToolkit::Data::Object::Error provides a simple interface to errors returned by B<Data->fetch()>. This class seperates errors into three classes: plain text errors (B<errors>), missing items (B<missing>), and wrong items (B<wrong>). Plain text errors are for sending back to the interface. Missing items and wrong items are both lists of keys that were missing or wrong in the args provided to B<store>.

=head2 METHODS

The following methods are for use by scripts using B<CGI::AppToolkit::Data> and will only need to retrieve errors.

=over 4

=item B<has_errors()>

Return nonzero if there are errors and zero if there are not.

=item B<get()>

Returns three arrayrefs: errors, missing, and wrong, in that order. The errors arrayref points to an array of hashes of the form C<{'text' =E<gt> $error}>. The other two arrayrefs point to arrays of strings.

  # as called in a script using CGI::AppToolkit
  # $of is an instance of CGI::AppToolkit
  my $ret = $CGI::AppToolkit->data('person')->store(\%person);
  if (ref $ret =~ /Error/) {
    my ($errors_a, $missing_a, $wrong_a) = $ret->get();
	# ...
  }

=back

The following methods are for use inside B<CGI::AppToolkit::Data::Object> descendants. 

=over 4

=item B<error(>I<ERROR>B<)>

Adds an error with the text I<ERROR> to the error object.

  $error->error('You screwed up, dude!');

=item B<missing(>I<ITEM>B<)>

=item B<wrong(>I<ITEM>B<)>

Adds a missing or wrong I<ITEM> to the error object.

  $error->missing('address1'); # missing a required field
  $error->wrong('email'); # malformed email address

=back

=head1 AUTHOR

Copyright 2002 Robert Giseburt (rob@heavyhosting.net).  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Please visit http://www.heavyhosting.net/AppToolkit/ for complete documentation.

=cut