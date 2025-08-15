package App::Env::_app;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.05';

use App::Env::_Util;

use Storable ();
use Digest;

# new( pid => $pid, app => $app, opt => \%opt )
# new( pid => $pid, env => \%env, module => $module, cacheid => $cacheid )
sub new {
    my ( $class, %opt ) = @_;

    # make copy of options
    my $self = bless Storable::dclone( \%opt ), $class;

    if ( exists $self->{env} ) {
        $self->{opt} = {} unless defined $self->{opt};
        $self->{ENV} = delete $self->{env};
    }
    else {

        ( $self->{module}, my $app_opts ) = eval {
            App::Env::_Util::require_module(
                $self->{app},
                (
                    exists $self->{opt}{Site}
                    ? ( site => $self->{opt}{Site} )
                    : () ) );
        };

        App::Env::_Util::croak( ref $@
            ? $@
            : "error loading application environment module for $self->{app}:\n", $@, )
          if $@ ne q{};

        App::Env::_Util::croak( "application environment module for $self->{app} does not exist\n" )
          unless defined $self->{module};

        # merge possible alias AppOpts
        $self->{opt}{AppOpts} //= {};
        $self->{opt}{AppOpts} = { %$app_opts, %{ $self->{opt}{AppOpts} } };

        $self->mk_cacheid;
    }

    # return cached entry if possible
    if ( App::Env::_Util::existsCacheEntry( $self->cacheid ) && !$opt{opt}{Force} ) {
        $self = App::Env::_Util::getCacheEntry( $self->cacheid );
    }

    else {
        $self->load unless $self->{NoLoad};
        delete $self->{NoLoad};
    }

    return $self;
}

#-------------------------------------------------------

sub mk_cacheid {
    my ( $self, $cacheid ) = @_;

    $cacheid = $self->{opt}{CacheID} unless defined $cacheid;

    my @elements;

    if ( defined $cacheid ) {
        push @elements, $cacheid eq 'AppID' ? $self->{module} : $cacheid;
    }
    else {
        # create a hash of unique stuff which will be folded
        # into the cacheid
        my %uniq;
        $uniq{AppOpts} = $self->{opt}{AppOpts}
          if defined $self->{opt}{AppOpts} && keys %{ $self->{opt}{AppOpts} };

        my $digest;

        if ( keys %uniq ) {
            local $Storable::canonical = 1;    ## no critic( Variables::ProhibitPackageVars )
            $digest = Storable::freeze( \%uniq );

            # use whatever digest aglorithm we can find.  if none is
            # found, default to the frozen representation of the
            # options
            for my $alg ( qw[ SHA-256 SHA-1 MD5 ] ) {
                my $ctx = eval { Digest->new( $alg ) };

                if ( defined $ctx ) {
                    $digest = $ctx->add( $digest )->digest;
                    last;
                }
            }
        }
        push @elements, $self->{module}, $digest;
    }

    $self->cacheid( join( $;, grep { defined } @elements ) );
}


#-------------------------------------------------------

sub load {
    my ( $self ) = @_;

    # only load if we haven't before
    return $self->{ENV} if exists $self->{ENV};

    my $module = $self->module;

    my $envs;
    my $fenvs = $module->can( 'envs' );

    App::Env::_Util::croak( "$module does not have an 'envs' function\n" )
      unless $fenvs;

    $envs = eval { $fenvs->( $self->{opt}{AppOpts} ) };

    App::Env::_Util::croak( ref $@ ? $@ : "error in ${module}::envs: $@\n" )
      if $@;

    # make copy of environment
    $self->{ENV} = { %{$envs} };

    # cache it
    $self->cache if $self->{opt}{Cache};

    return $self->{ENV};
}

#-------------------------------------------------------

sub cache {
    my ( $self ) = @_;
    App::Env::_Util::setCacheEntry( $self->cacheid, $self );
}

#-------------------------------------------------------

sub uncache {
    my ( $self ) = @_;
    my $cacheid = $self->cacheid;

    App::Env::_Util::deleteCacheEntry( $cacheid )
      if App::Env::_Util::existsCacheEntry( $cacheid )
      && App::Env::_Util::getCacheEntry( $cacheid )->{pid} eq $self->{pid};
}

#-------------------------------------------------------

sub opt     { @_ > 1 ? $_[0]->{opt}     = $_[1] : $_[0]->{opt} }
sub cacheid { @_ > 1 ? $_[0]->{cacheid} = $_[1] : $_[0]->{cacheid} }
sub module  { $_[0]->{module} }

#-------------------------------------------------------

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

App::Env::_app

=head1 VERSION

version 1.05

=for Pod::Coverage cache
cacheid
load
mk_cacheid
module
new
opt
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
