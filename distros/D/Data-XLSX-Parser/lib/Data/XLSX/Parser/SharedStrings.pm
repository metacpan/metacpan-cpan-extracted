package Data::XLSX::Parser::SharedStrings;
use strict;
use warnings;

use XML::Parser::Expat;
use Archive::Zip ();
use File::Temp;
use Carp;

sub new {
    my ($class, $archive) = @_;

    my $self = bless {
        _data      => [],

        _is_string => 0,
        _is_ph     => 0,
        _buf       => '',
    }, $class;

    my $fh = File::Temp->new( SUFFIX => '.xml' ) or confess "couldn't create temporary file: $!";

    my $handle = $archive->shared_strings or return $self;
    confess 'Failed to write temporary file: ', $fh->filename
        unless $handle->extractToFileNamed($fh->filename) == Archive::Zip::AZ_OK;

    my $parser = XML::Parser::Expat->new(Namespaces=>1);
    $parser->setHandlers(
        Start => sub { $self->_start(@_) },
        End   => sub { $self->_end(@_) },
        Char  => sub { $self->_char(@_) },
    );
    $parser->parse($fh);

    $self;
}

sub count {
    my ($self) = @_;
    scalar @{ $self->{_data} };
}

sub get {
    my ($self, $index) = @_;
    $self->{_data}->[$index];
}

sub _start {
    my ($self, $parser, $name, %attrs) = @_;
    $self->{_is_string} = 1 if $name eq 'si';
    $self->{_is_ph}     = 1 if $name eq 'rPh';
}

sub _end {
    my ($self, $parser, $name) = @_;

    if ($name eq 'si') {
        $self->{_is_string} = 0;
        push @{ $self->{_data} }, $self->{_buf};
        $self->{_buf} = '';
    }
    $self->{_is_ph} = 0 if $name eq 'rPh';
}

sub _char {
    my ($self, $parser, $data) = @_;
    $self->{_buf} .= $data if $self->{_is_string} && !$self->{_is_ph};
}

1;
__END__

=head1 NAME

Data::XLSX::Parser::SharedStrings - SharedStrings class of Data::XLSX::Parser

=head1 DESCRIPTION

Data::XLSX::Parser::SharedStrings parses the SharedStrings of the workbook and provides methods to get the shared string by the passed index and the count of contained shared strings.

=head1 METHODS

=head2 get

get the shared string by the passed index

=head2 count

get the count of contained shared strings.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut