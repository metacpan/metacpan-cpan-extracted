use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::ResultSet::Shortcut::AddColumn;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0108';

use parent 'DBIx::Class::Helper::ResultSet::Shortcut::AddColumns';
use Carp qw/confess/;
use experimental qw/signatures postderef/;

sub add_column($self, @args) {
    # If given single argument, fall back to DBIx::Class::Helper::ResultSet::Shortcut::AddColumns
    if(scalar @args == 1) {
        if(ref $args[0] eq 'ARRAY') {
            return $self->add_columns($args[0]);
        }
        else {
            return $self->add_columns([ $args[0] ]);
        }
    }
    # From here on we expect to expand @args to a hash
    if(scalar @args % 2 == 1) {
        confess "add_column given an un-even number of arguments"
    }
    my %args = @args;

    my %plus_select_args = ();
    my @plus_as_args = ();

    if(exists $args{'-as'}) {
        $plus_select_args{'-as'} = delete $args{'-as'};
    }
    if(exists $args{'-name'}) {
        push @plus_as_args => delete $args{'-name'};
    }

    if(scalar keys %args != 1) {
        confess sprintf("add_column has an unexpected number of keys (%d) before search: %s", scalar(keys %args), join(', ', keys %args));
    }

    %plus_select_args = (%plus_select_args, %args);
    return $self->search(undef, {
        '+select' => [\%plus_select_args],
        '+as' => \@plus_as_args,
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Helper::ResultSet::Shortcut::AddColumn - Short intro

=head1 VERSION

Version 0.0108, released 2020-11-29.

=head1 SOURCE

L<https://github.com/Csson/p5-DBIx-Class-Smooth>

=head1 HOMEPAGE

L<https://metacpan.org/release/DBIx-Class-Smooth>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
