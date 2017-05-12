#!perl
use strict;
use warnings;
use Authen::Prepare 0.04;
use Smart::Comments;

# Prompt for everything
my %auth = Authen::Prepare->new->credentials();

### %auth
