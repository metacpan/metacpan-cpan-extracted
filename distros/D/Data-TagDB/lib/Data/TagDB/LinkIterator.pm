# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::LinkIterator;

use v5.10;
use strict;
use warnings;

use parent 'Data::TagDB::Iterator';

use Carp;

our $VERSION = v0.08;


sub new {
    my ($pkg, %opts) = @_;

    foreach my $required (qw(db query package tag_keys raw_keys)) {
        croak 'Missing required member: '.$required unless defined $opts{$required};
    }

    return bless \%opts, $pkg;
}

sub next {
    my ($self) = @_;
    my Data::TagDB $db = $self->db;
    my $row = $self->{query}->fetchrow_hashref;
    my %args;

    return undef unless defined $row;

    foreach my $key (keys %{$self->{tag_keys}}) {
        my $value = $row->{$self->{tag_keys}{$key}};
        next unless defined($value) && $value > 0;

        $args{$key} = $db->tag_by_dbid($value);
    }

    foreach my $key (keys %{$self->{raw_keys}}) {
        my $value = $row->{$self->{raw_keys}{$key}};
        next unless defined($value);

        $args{$key} = $value;
    }

    return $self->{package}->_new(%args, _row => $row, db => $db);
}

sub finish {
    my ($self) = @_;
    $self->{query}->finish;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::LinkIterator - Work with Tag databases

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
