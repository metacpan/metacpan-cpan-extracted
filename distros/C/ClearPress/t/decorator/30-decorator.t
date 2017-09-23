# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More tests => 22;
use English qw(-no_match_vars);

use_ok('ClearPress::decorator');

{
  my $dec = ClearPress::decorator->new();
  isa_ok($dec, 'ClearPress::decorator', 'constructs without an argument');
}

{
  my $dec = ClearPress::decorator->new({});
  isa_ok($dec, 'ClearPress::decorator', 'constructs with an argument');
  is($dec->title('foo'), 'foo', 'able to set+get the title');
}

{
  my $dec = ClearPress::decorator->new();
  is($dec->defaults('meta_content_type'), 'text/html', 'has default content_type of text/html');
  is($dec->meta_content_type(), 'text/html', 'supports meta_content_type() method');
  is($dec->get('junk'), undef, 'returns undef on non-existent attribute fetch');
  is_deeply($dec->get('jsfile'), [], 'returns empty array on jsfile fetch');
}

{
  my $dec = ClearPress::decorator->new();

  my $ref = ['/foo.js'];
  if($ClearPress::decorator::DEFAULTS) {
    $ClearPress::decorator::DEFAULTS->{'jsfile'} = $ref;
  }
  is_deeply($dec->jsfile(), $ref, 'returns default array for jsfile()');
}

{
  my $dec = ClearPress::decorator->new();

  my $ref = ['/bar.js'];
  $dec->jsfile($ref);
  is_deeply($dec->jsfile(), $ref, 'returns given array for jsfile()');
}

{
  my $dec = ClearPress::decorator->new();

  $dec->jsfile(q[foo.js,bar.js]);
  is_deeply($dec->jsfile(), [qw(foo.js bar.js)], 'returns given array for jsfile()');
}

{
  my $dec = ClearPress::decorator->new({
					script => q[foo.init({mode:"textareas",theme:"simple"});],
				       });

  is_deeply($dec->script(), [q[foo.init({mode:"textareas",theme:"simple"});]], 'returns given array for jsfile()');
}

{
  $ClearPress::decorator::DEFAULTS->{meta_version} = 123;
  $ClearPress::decorator::DEFAULTS->{lang} = 'en-gb';
  my $dec = ClearPress::decorator->new();
  is($dec->header(), from_file(q(header-1.frag)), 'default combined header');
}

{
  my $dec = ClearPress::decorator->new();
  isa_ok($dec->cgi(), 'CGI', 'cgi() returns a new CGI object');
}

{
  my $dec = ClearPress::decorator->new();
  is($dec->cgi(), $dec->cgi(), 'cgi() returns a cached CGI object');
}

{
  my $dec = ClearPress::decorator->new();
  my $cgi = {};
  is($dec->cgi($cgi), $cgi, 'cgi() returns a given cgi object');
}

{
  my $dec = ClearPress::decorator->new();
  is($dec->save_session(), undef, 'save_session returns undef');
}

{
  my $dec = ClearPress::decorator->new();
  is($dec->username(), q(), 'username returns ""');
}

{
  my $dec = ClearPress::decorator->new();
  is($dec->footer(), from_file(q(footer-1.frag)), 'footer returns default html');
}

{
  my $dec = ClearPress::decorator->new();
  is($dec->charset, 'iso8859-1', 'default charset');
}

{
  my $dec = ClearPress::decorator->new({charset=>'UTF-8'});
  is($dec->charset, 'UTF-8', 'constructor charset');
}

{
  my $dec = ClearPress::decorator->new();
  $dec->charset('UTF-8');
  is($dec->charset, 'UTF-8', 'accessor-set charset');
}

sub from_file {
  my $fn = shift;

  open my $fh, q[<], "t/data/rendered/$fn";
  local $RS = undef;
  my $content = <$fh>;
  close $fh;

  return $content;
}
