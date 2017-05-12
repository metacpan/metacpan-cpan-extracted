#!/usr/bin/perl -s
##
## Concurrent::Object
##
## Copyright (c) 2001, Vipul Ved Prakash. All rights reserved. This code
## is free software; you can redistribute it and/or modify it under the
## same terms as Perl itself.
##
## $Id: Object.pm,v 1.7 2001/06/20 20:20:41 vipul Exp $

package Concurrent::Object;

use lib '../lib', 'lib';
require Exporter;
use Data::Dumper;
use Concurrent::Object::Proxy;
use Concurrent::Debug qw(debug);
use Concurrent::Object::Data::DefferedRV;
*import = \&Exporter::import;
use vars qw($VERSION $AUTOLOAD @EXPORT);
$VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; 
@EXPORT = qw( Concurrent );


sub Concurrent { 

    my ($proxyclass, %params) = @_;

    my $self = {%params}; 
    $$self{Method} ||= 1;
    $$self{ProxyClass} = $proxyclass;
    return undef unless $$self{ProxyClass};
    return bless $self, __PACKAGE__;

} 


sub AUTOLOAD { 

    my ($self, @args) = @_; 
    my $class = ref $self;
    my $method = $AUTOLOAD; $method =~ s/.*:://;
    my $context = wantarray ? 'list' : 'scalar';

    return if $method eq "DESTROY";

    unless ($self->{proxy}) { # we'll call the constructor here 

        $$self{proxy} = new Concurrent::Object::Proxy (
                                   Class => $self->{ProxyClass},
                             Constructor => $method, 
                                    Args => \@args, 
                        ProxyOverloading => 'No' );

        if ($self->{proxy}->{Overloaded}) { 
            debug( "setting up proxy overloading in C::O" );
            eval 'use overload fallback => 1, nomethod => "genover"';
            bless $self, $class;
        }

        return $self;

    } 

    my %params = ( Method => $method, Context => $context, Args => \@args, Secondary => $self->{Secondary} ); 

    # method() does a normal method call, method_bg() does $proxy->call, 
    # method_fg() does $proxy->rv
    if ($$self{Method} == 1) {  
        if ($method =~ s/_bg$//) { 
            $self->__method_bg ( %params, ( Method => $method ) );
            return;
        } elsif ($method =~ s/_fg$//) { 
            return $self->__method_fg ( %params, (Method => $method) );
        } else { 
            return $self->__method ( %params );
        }

    # method() does $proxy->call, method_fg() does $proxy->rv
    # or normal method() if method() was not called before
    } elsif ($$self{Method} == 2) { 
        if ($method =~ s/_fg$//) { 
            my $id = shift @{ $self->{CT}->{$method} }; 
            if ($id) { 
                return $self->__method_fg ( %params, (Id => $id) );
            } else { 
                return $self->__method ( %params )
            }
         } else { 
            $self->__method_bg ( %params );
         }

    # method() returns defferedscalar, method_fg() works
    # like normal method()
    } elsif ($$self{Method} == 3) { 
        debug ("calling method $method");
        if ($method =~ s/_fg$// || $params{Context} ne 'scalar') { 
            return $self->__method ( %params, ( Method => $method ) )
        } else { 
            my $id = $self->__method_bg ( %params );
            return new Concurrent::Object::Data::DefferedRV (CO => $self, Id => $id);
        }
    }

} 


sub __method {

    my ($self, %params) = @_;
    return if $params{Method} eq "DESTROY";
    my $id = $self->__method_bg (%params);
    return $self->__method_fg (Id => $id, Context => $params{Context});

} 

sub __method_bg { 

    my ($self, %params) = @_; 
    return if $params{Method} eq "DESTROY";
    my $id = $self->{proxy}->call ( %params );
    push @{ $self->{CT}->{$params{Method}} }, $id; 
    return $id; 

}


sub __method_fg { 

    my ($self, %params) = @_;
    my $id = $params{Id} ? $params{Id} : shift @{ $self->{CT}->{$params{Method}} };
    return undef unless $id;
    if (exists $params{Context} && ($params{Context} eq 'list')) { 
        my @rv = $self->{proxy}->rv ( %params, Id => $id );
        return @rv;
    } else {
        my $rv = $self->{proxy}->rv ( Id => $id );
        $rv = $self if $rv && ($rv eq $self->{proxy});
        if (ref $rv eq 'Concurrent::Object::Proxy::Secondary') { 
            $rv = bless { 
                   proxy => $self->{proxy}, 
                   Secondary => $rv->{Secondary},
                   Method => $self->{Method},
                  }, ref $self;
        }
        return $rv;
    }

}


sub genover { 

    my ($self, @args) = @_;
    my $id = $self->{proxy}->call ( Operation => \@args, Secondary => $self->{Secondary} );
    return $self->{proxy}->rv ( Id => $id );

}
 
1;

=head1 NAME

Concurrent::Object - Concurrent Objects in Perl.

=head1 VERSION

    $Revision: 1.7 $

=head1 SYNOPSIS

    use Concurrent::Object; 

    my $co = Concurrent( 'class' )->constructor( @arguments );

    $co->method_bg;           # returns immediately
    my $rv = $co->method_fg;  # blocks

    OR 

    my $co = Concurrent( 'class', Method => 3 )->constructor( @arguments );
    
    my $rv = $co->method;     # returns immediately
    $rv->value;               # blocks

=head1 WARNING

This is Alpha software.

=head1 DESCRIPTION

[coming soon]

=head1 AUTHOR

Vipul Ved Prakash, E<lt>mail@vipul.netE<gt>

=cut


