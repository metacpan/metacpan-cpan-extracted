use strict;
use warnings;
use Test::More;
use AnyEvent::Open3::Simple;

subtest 'create' => sub {
  my $ipc = eval { AnyEvent::Open3::Simple->new };
  diag $@ if $@;
  isa_ok $ipc, 'AnyEvent::Open3::Simple';
};

subtest 'implementation' => sub {
  my $ipc = AnyEvent::Open3::Simple->new(
    implementation => undef,
  );

  isnt $ipc->{impl}, undef, "impl = @{[ $ipc->{impl} ]}";
};

done_testing;
