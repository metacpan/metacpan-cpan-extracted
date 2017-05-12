#------------------------------------------------------------------------------
# $Id$

use strict;
use warnings;

# Test Modules
use Test::More tests => 5;
use Test::Exception;

# Extra Modules

# Local Modules;
use Authen::Prepare;

#------------------------------------------------------------------------------
# Setup
my $authen = Authen::Prepare->new();

#------------------------------------------------------------------------------
# Tests

test_prompt_timed();
test_prompt_while_empty();

#------------------------------------------------------------------------------
# Subroutines

sub test_prompt_timed {
    diag('Testing prompt timeouts: may take a few seconds to complete');
    dies_ok { $authen->_prompt_timed(1) } 'Dies after prompt timeout';
    dies_ok { $authen->_prompt_timed() } 'Dies after default prompt timeout';
}

sub test_prompt_while_empty {
    my $response;
    $authen->timeout(1);

    lives_ok { $response = $authen->_prompt_while_empty('foo') }
    'No prompt with non-empty response string';

    is( $response, 'foo', 'Response is correct' );

    $authen->timeout(1);
    dies_ok { $authen->_prompt_while_empty( undef, q{} ) }
    'Prompt when initial response is not given';
}

#------------------------------------------------------------------------------

__END__
