#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Test::Spec::Acceptance;
use Azure::Storage::Blob::Client::Call;

Feature 'serialize_uri_parameters' => sub {
  my ($call, $serialized_parameters);

  Scenario 'call class without parameter attributes' => sub {
    Given 'an object with no paramater attributes' => sub {
      $call = Azure::Storage::Blob::Client::Test::CallClassWithNoParameters->new(
        att1 => 1,
        att2 => 2,
        att3 => 3,
      );
    };

    When 'calling \'serialize_uri_parameters\' on it' => sub {
      $serialized_parameters = $call->serialize_uri_parameters();
    };

    Then 'it should return an empty hash' => sub {
      is_deeply($serialized_parameters, {});
    };
  };

  Scenario 'call class with URIParameter attributes' => sub {
    Given 'an object with URIParamater attributes' => sub {
      $call = Azure::Storage::Blob::Client::Test::CallClassWithURIParameters->new(
        att1 => 1,
        att2 => 2,
        att3 => 3,
      );
    };

    When 'calling \'serialize_uri_parameters\' on it' => sub {
      $serialized_parameters = $call->serialize_uri_parameters();
    };

    Then 'it should return the keys/values of URIParameter attributes' => sub {
      is_deeply($serialized_parameters, {
          att2 => 2,
          att3 => 3,
      });
    };
  };

  Scenario 'call class with all types of parameter attributes' => sub {
    Given 'an object with URIParamater, HeaderParameter & BodyParameter attributes' => sub {
      $call = Azure::Storage::Blob::Client::Test::CallClassWithAllParameters->new(
        att1 => 1,
        att2 => 2,
        att3 => 3,
        att4 => 4,
        att5 => 5,
      );
    };

    When 'calling \'serialize_uri_parameters\' on it' => sub {
      $serialized_parameters = $call->serialize_uri_parameters();
    };

    Then 'it should return the keys/values of URIParameter attributes' => sub {
      is_deeply($serialized_parameters, {
          att1 => 1,
          att4 => 4,
      });
    };
  };
};

Feature 'serialize_header_parameters' => sub {
  my ($call, $serialized_parameters);

  Scenario 'call class without parameter attributes' => sub {
    Given 'an object with no paramater attributes' => sub {
      $call = Azure::Storage::Blob::Client::Test::CallClassWithNoParameters->new(
        att1 => 1,
        att2 => 2,
        att3 => 3,
      );
    };

    When 'calling \'serialize_header_parameters\' on it' => sub {
      $serialized_parameters = $call->serialize_header_parameters();
    };

    Then 'it should return an empty hash' => sub {
      is_deeply($serialized_parameters, {});
    };
  };

  Scenario 'call class with HeaderParameter attributes' => sub {
    Given 'an object with HeaderParameter attributes' => sub {
      $call = Azure::Storage::Blob::Client::Test::CallClassWithHeaderParameters->new(
        att1 => 1,
        att2 => 2,
        att3 => 3,
      );
    };

    When 'calling \'serialize_header_parameters\' on it' => sub {
      $serialized_parameters = $call->serialize_header_parameters();
    };

    Then 'it should return the keys/values of HeaderParameter attributes' => sub {
      is_deeply($serialized_parameters, {
          h2 => 2,
          h3 => 3,
      });
    };
  };

  Scenario 'call class with all types of parameter attributes' => sub {
    Given 'an object with URIParamater, HeaderParameter & BodyParameter attributes' => sub {
      $call = Azure::Storage::Blob::Client::Test::CallClassWithAllParameters->new(
        att1 => 1,
        att2 => 2,
        att3 => 3,
        att4 => 4,
        att5 => 5,
      );
    };

    When 'calling \'serialize_header_parameters\' on it' => sub {
      $serialized_parameters = $call->serialize_header_parameters();
    };

    Then 'it should return the keys/values of HeaderParameter attributes' => sub {
      is_deeply($serialized_parameters, {
          h2 => 2,
          h4 => 4,
      });
    };
  };
};

Feature 'serialize_body_parameters' => sub {
  my ($call, $serialized_parameters);

  Scenario 'call class without parameter attributes' => sub {
    Given 'an object with no paramater attributes' => sub {
      $call = Azure::Storage::Blob::Client::Test::CallClassWithNoParameters->new(
        att1 => 1,
        att2 => 2,
        att3 => 3,
      );
    };

    When 'calling \'serialize_body_parameters\' on it' => sub {
      $serialized_parameters = $call->serialize_body_parameters();
    };

    Then 'it should return an empty hash' => sub {
      is_deeply($serialized_parameters, {});
    };
  };

  Scenario 'call class with BodyParameter attributes' => sub {
    Given 'an object with BodyParameter attributes' => sub {
      $call = Azure::Storage::Blob::Client::Test::CallClassWithBodyParameters->new(
        att1 => 1,
        att2 => 2,
        att3 => 3,
      );
    };

    When 'calling \'serialize_body_parameters\' on it' => sub {
      $serialized_parameters = $call->serialize_body_parameters();
    };

    Then 'it should return the keys/values of BodyParameter attributes' => sub {
      is_deeply($serialized_parameters, {
          att2 => 2,
          att3 => 3,
      });
    };
  };

  Scenario 'call class with all types of parameter attributes' => sub {
    Given 'an object with URIParamater, BodyParameter & BodyParameter attributes' => sub {
      $call = Azure::Storage::Blob::Client::Test::CallClassWithAllParameters->new(
        att1 => 1,
        att2 => 2,
        att3 => 3,
        att4 => 4,
        att5 => 5,
      );
    };

    When 'calling \'serialize_body_parameters\' on it' => sub {
      $serialized_parameters = $call->serialize_body_parameters();
    };

    Then 'it should return the keys/values of BodyParameter attributes' => sub {
      is_deeply($serialized_parameters, {
          att3 => 3,
          att4 => 4,
      });
    };
  };
};

package Azure::Storage::Blob::Client::Test::CallClassWithNoParameters {
  use Moose;
  with 'Azure::Storage::Blob::Client::Call';

  has att1 => (is => 'ro', isa => 'Any', required => 1);
  has att2 => (is => 'ro', isa => 'Any', required => 1);
  has att3 => (is => 'ro', isa => 'Any', required => 1);

  # required by Call role
  sub operation {}
  sub method {}
  sub endpoint {}
};

package Azure::Storage::Blob::Client::Test::CallClassWithURIParameters {
  use Moose;
  use Azure::Storage::Blob::Client::Meta::Attribute::Custom::Trait::URIParameter;
  with 'Azure::Storage::Blob::Client::Call';

  has att1 => (is => 'ro', isa => 'Any', required => 1);
  has att2 => (is => 'ro', isa => 'Any', traits => ['URIParameter'], required => 1);
  has att3 => (is => 'ro', isa => 'Any', traits => ['URIParameter'], required => 1);

  # required by Call role
  sub operation {}
  sub method {}
  sub endpoint {}
};

package Azure::Storage::Blob::Client::Test::CallClassWithHeaderParameters {
  use Moose;
  use Azure::Storage::Blob::Client::Meta::Attribute::Custom::Trait::HeaderParameter;
  with 'Azure::Storage::Blob::Client::Call';

  has att1 => (is => 'ro', isa => 'Any', required => 1);
  has att2 => (is => 'ro', isa => 'Any', traits => ['HeaderParameter'], header_name => 'h2', required => 1);
  has att3 => (is => 'ro', isa => 'Any', traits => ['HeaderParameter'], header_name => 'h3', required => 1);

  # required by Call role
  sub operation {}
  sub method {}
  sub endpoint {}
};

package Azure::Storage::Blob::Client::Test::CallClassWithBodyParameters {
  use Moose;
  use Azure::Storage::Blob::Client::Meta::Attribute::Custom::Trait::BodyParameter;
  with 'Azure::Storage::Blob::Client::Call';

  has att1 => (is => 'ro', isa => 'Any', required => 1);
  has att2 => (is => 'ro', isa => 'Any', traits => ['BodyParameter'], required => 1);
  has att3 => (is => 'ro', isa => 'Any', traits => ['BodyParameter'], required => 1);

  # required by Call role
  sub operation {}
  sub method {}
  sub endpoint {}
};

package Azure::Storage::Blob::Client::Test::CallClassWithAllParameters {
  use Moose;
  use Azure::Storage::Blob::Client::Meta::Attribute::Custom::Trait::URIParameter;
  use Azure::Storage::Blob::Client::Meta::Attribute::Custom::Trait::HeaderParameter;
  use Azure::Storage::Blob::Client::Meta::Attribute::Custom::Trait::BodyParameter;
  with 'Azure::Storage::Blob::Client::Call';

  has att1 => (is => 'ro', traits => ['URIParameter'], required => 1);
  has att2 => (is => 'ro', traits => ['HeaderParameter'], header_name => 'h2', required => 1);
  has att3 => (is => 'ro', traits => ['BodyParameter'], required => 1);
  has att4 => (is => 'ro', traits => ['URIParameter', 'HeaderParameter', 'BodyParameter'], header_name => 'h4', required => 1);
  has att5 => (is => 'ro', required => 1);

  # required by Call role
  sub operation {}
  sub method {}
  sub endpoint {}
};

runtests unless caller;
