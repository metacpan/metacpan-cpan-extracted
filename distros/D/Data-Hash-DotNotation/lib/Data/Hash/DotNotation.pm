package Data::Hash::DotNotation;
use strict;
use warnings;

our $VERSION = '1.02';

use Moose;
use Carp;

=head1 NAME

Data::Hash::DotNotation - Convenient representation for nested Hash structures

=head1 SYNOPSYS

    use Data::Hash::DotNotation;

    my $dn = Data::Hash::DotNotation->new({
            name => 'Gurgeh',
            planet  => 'earth',
            score   => {
                contact => 10,
                scrabble => 20,
            },
        });

    print $dn->get('score.contact');

=head1 METHODS

=cut

has 'data' => (
    is      => 'rw',
    default => sub { {}; },
);

=head2 get

=cut

sub get {
    my $self = shift;
    my $name = shift or croak "No name given";
    return $self->_get($name);
}

=head2 set

=cut

sub set {
    my $self  = shift;
    my $name  = shift or croak 'No name given';
    my $value = shift;

    $self->_set($name, $value);

    return $value;
}

=head2 key_exists

=cut

sub key_exists {
    my $self = shift;
    my $name = shift;
    my $data = $self->data;

    my @parts = split(/\./, $name);
    my $node = pop @parts;

    while ($data and (my $section = shift @parts)) {
        if (ref $data->{$section} eq 'HASH') {
            $data = $data->{$section};
        } else {
            return;
        }
    }

    return exists $data->{$node};
}

sub _get {
    my $self = shift;
    my $name = shift;
    my $data = $self->data;

    my @parts = split(/\./, $name);
    my $node = pop @parts;

    while ($data and (my $section = shift @parts)) {
        if (ref $data->{$section} eq 'HASH') {
            $data = $data->{$section};
        } else {
            return;
        }
    }

    if ($data and exists $data->{$node}) {
        return $data->{$node};
    }

    return;
}

sub _set {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;

    unless ($self->data) {
        $self->data({});
    }

    my @tarts = split(/\./, $name);
    my $node = pop @tarts;

    my $current_location = $self->data;
    foreach my $section (@tarts) {
        $current_location->{$section} //= {};
        $current_location = $current_location->{$section};
    }

    if (defined($value)) {
        $current_location->{$node} = $value;
    } else {
        delete $current_location->{$node};
    }

    return $self->data;
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 DEPENDENCIES

=over 4

=item L<Moose>

=back

=head1 SOURCE CODE

L<GitHub|https://github.com/binary-com/perl-Data-Hash-DotNotation>

=head1 AUTHOR

binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-moosex-role-registry at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Hash-DotNotation>.
We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Hash::DotNotation

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Hash-DotNotation>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Hash-DotNotation>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Hash-DotNotation>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Hash-DotNotation/>

=back

=cut

1;

