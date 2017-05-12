use strict;
use warnings;
use Try::Tiny;
use Test::More tests => 9;
use Dancer::Plugin::BeforeRoute;

my @cases = (
    {   subject => "missing method",
        path    => "/foobar",
        subref  => sub { },
        error   => qr/missing method/,
    },
    {   subject => "single method",
        method  => "get",
        path    => "/foobar",
        subref  => sub { },
    },
    {   subject => "multiple methods",
        methods => [ "get", "post", "put", "del" ],
        path    => "/foobar",
        subref => sub { },
    },
    {   subject => "missing path",
        methods => "put",
        subref  => sub { },
        error   => qr/missing path/,
    },
    {   subject => "missing subref",
        methods => "del",
        path    => "/foobar",
        error   => qr/missing a subref/,
    },
);

foreach my $case (@cases) {
    try {
        my $methods = $case->{method} || $case->{methods};
        my ( $path, $subref, @methods )
            = Dancer::Plugin::BeforeRoute::_args( $methods,
            @$case{qw( path subref )} );
        if ( $case->{method} ) {
            is_deeply [ $case->{method} ], \@methods,
                "$case->{subject} - method ok";
        }
        elsif ( $case->{methods} ) {
            is_deeply $case->{methods}, \@methods,
                "$case->{subject} - methods ok";
        }
        is $case->{path},   $path,   "$case->{subject} - path ok";
        is $case->{subref}, $subref, "$case->{subject} - got a subref";
    }
    catch {
        my $error = $_;
        like $error, $case->{error}, $case->{subject};
    }
}
