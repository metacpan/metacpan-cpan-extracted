# $Id: Model.pm 4 2007-09-13 10:16:35Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot-model.googlecode.com/svn/trunk/lib/Class/Dot/Model.pm $
# $Revision: 4 $
# $Date: 2007-09-13 12:16:35 +0200 (Thu, 13 Sep 2007) $
package Class::Dot::Model;

use strict;
use warnings;
use version; our $VERSION = qv('0.1.3');
use 5.006_001;

use Carp                    qw(croak);
use Params::Util            qw(_ARRAY);
use Config::PlConfig;
use Class::Dot::Model::Util qw(
    push_base_class
    install_coderef run_as_call_class
);

my $BASE_CLASS   = 'DBIx::Class::Schema';

my @INIT_METHODS = qw(
    load_classes
);

my %DSN_PARAMS = (
    hostname    => q{%s},
    database    => q{%s},
    port        => q{%d},
);

my %DSN_DRIVER_REWRITE = (
    mysql => {
        hostname    => 'host',
    },
    Pg    => {
        hostname    => 'hostname',
        database    => 'dbname',
    },
    SQLite => {
        database    => 'dbname',
    },
);

my $dsn_param_rewrite = sub {
    $DSN_DRIVER_REWRITE{$_[0]} ? $DSN_DRIVER_REWRITE{$_[0]} : $_[0];
};

sub requires {
    return $BASE_CLASS;
}

my @MODULES_THAT_IMPORTS_US;

sub import {
    my $class      = shift;
    my $call_class = caller 0;
    my %argv;
   
    if (scalar  @_ > 1) {
        %argv = @_;
    }

    push_base_class( $BASE_CLASS => $call_class );

    for my $init_method (@INIT_METHODS) {
        run_as_call_class( $call_class, $init_method );
    }

    return if not defined $argv{domain};
    return if $call_class->can('new');

    my $dbconfig  = _load_dbconfig( $argv{domain}, $argv{host} );
    my $dsnstring = _create_dsn_with_config($dbconfig);

    _install_constructor($call_class, $dsnstring, $dbconfig);

    push @MODULES_THAT_IMPORTS_US, $call_class;

    return;
}

# Install a sighandler that walks through all modules that imports
# us + inherits from DBIx::Class and then disconnects them.
BEGIN {
    $SIG{INT} = sub {
        for my $module (@MODULES_THAT_IMPORTS_US) {
            if ($module->isa($BASE_CLASS)) {
                $module->storage->disconnect();
            }
        }
    }
}

sub _load_dbconfig {
    my ($domain, $host) = @_;

    my $plconfig = Config::PlConfig->new({
        host   => $host,
        domain => $domain,
    });
    my $config = $plconfig->load()->{database};

    return $config;
}

sub _install_constructor {
    my ($call_class, $dsn, $config) = @_;

    my $new_coderef = sub {
        my ($class, $options_ref) = @_;
           $options_ref ||= { };

        my $self = $class->connect($dsn, $config->{username}, $config->{password});

        NOSTRICT: {
            no strict 'refs'; ## no critic
            if (my $build_ref = *{ $class . '::BUILD' }{CODE}) { ## no critic
                $build_ref->($self, $options_ref);
            }
        };

        return $self;
    };
        
    return install_coderef($new_coderef => $call_class, 'new');
}

sub _create_dsn_with_config {
    my ($config) = @_;

    # Format the DSN string.
    # %DSN_PARAMS holds the values we support, and values submitted
    # are copied to %dsn_params;
    my %dsn_params;
    my $dsn_format = qq{
        DBI:$config->{driver}:
    };

    DSNPARAM:
    for my $param_name (sort keys %DSN_PARAMS) {
        my $param_type = $DSN_PARAMS{$param_name};
        next DSNPARAM if not defined $config->{$param_name};
        $dsn_params{$param_name} = $config->{$param_name};

        $dsn_format .= join q{=}, (
            $dsn_param_rewrite->($param_name),
            $param_type
        );
        $dsn_format .= q{;};

    };
    chop $dsn_format;
    $dsn_format =~ s/\s*//xmsg;

    no warnings 'uninitialized';  ## no critic;
    my $dsn = sprintf $dsn_format,
        map { $dsn_params{$_} } sort keys %dsn_params;

    return $dsn;
}

1;

__END__

=begin wikidoc

= NAME

Class::Dot::Model - Simple way of defining models for DBIx::Class.

= VERSION

This document describes Class::Dot::Model version v%%VERSION%%

= SYNOPSIS

    package My::Model;
    use Class::Dot::Model   domain => 'org.mydomain.myapp';

    package My::Model::Cat;
    use Class::Dot::Model::Table qw(:has_many);

    Table       'cats';
    Columns     qw( id gender dna action colour );
    Primary_Key 'id';
    Has_Many    'memories'
        => 'My::Model::Cat::Memory';
    
       
    package My::Model::Cat::Memory;
    use Class::Dot::Model::Table qw(:belongs_to);

    Table       'memory';
    Columns     qw( id cat content );
    Primary_Key 'id';
    Belongs_To  'cat'
        => 'My::Model::Cat';

Then you would have to initialize the database configuration for
org.mydomain.myapp:

    use Config::PlConfig;
    my $DOMAIN   = 'org.mydomain.myapp';

    my $dbconfig = {
        driver      => 'mysql',
        database    => 'myappdb',
        hostname    => 'localhost',
        username    => 'me',
        password    => 'secret',
    };

    my $plconfig = Config::PlConfig->new({
        domain  => $DOMAIN,
    });
    my $config = $plconfig->load();
    $config->{database} = $dbconfig;
    $plconfig->save();

= DESCRIPTION

A module for making DBIx::Class even simpler.

= SUBROUTINES/METHODS

None of this modules functions should be used directly.

== PRIVATE CLASS METHODS

=== {_create_dsn_with_config($config)}
=for apidoc string = Class::Dot::Model::_create_dsn_with_config(HASHREF $config)

Create a DBI DSN out of a configuration hash.

=== {_install_constructor($call_class, $dsn, $config)}
=for apidoc CODEREF = Class::Dot::Model::_install_constructor(_CLASS $call_class, string $dsn, HASHREF $config)

Create an install a C<new> function into the callers namespace. This new
function is responsible for connecting to the database etc.

The property is a string.

=== {_load_dbconfig($config_domain, $config_host)}
=for apidoc CODEREF = Class::Dot::Model::_load_dbconfig(string $config_domain, string $config_host)

Load the database configuration using a [Config::PlConfig] host and domain.

== PRIVATE SUBROUTINES

=== {requires()}

Used by L<Class::Dot::Model::Preload> to know which modules this module
requires.

= DIAGNOSTICS

None.

= CONFIGURATION AND ENVIRONMENT

This module uses [Config::PlConfig] to load configuration if a domain is given
as import argument.

= DEPENDENCIES

* [DBIx::Class]

* [Class::Dot]

* [Class::Plugin::Util]

* [Params::Util]

* [Config::PlConfig]

* [version]

= INCOMPATIBILITIES

None known.

= BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
[bug-class-dot-model@rt.cpan.org|mailto:class-dot-model@rt.cpan.org], or through the web interface at
[CPAN Bug tracker|http://rt.cpan.org].

= SEE ALSO

== [DBIx::Class]

== [Class::Dot::Model::Table]

== [Class::Dot]

= AUTHOR

Ask Solem, [ask@0x61736b.net].

= LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem [ask@0x61736b.net|mailto:ask@0x61736b.net].

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

= DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=end wikidoc


=for stopwords expandtab shiftround
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
