#!perl -T

use strict;
use warnings;

use Test::More tests => 20;

use Biblio::Refbase;
use HTTP::Status ':constants';

use constant NO_INTERNET => 'no refbase for searching available';

my $refbase = Biblio::Refbase->new(
  url      => 'http://beta.refbase.net/',
  user     => 'guest@refbase.net',
  password => 'guest',
);



#
#  ping
#

can_ok $refbase, 'ping';
my $internet = $refbase->ping;
ok     defined $internet, 'ping returned defined';



#
#  search
#

can_ok $refbase, 'search';
eval { $refbase->search( foo => 'bar' ) };
like   $@, qr/^Unknown arguments/, 'search failed as expected due to unknown arguments';

my %fields = (
  author         => undef,
  title          => undef,
  type           => undef,
  year           => undef,
  publication    => undef,
  abbrev_journal => undef,
  keywords       => undef,
  abstract       => undef,
  thesis         => undef,
  area           => undef,
  notes          => undef,
  location       => undef,
  serial         => undef,
  date           => undef,
);

SKIP: {
  skip NO_INTERNET, 9 unless $internet;

  my $response = eval { $refbase->search( %fields, rows => 1 ) };
  unlike $@, qr/^Unknown arguments/, 'no unknown search fields';

  isa_ok $response, 'Biblio::Refbase::Response';
  isa_ok $response, 'HTTP::Response';

  can_ok $response, qw'is_success code hits content'
           or skip 'response misses some methods', 5;

  ok     $response->is_success, 'refbase could handle search request';
  is     $response->code, HTTP_OK, 'status code is OK';

  my $hits = $response->hits;
  ok     defined $hits, 'hits returned defined';
  ok     $hits > 0, 'search found some records'
           or skip 'search found nothing', 1;

  my $content = $response->content;
  ok     defined $content && length $content, 'search returned some records';
}

SKIP: {
  skip NO_INTERNET, 2 unless $internet;

  my $response = $refbase->search( user => 'let_me_fail' );
  isa_ok $response, 'Biblio::Refbase::Response';
  is     $response->code, HTTP_UNAUTHORIZED, 'status code is UNAUTHORIZED';
}



#
#  upload
#

can_ok $refbase, 'upload';
eval { $refbase->upload };
like   $@, qr/^upload requires/, 'upload failed as expected due to missing argument';
eval { $refbase->upload( 'baz', foo => 'bar' ) };
like   $@, qr/^Unknown arguments/, 'upload failed as expected due to unknown arguments';
eval { $refbase->upload( content => 'baz', foo => 'bar' ) };
like   $@, qr/^Unknown arguments/, 'upload failed as expected due to unknown arguments';
eval { $refbase->upload( source_ids => 'baz', foo => 'bar' ) };
like   $@, qr/^Unknown arguments/, 'upload failed as expected due to unknown arguments';
