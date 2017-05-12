#!/usr/bin/perl -w
# finally, my first test script!
package Fake::Request;

use Test::Simple tests=>4;
use CGI::URI2param qw(uri2param);

# make fake object
my $r=bless {},Fake::Request;

# prepare regexes
my $regex={
	   style=>'style_(plain|fancy)',
	   id=>'id(\d+)',
};

# tests!
ok ($r->can('param'),'   create fake test object');
ok (uri2param($r,$regex),'   apply regexes');
ok ($r->param('style') eq "plain",'   param style');
ok ($r->param('id') eq "1234",'   param id');

sub param {
   my ($self,$key,$val)=@_;
   $val ? 
      return $self->{$key}=$val :
	 return $self->{$key};
}

sub url {
   return "/somewhere/style_plain/";
}

sub path_info {
   return "id1234.html";
}


