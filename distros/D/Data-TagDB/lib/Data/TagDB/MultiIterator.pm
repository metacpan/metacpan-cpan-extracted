# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::MultiIterator;

use v5.10;
use strict;
use warnings;

use parent 'Data::TagDB::Iterator';

use Carp;

our $VERSION = v0.08;


sub new {
    my ($pkg, %opts) = @_;

    foreach my $required (qw(db iterators)) {
        croak 'Missing required member: '.$required unless defined $opts{$required};
    }

    return bless \%opts, $pkg;
}

sub next {
    my ($self) = @_;
    my $iterators = $self->{iterators};

    while (scalar @{$iterators}) {
        my $entry = $iterators->[0]->next;
        return $entry if defined $entry;
        $iterators->[0]->finish;
        shift(@{$iterators});
    }

    return undef;
}

sub finish {
    my ($self) = @_;
    foreach my $iter (@{$self->{iterators}}) {
        $iter->finish;
    }
    @{$self->{iterators}} = ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::MultiIterator - Work with Tag databases

=head1 VERSION

version v0.08

=head1 SYNOPSIS

    use Data::TagDB;

This is an interal package. See L<Data::TagDB::Iterator>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
