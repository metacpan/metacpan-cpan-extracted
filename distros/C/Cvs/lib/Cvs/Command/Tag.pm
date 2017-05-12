package Cvs::Command::Tag;

use strict;
use Cvs::Result::Tag;
use base qw(Cvs::Command::Base);

sub init
{
    my($self, $tag, @files) = @_;
    $self->SUPER::init(@_) or return;

    my $param = {};
    if(defined $files[-1] && ref $files[-1] eq 'HASH')
    {
        $param = pop @files;
    }

    return $self->error('Missing mandatory option for tag')
      unless defined $tag;

    $self->default_params
      (
       delete => 0,
       force => 0,
       branch => 0,
       release => undef,
       date => undef,
       recursive => 1,
      );
    $self->param($param);


    $self->command('tag');
    $self->push_arg('-d')
      if $self->param->{delete};
    $self->push_arg('-F')
      if $self->param->{force};
    $self->push_arg('-b')
      if $self->param->{branch};
    $self->push_arg('-r', $self->param->{release})
      if $self->param->{release};
    $self->push_arg('-D', $self->param->{date})
      if $self->param->{date};
    $self->push_arg('-l')
      unless $self->param->{recursive};
    $self->push_arg($tag, @files);

    my $main = $self->new_context();
    $self->initial_context($main);

    my $result = new Cvs::Result::Tag;
    $self->result($result);
    my $current_directory = '';

    $main->push_handler
    (
     qr/^cvs tag: (?:Unt|T)agging (.*)\n$/, sub
     {
         $current_directory = shift->[1];
     }
    );
    $main->push_handler
    (
     qr/^T (.*)\n$/, sub
     {
         my($match) = @_;
         my $file = $current_directory eq '.'
           ? $match->[1] : $current_directory . '/'. $match->[1];
         $result->push_tagged($file);
     }
    );
    $main->push_handler
    (
     qr/^W (.*?) : (.*)\n$/, sub
     {
         my($match) = @_;
         $result->push_warning($match->[1], $match->[2]);
     }
    );
    $main->push_handler
    (
     qr/^D (.*)\n$/, sub
     {
         my $file = $current_directory eq '.'
           ? shift->[1] : $current_directory . '/'. shift->[1];
         $result->push_untagged($file);
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

