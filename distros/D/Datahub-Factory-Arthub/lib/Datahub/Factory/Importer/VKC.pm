package Datahub::Factory::Importer::VKC;

use Datahub::Factory::Sane;

our $VERSION = '1.00';

use Moo;
use Catmandu;
use namespace::clean;

with 'Datahub::Factory::Importer';

sub _build_importer {
    my $self = shift;
}

1;
__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::VKC - Import data from the L<CollectiveAccess|http://collectiveaccess.org/> instance of the L<VKC|http://www.vlaamsekunstcollectie.be/>

=head1 SYNOPSIS

    use Datahub::Factory::Importer::VKC;
    use Data::Dumper qw(Dumper);

    my $vkc = Datahub::Factory::Importer::VKC->new(
    );

    $vkc->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

Datahub::Factory::Importer::VKC uses L<Catmandu|http://librecat.org/Catmandu/> to fetch a list of records
from the  L<CollectiveAccess|http://collectiveaccess.org/> instance of the L<VKC|http://www.vlaamsekunstcollectie.be/>.
It returns an L<Importer|Catmandu::Importer>.

=head1 PARAMETERS

=over


=back

=head1 ATTRIBUTES

=over

=item C<importer>

A L<Importer|Catmandu::Importer> that can be used in your script.

=back

=head1 AUTHOR

Pieter De Praetere E<lt>pieter at packed.be E<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Datahub::Factory>
L<Datahub::Factory::CollectiveAccess>
L<Catmandu>

=cut
