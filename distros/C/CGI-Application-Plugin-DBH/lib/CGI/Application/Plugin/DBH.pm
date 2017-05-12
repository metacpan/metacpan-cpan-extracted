package CGI::Application::Plugin::DBH;
{
  $CGI::Application::Plugin::DBH::VERSION = '4.04';
}
use parent 'Exporter';

# ABSTRACT: Easy DBI access from CGI::Application

use strict;
use Carp;

our @EXPORT_OK = qw(
    dbh
    dbh_config
    dbh_default_name
);

sub dbh {
    my $self = shift;
    my $name = shift;

    $self->{__DBH_DEFAULT_NAME} ||= "__cgi_application_plugin_dbh";     # First use case.
    $name ||= $self->{__DBH_DEFAULT_NAME};                              # Unnamed handle case.

    unless ($self->{__DBH_CONFIG}{$name}){
        __auto_config($self, $name);
        croak "must call dbh_config() before calling dbh()." unless $self->{__DBH_CONFIG}{$name};
    }

    unless( defined($self->{__DBH}{$name}) && $self->{__DBH}{$name}->ping ) {
        # create DBH object
        if(my $config = $self->{__DBH_CONFIG}{$name} ) {
            # Use a callback
            if (ref $config && ref $config eq 'CODE') {
                $self->{__DBH}{$name} = $config->();
            }
            # use the parameters the user supplied
            else {
                require DBI;
                $self->{__DBH}{$name} = DBI->connect(@{ $self->{__DBH_CONFIG}{$name} });
            }
        } else {
        }
    }

    return $self->{__DBH}{$name};
}

sub dbh_config {
    my $self = shift;

    $self->{__DBH_DEFAULT_NAME} ||= "__cgi_application_plugin_dbh";     # First use case.

    my $name = shift if( ref($_[1]) );
    $name ||= $self->{__DBH_DEFAULT_NAME};                              # Unnamed handle case.

    croak "Calling dbh_config after the dbh has already been created" if( defined $self->{__DBH}{$name} );

    # See if a handle is being passed in directly.
    require UNIVERSAL;
    if( ref($_[0]) eq 'ARRAY' or ref $_[0] eq 'CODE' ) {
        $self->{__DBH_CONFIG}{$name} = shift;
    }
    elsif( ref($_[0]) and $_[0]->isa('DBI::db') ) {
        $self->{__DBH}{$name} = shift;

        # Set this to note that we have completed the 'config' stage.
        $self->{__DBH_CONFIG}{$name} = 1;
    }
    else {
        $self->{__DBH_CONFIG}{$name} = \@_;
    }

}

sub __auto_config {
    # get parameters for dbh_config from CGI::App instance parameters
     my $app = shift;
     my $name = shift;


     my $params = $app->param('::Plugin::DBH::dbh_config');
     return __auto_config_env($app, $name) unless $params;

     # if array reference: only one handle configured, pass array contents to dbh_config
     if (UNIVERSAL::isa($params, 'ARRAY')){
        # verify that we really want the default handle
        return unless $name eq dbh_default_name($app);
        dbh_config($app, @$params);
        return;
     }

     # if hash reference: many handles configured, named with the hash keys
     if (UNIVERSAL::isa($params, 'HASH')){
        $params = $params->{$name};
        return __auto_config_env($app, $name) unless $params;
        dbh_config($app, $name, $params);
        return;
     }

    croak "Parameter ::Plugin::DBH::dbh_config must be an array or hash reference";
}

sub __auto_config_env{
    # check if DBI environment variable is set
    # this can be used to configure the default handle
    my $app = shift;
    my $name = shift;

    return unless $name eq dbh_default_name($app);
    return unless $ENV{DBI_DSN};
    # DBI_DSN is set, so autoconfigure with all DSN, user id, pass all undefined
    dbh_config($app, undef, undef, undef);
}

sub dbh_default_name {
    my $self = shift;
    my $old_name = $self->{__DBH_DEFAULT_NAME} || "__cgi_application_plugin_dbh"; # Possible first use case.
    $self->{__DBH_DEFAULT_NAME} = shift if $_[0];
    return $old_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CGI::Application::Plugin::DBH - Easy DBI access from CGI::Application

=head1 VERSION

version 4.04

=head1 SYNOPSIS

 use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);

 sub cgiapp_init  {
    my $self = shift;

    # use the same args as DBI->connect();
    $self->dbh_config($data_source, $username, $auth, \%attr);

    # or to use more than one dbh
    $self->dbh_config('my_handle',
            [ $data_source, $user, $auth, \%attr ]);
    $self->dbh_config('my_other_handle',
            [ $data_source, $user, $auth, \%attr ]);
 }

 sub my_run_mode {
    my $self = shift;

    my $date = $self->dbh->selectrow_array("SELECT CURRENT_DATE");
    # again with a named handle
    $date = $self->dbh('my_handle')->selectrow_array("SELECT CURRENT_DATE");

    # OR ...

    my $dbh = $self->dbh;
    # again with a named handle
    $dbh = $self->dbh('my_other_handle');
    my $date = $dbh->selectrow_array("SELECT CURRENT_DATE");
 }

=head1 DESCRIPTION

CGI::Application::Plugin::DBH adds easy access to a L<DBI> database handle to
your L<CGI::Application> modules.  Lazy loading is used to prevent a database
connection from being made if the C<dbh> method is not called during the
request.  In other words, the database connection is not created until it is
actually needed.

=head1 METHODS

=head2 dbh()

 my $date = $self->dbh->selectrow_array("SELECT CURRENT_DATE");
 # again with a named handle
 $date = $self->dbh('my_handle')->selectrow_array("SELECT CURRENT_DATE");

 # OR ...

 my $dbh = $self->dbh;
 # again with a named handle
 $dbh = $self->dbh('my_other_handle');
 my $date = $dbh->selectrow_array("SELECT CURRENT_DATE");

This method will return the current L<DBI> database handle.  The database handle is created on
the first call to this method, and any subsequent calls will return the same handle.

=head2 dbh_config()

 sub cgiapp_init  {
    my $self = shift;

    # use the same args as DBI->connect();
    $self->dbh_config($data_source, $username, $auth, \%attr);

    # or to use more than one dbh
    $self->dbh_config('my_handle',
            [ $data_source, $user, $auth, \%attr ]);
    $self->dbh_config('my_other_handle',
            [ $data_source, $user, $auth, \%attr ]);

    # ...or use some existing handle you have
    $self->dbh_config($DBH);
    $self->dbh_config('my_handle', $DBH);   # this works too

    # Use a callback to create your owh handle that is still lazy loaded
    $self->dbh_config(sub { DBI->connect_cached(); });
 }

Used to provide your DBI connection parameters. You can either pass in an existing
DBI database handle, or provide the usual parameters used for DBI->connect().

The recommended place to call C<dbh_config> is in the C<cgiapp_init>
stage of L<CGI::Application>.  If this method is called after the database handle
has already been accessed, then it will die with an error message.

=head3 Automatic configuration using CGI::App instance parameters

An alternative to explicitly calling C<dbh_config> in your application
is to rely on the presence of specific instance parameters that allow the
plugin to configure itself.

If you set the CGI::App parameter C<::Plugin::DBH::dbh_config> to
an array reference the contents of that array will be used as parameters to
C<dbh_config> (if it has not been explicitly called before).

The code in the synopsis can be rewritten as

  use CGI::Application::Plugin::DBH (qw/dbh/);
    # no longer a need to import dbh_config

  sub cgiapp_init  {
     # you do not need to do anything here
  }

  sub my_run_mode {

    # this part stays unchanged

    ....

  }

and in the instance script ( or instance configuration file, if you have)

   $app->param('::Plugin::DBH::dbh_config' =>
        [ $data_source, $username, $auth, \%attr ] );

If you want to configure more than one handle, set up a hash with the handle names
as keys:

    $app->param('::Plugin::DBH::dbh_config' =>
        { my_handle => [ $data_source, $username, $auth, \%attr ] ,
          my_other_handle => [ $data_source, $username, $auth, \%attr ]
        }  );

=head3 Automatic configuration with DBI environment variables

If you do not set any parameters, and do not call C<dbh_config>, this plugin
checks to see if you set the DBI environment variable C<DBI_DSN>. If present,
this DSN will be used for the default handle. Note that the DBI documentation
does not encourage using this method (especially in the context of web applications),
that you will most likely have to also set C<DBI_USER> and C<DBI_PASS>, and
that this can only be used for the default handle.

=head2 dbh_default_name()

 sub my_runmode {
    my $self = shift;

    my $old_handle_name = $self->dbh_default_name('my_handle');
    $self->some_legacy_code();  # some_legacy_code() will get "my_handle"
                                # when it calls $self->dbh() without parameters

    $self->dbh_default_name($old_handle_name);    # Return to normal.
 }

Can be used to alter the name of the handle that is returned by dbh() when
called with no parameters. It can even be used to alter the name used for the
unnamed handle if called before dbh_config().

Using this method is completely optional. If you don't have a use for it don't
use it. Internally the handle name "__cgi_application_plugin_dbh" is used to
keep track of the unnamed handle unless it is changed by dbh_default_name()
before a call to dbh_config() without a name parameter.

=head1 SEE ALSO

L<Ima::DBI> is similar, but has much more complexity and features.

L<CGI::Application>, L<DBI>, L<CGI::Application::Plugin::ValidateRM>

=head1 AUTHOR

Mark Stosberg <mark@stosberg.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Stosberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
