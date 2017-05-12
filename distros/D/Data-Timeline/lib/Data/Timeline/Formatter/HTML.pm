use 5.008;
use strict;
use warnings;

package Data::Timeline::Formatter::HTML;
our $VERSION = '1.100860';
# ABSTRACT: Print time line entry types side-by-side in an HTML table
use HTML::Table;
use parent qw(Data::Timeline::Formatter);
__PACKAGE__->mk_array_accessors(qw(columns));

sub format {
    my ($self, $timeline) = @_;
    my $table = HTML::Table->new(-head => [ 'timestamp', $self->columns ],);
    for my $entry ($timeline->entries) {
        my @row = (sprintf "%s" => $entry->timestamp);
        for my $col_type ($self->columns) {
            if ($entry->type eq $col_type) {
                push @row => $entry->description;
            } else {
                push @row => '';
            }
        }
        $table->addRow(@row);
    }
    $table->print;
}
1;


__END__
=pod

=for test_synopsis my $timeline;

=head1 NAME

Data::Timeline::Formatter::HTML - Print time line entry types side-by-side in an HTML table

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

    Data::Timeline::Formatter::HTML->new(
        columns => [ qw(iscrobbler svk) ],
    )->format($timeline);

=head1 DESCRIPTION

This class is a time line formatter. It takes a time line containing entries
of one or more entry types and a column definition. The column definition says
for each column which type of entries it should contain. The formatter's
C<format()> method will then print a simple HTML table containing the
requested columns, with a column for the timestamp at the beginning.

The column definition is a list of entry type strings. pairs. So for the
example in the synopsis, the first column would contain the timestamp, the
second column would contain C<iscrobbler> entries, produced by
L<Data::Timeline::IScrobbler>, and the third column would contain C<svk>
entries, produced by L<Data::Timeline::SVK>.

=head1 METHODS

=head2 format

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

