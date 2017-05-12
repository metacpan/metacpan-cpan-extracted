package MockLWP;

use LWP::UserAgent 5.834 qw ();
use JSON 2.17 qw ();
use HTTP::Response 5.824 qw ();

my $ua = LWP::UserAgent->new();

my $json = JSON->new();

my $text;
{
    local $/ = undef;
    $text = <DATA>;
}

my $data = $json->decode($text);

sub request {
    my ($self, $request) = @_;

    if ($ENV{CATALYST_COUCHDB_LIVE}) {
        return $ua->request($request);
    }

    if (exists $data->{ $request->uri->as_string}) {
        my $response_data = $data->{ $request->uri->as_string};
        my $response = HTTP::Response->new(
            $response_data->{code},
            $response_data->{message},
            $response_data->{headers},
            $response_data->{content},
        );
        $response->request($request);
        return $response;
    }
    return HTTP::Response->new(404);
}

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}


1;

__DATA__
{
   "http://localhost:5984/demouser/_design/user/_view/user?include_docs=true&limit=1&key=%22test%22" : {
      "headers" : [
         "ETag: \"ZIVZNIP4GVXNG09IBXVVGID9\"",
         "Server: CouchDB/1.1.0a1039022 (Erlang OTP/R14B02)",
         "Content-Type: text/plain;charset=utf-8"
      ],
      "content" : "{\"total_rows\":2,\"offset\":0,\"rows\":[\r\n{\"id\":\"d385a5a43716f56edcf1cc2f87000f86\",\"key\":\"test\",\"value\":null,\"doc\":{\"_id\":\"d385a5a43716f56edcf1cc2f87000f86\",\"_rev\":\"7-a9f04468e37fca84d2fde6894c5f8abc\",\"username\":\"test\",\"password\":\"test\",\"fullname\":\"Test User\",\"roles\":[\"admin\",\"user\"],\"_attachments\":{\"test.pl\":{\"content_type\":\"application/octet-stream\",\"revpos\":5,\"length\":214,\"stub\":true}}}}\r\n]}\n",
      "message" : "OK",
      "code" : "200"
   },
   "http://localhost:5984/demouser/_design%2Fuser" : {
      "headers" : [
         "ETag: \"1-d0d72dd3e71f0f0eb40ad37efe1ba388\"",
         "Server: CouchDB/1.1.0a1039022 (Erlang OTP/R14B02)",
         "Content-Length: 191",
         "Content-Type: text/plain;charset=utf-8"
      ],
      "content" : "{\"_id\":\"_design/user\",\"_rev\":\"1-d0d72dd3e71f0f0eb40ad37efe1ba388\",\"language\":\"javascript\",\"views\":{\"user\":{\"map\":\"function(doc) {\\n  if (doc.username) {\\n  emit(doc.username, null)\\n}\\n}\"}}}\n",
      "message" : "OK",
      "code" : "200"
   },
   "http://localhost:5984/demouser/_design/user/_view/user?include_docs=true&limit=1&key=%22testmissing%22" : {
      "headers" : [
         "Server: CouchDB/1.1.0a1039022 (Erlang OTP/R14B02)",
         "Content-Length: 38",
         "Content-Type: text/plain;charset=utf-8"
      ],
      "content" : "{\"total_rows\":2,\"offset\":2,\"rows\":[]}\n",
      "message" : "OK",
      "code" : "200"
   },
   "http://localhost:5984/demouser/_design/user/_view/user?include_docs=true&limit=1&key=%22test2%22" : {
      "headers" : [
         "ETag: \"ZIVZNIP4GVXNG09IBXVVGID9\"",
         "Server: CouchDB/1.1.0a1039022 (Erlang OTP/R14B02)",
         "Content-Type: text/plain;charset=utf-8"
      ],
      "content" : "{\"total_rows\":2,\"offset\":1,\"rows\":[\r\n{\"id\":\"d385a5a43716f56edcf1cc2f87001aeb\",\"key\":\"test2\",\"value\":null,\"doc\":{\"_id\":\"d385a5a43716f56edcf1cc2f87001aeb\",\"_rev\":\"2-e9db7c1eddc31c49591a59f4739751d2\",\"username\":\"test2\",\"password\":\"test2\",\"fullname\":\"Test User 2\",\"roles\":[\"user\"]}}\r\n]}\n",
      "message" : "OK",
      "code" : "200"
   },
   "http://localhost:5984/" : {
      "headers" : [
         "Server: CouchDB/1.1.0a1039022 (Erlang OTP/R14B02)",
         "Content-Length: 48",
         "Content-Type: text/plain;charset=utf-8"
      ],
      "content" : "{\"couchdb\":\"Welcome\",\"version\":\"1.1.0a1039022\"}",
      "code" : "200",
      "message" : "OK"
   },
   "http://localhost:5984/demouser/_design/user/_view/user?include_docs=true&limit=1&key=%22foo%22" : {
      "headers" : [
         "Server: CouchDB/1.1.0a1039022 (Erlang OTP/R14B02)",
         "Content-Length: 38",
         "Content-Type: text/plain;charset=utf-8"
      ],
      "content" : "{\"total_rows\":2,\"offset\":0,\"rows\":[]}\n",
      "message" : "OK",
      "code" : "200"
   }
}
