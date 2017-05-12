package Data::XLSX::Parser::DocumentArchive;
use strict;
use warnings;

use Archive::Zip;

sub new {
    my ($class, $filename) = @_;

    my $zip = Archive::Zip->new;
    if ($zip->read($filename) != Archive::Zip::AZ_OK) {
        die "Cannot open file: $filename";
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
    $self->{_zip}->memberNamed(sprintf 'xl/%s', $path);
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
