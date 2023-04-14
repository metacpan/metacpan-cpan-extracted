#
# This file is part of App-PythonToPerl
#
# This software is Copyright (c) 2023 by Auto-Parallel Technologies, Inc.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
# [[[ HEADER ]]]
# ABSTRACT: an unknown component
#use RPerl;
package Python::Unknown;
use strict;
use warnings;
our $VERSION = 0.016_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Python::Component);
use Python::Component;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print op
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants

# [[[ INCLUDES ]]]
use Perl::Types;
use OpenAI::API;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    component_type => my string $TYPED_component_type = 'Python::Unknown',
    sleep_seconds => my integer $TYPED_sleep_seconds = 5,
    sleep_retry_multiplier => my number $TYPED_sleep_retry_multiplier = 1.5,  # 1.5 == 150%, which means increase by 50%
    retries_max => my integer $TYPED_retries_max = 10,
    # all other properties inherited from Python::Component
};

# [[[ SUBROUTINES & OO METHODS ]]]

# PYUN01x
sub python_preparsed_to_perl_source {
# translate a chunk of Python source code into Perl source code
    { my string $RETURN_TYPE };
    ( my Python::Unknown $self, my OpenAI::API $openai ) = @ARG;

    # error if no OpenAI API
    if (not defined $openai) {
        croak 'ERROR EPYUN010: undefined OpenAI API, croaking';
    }

    # error or warning if no Python source code
    if ((not exists  $self->{python_source_code}) or
        (not defined $self->{python_source_code}) or
        ($self->{python_source_code} eq q{})) {
        croak 'ERROR EPYUN011: non-existent or undefined or empty Python source code, croaking';
    }

    # DEV NOTE, PYUN012: $self->{python_preparsed} not used in this class, no need to error check

    # initialize property that will store de-parsed & translated source code;
    # save fully translated Perl source code, to avoid repeated translating
    $self->{perl_source_code_full} = '';

    # DEV NOTE: OpenAI::API rate limit is 20 requests per minute (RPM) for free tier, sleep to avoid hitting rate limit;
    # DEV NOTE: sleep before API call instead of after call, to avoid "429 Too Many Requests" if previous call was recent
print 'in Python::Unknown::python_preparsed_to_perl_source(), about to call sleep(', $self->{sleep_seconds}, ')...', "\n";
    # sleep before calling API
    sleep($self->{sleep_seconds});
print 'in Python::Unknown::python_preparsed_to_perl_source(), ret from call to sleep(', $self->{sleep_seconds}, ')', "\n";

    # NEED ANSWER: the stop sequences were needed with Codex completions model 'code-davinci-002', do we still need now?
    # NEED ANSWER: the stop sequences were needed with Codex completions model 'code-davinci-002', do we still need now?
    # NEED ANSWER: the stop sequences were needed with Codex completions model 'code-davinci-002', do we still need now?

    # these strings signify an end to the translated Perl code, and the completion must stop when they are found
    my string::arrayref $stop_sequences = ['# Python to', 'Python:'];

    # DEV NOTE: shorten error sequences to speed up matching and allow for new or different wording
    my string::arrayref $error_sequences = [
        'Sorry, ',
#        'Sorry, as an AI language model, I cannot see any Python source code to translate. Can you please provide the code so I can assist you better?',
#        'Sorry, I cannot perform this task as the provided Python source code is incomplete and does not provide enough information to be translated accurately. Please provide the complete code.',
    ];

    # assemble "Python to Perl" message strings
    my string::hashref::arrayref $messages = [
        # DEV NOTE: save money by transmitting fewer tokens!
#        { 'role' => 'system',    'content' => 'You are a helpful assistant with detailed knowledge of the Perl and Python computer programming languages, as well as modern software development best practices.' },
#        { 'role' => 'user',      'content' => 'Translate the following Python source code to Perl:' . "\n" . $self->{python_source_code} . "\n" },
        { 'role' => 'user',      'content' => 'Translate this Python to Perl:' . "\n" . $self->{python_source_code} . "\n" },
    ];

print 'in Python::Unknown::python_preparsed_to_perl_source(), have $self->{python_source_code} =', "\n", $self->{python_source_code}, "\n";
print 'in Python::Unknown::python_preparsed_to_perl_source(), about to call python_preparsed_to_perl_source_api_call()...', "\n";

    # call OpenAI API
    my hashref $response = $self->python_preparsed_to_perl_source_api_call($openai, $stop_sequences, $messages);

print 'in Python::Unknown::python_preparsed_to_perl_source(), ret from call to python_preparsed_to_perl_source_api_call()', "\n";
#print 'in Python::Unknown::python_preparsed_to_perl_source(), received $response = ', Dumper($response), "\n";
#die 'TMP DEBUG, UNKNOWN';

# [[[ BEGIN FAILED API CALLS ]]]
# [[[ BEGIN FAILED API CALLS ]]]
# [[[ BEGIN FAILED API CALLS ]]]

    # handle HTTP response status codes returned from LWP::UserAgent
    if ((defined $EVAL_ERROR) and ($EVAL_ERROR ne '')) {

# NEED UPGRADE: accept any error code and just retry???
# NEED UPGRADE: accept any error code and just retry???
# NEED UPGRADE: accept any error code and just retry???

print 'in Python::Unknown::python_preparsed_to_perl_source(), received $EVAL_ERROR = \'', $EVAL_ERROR, '\'', "\n";

        # Error retrieving 'completions': 400 Bad Request
        if ($EVAL_ERROR =~ '400 Bad Request') {
            croak 'ERROR EPYUN013a: received HTTP response status code 400 (bad request) instead of OpenAI::API response, croaking', "\n", $EVAL_ERROR, "\n"; 
        }
        # Error retrieving 'completions': 429 Too Many Requests
        elsif ($EVAL_ERROR =~ '429 Too Many Requests') {
            carp 'WARNING WPYUN013b: received HTTP response status code 429 (too many requests) instead of OpenAI::API response, carping', "\n", $EVAL_ERROR, "\n"; 

            my integer $retries = 0;

            # backoff algorithm; increase sleep time and retry
            # https://help.openai.com/en/articles/5955604-how-can-i-solve-429-too-many-requests-errors
            # https://platform.openai.com/docs/guides/rate-limits/error-mitigation
            while ((defined $EVAL_ERROR) and ($EVAL_ERROR =~ '429 Too Many Requests')) {
print 'in Python::Unknown::python_preparsed_to_perl_source(), about to retry #', $retries, ' call python_preparsed_to_perl_source_api_call()...', "\n";
                $retries++;
                if ($retries >= $self->{retries_max}) {
                    croak 'ERROR EPYUN013b: received HTTP response status code 429 (too many requests) instead of OpenAI::API response, maximum retry limit ', $self->{retries_max}, ' reached, croaking'; 
                }

                # increase time to sleep by some percentage of current amount
                $self->{sleep_seconds} *= $self->{sleep_retry_multiplier};

print 'in Python::Unknown::python_preparsed_to_perl_source(), about to retry #', $retries, ' call sleep(', $self->{sleep_seconds}, ')...', "\n";
                # retry sleep before calling API
                sleep($self->{sleep_seconds});
print 'in Python::Unknown::python_preparsed_to_perl_source(), ret from retry #', $retries, ' call to sleep(', $self->{sleep_seconds}, ')', "\n";

                # retry call to OpenAI API
                $response = $self->python_preparsed_to_perl_source_api_call($openai, $messages);

print 'in Python::Unknown::python_preparsed_to_perl_source(), ret from retry #', $retries, ' call to python_preparsed_to_perl_source_api_call()', "\n";
#print 'in Python::Unknown::python_preparsed_to_perl_source(), received $response = ', Dumper($response), "\n";
#die 'TMP DEBUG, UNKNOWN 429 TOO MANY REQUESTS';
            }
        }
        # Error retrieving 'completions': 500 read timeout
        elsif ($EVAL_ERROR =~ '500 read timeout') {
            croak 'ERROR EPYUN013c: received HTTP response status code 500 (read timeout) instead of OpenAI::API response, croaking', "\n", $EVAL_ERROR, "\n"; 
# NEED SLEEP AND RETRY?
# NEED SLEEP AND RETRY?
# NEED SLEEP AND RETRY?
        }
        else {
            croak 'ERROR EPYUN013d: received unrecognized HTTP response status code instead of OpenAI::API response, croaking', "\n", $EVAL_ERROR, "\n"; 
        }
    }

print 'in Python::Unknown::python_preparsed_to_perl_source(), ret from call to OpenAI completions(), received $response =', "\n", Dumper($response), "\n";

    # DEV NOTE: sometimes the API returns an undefined or empty finish_reason, but still with valid 'text' field;
    # carp & return dummy code if translation ends for any other reason than reaching a legitimate 'stop' condition
    if (not defined $response) {
        croak 'ERROR EPYUN014a: received undefined OpenAI::API response, croaking'; 
    }
    elsif ((not exists $response->{choices}) or (not defined $response->{choices}) or
        (not defined $response->{choices}->[0])) {
        croak 'ERROR EPYUN014b: received non-existent or undefined OpenAI::API response choice, croaking'; 
    }
    else {
        # response choice is defined, check finish_reason and text
        if ((not exists $response->{choices}->[0]->{finish_reason}) or (not defined $response->{choices}->[0]->{finish_reason})) {
            carp 'WARNING WPYUN015a: received non-existent or undefined OpenAI::API response finish_reason, carping'; 
        }
        elsif ($response->{choices}->[0]->{finish_reason} ne 'stop') {
            carp 'WARNING WPYUN015b: received OpenAI::API response finish_reason \'', $response->{choices}->[0]->{finish_reason}, '\', expected \'stop\', carping';
        }

        if ((not exists $response->{choices}->[0]->{message}) or (not defined $response->{choices}->[0]->{message})) {
            croak 'ERROR EPYUN016a: received non-existent or undefined OpenAI::API response message, croaking'; 
        }
        elsif ((not exists $response->{choices}->[0]->{message}->{content}) or (not defined $response->{choices}->[0]->{message}->{content})) {
            croak 'ERROR EPYUN016b: received non-existent or undefined OpenAI::API response message content, croaking'; 
        }
        else {
            # retrieve Perl source code out of valid response choice
            $self->{perl_source_code} = $response->{choices}->[0]->{message}->{content};
        }
    }

    # translated Perl code must not start with any stop sequence,
    # it should never have been returned from OpenAI::API in the first place
    foreach my string $stop_sequence (@{$stop_sequences}) {
        foreach my string $perl_source_code_line (split /\n/, $self->{perl_source_code}) {
            if ($perl_source_code_line =~ m/^(\s*)$stop_sequence/) {
                croak 'ERROR EPYUN017a: stop sequence encountered in OpenAI::API response text, API call malfunction, croaking'; 
            }
        }
    }

    # translated Perl code must not start with any error sequence,
    # must ensure transmitted Python code is complete & recognizable,
    # if Python input code is good then we need to upgrade chunking or other App::PytonToPerl components
    foreach my string $error_sequence (@{$error_sequences}) {
        foreach my string $perl_source_code_line (split /\n/, $self->{perl_source_code}) {
            if ($perl_source_code_line =~ m/^(\s*)$error_sequence/) {
                croak 'ERROR EPYUN017b: error sequence encountered in OpenAI::API response text, API call malformation, croaking'; 
            }
        }
    }

# [[[ END FAILED API CALLS ]]]
# [[[ END FAILED API CALLS ]]]
# [[[ END FAILED API CALLS ]]]

    # remove all possibly-extraneous trailing blank lines and newlines returned by OpenAI::API response
    while ( chomp $self->{perl_source_code} ) {
print 'in Python::Unknown->python_preparsed_to_perl_source(), chomping $self->{perl_source_code} before returning', "\n";
        1;  # dummy no-op, so while() loop body is never empty
    }

# START HERE: need fix indentation of returned Perl code
# START HERE: need fix indentation of returned Perl code
# START HERE: need fix indentation of returned Perl code


# NEED REMOVE DUMMY CODE!!!
# NEED REMOVE DUMMY CODE!!!
# NEED REMOVE DUMMY CODE!!!
    if ($self->{perl_source_code} eq '') {
        $self->{perl_source_code} = '# DUMMY PERL SOURCE CODE, NEED RETRY FAILED API CALL!';  # TEMPORARY DEBUG, NEED DELETE!
    }

print 'in Python::Unknown::python_preparsed_to_perl_source(), have $self->{perl_source_code} =', "\n", $self->{perl_source_code}, "\n";

    # return Perl source code
    return $self->{perl_source_code};
}


# PYUN02x
sub python_preparsed_to_perl_source_api_call {
# call the OpenAI API
    { my hashref $RETURN_TYPE };
    ( my Python::Unknown $self, my OpenAI::API $openai, my string::arrayref $stop_sequences, my string::hashref::arrayref $messages ) = @ARG;
print 'in Python::Unknown::python_preparsed_to_perl_source_api_call(), received $self = ', Dumper($self), "\n";

    # error if no OpenAI API
    if (not defined $openai) {
        croak 'ERROR EPYUN020: undefined OpenAI API, croaking';
    }

    # error or warning if no Python source code
    if ((not exists  $self->{python_source_code}) or
        (not defined $self->{python_source_code}) or
        ($self->{python_source_code} eq q{})) {
        croak 'ERROR EPYUN021: non-existent or undefined or empty Python source code, croaking';
    }

    # error if no API messages
    if ((not defined $messages) or
        (not defined $messages->[0])) {
        croak 'ERROR EPYUN022: undefined API messages, croaking';
    }

print 'in Python::Unknown::python_preparsed_to_perl_source_api_call(), about to call OpenAI completions()...', "\n";

    # call OpenAI API, passing in Python source code and configuration options;
    # receive back response, containing Perl source code and other info;
    # wrap in eval{} to catch die() and enable checking $EVAL_ERROR below
    my hashref $response;
    eval { $response = $openai->chat(
#        model =>                'code-davinci-002',  # RIP free beta 20230323 ~1615hrs CDT; death to OpenAI!
        model =>                'gpt-3.5-turbo',
#        model =>                'gpt-4',  # wait until the price comes down, currently ~20x the price of gpt-3.5-turbo
        messages =>             $messages,
        temperature =>          0,
        max_tokens =>           256,
        top_p =>                1,
        frequency_penalty =>    0,
        presence_penalty =>     0,
        # DEV NOTE: the API spec & OpenAI::API allow the stop sequence to be a "string or array" which may contain "Up to 4 sequences"
        # https://platform.openai.com/docs/api-reference/completions/create#completions/create-stop
        # https://metacpan.org/pod/OpenAI::API
        # DEV NOTE: translating Python `if` conditional block header without following body can result in `Python: ...  Perl: ...` loop
        stop =>                 $stop_sequences,
    ); };

print 'in Python::Unknown::python_preparsed_to_perl_source_api_call(), received & about to return $response = ', Dumper($response), "\n";
#die 'TMP DEBUG, UNKNOWN OPENAI API';

    return $response;
}

1;
