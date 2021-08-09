package Courriel::Role::Streams;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.49';

use Courriel::Types qw( Streamable );
use Params::ValidationCompiler qw( validation_for );

use Moose::Role;

{
    my $validator = validation_for(
        params        => [ output => { type => Streamable } ],
        named_to_list => 1,
    );

    sub stream_to {
        my $self = shift;
        my ($output) = $validator->(@_);

        $self->_stream_to($output);

        return;
    }
}

sub as_string {
    my $self = shift;

    my $string = q{};

    $self->stream_to( output => $self->_string_output( \$string ) );

    return $string;
}

sub _string_output {
    my $self      = shift;
    my $stringref = shift;

    my $string = q{};
    return sub { ${$stringref} .= $_ for @_ };
}

1;
