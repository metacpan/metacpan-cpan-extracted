# NAME

App::Perlambda - A CLI tool for managing Lambda functions with Lambda Perl layer.

# SYNOPSIS

    $ perlambda dist ...   # Make a zip archive for Lambda function
    $ perlambda create ... # Create a Lambda function on AWS with perl layer
    $ perlambda update ... # Update the Lambda function code.
    $ perlambda help <dist|create|update>

# DESCRIPTION

App::Perlambda is a CLI tool for managing Lambda functions with Lambda Perl layer.

This CLI tool aims to manage the Lambda function with Lambda Perl layer: [aws-lambda-perl5-layer](https://github.com/moznion/aws-lambda-perl5-layer).

Please refer to the following for a concrete example: [aws-lambda-perl5-layer-example](https://github.com/moznion/aws-lambda-perl5-layer-example)

# REQUIREMENTS

- Perl 5.26 or later
- Docker
- [AWS::CLIWrapper](https://metacpan.org/pod/AWS::CLIWrapper)

This tool uses Docker and [AWS::CLIWrapper](https://metacpan.org/pod/AWS::CLIWrapper).

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
