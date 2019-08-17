# NAME

Curio::Role::DBIx::Connector - Build Curio classes around DBIx::Connector.

# SYNOPSIS

Create a Curio class:

```perl
package MyApp::Service::DB;

use MyApp::Config;
use MyApp::Secrets;

use Curio role => '::DBIx::Connector';
use strictures 2;

key_argument 'connection_key';
export_function_name 'myapp_db';
always_export;
export_resource;

add_key 'writer';
add_key 'reader';

has connection_key => (
    is       => 'ro',
    required => 1,
);

sub dsn {
    my ($self) = @_;
    return myapp_config()->{db}->{ $self->connection_key() }->{dsn};
}

sub username {
    my ($self) = @_;
    return myapp_config()->{db}->{ $self->connection_key() }->{username};
}

sub password {
    my ($self) = @_;
    return myapp_secret( $self->connection_key() . '_' . $self->username() );
}

1;
```

Then use your new Curio class elsewhere:

```perl
use MyApp::Service::DB;

my $db = myapp_db('writer');

$db->run(sub{
    my ($one) = $_->selectrow_array( 'SELECT 1' );
});
```

# DESCRIPTION

This role provides all the basics for building a Curio class which
wraps around [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector).

# OPTIONAL ARGUMENTS

## connector

Holds the [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) object.

May be passed as either ain arrayref of arguments or a pre-created
object.  If this argument is not set then it will be built from ["dsn"](#dsn),
["username"](#username), ["password"](#password), and ["attributes"](#attributes).

# REQUIRED METHODS

These methods must be implemented in your Curio class.

## dsn

This method must return a [DBI](https://metacpan.org/pod/DBI) `$dsn`/`$data_source`, such as
`dbi:SQLite:dbname=:memory:`.

# OPTIONAL METHODS

These methods may be implemented in your Curio class.

## username

If this method is not present then an empty string will be used for
the username when the ["connector"](#connector) is built.

## password

If this method is not present then an empty string will be used for
the passord when the ["connector"](#connector) is built.

## attributes

If this method is not present then an empty hashref will be used for
the attributes when the ["connector"](#connector) is built.

```perl
sub attributes {
    return { SomeAttribute => 3 };
}
```

Note what ["AUTOCOMMIT"](#autocommit) says.

# AUTOCOMMIT

The `AutoCommit` [DBI](https://metacpan.org/pod/DBI) attribute is defaulted to `1`.  You can
override this in ["attributes"](#attributes).

If the ["connector"](#connector) argument is set then this defaulting of
`AutoCommit` is skipped.

# FEATURES

This role turns on ["does\_caching" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#does_caching) and sets
["resource\_method\_name" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#resource_method_name) to `connector` (as in
["connector"](#connector)).

You can of course revert these changes:

```
does_caching 0;
resource_method_name undef;
```

# SUPPORT

Please submit bugs and feature requests to the
Curio-Role-DBIx-Connector GitHub issue tracker:

[https://github.com/bluefeet/Curio-Role-DBIx-Connector/issues](https://github.com/bluefeet/Curio-Role-DBIx-Connector/issues)

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/) for
encouraging their employees to contribute back to the open source
ecosystem.  Without their dedication to quality software development
this distribution would not exist.

# AUTHORS

```
Aran Clary Deltac <bluefeet@gmail.com>
```

# COPYRIGHT AND LICENSE

Copyright (C) 2019 Aran Clary Deltac

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see [http://www.gnu.org/licenses/](http://www.gnu.org/licenses/).
