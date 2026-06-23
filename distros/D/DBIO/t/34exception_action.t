use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;
use DBIO::Test;

my $schema = DBIO::Test->init_schema(no_deploy => 1);

# This is how we're generating exceptions in the rest of these tests,
#  which might need updating at some future time to be some other
#  exception-generating statement:

my $throw  = sub { $schema->resultset("Artist")->search(1,1,1) };
my $ex_regex = qr/Odd number of arguments to search/;

# Basic check, normal exception
throws_ok \&$throw, $ex_regex;

my $e = $@;

# Re-throw the exception with rethrow()
throws_ok { $e->rethrow }
  $ex_regex;
isa_ok( $@, 'DBIO::Exception' );

# Now lets rethrow via exception_action
$schema->exception_action(sub { die @_ });
throws_ok \&$throw, $ex_regex;

#
# This should have never worked!!!
#
# Now lets suppress the error
$schema->exception_action(sub { 1 });
throws_ok \&$throw,
  qr/exception_action handler .+ did \*not\* result in an exception.+original error: $ex_regex/;

# Now lets fall through and let croak take back over
$schema->exception_action(sub { return });
throws_ok {
  warnings_are \&$throw,
    qr/exception_action handler installed .+ returned false instead throwing an exception/;
} $ex_regex;

# again to see if no warning
throws_ok {
  warnings_are \&$throw,
    [];
} $ex_regex;


# Whacky useless exception class
{
    package DBIO::Test::Exception;
    use overload '""' => \&stringify, fallback => 1;
    sub new {
        my $class = shift;
        bless { msg => shift }, $class;
    }
    sub throw {
        my $self = shift;
        die $self if ref $self eq __PACKAGE__;
        die $self->new(shift);
    }
    sub stringify {
        "DBIO::Test::Exception is handling this: " . shift->{msg};
    }
}

# Try the exception class
$schema->exception_action(sub { DBIO::Test::Exception->throw(@_) });
throws_ok \&$throw,
  qr/DBIO::Test::Exception is handling this: $ex_regex/;

# While we're at it, lets throw a custom exception through Storage::DBI
throws_ok { $schema->storage->throw_exception('floob') }
  qr/DBIO::Test::Exception is handling this: floob/;

done_testing;
