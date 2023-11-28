package MyApp2;

use Dancer2;

=head1 NAME

MyApp - Dancing Web Service

=cut

use Dancer2::Plugin::OpenAPI;

our $VERSION = '0.1';

my %judge = (
    'Murphy' => {
        fullname => 'Mary Ann Murphy',
        seasons => [ 3..5, 6, 8..10 ],
    },
);

swagger_definition 'Judge' => {
    type => 'object',
    required => [ 'fullname' ],
    properties => {
        fullname => { type => 'string' },
        seasons  => { type => 'array', items => { type => 'integer' } },
    }
};

swagger_path {
    description => 'Returns information about a judge',
    parameters => [
        {
            name => 'judge_name',
            description => 'Last name of the judge',
        },
    ],
    responses => {
        404 => {
            template => sub { +{ error => "judge '@{[ shift ]}' not found" } },
            schema => {
                type => 'object',
                required => [ 'error' ],
                properties => {
                    error => { type => 'string' },
                }
            },
        },
        200 => {
            description => 'the judge information',
            example => {
                fullname => 'Mary Ann Murphy',
                seasons => [ 3..5, 6, 8..10 ],
            },
            schema => { '$ref' => "#/definitions/Judge" },
        },
    },
},
get '/judge/:judge_name' => sub {
    $judge{ param('judge_name') }
        ? swagger_template $judge{ param('judge_name') }
        : swagger_template 404, param('judge_name');
};

#swagger_auto_discover();

1;
