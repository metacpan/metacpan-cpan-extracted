package DBIx::Class::Sims::REST;

use 5.010_000;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.000012';

use DBI;
use Hash::Merge;

my $base_defaults = {
  database => {
    username => '',
    password => '',
    root => {
      username => '',
      password => '',
    },
  },
  create => 1,
  deploy => 1,
};

sub get_defaults {
  return;
}

sub get_root_connection {
  my $class = shift;
  my ($item, $defaults) = @_;

  my $user = $item->{database}{root}{username} // $defaults->{database}{root}{username} // '';
  my $pass = $item->{database}{root}{password} // $defaults->{database}{root}{password} // '';

  my $connect_string = $class->get_connect_string(
    $item, $defaults, { no_name => 1 },
  );
  return DBI->connect($connect_string, $user, $pass);
}

sub get_create_commands {
  die "Must override get_create_commands\n";
}

sub get_schema_class {
  die "Must override get_schema_class\n";
}

sub get_connect_string {
  die "Must override get_connect_string\n";
}

sub get_username {
  my $class = shift;
  my ($item, $defaults) = @_;

  return $item->{database}{username} // $defaults->{database}{username};
}

sub get_password {
  my $class = shift;
  my ($item, $defaults) = @_;

  return $item->{database}{password} // $defaults->{database}{password};
}

sub get_schema {
  my $class = shift;
  my ($item, $defaults) = @_;

  my $schema_class = $class->get_schema_class( $item, $defaults ) // return;
  my $connect_string = $class->get_connect_string( $item, $defaults ) // return;

  my $user = $class->get_username($item, $defaults) // '';
  my $pass = $class->get_password($item, $defaults) // '';

  return $schema_class->connect(
    $connect_string, $user, $pass, {
      PrintError => 0,
      RaiseError => 1,
    },
  );
}

sub populate_default_data {
  return;
}

sub sims_options {
  return;
}

sub flatten_for_transport {
  my $class = shift;
  my ($sims) = @_;
  # Convert objects into columns/values for JSON encoding.
  my %flattened;
  while ( my ($k, $v) = each %{$sims} ) {
    $flattened{$k} = [ map { { $_->get_columns } } @$v ];
  }

  return \%flattened;
}

sub do_sims {
  my $class = shift;
  my ($request) = @_;

  my $merger = Hash::Merge->new('RIGHT_PRECEDENT');

  my $defaults = $merger->merge(
    $base_defaults // {},
    $class->get_defaults // {},
    $request->{defaults} // {},
  );

  my $rv;
  foreach my $item ( @{$request->{databases} // []} ) {
    my $schema;
    if ( $item->{deploy} // $defaults->{deploy} ) {
      # Only create if we're also going to deploy.
      if ( $item->{create} // $defaults->{create} ) {
        my $root_dbh = $class->get_root_connection($item, $defaults) // next;
        my @commands = $class->get_create_commands($item, $defaults);

        if (@commands) {
          $root_dbh->do($_) for @commands;
        }
      }

      # The database may not exist until this point.
      $schema = $class->get_schema($item, $defaults) // next;

      # XXX Need to capture the warnings and provide them back to the caller
      $schema->deploy({
        add_drop_table => 1,
        show_warnings => 1,
      });
    }
    else {
      $schema = $class->get_schema($item, $defaults) // next;
    }

    $class->populate_default_data($schema, $item, $defaults);

    my $sims = $schema->load_sims(
      $item->{spec} // {},
      $merger->merge(
        $class->sims_options($schema, $item, $defaults) // {},
        $item->{options} // {}
      ),
    );
    push @{ $rv //= [] }, $class->flatten_for_transport($sims);
  }

  return $rv // { error => 'No actions taken' };
}

use JSON::XS qw( encode_json decode_json );
use Plack::Request;
use Web::Simple; # Needed for the prototypes

sub dispatch_request {
  my $class = shift;
  sub (/sims) {
    sub (POST) {
      my ($self, $env) = @_;

      my $r = Plack::Request->new($env);
      my $request = decode_json($r->content);

      my $rv = $class->do_sims( $request );

      [ 200, [ 'Content-type', 'application/json' ],
        [ encode_json($rv) ],
      ]
    },
  }
}

1;
__END__

=head1 NAME

DBIx::Class::Sims::REST

=head1 SYNOPSIS

In your REST API class:

  package My::Sims::REST

  use base 'DBIx::Class::Sims::REST::MySQL';

  sub get_schema_class { return 'My::Schema::Class' }

  1;

In a rest.cgi file (somewhere):

  use Module::Runtime qw(use_module);
  my $app = use_module('My::Sims::REST')->to_psgi_app;

  use Plack::Builder;

  builder {
    # Or whatever other middleware you want.
    enable "Runtime"; # Adds the X-Runtime header
    $app
  }

Then later:

  plackup <path/to/your/rest.cgi> -p <PORT>

And, finally, in your test (or some library your tests use):

  my $data = {
      databases => [
          {
              database => {
                  name => 'database name',
                  username => 'some username',
                  password => 'some password',
              },
              spec => <DBIx::Class::Sims specification>,
          },
      ],
  };

  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(POST => 'http://<URL>:<PORT>/sims');
  $req->content(encode_json($data));
  my $res = $ua->request($req);

  return decode_json($res->content);

=head1 PURPOSE

L<DBIx::Class::Sims> provides an easy way to create and populate test data. But,
sometimes, your application isn't built on L<DBIx::Class>. Or Perl. These issues
shouldn't get in the way of using good tools. (Even if your application or test
suite aren't in Perl.)

Assumption: Everything can issue an HTTP request.

Conclusion: The Sims should be available via an HTTP request.

=head1 DESCRIPTION

This is a skeleton base class that provides the basic functionality for a REST
API around L<DBIx::Class::Sims>. By itself, it only takes the request, parses it
out, and invokes a series of methods that have empty implementations. You are
supposed to subclass this class and provide the meat of these methods.

You will have to create a L<DBIx::Class> description of your schema (or, at the
least, the bits you want to be able to sim in your tests). It really isn't that
difficult - there are examples in the test suite for this module.

Once you have all of that, you will need to host this REST API somewhere. Since
its purpose is to aid in testing, a good place for it is in your developers'
Vagrant VMs, and also in the VM you use to run CI tests on.

B<THIS SHOULD NEVER BE MADE AVAILABLE IN PRODUCTION.> If you do so, the problems
you will have are on your head and your head alone. I explicitly and
categorically disavow any and all responsibility for your idiocy if this ends up
in your production environment. Please, do not be stupid.

=head1 REQUEST

The full data structure to be passed via a request is as follows:

  {
      defaults => {
          database => {
              username => '',
              password => '',
              root => {
                  username => '',
                  password => '',
              },
          },
          create => 1,
          deploy => 1,
      },
      databases => [
          {
              database => {
                  username => 'username',
                  password => 'password',
                  name     => 'name',
                  root     => {
                      username => 'root_username',
                      password => 'root_password',
                  },
              },
              create  => <0|1>,
              deploy  => <0|1>,
              spec    => < First parameter to load_sims() >
              options => < Second parameter to load_sims() >
          },
          ...
      ],
  }

=over 4

=item * databases

Each entry in this array represents the setting up of a single database. You may
want to set up multiple databases at the same time, hence the ability to specify
multiple databases. Each entry will be executed in the order they are specified,
if that matters. Each entry can decide whether or not to create or deploy, as
appropriate to your purpose.

=over 4

=item * create

This will drop and recreate the database. This defaults to true. If this is set,
then deploy will also be set.

This requires the root username, password, and whatever create commands are
required to be set. Please see the appropriate sections of the documentation for
further information.

=item * deploy

This will deploy the schema per C<<$schema->deploy(add_drop_tables => 1)>>.

=item * spec

This is the meat and potatoes of this module - the reason why you're here.

Please see L<DBIx::Class::Sims/load_sims> for further information.

=item * options

L<DBIx::Class::Sims/load_sims> has an optional second parameter of options. This
allows you to set them. Please see that documentation for further information.

You can set a default set of options by overriding L</sims_options>.

=back

=back

=head1 RESPONSE

If all goes well, the response will be an array of the return values from
L<DBIx::Class::Sims/load_sims>. The array will be in the same order as
the databases element of the request.

If nothing happens, the response will be exactly:

  { "error": "No actions taken" }

=head1 REQUIRED METHODS

You have to override the following methods for anything to work.

=head2 get_schema_class( $item, $defaults )

This method should return a string containing the package name for the schema.
It can use anything in the entry and the defaults.

If it returns nothing, then this entry will be skipped.

You B<MUST> provide an implementation of this method - the base implementation
throws an error.

=head2 get_connect_string( $item, $defaults )

This method should return the first parameter in the connect() method. It can
use anything in the entry and the defaults.

If it returns nothing, then this entry will be skipped.

This method has implementations in the SQLite and MySQL subclasses. Otherwise,
you B<MUST> provide an implementation of this method - the base implementation
throws an error.

=head1 OPTIONAL METHODS

=head2 get_defaults()

This method should return a hashref that provides the defaults for all calls.

The base implementation returns the following:

  {
    database => {
      username => '',
      password => '',
      root => {
        username => '',
        password => '',
      },
    },
    create => 1,
    deploy => 1,
  }

=head2 get_username( $item, $defaults )

This method should return a string to be used as the username in the connect
string.

The base implementation returns the username from either the C<$item> or the
C<$defaults>.

=head2 get_password( $item, $defaults )

This method should return a string to be used as the password in the connect
string.

The base implementation returns the password from either the C<$item> or the
C<$defaults>.

=head2 get_root_connection( $item, $defaults )

This method should return a DBI C<$dbh> that has a root connection to the
database. This is what the return value of C<get_create_commands()> will be
passed to.

The base implementation retrieves the root username and password from the
database entry in the C<$item> or C<$defaults>, then uses the value from
C<get_connect_string()> to connect to the database. This should be sufficient
for most purposes.

=head2 get_create_commands( $item, $defaults )

This method should return an array of SQL commands to be executed via a root
connection when a database is dropped and created. These commands will be
executed when C<<create => 1>>.

The base implementation returns an empty array.

=head2 populate_default_data( $schema, $item, $defaults )

This method is called after create/deploy is processed, but before
C<<$schema->load_sims()>> is invoked. You can use this method to do any default
data population. For example, to invoke L<DBIx::Class::Fixtures> or to call
L<DBIx::Class::Schema/populate>.

=head2 sims_options( $schema, $item, $defaults )

This method should return a hashref appropriate to pass as the second parameter
to C<load_sims()>. It will be merged with the whatever is passed in for the
specific item.

The base implementation returns an empty hashref.

=head1 SUGGESTIONS

=head2 Additional Keys

The keys listed thus far in C<$item> are only those L<DBIx::Class::Sims> uses
internally. You are more than welcome to add additional keys as you need. Then,
in the various methods that are passed C<$item>, you can pull those out.

=head2 Multiple databases

Your tests may need multiple databases to be populated. This is why the data
specification requires a databases array. The C<$item>s will be processed in the
order they are specified, in case that matters.

You can combine this with adding an additional key to specify which database
this C<$item> is dealing with. That way, you can have a different schema class,
different default data, etc.

=head1 TODO

=over 4

=item * Chef/Puppet recipes for auto-launching the REST API

=item * Figure out how to pass the class into plackup without an envvar.

=back

=head1 BUGS/SUGGESTIONS

This module is hosted on Github at
L<https://github.com/robkinyon/dbix-class-sims-rest>. Pull requests are strongly
encouraged.

=head1 SEE ALSO

L<DBIx::Class::Sims>, L<Web::Simple>

=head1 AUTHOR

Rob Kinyon <rob.kinyon@gmail.com>

=head1 LICENSE

Copyright (c) 2013 Rob Kinyon. All Rights Reserved.
This is free software, you may use it and distribute it under the same terms
as Perl itself.

=cut
