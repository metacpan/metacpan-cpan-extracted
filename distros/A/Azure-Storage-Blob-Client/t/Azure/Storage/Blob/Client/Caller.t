#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Test::Spec::Acceptance;
use Test::Exception;
use HTTP::Headers;
use HTTP::Response;
use Azure::Storage::Blob::Client::Call::GetBlobProperties;
use Azure::Storage::Blob::Client::Caller;

Feature 'Azure Storage Account API Exceptions handling' => sub {
  my ($caller, $error, $ua_mock, $signer_mock);
  my $account_name = 'myaccount';
  my $account_key = 'supersecret';
  my $api_version = '2018-03-28';

  before each => sub {
    $ua_mock = mock();
    $signer_mock = stub(
      isa => 'Azure::Storage::Blob::Client::Service::Signer',
      calculate_signature => 'myrequestsignature=',
    );

    $caller = Azure::Storage::Blob::Client::Caller->new(
      user_agent => $ua_mock,
      signer => $signer_mock,
    );
  };

  Scenario 'AuthenticationFailed' => sub {
    my $call_object;

    Given 'a GetBlobProperties call object' => sub {
      $call_object = Azure::Storage::Blob::Client::Call::GetBlobProperties->new(
        container => 'mycontainer',
        account_name => $account_name,
        account_key => $account_key,
        api_version => $api_version,
        blob_name => 'myblob',
      );
    };

    When 'the caller receives an InvalidAuthenticationInfo error from the API' => sub {
      $signer_mock
        ->expects('calculate_signature');
      $ua_mock
        ->expects('request')
        ->returns(HTTP::Response->new(
            403,
            'Server failed to authenticate the request. Make sure the value '.
            'of the Authorization header is formed correctly including the signature.',
            HTTP::Headers->new('x-ms-error-code' => 'AuthenticationFailed'),
          )
        );
      trap { $caller->request($account_name, $account_key, $call_object) };
      $error = $trap->die;
    };

    Then 'it should throw an AuthenticationFailed exception' => sub {
      like($error->code, qr/AuthenticationFailed/);
    };
  };

  Scenario 'InvalidAuthenticationInfo' => sub {
    my $call_object;

    Given 'a GetBlobProperties call object' => sub {
      $call_object = Azure::Storage::Blob::Client::Call::GetBlobProperties->new(
        container => 'mycontainer',
        account_name => $account_name,
        account_key => $account_key,
        api_version => $api_version,
        blob_name => 'myblob',
      );
    };

    When 'the caller receives an InvalidAuthenticationInfo error from the API' => sub {
      $signer_mock
        ->expects('calculate_signature');
      $ua_mock
        ->expects('request')
        ->returns(HTTP::Response->new(
            400,
            'Authentication information is not given in the correct format. '.
            'Check the value of Authorization header.',
            HTTP::Headers->new('x-ms-error-code' => 'InvalidAuthenticationInfo'),
          )
        );
      trap { $caller->request($account_name, $account_key, $call_object) };
      $error = $trap->die;
    };

    Then 'it should throw an InvalidAuthenticationInfo exception' => sub {
      like($error->code, qr/InvalidAuthenticationInfo/);
    };
  };

  Scenario 'BlobAlreadyExists' => sub {
    my $call_object;

    Given 'a GetBlobProperties call object' => sub {
      $call_object = Azure::Storage::Blob::Client::Call::GetBlobProperties->new(
        container => 'mycontainer',
        account_name => $account_name,
        api_version => $api_version,
        account_key => $account_key,
        blob_name => 'myblob',
      );
    };

    When 'the caller receives a BlobAlreadyExists error from the API' => sub {
      $signer_mock
        ->expects('calculate_signature');
      $ua_mock
        ->expects('request')
        ->returns(HTTP::Response->new(
            409,
            'The specified blob already exists.',
            HTTP::Headers->new('x-ms-error-code' => 'BlobAlreadyExists'),
          )
        );
      trap { $caller->request($account_name, $account_key, $call_object) };
      $error = $trap->die;
    };

    Then 'it should throw a BlobAlreadyExists exception' => sub {
      like($error->code, qr/BlobAlreadyExists/);
    };
  };

  Scenario 'BlobNotFound' => sub {
    my $call_object;

    Given 'a GetBlobProperties call object' => sub {
      $call_object = Azure::Storage::Blob::Client::Call::GetBlobProperties->new(
        container => 'mycontainer',
        account_name => $account_name,
        account_key => $account_key,
        api_version => $api_version,
        blob_name => 'myblob',
      );
    };

    When 'the caller receives a BlobNotFound error from the API' => sub {
      $signer_mock
        ->expects('calculate_signature');
      $ua_mock
        ->expects('request')
        ->returns(HTTP::Response->new(
            404,
            'The specified blob does not exist.',
            HTTP::Headers->new('x-ms-error-code' => 'BlobNotFound'),
          )
        );
      trap { $caller->request($account_name, $account_key, $call_object) };
      $error = $trap->die;
    };

    Then 'it should throw a BlobNotFound exception' => sub {
      like($error->code, qr/BlobNotFound/);
    };
  };

  Scenario 'ContainerNotFound' => sub {
    my $call_object;

    Given 'a GetBlobProperties call object' => sub {
      $call_object = Azure::Storage::Blob::Client::Call::GetBlobProperties->new(
        container => 'mycontainer',
        account_name => $account_name,
        account_key => $account_key,
        api_version => $api_version,
        blob_name => 'myblob',
      );
    };

    When 'the caller receives a ContainerNotFound error from the API' => sub {
      $signer_mock
        ->expects('calculate_signature');
      $ua_mock
        ->expects('request')
        ->returns(HTTP::Response->new(
            404,
            'The specified container does not exist.',
            HTTP::Headers->new('x-ms-error-code' => 'ContainerNotFound'),
          )
        );
      trap { $caller->request($account_name, $account_key, $call_object) };
      $error = $trap->die;
    };

    Then 'it should throw a ContainerNotFound exception' => sub {
      like($error->code, qr/ContainerNotFound/);
    };
  };

  Scenario 'InvalidBlobType' => sub {
    my $call_object;

    Given 'a GetBlobProperties call object' => sub {
      $call_object = Azure::Storage::Blob::Client::Call::GetBlobProperties->new(
        container => 'mycontainer',
        account_name => $account_name,
        account_key => $account_key,
        api_version => $api_version,
        blob_name => 'myblob',
      );
    };

    When 'the caller receives a InvalidBlobType error from the API' => sub {
      $signer_mock
        ->expects('calculate_signature');
      $ua_mock
        ->expects('request')
        ->returns(HTTP::Response->new(
            404,
            'The specified container does not exist.',
            HTTP::Headers->new('x-ms-error-code' => 'InvalidBlobType'),
          )
        );
      trap { $caller->request($account_name, $account_key, $call_object) };
      $error = $trap->die;
    };

    Then 'it should throw a InvalidBlobType exception' => sub {
      like($error->code, qr/InvalidBlobType/);
    };
  };

  Scenario 'UnknownAzureStorageAPIError' => sub {
    my $call_object;

    Given 'a GetBlobProperties call object' => sub {
      $call_object = Azure::Storage::Blob::Client::Call::GetBlobProperties->new(
        container => 'mycontainer',
        account_name => $account_name,
        account_key => $account_key,
        api_version => $api_version,
        blob_name => 'myblob',
      );
    };

    When 'the caller receives an unknown error from the Azure Storage API' => sub {
      $signer_mock
        ->expects('calculate_signature');
      $ua_mock
        ->expects('request')
        ->returns(HTTP::Response->new(
            404,
            'The specified blob does not exist.',
            HTTP::Headers->new('x-ms-error-code' => undef),
          )
        );
      trap { $caller->request($account_name, $account_key, $call_object) };
      $error = $trap->die;
    };

    Then 'it should throw an UknownAzureStorageAPIError exception' => sub {
      like($error->code, qr/UnknownAzureStorageAPIError/);
    };
  };
};

runtests unless caller;
