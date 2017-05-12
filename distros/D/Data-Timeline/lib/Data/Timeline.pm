use 5.008;
use strict;
use warnings;

package Data::Timeline;
our $VERSION = '1.100860';
# ABSTRACT: Time line represented as an object
use parent qw(Class::Accessor::Complex Class::Accessor::Constructor);
__PACKAGE__
    ->mk_constructor
    ->mk_array_accessors(qw(entries));

sub merge_timeline {
    my ($self, $timeline) = @_;
    $self->entries(sort { $a->timestamp <=> $b->timestamp }
          ($self->entries, $timeline->entries));
    $self;    # for chaining
}

sub filter_timeline_by_type {
    my ($self, $type) = @_;
    Data::Timeline->new(entries => grep { $_->type eq $type } $self->entries);
}

sub filter_timeline_by_date {
    my ($self, $from, $to) = @_;
    Data::Timeline->new(
        entries => grep { ($from <= $_->timestamp) && ($_->timestamp <= $to) }
          $self->entries);
}
1;


__END__
=pod

=for test_synopsis my $other_timeline;

=head1 NAME

Data::Timeline - Time line represented as an object

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

    my $timeline = Data::Timeline->new;
    $timeline->entries_push(Data::Timeline::Entry->new(
        # ...
    ));
    $timeline->merge_timeline($other_timeline);

=head1 DESCRIPTION

This class represents a time line, which is a collection of time line entry
objects (see L<Data::Timeline::Entry>).

=head1 METHODS

=head2 filter_timeline_by_date

FIXME

=head2 filter_timeline_by_type

FIXME

=head2 merge_timeline

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Timeline>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Timeline/>.

The development version lives at
L<http://github.com/hanekomu/Data-Timeline/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

