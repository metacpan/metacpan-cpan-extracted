package Class::DBI::Factory::Config;

use strict;
use AppConfig qw(:argcount);
use Data::Dumper;

use vars qw( $VERSION $AUTOLOAD );

$VERSION = '0.93';

=head1 NAME

Class::DBI::Factory::Config - an AppConfig-based configuration mechanism for Class::DBI::Factory

=head1 SYNOPSIS
    
	$config = Class::DBI::Factory::Config->new({
		-file => 
	});

	my @classes = $config->classes;
	
	my $tdir = $config->get('template_dir');
	
	my @referers = $config->get('allowed_referer');

=head1 INTRODUCTION

This is just a thin bit of glue that sits between AppConfig and Class::DBI::Factory. Its main purpose is to define the skeleton of parameters that AppConfig uses, but it also provides some useful shorthands for accessing commonly-needed parameters.

In the normal course of events you will never need to work with or subclass this module, or indeed know anything about it. The factory class will take care of constructing and maintaining its own configuration object and following the instructions contained therein.

AppConfig was chosen primarily because it is used by the Template Toolkit and therefore already loaded by my applications. If you're not using TT you may prefer to substitute some other configuration mechanism. You can also subclass more selectively, of course.

=head1 DATA SKELETON

The skeleton defined by this module is used by AppConfig to parse configuration files. It details the variables that we are expecting and what to do with each one. Simple variables don't need to be mentioned, but anything with multiple values or more than one level should be prescribed here.

=head2 skeleton()

This method returns a hashref that describes the configuration data it expects to encounter. You can refer to the documentation for AppConfig for details of how this works, but for most purposes you should only need to work with the list_parameters, hash_parameters and default_values methods.

You can subclass the whole skeleton() method, but for most purposes it will probably suffice to override some of the methods it calls:

=head2 list_parameters

Returns a list of parameter names that should be handled as lists of values rather than as simple scalars.

=head2 extra_list_parameters

If you want to extend the standard list of list parameters, rather than replacing it, then override this method and return your additions as a list of parameter names.

=head2 hash_parameters

Returns a list of parameter names that should be handled as hashes - ie the configuration files will specify both key and value. 

=head2 extra_hash_parameters

If you want to extend the standard list of hash parameters, rather than replacing it, then override this method and return your additions as a list of parameter names. 

=head2 default_values

Returns a hash of (parameter name => value), in which the value may be simple, a list or a hash. Its treatment will depend on what your data skeleton specifies for that parameter.

=head2 extra_defaults

If you want to extend the standard list of default values, rather than replacing it, then override this method and return your additions as a hash of name => default value pairs. The default values can be scalars, or references to lists or hashes as appropriate. 


=cut

sub skeleton {
	my $self = shift;
	my $construction = {
		CREATE => 1,
		CASE => 0,
		GLOBAL => { 
			DEFAULT  => "<undef>",
			ARGCOUNT => ARGCOUNT_ONE,
		},
	};
	my %definitions;
	my %defaults = $self->default_values;
	$definitions{$_} = { ARGCOUNT => ARGCOUNT_LIST } for $self->list_parameters;
	$definitions{$_} = { ARGCOUNT => ARGCOUNT_HASH } for $self->hash_parameters;
	$definitions{$_}->{ DEFAULT } = $defaults{$_} for keys %defaults;
	return ($construction, %definitions);
}

sub list_parameters {
	my $self = shift;
	my @param = $self->extra_list_parameters;
	push @param, qw(include_file class template_dir template_subdir module_dir module_subdir debug_topic);
	return @param;
}

sub hash_parameters {
	my $self = shift;
	my @param = $self->extra_hash_parameters;
	push @param, qw();
	return @param;
}

sub default_values {
	my $self = shift;
	my %and_from_subclass = $self->extra_defaults;
	my %defaults = (
		db_type => 'SQLite',
		smtp_server => 'localhost',
		db_autocommit => 1,
		db_taint => 0,
		db_raiseerror => 0,
		db_showerrorstatement => 1,
		db_dsn => undef,
		db_host => undef,
		db_name => undef,
		db_servername => undef,
		db_port => undef,
		debug_level => 0,
		dbi_trace => 0,
		%and_from_subclass
	);
}

sub extra_list_parameters { () }
sub extra_hash_parameters { () }
sub extra_defaults { () }

=head1 CONSTRUCTION AND MAINTENANCE

In which configuration files are sought, objects are built up and everything kept up to date.

=head2 new()

  $config = Class::DBI::Factory::Config->new('/path/to/file');

Should optionally take a file path parameter and pass it to file(): otherwise, just creates an empty configuration object ready for use but not yet populated.

=cut

sub new {
	my ($class, @config_files) = @_;
	my $self = bless {
		_file_read => {},
		_files => [],
		_config_files => [ @config_files ],
		_timestamp => scalar time,
	}, $class;
	return $self->_build;
}

=head2 _build()

This one does the real work of reading in all the configuration files we can find.

=cut

sub _build {
	my $self = shift;
	$self->file($self->config_files);
	$self->extra_prep;
	$self->file( $_ ) for @{ $self->get('include_file') };
	return $self;
}

=head2 config_files()

Accessor for the list of config files that will be read. This list can't be set after construction, but you can always call file() to read more files in.

This method will always return the list of files that was supposed to be read on construction. Call files() if you would like the list of files (successfully) read during the lifetime of the config object.

=head2 extra_prep()

Placeholder for any configuration-loading steps you want to include.

This method is called after config files have been read, so settings here will override defaults.

=cut

sub config_files { 
    my $self = shift;
    return unless $self->{_config_files};
    return @{ $self->{_config_files} };
}

sub extra_prep { }

=head2 file()

  $config->file('/path/to/file', '/path/to/otherfile');
  
Reads configuration files from the supplied addresses, and stores their addresses and modification dates in case of a later refresh() or rebuild().

=cut

sub file {
	my ($self, @files) = @_;
	my $time = scalar time;
	for (@files) {
        next unless _readable($_);
        my $mdate = _mdate($_);
		push @{ $self->{_files} } , $_;
		$self->{_file_read}->{$_} = $mdate;
		$self->ac->file($_) || next;
	}
}

sub _readable {
    my $self = shift;
    my $f = ref ($self) ? shift : $self;
    $f =~ s/\/+/\//g;
    return $f if -e $f && -f _ && -r _;
    return;
}

sub _mdate {
    my $self = shift;
    my $f = ref ($self) ? shift : $self;
    $f =~ s/\/+/\//g;
	my @stat = stat($f);
    return $stat[9];
}

=head2 refresh()

  $config->refresh();
  $config->refresh('/path/to/file');

Checks the modification date for each of the configuration files that have been read: if any have changed since we read it, the whole configuration object is dropped and rebuilt. 

By default this will revisit the whole set of read configuration files, but if you supply a list of files, refresh() will confine itself to looking at the intersection of your list and the list of files already read. Either way, configuration files are always read back in in the same order as we originally encountered them.

Note that if a configuration file is missing at startup it will not be looked for later: this only refreshes the files that were successfully read.

=head2 rebuild()

This will drop all configuration information and start again by re-reading all the configuration files. Any other changes your application has made, eg by setting values directly, will be lost.

=head2 files()

Returns a list in date order of all the configuration files successfully read during the lifetime of this object.

=cut

sub refresh {
	my $self = shift;
	my @files = @_ || $self->files;
    return unless @files;
	for (@files) {
        next unless exists $self->{_file_read}->{$_};
		next unless _readable($_);
		next unless _mdate($_) > $self->{_file_read}->{$_};
		return $self->rebuild;
	}
    return;
}

sub rebuild {
	my $self = shift;
	my @files = $self->files;
    $self->{_files} = [];
	$self->{_file_read} = {};
	$self->_new_ac;
	$self->file( @files );
	$self->{_timestamp} = scalar time,
}

sub files {
    return @{ shift->{_files} };
}

=head2 timestamp()

A possibly-useful read-only method that returns the epoch time at which this object read in its configuration files (ie when it was built, or last rebuilt).

=cut

sub timestamp {
    return shift->{_timestamp};
}

=head1 ACCESS TO SETTINGS

CDF::Config uses the same conventions as AppConfig. If there's no clash with a method name, you can retrieve settings like this:

  $address = $config->admin_email;
  @views = $config->permitted_view;
  [% FOREACH user IN config.sin_bin %]
  
or like this, which is the syntax you'll have to use if either CDFC or AppConfig provides a method with the same name as your parameter:

  $rebuild = $config->get('rebuild');
  
And you can set values the same two ways:

  $config->your_manager_for_today( $person->id );
  $config->set( your_manager_for_today => $person->id );

There are two big fat red flags to consider when setting values this way:

=over

=item This configuration object is shared by every request handler, data class and template that makes use of this factory. In practice that means that changes affect every visitor to the site, not just the present one (mumble within this apache process mumble).

=item If a configuration file is updated on disk, the configuration object will be torn down and rebuilt. Any changes you have made by calling set() will be lost.

=back

You can call the tethered AppConfig object directly through $config->ac, if you must.

=head2 get()
  
Gets the named value.

=head2 set()
  
Sets the named value.

=head2 all()

returns a simple list of all the variable names held.

=head2 classes()

returns the list of classes we're supposed to load. This is just for readability: all it does is call get('class'), but it allows us to write:

  $factory->config->classes
  
instead of the rather misleading:

  $factory->config->class

  
=cut

sub get {
	return shift->ac->get(@_);
}

sub set {
	return shift->ac->set(@_);
}

sub all {
	return shift->ac->varlist;
}

sub classes {
	return shift->get('class');
}

=head2 template_path()

It's normal for a subclass to add lots of custom lookup methods that combine configuration settings in useful ways. This is the only one we need at this level. It returns a reference to an array of directories in which to look for TT templates.

These can be defined in two ways: directly, with a 'template_dir' parameter, or in two stages, with a 'template_root' and one or more 'template_subdir' parameters.

Sequence is important, since the first encountered instance of a template will be used. The order of definition is preserved (so site file > package file > global file), except that all template_dir values are given priority over all template_subdir values: the former would normally be defined by a standard package, the latter by local site configuration.

=cut

sub template_path {
    my $self = shift;
    my $tdirs = $self->get('template_dir');
    my $troot = $self->get('template_root');
    my $tsubdirs = $self->get('template_subdir');
    
    my @path = @$tdirs;
    push @path, map { "$troot/$_" } reverse @$tsubdirs if $troot;
    return \@path;
}

sub AUTOLOAD {
	my $self = shift;
	my $key = shift;
	my $method_name = $AUTOLOAD;
	$method_name =~ s/.*://;
    return if $method_name eq 'DESTROY';
    return unless $self->ac;
    my %hashed = map { $_=> 1} $self->hash_parameters;
    return $self->ac->$method_name()->{ $key } if $key && $hashed{$method_name}; 
	return $self->ac->$method_name();
}

sub ac {
    my $self = shift;
    return $self->{ac} = $_[0] if @_;
    return $self->{ac} || $self->_new_ac;
}

=head2 _new_ac()

Forces the creation of a new, empty AppConfig object. This should only ever be called during a build or rebuild.

=cut

sub _new_ac {
    my $self = shift;
    return $self->{ac} = AppConfig->new( $self->skeleton );
}

=head1 SEE ALSO

L<AppConfig> L<Class::DBI> L<Class::DBI::Factory> L<Class::DBI::Factory::Handler> L<Class::DBI::Factory::List>

=head1 AUTHOR

William Ross, wross@cpan.org

=head1 COPYRIGHT

Copyright 2001-4 William Ross, spanner ltd.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
