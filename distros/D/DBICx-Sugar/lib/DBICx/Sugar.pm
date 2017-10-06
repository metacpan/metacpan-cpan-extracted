package DBICx::Sugar;

use strict;
use warnings;
use Carp qw(croak);
use Exporter qw(import);
use Module::Load;
use YAML qw(LoadFile);

our $VERSION = '0.0200'; # VERSION

our @EXPORT_OK = qw(config get_config add_schema_to_config rset resultset schema);

my $_config;
my $_schemas = {};

sub config {
    my ($data) = @_;
    if ($data) {
        croak 'config data must be a hashref' unless 'HASH' eq ref $data;
        $_config = $data;
    }
    return $_config if $_config;
    my $config_path;
    if (-f 'config.yaml') {
        $config_path = 'config.yaml';
    } elsif (-f 'config.yml') {
        $config_path = 'config.yml';
    } else {
        croak "could not find a config.yml or config.yaml file";
    }
    return $_config = LoadFile($config_path)->{dbicx_sugar};
}

sub get_config { return $_config; }

sub add_schema_to_config {
    my ($schema_name, $schema_data) = @_;
    croak "Schema name $schema_name already exists"
        if exists $_config->{$schema_name};
    croak "Schema data must be a hashref (schema name: $schema_name)"
        unless 'HASH' eq ref $schema_data;
    $_config->{$schema_name} = $schema_data;
}

sub schema {
    my ( $name, $schema_cfg ) = @_;

    my $cfg = config();

    # We weren't asked for a specific name
    # try to get one from the default config
    if (not defined $name) {
        my @names = keys %{$cfg}
            or croak("No schemas are configured");

        # Either pick the only one in the config or the default
        $name = @names == 1 ? $names[0] : 'default';
    }

    my $options = $cfg->{$name}
        or croak("The schema $name is not configured");

    # Schema specific configuration from the user
    if ($schema_cfg) {
        # Just return a new schema and do not save it
        return _create_schema( $name, $schema_cfg );
    }

    # Return existing schemas, either by name
    return $_schemas->{$name} if $_schemas->{$name};

    # Or by alias
    if ( my $alias = $options->{alias} ) {
        $options = $cfg->{$alias}
            or croak("The schema alias $alias does not exist in the config");
        return $_schemas->{$alias} if $_schemas->{$alias};
    }

    # Create schema
    my $schema = _create_schema( $name, $options );

    return $_schemas->{$name} = $schema;
}

sub resultset {
    my ($rset_name) = @_;
    return schema()->resultset($rset_name);
}

sub rset { goto &resultset }

sub _create_schema {
    my ( $name, $options ) = @_;
    my @conn_info = $options->{connect_info}
        ? @{$options->{connect_info}}
        : @$options{qw(dsn user password options)};
    if ( exists $options->{pass} ) {
        warn "The pass option is deprecated. Use password instead.";
        $conn_info[2] = $options->{pass};
    }

    my $schema;

    if ( my $schema_class = $options->{schema_class} ) {
        $schema_class =~ s/-/::/g;
        eval { load $schema_class };
        croak("Could not load schema_class $schema_class: $@") if $@;
        if ( my $replicated = $options->{replicated} ) {
            $schema = $schema_class->clone;
            my %storage_options;
            my @params = qw( balancer_type balancer_args pool_type pool_args );
            for my $p ( @params ) {
                my $value = $replicated->{$p};
                $storage_options{$p} = $value if defined $value;
            }
            $schema->storage_type([ '::DBI::Replicated', \%storage_options ]);
            $schema->connection( @conn_info );
            $schema->storage->connect_replicants( @{$replicated->{replicants}});
        } else {
            $schema = $schema_class->connect( @conn_info );
        }
    } else {
        my $dbic_loader = 'DBIx::Class::Schema::Loader';
        eval { load $dbic_loader };
        croak("You must provide a schema_class option or install $dbic_loader.")
            if $@;
        $dbic_loader->naming( $options->{schema_loader_naming} || 'v7' );
        $schema = DBIx::Class::Schema::Loader->connect(@conn_info);
    }

    return $schema;
}

# ABSTRACT: Just some syntax sugar for DBIx::Class


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBICx::Sugar - Just some syntax sugar for DBIx::Class

=head1 VERSION

version 0.0200

=head1 SYNOPSIS

    use DBICx::Sugar qw(schema resultset rset);

    # all of the following are equivalent:

    $user = schema('default')->resultset('User')->find('bob');
    $user = schema->resultset('User')->find('bob');
    $user = resultset('User')->find('bob');
    $user = rset('User')->find('bob');

=head1 DESCRIPTION

Just some syntax sugar for your DBIx::Class applications.
This was originally created to remove code duplication between
L<Dancer::Plugin::DBIC> and L<Dancer2::Plugin::DBIC>.

=head1 CONFIGURATION

Configuration can be automatically parsed from a `config.yaml` or `config.yml`
file  in the current working directory, or it can be explicitly set with the
C<config> function:

    DBICx::Sugar::config({ default => { dsn => ... } });

If you want the config to be autoloaded from a yaml config file, just make sure
to put your config data under a top level C<dbicx_sugar> key.

=head2 simple example

Here is a simple example. It defines one database named C<default>:

    dbicx_sugar:
      default:
        dsn: dbi:SQLite:dbname=myapp.db
        schema_class: MyApp::Schema

=head2 multiple schemas

In this example, there are 2 databases configured named C<default> and C<foo>:

    dbicx_sugar:
      default:
        dsn: dbi:SQLite:dbname=myapp.db
        schema_class: MyApp::Schema
      foo:
        dsn: dbi:Pg:dbname=foo
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
You need L<DBIx::Class::Schema::Loader> installed for this to work.

WARNING: Dynamic loading is not recommended for production environments.
It is almost always better to provide a schema_class option.

The schema_class option should be the name of your L<DBIx::Class::Schema> class.
See L</"SCHEMA GENERATION">
Optionally, a database configuration may have user, password, and options
parameters as described in the documentation for C<connect()> in L<DBI>.

=head2 connect_info

Alternatively, you may also declare your connection information inside an
array named C<connect_info>:

    dbicx_sugar:
      default:
        schema_class: MyApp::Schema
        connect_info:
          - dbi:Pg:dbname=foo
          - bob
          - secret
          -
            RaiseError: 1
            PrintError: 1

=head2 replicated

You can also add database read slaves to your configuration with the
C<replicated> config option.
This will automatically make your read queries go to a slave and your write
queries go to the master.
Keep in mind that this will require additional dependencies:
L<DBIx::Class::Optional::Dependencies#Storage::Replicated>
See L<DBIx::Class::Storage::DBI::Replicated> for more details.
Here is an example configuration that adds two read slaves:

    dbicx_sugar:
      default:
        schema_class: MyApp::Schema
        dsn: dbi:Pg:dbname=master
        replicated:
          balancer_type: ::Random     # optional
          balancer_args:              # optional
              auto_validate_every: 5  # optional
              master_read_weight:1    # optional
          # pool_type and pool_args are also allowed and are also optional
          replicants:
            -
              - dbi:Pg:dbname=slave1
              - user1
              - password1
              -
                quote_names: 1
                pg_enable_utf8: 1
            -
              - dbi:Pg:dbname=slave2
              - user2
              - password2
              -
                quote_names: 1
                pg_enable_utf8: 1

=head2 alias

Schema aliases allow you to reference the same underlying database by multiple
names.
For example:

    dbicx_sugar:
      default:
        dsn: dbi:Pg:dbname=master
        schema_class: MyApp::Schema
      slave1:
        alias: default

Now you can access the default schema with C<schema()>, C<schema('default')>,
or C<schema('slave1')>.
This can come in handy if, for example, you have master/slave replication in
your production environment but only a single database in your development
environment.
You can continue to reference C<schema('slave1')> in your code in both
environments by simply creating a schema alias in your development.yml config
file, as shown above.

=head1 FUNCTIONS

=head2 schema

    my $user = schema->resultset('User')->find('bob');

Returns a L<DBIx::Class::Schema> object ready for you to use.
For performance, schema objects are cached in memory and are lazy loaded the
first time they are accessed.
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

=head2 get_config

Returns the current configuration, like config does,
but does not look for a config file.

Use this for introspection, eg:

    my $dbix_sugar_is_configured = get_config ? 1 : 0 ;

=head2 add_schema_to_config

This function does not touch the existing config.
It can be used if some other part of your app
has configured DBICx::Sugar but did not know about
the part that uses an extra schema.

    add_schema_to_config('schema_name', { dsn => ... });

=head1 SCHEMA GENERATION

Setting the schema_class option and having proper DBIx::Class classes
is the recommended approach for performance and stability.
You can use the L<dbicdump> command line tool provided by
L<DBIx::Class::Schema::Loader> to help you.
For example, if your app were named Foo, then you could run the following
from the root of your project directory:

    dbicdump -o dump_directory=./lib Foo::Schema dbi:SQLite:/path/to/foo.db

For this example, your C<schema_class> setting would be C<'Foo::Schema'>.

=head1 CONTRIBUTORS

=over

=item *

Henk van Oers <L<https://github.com/hvoers>>

=back

=head1 AUTHOR

Naveed Massjouni <naveed@vt.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
