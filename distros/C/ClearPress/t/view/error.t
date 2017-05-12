# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Carp;
#use HTML::TreeBuilder;
use XML::TreeBuilder;
use Template;
use Test::Trap;

eval {
  require DBD::SQLite;
  plan tests => 10;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

use lib qw(t/lib);
use t::util;


use_ok('ClearPress::view::error');

{
  my $util = t::util->new(); delete $util->{cgi};
  my $view = ClearPress::view::error->new({
					   util   => $util,
					  });
  isa_ok($view, 'ClearPress::view::error');
}

{
  my $util = t::util->new(); delete $util->{cgi};
  $util->cgi->param('errstr', 'test');
  my $view = ClearPress::view::error->new({
					   aspect => q[read],
					   util   => $util,
					  });
  trap {
    render_ok($view, 'view-error-read.html', 'html error');
  };
  like($trap->stderr(), qr/Serving\ error/mix, 'warn to console');
}

{
  my $util = t::util->new(); delete $util->{cgi};
  $util->cgi->param('errstr', q[test & @ ' ; "]);
  my $view = ClearPress::view::error->new({
					   aspect => q[read_xml],
					   util   => $util,
					  });
  trap {
    render_ok($view, 'view-error-read.xml', 'xml error');
  };
  like($trap->stderr(), qr/Serving\ error/mix, 'warn to console');
}

{
  my $util = t::util->new(); delete $util->{cgi};
  $util->cgi->param('errstr', q[test & @ ' ; "]);
  my $view = ClearPress::view::error->new({
					   aspect => q[read_json],
					   util   => $util,
					  });

  trap {
    is($view->render(), q[{"error":"Error: test & @ ' ; \""}], 'streamed json error');
  };
  like($trap->stderr(), qr/Serving\ error/mix, 'warn to console');
}

{
  my $util = t::util->new(); delete $util->{cgi};
  Template->error(q[a template error]);
  my $view = ClearPress::view::error->new({
					   aspect => q[read],
					   util   => $util,
					  });
  trap {
    render_ok($view, 'view-error-read-tt.html', 'html template engine error');
  };
  like($trap->stderr(), qr/Serving\ error/mix, 'warn to console');
}

sub render_ok {
  my ($view, $fn, $msg) = @_;

  open my $fh, q[<], "t/data/rendered/$fn" or croak $ERRNO;
  local $RS   = undef;
  my $content = <$fh>;
  close $fh;

  my $expected_tree = XML::TreeBuilder->new;
  $expected_tree->parse_file("t/data/rendered/$fn");

  my $rendered_tree = XML::TreeBuilder->new;
  $rendered_tree->parse($view->render());

  return is($rendered_tree->as_XML(), $expected_tree->as_XML(), $msg);
}
