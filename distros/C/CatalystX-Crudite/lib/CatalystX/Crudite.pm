package CatalystX::Crudite;
use Moose;
use namespace::autoclean;
use File::ShareDir qw(dist_dir);
use CatalystX::Resource v0.6.1;
use CatalystX::Crudite::Util qw(merge_configs);
use Web::Library;
extends 'Catalyst';
our $VERSION = '0.21';
our @IMPORT  = qw(
  ConfigLoader
  Static::Simple
  +CatalystX::Resource
  +CatalystX::SimpleLogin
  Authentication
  Authorization::Roles
  Session
  Session::Store::FastMmap
  Session::State::Cookie
);

sub config_app {
    my ($class, %args) = @_;
    my $app_name        = $args{name};
    my $crudite_config  = delete $args{'CatalystX::Crudite'} // {};

    # load web libraries
    my $library_manager = Web::Library->instance;
    my @libs = qw(Bootstrap jQuery jQueryUI DataTables);
    for my $lib (@libs) {
        my $lib_args = $crudite_config->{web_library}{$lib} // {};
        $library_manager->mount_library({ name => $lib, %$lib_args });
    }

    # merge given config with our default config
    my %config = (

        # Disable deprecated behavior needed by old applications
        disable_component_resolution_regex_fallback => 1,
        encoding                                    => 'UTF-8',
        enable_catalyst_header => 1,    # Send X-Catalyst header
        'Plugin::Static::Simple' =>
          { include_path => [ $library_manager->include_paths ] },
        'Plugin::Session'        => { flash_to_stash => 1 },
        'Plugin::Authentication' => {
            default => {
                store => {
                    class         => 'DBIx::Class',
                    user_model    => 'DB::User',
                    role_relation => 'roles',
                    role_field    => 'name',
                },
                credential => {
                    class          => 'Password',
                    password_field => 'password',
                    password_type  => 'self_check',
                },
            },
        },
        'Controller::Login' => {
            traits          => ['-RenderAsTTTemplate'],
            login_form_args => { authenticate_username_field_name => 'name' }
        },
        'Model::DB' => {
            schema_class => "${app_name}::Schema",
            connect_info => {
                dsn => 'dbi:SQLite:dbname='
                  . __PACKAGE__->path_to(lc "${app_name}.db"),
                sqlite_unicode => 1,
            },
        },
    );
    my $merged_config = merge_configs(\%config, \%args);
    $class->config(%$merged_config);
}
1;

=pod

=for stopwords CMS CatalystX Crudite

=head1 NAME

CatalystX::Crudite - Framework for Catalyst-based CMS Web Applications

=head1 SYNOPSIS

   $ crudite-starter MyApp
   $ cd MyApp
   $ ./test.sh
   $ ./script/db_deploy.pl
   $ ./script/myapp_server.pl

   # log in with username 'admin' and password 'admin'
   # enjoy

   ...

   # later
   $ ./script/myapp_crudite_create.pl resource Article

=head1 DESCRIPTION

CatalystX-Crudite is a framework for writing Catalyst-based CMS web
applications. It includes out-of-the-box user and role management
and many starter templates. It builds upon L<CatalystX-Resource> and
L<CatalystX-SimpleLogin>.

In order for C<crudite_starter> to work, you need to install this distribution.
The starter templates are stored as per-dist shared files using
C<File::ShareDir>, so they can't be found from the uninstalled repository. I
hope to improve this in a later version.

=head1 CONFIGURATION

The user can specify extra args for web libraries such as specific versions.
Example:

    __PACKAGE__->config_app(
        name                     => 'MyApp',
        'CatalystX::Crudite'     => {
            web_library => {
                Bootstrap => { version => '2.3.2' },
            },
        },
        # other standard Catalyst config such as:
        'Plugin::Static::Simple' => {
            include_path => [ __PACKAGE__->path_to(qw(root static)), \&dir2 ],
            ignore_extensions => [qw(tmpl tt tt2 xhtml)]
        }
    );

By default the latest versions of the web libraries - Bootstrap, jQuery,
jQueryUI and DataTables - are laoded.

=head1 AUTHORS

The following person is the author of all the files provided in
this distribution unless explicitly noted otherwise.

Marcel Gruenauer C<< <marcel@cpan.org> >>, L<http://marcelgruenauer.com>

=head1 COPYRIGHT AND LICENSE

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

This software is copyright (c) 2013-2014 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

