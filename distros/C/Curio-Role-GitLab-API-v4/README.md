# NAME

Curio::Role::GitLab::API::v4 - Build Curio classes around GitLab::API::v4.

# SYNOPSIS

Create your Curio class:

```perl
package MyApp::Service::GitLab;

use MyApp::Config;
use MyApp::Secrets;
use Types::Common::String qw( NonEmptySimpleStr );

use Curio role => '::GitLab::API::v4';
use strictures 2;

export_function_name 'myapp_gitlab';
key_argument 'connection_key';

has connection_key => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    required => 1,
);

add_key 'anonymous';
add_key 'admin';

default_key 'anonymous';

default_arguments (
    api => {
        url => myapp_config()->{gitlab_api_url},
    },
);

sub private_token {
    my ($self) = @_;
    return undef if $self->connection_key() eq 'anonymous';
    return myapp_secret(
        'gitlab-token-' . $self->connection_key(),
    );
}

1;
```

Then use your new Curio class elsewhere:

```perl
use MyApp::Service::GitLab qw( myapp_gitlab );

my $api = myapp_gitlab('admin');
```

# DESCRIPTION

This role provides all the basics for building a Curio class which wraps around
[GitLab::API::v4](https://metacpan.org/pod/GitLab::API::v4).

# OPTIONAL ARGUMENTS

## api

Holds the [GitLab::API::v4](https://metacpan.org/pod/GitLab::API::v4) object.

May be passed as a hashref of arguments, or a pre-created object.

# OPTIONAL METHODS

These methods may be declared in your Curio class.

## access\_token

The ["access\_token" in GitLab::API::v4](https://metacpan.org/pod/GitLab::API::v4#access_token).  See ["TOKENS"](#tokens).

## private\_token

The ["private\_token" in GitLab::API::v4](https://metacpan.org/pod/GitLab::API::v4#private_token).  See ["TOKENS"](#tokens).

# TOKENS

In your Curio class you may create two methods, ["access\_token"](#access_token) and ["private\_token"](#private_token).
If either/both of these methods exist and return a defined value then they will be used
when constructing the ["api"](#api) object.

In the ["SYNOPSIS"](#synopsis) a sample `private_token` method is shown:

```perl
sub private_token {
    my ($self) = @_;
    return undef if $self->connection_key() eq 'anonymous';
    return myapp_secret(
        'gitlab-token-' . $self->connection_key(),
    );
}
```

The `myapp_secret` call is expected to be the place where you use whatever tool you use
to hold your GitLab tokens and likely all passwords and other credentials (secrets) that
your application needs.

Some common tools that people use to manage their secrets are Kubernetes' secrets objects,
AWS's Secret Manager, HashiCorp's Vault, or just an inescure configuration file; to name a
few.

So, the way you write your token methods is going to be unique to your setup.

# FEATURES

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

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/) for encouraging their employees
to contribute back to the open source ecosystem.  Without their dedication to quality
software development this distribution would not exist.

# AUTHORS

```
Aran Clary Deltac <bluefeet@gmail.com>
```

# COPYRIGHT AND LICENSE

Copyright (C) 2019 Aran Clary Deltac

This program is free software: you can redistribute it and/or modify it under the terms of
the GNU General Public License as published by the Free Software Foundation, either
version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.
If not, see [http://www.gnu.org/licenses/](http://www.gnu.org/licenses/).
