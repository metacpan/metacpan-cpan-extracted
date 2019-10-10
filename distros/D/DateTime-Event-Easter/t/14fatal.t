# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Event::Easter
#     Copyright © 2019 Rick Measham and Jean Forget, all rights reserved
#
#     This program is distributed under the same terms as Perl:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<https://dev.perl.org/licenses/artistic.html>
#     and L<https://www.gnu.org/licenses/gpl-1.0.html>.
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
#     Inc., <https://www.fsf.org/>.
#
use strict;
use warnings;
use Test::More;

use DateTime::Event::Easter qw/easter
                               golden_number
                               western_epact        
                               western_sunday_letter
                               western_sunday_number
                               eastern_epact        
                               eastern_sunday_letter
                               eastern_sunday_number
                              /;

BEGIN {
  eval "use Test::Fatal qw/exception lives_ok/;";
  if ($@) {
    plan skip_all => "Test::Fatal needed";
    exit;
  }
}

plan tests => 31;

like( exception { DateTime::Event::Easter->new(as =>  'spin'); } , qr/Argument 'as' must be 'point' or 'span'./ , "Argument 'as' must be 'point' or 'span'." );

lives_ok  { DateTime::Event::Easter->new(as =>  'point' ); } "Use the singular form 'point'";
lives_ok  { DateTime::Event::Easter->new(as =>  'span'  ); } "Use the singular form 'span'";
lives_ok  { DateTime::Event::Easter->new(as =>  'points'); } "Use the plural form 'points'";
lives_ok  { DateTime::Event::Easter->new(as =>  'spans' ); } "Use the plural form 'spans'";
lives_ok  { DateTime::Event::Easter->new(as =>  'POINT' ); } "Use the upper-case singular form 'POINT'";
lives_ok  { DateTime::Event::Easter->new(as =>  'Span'  ); } "Use the capitalized singular form 'Span'";

my $west =  DateTime::Event::Easter->new();
my $east =  DateTime::Event::Easter->new(easter => 'eastern');
like( exception { $west->following("2019-01-01"); } , qr/Dates need to be datetime objects/ , "Using a string instead of a DateTime object in following" );
like( exception { $west->previous ("2019-01-01"); } , qr/Dates need to be datetime objects/ , "Using a string instead of a DateTime object in previous" );
like( exception { $west->closest  ("2019-01-01"); } , qr/Dates need to be datetime objects/ , "Using a string instead of a DateTime object in closest" );
like( exception { $west->is       ("2019-01-01"); } , qr/Dates need to be datetime objects/ , "Using a string instead of a DateTime object in is" );
like( exception { $east->following("2019-01-01"); } , qr/Dates need to be datetime objects/ , "Using a string instead of a DateTime object in following" );
like( exception { $east->previous ("2019-01-01"); } , qr/Dates need to be datetime objects/ , "Using a string instead of a DateTime object in previous" );
like( exception { $east->closest  ("2019-01-01"); } , qr/Dates need to be datetime objects/ , "Using a string instead of a DateTime object in closest" );
like( exception { $east->is       ("2019-01-01"); } , qr/Dates need to be datetime objects/ , "Using a string instead of a DateTime object in is" );

my $d1 = DateTime->new(year => 2019, month =>  1, day =>  1);
my $d9 = DateTime->new(year => 2019, month => 12, day => 31);
like( exception { $west->as_set(                      to => $d9         ); } , qr/You must specify both a 'from' and a 'to' datetime/ , "Missing begin date" );
like( exception { $west->as_set(from => $d1                             ); } , qr/You must specify both a 'from' and a 'to' datetime/ , "Missing end date" );
like( exception { $west->as_set(from => '2019-01-01', to => $d9         ); } , qr/You must specify both a 'from' and a 'to' datetime/ , "Wrong begin date" );
like( exception { $west->as_set(from => $d1,          to => '2019-12-31'); } , qr/You must specify both a 'from' and a 'to' datetime/ , "Wrong end date" );
like( exception { $west->as_set(                      to => $d9         , inclusive => 1); } , qr/You must specify both a 'from' and a 'to' datetime/ , "Missing begin date" );
like( exception { $west->as_set(from => $d1                             , inclusive => 1); } , qr/You must specify both a 'from' and a 'to' datetime/ , "Missing end date" );
like( exception { $west->as_set(from => '2019-01-01', to => $d9         , inclusive => 1); } , qr/You must specify both a 'from' and a 'to' datetime/ , "Wrong begin date" );
like( exception { $west->as_set(from => $d1,          to => '2019-12-31', inclusive => 1); } , qr/You must specify both a 'from' and a 'to' datetime/ , "Wrong end date" );
like( exception { easter               ('a') } , qr/Year value '.*' should be numeric./ , "Wrong numeric argument to easter" ) ;
like( exception { golden_number        ('a') } , qr/Year value '.*' should be numeric./ , "Wrong numeric argument to golden_number" ) ;
like( exception { western_epact        ('a') } , qr/Year value '.*' should be numeric./ , "Wrong numeric argument to western_epact" ) ;
like( exception { western_sunday_letter('a') } , qr/Year value '.*' should be numeric./ , "Wrong numeric argument to western_sunday_letter" ) ;
like( exception { western_sunday_number('a') } , qr/Year value '.*' should be numeric./ , "Wrong numeric argument to western_sunday_number" ) ;
like( exception { eastern_epact        ('a') } , qr/Year value '.*' should be numeric./ , "Wrong numeric argument to eastern_epact" ) ;
like( exception { eastern_sunday_letter('a') } , qr/Year value '.*' should be numeric./ , "Wrong numeric argument to eastern_sunday_letter" ) ;
like( exception { eastern_sunday_number('a') } , qr/Year value '.*' should be numeric./ , "Wrong numeric argument to eastern_sunday_number" ) ;
