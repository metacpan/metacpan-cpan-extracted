use Test::Most;
use Test::Lib;
use DateTime;
use Test::DBIx::Class
  -schema_class => 'Schema::Create';

{
  # Basic tests with new_result.   You should be able to make a new result which
  # can be invalid but not yet have an errors list.

  ok my $person = Schema
    ->resultset('Person')
    ->new_result({
      username => '  jjn   ',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'hello',
    }), 'created fixture';

  ok !$person->has_errors;  # No errors because validation was not yet run.

  $person->insert; # try to put into the DB.  This should fail due to errors

  ok $person->has_errors;
  ok !$person->in_storage, 'record was not saved';
  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    password => [
      "Password is too short (minimum is 8 characters)",
    ],
    password_confirmation => [
      "Password Confirmation doesn't match 'Password'",
    ],
  }, 'Got expected errors';

  # Fix it

  $person->password("thisistotallylongenough");
  $person->password_confirmation("thisistotallylongenough");

  $person->insert;

  ok !$person->has_errors;
  ok $person->in_storage, 'record was saved';
  ok $person->valid;
}

done_testing;
