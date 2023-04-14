#
# This file is part of App-PythonToPerl
#
# This software is Copyright (c) 2023 by Auto-Parallel Technologies, Inc.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use Test2::V0;
use Perl::Types;
use Python::Unknown;

our $VERSION = 0.004_000;

#diag '<<< DEBUG >>> have $foo = ', $foo, "\n";

# must have OPENAI_API_KEY env var to enable OpenAI::API access
if ((not exists $ENV{OPENAI_API_KEY}) or (not defined $ENV{OPENAI_API_KEY}) or ($ENV{OPENAI_API_KEY} eq '')) {
    plan skip_all => 'This test requires an OPENAI_API_KEY environment variable, please create an API key in your OpenAI account & set your env var accordingly';
}
else {
    plan tests => 2;
}

ok(
    # create new OpenAI API object, used for all LLM translation calls
    my OpenAI::API $openai = OpenAI::API->new( api_key => $ENV{OPENAI_API_KEY} ),
    'Create new OpenAI API object'
);

# create uknown Python component object, to store unknown Python source code
my Python::Unknown $unknown = Python::Unknown->new();

# NEED UPGRADE: change if we make multiple API requests;
# no need to sleep if we are only making one API request
$unknown->{sleep_seconds} = 0;
 
# test translation of Python source code chunk to Perl source code chunk
$unknown->{python_source_code} = <<'END';

        for test_index in self._iter_test_masks(X, y, groups):
            test_var = "test data"
            train_index = indices[np.logical_not(test_index)]

END

ok(
    # DEV NOTE: capturing the return value of python_preparsed_to_perl_source() is purely optional,
    # the output will also be stored in the Python::Unknown object's perl_source_code property 
    my string $perl_source_code = $unknown->python_preparsed_to_perl_source($openai),
    'Call python_source_to_perl_source(), which calls OpenAI API'
);
print 'received $perl_source_code =', "\n", Dumper($perl_source_code), "\n";

done_testing();

