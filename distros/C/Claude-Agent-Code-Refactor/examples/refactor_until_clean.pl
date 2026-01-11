#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;

use Claude::Agent::Code::Refactor qw(refactor_until_clean);
use Claude::Agent::Code::Refactor::Options;
use IO::Async::Loop;

# Create event loop
my $loop = IO::Async::Loop->new;

# Configure refactor options
my $options = Claude::Agent::Code::Refactor::Options->new(
    max_iterations         => 5,              # Max review-fix cycles
    min_severity           => 'medium',       # Only fix medium+ issues
    categories             => ['bugs', 'security'],  # Focus on these
    permission_mode        => 'acceptEdits',  # Auto-accept file edits
    perlcritic             => 1,              # Include perlcritic analysis
    perlcritic_severity    => 4,              # Perlcritic severity level
    filter_false_positives => 1,              # Filter out false positives
);

# Run the refactor loop on lib/
my $result = refactor_until_clean(
    paths   => ['lib/'],
    options => $options,
    loop    => $loop,
)->get;

# Display results
print $result->as_text;

# Exit with appropriate code
exit($result->is_clean ? 0 : 1);
