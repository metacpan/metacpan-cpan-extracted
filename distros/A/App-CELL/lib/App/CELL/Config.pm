# ************************************************************************* 
# Copyright (c) 2014-2020, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

package App::CELL::Config;

use strict;
use warnings;
use 5.012;

use App::CELL::Log qw( $log );
use App::CELL::Status;
#use Data::Dumper;
use Scalar::Util qw( blessed );

=head1 NAME

App::CELL::Config -- load, store, and dispense meta parameters, core
parameters, and site parameters



=head1 SYNOPSIS
 
    use App::CELL::Config qw( $meta $core $site );

    # get a parameter value (returns value or undef)
    my $value;
    $value = $meta->MY_PARAM;
    $value = $core->MY_PARAM;
    $value = $site->MY_PARAM;

    # set a meta parameter
    $meta->set( 'MY_PARAM', 42 );

    # set an as-yet undefined core/site parameter
    $core->set( 'MY_PARAM', 42 );
    $site->set( 'MY_PARAM', 42 );



=head1 DESCRIPTION

The purpose of the L<App::CELL::Config> module is to maintain and provide
access to three package variables, C<$meta>, C<$core>, and C<$site>, which
are actually singleton objects, containing configuration parameters loaded
by L<App::CELL::Load> from files in the distro sharedir and the site
configuration directory, if any.

For details, read L<App::CELL::Guilde>.



=head1 EXPORTS

This module exports three scalars: the 'singleton' objects C<$meta>,
C<$core>, and C<$site>.

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( $meta $core $site );

our $meta = bless { CELL_CONFTYPE => 'meta' }, __PACKAGE__;
our $core = bless { CELL_CONFTYPE => 'core' }, __PACKAGE__;
our $site = bless { CELL_CONFTYPE => 'site' }, __PACKAGE__;



=head1 SUBROUTINES


=head2 AUTOLOAD

The C<AUTOLOAD> routine handles calls that look like this:
   $meta->MY_PARAM
   $core->MY_PARAM
   $site->MY_PARAM

=cut

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    ( my $param ) = $AUTOLOAD =~ m/.*::(.*)$/;
    return SUPER->DESTROY if $param eq 'DESTROY'; # for Perl <= 5.012
    my ( undef, $file, $line ) = caller;
    die "Bad call to Config.pm \$$param at $file line $line!" if not blessed $self;
    return _retrieve_param( $self->{'CELL_CONFTYPE'}, $param );
}

sub _retrieve_param {
    my ( $type, $param ) = @_;
    if ( $type eq 'meta' ) {
        return (exists $meta->{$param})
            ? $meta->{$param}->{Value}
            : undef;
    } elsif ( $type eq 'core' ) {
        return (exists $core->{$param})
            ? $core->{$param}->{Value}
            : undef;
    } elsif ( $type eq 'site' ) {
        if (exists $site->{$param}) {
            return $site->{$param}->{Value};
        } elsif (exists $core->{$param}) {
            return $core->{$param}->{Value};
        }
    }
    return;
}


=head2 DESTROY

For some reason, Perl 5.012 seems to want a DESTROY method

=cut 

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}


=head2 exists

Determine parameter existence.

=cut

sub exists {
    my ( $self, $param ) = @_;
    my $type = $self->{'CELL_CONFTYPE'};

    my $bool;
    if ( $type eq 'meta' ) {
        $bool = exists $meta->{ $param };
    } elsif ( $type eq 'core' ) {
        $bool = exists $core->{ $param };
    } elsif ( $type eq 'site' ) {
        $bool = exists $site->{ $param };
        if ( ! $bool ) {
            $bool = exists $core->{ $param };
        }
    } else {
        die "AAAAAAAAAAGGAHHAGHHG! improper param type in exists routine";
    }
    return $bool;
}


=head2 get

Wrapper for get_param

=cut

sub get {
    my ( $self, $param ) = @_;
    return $self->get_param( $param );
}


=head2 get_param

Get value of config param provided in the argument.

=cut

sub get_param {
    my ( $self, $param ) = @_;
    my ( undef, $file, $line ) = caller;
    die "Bad call to Config.pm \$$param at $file line $line!" if not blessed $self;
    return _retrieve_param( $self->{'CELL_CONFTYPE'}, $param );
}


=head2 get_param_metadata

Routine to provide access not only to the value, but also to the metadata
(file and line number where parameter was defined) associated with a
given parameter.

Takes: parameter name.  Returns: reference to the hash associated with the
given parameter, or undef if no parameter found.

=cut

sub get_param_metadata {
    my ( $self, $param ) = @_;
    my ( undef, $file, $line ) = caller;
    die "Bad call to Config.pm \$$param at $file line $line!" if not blessed $self;
    my $type = $self->{'CELL_CONFTYPE'};
    if ( $type eq 'meta' ) {
        return (exists $meta->{$param})
            ? $meta->{$param}
            : undef;
    } elsif ( $type eq 'core' ) {
        return (exists $core->{$param})
            ? $core->{$param}
            : undef;
    } elsif ( $type eq 'site' ) {
        if (exists $site->{$param}) {
            return $site->{$param};
        } elsif (exists $core->{$param}) {
            return $core->{$param};
        }
    }
    return;
}


=head2 set

Use this function to set new params (meta/core/site) or change existing
ones (meta only). Takes two arguments: parameter name and new value. 
Returns a status object.

=cut

sub set {
    my ( $self, $param, $value ) = @_;
    return App::CELL::Status->not_ok if not blessed $self;
    my %ARGS = (
                    level => 'OK',
                    caller => [ CORE::caller() ],
               );
    if ( $self->{'CELL_CONFTYPE'} eq 'meta' ) {
        if ( exists $meta->{$param} ) {
            %ARGS = (   
                        %ARGS,
                        code => 'CELL_OVERWRITE_META_PARAM',
                        args => [ $param, ( defined( $value ) ? $value : 'undef' ) ],
                    );
            #$log->debug( "Overwriting \$meta->$param with ->$value<-", cell => 1 );
        } else {
            #$log->debug( "Setting new \$meta->$param to ->$value<-", cell => 1 );
        }
        $meta->{$param} = {
                               'File' => (caller)[1],
                               'Line' => (caller)[2],
                               'Value' => $value,
                          };
    } elsif ( $self->{'CELL_CONFTYPE'} eq 'core' ) {
        if ( exists $core->{$param} ) {
            %ARGS = (
                        %ARGS,
                        level => 'ERR',
                        code => 'CELL_PARAM_EXISTS_IMMUTABLE',
                        args => [ 'Core', $param ],
                    );
        } else {
            $core->{$param} = {
                                   'File' => (caller)[1],
                                   'Line' => (caller)[2],
                                   'Value' => $value,
                              };
        }
    } elsif ( $self->{'CELL_CONFTYPE'} eq 'site' ) {
        if ( exists $site->{$param} ) {
            %ARGS = (
                        %ARGS,
                        level => 'ERR',
                        code => 'CELL_PARAM_EXISTS_IMMUTABLE',
                        args => [ 'Site', $param ],
                    );
        } else {
            $site->{$param} = {
                                   'File' => (caller)[1],
                                   'Line' => (caller)[2],
                                   'Value' => $value,
                              };
        }
    }
    return App::CELL::Status->new( %ARGS );
}

# END OF App::CELL::Config MODULE
1;
