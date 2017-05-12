# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use IO::Scalar;
use CGI;
use Test::Trap;
use Carp;
use File::Copy qw(copy);
use File::Path qw(rmtree make_path);
use File::Temp qw(tempdir);

eval {
  require DBD::SQLite;
  plan tests => 111;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

use lib qw(t/lib);
use t::util;
use t::model;
use t::user::admin;
use t::user::basic;

use_ok('ClearPress::view');

$ClearPress::view::DEBUG_OUTPUT = 0;

my $util = t::util->new;

{
  my $view = ClearPress::view->new({
				    util => $util,
				   });
  isa_ok($view, 'ClearPress::view', 'constructs ok with ref');
}

{
  my $view = ClearPress::view->new;
  isa_ok($view, 'ClearPress::view', 'constructs ok without ref');
}

{
  $util->username('joe_user');
  is($util->username, 'joe_user', 'username set');
  my $view = ClearPress::view->new({
				    util => $util,
				   });
  isa_ok($view, 'ClearPress::view', 'constructs ok with ref');
  $util->username(undef);
  is($util->username, undef, 'username unset');
}

{
  my $types = {
	       _xml  => 'text/xml',
	       _rss  => 'text/xml',
	       _atom => 'text/xml',
	       _ajax => 'text/xml',
	       _js   => 'application/json',
	       _json => 'application/json',
	       _png  => 'image/png',
	       _jpg  => 'image/jpeg',
	       q[]   => 'text/html',
	      };
  for my $k (keys %{$types}) {
    my $view = ClearPress::view->new({
				      util   => $util,
				      aspect => "read$k",
				     });
    is($view->content_type, $types->{$k}, "$k => $types->{$k} content_type");
  }
}

{
  my $view = ClearPress::view->new({
				    util   => $util,
				   });
  is($view->decor, 1, 'decorate when no aspect given');

  my $types = {
	       _xml  => 0,
	       _rss  => 0,
	       _atom => 0,
	       _ajax => 0,
	       _js   => 0,
	       _json => 0,
	       _png  => 0,
	       _jpg  => 0,
	       q[]   => 1,
	      };
  for my $k (keys %{$types}) {
    my $view = ClearPress::view->new({
				      util   => $util,
				      aspect => "read$k",
				     });
    is($view->decor, $types->{$k}, "$k => $types->{$k} decor");
  }
}

{
  my $view = ClearPress::view->new({
				    util => $util,
				   });
  is((scalar @{$view->warnings}), 0, 'no warnings present');
  $view->add_warning('a warning');
  is((scalar @{$view->warnings}), 1, '1 warning present');
  is($view->warnings->[0], 'a warning', 'correct warning present');
}

{
  my $view = ClearPress::view->new({
				    util => $util,
				   });
  trap {
    is($view->_accessor('key', 'value'), 'value', 'accessor set value');
    is($view->_accessor('key'), 'value', 'accessor get value');
  };

  like($trap->stderr, qr/deprecated/smx, 'deprecated warn');
}

{
  my $view = ClearPress::view->new({
				    util => $util,
				   });
  my $str    = q[];
  my $io     = IO::Scalar->new(\$str);
  my $stdout = select $io;

  $view->output_buffer("Content-type: text/html\n\n");
  $view->output_reset;
  $view->output_buffer("Content-type: text/plain\n\n");
  $view->output_end;
  $view->output_buffer("Content-type: text/plain\n\n");

  select $stdout;

  is($str, "Content-type: text/plain\n\n", 'output buffer ok without debugging');
}

{
  my $view = ClearPress::view->new({
				    util => $util,
				   });

  $ClearPress::view::DEBUG_OUTPUT = 1;

  my $str    = q[];
  my $io     = IO::Scalar->new(\$str);
  my $stdout = select $io;

  trap {
    $view->output_buffer("Content-type: text/html\n\n");
    $view->output_reset;
    $view->output_buffer("Content-type: text/plain\n\n");
    $view->output_end;
    $view->output_buffer("Content-type: text/plain\n\n");
  };
  like($trap->stderr, qr/output_/mx, 'output buffer debugging');
  select $stdout;

  is($str, "Content-type: text/plain\n\n", 'output buffer ok with debugging');
}

{
  my $model = t::model->new;
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'list',
				     aspect => q[],
				    });

  is($view->template_name, 'view_list', 'view_list template_name');
}

{
  my $model = t::model->new;
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'list',
				     aspect => q[],
				    });
  $view->template_name('some_other');
  is($view->template_name, 'some_other', 'override template_name');
}

{
  my $model = t::model->new;
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'read',
				     aspect => q[],
				    });

  is($view->template_name, 'view_list', 'fix read / view_list template_name');
}

{
  my $cgi   = CGI->new;
  $cgi->param('test_field', 'blabla');
  $cgi->param('test_pk',    'two');

  $util->cgi($cgi);

  my $model = t::model->new({
			     util    => $util,
			     test_pk => 'one',
			    });
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'read',
				     aspect => q[],
				    });

  is($view->add, 1, 'add ok');

  is($model->test_field, 'blabla', 'test field');
  is($model->test_pk, 'one', 'test pk remains unmodified');

  for my $method (qw(create read update delete)) {
    is($view->$method, 1, "$method ok");
    my $method_xml = "${method}_xml";
    is($view->$method_xml, 1, "$method_xml ok");
  }

  $util->cgi(undef);
}

{
  my $model = t::model->new;
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'create',
				     aspect => q[],
				    });
  is($view->authorised, 1, 'always authorised when authentication unsupported');
}

{
  my $model = t::model->new;
  my $basic = t::user::basic->new;
  is($util->requestor($basic), $basic, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'create',
				     aspect => q[],
				    });
  is($view->authorised, undef, 'basic user cannot create');
}

{
  my $model = t::model->new;
  my $basic = t::user::basic->new;
  is($util->requestor($basic), $basic, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'read',
				     aspect => q[],
				    });
  is($view->authorised, 1, 'basic user can read');
}

{
  my $model = t::model->new;
  my $basic = t::user::basic->new;
  is($util->requestor($basic), $basic, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'list',
				     aspect => q[],
				    });
  is($view->authorised, 1, 'basic user can list');
}

{
  my $model = t::model->new;
  my $basic = t::user::basic->new;
  is($util->requestor($basic), $basic, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'read',
				     aspect => q(add),
				    });
  is($view->authorised, undef, 'basic user cannot add');
}

{
  my $model = t::model->new;
  my $basic = t::user::basic->new;
  is($util->requestor($basic), $basic, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'create',
				     aspect => q(update),
				    });
  is($view->authorised, undef, 'basic user cannot update');
}

{
  my $model = t::model->new;
  my $basic = t::user::basic->new;
  is($util->requestor($basic), $basic, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'edit',
				     aspect => q(delete),
				    });
  is($view->authorised, undef, 'basic user cannot delete');
}

{
  my $model = t::model->new;
  my $admin = t::user::admin->new;
  is($util->requestor($admin), $admin, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'create',
				     aspect => q[],
				    });
  is($view->authorised, 1, 'admin user can create');
}

{
  my $pid = $$;
  $util->data_path("/tmp/data$pid");
  my $model = t::model->new;
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'read',
				     aspect => q[],
				    });
  my $fn  = "/tmp/data$pid/templates/$pid.tt2";

  make_path("/tmp/data$pid/templates") or croak $ERRNO;

  copy('t/data/templates/cache.tt2', $fn) or croak $ERRNO;
  ok(-f $fn, 'test file copied');
  my $result1 = q[];
  $view->process_template("$pid.tt2", {}, \$result1);

  unlink $fn;
  like($result1, qr/cached/mx, 'first result');
  $util->data_path(q[]);
}

{
  my $pid = $$;
  $util->data_path("/tmp/data$pid");
  my $model = t::model->new;
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'read',
				     aspect => q[],
				    });
  my $fn  = "/tmp/data$pid/templates/$pid.tt2";

  my $err;
  make_path("/tmp/data$pid/templates",{verbose=>1,error=>\$err});
  if(scalar @{$err}) {
    croak "Error in make_path: @{$err}";
  }

  copy('t/data/templates/actions.tt2', $fn) or croak "Error in copy: $ERRNO";
  ok(-f $fn, 'test file copied');
  my $result2 = q[];
  $view->process_template("$pid.tt2", {}, \$result2);

  like($result2, qr/cached/mx, 'second process used cached template');

  rmtree('/tmp/data');
  $util->data_path(q[]);
}

{
  my $cgi = CGI->new;
  my $xml = qq[<?xml version='1.0'?>\n<model><test_pk>two</test_pk><test_field>bar</test_field></model>];

  $cgi->param('XForms:Model', $xml);
  $util->cgi($cgi);

  my $model = t::model->new({
			     test_pk => 'one',
			     util    => $util,
			    });
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'update',
				     aspect => q[],
				    });
  like($view->render, qr/Updated/smx, 'submit-xml render ok');
  is($model->test_pk,    'one', 'key population from param not xml');
  is($model->test_field, 'bar', 'field population from xml');
}

{
  my $cgi = CGI->new;
  my $xml = qq[<?xml version='1.0'?>\n<model><test_pk>two</test_pk><test_field>bar</test_field></model>];

  $cgi->param('POSTDATA', $xml);
  $util->cgi($cgi);

  my $model = t::model->new({
			     test_pk => 'one',
			     util    => $util,
			    });
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'update',
				     aspect => q[],
				    });
  like($view->render, qr/Updated/smx, 'submit-xml render ok');
  is($model->test_pk,    'one', 'key population from param not xml');
  is($model->test_field, 'bar', 'field population from xml');
}

{
  delete $util->{tt};
  my $view  = ClearPress::view->new({
				     util => $util,
				    });
  my $tt    = $view->tt; # initialise filters
  my $xml_f = $view->tt_filters->{xml_entity};

  is($xml_f->(0),     q[0]);
  is($xml_f->(q[]),   q[]);
  is($xml_f->(undef), q[]);
}

{
  my $view = ClearPress::view->new;
  is($view->charset, 'UTF-8', 'default charset');
}

{
  my $view = ClearPress::view->new({charset => 'iso8859-1'});
  is($view->charset, 'iso8859-1', 'constructor charset');
}

{
  my $view = ClearPress::view->new;
  $view->charset('koir-8');
  is($view->charset, 'koir-8', 'accessor charset');
}

{
  my $model = t::model->new;
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     aspect => q[],
				    });

  is($view->template_name, 'view', 'view template_name (no method)');
}

{
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $model  = t::model->new;
  my $view   = ClearPress::view->new({
                                      util   => $util,
                                      model  => $model,
                                      action => 'list',
                                      aspect => q[],
                                     });
  no warnings qw(redefine once);
  local *t::util::data_path = sub { return $tmpdir; };
  mkdir "$tmpdir/templates";
  mkdir "$tmpdir/templates/view";

  open my $fh, q[>], "$tmpdir/templates/view/list.tt2";
  close $fh;

  is($view->template_name, 'view/list', 'view/list template_name in subdirectory');
}

{
  my $model = t::model->new;
  my $view  = ClearPress::view->new({
                                     util  => $util,
                                     model => $model,
                                    });

  for my $aspect (qw(json xml ajax)) {
    for my $action (qw(list read create update delete)) {
      my $method = "ClearPress::view::$action";
      no strict 'refs';
      no warnings qw(redefine once);
      my $triggered = 0;
      local *{$method} = sub { $triggered = 1; };

      my $call = "${action}_$aspect";
      ok($view->$call, "$call return value");
      ok($triggered, "$call triggered $action")
    }
  }
}
