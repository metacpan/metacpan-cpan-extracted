
use strict;
use warnings;
use Test::More;
use DBIx::Class::Async;

# 1. Setup a Mock Object environment
{
    package Mock::Exception;
    sub new     { my ($class, $msg) = @_; bless { message => $msg }, $class }
    sub message { shift->{message} }
    sub msg     { shift->{message} } # Support both common naming conventions
    sub isa     { my ($self, $class) = @_; return $class eq 'DBIx::Class::Exception' || $self->SUPER::isa($class) }

    package Mock::Source;
    sub new             { bless {}, shift }
    sub primary_columns { return ('user_id') }

    package Mock::Schema;
    sub new    { bless {}, shift }
    sub source { return Mock::Source->new }

    package Mock::Async;
    use base 'DBIx::Class::Async';
    sub new {
        return bless { _schema => Mock::Schema->new }, shift
    }
    sub _schema_instance { return shift->{_schema} }
}

my $async = Mock::Async->new;

subtest '_check_response tests' => sub {
    # Test 1: Plain success hash
    is($async->_check_response({ id => 1 }), undef, "Plain hash is not an error");

    # Test 2: Scalar success
    is($async->_check_response(1), undef, "Scalar (row count/ID) is not an error");

    # Test 3: Mocked Exception object
    # We use our Mock::Exception which reports itself as a DBIx::Class::Exception
    my $ex = Mock::Exception->new("Unique constraint failed");
    my $caught_ex = $async->_check_response($ex);

    ok(defined $caught_ex, "Caught the exception object");
    is($caught_ex->message, "Unique constraint failed", "Exception message preserved");

    # Test 4: Internal __error hash key
    my $err_hash = { __error => "Database connection lost" };
    is($async->_check_response($err_hash), "Database connection lost", "Catches __error key");

    # Test 5: Undef
    is($async->_check_response(undef), undef, "Undef returns undef (no error)");
};

subtest '_merge_result_data tests' => sub {
    my $original = { name => 'Manwar', email => 'perl@example.com' };

    # Test 1: Merge HASH (Worker returns updated/full row)
    my $returned_hash = { user_id => 42, last_login => 'now' };
    my $merged_h = $async->_merge_result_data('User', $original, $returned_hash);

    is($merged_h->{user_id}, 42, "Merged ID from hash");
    is($merged_h->{name}, 'Manwar', "Original data preserved");
    is($merged_h->{last_login}, 'now', "New fields from worker added");

    # Test 2: Merge SCALAR (Worker returns just the new ID)
    my $returned_id = 99;
    my $merged_s = $async->_merge_result_data('User', $original, $returned_id);

    is($merged_s->{user_id}, 99, "Auto-detected PK 'user_id' and set to scalar result");
    is($merged_s->{email}, 'perl@example.com', "Original data preserved during scalar merge");
};

done_testing;
