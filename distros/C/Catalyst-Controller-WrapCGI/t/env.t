use strict;
use warnings;

use Test::More tests => 3;
use Catalyst::Controller::WrapCGI;

my $obj = Catalyst::Controller::WrapCGI->new;

# to suppress a warning from Catalyst
BEGIN { *Catalyst::Controller::WrapCGI::_application = sub { 'dummy' }; }

delete $ENV{MOD_PERL};

my $want = {%ENV};
my $have = {%ENV};
{
  local $have->{MOD_PERL} = 1;
  is_deeply(
    $obj->_filtered_env($have),
    $want,
    "default: pass all except MOD_PERL",
  );
}

{
  local $obj->{CGI}{pass_env} = 'MOD_PERL';
  local $have->{MOD_PERL} = 1;
  is_deeply(
    $obj->_filtered_env($have),
    {},
    "empty when all passes are killed",
  );
}

{
  local $obj->{CGI}{kill_env} = [];
  local $have->{MOD_PERL} = 1;
  local $want->{MOD_PERL} = 1;
  is_deeply(
    $obj->_filtered_env($have),
    $want,
    "explicit override for default kill",
  );
}

