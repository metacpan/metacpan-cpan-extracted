package CGI::Application::Plugin::DBIC::Schema;

use strict;
use vars qw($VERSION @ISA  @EXPORT_OK);
use Carp;
require Exporter;
@ISA = qw(Exporter);

# "Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants."
# -- quote from M. Stosberg in ::Plugin::DBH
@EXPORT_OK = qw(
  schema
  dbic_config
  resultset
  rs
);

$VERSION = '0.3';

#
# This name will be used for 'default' schema (i.e., when no name is supplied.)
#
use constant DEFAULT_CONFIG_NAME => "__cgi_application_plugin_dbic_schema";

sub schema {
    my $self = shift;
    my $name = shift;

    # Establish a default config name for the cgi::app
    $self->{__DBIC_SCHEMA_DEFAULT_NAME} ||= DEFAULT_CONFIG_NAME;

    # Use the default name if no  name was supplied.
    $name ||= $self->{__DBIC_SCHEMA_DEFAULT_NAME};    # Unamed handle case.

    croak "must call dbic_config() before calling schema()."
      unless $self->{__DBIC_SCHEMA_CONFIG}{$name};

    unless ( defined( $self->{__DBIC_SCHEMA}{$name} ) ) {
        my $schema = $self->{__DBIC_SCHEMA_CONFIG}{$name}->{schema};

        #TODO Allow use of a DBI handle in place of a config
        my @con_info = @{ $self->{__DBIC_SCHEMA_CONFIG}{$name}->{connect_info} };
        eval { "require $schema;" } or die "Cannot require $schema: $@";
        $self->{__DBIC_SCHEMA}{$name} = $schema->connect(@con_info);
    }

    return $self->{__DBIC_SCHEMA}{$name};
}

sub dbic_config {
    my $self = shift;

    croak "too many parameters passed to dbic_config." if ( @_ > 2 );
    my ( $name, $config );
    if ( @_ == 2 ) {
        ( $name, $config ) = @_;
    }
    elsif ( @_ == 1 ) {
        $config = shift;
    }
    else {
        croak "no config passed to dbic_config";
    }

    # TODO Allow config to  be a DBI::db handle as alternative
    croak "config must be hashref" unless ref $config eq 'HASH';

    $self->{__DBIC_SCHEMA_DEFAULT_NAME} ||= DEFAULT_CONFIG_NAME;    # First use case.
    $name ||= $self->{__DBIC_SCHEMA_DEFAULT_NAME};    # Unamed handle case.

    croak "Calling dbic_config after the dbic has already been created"
      if ( defined $self->{__DBIC_SCHEMA}{$name} );

    $self->{__DBIC_SCHEMA_CONFIG}{$name} = $config;

}

sub resultset {
    my $c = shift;

    my $param_count = scalar(@_);
    croak "Too many parameters passed to resultset" if ( $param_count > 2 );
    croak "Too few parameters passed to resultset"  if ( $param_count == 0 );

    my ( $config_name, $resultset_name, $result );
    if ( $param_count == 2 ) {
        ( $config_name, $resultset_name ) = @_;

        # allow undef config name (use default), but require result class name
        croak "resultset class name must be defined"
          if ( !defined($resultset_name) );

        $result = $c->schema($config_name)->resultset($resultset_name);
    }
    else {
        $resultset_name = shift;
        croak "resultset class name must be defined"
          if ( !defined($resultset_name) );
        $result = $c->schema()->resultset($resultset_name);
    }
    return $result;
}

# short form
*rs = \&resultset;

1;
__END__

=head1 NAME

CGI::Application::Plugin::DBIC::Schema - Easy DBIx::Class access from CGI::Application, inspired by CGI::Application::Plugin::DBH.

=head1 SYNOPSIS

    use CGI::Application::Plugin::DBIC::Schema (qw/dbic_config schema resultset rs/);

    sub cgiapp_init{

            my $c = shift;

            my $dsn = $c->param('dsn');
            my $dbpw = $c->param('dbpw');
            my $dbuser = $c->param('dbuser');

            # Provide a default config.

            $c->dbic_config({schema=>"My::DB",                  # DBIC class
                             connect_info=>[$dsn,$dbuser,$dbpw] # use same args as DBI connect
                            });


    }


    sub setup {

            my $c = shift;

            $c->start_mode('runmode1');
            $c->run_modes([qw/runmode1 runmode2/]);
    }

    sub runmode1 {

            my $c = shift;

            my $id = $c->param('id);
            $c->resultset("My::DB::DemoTable")->find($id);
            
            # do something with the object ...

            return "found it.";
    }

    sub runmode2 {

            my $c = shift;
            
            $c->schema()->resultset("My::DB::DemoTable")
                ->create({name=>"John Doe", address=>"Any Street"});

            return "created it";
    }



=head1 DESCRIPTION

CGI::Application::Plugin::DBIC::Schema adds easy access to a L<DBIx::Class::Schema|DBIx::Class::Schema> to
your L<Titanium|Titanium> or L<CGI::Application|CGI::Application> modules.  Lazy loading is used to prevent a database
connection from being made if the C<schema> method is not called during the
request.  In other words, the database connection is not created until it is
actually needed. 

DBIx::Class has lots of dependencies, and therefore a certain length of compile time, but it works fine in a CGI environment for low volume sites.  If you expect a high volume of traffic, think about FastCGI or other alternatives. 

=head1 METHODS

=head2 schema($name?)


This method will return the default L<DBIx::Class::Schema|DBIx::Class::Schema> instance if no name  is provided.  Provide a schema name to retrieve an alternate schema.  The schema instance is created on the first call to this method, and any subsequent calls will return the same instance. 

  my $schema = $c->schema();                 # gets default (unnamed) schema
  
  # Or ...
  
  my $schem = $c->schema('my_schema_name');  # gets one of named schemas

=head2 dbic_config($name?, \%connect_info)


Used to provide your DBIx::Class::Schema class name, an optional config name, and DBI connection parameters.  For \%config_info 
supply the same parameter list that you would for DBI::connect.  You may also supply DBIx::Class specifig attributes.  For that see L<DBIx::Class::Storage::DBI|DBIx::Class::Storage::DBI> for details.

The recommended place to call C<dbic_config> is in the C<cgiapp_init>
stage of L<CGI::Application|CGI::Application>.  If this method is called after the dbic() method
has already been accessed, then it will die with an error message.

        # Setup  default schema config
        
	$c->dbic_config({schema=>"My::DB",                  # DBIC class
			 connect_info=>[$dsn,$dbuser,$dbpw] # use same args as DBI connect
			});

	# Or, provide additional configs by name.

	$c->dbic_config("another_config",
			{schema=>"My::Other::DB",
			 connect_info=>[$dsn,$dbuser,$dbpw]
			});

=head2 resultset($config_name?,$resultset_classname)

An alias to $c->schema(...)->resultset(...).

This method provides DBIx::Class::Resultset access.


   # Use the default dbic schema via 'resultset'. 

   $c->resultset("DBICT::Result::Test")->find($id);


   # Or use a named config to access resultset via an alternative schema.

   $c->resultset('another_config', "DBICT::Result::Test")->find($id);

   # Or use alias short form, 'rs' with default config

   $c->rs("DBICT::Result::Test")->find($id);

   # Or use alias short form with alternate config/schema

   $c->rs('yet_another_schema', "DBICT::Result::Test")->find($id);




=head2 rs

An alias to resultset



=head1 SEE ALSO

L<DBIx::Class|DBIx::Class>, L<Titanium|Titanium>, L<CGI::Application|CGI::Application>,L<CGI::Application::Plugin::DBH|CGI::Application::Plugin::DBH>

=head1 AUTHOR

Gordon Van Amburg <gordon@minipeg.net>

=head1 LICENSE

Copyright (C) 2009 Gordon Van Amburg <gordon@minipeg.net>

This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=cut
