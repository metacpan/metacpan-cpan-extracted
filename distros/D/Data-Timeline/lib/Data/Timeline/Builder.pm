use 5.008;
use strict;
use warnings;

package Data::Timeline::Builder;
our $VERSION = '1.100860';
# ABSTRACT: Base class for time line builders
use Data::Timeline;
use Data::Timeline::Entry;
use parent qw(Class::Accessor::Complex Class::Accessor::Constructor);
__PACKAGE__
    ->mk_constructor
    ->mk_abstract_accessors(qw(create));

sub make_timeline {
    my $self = shift;
    Data::Timeline->new(@_);
}

sub make_entry {
    my $self = shift;
    Data::Timeline::Entry->new(@_);
}
1;


__END__
=pod

=for test_synopsis my @entries;

=head1 NAME

Data::Timeline::Builder - Base class for time line builders

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

    Data::Timeline::Builder->new;

    package Data::Timeline::SVK;
    use base 'Data::Timeline::Builder';

    sub create {
        my $self = shift;
        my $timeline = $self->make_timeline;
        for (@entries) {
            # ...
            $timeline->entries_push($self->make_entry(
                timestamp   => '...',
                description => '...',
                type        => 'svk',
            ));
        }
        $timeline;
    }

=head1 DESCRIPTION

This is a base class for time line builders. Subclasses need to implement the
C<create()> method.

=head1 METHODS

=head2 make_entry

FIXME

=head2 make_timeline

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

