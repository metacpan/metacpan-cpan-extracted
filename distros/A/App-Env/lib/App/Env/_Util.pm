package App::Env::_Util;

# ABSTRACT: Utilities

use v5.10;
use strict;
use warnings;

our $VERSION = '1.04';

# need to distinguish between a non-existent module
# and one which has compile errors.
use Module::Find qw( );
use List::Util 1.33 'any';
use Params::Validate ();

#-------------------------------------------------------

sub croak {
    require Carp;
    goto &Carp::croak;
}

#-------------------------------------------------------

# environment cache
my %Cache;

sub getCacheEntry    { return $Cache{ $_[0] }; }
sub setCacheEntry    { $Cache{ $_[0] } = $_[1]; }
sub deleteCacheEntry { delete $Cache{ $_[0] } }
sub existsCacheEntry { return exists $Cache{ $_[0] }; }
sub is_CacheEmpty    { keys %Cache == 0 }

sub uncache {
    my %opt = Params::Validate::validate(
        @_,
        {
            All     => { default  => undef, type => Params::Validate::SCALAR },
            App     => { default  => undef, type => Params::Validate::SCALAR },
            Site    => { optional => 1,     type => Params::Validate::SCALAR },
            CacheID => { default  => undef, type => Params::Validate::SCALAR },
        } );

    if ( $opt{All} ) {
        delete $opt{All};
        croak( "can't specify All option with other options\n" )
          if any { defined } values %opt;
        %Cache = ();
    }

    elsif ( defined $opt{CacheID} ) {
        my $cacheid = delete $opt{CacheID};
        croak( "can't specify CacheID option with other options\n" )
          if any { defined } values %opt;

        delete $Cache{$cacheid};
    }
    else {
        croak( "must specify App or CacheID options\n" )
          unless defined $opt{App};

        # don't use normal rules for Site specification as we're trying
        # to delete a specific one.
        delete $Cache{ modulename( app_env_site( exists $opt{Site} ? ( $opt{Site} ) : () ), $opt{App} ) };
    }

    return;
}

#-------------------------------------------------------

my %existsModule;

sub loadModuleList {
    %existsModule = ();

    for my $path ( Module::Find::findallmod( 'App::Env' ) ) {
        # greedy match picks up full part of path
        my ( $base, $app ) = $path =~ /^(.*)::(.*)/;

        # store lowercased module
        $existsModule{ $base . q{::} . lc $app } = $path;
    }

    return;
}

sub existsModule {
    my ( $path ) = @_;

    # reconstruct path with lowercased application name.
    # greedy match picks up full part of path
    my ( $base, $app ) = $path =~ /^(.*)::(.*)/;
    $path = $base . q{::} . lc $app;

    # (re)load cache if we can't find the module in the list
    loadModuleList()
      unless $existsModule{$path};

    # really check
    return $existsModule{$path};
}


# allow site specific site definition
use constant APP_ENV_SITE => do {
    if ( !exists $ENV{APP_ENV_SITE} && existsModule( 'App::Env::Site' ) ) {
        eval { require App::Env::Site; 1; } // croak( ref $@ ? $@ : "Error loading App::Env::Site: $@\n" );
    }

    # only use the environment variable if defined and not empty.
    defined $ENV{APP_ENV_SITE}
      && length $ENV{APP_ENV_SITE} ? $ENV{APP_ENV_SITE} : undef;
};

# _App_Env_Site ( [$alt_site] );
# if $alt_site is non-empty, return it.
# if $alt_site is empty or undefined return ().
# otherwise return APP_ENV_SITE
sub app_env_site {

    @_ || return APP_ENV_SITE;

    my $site = shift;

    return () if !defined $site || $site eq q{};
    return $site;

# App::Env::_Util::croak( "Environment variable APP_ENV_SITE is only obeyed at the time that ${ \__PACKAGE__ } is loaded" )
#   if ( defined( APP_ENV_SITE ) xor defined $ENV{APP_ENV_SITE} )
#   || ( defined( APP_ENV_SITE ) && defined $ENV{APP_ENV_SITE} && APP_ENV_SITE ne $ENV{APP_ENV_SITE} );
}


sub shell_escape {
    my $str = shift;

    # empty string
    return q{''} unless length( $str );

    # otherwise, escape all but the "known" non-magic characters.
    $str =~ s{([^\w/.:=\-+%@,])}{\\$1}go;

    return $str;
}

#-------------------------------------------------------

sub modulename {
    return join( q{::}, 'App::Env', grep { defined } @_ );
}

#-------------------------------------------------------

sub exclude_param_check {
    !ref $_[0]
      || 'ARRAY' eq ref $_[0]
      || 'Regexp' eq ref $_[0]
      || 'CODE' eq ref $_[0];
}

#-------------------------------------------------------

# construct a module name based upon the current or requested site.
# requires the module if found.  returns the module name if module is
# found, undef if not, die's if require fails

sub require_module {
    my ( $app, %par ) = @_;

    my $app_opts = $par{app_opts} //= {};
    my $loop     = $par{loop}     //= 1;

    croak( "too many alias loops for $app\n" )
      if $loop == 10;

    my @sites = app_env_site( exists $par{site} ? $par{site} : () );

    # check possible sites, in turn.
    my ( $module )
      = grep { defined } ( map { existsModule( modulename( $_, $app ) ) } @sites ),
      existsModule( modulename( $app ) );

    if ( defined $module ) {
        ## no critic ( ProhibitStringyEval );
        eval "require $module"
          or croak $@;

        # see if this is an alias
        if ( my $alias = $module->can( 'alias' ) ) {
            ( $app, my $napp_opts ) = $alias->();
            @{$app_opts}{ keys %$napp_opts } = @{$napp_opts}{ keys %$napp_opts }
              if $napp_opts;
            return require_module(
                $app, %par,
                loop     => ++$loop,
                app_opts => $app_opts,
            );
        }
    }

    else {
        return ( undef );
    }

    return ( $module, $app_opts );
}

1;

#
# This file is part of App-Env
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

App::Env::_Util - Utilities

=head1 VERSION

version 1.04

=for Pod::Coverage app_env_site
croak
deleteCacheEntry
exclude_param_check
existsCacheEntry
existsModule
getCacheEntry
is_CacheEmpty
loadModuleList
modulename
require_module
setCacheEntry
shell_escape
uncache

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-app-env@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Env>

=head2 Source

Source is available at

  https://gitlab.com/djerius/app-env

and may be cloned from

  https://gitlab.com/djerius/app-env.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<App::Env|App::Env>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
