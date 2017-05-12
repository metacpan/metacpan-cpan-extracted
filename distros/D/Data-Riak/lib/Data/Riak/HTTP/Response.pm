package Data::Riak::HTTP::Response;
{
  $Data::Riak::HTTP::Response::VERSION = '2.0';
}

use strict;
use warnings;

use Moose;
use URI;
use HTTP::Headers::ActionPack 0.05;

use overload '""' => 'as_string', fallback => 1;

my $_deconstruct_parts;

has 'parts' => (
    is => 'ro',
    isa => 'ArrayRef[HTTP::Message]',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @parts = $_deconstruct_parts->( $self->http_response );
        return \@parts;
    }
);

has 'http_response' => (
    is => 'ro',
    isa => 'HTTP::Response',
    required => 1,
    handles => {
        code        => 'code',
        status_code => 'code',
        message     => 'content',
        value       => 'content',
        is_success  => 'is_success',
        is_error    => 'is_error',
        as_string   => 'as_string',
        header      => 'header',
        headers     => 'headers'
    }
);

$_deconstruct_parts = sub {
    my $message = shift;
    return () unless $message->content;
    my @parts = $message->parts;
    return $message unless @parts;
    return map { $_deconstruct_parts->( $_ ) } @parts;
};

with 'Data::Riak::Transport::Response';

sub create_results {
    my ($self, $riak, $request) = @_;

    return map {
        $self->_create_result($riak, $request, $_)
    } @{ $self->parts };
}

my %header_values = (
    etag          => 'etag',
    content_type  => 'content-type',
    vector_clock  => 'x-riak-vclock',
    last_modified => 'last_modified',
);

sub _create_result {
    my ($self, $riak, $request, $http_message) = @_;

    HTTP::Headers::ActionPack->new->inflate( $http_message->headers );

    my %result_args = (
        riak          => $riak,
        status_code   => $self->http_response->code, # FIXME: http specific
        value         => $http_message->content,
        (map {
            my $v = $http_message->header($header_values{$_});
            defined $v ? ($_ => $v) : ();
        } keys %header_values),
    );

    if ($request->result_does('Data::Riak::Result::WithLocation')) {
        $result_args{location} = $http_message->can('request')
            ? $http_message->request->uri
            : (URI->new( $http_message->header('location') )
                   || die 'Cannot determine location from ' . $http_message);
    }

    if ($request->result_does('Data::Riak::Result::WithLinks')) {
        my $links = $http_message->header('link');
        $result_args{links} = [map {
            Data::Riak::Link->from_link_header($_)
        } $links ? $links->iterable : ()],
    }

    return $request->new_result(\%result_args);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=head1 NAME

Data::Riak::HTTP::Response

=head1 VERSION

version 2.0

=head1 AUTHORS

=over 4

=item *

Andrew Nelson <anelson at cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
