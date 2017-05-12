use strict;
use warnings;
use Test::More tests => 9;

eval q{
  use Authen::Simple::PlugAuth;
};
die $@ if $@;

my $tiny;

my $auth = eval { Authen::Simple::PlugAuth->new( url => "https://foo.bar.baz" ) };
diag $@ if $@;
isa_ok $auth, 'Authen::Simple::PlugAuth';

is $auth->authenticate('optimus', 'matrix'),   1, "login with optimus:matrix";

is $tiny->{url}, 'https://foo.bar.baz', 'url = https://foo.bar.baz';
is $tiny->{user}, 'optimus',            'user = optimus';
is $tiny->{pass}, 'matrix',             'pass = matrix';

is $auth->authenticate('bogus',   'bogus' ),   0, "login with bogus:bogus";

is $tiny->{url}, 'https://foo.bar.baz', 'url = https://foo.bar.baz';
is $tiny->{user}, 'bogus',              'user = bogus';
is $tiny->{pass}, 'bogus',              'pass = bogus';

package PlugAuth::Client::Tiny;

BEGIN { $INC{'PlugAuth/Client/Tiny.pm'} = __FILE__ }

sub new {
  my $class = shift;
  my %args = ref $_[0] ? %{$_[0]} : @_;
  my $url = (delete $args{url}) || 'http://localhost:3000/';
  $tiny = bless { url => $url }, $class;
}

sub auth
{
  my $self = shift;
  $self->{user} = shift;
  $self->{pass} = shift;
  return ($self->{user} eq 'optimus' && $self->{pass} eq 'matrix') ? 1 : 0;
}
