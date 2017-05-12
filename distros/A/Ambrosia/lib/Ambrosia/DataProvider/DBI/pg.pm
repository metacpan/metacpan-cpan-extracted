package Ambrosia::DataProvider::DBI::pg;
use strict;
use warnings;

use Ambrosia::Meta;
class sealed
{
    extends => [qw/Ambrosia::DataProvider::DBIDriver/],
};

our $VERSION = 0.010;

sub _name
{
    'Pg';
}

sub _make_limit
{
    my $a = shift;
    return '' unless $a && scalar @$a && (scalar @$a == 2 || $a->[0]);
    return 'LIMIT ' . join ',', map {int($_)} grep {defined $_} @$a;
}

1;

__END__

=head1 NAME

Ambrosia::DataProvider::DBI::Pg - This class extends L<Ambrosia::DataProvider::DBIDriver>.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

See L<Ambrosia::DataProvider>.

=head1 DESCRIPTION

C<Ambrosia::DataProvider::DBI::Pg> extends L<Ambrosia::DataProvider::DBIDriver>.

=cut

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
