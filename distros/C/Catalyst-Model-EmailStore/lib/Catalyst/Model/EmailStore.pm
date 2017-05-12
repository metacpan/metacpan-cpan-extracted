package Catalyst::Model::EmailStore;

use warnings;
use strict;
use base qw/Catalyst::Base/;
use NEXT;
use Data::Dumper;
use Scalar::Util;
use Clone qw();

our $VERSION = '0.03';

=head1 NAME

Catalyst::Model::EmailStore - Email::Store Model Class

=head1 SYNOPSIS

    # use the helper
    create model EmailStore EmailStore dsn user password

    # lib/MyApp/Model/EmailStore.pm
    package MyApp::Model::EmailStore;

    use base 'Catalyst::Model::EmailStore';

    __PACKAGE__->config(
        dsn                    => 'dbi:Pg:dbname=myapp',
        password               => '',
        user                   => 'postgres',
        options                => { AutoCommit => 1 },
        cdbi_plugins           => [ qw/AbstractCount Pager/ ],
        upgrade_relationships  => 1
    );

    1;

    # As object method
    $c->model('EmailStore::Address')->search(...);

    # As class method
    MyApp::Model::EmailStore::Adress->search(...);

=head1 DESCRIPTION

This is the C<Email::Store> model class. It will automatically
subclass all model classes from the C<Email::Store> namespace
and import them into your application. For this purpose a class
is considered to be a model if it descends from C<Email::Store::DBI>.

This class is also doing its best to upgrade the relationships of
all Email::Store models (i.e. MyApp::Model::EmailStore::Entity::Name
will have many MyApp::Model::EmailStore::Addressing objects instead
of Email::Store::Addressing ones). But be warned that this will not
affect event handlers in any way. If you want to extend or modify
these you are still stuck in the Email::Store namespace
unfortunatly.

=head1 CAVEATS

Due to limitations in the design of Email::Store the main model class
(e.g. MyApp::Model::EmailStore) is not part of the inheritance chain
that leads up to Class::DBI so you can't use any CDBI plugins there.
To alleviate this problem a config option named I<cdbi_plugins> is
provided. All classes named therein (without the mandatory
C<Class::DBI::Plugin> prefix) will be required and imported
into C<Email::Store::DBI>.

Also I've take the liberty to remove the overloading of 'bool' that is
done automatically by CDBI and would cause $c->model( 'XXX' ) to fail.

Upgrading relationships is dependent on an internal Class::DBI structure
called '__meta_info'. This structure might change in the future or might
already have changed in the course of CDBI development, so be prepared
to experience breakage if this model is used with any version of
Class::DBI except 3.0.1.

I also suggest that you keep your Email::Store tables in
their own database and separate from your other tables

=head1 METHODS

=head2 new

Initializes Email::Store::DBI and loads model classes according to
Email::Store->plugins. Actually it reimplements the plugin
mechanism of Email::Store so you are on your own if you rely on
modifications to this class itself. Also attempts to borg
all the classes.

=cut

BEGIN {

  require Email::Store::DBI;
  require Module::Pluggable::Ordered;

  {

	 #BUG: this doesn't allow to refine plugins in the Catalyst model
	 #BUG: but I really don't know how to fix this

	 sub Email::Store::call_plugins {
		shift; Catalyst::Model::EmailStore->call_plugins( @_ );
	 }

	 package Email::Store::DBI;
	 sub _cataylst_model_email_store_import_hook {
		my $class = shift;
		my $to_import = shift;
		$to_import->import(@_);
	 };

	 # remove overloading of bool done by CDBI which will cause
    # problems with $c->model and maybe other stuff as well
	 use overload bool => sub { $_[0] };
  }

}

sub new {
  my $class = shift;
  my $self  = $class->NEXT::new( @_ );
  my $c     = shift;
  my $prefix = $c  . '::Model::EmailStore';

  return bless {%$self}, $class if $class =~ /^$prefix\::/;

  my %p = %{ $self };

  my $caller = caller();

  Module::Pluggable::Ordered->import
		( inner => 1, search_path => [ "Email::Store" ] );
  Email::Store::DBI->import( @p{ qw/dsn user password options/ } );


  # exclude Email::Store::DBI which is wrongly detected as plugin of
  # Email::Store and import only model classes (i.e. E::S::DBI descendants)
  # from this namespace

  my @models = grep{
	 $_ ne qw/Email::Store::DBI/ and $_->isa( qw/Email::Store::DBI/ );
  } __PACKAGE__->plugins;

  for my $plugin ( @models ) {
	 no strict 'refs';
	 $plugin->require;
	 my $model = $plugin;
	 $model =~ s/^Email::Store/$prefix/;
	 @{"$model\::ISA"} = ( $plugin, ref( $self ) );
    *{"$model\::new"} = sub { bless {%$self}, $model };
	 $c->components->{$model} ||= $model->new();
  }

  $c->log->info( "Loaded Email::Store models: @models" ) if $c->debug;

  if ( $self->{upgrade_relationships} ) {
	 # upgrade table relationships
	 require Clone;
	 for my $plugin ( @models ) {
		my $model = $plugin;
		$model =~ s/^Email::Store/$prefix/;

		$c->log->debug( "Upgradin relationships of $model" ) if $c->debug;

		# create a clean copy of table meta information
		my $meta = $model->__meta_info( Clone::clone( $plugin->__meta_info ) );

		# use a recursive anonymous sub to change all keys that describe
		# class relationships from Email::Store to the newly created
		# Catalyst models
		my $recursive_upgrade;
		$recursive_upgrade = sub {
		  my $href = shift;
		  my $changes = 0;
		  for ( keys %{ $href } ) {
			 if ( ref($href->{$_}) eq 'HASH' ) {
				$changes += &$recursive_upgrade($href->{$_});
				next;
			 }
			 if ( Scalar::Util::blessed($href->{$_}) ) {
				$changes += &$recursive_upgrade($href->{$_});
				# if we encountered a relationship we have to
				# reinitialize it so that the correct accessors will
				# be created
				next unless $changes;
				if ( $href->{$_}->isa( qw/Class::DBI::Relationship/ ) ) {
				  $href->{$_}->_set_up_class_data;
				  $href->{$_}->_add_triggers;
				  $href->{$_}->_add_methods;
				}
				# all changes to this relationship have been done
				# so we can reset our counter here ( relationships
				# can't be nested as far as I know )
				$changes = 0;
			 }
			 if ( $_ =~ /class$/ ) {
				$changes += ( $href->{$_} =~ s/Email::Store/$prefix/ );
			 }
		  }
		  return $changes;
		};
		&$recursive_upgrade( $meta );
	 }
  }

  # pull in the requested cdbi plugins
  if ( exists( $self->{cdbi_plugins} ) ) {
	 my @cdbi_plugins = map{"Class::DBI::Plugin::$_"} @{$self->{cdbi_plugins}};
	 for my $plugin ( @cdbi_plugins ) {
		$plugin->require;
		Email::Store::DBI->_cataylst_model_email_store_import_hook( $plugin );
	 }
	 $c->log->info( "Loaded CDBI plugins for Email::Store: @cdbi_plugins" )
		if $c->debug;
  }

  return $self;
}

1;

__END__

=head1 BUGS

Probably many as this is the initial release.

=head1 SEE ALSO

L<Catalyst>, L<Email::Store>

=head1 AUTHOR

Sebastian Willert <willert@cpan.org>

Many thanks to Brian Cassidy <bricas@cpan.org> for inspiration and help
with bringing this class to CPAN.

=head1 COPYRIGHT

Copyright (C) 2005 by Sebastian Willert

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

