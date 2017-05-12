# ABSTRACT: Application Configuration via Environment Variables
package Config::Environment;

use utf8;
use 5.10.0;

use Moo;
use Hash::Flatten ();
use Hash::Merge::Simple ();

our $VERSION = '0.000010'; # VERSION


sub BUILDARGS {
    my ($class, @args) = @_;

    unshift @args, 'domain' if $args[0] && $#args == 0;
    return {@args};
}

sub BUILD {
    my ($self) = @_;

    $self->{domain} = lc $self->{domain};
    if ($self->{domain} =~ s/[^a-zA-Z0-9]+/_/g) {
        my ($dom, $subdom) = split /_/, $self->{domain}, 2;
        $self->{domain}    = $dom;
        $self->{subdomain} = $self->to_sub_key($subdom);
    }

    my $dom = $self->domain;
    $self->{snapshot} = { map {$_ => $ENV{$_}} grep { /^$dom\_/i } keys %ENV };
    return $self->load({%ENV}) if $self->autoload;
}


has autoload => (
    is       => 'ro',
    required => 0,
    default  => 1
);


has domain => (
    is       => 'ro',
    required => 1
);


has lifecycle => (
    is       => 'ro',
    required => 0,
    default  => 0
);


has mirror => (
    is       => 'rw',
    required => 0,
    default  => 1
);


has override => (
    is       => 'rw',
    required => 0,
    default  => 1
);


has stash => (
    is       => 'ro',
    required => 0,
    default  => sub {{}}
);


sub load {
    my ($self, $hash) = @_;
    my $dom = lc $self->domain;
    my $env = { map {$_ => $hash->{$_}} grep { /^$dom\_/i } keys %{$hash} };
    my $reg = $self->{registry} //= {env => {}, map => {}};
    my $map = $reg->{map};

    for my $key (sort keys %{$env}) {
        my $value = delete $env->{$key};

        $key =~ s/_/./g;
        $key =~ s/^$dom\.//gi;

        my $hash = {lc $key => $value};

        if (ref $value) {
            if ('ARRAY' eq ref $value) {
                my $i = 0;
                $value = { map { ++$i => $_ } @{$value} };
            }

            $hash = Hash::Flatten->new->flatten($value);

            for my $refkey (keys %{$hash}) {
                (my $newref = $refkey) =~ s/(\w):(\d+)/"$1.".($2+1)/gpe;
                $hash->{lc "$key.$newref"} = delete $hash->{$refkey};
            }
        }

        $map = Hash::Merge::Simple->merge(
            $map => Hash::Flatten->new->unflatten($hash)
        );

        if ($self->mirror) {
            while (my($key, $val) = each(%{$hash})) {
                $ENV{$self->to_env_key($key)} = $val;
            }
        }
    }

    $reg->{map} = $map;

    return $self;
}


sub param {
    my ($self, $key, $val) = @_;

    return unless defined $key;

    my $dom = $self->domain;

    $key = $self->to_dom_key($key);
    $key =~ s/^$dom(\.)?//;

    if (@_ > 2) {
        my $pairs = Hash::Flatten::flatten({$key => $val});
        while (my($key, $val) = each(%{$pairs})) {
            $key =~ s/(\w):(\d+)/"$1.".($2+1)/gpe;
            $key =~ s/\\//g;
            unless (exists $ENV{$self->to_env_key($key)} && ! $self->override) {
                $self->load({$self->to_env_key($key) => $val});
                $self->{registry}{env}{$key} = $val;
            }
        }
    }

    my $result;

    # env lookup
    if (exists $self->{registry}{env}{$key}) {
        $result = $self->{registry}{env}{$key};
    }

    # env map walk
    if (!$result) {
        my $node  = $self->{registry}{map};
        my @steps = split /\./, $key;
        for (my $i=0; $i<@steps; $i++) {
            my $step = $steps[$i];
            if (exists $node->{$step}) {
                if ($i<@steps && 'HASH' ne ref $node) {
                    undef $node and last;
                }
                $node = $node->{$step};
            }
            else {
                undef $node and last;
            }
        }
        $result = $node;
    }

    # stash walk
    if (!$result) {
        my $key = join '.', grep defined, $self->{subdomain}, $_[1]; #hack
        $key =~ s/\.(\d+)\./".".($1-1)."."/gpe;
        unless ($result = $self->stash->{$key}) {
            my $node  = $self->stash;
            my @steps = split /\./, $key;
            for (my $i=0; $i<@steps; $i++) {
                my $step = $steps[$i];
                if ('ARRAY' eq ref $node) {
                    if ($i<@steps && !defined $node->[$step]) {
                        undef $node and last;
                    }
                    else {
                        $node = $node->[$step];
                    }
                }
                elsif ('HASH' eq ref $node) {
                    if ($i<@steps && !defined $node->{$step}) {
                        undef $node and last;
                    }
                    else {
                        $node = $node->{$step};
                    }
                }
                else {
                    undef $node and last;
                }
            }
            $result = $node;
        }
    }

    return $result;
}


sub params {
    my ($self, @keys) = @_;

    if ($#keys == 0) {
        if ('HASH' eq ref $keys[0]) {
            while (my ($key, $value) = each%{$keys[0]}) {
                $self->param($key, $value);
            }
            return;
        }
    }

    my @vals = map { $self->param($_) } @keys;
    return wantarray ? @vals : $vals[0];
}


sub environment {
    my ($self) = @_;
    my $map = Hash::Merge::Simple->merge(
        Hash::Flatten->new->flatten($self->{registry}{map}),
        Hash::Flatten->new->flatten($self->stash),
    );

    for my $key (keys %{$map}) {
        $map->{$self->to_env_key($key)} = delete $map->{$key};
    }

    return $map;
}


sub subdomain {
    my ($self, $key) = @_;
    my $dom  = $self->domain;
    my $copy = ref($self)->new(
        autoload  => 0,
        override  => $self->override,
        lifecycle => $self->lifecycle,
        mirror    => $self->mirror,
        stash     => $self->stash,
        domain    => $dom
    );

    $copy->{subdomain} = $self->to_sub_key($key);
    $copy->{registry}  = $self->{registry};

    return $copy;
}

sub to_dom_key {
    my ($self, $key) = @_;
    my $dom = $self->domain;

    $key =~ s/^$dom//;

    my @prefix = ($dom);
    push @prefix, $self->{subdomain} if defined $self->{subdomain};

    return lc join '.', @prefix, split /_/, $key;
}

sub to_env_key {
    my ($self, $key) = @_;
    my $dom = $self->domain;

    $key =~ s/^$dom//;

    return uc join '_', $dom, split /\./, $key
}

sub to_sub_key {
    my ($self, $key) = @_;
    my $dom = $self->domain;

    ($key = $self->to_dom_key($key)) =~ s/^$dom(\.)?//;

    return $key;
}

sub DESTROY {
    my ($self) = @_;

    if ($self->lifecycle) {
        my $environment = $self->environment;
        my $snapshot    = $self->{snapshot};

        delete $ENV{$_} for grep { ! exists $snapshot->{$_} }
            keys %{$environment};
        $ENV{$_} = $snapshot->{$_} for keys %{$snapshot};
    }
}

1;

__END__

=pod

=head1 NAME

Config::Environment - Application Configuration via Environment Variables

=head1 VERSION

version 0.000010

=head1 SYNOPSIS

    use Config::Environment;

    my $conf = Config::Environment->new('myapp');
    my $conn = $conf->param('db.1.conn' => 'dbi:mysql:dbname=foobar');
    my $user = $conf->param('db.1.user'); # via $ENV{MYAPP_DB_1_USER} or undef
    my $pass = $conf->param('db.1.pass'); # via $ENV{MYAPP_DB_1_PASS} or undef

    or

    my $info = $conf->param('db.1');
    say $info->{conn}; # outputs dbi:mysql:dbname=foobar
    say $info->{user}; # outputs the value of $ENV{MYAPP_DB_1_USER}
    say $info->{pass}; # outputs the value of $ENV{MYAPP_DB_1_PASS}

    likewise ...

    $conf->param('server' => {node => ['10.10.10.02', '10.10.10.03']});

    creates the following environment variables and assignments

    $ENV{MYAPP_SERVER_NODE_1} = '10.10.10.02';
    $ENV{MYAPP_SERVER_NODE_2} = '10.10.10.03';

    ... and the configuration can be retrieved using any of the following

    $conf->param('server');
    $conf->param('server.node');
    $conf->param('server.node.1');
    $conf->param('server.node.2');

    or

    my ($node1, $node2) = $conf->params(qw(server.node.1 server.node.2));

=head1 DESCRIPTION

Config::Environment is an interface for managing application configuration using
environment variables as a backend. Using environment variables as a means of
application configuration is a great way of controlling which parts of your
application configuration gets hard-coded and shipped with your codebase (and
which parts do not). Using environment variables, application configuration can
be set at the system, user, and/or application levels and easily overridden.

=head1 ATTRIBUTES

=head2 autoload

The autoload attribute contains a boolean value which determines whether
the global ENV hash will be sourced during instantiation. This attribute is
set to true by default.

=head2 domain

The domain attribute contains the environment variable prefix used as context
to differentiate between other environment variables.

=head2 lifecycle

The lifecycle attribute contains a boolean value which if true restricts any
environment variables changes to life of the class instance. This attribute
is set to false by default.

=head2 mirror

The mirror attribute contains a boolean value which if true copies any
configuration assignments to the corresponding environment variables. This
attribute is set to true by default.

=head2 override

The override attribute contains a boolean value which determines whether
parameters corresponding to an existing environment variable can have it's
value overridden. This attribute is set to true by default.

=head2 stash

The stash attribute contains a hashref which can be used to store arbitrary data
which does not undergo parsing and which can be accessed using the param method.

=head1 METHODS

=head2 load

The load method expects a hashref which it parses and generates environment
variables from (whether they exist or not) and registers the formatted
environment structure. This method is called automatically on instantiation
using the global ENV hash as an argument. Note! The hash can contain nested
objects but it's keys should resemble capitalized/underscored environment
variable names.

    my $hash = {
        APP_MODE => 'development',
        APP_USER => 'vagrant',
        APP_PORT => 9000
    };

    $self->load($hash);

=head2 param

The param method expects a key which it uses to locate the corresponding
environment variable in the registered data structure. The key uses dot-notation
to traverse hierarchical data in the registry. This method will return undefined
if no element can be found matching the query. The method can also be used to
set environment variables by passing an additional argument as the value in the
form of a scalar, arrayref or hashref.

    my $item = $self->param($key);
    my $item = $self->param($key => $value);

    # load parsed data from another configuration source, e.g. a config file
    while (my($key, $val) = each(%$configuration) {
        $self->param($key => $val);
    }

=head2 params

The params method expects a list of keys which are used to locate the
corresponding environment variables in the registered data structure. The keys
use dot-notation to traverse hierarchical data in the registry and return a list
of corresponding values in order specified. This method returns a list in
list-context, otherwise it returns the first element found of the list of
queries specified.

    my $item  = $self->params(@list_of_keys);
    my @items = $self->params(@list_of_keys);

You can also pass a single hash-reference to this method and have it traverse
the key/value pairs and perform the desired assignments. This usage will not
return a value.

    $self->params(\%params);

=head2 environment

The environment method returns a hashref representing all environment variables
specific to the instantiated object's domain and instance.

    my $environment = $self->environment;

=head2 subdomain

The subdomain method returns a copy of the class instance with a modified domain
reference for easier access to nested configuration keys.

    my $db  = $self->subdomain('db');
    my $db1 = $db->subdomain('1');

    $db1->param('conn' => $connstring);
    $db1->param('user' => $username);
    $db1->param('pass' => $password);

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
