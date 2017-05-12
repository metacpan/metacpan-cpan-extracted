#!perl
use strict;
use warnings;
use Authen::Prepare 0.04;
use Smart::Comments;

# Prompt for nothing: read 'mypassfile' for the password
my %auth = Authen::Prepare->new(
    {
        hostname => 'myhost',
        username => 'myuser',
        passfile => 'mypassfile',
    }
)->credentials();

### %auth
