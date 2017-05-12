package CGI::AppToolkit;

# Copyright 2002 Robert Giseburt. All rights reserved.
# This library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# Email: rob@heavyhosting.net

$CGI::AppToolkit::VERSION = '0.05';

# NOTE: The following are done on-the-fly, as needed, if needed.
#use CGI::AppToolkit::Template;
#use DBI;

use Carp;

use strict;

use vars qw/$AUTOLOAD/;

1;

#-------------------------------------#
# OO Constructor                       #
#-------------------------------------#


sub new {
	my $type = shift;
	my $self = bless _clean_vars(@_), $type;
	
	$self->init();
	
	return $self;
}


#-------------------------------------#
# OO Methods                          #
#-------------------------------------#


# initialize the object
sub init {
	my $self = shift;
	$self->{'_obj'} = {};
}


#-------------------------------------#

# connect to a database
sub connect {
	my $self = shift;
	
	unless ($INC{'DBI.pm'}) {
		eval 'package CGI::AppToolkit::_firesafe; use DBI;';
	}
	
	$self->{'dbi'} = DBI->connect(@_);
	
	return $self->{'dbi'}
}


#-------------------------------------#

# fetch the data object
sub data {
	my $self = shift;
	my $orignal_kind = shift;

	my $kind = $orignal_kind;
	my ($am) = ($kind =~ s/^(automorph:)//);
	my $table = $kind;
	
	$kind =~ s/\s+/_/g;
	$kind =~ s/(?:^|_)([a-zA-Z])/uc($1)/ge;
	
	my $obj;
	
	if ($am) {
		unless ($self->{'_am_loaded'}) {
			eval "package CGI::AppToolkit::Data::_firesafe; require CGI::AppToolkit::Data::Automorph";
			if ($@) {
				my $err = $@;
				my $advice = "Automorph.pm appears to be missing, called";
	
				Carp::croak("obj($orignal_kind) failed: $err$advice");
			}
		
		}
		
		$kind = 'am:' . $kind;
		
		if (exists $self->{'_obj'}{$kind}) {
			return $self->{'_obj'}{$kind};		
		} else {
			$obj = CGI::AppToolkit::Data::Automorph->new(-kit => $self, -table => $table);		
			return $self->{'_obj'}{$kind} = $obj;
		}
		
	} elsif (exists $self->{'_obj'}{$kind}) {
		return $self->{'_obj'}{$kind};
		
	} else {
		#no strict 'refs';
    	eval "package CGI::AppToolkit::Data::_firesafe; require CGI::AppToolkit::Data::$kind";
		if ($@) {
			my $err = $@;
			my $advice = "";

			if ($err =~ /Can't find loadable object/) {
				$advice = "Perhaps CGI::AppToolkit::Data::$kind was statically linked into a new perl binary.\n"
					."In which case you need to use that new perl binary.\n"
					."Or perhaps only the .pm file was installed but not the shared object file."

			} elsif ($err =~ /Can't locate.*?Data\/$kind\.pm in \@INC/) {
				$advice = "Perhaps the CGI::AppToolkit::Data::$kind perl module hasn't been fully installed.";

			} elsif ($err =~ /Can't locate .*? in \@INC/) {
				$advice = "Perhaps a module that CGI::AppToolkit::Data::$kind requires hasn't been fully installed.";
			}
			Carp::croak("obj($orignal_kind) failed: $err$advice Called");
		}
		
		$obj = "CGI::AppToolkit::Data::$kind"->new(-kit => $self, -table => $table);
		
		carp ($CGI::AppToolkit::Data::ERROR || "CGI::AppToolkit::Data::$kind\->init() didn't return 'true', called") unless $obj;
		
		return $self->{'_obj'}{$kind} = $obj;
	}
}


#-------------------------------------#

# fetch the template object
sub template {
	my $self = shift;

	unless ($INC{'CGI::AppToolkit/Template.pm'}) {
		eval 'package CGI::AppToolkit::_firesafe; use CGI::AppToolkit::Template;';
		croak "$@" if $@;
	}

	if (@_) {		
		return CGI::AppToolkit::Template->template(@_);
	} else {
		return CGI::AppToolkit::Template->new();	
	}
}

#-------------------------------------#

# AUTOLOAD
sub AUTOLOAD {
	#my $self = shift;

	my $name = $AUTOLOAD;
	$name =~ s/.*://;	# strip fully-qualified portion
	
	return if $name eq 'DESTROY';

# NOTE: Have CGI::AppToolkit load subs from other packages on autoload?
#	if ( CGI::AppToolkit::Template->can($name) ) {
#	
#	} else {
#	}
	
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

__DATA__

=head1 NAME

CGI::AppToolkit - An object-oriented application development framework

=head1 DESCRIPTION

This module is the single access point for data and interface abstraction modules. These abstraction layers have a similar interface, and are called using the same techniques.

This framework has been developed for web-based applications, but there is no reason for it not to work in other perl applications.

The data abstraction portion's primary use is to provide a simple and easy to use interface to retrieve and store data. This allows varying types of data to be accessed using the same API. The varying types of data are handled in self-contained sub-objects that inherit from L<B<CGI::AppToolkit::Data::Object>|CGI::AppToolkit::Data::Object>. There are subclasses of B<CGI::AppToolkit::Data::Object> that are specialized to use DBI.

The interface abstraction part is a text templating module, B<CGI::AppToolkit::Template>. Please read the L<B<CGI::AppToolkit::Template>|CGI::AppToolkit::Template> documentnation for more information about the templating syntax and calling methods.

=head1 SYNOPSIS

  use strict;
  use CGI;
  use CGI::AppToolkit;
  
  my $kit = new CGI::AppToolkit;
  my $cgi = new CGI;
  
  if ($cgi->param('do') eq 'search') {
    my $keywords = $cgi->param('keywords') || '';
    
    #fetch a arrayref of hashrefs
    my $articles = $kit->data('Articles')->fetch(keywords => $keywords);
    
    
    #print the header and the 'search' template with our results
    print $cgi->header;    
    print $kit->template('search')->make(articles => $articles, keywords => $keywords);
    
  } elsif ($cgi->param('do') eq 'show-one') {
    my $article = $kit->data('Articles')->fetch(id => $cgi->param('id') || 1);
    
    #print the header and the 'form' template filled in with our data
    print $cgi->header;
    print $kit->template('form')->make($article);
    
  } elsif ($cgi->param('do') eq 'save-one') {
    my $article = $kit->data('Articles')->fetch(id => $cgi->param('id') || 1);
  
    foreach my $key (qw/content byline headline/) {
      $article->{$key} = $cgi->param($key);
    }
    
    my $result = $kit->data('Articles')->store($article);
    
    if (ref $result =~ /::Error/) {
      #there's an error
      my ($errors_a, $missing_a, $wrong_a) = $ret->get();
      
      #put the error text into the data structure
      $article->{'errors'} = $errors_a;
      
      #and flag the parameters that were wrong or missing
      #the template can somehow display the form fields that need changed
      foreach $erroneous (@$missing_a, @$wrong_a) {
        $article->{$erroneous . '-wrongflag'} = 1;
      }
      
      #show the form again
      print $cgi->header;
      print $kit->template('form')->make($article);
        
    } else {
      # all is well, go back to the display
  
      print $cgi->redirect('./index.cgi?do=show-one&id=' . $result->{'id'});
    }
  }

=head1 METHODS

=over 4

=item B<new(>I<[OPTIONS]>B<)>

  $kit = CGI::AppToolkit->new();

Returns a new CGI::AppToolkit object. OPTIONS is an options list of key-value pairs that are made available to all of the objects that use or are used by B<CGI::AppToolkit>. These values can be accessed later with C<get_*> and C<set_*> to retrieve or set the values, respectively. The keys and accessors are NOT case-sensitive.

  $kit = CGI::AppToolkit->new(DBI => DBI->connect(...)); # See connect()
  $db = $kit->get_dbi();
  $kit->set_projectSpecific(1);
  
  #... in another module that was passed $kit
  
  if ($kit->get_projectSpecific()) {
    ...
  }

=item B<template(>I<[NAME]>B<)>

  $t = $kit->template('template name');
  print $t->make(\%data);

Returns a L<B<CGI::AppToolkit::Template>|CGI::AppToolkit::Template> object with the I<NAME>d template loaded.

If I<NAME> is actually a multiline string, then it will be assumed that it is the actual template itself and parsed for tokens.

If I<NAME> is a file name, then the template will be loaded and (by default) cached. This cache will persist across severel uses of CGI::AppToolkit::Template under B<mod_perl> or similar environments.

B<CGI::AppToolkit::Template> employs a shell-style PATH mechanism for convenience. Call B<CGI::AppToolkit::Template-E<gt>set_path(>I<LIST>B<)> to set the path to list. It is set to C<qw/. templates/> by default. If the template name requested contains a '/', then the PATH will not be used and it will attempt to load the file exactly as it is named.

=item B<data(>I<NAME>B<)>

  $kit->data('data source name')->fetch( ... );

Returns a data object that you can use to access and manipulate the data in some sort of database (or flat file). See L<B<CGI::AppToolkit::Data::Object>|CGI::AppToolkit::Data::Object> for instructions on creating data objects. Data objects are loaded from other modules and cached. Please see L<DATA SOURCE NAMING|"DSN"> for what to provide as the I<NAME>, and L<DATA SOURCE METHODS|"DSM"> for how to call the data sources.

=item B<AUTOLOAD>

Using the built-in AUTOLOAD mechanism, you can retrieve and set object variables with named method calls. These method names are B<not> case sensitive.

  # setting
  $kit->set_wierd_variable($value);
  
  #...
  
  # retrieving
  my $value = $kit->get_wierd_variable();

=back

=head1 X<DSN>DATA SOURCE NAMING

The data source is an object in C<CGI::AppToolkit::Data::> that inherits from L<B<CGI::AppToolkit::Data::Object>|CGI::AppToolkit::Data::Object> or one that inherits from it such as L<B<CGI::AppToolkit::Data::SQLObject>|CGI::AppToolkit::Data::SQLObject> or L<B<CGI::AppToolkit::Data::Automorph>|CGI::AppToolkit::Data::Automorph>.

Data source names that begin with C<automorph:>, and end with a SQL table name will use an instance of C<CGI::AppToolkit::Data::Automorph> directly, instead of a subclass. In this case, C<CGI::AppToolkit::Data::Automorph> will make certain assumptions (as well as do some investigation) about the structure of the table. This is good for simply structured tables that don't requre any special or complex SQL.

All other data source names are normalized into package names like this:

=over 4

=item 1

The first character and all characters following underscores and space runs are uppercased.

=item 2

All underscores and space runs are removed.

=item 3

The results will be appended to C<CGI::AppToolkit::Data::> and used as a package name.

=back

So, 'C<the real_THING>' will become 'C<CGI::AppToolkit::Data::TheRealTHING>'. That package must be B<require>able. This will be done automatically by B<data()>:

  require CGI::AppToolkit::Data::TheRealTHING;

If the B<require> fails, Data will throw a fatal error with a little bit of diagnostic information.

I<You should not B<use> or B<require> the object in your code.>

=head1 X<DSM>DATA SOURCE METHODS

These methods can be made on the data sources returned from C<CGI::AppToolkit->data()>.

=over 4

=item B<fetch(>I<[OPTIONS]>B<)> or B<fetch_one(>I<[OPTIONS]>B<)>

  # return the first match as a hashref
  $data_hash_ref = $kit->data('people')->fetch_one({'id' => 12});
  
  # or return every match in a arrayref of hashrefs
  $data_array_ref = $kit->data('people')->fetch({'name' => 'Rob'});

Returns a data structure retrieved from the data source. The format of the data structure returned depends on whether you called B<fetch()> or B<fetch_one()>.

=item B<store(>I<[OPTIONS]>B<)>

  # %person holds the data needed to create or store a person
  $ret = $kit->data('people')->store(\%person);
  
  if (ref $ret =~ /Error/) {
  	# error handling
  }

Stores a data structure provided in I<OPTIONS> to the data source. B<store()> returns a L<B<CGI::AppToolkit::Data::Object::Error>|CGI::AppToolkit::Data::Object/"CGI::AppToolkit::Data::Object::Error"> upon failure, otherwise it conventionally returns the data that was passed to it, possibly altered (e.g.: an unique ID was assigned, etc.). 

=item B<update(>I<[OPTIONS]>B<)>

  $kit->data('people')->update({'id' => $id, 'position' => 'Management'});

Updates the data source based upon the I<OPTIONS> sent. Returns like B<store()>.

=item B<delete(>I<[OPTIONS]>B<)>

  $kit->data('people')->delete({'id' => $id});

Delete data from the data source based upon data provided in I<OPTIONS>.

=item B<connect(>I<[DBI PARAMETERS]>B<)>

  $dbi = $kit->connect($data_source, $username, $auth, \%attr);

This method loads DBI (if need be), opens a L<B<DBI>|DBI> connection with the given parameters, stores it, and returns it. Please see L<B<DBI>|DBI> for what parameters to pass.

=item B<get_dbi()>

  $dbi = $kit->get_dbi();

This method returns the L<B<DBI>|DBI> handle object that was stored in B<connect()>.

This is mostly for use within the B<CGI::AppToolkit::Data::Object> descendant modules.

=back

=head1 TODO

=over 4

=item *

These docs need cleaned up.

=item *

SQLObject still doesn't have the range and data checking that Automorph provides vars for.

=item *

SQLObject needs to have specific support for reformatting dates, both incoming and outgoing.

=item *

Template needs rewritten for several reason. It should support objects as values (such as a C<Data::Object::Error> object), as well as data delegates. It should have a pure-perl fallback for when in a C++-free environment. It should have support for shared memory caching. The parser should be seperated into another method, for overriding.

=item *

CGI::AppToolkit::Data::XMLObject needs to be written. I haven't even started it yet.

=back

=head1 AUTHOR

Copyright 2002 Robert Giseburt (rob@heavyhosting.net).  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Please visit http://www.heavyhosting.net/AppToolkit/ for complete documentation.

=cut