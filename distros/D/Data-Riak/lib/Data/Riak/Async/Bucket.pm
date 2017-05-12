package Data::Riak::Async::Bucket;
{
  $Data::Riak::Async::Bucket::VERSION = '2.0';
}

use Moose;
use JSON 'decode_json';
use namespace::autoclean;

with 'Data::Riak::Role::Bucket';

sub remove_all {
    my ($self, $opts) = @_;

    my ($cb, $error_cb) = map { $opts->{$_} } qw(cb error_cb);
    $self->list_keys({
        error_cb => $error_cb,
        cb       => sub {
            my ($keys) = @_;
            return $cb->() unless ref $keys eq 'ARRAY' && @$keys;

            my %keys = map { ($_ => 1) } @{ $keys };
            for my $key (@{ $keys }) {
                $self->remove($key, {
                    error_cb => $error_cb,
                    cb       => sub {
                        delete $keys{$key};
                        $cb->() if !keys %keys;
                    },
                });
            }
        },
    });

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Async::Bucket

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
