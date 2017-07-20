# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Test::Trap;

eval {
  require DBD::SQLite;
  plan tests => 81;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

use lib qw(t/lib);
use t::util;

our $CTRL = 'ClearPress::controller';
use_ok($CTRL);

my $util = t::util->new();

my $T = [
	 ['GET', '/',                          '', {}, 'read',  'example', 'list', 0], #default_view
	 ['GET', '/thing/method',              '', {}, 'read',  'thing', 'read', 'method'],
	 ['GET', '/thing2/method',             '', {}, 'read',  'thing2', 'list_method', 0],
	 ['GET', '/thing/method/50',           '', {}, 'read',  'thing', 'read_method', 50],
	 ['GET', '/thing3/avg/by/pos',         'id_run=1234', {}, 'read', 'thing3', 'list_avg_by_pos', 0],
	 ['GET', '/thing4/avg/by/pos.xml',     'id_run=1234', {}, 'read', 'thing4', 'list_avg_by_pos_xml', 0],
	 ['GET', '/thing5/avg/by/pos.xml',     'id_run=1234', {}, 'read', 'thing5', 'read_avg_by_xml', 'pos'],
	 ['GET', '/thing',                     '', {}, 'read',   'thing', 'list',     0],
	 ['GET', '/thing/1',                   '', {}, 'read',   'thing', 'read',     1],
	 ['GET', '/thing.xml',                 '', {}, 'read',   'thing', 'list_xml', 0],
	 ['GET', '/thing/1.xml',               '', {}, 'read',   'thing', 'read_xml', 1],
	 ['GET', '/thing;list_xml',            '', {}, 'read',   'thing', 'list_xml', 0],
	 ['GET', '/thing;do_stuff',            '', {}, 'read',   'thing', 'list_do_stuff', 0],
	 ['GET', '/thing/1;read_xml',          '', {}, 'read',   'thing', 'read_xml', 1],
	 ['GET', '/thing;add',                 '', {}, 'read',   'thing', 'add',      0],
	 ['GET', '/thing;add_xml',             '', {}, 'read',   'thing', 'add_xml',  0],
	 ['GET', '/thing.xml;add',             '', {}, 'read',   'thing', 'add_xml',  0],

	 ['GET', '/thing/1;edit',              '', {}, 'read',   'thing', 'edit',     1],
	 ['GET', '/thing/edit/1',              '', {}, 'read',   'thing', 'edit',     1],

	 ['GET', '/thing/edit/1.ajax',         '', {}, 'read',   'thing', 'edit_ajax', 1],
	 ['GET', '/thing/edit_ajax/1',         '', {}, 'read',   'thing', 'edit_ajax', 1],

	 ['GET', '/thing/edit_batch/1',        '', {}, 'read',   'thing', 'edit_batch', 1],
	 ['GET', '/thing/edit_batch/1.ajax',   '', {}, 'read',   'thing', 'edit_batch_ajax', 1],
	 ['GET', '/thing/edit_batch_ajax/1',   '', {}, 'read',   'thing', 'edit_batch_ajax', 1],
	 ['GET', '/thing/1.ajax;edit_batch',   '', {}, 'read',   'thing', 'edit_batch_ajax', 1],
	 ['GET', '/thing/1;edit_batch_ajax',   '', {}, 'read',   'thing', 'edit_batch_ajax', 1],

	 ['POST', '/thing/batch/1',             '', {}, 'update', 'thing', 'update_batch', 1],
	 ['POST', '/thing/batch/1.ajax',        '', {}, 'update', 'thing', 'update_batch_ajax', 1],
	 ['POST', '/thing/update_batch/1',      '', {}, 'update', 'thing', 'update_batch', 1],
	 ['POST', '/thing/batch/1.ajax',        '', {}, 'update', 'thing', 'update_batch_ajax', 1],
	 ['POST', '/thing/1.ajax;update_batch', '', {}, 'update', 'thing', 'update_batch_ajax', 1],
	 ['POST', '/thing/1;update_batch_ajax', '', {}, 'update', 'thing', 'update_batch_ajax', 1],

	 ['GET', '/thing/released/cluster.xml', '', {}, 'read', 'thing', 'read_released_xml', 'cluster'],

	 ['GET', '/user/me@example.com;edit',  '', {}, 'read',   'user',   'edit', 'me@example.com'],
	 ['GET', '/thing/heatmap.png',         '', {}, 'read',   'thing',  'read_png', 'heatmap'],
	 ['GET', '/thing5/heatmap.png',        '', {}, 'read',   'thing5', 'list_heatmap_png',   0],
	 ['GET', '/thing9/heatmap',            '', {}, 'read',   'thing9', 'list_heatmap',       0],
	 ['GET', '/thing/heatmap/45.png',      '', {}, 'read',   'thing',  'read_heatmap_png',   45],
	 ['POST', '/thing/heatmap/45.png',     '', {}, 'update', 'thing',  'update_heatmap_png', 45],

	 ['POST', '/thing',                    '', {}, 'create', 'thing', 'create', 0],
	 ['POST', '/thing.xml',                '', {}, 'create', 'thing', 'create_xml', 0],
	 ['POST', '/thing;create_xml',         '', {}, 'create', 'thing', 'create_xml', 0],
	 ['POST', '/thing/10',                 '', {}, 'update', 'thing', 'update', 10],
	 ['POST', '/thing/10.xml',             '', {}, 'update', 'thing', 'update_xml', 10],
	 ['POST', '/thing/10;update_xml',      '', {}, 'update', 'thing', 'update_xml', 10],
	 ['POST', '/thing/update/10.xml',      '', {}, 'update', 'thing', 'update_xml', 10],
	 ['POST', '/thing10/heatmap.png',      '', {}, 'create', 'thing10', 'create_heatmap_png', 0],

	 ['POST', '/thing6/batch.xml',         '', {}, 'create', 'thing6', 'create_batch_xml', 0],
	 ['POST', '/thing6/batch.xml',         '', {
						    HTTP_ACCEPT => 'text/xml',
						   }, 'create', 'thing6', 'create_batch_xml', 0],
	 ['POST', '/thing7/batch',             '', {
						    HTTP_X_REQUESTED_WITH => 'XMLHttpRequest',
						   },  'create', 'thing7', 'create_batch_ajax', 0], ###### fail
	 ['POST', '/thing7;create_batch',      '', {
						    HTTP_X_REQUESTED_WITH => 'XMLHttpRequest',
						   },  'create', 'thing7', 'create_batch_ajax', 0],
	 ['POST', '/thing7;create_batch_ajax', '', {}, 'create', 'thing7', 'create_batch_ajax', 0],
	 ['POST', '/thing7.ajax;create_batch', '', {}, 'create', 'thing7', 'create_batch_ajax', 0],
	 ['POST', '/thing8/batch.xml',         '', {
						    HTTP_X_REQUESTED_WITH => 'XMLHttpRequest',
						   },  'create', 'thing8', 'create_batch_xml', 0],
	 ['DELETE', '/thing/10',               '', {}, 'delete', 'thing', 'delete', 10],
	 ['POST',   '/thing/10;delete',        '', {}, 'delete', 'thing', 'delete', 10],

         ['GET', '/thing11/overridden',        '', {
                                                    HTTP_X_REQUESTED_WITH => 'XmlHttpRequest',
                                                   }, 'read', 'thing11', 'list_overridden_ajax', 0],
         ['GET', '/thing12.txt',               '', {
                                                    HTTP_X_REQUESTED_WITH => 'XmlHttpRequest',
                                                   }, 'read', 'thing12', 'list_txt', 0],
         ['GET', '/thing/12.txt',              '', {
                                                    HTTP_X_REQUESTED_WITH => 'XmlHttpRequest',
                                                   }, 'read', 'thing', 'read_txt', 12],
	 ['GET', '/testmap/test.xml',          '', {}, 'read', 'testmap', 'list_test_xml', 0],

         ['GET', '/thing/valid_flowcell/12.js', '', {
                                                     HTTP_X_REQUESTED_WITH => 'XmlHttpRequest',
                                                    }, 'read', 'thing', 'read_valid_flowcell_json', 12],
         ['GET', '/thing/valid_flowcell_json/12', '', {
                                                     HTTP_X_REQUESTED_WITH => 'XmlHttpRequest',
                                                    }, 'read', 'thing', 'read_valid_flowcell_json', 12],
	 ['OPTIONS', '/thing',                    '', {}, 'options',  'thing', 'options', 0],
	];

{
  no warnings;
  *{t::view::thing2::list_method}           = sub { return 1; };
  *{t::view::thing3::list_avg_by_pos}       = sub { return 1; };
  *{t::view::thing4::list_avg_by_pos_xml}   = sub { return 1; };
  *{t::view::thing5::list_heatmap_png}      = sub { return 1; };
  *{t::view::thing6::create_batch_xml}      = sub { return 1; };
  *{t::view::thing7::create_batch_ajax}     = sub { return 1; };
  *{t::view::thing8::create_batch_xml}      = sub { return 1; };
  *{t::view::thing9::list_heatmap}          = sub { return 1; };
  *{t::view::thing10::create_heatmap_png}   = sub { return 1; };
  *{t::view::thing11::list_overridden_ajax} = sub { return 1; };
  *{t::view::thing12::list_txt_ajax}        = sub { return 1; };
  *{t::view::foo::test::list_test_xml}      = sub { return 1; }; # packagemapped
}

{
  my $ctrl = $CTRL->new({util => $util});
  is($ctrl->packagespace('view', 'testmap', $util),
     't::view::foo::test',
     'packagemapped space');
}

sub request_test {
  my $t = shift;
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => $t->[0],
		PATH_INFO      => $t->[1],
		QUERY_STRING   => $t->[2],
		%{$t->[3]},
	       );
  my $ctrl    = $CTRL->new({util => $util});
  my $headers = HTTP::Headers->new;
  my $ref     = [];
  eval {
    $ref = [$ctrl->process_request($headers)];

  } or do {
    diag($EVAL_ERROR);
  };

  is((join q[,], @{$ref}),
     (join q[,], grep { defined } @{$t}[4..7]),
     "$t->[0] $t->[1]?$t->[2] => @{[join q[, ], grep {defined} @{$t}[4..7]]}");
  delete $util->{cgi};
}

for my $t (@{$T}) {
  request_test($t);
}

{
  no warnings qw(redefine once);
  local *t::util::data_path = sub { return 't/data-no-default_view'; };
  delete $util->{config};
  request_test(['GET', '/', '', {}, 'read',  'no_default', 'list', 0]);
}

{
  no warnings qw(redefine once);
  local *t::util::data_path = sub { return 't/data-no-views'; };
  delete $util->{config};
  request_test(['GET', '/', '', {}]);
}

my $B = [# METHOD PATH_INFO    QUERY_STRING CGI COMMENT
	 ['POST', '/thing/10;read_xml', '', {}, 'update vs. read'],
	 ['POST', '/thing;read',        '', {}, 'create vs. read'],
	 ['GET',  '/thing/10;delete',   '', {}, 'read vs. delete'],
	 ['GET',  '/thing;read',        '', {}, 'read without id'],
	 ['POST', '/thing;update',      '', {}, 'update without id'],
	 ['GET',  '/thing;edit',        '', {}, 'edit without id'],
	 ['POST', '/thing;delete',      '', {}, 'delete without id'],
	 ['POST', '/thing/10;create',   '', {}, 'create with id'],
	 ['GET',  '/thing/10;list',     '', {}, 'list with id'],
	 ['GET',  '/thing/10;add',      '', {}, 'add with id'],
	 ];

for my $b (@{$B}) {
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => $b->[0],
		PATH_INFO      => $b->[1],
		QUERY_STRING   => $b->[2],
		%{$b->[3]},
	       );
  my $ctrl    = $CTRL->new({util => $util});
  my $headers = HTTP::Headers->new;
  my $ref     = [];
  eval {
    $ref = [$ctrl->process_request($headers)];
  };

  if(scalar @{$ref}) {
    diag(join q[,], @{$ref});
  }

  like($EVAL_ERROR, qr/Bad[ ]request/smx, $b->[4]);
  delete $util->{cgi};
}

{
  delete $util->{config};

  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/10',
	       );

  my $ctrl = $CTRL->new({util => $util});
  trap {
    $ctrl->handler($util);
  };

  like($trap->stdout, qr{Status:[ ]500}smix,  'error response status');
  unlike($trap->stdout, qr/charset=UTF-8/smx, 'error response header is NOT UTF-8 by default');
  delete $util->{cgi};
}

{
  delete $util->{config};
$util->config->setval('application', 'views', 'thing20');
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing20',
	       );

  my $ctrl = $CTRL->new({util => $util});
  trap {
    $ctrl->handler($util);
  };

  like($trap->stdout, qr{Status:[ ]200}smix, 'non-error response status');
  like($trap->stdout, qr/charset=UTF-8/smx,  'non-error response header is UTF-8 by default');
  delete $util->{cgi};
}

package t::view::thing;
use base qw(ClearPress::view);

1;

package t::view::thing20;
use base qw(ClearPress::view);

sub decor { return; }
sub streamed_aspects { return ['list']; }
sub list {
  my $self = shift;
  $self->output_buffer($self->headers->as_string, "\n");
  $self->output_buffer(q[list]);
  return q[];
}
1;

package t::model::thing;
use base qw(ClearPress::model);

1;

package t::model::thing20;
use base qw(ClearPress::model);

1;
