package AWS::Lambda::Quick;

use strict;
use warnings;
use autodie;

our $VERSION = '1.0002';

use AWS::Lambda::Quick::Processor ();

sub import {
    shift;

    # where's the source code of the script calling us?
    my ( undef, $file, undef ) = caller;

    # process the whole thing
    my $proc = AWS::Lambda::Quick::Processor->new(
        src_filename => $file,
        @_,
    );
    my $url = $proc->process;
    print "$url\n" or die "problem with fh: $!";

    # and exit before we run the remainder of the script
    # (since that's meant to be run on AWS Lambda, and we're just
    # uploading at this time!)
    exit;
}

1;

__END__

=head1 NAME

AWS::Lambda::Quick - quickly create a REST accesible AWS Lambda function

=head1 SYNOPSIS

Write a simple script containing a 'handler' function:

    #!/usr/bin/perl

    use strict;
    use warnings;

    use AWS::Lambda::Quick (
        name => 'hello-world',
    );

    sub handler {
        my $data = shift;
        my $name = $data->{queryStringParameters}{who} // "World";
        return {
            statusCode => 200,
            headers => {
                'Content-Type' => 'text/plain',
            },
            body => "Hello, $name",
        };
    }

    1;

To upload to and configure AWS, just run the script locally:

    shell$ perl myscriptname.pl
    https://52p3rf890b.execute-api.us-east-1.amazonaws.com/quick/hello-world

Then you can access it from anywhere:

    shell$ curl https://52p3rf890b.execute-api.us-east-1.amazonaws.com/quick/hello-world?who=Mark'
    Hello, Mark

=head1 DESCRIPTION

This module allows you to very quickly create a Perl based AWS
Lambda function which can be accessed via HTTP.

Coding Lambda functions in Perl is straight forward: You need only
implement a script with the one C<handler> function that returns the
expected data structure as described in the L<AWS::Lambda>
documentation.

The hard part is configuring AWS to execute the code.  Traditionally
you have to complete the following steps.

=over

=item Create a zip file containing your code

=item Create (or update) an AWS Lambda function with this zip file

=item Create a REST API with AWS Gateway API

=item Configure a resource for that REST API for this script

=item Set up a method and put method response for that resource

=item Manage an integration and integration response for that resource

=back

And then debug all the above things, a lot, and google weird error
messages it generates when you inevitably make a mistake.

This module provides a way to do all of this completely transparently
just by executing your script, without having to either interact with
the AWS Management Console nor directly use the awscli utility.

Simply include this module at the top of your script containing the
handler function:

    use AWS::Lambda::Quick (
        name => 'random-lottery-numbers',
    );

And then execute it locally.  Rather than running as normal your script
will instead upload itself to AWS as a Lambda function (modifying
itself so that it no longer has a dependency on AWS::Lambda::Quick) and
handle all the other steps needed to make itself web accessible.
Running the script locally subsequent times will update the code and
AWS settings.

=head2 What This Actually Does

You probably don't care about this, but this is actually what's
going on when the script uploads itself.  This is subject to change
in later versions of this utility as better ways to do things
become available (for example AWS has a HTTP API that is currently in
beta that could make some of this easier!).

By default, unless you specify extra parameters when you import
AWS::Lambda::Quick, AWS will be configured as described below

=head3 Create A New Role For Use With AWS::Lambda::Quick

Execution creates a new role called C<perl-aws-lambda-quick> that can
be assumed by both the API Gateway (C<apigateway.amazonaws.com>) and
Lambda (C<lambda.amazonaws.com>) services.  The role will have
C<AWSLambdaRole> and C<CloudWatchLogsFullAccess>  policies permissioned
(so it execute the lambda function and write logs.)

You can modify this role as you see fit.  For example, to give your
lambda functions the ability to access S3:

    shell$ aws iam attach-role-policy \
             --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
             --role-name perl-aws-lambda-quick

If you really want your lambda functions to use a different role then
you can control this with the C<role> parameter described below.

=head3 Create a new Lambda Function

Execution uploads the script (and any extra files specified, see
the C<extra_files> parameter below) as a new Lambda function with the
passed name.  Subsequent uploads will replace and update that Lambda
function

The function will be assigned the previously created role.

=head3 Create a API Gateway For All Quick Functions

This will create a REST API API Gateway that we use for accessing
any quick functions created on that account.  If you're not familiar
with AWS, this can we considered somewhat like a top level domain where
all the APIs we create will be "mounted".

If you want you can pass in an alternative existing rest API to
be used instead, either with the C<rest_api_id> parameter to specify
by id, or by passing in the name via the C<rest_api> parameter.

=head3 Create a new resource

Executing will create a new resource for each Lambda function (If you're
not familiar with AWS this is somewhat like specifying a path for the
API to be callable on.) This will be created directly off the top level
resource (i.e. off of "/") and will be named after the name of the
Lambda function (i.e. calling C<use AWS::Lambda::Quick (name => "foo")>
will create a resource C</foo>)

=head3 Create a new method

Each Lambda function we create gets its own method, which is where
AWS specifies what HTTP method it accepts (C<GET>,C<POST>,C<PUT>,
etc.) and how it decides who can access it.

This module always sets the type of method to C<ANY> (i.e. we always
call the lambda function and let it figure out what it wants to accept
or not.)

We setup the C<NONE> authentication, meaning anyone can call the API
over the internet - i.e. it's configured as a public API.

=head3 Create a new integration

Integrations are how AWS decides both where a request is routed to
and what extracted from that HTTP request is passed on and how.

We configure an AWS_PROXY integration routing to our new Lambda
function.  This essentially means everything is passed "as is"
through to our handler as the first argument.

Upload and GET the following to see what is being passed in
your environment:

    #!/usr/bin/perl

    use strict;
    use warnings;

    use JSON::PP;

    use AWS::Lambda::Quick (
        name => 'echo',
    );

    sub handler {
        my $data = shift;
        return {
            statusCode => 200,
            headers => {
                'Content-Type' => 'application/json',
            },
            body => encode_json($data),
        };
    }

    1;

=head3 Create a new integration-response and method-response

The integration response and method response are analogous to the
integration and method - but instead of getting data from HTTP to
Lambda, they get Lambda data back to HTTP.

Because we want our handler to have complete control over the output
we don't do anything special with what we create.

=head3 Deploying the Code.

Once all the above is done the module finally deploys the code
so it's web accessible.

By default this is to the C<quick>, though you can reconfigure that
with the C<stage_name> parameter.

=head2 Parameters

This is a full list of parameters you can currently configure.  Only
one parameter - C<name> - is required and all other parameters are
optional and will have hopefully sensible defaults.

It is not the intent of the author to provide a complete and exhaustive
list of all possibilities - you have the power of the AWS Management
console and AWS API to make any further tweaks you may desire.

=over

=item name

The name of the Lambda function.  Required.

This will become part of the URL that can be used to call this
function so you are strongly encouraged not to use any non-url
safe characters (including C</>, C<?>, etc) in the name.

=item description

The description of the Lambda function (shown in the AWS console, etc.)

=item extra_files

An array of extra files and directories that you wish to upload in
addition to the script itself.

For example, to upload the C<lib> directory, you would write:

    use AWS::Lambda::Quick (
        name => 'some-script-that-needs-modules',
        extra_files => [ 'lib' ],
    );

These filenames must be relative and will be expected to be in the
same directory as the script itself.  Passing a directory name will
cause the directory contents to be recursively uploaded.  If a named
file/directory is not present at the passed location it will be
silently ignored.

=item region

The region you wish to deploy the lamda function to.  By default
this will be C<us-east-1>.

=item memory_size

The amount of memory that your function has access to. Increasing
the function's memory also increases its CPU allocation. The default
value is 128 MB. The value must be a multiple of 64 MB.

=item timeout

The amount of time that Lambda allows a function to run before stopping
it. The default is 3 seconds. The maximum allowed value is 900 seconds.

=item role

The AWS role you want to run the Lambda function as.  This can
either be a full arn, or the name of the role to use (which will
be automatically created with permissions to run Lambda functions
if it does not exist).

If you do not pass a role argument the role with the name
C<perl-aws-lambda-quick> will be used (and created if it does not
exist).

=item rest_api_id

The id of the rest api to use.  If no id is passed then it is
automatically determined from the rest_api parameter.

Including this value will make your script less portable between
accounts, but will reduce the number of API calls made during updates.

=item rest_api

The name of the rest api to use if you did not pass a C<rest_api_id>
(if you did this parameter will be ignored.) Will default to
C<perl-aws-lambda-quick> if not passed.  If no such named rest api
exists then one will be automatically created.

=item stage_name

The name we stage to.  By default this is C<quick> meaning that
our live URL will be of the form:

    https://????.execute-api.????.amazonaws.com/quick/????

By setting stage_name to another value you can change this.

=item extra_layers

An arrayref of extra layers (in addition to the standard prebuilt public
Lambda layer for Perl) that will be used by this Lambda function.

Currently AWS Lamda supports up to four extra layers (five in total
including the prebuilt public layer for Perl.)  All layers, when
decompressed, must be less that 250MB in size.

You may either identify a layer by its ARN, or by using a identifying
name that is known to this module.  At this time the only known
identifying name is C<paws> which indicates that the Lambda function
should use the prebuilt Paws layer in the same region as the Lambda
function.

    use AWS::Lambda::Quick (
        name => 'email sender',
        extra_layers => [ 'paws' ],
    );

=back

=head2 Installing the CLI tools

This module requires you to have the version 1 AWS CLI tools installed
on your system and configured with your authentication credentials.
Installing the tools are covered in many AWS guides, but can be
quickly summarized as:

    shell$ curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    shell$ unzip awscli-bundle.zip
    shell$ sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

You'll need to configure awscli with your own personal AWS Access
Key ID and AWS Secret Access Key.  You can create these from the AWS
Management console by following the guide on
L<How to quickly find and update your access keys, password, and MFA setting using the AWS Management Console|https://aws.amazon.com/blogs/security/how-to-find-update-access-keys-password-mfa-aws-management-console/>

Once you have your keys you can then use the C<configure> command
to update the aws command line utility.

    shell$ aws configure
    AWS Access Key ID [********************]:
    AWS Secret Access Key [********************]:
    Default region name [us-east-1]:
    Default output format [None]:

=head2 Speeding up Code Updates

By default this module will check that everything is configured
correctly in AWS and will make changes as needed.  This requires several
API calls (and several executions of the AWS python command line
tool.)

If you've only changed the source code and want to deploy a new version
you can just do that by setting the C<AWS_LAMBDA_QUICK_UPDATE_CODE_ONLY>
enviroment variable:

   shell$ AWS_LAMBDA_QUICK_UPDATE_CODE_ONLY=1 perl lambda-function.pl

In the interest of being as quick as possible, when this is environment
variable is enabled the URL for the upload is not computed and printed
out.

=head2 Enabling debugging output

To gain a little more insight into what is going on you can set
the C<AWS_LAMBDA_QUICK_DEBUG> environment variable to enabled
debugging to STDERR:

    shell$ AWS_LAMBDA_QUICK_DEBUG=1 perl lambda-function.pl
    updating function code
    function code updated
    updating function configuration
    searching for existing role
    found existing role
    ...

=head1 AUTHOR

Written by Mark Fowler B<mark@twoshortplanks.com>

Copyright Mark Fowler 2019.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AWS::Lambda>, L<AWS::CLIWrapper>

=cut
