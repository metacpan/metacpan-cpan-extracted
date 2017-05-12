use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;
use Dancer2::Core::Session;
use Hash::MultiValue;
use aliased 'Dancer2::Plugin::TemplateFlute::Form';

my ( $form, $log, @logs );

# fixtures

{

    package TestObjNoMethods;
    use Moo;
}
{

    package TestObjReadOnly;
    use Moo;
    sub read { }
}
{

    package TestObjWriteOnly;
    use Moo;
    sub write { }
}
{

    package TestObjReadAndWrite;
    use Moo;
    sub read  { }
    sub write { }
}

my $log_cb = sub {
    my $level = shift;
    my $message = join( '', @_ );
    push @logs, { $level => $message };
};

my $session = Dancer2::Core::Session->new( id => 1 );

subtest 'form attribute types and coercion' => sub {

    like exception { Form->new }, qr/Missing required arguments: session at/,
      "Form->new with no args dies";

    like exception { Form->new( session => 'string' ) },
      qr/string.+did not pass type constraint.+HasMethods/,
      "Form->new with string as session value dies";

    like exception { Form->new( session => TestObjNoMethods->new ) },
      qr/bless.+TestObjNoMethods.+did not pass type constraint.+HasMethods/,
      "Form->new with session TestObjNoMethods dies";

    like exception { Form->new( session => TestObjReadOnly->new ) },
      qr/bless.+TestObjReadOnly.+did not pass type constraint.+HasMethods/,
      "Form->new with session TestObjReadOnly dies";

    like exception { Form->new( session => TestObjWriteOnly->new ) },
      qr/bless.+TestObjWriteOnly.+did not pass type constraint.+HasMethods/,
      "Form->new with session TestObjWriteOnly dies";

    is exception { Form->new( session => TestObjReadAndWrite->new ) },
      undef,
      "Form->new with session TestObjReadAndWrite lives";

    is exception { Form->new( session => $session ) },
      undef,
      "Form->new with valid session lives";

    like exception { Form->new( session => $session, action => undef ) },
      qr/Undef did not pass type constraint "Defined"/,
      "Form->new with undef action dies";

    like exception { Form->new( session => $session, action => $session ) },
      qr/bless.+did not pass type constraint "Str"/,
      "Form->new with bad action dies";

    like exception { Form->new( session => $session, errors => 'qq' ) },
      qr/Unable to coerce to Hash::MultiValue/,
      "Form->new with scalar errors dies";

    is exception {
        $form = Form->new(
            session => $session,
            errors  => Hash::MultiValue->new( a => 1, b => 1, b => 2 )
          )
    }, undef, "Form->new with Hash::MultiValue errors lives";

    isa_ok $form->errors, "Hash::MultiValue", "errors";
    cmp_deeply $form->errors->mixed, { a => 1, b => [ 1, 2 ] },
      "errors are as expected";

    is exception {
        $form =
          Form->new( session => $session, errors => { a => 1, b => [ 1, 2 ] } )
    }, undef, "Form->new with hashref errors lives";

    isa_ok $form->errors, "Hash::MultiValue", "errors";
    cmp_deeply $form->errors->mixed, { a => 1, b => [ 1, 2 ] },
      "errors are as expected";

    like exception { Form->new( session => $session, fields => undef ) },
      qr/Undef did not pass type constraint "ArrayRef\[Str\]"/,
      "Form->new with undef fields dies";

    like exception { Form->new( session => $session, fields => [$session] ) },
      qr/bless.+did not pass type constraint "ArrayRef\[Str\]"/,
      "Form->new with bad fields dies";

    is exception { Form->new( session => $session, fields => [] ) },
      undef,
      "Form->new with empty arrayref fields lives";

    is
      exception { Form->new( session => $session, fields => [ 'one', 'two' ] ) }
    , undef, "Form->new with filled arrayref fields lives";

    like exception { Form->new( session => $session, log_cb => undef ) },
      qr/Undef did not pass type constraint "CodeRef"/,
      "Form->new with undef log_cb dies";

    like exception { Form->new( session => $session, log_cb => {} ) },
      qr/Reference \{\} did not pass type constraint "CodeRef"/,
      "Form->new with bad log_cb dies";

    is exception {
        Form->new( session => $session, log_cb => sub { } )
    }, undef, "Form->new with good log_cb lives";

    like exception { Form->new( session => $session, name => undef ) },
      qr/Undef did not pass type constraint "Str"/,
      "Form->new with undef name dies";

    like exception { Form->new( session => $session, name => {} ) },
      qr/Reference \{\} did not pass type constraint "Str"/,
      "Form->new with bad name dies";

    is exception { $form = Form->new( session => $session, name => 'new' ) },
      undef,
      "Form->new with good name lives";
    cmp_ok $form->name, 'eq', 'new', 'form name is "new"';

    like exception { Form->new( session => $session, pristine => undef ) },
      qr/Undef did not pass type constraint "Defined&Bool"/,
      "Form->new with undef pristine dies";

    like exception { Form->new( session => $session, pristine => 'string' ) },
      qr/Value "string" did not pass type constraint "Bool"/,
      "Form->new with bad pristine dies";

    is exception { Form->new( session => $session, pristine => 0 ) },
      undef,
      "Form->new with pristine => 0 lives";

    is exception { Form->new( session => $session, pristine => 1 ) },
      undef,
      "Form->new with pristine => 1 lives";

    like exception { Form->new( session => $session, valid => 'string' ) },
      qr/Value "string" did not pass type constraint "Bool"/,
      "Form->new with bad valid dies";

    is exception { Form->new( session => $session, valid => 0 ) },
      undef,
      "Form->new with valid => 0 lives";

    is exception { Form->new( session => $session, valid => 1 ) },
      undef,
      "Form->new with valid => 1 lives";

    is exception {
        $form = Form->new(
            session => $session,
            values  => Hash::MultiValue->new( a => 1, b => 1, b => 2 )
          )
    }, undef, "Form->new with Hash::MultiValue values lives";

    isa_ok $form->values, "Hash::MultiValue", "values";
    cmp_deeply $form->values->mixed, { a => 1, b => [ 1, 2 ] },
      "values are as expected";

    is exception {
        $form = Form->new(
            session => $session,
            values  => { a => 1, b => [ 1, 2 ] }
          )
    }, undef, "Form->new with hashref values lives";

    isa_ok $form->values, "Hash::MultiValue", "values";
    cmp_deeply $form->values->mixed, { a => 1, b => [ 1, 2 ] },
      "values are as expected";

    like exception { Form->new( session => $session, fields => undef ) },
      qr/Undef did not pass type constraint "ArrayRef\[Str\]"/,
      "Form->new with undef fields dies";

    like
      exception { Form->new( session => $session, fields => [$session] ) },
      qr/bless.+did not pass type constraint "ArrayRef\[Str\]"/,
      "Form->new with bad fields dies";
};

subtest 'empty form creation with add_error, set_error and reset' => sub {
    @logs = ();
    $session->delete('form');

    is
      exception { $form = Form->new( log_cb => $log_cb, session => $session ) },
      undef,
      "Form->new with valid session lives";

    ok !defined $session->read('form'), "No form data in the session";
    ok !@logs, "Nothing logged";

    ok !defined $form->action, "action is undef";
    cmp_ok ref( $form->errors ), 'eq', 'Hash::MultiValue',
      'errors is a Hash::MultiValue';
    cmp_ok scalar $form->errors->keys, '==', 0, 'errors is empty';
    cmp_ok ref( $form->fields ), 'eq', 'ARRAY', 'fields is an array reference';
    cmp_ok @{ $form->fields }, '==', 0, 'fields is empty';
    cmp_ok ref( $form->log_cb ), 'eq', 'CODE', 'log_cb is a code reference';
    cmp_ok $form->name, 'eq', 'main', 'form name is "main"';
    ok $form->pristine, "form is pristine";
    ok $session->can('read'),  'session->can read';
    ok $session->can('write'), 'session->can write';
    ok !defined $form->valid, "valid is undef";
    cmp_ok ref( $form->values ), 'eq', 'Hash::MultiValue',
      'values is a Hash::MultiValue';
    cmp_ok scalar $form->values->keys, '==', 0, 'values is empty';

    # add_error

    is exception { $form->add_error( foo => "bar" ) }, undef,
      'add_error foo => "bar" ';

    cmp_deeply $form->errors->mixed, { foo => "bar" }, "errors looks good";
    cmp_deeply $form->errors_hashed, [ { name => "foo", label => "bar" } ],
      "errors_hashed looks good";

    ok $form->pristine, "form is pristine";
    cmp_ok $form->valid, '==', 0, "valid is 0";

    cmp_deeply \@logs,
      superbagof( { debug => 'Setting valid for form main to 0.' } ),
      'got "valid is 0" debug log entry';
    @logs = ();

    cmp_deeply $session->read('form'),
      {
        main => {
            action => undef,
            errors => { foo => "bar" },
            fields => [],
            name   => "main",
            valid  => 0,
            values => {},
        },
      },
      "form in session looks good";

    # set_error

    is exception { $form->set_valid(1) }, undef, "set valid to 1";

    cmp_deeply \@logs,
      superbagof( { debug => 'Setting valid for form main to 1.' } ),
      'got "valid is 1" debug log entry';
    @logs = ();

    cmp_deeply $session->read('form'),
      {
        main => {
            action => undef,
            errors => { foo => "bar" },
            fields => [],
            name   => "main",
            valid  => 1,
            values => {},
        },
      },
      "form in session looks good";

    is exception { $form->set_error( "buzz", "one", "two", "three" ) }, undef,
      'set_error "buzz", "one", "two", "three"';

    cmp_deeply $form->errors->mixed,
      { buzz => [ "one", "two", "three" ], foo => "bar" }, "errors looks good";

    cmp_deeply $form->errors_hashed,
      bag(
        { name => "foo",  label => "bar" },
        { name => "buzz", label => "one" },
        { name => "buzz", label => "two" },
        { name => "buzz", label => "three" },
      ),
      "errors_hashed looks good";

    ok $form->pristine, "form is pristine";
    cmp_ok $form->valid, '==', 0, "valid is 0";

    cmp_deeply \@logs,
      superbagof( { debug => 'Setting valid for form main to 0.' } ),
      'got "valid is 0" debug log entry';
    @logs = ();

    cmp_deeply $session->read('form'),
      {
        main => {
            action => undef,
            errors => { buzz => bag( "one", "two", "three" ), foo => "bar" },
            fields => [],
            name   => "main",
            valid  => 0,
            values => {},
        },
      },
      "form in session looks good";

    # reset

    is exception { $form->reset }, undef, "form reset lives";

    cmp_ok ref( $form->errors ), 'eq', 'Hash::MultiValue',
      'errors is a Hash::MultiValue';
    cmp_ok scalar $form->errors->keys, '==', 0, 'errors is empty';
    cmp_ok ref( $form->fields ), 'eq', 'ARRAY', 'fields is an array reference';
    cmp_ok @{ $form->fields }, '==', 0, 'fields is empty';
    cmp_ok $form->name, 'eq', 'main', 'form name is "main"';
    ok $form->pristine, "form is pristine";
    ok !defined $form->valid, "valid is undef";
    cmp_ok ref( $form->values ), 'eq', 'Hash::MultiValue',
      'values is a Hash::MultiValue';
    cmp_ok scalar $form->values->keys, '==', 0, 'values is empty';

    cmp_deeply $session->read('form'),
      {
        main => {
            action => undef,
            errors => {},
            fields => [],
            name   => "main",
            valid  => undef,
            values => {},
        },
      },
      "form in session looks good";
};

subtest 'to/from session' => sub {
    $session->delete('form');

    is exception {
        $form = Form->new(
            action  => '/cart',
            fields  => [qw/one two three/],
            log_cb  => $log_cb,
            name    => 'cart',
            session => $session
          )
    }, undef, "Form->new with action, fields, log_cb, name and session lives";

    cmp_ok $form->pristine, '==', 1, "form is pristine";

    ok !defined $form->valid, "valid is undef";

    ok !defined $session->read('form'), "form not yet in session"
      or diag explain $session;

    is exception {
        $form->fill( { one => 'foo', two => 'bar', three => 'buzz' } )
    }, undef, "fill the form";

    cmp_ok $form->pristine, '==', 0, "form is no longer pristine";

    ok !defined $form->valid, "valid is undef";

    ok !defined $session->read('form'), "form is still not in session"
      or diag explain $session;

    is exception { $form->add_error( one => "bad value for one" ) }, undef,
      "add_error lives";

    cmp_ok $form->valid, '==', 0, "valid is 0 (not valid)";

    ok defined $session->read('form'), "form is now in the session"
      or diag explain $session;

    cmp_deeply $session->read('form'),
      {
        cart => {
            action => '/cart',
            errors => { one => "bad value for one" },
            fields => [ "one", "two", "three" ],
            name   => "cart",
            valid  => 0,
            values => { one => 'foo', two => 'bar', three => 'buzz' },
        },
      },
      "form in session looks good"
      or diag explain $session;

    is exception {
        $form = Form->new(
            log_cb  => $log_cb,
            name    => 'cart',
            session => $session
          )
    }, undef, "Form->new with log_cb, name and session lives";

    cmp_ok $form->errors->keys, '==', 0, 'no errors';
    cmp_ok @{ $form->fields }, '==', 0, 'no fields';
    cmp_ok $form->values->keys, '==', 0, 'no values';
    cmp_ok $form->pristine, '==', 1, 'for is pristine';
    ok !defined $form->valid, "valid is undef";

    is exception { $form->from_session }, undef, "from_session lives";

    cmp_ok $form->errors->keys, '==', 1, '1 error';
    cmp_ok @{ $form->fields }, '==', 3, '3 fields';
    cmp_ok $form->values->keys, '==', 3, '3 values';
    cmp_ok $form->pristine, '==', 0, 'for is no longer pristine';
    cmp_ok $form->valid,    '==', 0, "valid is 0 (not valid)";

    cmp_deeply \@logs,
      superbagof( { debug => 'Setting valid for form cart to 0.' } ),
      'got "valid is 0" debug log entry' or diag explain @logs;
    @logs = ();

    cmp_deeply $form->errors->mixed, { one => "bad value for one" },
      "errors looks good";
};

done_testing;
