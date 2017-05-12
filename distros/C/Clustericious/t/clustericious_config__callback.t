use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 3;
use Clustericious::Config;
use YAML::XS qw( Load );

subtest 'base object' => sub {

  my $cb = Clustericious::Config::Callback->new('foo','bar','baz');
  isa_ok $cb, 'Clustericious::Config::Callback';

  is_deeply [$cb->args], [qw(foo bar baz )], 'cb.args';

  is $cb->execute, '', 'cb.execute';

  ok $cb->to_yaml, "cb.to_yaml = @{[ $cb->to_yaml ]}";
  
  my $yaml = "---\na: @{[ $cb->to_yaml ]}\n";
  
  my $cb2 = Load($yaml)->{a};
  
  is_deeply [$cb2->args], [qw( foo bar baz )], 'cb2.args (restored!)';
};

subtest 'derrived object' => sub {
  plan tests => 2;

  do {
    package Foo;
    use base qw( Clustericious::Config::Callback );
    sub execute { join ':', shift->args }
  };
  
  my $cb = Foo->new('abc','def');
  isa_ok $cb, 'Clustericious::Config::Callback';
  is $cb->execute, 'abc:def', 'cb.execute';

};

subtest 'password' => sub {
  plan tests => 2;

  do {
    package Term::Prompt;
    sub prompt { 'mypass' }
    $INC{'Term/Prompt.pm'} = __FILE__;
  };
  
  my $cb = Clustericious::Config::Callback::Password->new;
  isa_ok $cb, 'Clustericious::Config::Callback';
  is $cb->execute, 'mypass', 'cb.execute';

};
