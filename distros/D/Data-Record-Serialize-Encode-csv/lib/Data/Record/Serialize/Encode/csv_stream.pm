package Data::Record::Serialize::Encode::csv_stream;

# ABSTRACT: encode a record as csv

use Moo::Role;

use namespace::clean;

our $VERSION = '0.03';


sub send {
    my $self = shift;
    $self->_csv->say( $self->fh, [ @{ $_[0] }{ @{ $self->output_fields } }  ]);
}

sub say {
    my $self = shift;
    $self->fh->say( @_ );
}

sub print {
    my $self = shift;
    $self->fh->print( @_ );
}

with 'Data::Record::Serialize::Role::Encode::CSV';
with 'Data::Record::Serialize::Role::Sink::Stream';









with 'Data::Record::Serialize::Role::EncodeAndSink';

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

Data::Record::Serialize::Encode::csv_stream - encode a record as csv

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'csv_stream', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::csv_stream> encodes a record as CSV (well
anything that L<Text::CSV> can write) and writes it to a stream.

It performs both the L<Data::Record::Serialize::Role::Encode> and
L<Data::Record::Serialize::Role::Sink> roles.

It is more efficient than coupling the L<Data::Record::Serialize::Encode::csv|csv>
encoder with the B<Data::Record::Serialize::Sink::stream|stream> sink.

=for Pod::Coverage encode
send
say
print

=head1 CONSTRUCTOR OPTIONS

=head2 Text::CSV Options

Please see L<Data::Record::Serialize::Role::Encode::CSV>.

=head2 Stream Options

Please see L<Data::Record::Serialize::Role::Sink::Stream>.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize-encode-csv@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize-Encode-csv

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize-encode-csv

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize-encode-csv.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize::Encode::csv|Data::Record::Serialize::Encode::csv>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
