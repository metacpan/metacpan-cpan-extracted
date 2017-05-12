#    Copyright (c) 2011 Raphaël Pinson.
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
#    02110-1301 USA

package Config::KingKong::File;

use strict;
use warnings;
use base qw(Class::Accessor);

sub new {
   my $class = shift;
   my %options = @_;

   my $self = __PACKAGE__->SUPER::new();

   $self->{engine} = $options{engine};
   $self->{directory} = $options{directory};
   $self->{target} = $options{target};
   $self->{template} = $options{template};
   $self->{template_extension} = $options{template_extension};
   $self->{verbose} = $options{verbose};
   $self->{environment} = $options{environment};

   return $self;
}


sub process {
   my ($self) = @_;

   my @matches = $self->{target} =~ /\${(\w+)}/g;
   $self->{file_vars} = \@matches;
   if ($#matches >= 0) {
      $self->recurse_file(0);
   } else {
      $self->generate();
   }
}

sub recurse_file {
   my ($self, $level) = @_;
   my @file_vars = @{$self->{file_vars}};
   if ($level <= $#file_vars) {
      my $newmatch = $file_vars[$level];
      my $newkey = $newmatch . "s";
      die "E: No such key $newkey" unless $self->{environment}{$newkey};
      my @items;
      if (ref($self->{environment}{$newkey}) eq "HASH") {
         @items = keys %{$self->{environment}{$newkey}};
      } elsif (ref($self->{environment}{$newkey}) eq "ARRAY") {
         @items = @{$self->{environment}{$newkey}};
      } else {
         @items = ( $self->{environment}{$newkey} );
      }
      foreach my $item (@items) {
         $self->{environment}{local_values}{$newmatch} = $item;
         $self->recurse_file($level+1);
      }
   } else {
      my $filename = $self->{target};
      foreach my $key (keys %{$self->{environment}{local_values}}) {
         my $value = $self->{environment}{local_values}{$key};
         $filename =~ s|\${$key}|$value|;
      }
      print "V: Filename: $filename\n" if $self->{verbose};
      $self->generate($filename);
   }
}

sub generate {
   my ($self, $file) = @_;

   my $tmpl = $self->{template};
   my $tmpl_ext = $self->{template_extension};
   $file ||= $self->{target};
   $tmpl ||= "$file.$tmpl_ext";
   my $dirname = $self->{directory};
   print "V: Generating $dirname/$file from $dirname/$tmpl\n" if $self->{verbose};
   $self->{engine}->process($tmpl, $self->{environment}, $file)
         || die $self->{engine}->error();
}

1;
