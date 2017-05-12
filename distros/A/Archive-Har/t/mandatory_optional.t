#!perl -T

use strict;
use warnings;
use Test::More tests => 139;
use Archive::Har();
use JSON();

my $har = Archive::Har->new();

my $checking = <<'_CHECK_';
{
  "log": {
      "comment": "empty har"
   }
}
_CHECK_
$har->string($checking);
my $hash = JSON::decode_json($har->string());
ok($hash, "Successfully read empty har archive");
ok($hash->{log}->{version}, "version is defined for har archive:$hash->{log}->{version}");
ok((defined $hash->{log}->{creator} and ref $hash->{log}->{creator} eq 'HASH' and $hash->{log}->{creator}->{name} && $hash->{log}->{creator}->{version}), "creator is defined as a HASH");
ok(!defined $hash->{log}->{browser}, "browser is not defined");
ok(!defined $hash->{log}->{pages}, "pages is not defined");
ok((defined $hash->{log}->{entries} and (ref $hash->{log}->{entries} eq 'ARRAY') and (@{$hash->{log}->{entries}} == 0)), "entries is defined as an empty ARRAY");
ok($hash->{log}->{comment} eq "empty har", "comment is correct");
$checking = <<'_CHECK_';
{
  "log": {
        "creator": { "comment": "test creator", "_private": "creator" },
        "browser": { "comment": "test browser", "_private": "browser" },
	"pages": [ {} ]
   }
}
_CHECK_
$har->string($checking);
$hash = $har->hashref();
ok($hash, "Successfully read empty page element in har archive");
ok($hash->{log}->{pages}->[0]->{startedDateTime} =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+\+\d{2}:\d{2}$/smx, "page->startedDateTime is defined as a datetime:$hash->{log}->{pages}->[0]->{startedDateTime}");
ok($hash->{log}->{pages}->[0]->{id} eq 'page_0', "page->id is defined as page_0:$hash->{log}->{pages}->[0]->{id}");
ok(length $hash->{log}->{pages}->[0]->{title}, "page->title is defined:$hash->{log}->{pages}->[0]->{title}");
ok((defined $hash->{log}->{pages}->[0]->{pageTimings} and ref $hash->{log}->{pages}->[0]->{pageTimings} eq 'HASH'), "page->pageTimings is defined as a HASH");

ok($hash->{log}->{browser}->{comment} eq "test browser", "comment is correct");
ok($hash->{log}->{browser}->{_private} eq "browser", "_private value is correct");
$har->browser()->_private("value");
$hash = $har->hashref();
ok($hash->{log}->{browser}->{_private} eq "value", "new _private value is correct (1)");
ok($har->browser()->_private() eq "value", "new _private value is correct (2)");
eval { $har->browser()->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");

ok($hash->{log}->{creator}->{comment} eq "test creator", "comment is correct");
ok($hash->{log}->{creator}->{_private} eq "creator", "_private value is correct");
$har->creator()->_private("value");
$hash = $har->hashref();
ok($hash->{log}->{creator}->{_private} eq "value", "new _private value is correct (1)");
ok($har->creator()->_private() eq "value", "new _private value is correct (2)");
eval { $har->creator()->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");

# entries

$checking = <<'_CHECK_';
{
  "log": {
	"entries": [ { "comment": "test entry", "_private": "entry", "cache": { "comment": "test cache", "_private": "cache", "beforeRequest": { "comment": "test beforeRequest", "_private": "beforeRequest" }, "afterRequest": null } } ]
   }
}
_CHECK_

$har->string($checking);
$hash = $har->hashref();
ok($hash, "Successfully read empty entry element in har archive");
ok($hash->{log}->{entries}->[0]->{startedDateTime} =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+\+\d{2}:\d{2}$/smx, "entry->startedDateTime is defined as a datetime:$hash->{log}->{entries}->[0]->{startedDateTime}");
foreach my $name (qw(request response cache timings)) {
	ok((defined $hash->{log}->{entries}->[0]->{$name} and ref $hash->{log}->{entries}->[0]->{$name} eq 'HASH'), "page->$name is defined as a HASH");
}
ok($hash->{log}->{entries}->[0]->{time} =~ /^\-?\d+$/smx, "entry->time is defined as a number:$hash->{log}->{entries}->[0]->{time}");
(($har->entries())[0])->started_date_time(undef);
$hash = $har->hashref();
ok($hash->{log}->{entries}->[0]->{startedDateTime} eq '0000-00-00T00:00:00.0+00:00', "started_date_time is not defined");


ok($hash->{log}->{entries}->[0]->{comment} eq "test entry", "comment is correct");
ok($hash->{log}->{entries}->[0]->{_private} eq "entry", "_private value is correct");
(($har->entries())[0])->_private(undef);
$hash = $har->hashref();
ok(!exists $hash->{log}->{entries}->[0]->{_private}, "new _private value is correct (2)");
(($har->entries())[0])->_private("value");
$hash = $har->hashref();
ok($hash->{log}->{entries}->[0]->{_private} eq "value", "new _private value is correct (3)");
ok((($har->entries())[0])->_private() eq "value", "new _private value is correct (4)");
eval { (($har->entries())[0])->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");
eval { (($har->entries())[0])->started_date_time("not_formatted") };
ok($@ =~ /^started_date_time is not formatted correctly/, "started_date_time throws an exception with invalid input");

ok($hash->{log}->{entries}->[0]->{cache}->{comment} eq "test cache", "comment is correct");
ok($hash->{log}->{entries}->[0]->{cache}->{_private} eq "cache", "_private is correct");
(($har->entries())[0])->cache()->_private(undef);
$hash = $har->hashref();
ok(!exists $hash->{log}->{entries}->[0]->{cache}->{_private}, "new _private value is correct (2)");
(($har->entries())[0])->cache()->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{cache}->{_private} eq "value", "new _private value is correct (3)");
ok((($har->entries())[0])->cache()->_private() eq "value", "new _private value is correct (4)");
eval { (($har->entries())[0])->cache()->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");

ok($hash->{log}->{entries}->[0]->{cache}->{beforeRequest}->{comment} eq "test beforeRequest", "comment is correct");
ok($hash->{log}->{entries}->[0]->{cache}->{beforeRequest}->{_private} eq "beforeRequest", "_private is correct");
(($har->entries())[0])->cache()->before_request()->_private(undef);
$hash = JSON::decode_json($har->string());
ok(!exists $hash->{log}->{entries}->[0]->{cache}->{beforeRequest}->{_private}, "new _private value is correct (2)");
(($har->entries())[0])->cache()->before_request()->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{cache}->{beforeRequest}->{_private} eq "value", "new _private value is correct (3)");
ok((($har->entries())[0])->cache()->before_request()->_private() eq "value", "new _private value is correct (4)");
eval { (($har->entries())[0])->cache()->before_request()->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");
eval { (($har->entries())[0])->cache()->before_request()->last_access("not_formatted") };
ok($@ =~ /^last_access is not formatted correctly/, "last_access throws an exception with invalid input");

# request

ok(($hash->{log}->{entries}->[0]->{request}->{method} eq 'GET'), "request->method is GET by default");
ok(($hash->{log}->{entries}->[0]->{request}->{url} eq 'http://example.com/'), "request->url is http://example.com/ by default");
ok(($hash->{log}->{entries}->[0]->{request}->{httpVersion} eq 'HTTP/0.9'), "request->http_version is HTTP/0.9 by default");
ok(($hash->{log}->{entries}->[0]->{request}->{headersSize} == -1), "request->headersSize is -1 by default");
ok(($hash->{log}->{entries}->[0]->{request}->{bodySize} == -1), "request->bodySize is -1 by default");

$checking = <<'_CHECK_';
{
  "log": {
	"entries": [ { "request": { "comment": "test request", "_private": "request", "postData": { "comment": "test postData", "_private": "postData", "params": [ { "comment": "test params", "fileName": "example.pdf", "contentType": "application/pdf", "_private": "params" } ] }, "headers": [ { "comment": "test headers", "_private": "headers" } ], "queryString": [ { "comment": "test queryString", "_private": "queryString" } ] }, "response": { "comment": "test response", "_private": "response", "cookies": [ { "comment": "test cookie", "_private": "cookie" } ], "content": { "comment": "test content", "_private": "content" } }, "timings": { "comment": "test timings", "_private": "timings" } } ]
   }
}
_CHECK_

$har->string($checking);
$hash = JSON::decode_json($har->string());
ok($hash, "Successfully read request/response/cookie elements in har archive");

ok($hash->{log}->{entries}->[0]->{request}->{comment} eq "test request", "comment is correct");
ok($hash->{log}->{entries}->[0]->{request}->{_private} eq "request", "_private is correct");
(($har->entries())[0])->request()->_private(undef);
$hash = JSON::decode_json($har->string());
ok(!exists $hash->{log}->{entries}->[0]->{request}->{_private}, "new _private value is correct (2)");
(($har->entries())[0])->request()->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{request}->{_private} eq "value", "new _private value is correct (3)");
ok((($har->entries())[0])->request()->_private() eq "value", "new _private value is correct (4)");
eval { (($har->entries())[0])->request()->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");

ok($hash->{log}->{entries}->[0]->{response}->{comment} eq "test response", "comment is correct");
ok($hash->{log}->{entries}->[0]->{response}->{_private} eq "response", "_private is correct");
(($har->entries())[0])->response()->_private(undef);
$hash = JSON::decode_json($har->string());
ok(!exists $hash->{log}->{entries}->[0]->{response}->{_private}, "new _private value is correct (2)");
(($har->entries())[0])->response()->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{response}->{_private} eq "value", "new _private value is correct (3)");
ok((($har->entries())[0])->response()->_private() eq "value", "new _private value is correct (4)");
eval { (($har->entries())[0])->response()->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");

ok($hash->{log}->{entries}->[0]->{response}->{cookies}->[0]->{comment} eq "test cookie", "comment is correct");
ok($hash->{log}->{entries}->[0]->{response}->{cookies}->[0]->{_private} eq "cookie", "_private is correct");
(((($har->entries())[0])->response()->cookies())[0])->_private(undef);
$hash = JSON::decode_json($har->string());
ok(!exists $hash->{log}->{entries}->[0]->{response}->{cookies}->[0]->{_private}, "new _private value is correct (2)");
(((($har->entries())[0])->response()->cookies())[0])->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{response}->{cookies}->[0]->{_private} eq "value", "new _private value is correct (3)");
ok((((($har->entries())[0])->response()->cookies())[0])->_private() eq "value", "new _private value is correct (4)");
eval { (((($har->entries())[0])->response()->cookies())[0])->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");

ok($hash->{log}->{entries}->[0]->{response}->{content}->{comment} eq "test content", "comment is correct");
ok($hash->{log}->{entries}->[0]->{response}->{content}->{_private} eq "content", "_private is correct");
(($har->entries())[0])->response()->content()->_private(undef);
$hash = JSON::decode_json($har->string());
ok(!exists $hash->{log}->{entries}->[0]->{response}->{content}->{_private}, "new _private value is correct (2)");
(($har->entries())[0])->response()->content()->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{response}->{content}->{_private} eq "value", "new _private value is correct (3)");
ok((($har->entries())[0])->response()->content()->_private() eq "value", "new _private value is correct (4)");
eval { (($har->entries())[0])->response()->content()->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");

ok($hash->{log}->{entries}->[0]->{request}->{headers}->[0]->{comment} eq "test headers", "comment is correct");
ok($hash->{log}->{entries}->[0]->{request}->{headers}->[0]->{_private} eq "headers", "_private is correct");
(((($har->entries())[0])->request()->headers())[0])->_private(undef);
$hash = JSON::decode_json($har->string());
ok(!exists $hash->{log}->{entries}->[0]->{request}->{headers}->[0]->{_private}, "new _private value is correct (2)");
(((($har->entries())[0])->request()->headers())[0])->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{request}->{headers}->[0]->{_private} eq "value", "new _private value is correct (3)");
ok((((($har->entries())[0])->request()->headers())[0])->_private() eq "value", "new _private value is correct (4)");
eval { (((($har->entries())[0])->request()->headers())[0])->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");

ok($hash->{log}->{entries}->[0]->{request}->{postData}->{comment} eq "test postData", "comment is correct");
ok($hash->{log}->{entries}->[0]->{request}->{postData}->{_private} eq "postData", "_private is correct");
(($har->entries())[0])->request()->post_data()->_private(undef);
$hash = JSON::decode_json($har->string());
ok(!exists $hash->{log}->{entries}->[0]->{request}->{postData}->{_private}, "new _private value is correct (2)");
(($har->entries())[0])->request()->post_data()->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{request}->{postData}->{_private} eq "value", "new _private value is correct (3)");
ok((($har->entries())[0])->request()->post_data()->_private() eq "value", "new _private value is correct (4)");
eval { (($har->entries())[0])->request()->post_data()->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");

ok($hash->{log}->{entries}->[0]->{request}->{postData}->{params}->[0]->{comment} eq "test params", "comment is correct");
ok($hash->{log}->{entries}->[0]->{request}->{postData}->{params}->[0]->{fileName} eq "example.pdf", "fileName is correct");
ok($hash->{log}->{entries}->[0]->{request}->{postData}->{params}->[0]->{contentType} eq "application/pdf", "contentType is correct");
ok($hash->{log}->{entries}->[0]->{request}->{postData}->{params}->[0]->{_private} eq "params", "_private is correct");
(((($har->entries())[0])->request()->post_data()->params())[0])->_private(undef);
$hash = JSON::decode_json($har->string());
ok(!exists $hash->{log}->{entries}->[0]->{request}->{postData}->{params}->[0]->{_private}, "new _private value is correct (2)");
(((($har->entries())[0])->request()->post_data()->params())[0])->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{request}->{postData}->{params}->[0]->{_private} eq "value", "new _private value is correct (3)");
ok((((($har->entries())[0])->request()->post_data()->params())[0])->_private() eq "value", "new _private value is correct (4)");
eval { (((($har->entries())[0])->request()->post_data()->params())[0])->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");

ok($hash->{log}->{entries}->[0]->{request}->{queryString}->[0]->{comment} eq "test queryString", "comment is correct");
ok($hash->{log}->{entries}->[0]->{request}->{queryString}->[0]->{_private} eq "queryString", "_private is correct");
(((($har->entries())[0])->request()->query_string())[0])->_private(undef);
$hash = JSON::decode_json($har->string());
ok(!exists $hash->{log}->{entries}->[0]->{request}->{queryString}->[0]->{_private}, "new _private value is correct (2)");
(((($har->entries())[0])->request()->query_string())[0])->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{request}->{queryString}->[0]->{_private} eq "value", "new _private value is correct (3)");
ok((((($har->entries())[0])->request()->query_string())[0])->_private() eq "value", "new _private value is correct (4)");
eval { (((($har->entries())[0])->request()->query_string())[0])->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");

ok($hash->{log}->{entries}->[0]->{timings}->{comment} eq "test timings", "comment is correct");
ok($hash->{log}->{entries}->[0]->{timings}->{_private} eq "timings", "_private is correct");
(($har->entries())[0])->timings()->ssl(undef);
(($har->entries())[0])->timings()->blocked(undef);
(($har->entries())[0])->timings()->connect(undef);
(($har->entries())[0])->timings()->dns(undef);
(($har->entries())[0])->timings()->_private(undef);
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{timings}->{ssl} == -1, "timings ssl unavailable is correct");
ok($hash->{log}->{entries}->[0]->{timings}->{blocked} == -1, "timings blocked unavailable is correct");
ok($hash->{log}->{entries}->[0]->{timings}->{connect} == -1, "timings connect unavailable is correct");
ok($hash->{log}->{entries}->[0]->{timings}->{dns} == -1, "timings dns unavailable is correct");
ok(!exists $hash->{log}->{entries}->[0]->{timings}->{_private}, "new _private value is correct (2)");
(($har->entries())[0])->timings()->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{timings}->{_private} eq "value", "new _private value is correct (3)");
ok((($har->entries())[0])->timings()->_private() eq "value", "new _private value is correct (4)");
eval { (($har->entries())[0])->timings()->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");

(($har->entries())[0])->request()->post_data()->text("foobar");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{entries}->[0]->{request}->{postData}->{text} eq "foobar", "postData text is correct");
ok(!exists $hash->{log}->{entries}->[0]->{request}->{postData}->{params}->[0], "postData params does not exist");

$checking = <<'_CHECK_';
{
  "log": {
	"pages": [ { "comment": "test pages", "_private": "pages", "pageTimings": { "comment": "test pageTimings", "_private": "pageTimings" } } ]
   }
}
_CHECK_
$har->string($checking);
$hash = JSON::decode_json($har->string());
ok($hash, "Successfully read pages elements in har archive");
ok($hash->{log}->{pages}->[0]->{comment} eq "test pages", "comment is correct");
ok($hash->{log}->{pages}->[0]->{_private} eq "pages", "_private is correct");
(($har->pages())[0])->_private(undef);
$hash = JSON::decode_json($har->string());
ok(!exists $hash->{log}->{pages}->[0]->{_private}, "new _private value is correct (2)");
(($har->pages())[0])->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{pages}->[0]->{_private} eq "value", "new _private value is correct (3)");
ok((($har->pages())[0])->_private() eq "value", "new _private value is correct (4)");
eval { (($har->pages())[0])->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");
(($har->pages())[0])->started_date_time(undef);
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{pages}->[0]->{startedDateTime} eq '0000-00-00T00:00:00.0+00:00', "started_date_time is not defined");
eval { (($har->pages())[0])->started_date_time("not_formatted") };
ok($@ =~ /^started_date_time is not formatted correctly/, "started_date_time throws an exception with invalid input");

ok($hash->{log}->{pages}->[0]->{pageTimings}->{comment} eq "test pageTimings", "comment is correct");
ok($hash->{log}->{pages}->[0]->{pageTimings}->{_private} eq "pageTimings", "_private is correct");
(($har->pages())[0])->page_timings()->_private(undef);
$hash = JSON::decode_json($har->string());
ok(!exists $hash->{log}->{pages}->[0]->{pageTimings}->{_private}, "new _private value is correct (2)");
(($har->pages())[0])->page_timings()->_private("value");
$hash = JSON::decode_json($har->string());
ok($hash->{log}->{pages}->[0]->{pageTimings}->{_private} eq "value", "new _private value is correct (3)");
ok((($har->pages())[0])->page_timings()->_private() eq "value", "new _private value is correct (4)");
eval { (($har->pages())[0])->page_timings()->does_not_exist() };
ok($@ =~ /^does_not_exist is not specified in the HAR 1.2 spec and does not start with an underscore/, "does_not_exist access throws an exception");
eval { (($har->pages())[0])->page_timings()->on_content_load('sdf') };
ok($@ =~ /^on_content_load must be a positive number or -1/, "setting on_content_load to a non numeric throws an exception");
eval { (($har->pages())[0])->page_timings()->on_load('sdf') };
ok($@ =~ /^on_load must be a positive number or -1/, "setting on_load to a non numeric throws an exception");

no warnings;
eval "sub IO::Uncompress::Gunzip::gunzip { return; }";
use warnings;
my $plainData = "asdadsdsfsdF";
my $gzippedData ;
IO::Compress::Gzip::gzip(\$plainData, \$gzippedData);
ok(not(defined(IO::Uncompress::Gunzip::gunzip(\$gzippedData, \$plainData))), "Successfully redefined IO::Uncompress::Gunzip::gunzip");
eval { my $x = $har->gzip($gzippedData); print $x; };
ok($@ =~ /^Failed to gunzip/, "Gunzip failing throws an exception:$@");

no warnings;
eval "sub IO::Compress::Gzip::gzip { return; }";
use warnings;
ok(not(defined(IO::Compress::Gzip::gzip(\$plainData, \$gzippedData))), "Successfully redefined IO::Compress::Gzip::gzip");
eval { $har->gzip() };
ok($@ =~ /^Failed to gzip/, "Gzip failing throws an exception");

