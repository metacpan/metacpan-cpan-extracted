package Cvs::Command::Diff;

use strict;
use Cvs::Result::DiffList;
use Cvs::Result::DiffItem;
use base qw(Cvs::Command::Base);

sub init
{
    my($self, @file_list) = @_;
    $self->SUPER::init(@_) or return;

    $self->default_params
      (
       multiple => 0,
       recursive => 1,
       from_date => undef,
       to_date => undef,
       from_revision => undef,
       to_revision => undef,
      );
    my $param = pop @file_list
      if ref $file_list[-1] eq 'HASH';
    $param = $self->param($param||{});

    return
      $self->error('can\'t have more than one source type')
        if((defined $self->param->{from_date}
            and defined $self->param->{from_revision}));
    return
      $self->error('can\'t have more than one destination type')
        if((defined $self->param->{to_date}
            and defined $self->param->{to_revision}));

    return
      $self->error('can\'t have a destination without a source')
        if((defined $self->param->{to_revision}
            or defined $self->param->{to_date})
           and
           (not defined $self->param->{from_revision}
            and not defined $self->param->{from_revision}));

    $self->command('diff');
    $self->push_arg('-u2', '-N');
    $self->push_arg('-r', $self->param->{from_revision})
      if defined $self->param->{from_revision};
    $self->push_arg('-D', $self->param->{from_date})
      if defined $self->param->{from_date};
    $self->push_arg('-r', $self->param->{to_revision})
      if defined $self->param->{to_revision};
    $self->push_arg('-D', $self->param->{to_date})
      if defined $self->param->{to_date};
    $self->push_arg(@file_list);

    my $main = $self->new_context();
    $self->initial_context($main);

    my $resultlist;
    my $result = $self->err_result('No file in response');
    $self->result($result);

    $main->push_handler
    (
     qr/^Index: (.*)\n$/, sub
     {
         my($match) = @_;
         if($self->param->{multiple})
         {
             unless(defined $resultlist)
             {
                 $resultlist = new Cvs::Result::DiffList;
                 $self->result($resultlist);
             }
             $result = new Cvs::Result::DiffItem;
             $resultlist->push($result);
         }
         else
         {
             if($result->isa('Cvs::Result::DiffItem'))
             {
                 # first item is complete, don't continue
                 return $main->finish()
             }
             else
             {
                 $result = new Cvs::Result::DiffItem;
                 $self->result($result);
             }
         }
         $result->success(1);
         $result->filename($match->[1]);
         $result->push_diff($match->[0]);
     }
    );
    $main->push_handler
    (
     qr/^=+$/, sub
     {
         $result->push_diff(shift->[0]);
     }
    );
    $main->push_handler
    (
     qr/^RCS file: (.*)\n$/, sub
     {
         my($match) = @_;
         $result->rcs_file($match->[1]);
         $result->push_diff($match->[0]);
     }
    );
    $main->push_handler
    (
     qr/^retrieving revision .*$/, sub
     {
         $result->push_diff(shift->[0]);
     }
    );
    $main->push_handler
    (
     qr/^diff .*(?:-r([.\d]+)).*(?: -r([.\d]+))?.*$/, sub
     {
         my($match) = @_;
         $result->from_revision($match->[1]);
         $result->to_revision($match->[2]);
         $result->push_diff($match->[0]);
     }
    );
    $main->push_handler
    (
     qr/^cvs server: .*$/, sub
     {
         # do nothing
     }
    );
    $main->push_handler
    (
     qr/^\? /, sub
     {
         # do nothing
     }
    );
    $main->push_handler
    (
     qr/^[\-\+@ ]/, sub
     {
         my $line = shift->[0];
         if(index($line, '--- /dev/null') == 0)
         {
             warn "new";
             $result->is_added(1);
         }
         elsif(index($line, '+++ /dev/null') == 0)
         {
             $result->is_removed(1);
         }
         $result->push_diff($line);
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

