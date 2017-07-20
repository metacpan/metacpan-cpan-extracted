package MAB2::Parser::XML;

our $VERSION = '0.20';

use strict;
use warnings;
use Carp qw<croak>;
use XML::LibXML::Reader;


sub new {
    my $class = shift;
    my $input  = shift;

    my $self = {
        filename   => undef,
        rec_number => 0,
        xml_reader => undef,
    };

    # check for file or filehandle
    my $ishandle = eval { fileno($input); };
    if ( !$@ && defined $ishandle ) {
        binmode $input; # drop all PerlIO layers, as required by libxml2
        my $reader = XML::LibXML::Reader->new( IO => $input )
            or croak "cannot read from filehandle $input\n";
        $self->{filename}   = scalar $input;
        $self->{xml_reader} = $reader;
    }
    elsif ( defined $input && $input !~ /\n/ && -e $input ) {
        my $reader = XML::LibXML::Reader->new( location => $input )
            or croak "cannot read from file $input\n";
        $self->{filename}   = $input;
        $self->{xml_reader} = $reader;
    }
    elsif ( defined $input && length $input > 0 ) {
        my $reader = XML::LibXML::Reader->new( string => $input )
            or croak "cannot read XML string $input\n";
        $self->{xml_reader} = $reader;
    }
    else {
        croak "file, filehande or string $input does not exists";
    }
    return ( bless $self, $class );
}


sub next {
    my $self = shift;
    if ( $self->{xml_reader}->nextElement('datensatz') ) {
        $self->{rec_number}++;
        my $record = _decode( $self->{xml_reader} );
        my ($id) = map { $_->[-1] } grep { $_->[0] =~ '001' } @{$record};
        return { _id => $id, record => $record };
    }
    return;
}


sub _decode {
    my $reader = shift;
    my @record;

    # get all field nodes from MAB2 XML record;
    foreach my $field_node (
        $reader->copyCurrentNode(1)->getChildrenByTagName('feld') )
    {
        my @field;

        # get field tag number
        my $tag = $field_node->getAttribute('nr');
        my $ind = $field_node->getAttribute('ind') // '';
        
        # ToDo: textContent ignores </tf> and <ns>

        # Check for data or subfields
        if ( my @subfields = $field_node->getChildrenByTagName('uf') ) {
            push( @field, ( $tag, $ind ) );

            # get all subfield nodes
            foreach my $subfield_node (@subfields) {
                my $subfield_code = $subfield_node->getAttribute('code');
                my $subfield_data = $subfield_node->textContent;
                push( @field, ( $subfield_code, $subfield_data ) );
            }
        }
        else {
            my $data = $field_node->textContent();
            push( @field, ( $tag, $ind, '_', $data ) );
        }

        push( @record, [@field] );
    }
    return \@record;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MAB2::Parser::XML - MAB2 XML parser

=head1 SYNOPSIS

L<MAB2::Parser::XML> is a parser for MAB2 XML records.

    use MAB2::Parser::XML;

    my $parser = MAB2::Parser::XML->new( $filename );

    while ( my $record_hash = $parser->next() ) {
        # do something        
    }

=head1 Arguments

=over

=item C<file>

Path to file with MAB2 XML records.

=item C<fh>

Open filehandle for file with MAB2 XML records.

=item C<string>

XML string with MAB2 XML records.

=back

=head1 METHODS

=head2 new($filename | $filehandle | $string)

=head2 next()

Reads the next record from MAB2 XML input stream. Returns a Perl hash.

=head2 _decode($record)

Deserialize a MAB2 XML record to an an ARRAY of ARRAYs.

=head1 SEEALSO

L<Catmandu::Importer::MAB2>.

=head1 AUTHOR

Johann Rolschewski <jorol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Johann Rolschewski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
