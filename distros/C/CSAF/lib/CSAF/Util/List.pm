package CSAF::Util::List;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;

use overload '@{}' => \&to_array, fallback => 1;

has items => (is => 'rw', default => sub { [] });

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;

    return {items => \@args} if @args > 0;    # TODO
    return $class->$orig(@args);
};

sub size { scalar @{shift->items} }

sub each {

    my ($self, $callback) = @_;

    return @{$self->items} unless $callback;

    my $idx = 0;
    $_->$callback($idx++) for @{$self->items};

    return $self;

}

sub grep {
    my ($self, $callback) = @_;
    return $self->new(grep { $_->$callback(@_) } @{$self->items});
}

sub map {
    my ($self, $callback) = @_;
    return $self->new(map { $_->$callback(@_) } @{$self->items});
}


sub to_array { [@{shift->items}] }

sub item { push @{shift->items}, shift }
sub add  { shift->item(@_) }

sub first { shift->items->[0] }
sub last  { shift->items->[-1] }
sub join  { join($_[1] // '', @{$_[0]->items}) }

sub TO_JSON { [@{shift->items}] }

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Util::List - (Mojo like) collection utility

=head1 SYNOPSIS

    use CSAF::Util::List;
    my $collection = CSAF::Util::List->new( qw[foo bar baz] );


=head1 DESCRIPTION

L<CSAF::Util::List> is a collection utility.


=head2 METHODS

=over

=item TO_JSON

Alias for L</"to_array">.

=item add

Alias for L</"item">.

=item each

Evaluate callback for each element in collection.

    foreach my $item ($c->each) {
        [...]
    }

    my $collection = $c->each(sub {...});

    $c->each(sub {
        my ($value, $idx) = @_;
        [...]
    });

=item first

Get the first element of collection.

=item grep

Filter items.

    my $filtered = $c->grep(sub { $_ eq 'foo' });

=item item

Add a new item in collection.

    $c->item('foo');
    $c->item(sub {...});

=item items

Get the list of collection items.

=item join

Join elements in collection.

    $c->join(', ');

=item last

Get the last element of collection.

=item map

Evaluate the callback and create a new collection.

    CSAF::Util::List->new(1,2,3)->map(sub { $_ * 2 });

=item new

Create a new collection.

    my $c = CSAF::Util::List->new( [foo bar baz] );

=item size

Number of item elements.

=item to_array

Return the collection array.

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CSAF/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CSAF>

    git clone https://github.com/giterlizzi/perl-CSAF.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
