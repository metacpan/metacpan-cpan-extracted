# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

package AppChartTestHelpers;
use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(ignore_symlists
                    is_global_number_formatter);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# uncomment this to run the ### lines
#use Smart::Comments;

sub ignore_classes {
  my $ref = shift;
  if (! @_) {
    require Carp;
    Carp::croak ('ignore_classes(): no classes given');
  }
  require Scalar::Util;
  if (Scalar::Util::blessed($ref)) {
    foreach my $class (@_) {
      if ($ref->isa($class)) {
        return 1;
      }
    }
  }
  return 0;
}

sub ignore_symlists {
  my ($ref) = @_;
  return ignore_classes ($ref, 'App::Chart::Gtk2::Symlist');
}

sub ignore_all_dbi {
  my ($ref) = @_;
  return (Scalar::Util::blessed($ref)
          && ($ref->isa('DBI::db')
              || $ref->isa('DBI::st')));
}

sub ignore_global_dbi {
  my ($ref) = @_;
  require Scalar::Util;

  if (Scalar::Util::blessed($ref)
      && $ref->isa('DBI::db')
      && App::Chart::DBI->can('has_instance')) {
    my $dbh = App::Chart::DBI->has_instance;

    if (Scalar::Util::refaddr($ref) == Scalar::Util::refaddr($dbh)) {
      ### ignore DBI: "$ref"
      return 1;
    }
    if (my $dt = tied %$dbh) {
      if (Scalar::Util::refaddr($ref) == Scalar::Util::refaddr($dt)) {
        ### ignore DBI tied(): "$ref"
        return 1;
      }
    }
  }
  return 0;
}

sub ignore_global_number_formatter {
  my ($ref) = @_;
  require Scalar::Util;
  return (Scalar::Util::blessed($ref)
          && $ref->isa('Number::Format')
          && $ref == App::Chart::number_formatter());
}

# # =item C<$bool = ignore_module_functions ($ref, $module, $module, ...)>
# #
# # Return true if C<$ref> is a coderef to any function in any of the given
# # modules.
# #
# # Each C<$module> is a string like C<My::Module>.  If a module doesn't exist
# # then it's skipped, so it doesn't matter if the C<My::Module> package is
# # actually loaded yet.
# #
# sub ignore_module_functions {
#   my $ref = shift;
#   ref $ref eq 'CODE' or return;
# 
#   while (@_) {
#     my $module = shift;
#     my $symtabname = "${module}::";
#     no strict 'refs';
#     %$symtabname or next;
#     foreach my $name (keys %$symtabname) {
#       my $fullname = "${module}::$name";
#       if (defined &$fullname && $ref == \&$fullname) {
#         return 1;
#       }
#     }
#   }
#   return 0;
# }

1;
__END__
