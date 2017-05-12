#!perl

use strict;
use warnings;

use Test::More 'no_plan';    # tests => 15;

use lib 'lib';
use App::Grepl;
use App::Grepl::Results;

can_ok 'App::Grepl', 'new';

#
# Bad arguments to constructor
#

eval { App::Grepl->new( what => 'now' ) };
ok my $error = $@, '... and calling it without a hashref should fail';
like $error, qr/^\QArgument to new must be a hashref, not a (SCALAR)/,
  '... with an appropriate error message';

eval { App::Grepl->new( { what => 'now', brown => 'cow' } ) };
ok $error = $@, 'Calling it with bad keys should fail';
like $error, qr/^\QUnknown keys to new:  (brown, what)/,
  '... with an appropriate error message';

eval { App::Grepl->new( { dir => 'no such dir' } ) };
ok $error = $@, 'Specifying a non-existent directory should fail';
like $error, qr/^\QCannot find directory (no such dir)/,
  '... with an appropriate error message';

eval { App::Grepl->new( { files => ['no such file'] } ) };
ok $error = $@, 'Specifying a non-existent file should fail';
like $error, qr/^\QCannot find or read file (no such file)/,
  '... with an appropriate error message';

eval { App::Grepl->new( { files => 'no such file' } ) };
ok $error = $@, 'Specifying a non-existent file should fail';
like $error, qr/^\QCannot find or read file (no such file)/,
  '... with an appropriate error message';

eval { App::Grepl->new( { look_for => 'this' } ) };
ok $error = $@, 'Specifying a non-existent file should fail';
like $error, qr/^\QDon't know how to look_for (this)/,
  '... with an appropriate error message';

eval { App::Grepl->new( { dir => 't', files => 't/00-load.t' } ) };
ok $error = $@, 'dir and files are mutually exclusive';
like $error, qr/^\QYou cannot specify both "dir" and "files"/,
  '... and should generate an appropriate error message';

#
# Bad pattern
#

my $grepl = App::Grepl->new;
eval { $grepl->pattern('?') };
ok $error = $@, 'Trying to search on an invalid pattern should fail';
like $error,
  qr/^\QCould not search on (?):  Quantifier follows nothing in regex/,
  '... with an appropriate error message';

#
# filename_only should only return filenames
#

ok $grepl = App::Grepl->new(
    {
        dir           => 't/lib/quotes',
        filename_only => 1,
    }
  ),
  'We should be able to search on filenames only';
my @results = $grepl->search;
is $results[0]->file, 't/lib/quotes/quote1.pl', '... and get the filenames';
eval { $results[0]->next };
ok $error = $@,
  '... but asking for results from filename only searches should fail';
like $error, qr/^No results available for 'filename_only' results objects/,
  '... with an appropriate error message';

#
# Result failures
#

eval { App::Grepl::Results->new( { file => 'no_such_file' } ) };
ok $error = $@, 'Creating a results object with an unknown file should fail';
like $error, qr/^\QCannot find file (no_such_file)/,
  '... with an appropriate error message';

$grepl = App::Grepl::Results->new( { file => $0 } );
eval { $grepl->add_results( 'no_such_token' => [] ) };
ok $error = $@, 'Adding results for unknown tokens should fail';
like $error, qr/^\QDo not know how to add a result for (no_such_token)/,
    '... with an appropriate error message';
eval { $grepl->add_results( 'comment' => {} ) };
ok $error = $@, 'Adding results which are not an array ref should fail';
like $error, qr/^Results must be an array reference/,
    '... with an appropriate error message';
