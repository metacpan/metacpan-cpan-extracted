use Test::Most;
use Test::Lib;
use Test::DBIx::Class
  -schema_class => 'Schema::Nested';

{
  ok my ($resultset, @errs) = Schema
    ->resultset('OneOne')
    ->set_recursively([
      { value => 'test1', one => { value => 'hello1'} },
      { value => 'test2', one => { value => 'hello2'} },
      { value => 'a', one => { value => 'a'} },     
    ]), 'created fixture';

  is_deeply $resultset->_dump_resultset, {
    one_one => [
      {
        data => {
          id => 1,
          one => {
            data => {
              one_id => 1,
              value => "hello1",
            },
            errors => {},
          },
          value => "test1",
        },
        errors => {},
      },
      {
        data => {
          id => 2,
          one => {
            data => {
              one_id => 2,
              value => "hello2",
            },
            errors => {},
          },
          value => "test2",
        },
        errors => {},
      },
      {
        data => {
          id => undef,
          one => {
            data => {
              value => "a",
            },
            errors => {
              value => [
                "Value is too short (minimum is 2 characters)",
              ],
            },
          },
          value => "a",
        },
        errors => {
          one => [
            "One Is Invalid",
          ],
          value => [
            "Value is too short (minimum is 3 characters)",
          ],
        },
      },
    ],
  }, 'dumped resultset';

  is scalar @errs, 1;
  is $errs[0]->errors->count, 3, 'no errors';
  is_deeply [$errs[0]->errors->full_messages], [
    "Value is too short (minimum is 3 characters)",
    "One Is Invalid",
    "One Value is too short (minimum is 2 characters)",
  ], 'errors';

}

{
  ok my ($resultset, @errs) = Schema
    ->resultset('OneOne')
    ->set_recursively([
      { value => 'test1', one => { value => 'hello1'} },
      { value => 'test2', one => { value => 'hello2'} },
      { value => 'a', one => { value => 'a'} },     
    ], {rollback_on_invalid=>1}), 'created fixture';


  #use Devel::Dwarn;
 #Dwarn $resultset->_dump_resultset;

  is_deeply $resultset->_dump_resultset, {
    one_one => [
      {
        data => {
          id => undef,
          one => {
            data => {
              value => "hello1",
            },
            errors => {},
          },
          value => "test1",
        },
        errors => {
          value => [
            "Value chosen is not unique",
          ],
        },
      },
      {
        data => {
          id => undef,
          one => {
            data => {
              value => "hello2",
            },
            errors => {},
          },
          value => "test2",
        },
        errors => {
          value => [
            "Value chosen is not unique",
          ],
        },
      },
      {
        data => {
          id => undef,
          one => {
            data => {
              value => "a",
            },
            errors => {
              value => [
                "Value is too short (minimum is 2 characters)",
              ],
            },
          },
          value => "a",
        },
        errors => {
          one => [
            "One Is Invalid",
          ],
          value => [
            "Value is too short (minimum is 3 characters)",
          ],
        },
      },
    ],
  }, 'dumped resultset';

}


done_testing;
