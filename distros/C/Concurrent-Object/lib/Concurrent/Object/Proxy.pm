#!/usr/bin/perl -sw
##
##
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: Proxy.pm,v 1.1.1.1 2001/06/10 14:39:39 vipul Exp $


package Concurrent::Object::Proxy::Secondary;

sub new { 
    
    my ($class, %params) = @_;
    return bless { %params }, $class;

}


package Concurrent::Object::Proxy;
use lib '../../../lib';
use Concurrent::Channel::LinkedPipes;
use Concurrent::Object::Forked;
use Concurrent::Debug qw(debug debuglevel);
use Data::Dumper;

sub new { 

    my ($class, %params) = @_; 
    
    my $channel = new Concurrent::Channel::LinkedPipes Payload => 'Perl';

    my $self = {
        DEBUG   =>  1,
        MID     =>  0,
        MT      => {},
        Channel => $channel,
        %params  # remove this later if not required
    }; 
    
    bless $self, $class;

    my $obj = new Concurrent::Object::Forked ( Channel => $channel, %params );

    $channel->init();
    my $status = $channel->getline();

    if ($$status{Status} eq "Success") { 
        $$self{Overloaded} = 1;
        if ($$status{Overloaded}) { 
            $$self{Overloaded} = 1;
            # implement proxy overloading unless instructed not to.
            if ($$self{ProxyOverloading} ne 'No') {  
                debug ("setting up overloading in C::O::Proxy ...");
                eval 'use overload fallback => 1, nomethod => "genover"';
                bless $self, $class;
            }
        }
        return $self;
    } else { 
        return undef;
    }

}


sub call {

    my ($self, %params) = @_;
    my $mid = $self->mid();
    $$self{Channel}->print( {%params, Id => $mid} ) or die $$self{Channel}->errstr();
    return $mid;

}


sub rv {

    my ($self, %params) = @_;
    my $id = $params{Id};
    do {
        my $ret = $$self{MT}{$id};
        if (defined $ret) {
            delete $$self{MT}{$id};
            return exists $params{Context} && ($params{Context} eq 'list') ? @$ret : $ret
        }
        my $rv = $$self{Channel}->getline;
        $$self{MT}{$$rv{Id}} = $$rv{Rv};
        $$self{MT}{$$rv{Id}} = $self if !($$rv{Rv}) && exists( $$rv{Self} ) && ($$rv{Self} == 1);
        $$self{MT}{$$rv{Id}} = Concurrent::Object::Proxy::Secondary->new ( Secondary => $$rv{Secondary} ) if $$rv{Secondary};
        $ret = $$self{MT}{$id};
        if ($$rv{Id} eq $id) {
            delete $$self{MT}{$id};
            return exists $params{Context} && ($params{Context} eq 'list') ? @$ret : $ret
        }

    } until 0;

}


sub genover { 

    my ($self, @args) = @_;
    my $id = $self->call ( Operation => \@args );
    return $self->rv ( Id => $id );

}


sub mid {

    my $self = shift;
    return ++$$self{MID};

}


1;

