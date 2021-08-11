package App::MechaCPAN::t::Helper;

use App::MechaCPAN;

$App::MechaCPAN::QUIET   = 1;
$App::MechaCPAN::LOG_ON  = 0;
$App::MechaCPAN::TIMEOUT = 0;

# Delete PERL_USE_UNSAFE_INC, it will interfere with our tests.
# This shouldn't be a problem for us since this helper has already been
# included, this is so we can test the rest of our functionality
delete $ENV{PERL_USE_UNSAFE_INC};

# Make sure that none of the dists we're testing run author tests
delete $ENV{AUTHOR_TESTING};

no strict 'refs';
no warnings 'redefine';
*App::MechaCPAN::error = sub
{
  my $key  = shift;
  my $line = shift;
  if ( !defined $line )
  {
    $line = $key;
    undef $key;
  }
  Test::More::diag("$key - $line");
};

1;
