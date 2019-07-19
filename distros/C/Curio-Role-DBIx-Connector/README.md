# NAME

Curio::Role::DBIx::Connector - Build Curio classes around DBIx::Connector.

# SYNOPSIS

Create a Curio class:

```perl
package MyApp::Service::DB;

use Curio role => '::DBIx::Connector';
use strictures 2;

key_argument 'key';
export_function_name 'myapp_db';

add_key 'writer';
add_key 'reader';

has key => (
    is       => 'ro',
    required => 1,
);

sub dsn {
    my ($self) = @_;
    return myapp_config()->{db}->{ $self->key() }->{dsn};
}

sub username {
    my ($self) = @_;
    return myapp_config()->{db}->{ $self->key() }->{username};
}

sub password {
    my ($self) = @_;
    return myapp_secret( $self->key() . '_' . $self->username() );
}

sub attributes {
    return { PrintError=>1 };
}

1;
```

Then use your new Curio class elsewhere:

```perl
use MyApp::Service::DB qw( myapp_db );

my $db = myapp_db('writer')->connector();

$db->run(sub{
    $_->do( 'CREATE TABLE foo ( bar )' );
});
```

# DESCRIPTION

This role provides all the basics for building a Curio class
which wraps around [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector).

# OPTIONAL ARGUMENTS

## connector

```perl
my $connector = MyApp::Service::DB->fetch('writer')->connector();
```

Holds the [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) object.

If not specified as an argument, a new connector will be automatically
built based on ["dsn"](#dsn), ["username"](#username), ["password"](#password), and ["attributes"](#attributes).

# REQUIRED METHODS

These methods must be implemented by the consuming curio class.

## dsn

```perl
sub dsn { 'dbi:...' }
```

# OPTIONAL METHODS

These methods may be implemented by the consuming curio class.

## username

```perl
sub username { '' }
```

## password

```perl
sub password { '' }
```

## attributes

```perl
sub attributes { {} }
```

`AutoCommit` will be set to `1` unless you directly override it
in this hashref.

See ["ATTRIBUTES-COMMON-TO-ALL-HANDLES" in DBI](https://metacpan.org/pod/DBI#ATTRIBUTES-COMMON-TO-ALL-HANDLES).

# CACHING

This role sets the ["does\_caching" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#does_caching) feature.

You can of course disable this feature.

```
does_caching 0;
```

# SUPPORT

Please submit bugs and feature requests to the
Curio-Role-DBIx-Connector GitHub issue tracker:

[https://github.com/bluefeet/Curio-Role-DBIx-Connector/issues](https://github.com/bluefeet/Curio-Role-DBIx-Connector/issues)

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

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
