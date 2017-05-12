package MyURI;

use parent 'URI::SmartURI';

sub mtfnpy {
    my $uri = shift;
    $uri->query_form([ $uri->query_form, qw(foo bar) ]);
    $uri
}

1;
