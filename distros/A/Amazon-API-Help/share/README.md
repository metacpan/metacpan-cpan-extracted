# Table of Contents

* [NAME](#name)
* [DESCRIPTION](#description)
  * [Design: Documentation Lives Here, Not in the Runtime](#design-documentation-lives-here-not-in-the-runtime)
* [USAGE](#usage)
  * [Commands](#commands)
  * [Options](#options)
* [VERSION](#version)
* [AUTHOR](#author)
* [SEE ALSO](#see-also)
# NAME

amzn-api-help - Help for AWS services and types

# DESCRIPTION

`amzn-api-help` renders documentation for AWS services, their
operations, and their data types (shapes) on demand, for developers
working with [Amazon::API](https://metacpan.org/pod/Amazon%3A%3AAPI). It answers the questions you hit while
writing API calls: what operations a service exposes, what parameters
an operation takes and returns, what errors it can raise, and what a
given shape looks like.

The documentation is generated from the same Botocore metadata the
[Amazon::API](https://metacpan.org/pod/Amazon%3A%3AAPI) classes are built from, pinned to the Botocore version
recorded in [Amazon::API::BuildInfo](https://metacpan.org/pod/Amazon%3A%3AAPI%3A%3ABuildInfo) and shown at the foot of each
page. This matters: it is the one description of the request and
response shapes guaranteed to match what [Amazon::API](https://metacpan.org/pod/Amazon%3A%3AAPI) actually
sends and expects. You can approximate the same information by reading
`aws SERVICE OPERATION help` from the AWS CLI, but those shapes are
the CLI's own rendering of Botocore -- close, but not guaranteed to
line up with the shape names and structures [Amazon::API](https://metacpan.org/pod/Amazon%3A%3AAPI) uses, or
with the Botocore version it was built against.

Within a service, **operations** are the callable actions (for example
`ListQueues`) and **shapes** are the data types those operations send
and receive (for example `ListQueuesRequest`, or reusable types like
`Arn`). Operations reference shapes; the same shape may be reached
through several operations. When a name exists as both an operation
and a shape, the operation takes precedence -- use `--shape` to ask
for the shape instead.

Documentation is paged through your default pager unless
`--no-cli-pager` is given.

## Design: Documentation Lives Here, Not in the Runtime

The other Perl AWS SDK, [Paws](https://metacpan.org/pod/Paws), takes the opposite approach, and the
contrast is the reason this tool exists as a separate install. Paws
renders POD into every generated class and builds on [Moose](https://metacpan.org/pod/Moose), so both
the documentation and the meta-object protocol are compiled into the
runtime whether or not they are used. `Amazon::API` installs neither:
its generated classes are lean stubs carrying only the metadata slice
they need to make calls, and the documentation lives here, in a
developer tool you install only if you want it. The result is a
smaller install and a faster cold start -- Paws itself notes its
objects must be immutabilized "at the cost of startup time".

# USAGE

## Commands

- help

        amzn-api-help help service type|operation

    - Get a list of all services

            amzn-api-help help

        _Note: 'help' is optional in all examples. `amzn-api-help sts` is also valid for example._

    - Get a list of all operations for a service

            amzn-api-help help sqs

    - Get documentation for an operation

            amzn-api-help help sqs ListQueues

    - Get documention for a type or shape

            amzn-api-help help sqs ListQueuesRequest

- dump-service

    Dump service metadata as JSON.

        amzn-api-help dump-service sts

- version

    Display the [Amazon::API](https://metacpan.org/pod/Amazon%3A%3AAPI) and Botocore versions.

## Options

    --help, -h       This help
    --shape          Force shape lookup precendence.
    --no-cli-pager   Disable use of pager.

# VERSION

This documentation refers to version 1.0.3

# AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

# SEE ALSO

[Amazon::API](https://metacpan.org/pod/Amazon%3A%3AAPI)
