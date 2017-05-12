# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


# Doesn't work.

# TieWeakNotify
# TieWeakField
# TieWeakProperty->setup ($obj, $pname)
# TieWeakProperty->setup ($obj, $pname)

# TieWeakProperty->set ($obj, $pname, $value)


package App::Chart::Glib::Ex::TieWeakNotify;
use 5.008;
use strict;
use warnings;
use Carp;
use Scalar::Util;

# uncomment this to run the ### lines
#use Smart::Comments;

my %instances;

sub set {
  my ($class, $obj, $pname, $value) = @_;
  if ($value) {
    Scalar::Util::weaken ($obj->{$pname} = $value);
    Scalar::Util::weaken ($instances{__PACKAGE__.'.'.$pname} = $value);
    tie $instances{__PACKAGE__.'.'.$pname}, $class, $obj, $pname;
  } else {
    delete $instances{__PACKAGE__.'.'.$pname};
    $obj->{$pname} = $value;
  }
  ### $obj
}

sub TIESCALAR {
  my ($class, $obj, $pname) = @_;
  ### TieWeakNotify TIESCALAR()
  ### $obj
  ### $pname
  my $self = bless [ $obj, $pname ], $class;
  Scalar::Util::weaken ($self->[0]);
  return $self;
}

# Devel::FindBlessedRefs callback may end up fetching
sub FETCH {
  my ($self) = @_;
  return $self->[0];
  # croak __PACKAGE__.' no FETCH allowed';
}

sub STORE {
  my ($self, $value) = @_;
  ### TieWeakNotify STORE(): $value

  if (! $value && (my $obj = $self->[0])) {
    ### weakened away
    delete $instances{__PACKAGE__.'.'.$self->[1]};
    $obj->notify ($self->[1]);
  }
}

1;
__END__

# sub setup {
#   my ($class, $obj, $pname, $initial_value) = @_;
#   return tie $obj->{$pname}, $class, $obj, $pname, $initial_value;
# }


# use constant { 0 => 0,
#                1 => 1,
#                2 => 2 };

  #   if (@_ < 2) {
  #     croak 'TieWeakNotify expects object and propname';
  #   }
  #   if (@_ < 3) {
  #     $initial_value = $obj->get_property($pname);
  #   }

#   if (ref ($self->[2] = $value)) {
#     Scalar::Util::weaken ($self->[2]);
# 
# #     my $obj = $self->[0];
# #     my $pname = $self->[1];
# #     Scalar::Util::weaken ($obj->{$pname});
#   }

=head1 NAME

App::Chart::Glib::Ex::TieWeakNotify -- notify signal from weakened property setting

=for test_synopsis my ($obj)

=head1 SYNOPSIS

 use App::Chart::Glib::Ex::TieWeakNotify;

 sub SET_PROPERTY {
   my ($self, $pspec, $newval) = @_;
   my $pname = $pspec->get_name;
   if ($pname eq 'model') {
     App::Chart::Glib::Ex::TieWeakNotify->set ($obj, $pname, $newval);
   }
   # ...
 }

=head1 SEE ALSO

L<Glib>, L<Glib::Ex::TieProperties>

=cut
