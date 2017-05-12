#!/usr/bin/perl -sw
##
##
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: Forked.pm,v 1.3 2001/06/10 15:43:04 vipul Exp $

package Concurrent::Object::Forked;
use Class::Loader;
use overload;
use Data::Dumper;
use Concurrent::Debug qw(debug debuglevel);
use base qw(Concurrent::Errorhandler);

sub new {

    my ($class, %params) = @_;

    my $channel = $params{Channel};
    my $proxy   = $params{Proxy};
    my $self    = bless {}, $class;

    if (fork == 0) {

        # initialize our side of communication channel
        $channel->init();

        # create the object and report status to proxy
        my $obj = $self->load (%params);

        unless ($obj) {
            $channel->print ( { Status => 'Failure' } );
            exit 0;
        } else {
            my %status = ( Status => 'Success' );
            if (my $od = $self->overloaded ($obj)) { 
                debug ("somebody setup us the overload!");
                $status{Overloaded} = 1 if $od;
            }
            $channel->print ( \%status );
        }

        my %secondaries = ( 0 => $obj );
        my $sc = 0;

        # call methods requested by the proxy
        while (my $call = $channel->getline) {

            my ($method, $args, $context);

            $obj = $$call{Secondary} ? $secondaries{$$call{Secondary}} : $secondaries{0};
            $context = $$call{Context} || 'scalar';

            if ($$call{Method}) { 
                $method  = $$call{Method};  
                debug ("calling $method() on the object");
                $args    = $$call{Args};
            } elsif ($$call{Operation}) { 
                my $operation = $$call{Operation}; 
                debug ("calling overloaded method corresponding to @$operation[2] (ID: $$call{Id})");
                $method = overload::Method($obj, $operation->[2]);
                $args   = [ $operation->[0], $operation->[1] ];
            } else { next }

            my %RV; $RV{Id} = $$call{Id};

            if ($context eq 'list') {
                my @rv = $obj->$method (@$args);
                $RV{Rv} = [@rv];
            } else {
                my $rv;
                if (ref $method) {  # overloaded operator handler
                    $rv = &$method ($obj, @$args);
                } else { 
                    $rv = $obj->$method (@$args);
                }
                if ((ref $rv) && ($rv eq $obj)) {
                    debug ("got myself as return value");
                    $rv = undef;
                    $RV{Self} = 1;
                } elsif ((ref $rv) && ((ref $rv) !~ /(^SCALAR|ARRAY|HASH|CODE|REF|GLOB|LVALUE$)/)) { 
                    debug ("built a secondary object");
                    $secondaries{++$sc} = $rv;
                    $rv = undef;
                    $RV{Secondary} = $sc;
                }
                debug ("$$call{Method}() returned undef.") unless $rv;
                $RV{Rv} = $rv;
            }

            $channel->print (\%RV);
            debug ("wrote result of $$call{Method} to parent...") if exists $$call{Method};

        }

        # proxy closed the comms channel, so we close it from our side 
        # and commit suicide
        undef $obj;
        $channel->destroy();
        exit 0;

    }

}
        

sub load { 

    my ($self, %params) = @_;
    my $loader = new Class::Loader;
    return $loader->_load ( 
        Module      => $params{Class}, 
        Constructor => $params{Constructor},
        Args        => $params{Args}
    );

}


sub overloaded {

    my ($self, $thing) = @_;
    return unless overload::Overloaded ($thing);
    return 1;

}


1;



