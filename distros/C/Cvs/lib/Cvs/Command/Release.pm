package Cvs::Command::Release;

use strict;
use Cvs::Result::Release;
use base qw(Cvs::Command::Base);

sub init
{
    my($self, @modules) = @_;
    $self->SUPER::init(@_) or return;

    my $param = {};
    if(defined $modules[-1] && ref $modules[-1] eq 'HASH')
    {
        $param = pop @modules;
    }

    $self->default_params
      (
       delete_after => 0,
       force => 0,
      );

    $self->param($param);


    $self->command('release');
    $self->push_arg('-d')
      if $self->param->{delete_after};
    $self->push_arg(@modules ? @modules : $self->cvs->workdir());
    $self->go_into_workdir(0);

    my $main = $self->new_context();
    $self->initial_context($main);

    my $result = new Cvs::Result::Release;
    $self->result($result);

    $main->push_handler
    (
     qr/^M (.*)$/, sub
     {
         $result->push_altered(shift->[1]);
     }
    );
    $main->push_handler
    (
     qr/^You have \[(\d+)\] altered files in this repository\.$/, sub
     {
         my($match) = @_;
         unless($match->[1] == $result->altered())
         {
             my $found = $result->altered();
             warn "Internal error, we haven't found an equal ".
               "number of altered files than cvs. ".
                 "Found: $found cvs said: $match->[1]";
         }
     }
    );
    $main->push_handler
    (
     qr/^Are you sure you want to release.* directory .*:\s*$/, sub
     {
         if(defined $result->altered && $result->altered == 0 or $self->param->{force})
         {
             $self->send("y\n");
         }
         else
         {
             $self->send("n\n");
         }
         $result->success(1);
     }
    );
    $main->push_handler
    (
     qr/cvs release: deletion of directory .* failed: Invalid argument/, sub
     {
         $result->success(0);
         $result->error(shift->[0]);
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

