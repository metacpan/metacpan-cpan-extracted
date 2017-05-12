package Data::Riak::Role::Frontend;
{
  $Data::Riak::Role::Frontend::VERSION = '2.0';
}

use Moose::Role;
use Class::Load 'load_class';
use namespace::autoclean;

has transport => (
    is       => 'ro',
    does     => 'Data::Riak::Transport',
    required => 1,
    handles  => {
        base_uri => 'base_uri'
    }
);

has request_classes => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Str]',
    builder => '_build_request_classes',
    handles => {
        _available_request_classes => 'values',
        request_class_for          => 'get',
        has_request_class_for      => 'exists',
    },
);

has bucket_class => (
    is      => 'ro',
    isa     => 'ClassName',
    builder => '_build_bucket_class',
    handles => {
        _new_bucket => 'new',
    },
);

sub BUILD {}
after BUILD => sub {
    my ($self) = @_;

    load_class $_
        for $self->_available_request_classes;
};

sub _create_request {
    my ($self, $args) = @_;

    my %args_copy = %{ $args };
    my $type = delete $args_copy{type};

    confess sprintf 'Unknown request class %s', $type
        unless $self->has_request_class_for($type);

    return $self->request_class_for($type)->new(\%args_copy);
}

sub bucket {
    my ($self, $bucket_name) = @_;
    return $self->_new_bucket({
        riak => $self,
        name => $bucket_name,
    });
}

sub ping {
    my ($self, $opts) = @_;

    return $self->send_request({
        %{ $opts || {} },
        type => 'Ping',
    });
}

sub status {
    my ($self, $opts) = @_;

    return $self->send_request({
        %{ $opts || {} },
        type => 'Status',
    });
}

sub _buckets {
    my ($self, $opts) = @_;

    return $self->send_request({
        %{ $opts || {} },
        type => 'ListBuckets',
    });
}

sub resolve_link {
    my ($self, $link, $opts) = @_;
    $self->bucket($link->bucket)->get($link->key => $opts);
}

sub linkwalk {
    my ($self, $args) = @_;
    my $object = delete $args->{object} || confess 'You must have an object to linkwalk';
    my $bucket = delete $args->{bucket} || confess 'You must have a bucket for the original object to linkwalk';

    return $self->send_request({
        %{ $args },
        type        => 'LinkWalk',
        bucket_name => $bucket,
        key         => $object,
    });
}

1;

__END__

=pod

=head1 NAME

Data::Riak::Role::Frontend

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
