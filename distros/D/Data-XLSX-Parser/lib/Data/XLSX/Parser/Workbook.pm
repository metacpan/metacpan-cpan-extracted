package Data::XLSX::Parser::Workbook;
use strict;
use warnings;

use XML::Parser::Expat;
use Archive::Zip ();
use File::Temp;
use Carp;

sub new {
    my ($class, $archive) = @_;

    my $self = bless [], $class;

    my $fh = File::Temp->new( SUFFIX => '.xml' ) or confess "couldn't create temporary file: $!";

    my $handle = $archive->workbook or confess "couldn't get handle to workbook archive: $!";;
    confess 'Failed to write temporary file: ', $fh->filename
        unless $handle->extractToFileNamed($fh->filename) == Archive::Zip::AZ_OK;

    my $parser = XML::Parser::Expat->new(Namespaces=>1);
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

sub sheet_rid {
    my ($self, $name) = @_;

    my ($meta) = grep { $_->{name} eq $name } @$self
        or do {carp ("didn't find $name in workbook's sheet names"); return;};

    return  $meta->{'id'};
}

sub sheet_id {
    my ($self, $name) = @_;

    my ($meta) = grep { $_->{name} eq $name } @$self
        or do {carp ("didn't find $name in workbook's sheet names"); return;};

     return $meta->{sheetId};
}

sub _start {
    my ($self, $parser, $el, %attr) = @_;
    push @$self, \%attr if $el eq 'sheet';
}

1;
__END__

=head1 NAME

Data::XLSX::Parser::Workbook - Workbook class of Data::XLSX::Parser

=head1 SYNOPSIS

    use Data::XLSX::Parser;
    
    # get sheet relation id with sheet name
    my $sheet_relation_id = $parser->workbook->sheet_rid( 'Sheet1' ) );
    
    # .. or get sheetId with sheet name
    my $sheet_id = $parser->workbook->sheet_id( 'Sheet1' ) );

=head1 DESCRIPTION

Data::XLSX::Parser::Workbook provides sheet Id getter methods to lookup sheetId and sheet relation Id by Sheetname


=head1 METHODS

=head2 names

get all sheet names from the workbook.

=head2 sheet_id

get sheet Id of sheet identified by sheet name.

=head2 sheet_rid

get sheet relation Id of sheet identified by sheet name.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut