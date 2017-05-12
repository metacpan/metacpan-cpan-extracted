package DBIx::Class::InflateColumn::IP;

use warnings;
use strict;
use 5.008001;

our $VERSION = '0.02003';

use base qw/DBIx::Class/;
__PACKAGE__->mk_classdata(ip_format => 'addr');
__PACKAGE__->mk_classdata(ip_class  => 'NetAddr::IP');

=encoding utf-8

=head1 NAME

DBIx::Class::InflateColumn::IP - Auto-create NetAddr::IP objects from columns.

=head1 SYNOPSIS

Load this component and declare columns as IP addresses with the
appropriate format.

    package Host;
    __PACKAGE__->load_components(qw/InflateColumn::IP Core/);
    __PACKAGE__->add_columns(
        ip_address => {
            data_type => 'bigint',
            is_nullable => 0,
            is_ip => 1,
            ip_format => 'numeric',
        }
    );

    package Network;
    __PACKAGE__->load_components(qw/InflateColumn::IP Core/);
    __PACKAGE__->add_columns(
        address => {
            data_type => 'varchar',
            size        => 18
            is_nullable => 0,
            is_ip => 1,
            ip_format => 'cidr',
        }
    );

Then you can treat the specified column as a NetAddr::IP object.

    print 'IP address: ', $host->ip_address->addr;
    print 'Address type: ', $host->ip_address->iptype;

DBIx::Class::InflateColumn::IP supports a limited amount of
auto-detection of the format based on the column type. If the type
begins with C<int> or C<bigint>, it's assumed to be numeric, while
C<inet> and C<cidr> (as used by e.g. PostgreSQL) are assumed to be
C<cidr> format.

=head1 METHODS

=head2 ip_class

=over

=item Arguments: $class

=back

Gets/sets the address class that the columns should be inflated into.
The default class is NetAddr::IP.

=head2 ip_format

=over

=item Arguments: $format

=back

Gets/sets the name of the method used to deflate the address for the
database. This must return a value suitable for C<$ip_class->new(); The
default format is C<addr>, which returns the address in dotted-quad
notation. See L<NetAddr::IP/Methods> for suitable values.

=head2 register_column

Chains with L<DBIx::Class::Row/register_column>, and sets up IP address
columns appropriately. This would not normally be called directly by end
users.

=cut

sub register_column {
    my ($self, $column, $info, @rest) = @_;
    $self->next::method($column, $info, @rest);

    return unless defined $info->{'is_ip'};

    my $ip_format = $info->{ip_format} || _default_format($info->{data_type})
        || $self->ip_format || 'addr';
    my $ip_class = $info->{ip_class} || $self->ip_class || 'NetAddr::IP';

    eval "use $ip_class";
    $self->throw_exception("Error loading $ip_class: $@") if $@;
    $self->throw_exception("Format '$ip_format' not supported by $ip_class")
        unless $ip_class->can($ip_format);

    $self->inflate_column(
        $column => {
            inflate => sub { return $ip_class->new(shift); },
            deflate => sub { return scalar shift->$ip_format; },
        }
    );
}

my @format_map = (
  { type => qr/^(?:big)?int/i, format => 'numeric' },
  { type => qr{^(?:inet|cidr)$}i, format => 'cidr' },
);

sub _default_format {
    my ($type) = @_;

    for my $match (@format_map) {
        return $match->{format} if $type =~ $match->{type};
    }
}

=head1 AUTHOR

Dagfinn Ilmari Mannsåker, C<< <ilmari at ilmari.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbix-class-inflatecolumn-ip at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-InflateColumn-IP>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::InflateColumn::IP

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-InflateColumn-IP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-InflateColumn-IP>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-InflateColumn-IP>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-InflateColumn-IP>

=back

=head1 SEE ALSO

L<DBIx::Class>, L<NetAddr::IP>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Dagfinn Ilmari Mannsåker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of DBIx::Class::InflateColumn::IP
