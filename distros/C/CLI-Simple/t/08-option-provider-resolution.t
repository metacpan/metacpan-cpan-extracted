#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use CLI::Simple ();

our @CALLS;

{
  package Local::Boundaries::First;
  use Role::Tiny;

  sub _first_init {
    push @main::CALLS, q{first:init};
    return;
  }

  sub _first_resolve {
    my ( $self, @names ) = @_;
    push @main::CALLS, q{first:} . join q{,}, sort @names;
    return { map { $_ => q{provider} } @names };
  }
}

{
  package Local::Boundaries::Bad;
  use Role::Tiny;

  sub _bad_resolve {
    my ( $self, @names ) = @_;
    return { unexpected => q{value} };
  }
}

BEGIN {
  $INC{'Local/Boundaries/First.pm'} = __FILE__;
  $INC{'Local/Boundaries/Bad.pm'}   = __FILE__;
}

{
  package Local::Boundaries::AllCLI;
  use parent qw(CLI::Simple);
}

{
  package Local::Boundaries::Unrequested;
  use parent qw(CLI::Simple);
}

{
  package Local::Boundaries::Isolated;
  use parent qw(CLI::Simple);
}

Local::Boundaries::AllCLI->use_options(
  first => { 'Local::Boundaries::First' => [qw(token)] },
);

Local::Boundaries::Unrequested->use_options(
  bad => { 'Local::Boundaries::Bad' => [qw(token)] },
);

subtest 'skip initializer and resolver when CLI supplied every requested option' => sub {
  @CALLS = ();
  local @ARGV = qw(--token cli-value);
  my $app = Local::Boundaries::AllCLI->new(
    option_specs => [qw(token=s)],
    commands     => { noop => sub { return 0; } },
  );
  is( $app->get_token, q{cli-value}, q{CLI value retained} );
  is_deeply( \@CALLS, [], q{provider was never initialized or invoked} );
};

subtest 'reject provider output outside requested names' => sub {
  local @ARGV = ();
  my $ok = eval {
    Local::Boundaries::Unrequested->new(
      option_specs => [qw(token=s)],
      commands     => { noop => sub { return 0; } },
    );
    1;
  };
  ok( !$ok, q{constructor rejects unrequested name} );
  like( $@, qr/returned unrequested option 'unexpected'/, q{useful diagnostic} );
};

subtest 'registration belongs to its application class' => sub {
  @CALLS = ();
  local @ARGV = ();
  my $app = Local::Boundaries::Isolated->new(
    option_specs    => [qw(token=s)],
    default_options => { token => q{fallback} },
    commands        => { noop => sub { return 0; } },
  );
  is( $app->get_token, q{fallback}, q{unregistered class receives its default} );
  is_deeply( \@CALLS, [], q{another application's provider is not invoked} );
};

done_testing;
1;
