# -*- Mode: Perl; -*-

=head1 NAME

1_validate_07_yaml.t - Check for CGI::Ex::Validate's ability to use YAML.

=cut

use strict;
use Test::More tests => 5;

SKIP: {

skip("Missing YAML.pm", 5) if ! eval { require 'YAML.pm' };

use_ok('CGI::Ex::Validate');

my $N = 0;
my $v;
my $e;

sub validate { scalar CGI::Ex::Validate::validate(@_) }

###----------------------------------------------------------------###

### single group
$v = '
user:
  required: 1
foo:
  required_if: bar
';

$e = validate({}, $v);
ok($e);
$e = validate({user => 1}, $v);
ok(! $e);
$e = validate({user => 1, bar => 1}, $v);
ok($e);
$e = validate({user => 1, bar => 1, foo => 1}, $v);
ok(! $e);


};
