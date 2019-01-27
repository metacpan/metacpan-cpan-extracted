package App::Perlambda;

use 5.020000;
use strict;
use warnings;
use utf8;

our $VERSION = "0.01";

1;
__END__

=encoding utf-8

=head1 NAME

App::Perlambda - A CLI tool for managing Lambda functions with Lambda Perl layer.

=head1 SYNOPSIS

    $ perlambda dist ...   # Make a zip archive for Lambda function
    $ perlambda create ... # Create a Lambda function on AWS with perl layer
    $ perlambda update ... # Update the Lambda function code.
    $ perlambda help <dist|create|update>

=head1 DESCRIPTION

App::Perlambda is a CLI tool for managing Lambda functions with Lambda Perl layer.

This CLI tool aims to manage the Lambda function with Lambda Perl layer: L<aws-lambda-perl5-layer|https://github.com/moznion/aws-lambda-perl5-layer>.

Please refer to the following for a concrete example: L<aws-lambda-perl5-layer-example|https://github.com/moznion/aws-lambda-perl5-layer-example>

=head1 REQUIREMENTS

=over 4

=item * Perl 5.26 or later

=item * Docker

=item * L<AWS::CLIWrapper>

=back

This tool uses Docker and L<AWS::CLIWrapper>.

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

