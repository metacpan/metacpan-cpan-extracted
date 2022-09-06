package Data::Record::Serialize::Encode::csv;

# ABSTRACT: encode a record as csv

use Moo::Role;

use namespace::clean;

our $VERSION = '0.02';

with 'Data::Record::Serialize::Role::Encode::CSV';

sub encode {
    my $self = shift;
    $self->_csv->combine( @{ $_[0] }{ @{ $self->output_fields } } );
    $self->_csv->string;
}






with 'Data::Record::Serialize::Role::Encode';

1;

#
# This file is part of Data-Record-Serialize-Encode-csv
#
# This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Data::Record::Serialize::Encode::csv - encode a record as csv

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'csv', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::csv> encodes a record as CSV (well
anything that L<Text::CSV> can write).

It performs the L<Data::Record::Serialize::Role::Encode> role. If the data sink
is a stream, try L<Data::Record::Serialize::Encode::csv_stream|csv_stream>; it
provides better performance using L<Text::CSV>'s native output to filehandles.

=for Pod::Coverage encode

=head1 CONSTRUCTOR OPTIONS

=head2 Text::CSV Options

Please see L<Data::Record::Serialize::Role::Encode::CSV>.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize-encode-csv@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize-Encode-csv

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize-encode-csv

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize-encode-csv.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
