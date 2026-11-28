package DBIx::QuickORM::JoinRow;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;

use Object::HashBase qw{
    +aliases
    +rows
    <data
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::JoinRow - One row of a join: its component rows and raw data.

=head1 DESCRIPTION

A row fetched through a join (L<DBIx::QuickORM::Source::Join>). It holds the
row of each component, built with that table's row class, and the fetched
values. It has no write methods, so write through the component rows.

=head1 SYNOPSIS

    my $jrow  = $orm->handle('posts')->join('users')->first;
    my $post  = $jrow->row('posts');
    my $name  = $jrow->row('users')->field('name');
    my @names = $jrow->aliases;                 # ('posts', 'users')
    my $title = $jrow->data->{'posts.title'};

=head1 ATTRIBUTES

All three are required at construction, and one of the wrong shape croaks.

=over 4

=item $data = $jrow->data

The fetched values as a hashref keyed C<component.field>.

=item aliases => \@names

=item rows => {$name => $row_or_undef}

Read through the C<aliases> and C<row> methods.

=back

=cut

sub init {
    my $self = shift;
    croak "'aliases' must be an arrayref" unless ref($self->{+ALIASES}) eq 'ARRAY';
    croak "'rows' must be a hashref"      unless ref($self->{+ROWS}) eq 'HASH';
    croak "'data' must be a hashref"      unless ref($self->{+DATA}) eq 'HASH';
}

=head1 PUBLIC METHODS

=over 4

=item @names = $jrow->aliases

The component names, in join order.

=back

=cut

sub aliases { @{$_[0]->{+ALIASES}} }

=pod

=over 4

=item $row = $jrow->row($name)

The component's row, or undef when a left join matched nothing. Croaks for a
name that is not a component.

=back

=cut

sub row {
    my $self = shift;
    my ($name) = @_;
    croak "The join has no component named '" . ($name // 'undef') . "'" unless defined($name) && grep { $_ eq $name } @{$self->{+ALIASES}};
    return $self->{+ROWS}->{$name};
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
