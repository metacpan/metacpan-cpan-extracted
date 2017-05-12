package Dancer2::Plugin::DBIC;

our $VERSION = '0.0013'; # VERSION

use strict;
use warnings;
use utf8;
use Dancer2::Plugin;
use DBICx::Sugar;

sub _schema {
    my ($dsl, $name) = @_;
    my $config;
    # ugly switch needed to support plugin2 plugins which use this plugin
    # whilst still working for plugin1
    if ( $dsl->app->can('with_plugin') ) {
        $config = $dsl->config;
    }
    else {
        $config = plugin_setting;
    }
    DBICx::Sugar::config( $config );
    return DBICx::Sugar::schema($name);
};

sub _rset {
    my ($dsl, $rset_name) = @_;
    return schema($dsl)->resultset($rset_name);
}

register schema    => \&_schema;
register resultset => \&_rset;
register rset      => \&_rset;
register_plugin;

# ABSTRACT: DBIx::Class interface for Dancer2 applications


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::DBIC - DBIx::Class interface for Dancer2 applications

=head1 VERSION

version 0.0013

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::DBIC qw(schema resultset rset);

    get '/users/:user_id' => sub {
        my $user = schema('default')->resultset('User')->find(param 'user_id');

        # If you are accessing the 'default' schema, then all the following
        # are equivalent to the above:
        $user = schema->resultset('User')->find(param 'user_id');
        $user = resultset('User')->find(param 'user_id');
        $user = rset('User')->find(param 'user_id');

        template user_profile => {
            user => $user
        };
    };

    dance;

=head1 DESCRIPTION

This plugin makes it very easy to create L<Dancer2> applications that interface
with databases.
It automatically exports the keyword C<schema> which returns a
L<DBIx::Class::Schema> object.
You just need to configure your database connection information.
For performance, schema objects are cached in memory
and are lazy loaded the first time they are accessed.

This plugin is a thin wrapper around L<DBICx::Sugar>.

=head1 CONFIGURATION

Configuration can be done in your L<Dancer2> config file.
This is a minimal example. It defines one database named C<default>:

    plugins:
      DBIC:
        default:
          dsn: dbi:SQLite:dbname=some.db

In this example, there are 2 databases configured named C<default> and C<foo>:

    plugins:
      DBIC:
        default:
          dsn: dbi:SQLite:dbname=some.db
          schema_class: MyApp::Schema
        foo:
          dsn: dbi:mysql:foo
          schema_class: Foo::Schema
          user: bob
          password: secret
          options:
            RaiseError: 1
            PrintError: 1

Each database configured must at least have a dsn option.
The dsn option should be the L<DBI> driver connection string.
All other options are optional.

If you only have one schema configured, or one of them is named
C<default>, you can call C<schema> without an argument to get the only
or C<default> schema, respectively.

If a schema_class option is not provided, then L<DBIx::Class::Schema::Loader>
will be used to dynamically load the schema by introspecting the database
corresponding to the dsn value.
Remember that you need L<DBIx::Class::Schema::Loader> installed to take
advantage of that.

The schema_class option, should be a proper Perl package name that
Dancer2::Plugin::DBIC will use as a L<DBIx::Class::Schema> class.
Optionally, a database configuration may have user, password, and options
parameters as described in the documentation for C<connect()> in L<DBI>.

You may also declare your connection information in the following format
(which may look more familiar to DBIC users):

    plugins:
      DBIC:
        default:
          connect_info:
            - dbi:mysql:foo
            - bob
            - secret
            -
              RaiseError: 1
              PrintError: 1

=head1 FUNCTIONS

=head2 schema

    my $user = schema->resultset('User')->find('bob');

The C<schema> keyword returns a L<DBIx::Class::Schema> object ready for you to
use.
If you have configured only one database, then you can simply call C<schema>
with no arguments.
If you have configured multiple databases,
you can still call C<schema> with no arguments if there is a database
named C<default> in the configuration.
With no argument, the C<default> schema is returned.
Otherwise, you B<must> provide C<schema()> with the name of the database:

    my $user = schema('foo')->resultset('User')->find('bob');

=head2 resultset

This is a convenience method that will save you some typing.
Use this B<only> when accessing the C<default> schema.

    my $user = resultset('User')->find('bob');

is equivalent to:

    my $user = schema->resultset('User')->find('bob');

=head2 rset

    my $user = rset('User')->find('bob');

This is simply an alias for C<resultset>.

=head1 SCHEMA GENERATION

There are two approaches for generating schema classes.
You may generate your own L<DBIx::Class> classes and set
the corresponding C<schema_class> setting in your configuration as shown above.
This is the recommended approach for performance and stability.

It is also possible to have schema classes dynamically generated
if you omit the C<schema_class> configuration setting.
This requires you to have L<DBIx::Class::Schema::Loader> installed.
The C<v7> naming scheme will be used for naming the auto generated classes.
See L<DBIx::Class::Schema::Loader::Base/naming> for more information about
naming.

For generating your own schema classes,
you can use the L<dbicdump> command line tool provided by
L<DBIx::Class::Schema::Loader> to help you.
For example, if your app were named Foo, then you could run the following
from the root of your project directory:

    dbicdump -o dump_directory=./lib Foo::Schema dbi:SQLite:/path/to/foo.db

For that example, your C<schema_class> setting would be C<Foo::Schema>.

=head1 SEE ALSO

=over 4

=item *

L<DBICx::Sugar>

=back

=head1 CONTRIBUTORS

=over 4

=item *

Alexis Sukrieh <sukria@sukria.net>

=item *

Dagfinn Ilmari Mannsåker <L<https://github.com/ilmari>>

=item *

David Precious <davidp@preshweb.co.uk>

=item *

ennio <L<https://github.com/scriplit>>

=item *

Fabrice Gabolde <L<https://github.com/fgabolde>>

=item *

Franck Cuny <franck@lumberjaph.net>

=item *

Steven Humphrey <L<https://github.com/shumphrey>>

=item *

Yanick Champoux <L<https://github.com/yanick>>

=back

=head1 AUTHOR

Naveed Massjouni <naveed@vt.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
