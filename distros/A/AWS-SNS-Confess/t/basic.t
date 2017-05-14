#!/usr/bin/perl -w

package Amazon::SNS::Topic::Mock;
use base 'Amazon::SNS::Topic';

our @log = ();

sub new
{
  my ($class, %args ) = @_;
  return bless \%args, $class;
}

sub Publish
{
  my ($s, $msg) = @_;
  push @log, $msg;
}

sub LastLogEntry
{
  return $log[-1];
}

1;

package Amazon::SNS::Mock;
use base 'Amazon::SNS';
our $topic = Amazon::SNS::Topic::Mock->new();

sub GetTopic
{
  return $topic;
}
1;


package main;
use strict;
use warnings 'all';
no warnings 'once';
use Test::More 'no_plan';
use Test::Exception;
use Data::Dumper;
use FindBin qw/ $Bin /;
use lib "../lib";

BEGIN {
  use_ok('AWS::SNS::Confess', qw/confess/);
}

can_ok('AWS::SNS::Confess', "setup");
my $topic_name = "arn:aws:sns:region:1234:topic";
my $sns = Amazon::SNS::Mock->new(); 
AWS::SNS::Confess::setup(
  access_key_id => "key",
  secret_access_key => "secret",
  topic => $topic_name,
  sns => $sns,  # This is specified just for testing
);
is AWS::SNS::Confess::_service_url(), "http://sns.region.amazonaws.com";

is $AWS::SNS::Confess::access_key_id, "key", "correctly set access key";
is $AWS::SNS::Confess::secret_access_key, "secret", "correctly set secret";
is $AWS::SNS::Confess::topic, $topic_name, "correctly set topic";


SEND_TO_SNS: {
  AWS::SNS::Confess::_send_msg("Hello");
  is $sns->GetTopic($topic_name)->LastLogEntry(), "Hello";
}

CONFESSS: {
  can_ok('main', 'confess');
  dies_ok { confess("something went wrong") } "confess correctly dies";
  my $last_msg =  $sns->GetTopic($topic_name)->LastLogEntry();
  like $last_msg, qr/something went wrong/, "sns msg contains error passed in";
  like $last_msg, qr/Trace begun/, "sns msg contains stack trace";
}



