package AnyEvent::Processor::Conversion;
# ABSTRACT: Base class for conversion type subclasses
$AnyEvent::Processor::Conversion::VERSION = '0.006';
use Moose;

extends 'AnyEvent::Processor';

use Modern::Perl;


has reader => (
    is => 'rw', 
    does => 'MooseX::RW::Reader',
);

has writer => ( 
    is => 'rw',
    does => 'MooseX::RW::Writer',
);

has converter => ( is => 'rw', does => 'AnyEvent::Processor::Converter' );


sub run  {
    my $self = shift;
    $self->writer->begin();
    $self->SUPER::run();
    $self->writer->end();
};


sub process {
    my $self = shift;
    my $record = $self->reader->read();
    if ( $record ) {
        $self->SUPER::process();
        my $converter = $self->converter;
        my $converted_record = 
            $converter ? $converter->convert( $record ) : $record;
        unless ( $converted_record ) {
            # Conversion échouée mais il reste des enregistrements
            # print "NOTICE NON CONVERTIE #", $self->count(), "\n";
            return 1;
        }
        $self->writer->write( $converted_record );
        return 1;
    }
    return 0;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Processor::Conversion - Base class for conversion type subclasses

=head1 VERSION

version 0.006

=head1 ATTRIBUTES

=head2 reader

The L<MooseX::RW::Reader> from which reading something.

=head2 writer

The L<Moose::RW::Writer> in which writing something.

=head2 converter

Convert something read from the reader into something to write to the writer.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
