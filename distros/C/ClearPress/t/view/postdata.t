# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use IO::Scalar;
use CGI;
use Carp;
use lib qw(t/lib);
use t::request;
use t::model::derived;
use t::view::derived;
use t::view::touchy;
use JSON;

eval {
  require DBD::SQLite;
  plan tests => 9;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

{
  my $util = t::util->new;
  my $obj = {
	     char_dummy => "a string",
	     int_dummy  => 5,
	    };
  my $str = t::request->new({
			     PATH_INFO      => '/derived',
                             REQUEST_METHOD => 'POST',
                             util           => $util,
			     cgi_params     => {
						POSTDATA => JSON->new->encode($obj),
					       },
			    });
  my $ref = $util->dbh->selectall_arrayref(q[SELECT * FROM derived], {Slice => {}});

  is_deeply($ref, [
		   {
		    id_derived        => 1,
		    char_dummy        => "a string",
		    text_dummy        => undef,
		    int_dummy         => 5,
		    float_dummy       => undef,
		    id_derived_status => undef,
		    id_derived_parent => undef,
		   }
		  ], 'create with json postdata');
}

{
  my $util = t::util->new;
  my $existing = t::model::derived->new({
					 id_derived_parent => 1,
					 id_derived_status => 2,
					 char_dummy => "existing char",
					 float_dummy => 42.7,
					 int_dummy => 42,
					 text_dummy => "some text",
					});
  $existing->create;
  my $obj = {
	     id_derived => $existing->id_derived, # has no impact!
	     char_dummy => "a string",
	     int_dummy  => 5,
	    };
  my $str = t::request->new({
			     PATH_INFO      => "/derived/@{[$existing->id_derived]}",
                             REQUEST_METHOD => 'POST',
                             util           => $util,
			     cgi_params     => {
						POSTDATA => JSON->new->encode($obj),
					       },
			    });
  my $ref = $util->dbh->selectall_arrayref(q[SELECT * FROM derived], {Slice => {}});
  is_deeply($ref, [
		   {
		    id_derived_parent => 1,
		    char_dummy => 'a string',
		    text_dummy => 'some text',
		    int_dummy => 5,
		    id_derived => 1,
		    id_derived_status => 2,
		    float_dummy => 42.7,
		   }
		  ], 'update (id in url) with json postdata');
}

{
  my $util = t::util->new;
  my $existing = t::model::derived->new({
					 id_derived_parent => 1,
					 id_derived_status => 2,
					 char_dummy => "existing char",
					 float_dummy => 42.7,
					 int_dummy => 42,
					 text_dummy => "some text",
					});
  $existing->create;
  my $obj = {
	     id_derived => $existing->id_derived, # has no impact!
	     char_dummy => "a string",
	     int_dummy  => 5,
	    };
  my $str = t::request->new({
			     PATH_INFO      => '/derived',
                             REQUEST_METHOD => 'POST',
                             util           => $util,
			     cgi_params     => {
						POSTDATA => JSON->new->encode($obj),
					       },
			    });
  my $ref = $util->dbh->selectall_arrayref(q[SELECT * FROM derived], {Slice => {}});
  is_deeply($ref, [
		   {
		    id_derived_parent => 1,
		    char_dummy => 'existing char',
		    text_dummy => 'some text',
		    id_derived_status => 2,
		    id_derived => 1,
		    float_dummy => 42.7,
		    int_dummy => 42
		   },
		   {
		    id_derived_status => undef,
		    text_dummy => undef,
		    char_dummy => 'a string',
		    id_derived_parent => undef,
		    int_dummy => 5,
		    float_dummy => undef,
		    id_derived => 2
		   }
		  ], 'update (id in payload) with json postdata - should create, not update');
}

{
  my $util = t::util->new;
  $util->driver->drop_table('touchy');
  $util->driver->create_table('touchy',
			      {
			       id_touchy => 'primary key',
			       created   => 'timestamp',
			       last_modified => 'timestamp',
			      });
  my ($id, $created, $last_mod);

  {
    my $str  = t::request->new({
				PATH_INFO      => '/touchy',
				REQUEST_METHOD => 'POST',
				util           => $util,
				cgi_params     => {
						   POSTDATA => JSON->new->encode({}),
						  },
			       });

    ($id)       = $str =~ m{^id=(\d+)$}smix;
    ($created)  = $str =~ m{^created=(\d{4}-\d{2}-\d{2}[ ]\d{2}:\d{2}:\d{2})$}smix;
    ($last_mod) = $str =~ m{^last_modified=(\d{4}-\d{2}-\d{2}[ ]\d{2}:\d{2}:\d{2})$}smix;

    like($created,  qr{^\d{4}-\d{2}-\d{2}[ ]\d{2}:\d{2}:\d{2}$}smix, 'created set');
    like($last_mod, qr{^\d{4}-\d{2}-\d{2}[ ]\d{2}:\d{2}:\d{2}$}smix, 'last_modified set');
  }

  sleep 1; # sleep >=1 second to ensure last_modified is different

  {
    my $str  = t::request->new({
				PATH_INFO      => "/touchy/$id",
				REQUEST_METHOD => 'POST',
				util           => $util,
				cgi_params     => {
						   POSTDATA => JSON->new->encode({}),
						  },
			       });
    my ($id2, $created2, $last_mod2);
    ($id2)       = $str =~ m{^id=(\d+)$}smix;
    ($created2)  = $str =~ m{^created=(\d{4}-\d{2}-\d{2}[ ]\d{2}:\d{2}:\d{2})$}smix;
    ($last_mod2) = $str =~ m{^last_modified=(\d{4}-\d{2}-\d{2}[ ]\d{2}:\d{2}:\d{2})$}smix;

    like($created2,  qr{^\d{4}-\d{2}-\d{2}[ ]\d{2}:\d{2}:\d{2}$}smix, 'created set');
    like($last_mod2, qr{^\d{4}-\d{2}-\d{2}[ ]\d{2}:\d{2}:\d{2}$}smix, 'last_modified set');

    is($created, $created2, 'created timestamp unchanged');
    isnt($last_mod, $last_mod2, 'last_modified timestamp changed');
  }
}
