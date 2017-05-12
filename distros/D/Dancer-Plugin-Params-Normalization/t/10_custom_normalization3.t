use strict;
use warnings;

use Test::More;
use Dancer::Test;

{
package My::Normalization3;
use strict;
use warnings;
use base qw(Dancer::Plugin::Params::Normalization::Abstract);

#set the trim_filter
my $trim_filter = sub {
    return scalar($_[0] =~ s/^\s+|\s+$//g)
};

sub normalize {
    my ($self, $params) = @_;
    $trim_filter->($_) for values %$params;
    return $params;
    }
}

plan tests => 1;

{
    package Webservice;
    use Dancer;

    BEGIN {
        set plugins => {
            'Params::Normalization' => {
                method => 'My::Normalization3',
            },
        };
    }
    use Dancer::Plugin::Params::Normalization;

    get '/foo' => sub {
     return params->{'test'};
    };
}

my $response = dancer_response GET => '/foo', { params => {test => ' 5  ' } };
is($response->{content}, 5);

1;
