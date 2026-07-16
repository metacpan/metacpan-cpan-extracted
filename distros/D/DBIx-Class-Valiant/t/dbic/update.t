use Test::Most;
use Test::Lib;
use Test::DBIx::Class
  -schema_class => 'Schema::Create';

ok my $person = Schema
  ->resultset('Person')
  ->create({
    username => '  jjn   ',
    first_name => 'john',
    last_name => 'napiorkowski',
    password => 'hellohello',
    password_confirmation => 'hellohello',
  }), 'created fixture';

ok $person->valid;

# Ok so tricky.   calling ->update on a resultset doesn't do any validations
# since that's intended to be a shortcut to update lots of stuff so if you are
# doing that we assume you know what you are doing.  But ->update_all does actually
# inflate objects so we can check.   BUT you need to set the cache attribute if you
# want to see the valid/invalid states of what you used update_all on.  That's because
# ->all doesn't set cache unless the cache attribute is true. I'm not
# sure I want to mess with that but it needs good docs for people doing ->update_all
# and all that.
{
  my $person_rs = Schema
    ->resultset('Person')
    ->search({},{cache=>1});

  $person_rs->update_all({first_name=>'a'});

  ok my $first = $person_rs->next; # remember that ->all resets the cache

  is $first->first_name, 'a'; # make sure we got the cached version 
  ok $first->invalid;
  ok $first->is_changed;
}

{
  ok my $profile = $person->create_related('profile', +{
    address => '123 Hello Street',
    city => "Smalltown",
    zip => '78621',
    birthday => '2000-01-01',
  });

  ok $person->valid;
  ok ref($profile->birthday), 'DateTime';
  ok ref($person->profile->birthday), 'DateTime';
}



done_testing;
