package Data::Riak::Request::LinkWalk;
{
  $Data::Riak::Request::LinkWalk::VERSION = '2.0';
}

use Moose;
use namespace::autoclean;

has params => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

sub as_http_request_args {
    my ($self) = @_;

    my $params = $self->params;
    my $params_str = '';

    for my $depth (@$params) {
        if(@{ $depth } == 2) {
            unshift @{ $depth }, $self->bucket_name;
        }
        my ($buck, $tag, $keep) = @{$depth};
        $params_str .= "$buck,$tag,$keep/";
    }

    return {
        method => 'GET',
        uri    => sprintf('buckets/%s/keys/%s/%s',
                          $self->bucket_name, $self->key, $params_str),
    };
}

sub _build_http_exception_classes {
    return {
        404 => Data::Riak::Exception::ObjectNotFound::,
    };
}

with 'Data::Riak::Request::WithObject',
     'Data::Riak::Request::WithHTTPExceptionHandling';

has '+result_class' => (
    default => Data::Riak::Result::Object::,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Request::LinkWalk

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
