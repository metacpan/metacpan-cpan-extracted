#!/usr/bin/env perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Data::FormValidator;

# to test definedness of built-in filters and general functions, as reported: http://rt.cpan.org/Ticket/Display.html?id=2751

# upgrade warn to die so we can catch it.
$SIG{__WARN__} = sub { die $_[0] };

eval {
  my $results = Data::FormValidator->check( {
      empty_array => [ undef, undef ],
      very_empty  => undef,

    },
    {
      required => [qw/very_empty empty_array/],

    } );
};
ok( !$@, 'basic validation generates no warnings with -w' ) or diag $@;

use Data::FormValidator::Filters (qw/:filters/);

for my $filter ( grep { /^filter_/ } keys %:: )
{
  eval { $::{$filter}->(undef) };
  ok( !$@, "uninitialized value in $filter filter generates no warning" )
    or diag $@;
}
