# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Test::Trap;

eval {
  require DBD::SQLite;
  plan tests => 109;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

use lib qw(t/lib);
use t::util;

our $CTRL = 'ClearPress::controller';
use_ok($CTRL);

my $util = t::util->new();
my $ajax = { HTTP_X_REQUESTED_WITH => 'XmlHttpRequest' };
my $json = { HTTP_CONTENT_TYPE     => 'application/json' };
my $T = [
	 ['GET', '/',                                 '', undef, 'read',  'example', 'list', 0], #default_view
	 ['GET', '/thing/method',                     '', undef, 'read',  'thing', 'read', 'method'],
	 ['GET', '/thing2/method',                    '', undef, 'read',  'thing2', 'list_method', 0],
	 ['GET', '/thing/method/50',                  '', undef, 'read',  'thing', 'read_method', 50],
	 ['GET', '/thing3/avg/by/pos',                'id_run=1234', undef, 'read', 'thing3', 'list_avg_by_pos', 0],
	 ['GET', '/thing4/avg/by/pos.xml',            'id_run=1234', undef, 'read', 'thing4', 'list_avg_by_pos_xml', 0],
	 ['GET', '/thing5/avg/by/pos.xml',            'id_run=1234', undef, 'read', 'thing5', 'read_avg_by_xml', 'pos'],
	 ['GET', '/thing',                            '', undef, 'read',   'thing', 'list',     0],
	 ['GET', '/thing/1',                          '', undef, 'read',   'thing', 'read',     1],
	 ['GET', '/thing.xml',                        '', undef, 'read',   'thing', 'list_xml', 0],
	 ['GET', '/thing/1.xml',                      '', undef, 'read',   'thing', 'read_xml', 1],
	 ['GET', '/thing;list_xml',                   '', undef, 'read',   'thing', 'list_xml', 0],
	 ['GET', '/thing;do_stuff',                   '', undef, 'read',   'thing', 'list_do_stuff', 0],
	 ['GET', '/thing/1;read_xml',                 '', undef, 'read',   'thing', 'read_xml', 1],
	 ['GET', '/thing;add',                        '', undef, 'read',   'thing', 'add',      0],
	 ['GET', '/thing;add_xml',                    '', undef, 'read',   'thing', 'add_xml',  0],
	 ['GET', '/thing.xml;add',                    '', undef, 'read',   'thing', 'add_xml',  0],

	 ['GET', '/thing/1;edit',                     '', undef, 'read',   'thing', 'edit',     1],
	 ['GET', '/thing/edit/1',                     '', undef, 'read',   'thing', 'edit',     1],

	 ['GET', '/thing/edit/1.ajax',                '', undef, 'read',   'thing', 'edit_ajax', 1],
	 ['GET', '/thing/edit_ajax/1',                '', undef, 'read',   'thing', 'edit_ajax', 1],

	 ['GET', '/thing/edit_batch/1',               '', undef, 'read',   'thing', 'edit_batch',      1],
	 ['GET', '/thing/edit_batch/1.ajax',          '', undef, 'read',   'thing', 'edit_batch_ajax', 1],
	 ['GET', '/thing/edit_batch_ajax/1',          '', undef, 'read',   'thing', 'edit_batch_ajax', 1],
	 ['GET', '/thing/1.ajax;edit_batch',          '', undef, 'read',   'thing', 'edit_batch_ajax', 1],
	 ['GET', '/thing/1;edit_batch_ajax',          '', undef, 'read',   'thing', 'edit_batch_ajax', 1],

	 ['POST', '/thing/batch/1',                   '', undef, 'update', 'thing', 'update_batch', 1],
	 ['POST', '/thing/batch/1.ajax',              '', undef, 'update', 'thing', 'update_batch_ajax', 1],
	 ['POST', '/thing/update_batch/1',            '', undef, 'update', 'thing', 'update_batch', 1],
	 ['POST', '/thing/batch/1.ajax',              '', undef, 'update', 'thing', 'update_batch_ajax', 1],
	 ['POST', '/thing/1.ajax;update_batch',       '', undef, 'update', 'thing', 'update_batch_ajax', 1],
	 ['POST', '/thing/1;update_batch_ajax',       '', undef, 'update', 'thing', 'update_batch_ajax', 1],

	 ['GET', '/thing/released/cluster.xml',       '', undef, 'read', 'thing', 'read_released_xml', 'cluster'],

	 ['GET', '/user/me@example.com;edit',         '', undef, 'read',   'user',   'edit', 'me@example.com'],
	 ['GET', '/thing/heatmap.png',                '', undef, 'read',   'thing',  'read_png', 'heatmap'],
	 ['GET', '/thing5/heatmap.png',               '', undef, 'read',   'thing5', 'list_heatmap_png',   0],
	 ['GET', '/thing9/heatmap',                   '', undef, 'read',   'thing9', 'list_heatmap',       0],
	 ['GET', '/thing/heatmap/45.png',             '', undef, 'read',   'thing',  'read_heatmap_png',   45],
	 ['POST', '/thing/heatmap/45.png',            '', undef, 'update', 'thing',  'update_heatmap_png', 45],

	 ['POST', '/thing',                           '', undef, 'create', 'thing', 'create', 0],
	 ['POST', '/thing.xml',                       '', undef, 'create', 'thing', 'create_xml', 0],
	 ['POST', '/thing;create_xml',                '', undef, 'create', 'thing', 'create_xml', 0],
	 ['POST', '/thing/10',                        '', undef, 'update', 'thing', 'update', 10],
	 ['POST', '/thing/10.xml',                    '', undef, 'update', 'thing', 'update_xml', 10],
	 ['POST', '/thing/10;update_xml',             '', undef, 'update', 'thing', 'update_xml', 10],
	 ['POST', '/thing/update/10.xml',             '', undef, 'update', 'thing', 'update_xml', 10],
	 ['POST', '/thing10/heatmap.png',             '', undef, 'create', 'thing10', 'create_heatmap_png', 0],

	 ['POST', '/thing6/batch.xml',                '', undef, 'create', 'thing6', 'create_batch_xml', 0],
	 ['POST', '/thing6/batch.xml',                '', {
                                                           HTTP_ACCEPT => 'text/xml',
                                                          }, 'create', 'thing6', 'create_batch_xml', 0],
	 ['POST', '/thing7/batch',                    '', $ajax, 'create', 'thing7', 'create_batch_ajax', 0], ###### fail
	 ['POST', '/thing7;create_batch',             '', $ajax, 'create', 'thing7', 'create_batch_ajax', 0],
	 ['POST', '/thing7;create_batch_ajax',        '', undef, 'create', 'thing7', 'create_batch_ajax', 0],
	 ['POST', '/thing7.ajax;create_batch',        '', undef, 'create', 'thing7', 'create_batch_ajax', 0],
	 ['POST', '/thing8/batch.xml',                '', $ajax, 'create', 'thing8', 'create_batch_xml', 0],
	 ['DELETE', '/thing/10',                      '', undef, 'delete', 'thing', 'delete', 10],
	 ['POST',   '/thing/10;delete',               '', undef, 'delete', 'thing', 'delete', 10],

         ['GET', '/thing11/overridden',               '', $ajax, 'read', 'thing11', 'list_overridden_ajax', 0],
         ['GET', '/thing12.txt',                      '', $ajax, 'read', 'thing12', 'list_txt', 0],
         ['GET', '/thing/12.txt',                     '', $ajax, 'read', 'thing', 'read_txt', 12],
	 ['GET', '/testmap/test.xml',                 '', undef, 'read', 'testmap', 'list_test_xml', 0],

         ['GET', '/thing/valid_flowcell/12.js',       '', $ajax, 'read', 'thing', 'read_valid_flowcell_json', 12],
         ['GET', '/thing/valid_flowcell_json/12',     '', $ajax, 'read', 'thing', 'read_valid_flowcell_json', 12],

	 ['OPTIONS', '/',                             '', undef, 'options', 'example', 'options',             0],
	 ['OPTIONS', '/thing',                        '', undef, 'options', 'thing',   'options',             0],
	 ['OPTIONS', '/thing/1',                      '', undef, 'options', 'thing',   'options',             1],
	 ['OPTIONS', '/thing/1.js',                   '', undef, 'options', 'thing',   'options_json',        1],
	 ['OPTIONS', '/thing/1.xml',                  '', undef, 'options', 'thing',   'options_xml',         1],
	 ['OPTIONS', '/thing/entity',                 '', undef, 'options', 'thing',   'options',             'entity'],
	 ['OPTIONS', '/thing/method/1',               '', undef, 'options', 'thing',   'options_method',      1],
	 ['OPTIONS', '/thing/method/1.js',            '', undef, 'options', 'thing',   'options_method_json', 1],
	 ['OPTIONS', '/thing/method/1.xml',           '', undef, 'options', 'thing',   'options_method_xml',  1],
	 ['OPTIONS', '/thing/deep/entity',            '', undef, 'options', 'thing',   'options_deep',        'entity'],
	 ['OPTIONS', '/thing/deep/entity.xml',        '', undef, 'options', 'thing',   'options_deep_xml',    'entity'],

         ['OPTIONS', '/thing11/overridden',           '', $ajax, 'options', 'thing11', 'options_overridden_ajax',     0],
         ['OPTIONS', '/thing12.txt',                  '', $ajax, 'options', 'thing12', 'options_txt',                 0],
         ['OPTIONS', '/thing/12.txt',                 '', $ajax, 'options', 'thing',   'options_txt',                 12],
	 ['OPTIONS', '/testmap/test.xml',             '', undef, 'options', 'testmap', 'options_test_xml',            0],
         ['OPTIONS', '/thing/valid_flowcell/12.js',   '', $ajax, 'options', 'thing',   'options_valid_flowcell_json', 12],
         ['OPTIONS', '/thing/valid_flowcell_json/12', '', $ajax, 'options', 'thing',   'options_valid_flowcell_json', 12],

         # interesting compound queries. Apache can use the "AllowEncodedSlashes On" directive
	 ['GET',  '/thing/released/cluster/foo',        '', undef, 'read',   'thing', 'read_released_cluster', 'foo'],
	 ['GET',  '/thing/released/cluster%2Ffoo',      '', undef, 'read',   'thing', 'read_released', 'cluster/foo'],
	 ['POST', '/thing/released/cluster/foo',        '', undef, 'update', 'thing', 'update_released_cluster', 'foo'],
	 ['POST', '/thing/released/cluster%2Ffoo',      '', undef, 'update', 'thing', 'update_released', 'cluster/foo'],

	 ['GET',  '/thing/released/cluster/foo.json',   '', undef, 'read',   'thing', 'read_released_cluster_json', 'foo'],
	 ['GET',  '/thing/released/cluster%2Ffoo.json', '', undef, 'read',   'thing', 'read_released_json', 'cluster/foo'],
	 ['POST', '/thing/released/cluster/foo.json',   '', undef, 'update', 'thing', 'update_released_cluster_json', 'foo'],
	 ['POST', '/thing/released/cluster%2Ffoo.json', '', undef, 'update', 'thing', 'update_released_json', 'cluster/foo'],

	 ['GET',  '/thing/released/cluster/foo.json',   '', $json, 'read',   'thing', 'read_released_cluster_json', 'foo'],
	 ['GET',  '/thing/released/cluster%2Ffoo.json', '', $json, 'read',   'thing', 'read_released_json', 'cluster/foo'],
	 ['POST', '/thing/released/cluster/foo.json',   '', $json, 'update', 'thing', 'update_released_cluster_json', 'foo'],
	 ['POST', '/thing/released/cluster%2Ffoo.json', '', $json, 'update', 'thing', 'update_released_json', 'cluster/foo'],
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
  *{t::view::thing11::options_overridden_ajax} = sub { return 1; };
  *{t::view::thing12::options_txt_ajax}        = sub { return 1; };
  *{t::view::foo::test::options_test_xml}      = sub { return 1; }; # packagemapped
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
		%{$t->[3]||{}},
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

#########
# Bad requests - broken combinations
#
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
