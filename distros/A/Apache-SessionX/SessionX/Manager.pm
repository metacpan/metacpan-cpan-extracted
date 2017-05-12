###################################################################################
#
#   Apache::SessionX - Copyright (c) 1999-2001 Gerald Richter / ecos gmbh
#   Copyright(c) 1998, 1999 Jeffrey William Baker (jeffrey@kathyandjeffrey.net)
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Manager.pm,v 1.1 2002/03/12 08:50:32 richter Exp $
#
###################################################################################


package Apache::SessionX::Manager ;

use strict;
use vars qw(@ISA $VERSION);

$VERSION = '2.00b5';

use Apache::Session;
use Apache::SessionX::Config ;

sub new 
    {
    my $class = shift;
    
    my $args       = shift || {};

    if(ref $args ne "HASH") 
        {
        die "Additional arguments should be in the form of a hash reference";
        }

    my $config = $args -> {config} || $Apache::SessionX::Config::default;
    foreach my $cfg (keys  (%{$Apache::SessionX::Config::param{$config}})) 
        {
        $args -> {$cfg} = $Apache::SessionX::Config::param{$config} -> {$cfg} if (!exists $args -> {$cfg}) ;
        }  
    
    my $self = 
        {
        args         => $args,
        };
    
    bless $self, $class;

    Apache::SessionX -> require_modules ($args) ;
    Apache::SessionX::populate ($self) ;


    return $self ;
    }


sub count_sessions 
    {
    my $self = shift;
    return $self->{object_store}->count_sessions($self);
    }
 
sub first_session_id 
    {
    my $self = shift;
    return $self->{object_store}->first_session_id($self);
    }
 
sub next_session_id 
    {
    my $self = shift;
    return $self->{object_store}->next_session_id($self);
    }
 
sub first_session 
    {
    my $self = shift;
    my %session ;
    my $id = $self -> first_session_id ;

    return undef if (!$id) ;

    tie %session, 'Apache::SessionX', $id, $self -> {args} ;
    
    return \%session ;
    }
 
sub next_session 
    {
    my $self = shift;
    my $id = $self -> next_session_id ;
    my %session ;

    return undef if (!$id) ;

    tie %session, 'Apache::SessionX', $id, $self -> {args} ;
    
    return \%session ;
    }
 
