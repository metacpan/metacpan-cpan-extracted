package Bintray::API::Search;

#######################
# LOAD CORE MODULES
#######################
use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);

#######################
# VERSION
#######################
our $VERSION = '1.0.2';

#######################
# LOAD CPAN MODULES
#######################
use Params::Validate qw(validate_with :types);

use Object::Tiny qw(
  session
  max_results
);

#######################
# LOAD DIST MODULES
#######################
use Bintray::API::Session;

#######################
# PUBLIC METHODS
#######################

## Constructor
sub new {
    my ( $class, @args ) = @_;
    my %opts = validate_with(
        params => [@args],
        spec   => {
            session => {
                type => OBJECT,
                isa  => 'Bintray::API::Session',
            },
            max_results => {
                type    => SCALAR,
                regex   => qr/^\d+$/x,
                default => '100',
            },
        },
    );

  return $class->SUPER::new(%opts);
} ## end sub new

#######################
# API METHODS
#######################

## Search Repos
sub repos {
    my ( $self, @args ) = @_;
    my %opts = validate_with(
        params => [@args],
        spec   => {
            name => {
                type    => SCALAR,
                default => '',
            },
            desc => {
                type    => SCALAR,
                default => '',
            },
        },
    );

    # Need either name or description
    $opts{name}
      or $opts{desc}
      or croak "ERROR: Please provide a name or desc to search for ...";

  return $self->session()->paginate(
        path  => '/search/repos',
        max   => $self->max_results(),
        query => [
            ( $opts{name} ? { name => $opts{name} } : () ),
            ( $opts{desc} ? { desc => $opts{desc} } : () ),
        ],
    );
} ## end sub repos

## Search Packages
sub packages {
    my ( $self, @args ) = @_;
    my %opts = validate_with(
        params => [@args],
        spec   => {
            name => {
                type    => SCALAR,
                default => '',
            },
            desc => {
                type    => SCALAR,
                default => '',
            },
            repo => {
                type    => SCALAR,
                default => '',
            },
            subject => {
                type    => SCALAR,
                default => '',
            },
        },
    );

    # Need either name or description
    $opts{name}
      or $opts{desc}
      or croak "ERROR: Please provide a name or desc to search for ...";

  return $self->session()->paginate(
        path  => '/search/packages',
        max   => $self->max_results(),
        query => [
            ( $opts{name} ? { name => $opts{name} } : () ),
            ( $opts{desc}    ? { desc    => $opts{desc} }    : () ),
            ( $opts{repo}    ? { repo    => $opts{repo} }    : () ),
            ( $opts{subject} ? { subject => $opts{subject} } : () ),
        ],
    );
} ## end sub packages

## Search Users
sub users {
    my ( $self, @args ) = @_;
    my %opts = validate_with(
        params => [@args],
        spec   => {
            name => {
                type => SCALAR,
            },
        },
    );

  return $self->session()->paginate(
        path  => '/search/users',
        max   => $self->max_results(),
        query => [ { name => $opts{name} }, ],
    );
} ## end sub users

## Search Files
sub files {
    my ( $self, @args ) = @_;
    my %opts = validate_with(
        params => [@args],
        spec   => {
            name => {
                type    => SCALAR,
                default => '',
            },
            sha1 => {
                type    => SCALAR,
                regex   => qr/^[\da-z]{40}$/x,
                default => '',
            },
            repo => {
                type    => SCALAR,
                default => '',
            },
        },
    );

    # Need either name or description
    $opts{name}
      or $opts{sha1}
      or croak "ERROR: Please provide a name or sha1 to search for ...";

    if ( $opts{sha1} ) {
      return $self->session()->paginate(
            path  => '/search/file',
            max   => $self->max_results(),
            query => [
                { sha1 => $opts{sha1} },
                ( $opts{repo} ? { repo => $opts{repo} } : () ),
            ],
        );
    } ## end if ( $opts{sha1} )

    if ( $opts{name} ) {
      return $self->session()->paginate(
            path  => '/search/file',
            max   => $self->max_results(),
            query => [
                { name => $opts{name} },
                ( $opts{repo} ? { repo => $opts{repo} } : () ),
            ],
        );
    } ## end if ( $opts{name} )

  return;
} ## end sub files

#######################
1;

__END__
