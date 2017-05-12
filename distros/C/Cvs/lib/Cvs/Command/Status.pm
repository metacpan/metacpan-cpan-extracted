package Cvs::Command::Status;

use strict;
use Cvs::Result::StatusList;
use Cvs::Result::StatusItem;
use base qw(Cvs::Command::Base);

sub init
{
    my($self, @file_list) = @_;
    $self->SUPER::init(@_) or return;

    $self->default_params
      (
       multiple => 0,
       recursive => 1,
      );
    my $param = pop @file_list
      if ref $file_list[-1] eq 'HASH';
    $self->param($param);

    $self->command('status');
    $self->push_arg('-l')
      unless $self->param->{recursive};
    $self->push_arg('-v', @file_list);

    my $main = $self->new_context;
    my $tags = $self->new_context;
    $self->initial_context($tags);

    my($resultlist, $current_directory);
    my $result = $self->err_result('No file in response');

    $tags->push_handler
    (
     qr/cvs (?:status|server): Examining (.*)\n$/, sub
     {
         $current_directory = shift->[1];
     }
    );
    $tags->push_handler
    (
     qr/^=+$/, sub
     {
         if($self->param->{multiple})
         {
             unless(defined $resultlist)
             {
                 $resultlist = new Cvs::Result::StatusList;
                 $self->result($resultlist);
             }
             $result = new Cvs::Result::StatusItem;
             $resultlist->push($result);
         }
         else
         {
             if($result->isa('Cvs::Result::StatusItem'))
             {
                 return $tags->finish();
             }
             else
             {
                 $result = new Cvs::Result::StatusItem;
                 $self->result($result);
             }
         }

         # switch to main context
         return $main;
     }
    );
    $tags->push_handler
    (
     qr/^\s+([^\s]+)\s+(\(.*\))\s*$/, sub
     {
         my($match) = @_;
         $result->push_tag($match->[1], $match->[2]);
     }
    );
    $tags->push_handler
    (
     qr/No Tags Exist/, sub
     {
         # nothing to do...
     }
    );
    $main->push_handler
    (
     qr/^File: (.*)\s+Status: (.*)\n$/, sub
     {
         my($match) = @_;
         my $filename = $match->[1];
         $filename =~ s/^\s+|\s$//g;
         $result->basedir($current_directory);
         $result->status($match->[2]);
         $result->exists(1);
         if($filename =~ /^no file (.*)$/)
         {
             $filename = $1;
             $result->exists(0);
         }
         $result->filename($filename);
     }
    );
    $main->push_handler
    (
     qr/^\s+Working revision:\s+([\d\.]+|No entry for .*)/, sub
     {
         my($match) = @_;
         $result->working_revision($match->[1]) if $match->[1] =~ /^[\d.]+$/;
     }
    );
    $main->push_handler
    (
     qr/^\s+Repository revision:\s+([\d\.]+|No revision control file)/, sub
     {
         my($match) = @_;
         $result->repository_revision($match->[1]) if $match->[1] =~ /^[\d.]+$/;
     }
    );
    $main->push_handler
    (
     qr/^\s+Sticky Tag:\s+(.*)\s*$/, sub
     {
         my($match) = @_;
         $result->sticky_tag($match->[1]) unless $match->[1] eq '(none)';
     }
    );
    $main->push_handler
    (
     qr/^\s+Sticky Date:\s+(.*)\s*$/, sub
     {
         my($match) = @_;
         $result->sticky_date($match->[1]) unless $match->[1] eq '(none)';
     }
    );
    $main->push_handler
    (
     qr/\s+Sticky Options:\s+(.*)\s*$/, sub
     {
         my($match) = @_;
         $result->sticky_options($match->[1]) unless $match->[1] eq '(none)';
     }
    );
    $main->push_handler
    (
     qr/\s+Existing Tags:/, sub
     {
         # switching to tags context
         return $tags
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

