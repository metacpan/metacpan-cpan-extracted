# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     t/04exception.t - checking the error messages (using Test::Exception)
#     Test script for DateTime::Format::Baby
#     Copyright (C) 2015, 2016, Rick Measham and Jean Forget
#
#     This program is distributed under the same terms as Perl 5.16.3:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<http://www.perlfoundation.org/artistic_license_1_0>
#     and L<http://www.gnu.org/licenses/gpl-1.0.html>.
#
#     Here is the summary of GPL:
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 1, or (at your option)
#     any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software Foundation,
#     Inc., <http://www.fsf.org/>.
#

use strict;
use warnings;
use Test::More;
use DateTime::Format::Baby;

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception needed"
    if $@;
}

plan(tests => 7);
dies_ok { my $baby = DateTime::Format::Baby->new('en', format => '??') } "new fails when called with odd number of parameters";
dies_ok { my $baby = DateTime::Format::Baby->new('el') } "that's all Greek for me";

my $baby = DateTime::Format::Baby->new('en');
dies_ok { $baby->language('el') } "that's all Greek for me";
dies_ok { $baby->parse_datetime('glglglglglgl') } "Bubbling baby";
dies_ok { $baby->parse_datetime('The big hand is on the Six') } "Partial result";
dies_ok { $baby->parse_duration('When will we arrive Mummy?') } "No duration";

SKIP: {
  eval "use DateTime::Duration";
  skip if $@;
  my $dur = DateTime::Duration->new(hours => 1, minutes => 30);
  dies_ok { $baby->format_duration($dur) } "No duration";
}
