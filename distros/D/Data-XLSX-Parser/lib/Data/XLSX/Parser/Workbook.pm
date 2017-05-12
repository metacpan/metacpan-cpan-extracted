package Data::XLSX::Parser::Workbook;
use strict;
use warnings;

use XML::Parser::Expat;
use Archive::Zip ();
use File::Temp;

sub new {
    my ($class, $archive) = @_;

    my $self = bless [], $class;

    my $fh = File::Temp->new( SUFFIX => '.xml' );

    my $handle = $archive->workbook;
    die 'Failed to write temporally file: ', $fh->filename
        unless $handle->extractToFileNamed($fh->filename) == Archive::Zip::AZ_OK;

    my $parser = XML::Parser::Expat->new;
    $parser->setHandlers(
        Start => sub { $self->_start(@_) },
        End   => sub {},
        Char  => sub {},
    );
    $parser->parse($fh);

    $self;
}

sub names {
    my ($self) = @_;
    map { $_->{name} } @$self;
}

sub sheet_id {
    my ($self, $name) = @_;

    my ($meta) = grep { $_->{name} eq $name } @$self
        or return;

    if ($meta->{'r:id'}) {
        (my $r = $meta->{'r:id'}) =~ s/^rId//;
        return $r;
    }
    else {
        return $meta->{sheetId};
    }
}

sub _start {
    my ($self, $parser, $el, %attr) = @_;
    push @$self, \%attr if $el eq 'sheet';
}

1;
