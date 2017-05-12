package Catmandu::MediaMosa;
use Catmandu::Sane;
use Carp qw(confess);
use Moo;
use LWP::UserAgent;
use Data::UUID;
use Data::Util qw(:check :validate);
use Digest::SHA1 qw(sha1_hex);
use Catmandu::MediaMosa::XPath::Helper qw(xpath);
use Catmandu::MediaMosa::Response;
use URI::Escape;

use all qw(
  Catmandu::MediaMosa::Items::*
  Catmandu::MediaMosa::Response::*
);

our $VERSION = "0.279";

#zie http://www.mediamosa.org/sites/default/files/Webservices-MediaMosa-1.5.3.pdf

has base_url => (
  is => 'ro',
  required => 1
);
has user => (
  is => 'ro',
  required => 1
);
has password => (
  is => 'ro',
  required => 1
);

sub _parse_header {
  my($self,$xpath) = @_;
  Catmandu::MediaMosa::Response::Header->parse_xpath($xpath);
}
sub _make_items {
  my($self,$items)=@_;
  Catmandu::MediaMosa::Response::Items->new(items => $items);
}
sub _make_response {
  my($self,$header,$items)=@_;
  Catmandu::MediaMosa::Response->new(header => $header,items => $items);
}
sub _ua {
  state $_ua = LWP::UserAgent->new(
    cookie_jar => {}
  );
}
sub _validate_web_response {
  my($self,$res) = @_;
  $res->is_error && confess($res->content."\n");
}
sub vp_request {
  my($self,@args) = @_;
  $self->login;
  $self->_vp_request(@args);
}
sub _vp_request {
  my($self,$path,$params,$method)=@_;
  $method ||= "GET";
  my $res;
  if(uc($method) eq "GET"){
    $res = $self->_get($path,$params);
  }elsif(uc($method) eq "POST"){
    $res = $self->_post($path,$params);
  }else{
    confess "method $method not supported";
  }
  $self->_validate_web_response($res);

  $res;
}
sub _construct_params_as_array {
  my($self,$params) = @_;
  my @array = ();
  for my $key(keys %$params){
    if(is_array_ref($params->{$key})){
      #PHP only recognizes 'arrays' when their keys are appended by '[]' (yuk!)
      for my $val(@{ $params->{$key} }){
        push @array,$key."[]" => $val;
      }
    }else{
      push @array,$key => $params->{$key};
    }
  }
  return \@array;
}
sub _post {
  my($self,$path,$data)=@_;
  $self->_ua->post($self->base_url.$path,$self->_construct_params_as_array($data));
}
sub _construct_query {
  my($self,$data) = @_;
  my @parts = ();
  for my $key(keys %$data){
    if(is_array_ref($data->{$key})){
      for my $val(@{ $data->{$key} }){
        push @parts,URI::Escape::uri_escape($key)."[]=".URI::Escape::uri_escape($val);
      }
    }else{
      push @parts,URI::Escape::uri_escape($key)."=".URI::Escape::uri_escape($data->{$key});
    }
  }
  join("&",@parts);
}
sub _get {
  my($self,$path,$data)=@_;
  my $query = $self->_construct_query($data) || "";
  $self->_ua->get($self->base_url.$path."?$query");
}
sub _authenticate {
  my $self = shift;
  #dbus communication

  #client: EGA stuurt "AUTH DBUS_COOKIE_SHA1 <username>" naar VP-Core
  my($challenge_server,$random);
  {
    my $res = $self->_vp_request("/login",{
      dbus => "AUTH DBUS_COOKIE_SHA1 ".$self->user
    },"POST");
  
    my $items = Catmandu::MediaMosa::Items::login->parse($res->content_ref);

    #server: "DATA vpx 0 <challenge-server>"
    my $dbus = $items->[0]->{dbus};

    if($dbus !~ /^DATA vpx 0 ([a-f0-9]{32})$/o){
      confess("invalid dbus response from server: $dbus\n");
    }
    $challenge_server = $1;
  }

  #client: EGA verzint willekeurige tekst <random> 
  #   en berekent response string: 
  #   <response> = sha1(<challenge-server>:<random>:<password>)
  $random = Data::UUID->new->create_str;

  #client: EGA stuurt "DATA <random> <response>" naar VP-Core
  my $success = "";
  {

    my $response_string = sha1_hex("$challenge_server:$random:".$self->password);
    my $res = $self->_vp_request("/login",{
      dbus => "DATA $random $response_string"
    },"POST");

    my $items = Catmandu::MediaMosa::Items::login->parse($res->content_ref);

    my $dbus =  $items->[0]->{dbus};  
    #server: OK|REJECTED vpx
    if($dbus !~ /^(OK|REJECTED) (\w+)$/o){
      confess("invalid dbus response from server: $dbus\n");
    }
    $success = $1;
  }

  #ok?
  return $success eq "OK";
}
sub login {
  my $self = shift;
  state $logged_in = 0;
  $logged_in ||= $self->_authenticate();
}

#assets
#
#<items>
#  <item id="1">
#    <asset_id>q1WmtebDr9F8eberUIjKrhTa</asset_id>
#  </item>
#</items>
sub asset_create {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/asset/create",$params,"POST");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
#asset_delete: rest api does not return response
sub asset_delete {
  my($self,$params) = @_;
  $params ||= {};
  $self->vp_request("/asset/$params->{asset_id}/delete",$params,"POST");
}
sub asset_list {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/asset",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::asset_list->parse_xpath($xpath))
  );
}
sub asset {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/asset/$params->{asset_id}",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::asset->parse_xpath($xpath))
  );

}
#asset_update: rest api does not return response
sub asset_update {
  my($self,$params) = @_;
  $params ||= {};
  $self->vp_request("/asset/$params->{asset_id}",$params,"POST");
}
sub asset_play {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/asset/$params->{asset_id}/play",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}

#asset_stills
sub asset_stills {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/asset/$params->{asset_id}/still",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
#asset_still_create: creates jobs
#
#<items>
#  <item id="1">
#    <job_id>15839</job_id>
#  </item>
#</items>
sub asset_still_create {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/asset/$params->{asset_id}/still/create",$params,"POST");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub asset_job_list {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/asset/$params->{asset_id}/joblist",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );

}
sub asset_collection_list {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/asset/$params->{asset_id}/collection",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
#asset_metadata_update: returns posted metadata
#
#<items>
#  <item id="1">
#    <description>test description</description>
#  </item>
#</items>
sub asset_metadata_update {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/asset/$params->{asset_id}/metadata",$params,"POST");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath))
  );
}
sub asset_mediafile_list {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/asset/$params->{asset_id}/mediafile",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::mediafile->parse_xpath($xpath))
  );
}

#jobs
sub job_status {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/job/$params->{job_id}/status",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub job_delete {
  my($self,$params) = @_;
  $params ||= {};
  $self->vp_request("/job/$params->{job_id}/delete",$params,"POST");
}
sub job_failures {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/job/failures",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
#collections
sub collection_list {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/collection",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub collection {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/collection/$params->{coll_id}",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub collection_asset_list {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/collection/$params->{coll_id}/asset",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::asset_list->parse_xpath($xpath))
  );
}
#<items>
#  <item id="1">
#    <coll_id>3</coll_id>
#  </item>
#</items>
sub collection_create {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/collection/create",$params,"POST");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}

##trancode
sub transcode_profile_list {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/transcode/profile",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub transcode_profile {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/transcode/profile/$params->{profile_id}",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
#transcode_profile_update:
#
#<items>
#  <item id="1">
#    <profile_id>1</profile_id>
#  </item>
#</items>
sub transcode_profile_update {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/transcode/profile/$params->{profile_id}",$params,"POST");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
#transcode_profile_create
#
#<items>
#  <item id="1">
#    <profile_id>11</profile_id>
#  </item>
#</items>
sub transcode_profile_create {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/transcode/profile/create",$params,"POST");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
#transcode_profile_delete: rest api does not return response
sub transcode_profile_delete {
  my($self,$params) = @_;
  $params ||= {};
  $self->vp_request("/transcode/profile/$params->{profile_id}/delete",$params,"POST");
}
#mediafile_create:
#
#<items>
#  <item id="1">
#    <mediafile_id>ERTpgSptYbqvUaYUJGrryyML</mediafile_id>
#  </item>
#</items>
sub mediafile_create {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/mediafile/create",$params,"POST");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub mediafile {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/mediafile/$params->{mediafile_id}",$params,"POST");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::mediafile->parse_xpath($xpath))
  );
}
#media_update: rest api does not return response
sub mediafile_update {
  my($self,$params) = @_;
  $params ||= {};
  $self->vp_request("/mediafile/$params->{mediafile_id}",$params,"POST");
}
sub mediafile_upload_ticket_create {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/mediafile/$params->{mediafile_id}/uploadticket/create",$params,"POST");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
#user
sub user_list {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/user",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub user_detail {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/user/$params->{user_id}",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub user_job_list {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/user/$params->{owner_id}/joblist",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub error_code_list {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/errorcodes",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub error_code {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/errorcodes/$params->{code}",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub version {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/version",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub acl_app {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/acl/app",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub app_quota {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/app/quota",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::simple_list->parse_xpath($xpath,1))
  );
}
sub status {
  my($self,$params) = @_;
  $params ||= {};
  my $res = $self->vp_request("/status",$params,"GET");
  my $xpath = xpath($res->content_ref);
  $self->_make_response(
    $self->_parse_header($xpath),
    $self->_make_items(Catmandu::MediaMosa::Items::status->parse_xpath($xpath))
  );
}
=head1 NAME
    
MediaMosa - Low level Perl connector for the MediaMosa REST API

=head1 SYNOPSIS

    my $mm = Catmandu::MediaMosa->new( base_url => 'http://localhost/mediamosa' , user => "foo",password => "mysecret" );

    #login is handled automatically ;-), and only redone when the session cookie expires
    #$mm->login;
    
    #equivalent of /asset?offset=0&limit=100
    my $vpcore = $mm->asset_list({ offset => 0,limit => 1000});

    die($vpcore->header->request_result_description) if($vpcore->header->request_result eq "error");

    say "total found:".$vpcore->header->item_count_total;
    say "total fetched:".$vpcore->header->item_count;

    #the result list 'items' is iterable!
    $vpcore->items->each(sub{
        my $item = shift;
        say "asset_id:".$item->{asset_id};
    });

=head1 SEE ALSO

L<Catmandu>

=head1 AUTHOR

Nicolas Franck , C<< <nicolas.franck at ugent.be> >>
    
=cut

1;
