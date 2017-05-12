package Cvs::Command::Login;

use strict;
use Cvs::Result::Login;
use Cvs::Cvsroot;
use base qw(Cvs::Command::Base);

sub init
{
    my($self, $param) = @_;
    $self->SUPER::init(@_) or return;

    $self->default_params(cvsroot => undef);
    $self->param($param);

    $self->command('login');


    my $result = new Cvs::Result::Login;
    $self->result($result);

    my $cvsroot;
    if(defined $self->param->{cvsroot})
    {
        $cvsroot =
          new Cvs::Cvsroot $self->param->{cvsroot}, %$param;
        $self->cvsroot($cvsroot);
    }
    elsif(defined $self->cvs->cvsroot())
    {
        $cvsroot = $self->cvs->cvsroot();
    }
    else
    {
        $result->success(0);
        $result->error('No cvsroot to login on, please define one.');
        $self->command(undef);
    }

    my $main = $self->new_context();
    $self->initial_context($main);

    $main->push_handler
    (
     qr/^CVS password/, sub
     {
         $self->send($cvsroot->password()."\n");
     }
    );
    $main->push_handler
    (
     qr/can only use .login. command with the .pserver. method/, sub
     {
         # do not fail if login was used with bad method, we don't care
         $result->success(1);
         $main->finish();
     }
    );
    $main->push_handler
    (
     qr/cvs login: authorization failed/, sub
     {
         $result->success(0);
         $result->error('authorization failed');
         $main->finish();
     }
    );

    return $self;
}

1;
=pod

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

=head1 COPYRIGHT

Copyright (C) 2003 - Olivier Poitrey

