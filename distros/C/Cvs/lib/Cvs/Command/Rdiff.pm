package Cvs::Command::Rdiff;

use strict;
use Cvs::Result::RdiffList;
use Cvs::Result::RdiffItem;
use base qw(Cvs::Command::Base);
 
sub init
{
    my($self, @modules) = @_;
    $self->SUPER::init(@_) or return;

    $self->default_params
      (
       from_date => undef,
       to_date => undef,
       from_revision => undef,
       to_revision => undef,
      );
    my $param = pop @modules
      if ref $modules[-1] eq 'HASH';
    $param = $self->param($param||{});

    return
      $self->error('can\'t have more than one source type')
        if((defined $param->{from_date}
            and defined $param->{from_revision}));
    return
      $self->error('can\'t have more than one destination type')
        if((defined $param->{to_date}
            and defined $param->{to_revision}));

    return $self->error('you must specify a source')
        if not defined $self->param->{from_date}
          and not defined $self->param->{from_revision};

    $self->command('rdiff');
    $self->push_arg('-u');
    $self->push_arg('-r', $self->param->{from_revision})
      if defined $self->param->{from_revision};
    $self->push_arg('-D', $self->param->{from_date})
      if defined $self->param->{from_date};
    $self->push_arg('-r', $self->param->{to_revision})
      if defined $self->param->{to_revision};
    $self->push_arg('-D', $self->param->{to_date})
      if defined $self->param->{to_date};
    $self->push_arg(@modules);
    $self->need_workdir(0);

    my $main = $self->new_context();
    $self->initial_context($main);

    my $result;
    my $resultlist = new Cvs::Result::RdiffList;
    $resultlist->success(1);
    $self->result($resultlist);

    $main->push_handler
    (
     qr/^Index: (.*)\n$/, sub
     {
         $result = new Cvs::Result::RdiffItem;
         $result->filename(shift->[1]);
         $result->success(1);
         $resultlist->push($result);
     }
    );
    $main->push_handler
    (
     qr/^diff -u (?:\/dev\/null|.*?:([\d\.]+))\s+.*?:([\d\.]+|removed)$/, sub
     {
         my($match) = @_;
         my($r1, $r2) = ($match->[1], $match->[2]);
         if(defined $r1 and length $r1)
         {
             $result->from_revision($r1);
         }
         else
         {
             $result->is_added(1);
         }
         if($r2 eq 'removed')
         {
             $result->is_removed(1);
         }
         else
         {
             $result->to_revision($r2);
         }
         $result->push_diff($match->[0]);
     }
    );
    $main->push_handler
    (
     qr/^cvs rdiff: .*$/, sub
     {
         # do nothing
     }
    );
    $main->push_handler
    (
     qr/^[\-\+@ ]/, sub
     {
         $result->push_diff(shift->[0]);
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

