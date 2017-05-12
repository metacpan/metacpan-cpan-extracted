package Cvs::Command::Update;

use strict;
use Cvs::Result::Update;
use base qw(Cvs::Command::Base);

sub init
{
    my($self, @files) = @_;
    $self->SUPER::init(@_) or return;

    $self->default_params
      (
       revision => undef,
       date => undef,
       reset => 0,
       send_to_stdout => 0,
       build_directories => 0,
       overwrite_local_modified => 0,
       recursive => 1,
      );
    my $param = ref $files[-1] ? pop @files : {};
    $self->param($param);

    $self->command('update');
    $self->push_arg('-A')
      if $self->param->{reset};
    $self->push_arg('-r', $self->param->{revision})
      if defined $self->param->{revision};
    $self->push_arg('-D', $self->param->{date})
      if defined $self->param->{date};
    $self->push_arg('-p')
      if $self->param->{send_to_stdout};
    $self->push_arg('-l')
      unless $self->param->{recursive};
    $self->push_arg('-d')
      if $self->param->{build_directories};
    $self->push_arg('-C')
      if $self->param->{overwrite_local_modified};
    $self->push_arg(@files);

    my $result = new Cvs::Result::Update;
    $self->result($result);

    my $main = $self->new_context();
    $self->initial_context($main);

    $main->push_handler
    (
     qr/^([UPARMC\?WG]) (.*)\n$/, sub
     {
         my($match) = @_;
         $result->add_entry($match->[1], $match->[2]);
     }
    );
    $main->push_handler
    (
     qr/^cvs update: (.*) is no longer in the repository$/, sub
     {
         my($match) = @_;
         # file is gone
         $result->add_entry('G', $match->[1]);
     }
    );
    $main->push_handler
    (
     qr/^cvs server: New directory `(.*)' -- ignored$/, sub
     {
         $result->push_ignored_directory(shift->[1]);
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

