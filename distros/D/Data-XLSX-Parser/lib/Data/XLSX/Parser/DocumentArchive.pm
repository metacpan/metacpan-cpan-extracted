package Data::XLSX::Parser::DocumentArchive;
use strict;
use warnings;
use Carp;

use Archive::Zip;

sub new {
    my ($class, $filename) = @_;

    my $zip = Archive::Zip->new;
    if ($zip->read($filename) != Archive::Zip::AZ_OK) {
        confess "couldn't open file: $filename $!";
    }

    bless {
        _zip => $zip,
    }, $class;
}

sub workbook {
    my ($self) = @_;
    $self->{_zip}->memberNamed('xl/workbook.xml');
}

sub sheet {
    my ($self, $path) = @_;
    # only add xl/ if not already there, as some tools add absolute paths in relations
    $path = sprintf ('xl/%s', $path) unless $path =~ /^xl\//;
    $self->{_zip}->memberNamed($path);
}

sub shared_strings {
    my ($self) = @_;
    $self->{_zip}->memberNamed('xl/sharedStrings.xml');
}

sub styles {
    my ($self) = @_;
    $self->{_zip}->memberNamed('xl/styles.xml');
}

sub relationships {
    my ($self) = @_;
    $self->{_zip}->memberNamed('xl/_rels/workbook.xml.rels');
}

1;
__END__

=head1 NAME

Data::XLSX::Parser::DocumentArchive - DocumentArchive class of Data::XLSX::Parser

=head1 DESCRIPTION

Data::XLSX::Parser::DocumentArchive reads the xlsx archive file and provides getter methods to the most relevant parts of the archive.


=head1 METHODS

=head2 workbook

get workbook file from archive.

=head2 sheet

get named sheet file from archive.

=head2 shared_strings

get sharedStrings file from archive.

=head2 styles

get styles file from archive.

=head2 relationships

get main relationships file from archive.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut