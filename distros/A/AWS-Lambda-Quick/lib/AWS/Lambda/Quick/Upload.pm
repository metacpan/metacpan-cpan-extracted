package AWS::Lambda::Quick::Upload;
use Mo qw( default required );

our $VERSION = '1.0002';

use AWS::CLIWrapper;
use JSON::PP ();

### required attributes

has zip_filename => required => 1;
has name         => required => 1;

### optional attributes wrt the lambda function itself

has extra_layers => default => [];
has region       => default => 'us-east-1';
has memory_size  => default => 128;           # this is the AWS default
has timeout      => default => 3;             # this is the AWS default
has description => default => 'A Perl AWS::Lambda::Quick Lambda function.';
has stage_name  => default => 'quick';

### lambda function computed attributes

has aws => sub {
    my $self = shift;

    return AWS::CLIWrapper->new(
        region => $self->region,
    );
};

has zip_file_blob => sub { 'fileb://' . shift->zip_filename };

# should we create the function from scratch or just update it?
# by default we interogate the api to see if it exists already
has update_type => sub {
    my $self = shift;
    my $aws  = $self->aws;

    my $result = $aws->lambda(
        'get-function',
        {
            'function-name' => $self->name,
        }
    );

    return $result ? 'update-function' : 'create-function';
};

### role attributes

has role      => default => 'perl-aws-lambda-quick';
has _role_arn => sub {
    my $self = shift;

    # if whatever we were passed in role was an actual ARN then we
    # can just use that without any further lookups
    if ( $self->role
        =~ /^arn:(aws[a-zA-Z-]*)?:iam::\d{12}:role\/?[a-zA-Z_0-9+=,.@\-_\/]+$/
    ) {
        $self->debug('using passed role arn');
        return $self->role;
    }

    $self->debug('searching for existing role');
    my $aws    = $self->aws;
    my $result = $aws->iam(
        'get-role',
        {
            'role-name' => $self->role,
        }
    );
    if ($result) {
        $self->debug('found existing role');
        return $result->{Role}{Arn};
    }

    $self->debug('creating new role');
    $result = $self->aws_do(
        'iam',
        'create-role',
        {
            'role-name' => $self->role,
            'description' =>
                'Role for lambda functions created by AWS::Lambda::Quick. See https://metacpan.org/pod/AWS::Lambda::Quick for more info.',
            'assume-role-policy-document' => <<'JSON',
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "lambda.amazonaws.com",
                    "apigateway.amazonaws.com"
                ]
            }
        }
    ]
}
JSON
        }
    );
    $self->debug('new role created');
    $self->debug('attaching permissions to role');
    $self->aws_do(
        'iam',
        'attach-role-policy',
        {
            'policy-arn' =>
                'arn:aws:iam::aws:policy/service-role/AWSLambdaRole',
            'role-name' => $self->role,
        }
    );
    $self->aws_do(
        'iam',
        'attach-role-policy',
        {
            'policy-arn' =>
                'arn:aws:iam::aws:policy/CloudWatchLogsFullAccess',
            'role-name' => $self->role,
        }
    );
    $self->debug('permissions attached to role');
    return $result->{Role}{Arn};
};

### rest api attributes

has rest_api    => default => 'perl-aws-lambda-quick';
has rest_api_id => sub {
    my $self = shift;

    # search existing apis
    $self->debug('searching for existing rest api');
    my $result = $self->aws_do(
        'apigateway',
        'get-rest-apis',
    );
    for ( @{ $result->{items} } ) {
        next unless $_->{name} eq $self->rest_api;
        $self->debug('found existing existing rest api');
        return $_->{id};
    }

    # couldn't find it.  Create a new one
    $self->debug('creating new rest api');
    $result = $self->aws_do(
        'apigateway',
        'create-rest-api',
        {
            name => $self->rest_api,
            description =>
                'Created by AWS::Lambda::Quick. See https://metacpan.org/pod/AWS::Lambda::Quick for more info.',
        },
    );
    $self->debug('created new rest api');
    return $result->{id};
};

has resource_id => sub {
    my $self = shift;

    # TODO: We shold probably make this configurable, right?
    my $path = '/' . $self->name;

    # search existing resources
    $self->debug('searching of existing resource');
    my $result = $self->aws_do(
        'apigateway',
        'get-resources',
        {
            'rest-api-id' => $self->rest_api_id,
        }
    );
    for ( @{ $result->{items} } ) {
        next unless $_->{path} eq $path;
        $self->debug('found exiting resource');
        return $_->{id};
    }

    # couldn't find it.  Create a new one
    $self->debug('creating new resource');
    my $parent_id;
    for ( @{ $result->{items} } ) {
        if ( $_->{path} eq '/' ) {
            $parent_id = $_->{id};
            last;
        }
    }
    unless ($parent_id) {
        die q{Can't find '/' resource to create a new resource from!};
    }
    $result = $self->aws_do(
        'apigateway',
        'create-resource',
        {
            'rest-api-id' => $self->rest_api_id,
            'parent-id'   => $parent_id,
            'path-part'   => $self->name,
        },
    );
    $self->debug('created new resource');
    return $result->{id};
};

has greedy_resource_id => sub {
    my $self = shift;

    my $path = '/' . $self->name . '/{proxy+}';

    # search existing resources
    $self->debug('searching of existing greedy resource');
    my $result = $self->aws_do(
        'apigateway',
        'get-resources',
        {
            'rest-api-id' => $self->rest_api_id,
        }
    );
    for ( @{ $result->{items} } ) {
        next unless $_->{path} eq $path;
        $self->debug('found exiting resource');
        return $_->{id};
    }

    # couldn't find it.  Create a new one
    $self->debug('creating new greedy resource');
    $result = $self->aws_do(
        'apigateway',
        'create-resource',
        {
            'rest-api-id' => $self->rest_api_id,
            'parent-id'   => $self->resource_id,
            'path-part'   => '{proxy+}',
        },
    );
    $self->debug('created new greedy resource');
    return $result->{id};
};

### methods

sub upload {
    my $self = shift;

    my $function_arn = $self->_upload_function;

    for my $resource_id ( $self->resource_id, $self->greedy_resource_id ) {
        $self->_create_method($resource_id);
        $self->_create_method_response($resource_id);
        $self->_create_integration( $function_arn, $resource_id );
        $self->_create_integration_response($resource_id);
    }
    $self->_stage;

    return ();
}

sub api_url {
    my $self = shift;

    return
          'https://'
        . $self->rest_api_id
        . '.execute-api.'
        . $self->region
        . '.amazonaws.com/'
        . $self->stage_name . '/'
        . $self->name;
}

sub _stage {
    my $self = shift;

    $self->aws_do(
        'apigateway',
        'create-deployment',
        {
            'rest-api-id' => $self->rest_api_id,
            'stage-name'  => $self->stage_name,
        }
    );
}

sub _create_method {
    my $self        = shift;
    my $resource_id = shift;

    my @identifiers = (
        'rest-api-id' => $self->rest_api_id,
        'resource-id' => $resource_id,
        'http-method' => 'ANY',
    );

    $self->debug('checking for existing method');

    # get the current method
    my $result = $self->aws->apigateway(
        'get-method', {@identifiers},
    );

    if ($result) {
        $self->debug('found existing method');
        return ();
    }

    $self->debug('putting new method');
    $self->aws_do(
        'apigateway',
        'put-method',
        {
            @identifiers,
            'authorization-type' => 'NONE',
        },
    );
    $self->debug('new method put');

    return ();
}

sub _create_method_response {
    my $self        = shift;
    my $resource_id = shift;

    my $identifiers = {
        'rest-api-id' => $self->rest_api_id,
        'resource-id' => $resource_id,
        'http-method' => 'ANY',
        'status-code' => 200,
    };

    $self->debug('checking for existing method response');

    # get the current method response
    my $result = $self->aws->apigateway(
        'get-method-response', $identifiers,
    );
    if ($result) {
        $self->debug('found existing method response');
        return ();
    }

    $self->debug('putting new method response');
    $self->aws_do(
        'apigateway',
        'put-method-response',
        $identifiers,
    );
    $self->debug('new method response put');

    return ();
}

sub _create_integration {
    my $self         = shift;
    my $function_arn = shift;
    my $resource_id  = shift;

    my $identifiers = {
        'rest-api-id' => $self->rest_api_id,
        'resource-id' => $resource_id,
        'http-method' => 'ANY',
    };

    # according the the documentation at https://docs.aws.amazon.com/cli/latest/reference/apigateway/put-integration.html
    # the uri has the form arn:aws:apigateway:{region}:{subdomain.service|service}:path|action/{service_api}
    # "lambda:path/2015-03-31/functions" is the {subdomain.service|service}:path|action for lambda functions
    my $uri
        = "arn:aws:apigateway:@{[ $self->region ]}:lambda:path/2015-03-31/functions/$function_arn/invocations";

    $self->debug('checking for existing integration');

    # get the current method response
    my $result = $self->aws->apigateway(
        'get-integration', $identifiers,
    );
    if ($result) {
        $self->debug('found existing integration');
        return ();
    }

    $self->debug('putting new integration');
    $self->aws_do(
        'apigateway',
        'put-integration',
        {
            %{$identifiers},
            type                      => 'AWS_PROXY',
            'integration-http-method' => 'POST',
            'credential'              => $self->_role_arn,
            uri                       => $uri,
        }
    );
    $self->debug('new integration put');

    return ();
}

sub _create_integration_response {
    my $self        = shift;
    my $resource_id = shift;

    my $identifiers = {
        'rest-api-id' => $self->rest_api_id,
        'resource-id' => $resource_id,
        'http-method' => 'ANY',
        'status-code' => 200,
    };

    $self->debug('checking for existing integration response');

    # get the current method response
    my $result = $self->aws->apigateway(
        'get-integration-response', $identifiers,
    );
    if ($result) {
        $self->debug('found existing integration response');
        return ();
    }

    $self->debug('putting new integration');
    $self->aws_do(
        'apigateway',
        'put-integration-response',
        {
            %{$identifiers},
            'selection-pattern' => q{},
        }
    );
    $self->debug('new integration put');

    return ();
}

sub _upload_function {
    my $self = shift;

    my $update_type = $self->update_type;
    my $region      = $self->region;

    # compute the arn based on the list in the AWS::Lambda 0.0.11
    # documentation
    my $v      = $region eq 'me-south-1' ? 3 : 5;
    my $layers = [
        "arn:aws:lambda:$region:445285296882:layer:perl-5-30-runtime:$v",
    ];

    for my $layer ( @{ $self->extra_layers } ) {
        if ( $layer
            =~ /(arn:[a-zA-Z0-9-]+:lambda:[a-zA-Z0-9-]+:\d{12}:layer:[a-zA-Z0-9-_]+)/aa
        ) {
            push @{$layers}, $layer;
            next;
        }

        if ( $layer eq 'paws' ) {

            # compute the arn based on the list in the AWS::Lambda 0.0.11
            # documentation
            my $pv = $region eq 'me-south-1' ? 3 : 4;
            push @{$layers},
                "arn:aws:lambda:$region:445285296882:layer:perl-5-30-paws:$pv";
            next;
        }

        die "Layer '$layer' is neither a known named layer nor a layer arn";
    }

    if ( $update_type eq 'create-function' ) {
        $self->debug('creating new function');
        my $result = $self->aws_do(
            'lambda',
            'create-function',
            {
                'function-name' => $self->name,
                'role'          => $self->_role_arn,
                'region'        => $region,
                'runtime'       => 'provided',
                'zip-file'      => $self->zip_file_blob,
                'handler'       => 'handler.handler',
                'layers'        => $layers,
                'timeout'       => $self->timeout,
                'memory-size'   => $self->memory_size,
            }
        );
        $self->debug('new function created');
        return $result->{FunctionArn};
    }

    $self->debug('updating function code');
    my $result = $self->aws_do(
        'lambda',
        'update-function-code',
        {
            'function-name' => $self->name,
            'zip-file'      => $self->zip_file_blob,
        }
    );
    $self->debug('function code updated');
    $self->debug('updating function configuration');
    $self->aws_do(
        'lambda',
        'update-function-configuration',
        {
            'function-name' => $self->name,
            'role'          => $self->_role_arn,
            'region'        => $region,
            'runtime'       => 'provided',
            'handler'       => 'handler.handler',
            'layers'        => $layers,
            'timeout'       => $self->timeout,
            'memory-size'   => $self->memory_size,
        }
    );
    $self->debug('function congifuration updated');
    return $result->{FunctionArn};
}

# just like $self->aws->$method but throws exception on error
sub aws_do {
    my $self   = shift;
    my $method = shift;

    my $aws    = $self->aws;
    my $result = $aws->$method(@_);

    return $result if defined $result;

    # uh oh, something went wrong, throw exception

    ## no critic (ProhibitPackageVars)
    my $code    = $AWS::CLIWrapper::Error->{Code};
    my $message = $AWS::CLIWrapper::Error->{Message};

    die "AWS CLI failure when calling $method $_[0] '$code': $message";
}

sub encode_json($) {
    return JSON::PP->new->ascii->canonical(1)->allow_nonref(1)->encode(shift);
}

sub debug {
    my $self = shift;
    return unless $ENV{AWS_LAMBDA_QUICK_DEBUG};
    for (@_) {
        print STDERR "$_\n" or die "Can't write to fh: $!";
    }
    return ();
}

sub just_update_function_code {
    my $self = shift;

    $self->aws_do(
        'lambda',
        'update-function-code',
        {
            'function-name' => $self->name,
            'zip-file'      => $self->zip_file_blob,
        },
    );

    return ();
}

1;

__END__

=head1 NAME

AWS::Lambda::Quick::Upload - upload for AWS::Lambda::Quick

=head1 DESCRIPTION

No user servicable parts.  See L<AWS::Lambda::Quick> for usage.

=head1 AUTHOR

Written by Mark Fowler B<mark@twoshortplanks.com>

Copyright Mark Fowler 2019.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AWS::Lambda::Quick>

=cut
