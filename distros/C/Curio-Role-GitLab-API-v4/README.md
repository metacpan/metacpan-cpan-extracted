# NAME

Curio::Role::GitLab::API::v4 - Build Curio classes around GitLab::API::v4.

# SYNOPSIS

Create your Curio class:

```perl
package MyApp::Service::GitLab;

use Curio role => '::GitLab::API::v4';
use strictures 2;

use Exporter qw( import );
our @EXPORT = qw( myapp_gitlab );

add_key 'anonymous';
add_key 'bot-wiki-updater';
add_key 'bot-user-manager';

default_key 'anonymous';

default_arguments (
    url => 'https://git.example.com/api/v4',
);

sub private_token {
    my ($self) = @_;
    return undef if $self->connection_key() eq 'anonymous';
    return get_secret_somehow(
        'gitlab-token-' . $self->connection_key(),
    );
}

sub myapp_gitlab {
    return __PACKAGE__->fetch( @_ )->api();
}

1;
```

Then use your new Curio class elsewhere:

```perl
use MyApp::Service::GitLab;

my $api = myapp_gitlab('bot-user-manager');
```

# DESCRIPTION

This role provides all the basics for building a Curio class
which wraps around [GitLab::API::v4](https://metacpan.org/pod/GitLab::API::v4).

# ATTRIBUTES

## connection\_key

```perl
my $key = MyApp::Service::GitLab
          ->fetch('bot-user-manager')
          ->connection_key();
```

The `connection_key` holds the Curio key.  So, in the example above
it would return `bot-user-manager`.  This attribute's primary purpose
is to facilitate the writing of token methods as shown in ["TOKENS"](#tokens).

## api

```perl
my $api = MyApp::Service::GitLab
          ->fetch('bot-user-manager')
          ->api();
```

Holds the [GitLab::API::v4](https://metacpan.org/pod/GitLab::API::v4) object.

# TOKENS

In your Curio class you may create two methods, `access_token` and
`private_token`.  If either/both of these methods exist and return a
defined value then they will be used when constructing the ["api"](#api)
object.

In the ["SYNOPSIS"](#synopsis) a sample `private_token` method is shown:

```perl
sub private_token {
    my ($self) = @_;
    return undef if $self->connection_key() eq 'anonymous';
    return get_secret_somehow(
        'gitlab-token-' . $self->connection_key(),
    );
}
```

The `get_secret_somehow` call is expected to be the place where
you use whatever tool you use to hold your GitLab tokens and likely
all passwords and other credentials (secrets) that your application
needs.

Some common tools that people use to manage their secrets are
Kubernetes' secrets objects, AWS's Secret Manager, HashiCorp's Vault,
or just an inescure configuration file; to name a few.

So, the way you write your token methods is going to be unique to
your setup.

# CACHING

This role sets the ["does\_caching" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#does_caching) feature.

You can of course disable this.

```
does_caching 0;
```

# SUPPORT

Please submit bugs and feature requests to the
Curio-Role-GitLab-API-v4 GitHub issue tracker:

[https://github.com/bluefeet/Curio-Role-GitLab-API-v4/issues](https://github.com/bluefeet/Curio-Role-GitLab-API-v4/issues)

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# AUTHORS

```
Aran Clary Deltac <aran@bluefeet.dev>
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
