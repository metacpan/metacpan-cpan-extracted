#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

{
  package Locale::TextDomain::Bastardize;
  use strict;
  use warnings;
  use Text::Bastardize;

  sub import {
    my ($class, $method) = @_;
    $class->setup ($method);
  }

  sub setup {
    my ($class, $method) = @_;
    require Locale::Messages;
  }
}

use Scalar::Util;

my $bast = Text::Bastardize->new;
{
  foreach my $name ('Locale::Messages::gettext',
                    'Locale::Messages::dgettext',
                    'Locale::Messages::dcgettext',
                    'Locale::Messages::ngettext',
                    'Locale::Messages::dngettext',
                    'Locale::Messages::dcngettext') {
    my $old = do { no strict 'refs'; \&$name };
    my $new = Scalar::Util::set_prototype
      (sub {
         my $str = $old->(@_);
         $bast->charge ($str);
         return $bast->pig;
       }, prototype ($old));

    { no strict 'refs';
      no warnings 'redefine';
      *$name = $new;
    }
  }
}
# {
#   my $old = \&Locale::Messages ::dgettext;
#   *Locale::Messages::dgettext = sub ($) {
#     my $str = $old->(@_);
#     $bast->charge ($str);
#     return $bast->pig;
#   }
# }

print Locale::Messages::gettext ('hello world'),"\n";
print Locale::Messages::dgettext ('App-Chart', 'hello world'),"\n";
exit 0;
