#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::ConfigLoader;
use ASP4::SimpleCGI;
use ASP4::API;
my $config; BEGIN { $config = ASP4::ConfigLoader->load }

use Carp 'confess';
$SIG{__DIE__} = \&confess;

use_ok('ASP4::HTTPContext');
use_ok('ASP4::Mock::RequestRec');


TEST1: {
  my $context = do_request( '/pageparser/01simple.asp' );
  like $context->r->buffer, qr/Hello\s+World/, "Has 'Hello World!'";
};


TEST2: {
  my $context = do_request( '/pageparser/child-inner2.asp' );
  like $context->r->buffer, qr/Child\s+\-\s+Inner2/, "Has 'Child - Inner2'";
};


TEST3: {
  my $context = do_request( '/pageparser/has-include.asp' );

  is $context->r->buffer => q(Before Include
This is an INCLUDE!!!!

After Include
), "Response.Include works properly";
};


TEST4: {
  my $context = do_request( '/pageparser/has-2-includes.asp' );

  is $context->r->buffer => q(Before Include1
This is an INCLUDE!!!!

After Include1
Before Include2
This is an INCLUDE!!!!

After Include2
), "Response.Include works properly";
};


TEST5: {
  my $context = do_request( '/pageparser/has-nested-include.asp' );

  is $context->r->buffer => q(Outer: Before Include
Before Include
This is an INCLUDE!!!!

After Include

Outer: After Include
), "Response.Include works properly";
};


TEST6: {
  my $context = do_request( '/pageparser/does-trapinclude.asp' );

  is $context->r->buffer => q(Before TrapInclude:
BEFORE INCLUDE1
THIS IS AN INCLUDE!!!!

AFTER INCLUDE1
BEFORE INCLUDE2
THIS IS AN INCLUDE!!!!

AFTER INCLUDE2

After TrapInclude:
), "Response.TrapInclude works properly";
};

sub do_request
{
  my $url = shift;
  my $req = ASP4::Mock::RequestRec->new( uri => $url );
  my $cgi = ASP4::SimpleCGI->new();
  my $context = ASP4::HTTPContext->new();
  $context->setup_request( $req, $cgi );
  $context->execute( );
  return $context;
}# end do_request()



