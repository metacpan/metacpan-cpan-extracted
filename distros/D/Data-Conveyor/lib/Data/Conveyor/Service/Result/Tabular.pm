use 5.008;
use strict;
use warnings;

package Data::Conveyor::Service::Result::Tabular;
BEGIN {
  $Data::Conveyor::Service::Result::Tabular::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Text::Table;
use Data::Miscellany 'trim';
use parent 'Data::Conveyor::Service::Result';
__PACKAGE__->mk_array_accessors(qw(headers rows));

sub result_as_string {
    my $self = shift;
    unless ($self->rows_count) {
        return "No results\n";
    }
    my @fields = $self->headers;
    my $table  = Text::Table->new(@fields);
    $table->load($self->rows);
    $table;
}

# Given a LoH (list of hashes, a typical DBI result set), it populates the
# result object with those rows. It can also be a list of objects if those
# objects have methods that correspond to the headers.
sub set_from_rows {
    my ($self, %args) = @_;
    my ($did_set_headers, $count);
    my $limit  = $args{limit}       if defined $args{limit};
    my @fields = @{ $args{fields} } if defined $args{fields};
    for my $row (@{ $args{rows} }) {
        last if defined($limit) && ++$count > $limit;
        unless ($did_set_headers) {
            scalar @fields or @fields = sort keys %$row;
            $self->headers(@fields);
            $did_set_headers++;
        }
        my @values;
        for (@fields) {
            if (ref $row eq 'HASH') {
                push @values => $row->{$_};
            } elsif (UNIVERSAL::can($row, $_)) {
                push @values => $row->$_;
            } else {
                throw Error::Hierarchy::Internal::CustomMessage(
                    custom_message => "can't set field [$_] from row [$row]");
            }
        }
        $self->rows_push([ map { defined($_) ? $_ : '' } @values ]);
    }
    $self;
}
sub result { $_[0]->rows }

sub result_as_list_of_hashes {
    my $self = shift;
    my @result;
    my @headers = $self->headers;    # don't call this accessor for every row
    for my $row_ref ($self->rows) {
        my $index = 0;
        my %row_hash;
        for my $header (@headers) {
            $row_hash{$header} = $row_ref->[ $index++ ];
        }
        push @result => \%row_hash;
    }
    wantarray ? @result : \@result;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Service::Result::Tabular - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 result

FIXME

=head2 result_as_list_of_hashes

FIXME

=head2 result_as_string

FIXME

=head2 set_from_rows

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at L<http://github.com/hanekomu/Data-Conveyor>
and may be cloned from L<git://github.com/hanekomu/Data-Conveyor>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

