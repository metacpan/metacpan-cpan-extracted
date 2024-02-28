use strict;
use warnings;
use Test::More 0.88;

BEGIN {
  my $has_xs = eval { require B::Hooks::EndOfScope::XS };
  die 'author tests require additional prerequisites for testing the XS path!' if not $has_xs
      and ($ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING});

  $has_xs or plan skip_all => 'XS functionality not available';

  B::Hooks::EndOfScope::XS->import();
}

BEGIN {
    ok(exists &on_scope_end, 'on_scope_end imported');
    is(prototype('on_scope_end'), '&', '.. and has the right prototype');
}

our $i;

sub foo {
    BEGIN {
        on_scope_end { $i = 42 };
    };

    is($i, 42, 'value still set at runtime');
}

BEGIN {
    is($i, 42, 'value set at compiletime')
}

foo();

done_testing;
