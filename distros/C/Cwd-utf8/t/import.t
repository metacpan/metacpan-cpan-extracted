#!perl
use strict;
use warnings;
use Test::Exception tests => 6;

# Test the various import combinations.
# Each test is performed in its own package to prevent one use
# statement influencing the other.

# Correct handling of the :none tag
{
    package test_none;
    use Cwd::utf8 qw(:none);
    Test::Exception::throws_ok
        {
            cwd();
        }
        qr/Undefined subroutine &test_none::cwd called/,
        ':none correctly imported';
}

# Correct handling of !getcwd
{
    package test_notcwd;
    use Cwd::utf8 qw(!cwd);
    Test::Exception::throws_ok
          {
              cwd();
          }
          qr/Undefined subroutine &test_notcwd::cwd called/,
          'cwd correctly not imported with !cwd';
    Test::Exception::lives_ok
          {
              getcwd();
          }
          'getcwd correctly imported with !cwd';
}

# Correct handling of /path/
{
    package test_re;
    use Cwd::utf8 qw(/path/);
    Test::Exception::lives_ok
    {
        abs_path('.');
        fast_abs_path('.');
        realpath('.');
        fast_realpath('.');
    }
    '*path* correctly imported with /path/';
    Test::Exception::throws_ok
    {
        cwd();
    }
    qr/Undefined subroutine &test_re::cwd called/,
    'cwd correctly not imported with /path/';
}

# Correct handling of invalid symbol
{
    package test_invalid;
    require Cwd::utf8;
    Test::Exception::throws_ok
          {
              Cwd::utf8->import(qw(invalid_symbol));
          }
          qr/"invalid_symbol" is not exported by the Cwd module/,
          'invalid symbol correctly noted';
}
