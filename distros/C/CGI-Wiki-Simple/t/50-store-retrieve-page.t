#!/usr/bin/perl -w
use strict;
use FindBin;
use File::Spec;
use CGI;
use CGI::Carp;
use CGI::Wiki::TestConfig;
use CGI::Wiki::TestConfig::Utilities;
use DBI;
use Test::Without::Module qw( HTML::Template );
use Test::HTML::Content;

BEGIN {
  use Test::More tests => 2+(25 * $CGI::Wiki::TestConfig::Utilities::num_stores);

  use_ok( "CGI::Wiki::Simple" );
  use_ok( "CGI::Wiki::Simple::Setup" );
};

use vars qw( $cgi $store %stores );

%stores = CGI::Wiki::TestConfig::Utilities->stores;

my @warnings;
BEGIN { $SIG{__WARN__} = sub { push @warnings, @_ };};

sub get_cgi_response {
  my $wiki = CGI::Wiki::Simple->new( TMPL_PATH => 'templates', PARAMS => { store => $store, search => undef } );
  isa_ok( $wiki, "CGI::Wiki::Simple", "The wiki" );
  my $result = $wiki->run;
  is_deeply(\@warnings,[],"No warnings raised during run");
  @warnings = ();
  my ($headers,$body) = split( /\015\012\015\012/ms, $result, 2);
  $headers = HTTP::Headers->new( map { /^(.*?): (.*)$/ ? ($1,$2) : () } split( /\r\n/, $headers ));
  my $response = HTTP::Response->new( 200, 'Testing', $headers, $body );
  $response;
};

{ no warnings 'once';
  *CGI::Wiki::Simple::cgiapp_get_query = sub { $cgi };
};

$ENV{SCRIPT_NAME} = '/wiki/test';
$ENV{CGI_APP_RETURN_ONLY} = "testing";

use vars qw( %dbargs $dataoffset );

SKIP: {
  $dataoffset = tell DATA;
  my ($storename);
  while (($storename,$store) = each %stores) {
    SKIP: {
      eval { require HTTP::Response; };
      skip "Need HTTP::Response to test CGI interaction", 25
        if $@;
      skip "Store $storename not configured for testing", 25
        unless $store;

      seek DATA, $dataoffset, 0
        or die "Couldn't reset data position";

      # We need to dispose of that store, but we'll steal the parameters :
      $dbargs{$_} = $store->$_ for (qw(dbname dbuser dbpass));

      my $storename = ref $store;
      $storename =~ m!^CGI::Wiki::Store::(.+)!
        or croak "Unknown wiki store subclass $storename";
      $dbargs{dbtype} = $1;
      $store->dbh->disconnect;
      undef $store;

      # Now set up an empty database :
      CGI::Wiki::Simple::Setup::setup( %dbargs, clear => 1, nocontent => 1, silent => 1 );

      # And recreate a store :
      $store = CGI::Wiki::Simple::Setup::get_store(%dbargs);
      my $nodes = $store->dbh->selectall_arrayref("select * from content");
      is_deeply($nodes,[],"Clean database");

      # Set up the environment as to fake a real CGI environment :
      $cgi = CGI->new('');
      $cgi->path_info('/display/foo');

      # Now let our app run on the database :
      my $response = get_cgi_response();

      # Now check that our output looks like we intended :
      is( $response->header('Title'), "foo", "$storename: Title header" );
      like( $response->header('Content-type'), qr"^text/html", "$storename: Content type text/html" );
      # Ugh. RE-HTML-parsing. I gotta finish the port of Test::HTML::Content to XPath
      like($response->content, qr!<title>foo</title>!i, "$storename: Title tag");
      like( $response->content, qr'<hr /><hr />', "$storename: Empty response wiki content");
      link_ok($response->content,'/wiki/test/preview/foo',"$storename: Edit link");
      no_link($response->content,'/wiki/test/display/foo',"$storename: No display link");
      # I also need form actions in T:H:C ...
      no_tag($response->content,'form', { action => '/wiki/test/commit/foo' },"$storename: Commit link");

      # Test our default page setup
      link_ok($response->content,'http://search.cpan.org/search?mode=module&query=CGI::Wiki',"$storename: CGI::Wiki link");
      tag_ok($response->content,'form', { action => '/wiki/test' },"$storename: Searchbox");

      # Now submit new content
      $cgi = CGI->new(*DATA);
      $cgi->path_info('/commit/foo');

      $response = get_cgi_response();

      is($response->header('Status'),'302 Moved',"$storename: Redirect after edit");
      is($response->header('Location'),'/wiki/test/display/foo',"$storename: Redirect url after edit");

      # Look at the edit page
      $cgi = CGI->new(*DATA);
      $cgi->path_info('/preview/foo');

      $response = get_cgi_response();

      no_link($response->content,'/wiki/test/preview/foo',"$storename: No edit link (edit page)");
      link_ok($response->content,'/wiki/test/display/foo',"$storename: Display link (edit page)");
      like($response->content,qr'\bTesting setting a new value\b',"$storename: Editbox content");

      # Check that we receive the new content back
      $cgi = CGI->new(*DATA);
      $cgi->path_info('/display/foo');

      $response = get_cgi_response();
      is($response->header('Title'),'foo','Title');
      like( $response->content, qr'\bTesting setting a new value\b', "Filled wiki content");

      # Check for munging of HTML entities

      # Now edit the page again
      # Check the page title
      # Check the page headers
      # Submit it with a wrong MD5
      # And check that we end up on the conflict page

      # Add a test for sub render() :
      #   render with empty action list should return three no_link/no_tags
      #   render with combined action list should return the correct links/tags
      #   render with empty action list should return three no_link/no_tags

      #$store->dbh->disconnect;
      #unlink $dbfile
      #  or diag "Couldn't remove $dbfile : $!";
    };
  };
}

__DATA__
content=Testing%20setting%20a%20new%20value%0D%0A
save=commit
checksum=d41d8cd98f00b204e9800998ecf8427e
=
