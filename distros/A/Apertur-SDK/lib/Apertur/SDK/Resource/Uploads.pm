package Apertur::SDK::Resource::Uploads;

use strict;
use warnings;

use URI::Escape qw(uri_escape);

sub new {
    my ($class, %args) = @_;
    return bless { http => $args{http} }, $class;
}

sub list {
    my ($self, %params) = @_;
    my $qs = _build_query_string(%params);
    return $self->{http}->request('GET', "/api/v1/uploads$qs");
}

sub recent {
    my ($self, %params) = @_;
    my $qs = _build_query_string(%params);
    return $self->{http}->request('GET', "/api/v1/uploads/recent$qs");
}

sub _build_query_string {
    my (%params) = @_;
    my @parts;
    for my $key (sort keys %params) {
        next unless defined $params{$key};
        push @parts, uri_escape($key) . '=' . uri_escape($params{$key});
    }
    return @parts ? '?' . join('&', @parts) : '';
}

1;

__END__

=head1 NAME

Apertur::SDK::Resource::Uploads - Upload listing operations

=head1 DESCRIPTION

Lists and retrieves recent uploads across all sessions.

=head1 METHODS

=over 4

=item B<list(%params)>

Lists uploads with optional pagination (C<page>, C<pageSize>).

=item B<recent(%params)>

Returns recent uploads with optional C<limit>.

=back

=cut
