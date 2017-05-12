#!/usr/bin/perl -w

=head1 NAME

bench_auth.pl - Test relative performance of CGI::Ex::Auth

=head1 SAMPLE OUTPUT

  Benchmark: running cookie_bad, cookie_good, cookie_good2, form_bad, form_good, form_good2, form_good3, form_good4 for at least 2 CPU seconds...
  cookie_bad:  3 wallclock secs ( 2.15 usr +  0.00 sys =  2.15 CPU) @ 6819.07/s (n=14661)
  cookie_good:  3 wallclock secs ( 2.01 usr +  0.08 sys =  2.09 CPU) @ 6047.85/s (n=12640)
  cookie_good2:  2 wallclock secs ( 1.95 usr +  0.10 sys =  2.05 CPU) @ 5087.80/s (n=10430)
    form_bad:  3 wallclock secs ( 2.19 usr +  0.00 sys =  2.19 CPU) @ 6542.92/s (n=14329)
   form_good:  3 wallclock secs ( 2.08 usr +  0.05 sys =  2.13 CPU) @ 6108.45/s (n=13011)
  form_good2:  3 wallclock secs ( 2.05 usr +  0.09 sys =  2.14 CPU) @ 5023.36/s (n=10750)
  form_good3:  3 wallclock secs ( 2.17 usr +  0.01 sys =  2.18 CPU) @ 7040.83/s (n=15349)
  form_good4:  3 wallclock secs ( 2.12 usr +  0.00 sys =  2.12 CPU) @ 1947.64/s (n=4129)
                 Rate form_good4 form_good2 cookie_good2 cookie_good form_good form_bad cookie_bad form_good3
  form_good4   1948/s         --       -61%         -62%        -68%      -68%     -70%       -71%       -72%
  form_good2   5023/s       158%         --          -1%        -17%      -18%     -23%       -26%       -29%
  cookie_good2 5088/s       161%         1%           --        -16%      -17%     -22%       -25%       -28%
  cookie_good  6048/s       211%        20%          19%          --       -1%      -8%       -11%       -14%
  form_good    6108/s       214%        22%          20%          1%        --      -7%       -10%       -13%
  form_bad     6543/s       236%        30%          29%          8%        7%       --        -4%        -7%
  cookie_bad   6819/s       250%        36%          34%         13%       12%       4%         --        -3%
  form_good3   7041/s       262%        40%          38%         16%       15%       8%         3%         --

=cut

use strict;
use Benchmark qw(cmpthese timethese);
use CGI::Ex::Auth;
use CGI::Ex::Dump qw(debug);

{
    package Auth;
    use base qw(CGI::Ex::Auth);
    use strict;
    use vars qw($printed $set_cookie $deleted_cookie);

    sub login_print      { $printed = 1 }
    sub set_cookie       { $set_cookie = 1 }
    sub delete_cookie    { $deleted_cookie = 1 }
    sub get_pass_by_user { '123qwe' }
    sub script_name      { $0 }
    sub no_cookie_verify { 1 }
    sub secure_hash_keys { ['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'bbbbbbbbbbbbbbbbbbbbbbbbbbb', 'ccc'] }
    sub failed_sleep     { 0 }
}

{
    package Aut2;
    use base qw(Auth);
    use vars qw($crypt);
    BEGIN { $crypt = crypt('123qwe', 'SS') };
    sub use_crypt { 1 }
    sub get_pass_by_user { $crypt }
}

{
    package Aut3;
    use base qw(Auth);
    sub use_blowfish  { "This_is_my_key" }
    sub use_base64    { 0 }
    sub use_plaintext { 1 }
}

my $token  = Auth->new->generate_token({user => 'test', real_pass => '123qwe', use_base64 => 1});
my $token2 = Aut3->new->generate_token({user => 'test', real_pass => '123qwe'});

my $form_bad     = { cea_user => 'test',   cea_pass => '123qw'  };
my $form_good    = { cea_user => 'test',   cea_pass => '123qwe' };
my $form_good2   = { cea_user => $token };
my $form_good3   = { cea_user => 'test/123qwe' };
my $form_good4   = { cea_user => $token2 };
my $cookie_bad   = { cea_user => 'test/123qw'  };
my $cookie_good  = { cea_user => 'test/123qwe' };
my $cookie_good2 = { cea_user => $token };

sub form_good    { Auth->get_valid_auth({form => {%$form_good},  cookies => {}              }) }
sub form_good2   { Auth->get_valid_auth({form => {%$form_good2}, cookies => {}              }) }
sub form_good3   { Aut2->get_valid_auth({form => {%$form_good3}, cookies => {}              }) }
sub form_good4   { Aut3->get_valid_auth({form => {%$form_good4}, cookies => {}              }) }
sub form_bad     { Auth->get_valid_auth({form => {%$form_bad},   cookies => {}              }) }
sub cookie_good  { Auth->get_valid_auth({form => {},             cookies => {%$cookie_good} }) }
sub cookie_good2 { Auth->get_valid_auth({form => {},             cookies => {%$cookie_good2}}) }
sub cookie_bad   { Auth->get_valid_auth({form => {},             cookies => {%$cookie_bad}  }) }

$Auth::printed = $Auth::set_cookie = $Auth::delete_cookie = 0;
die "Didn't get good auth"         if ! form_good();
die "printed was set"              if $Auth::printed;
die "set_cookie not called"        if ! $Auth::set_cookie;
die "delete_cookie was called"     if $Auth::deleted_cookie;

$Auth::printed = $Auth::set_cookie = $Auth::delete_cookie = 0;
debug form_good2(), (my $e = $@);
die "Didn't get good auth"         if ! form_good2();
die "printed was set"              if $Auth::printed;
die "set_cookie not called"        if ! $Auth::set_cookie;
die "delete_cookie was called"     if $Auth::deleted_cookie;

$Auth::printed = $Auth::set_cookie = $Auth::delete_cookie = 0;
die "Didn't get good auth"         if ! form_good3();
die "printed was set"              if $Auth::printed;
die "set_cookie not called"        if ! $Auth::set_cookie;
die "delete_cookie was called"     if $Auth::deleted_cookie;

$Auth::printed = $Auth::set_cookie = $Auth::delete_cookie = 0;
debug form_good4(), (my $e = $@);
die "Didn't get good auth"         if ! form_good4();
die "printed was set"              if $Auth::printed;
die "set_cookie not called"        if ! $Auth::set_cookie;
die "delete_cookie was called"     if $Auth::deleted_cookie;

$Auth::printed = $Auth::set_cookie = $Auth::delete_cookie = 0;
die "Didn't get bad auth"          if form_bad();
die "printed was not set"          if ! $Auth::printed;
die "set_cookie called"            if $Auth::set_cookie;
die "delete_cookie was called"     if $Auth::deleted_cookie;

$Auth::printed = $Auth::set_cookie = $Auth::delete_cookie = 0;
die "Didn't get good auth"         if ! cookie_good();
die "printed was set"              if $Auth::printed;
die "set_cookie not called"        if ! $Auth::set_cookie;
die "delete_cookie was called"     if $Auth::deleted_cookie;

$Auth::printed = $Auth::set_cookie = $Auth::delete_cookie = 0;
die "Didn't get good auth"         if ! cookie_good2();
die "printed was set"              if $Auth::printed;
die "set_cookie not called"        if ! $Auth::set_cookie;
die "delete_cookie was called"     if $Auth::deleted_cookie;

$Auth::printed = $Auth::set_cookie = $Auth::delete_cookie = 0;
die "Didn't get bad auth"          if cookie_bad();
die "printed was not set"          if ! $Auth::printed;
die "set_cookie called"            if $Auth::set_cookie;
die "delete_cookie was not called" if ! $Auth::deleted_cookie;

print "Ready\n";

my $r = eval { timethese (-2, {
    form_good    => \&form_good,
    form_good2   => \&form_good2,
    form_good3   => \&form_good3,
    form_good4   => \&form_good4,
    form_bad     => \&form_bad,
    cookie_good  => \&cookie_good,
    cookie_good2 => \&cookie_good2,
    cookie_bad   => \&cookie_bad,
}) };
if (! $r) {
    debug "$@";
    next;
}
eval { cmpthese $r };
