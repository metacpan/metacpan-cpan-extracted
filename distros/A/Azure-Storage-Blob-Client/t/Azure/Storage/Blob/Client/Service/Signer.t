#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Test::Spec::Acceptance;
use Test::MockTime 'set_fixed_time', 'restore_time';
use HTTP::Request;
use HTTP::Headers;
use HTTP::Date;
use Encode;
use Azure::Storage::Blob::Client::Service::Signer;

Feature 'calculate_signature' => sub {
  my ($request, $account_name, $account_key, $signature);
  my $now = '2019-05-06T08:23:01Z'; # Signature is time-dependent

  before all => sub { set_fixed_time($now) };
  after all => sub { restore_time() };

  Scenario 'HTTP request with no body content' => sub {
    # pre-calculated time-dependent signature
    my $expected_signature = 'mnEgYCZthLSJ0jEjTtY4u8t/Ae+lyJMVmA2RR0EU2mI=';

    Given 'an HTTP request with no body' => sub {
      my $headers = HTTP::Headers->new(
        'x-ms-version' => '2018-03-28',
        'Date'=> HTTP::Date::time2str(),
      );
      $request = HTTP::Request->new('GET', 'example.com', $headers);
    };

    And 'a Storage Account \'account_name\' & \'account_key\'' => sub {
      $account_name = 'enzimetestaccount';
      $account_key = 'supersecretstorageaccountkey==';
    };

    When 'calculating the request signature' => sub {
      my $signer = Azure::Storage::Blob::Client::Service::Signer->new();
      $signature = $signer->calculate_signature($request, $account_name, $account_key);
    };

    Then 'it should return the expected signature' => sub {
      cmp_ok($signature, 'eq', $expected_signature);
    };
  };

  Scenario 'HTTP request with body content' => sub {
    # pre-calculated time-dependent signature
    my $expected_signature = 'gyuJ97Kkk65kMFRNDXVDkbdxNLnheamLBgbikxpQJlc=';

    Given 'an HTTP request with body content' => sub {
      my $body = '42';
      my $headers = HTTP::Headers->new(
        'x-ms-version' => '2018-03-28',
        'Date'=> HTTP::Date::time2str(),
        'Content-Length' => length(Encode::encode_utf8($body)),
      );
      $request = HTTP::Request->new('POST', 'example.com', $headers, $body);
    };

    And 'a Storage Account \'account_name\' & \'account_key\'' => sub {
      $account_name = 'enzimetestaccount';
      $account_key = 'supersecretstorageaccountkey==';
    };

    When 'calculating the request signature' => sub {
      my $signer = Azure::Storage::Blob::Client::Service::Signer->new();
      $signature = $signer->calculate_signature($request, $account_name, $account_key);
    };

    Then 'it should return the expected signature' => sub {
      cmp_ok($signature, 'eq', $expected_signature);
    };
  };
};

runtests unless caller;
