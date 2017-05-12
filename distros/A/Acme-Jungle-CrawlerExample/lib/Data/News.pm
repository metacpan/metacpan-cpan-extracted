package Data::News;
use Moose;
use Text::CSV_XS;
use DateTime;
use Digest::SHA1 qw(sha1_hex);
use HTML::Entities;

has filename_csv => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        my ($self) = @_;
        my $today = DateTime->now( time_zone => 'local' );
        #defines a name for our csv.
        my $filename = $today->dmy('-').'_' . $today->hms( '-' ) . '.csv';
        $self->filename_csv($filename);
    },
);

has site_name => (
    is  => 'rw',
    isa => 'Str',
    default => '',
);

after 'site_name' => sub {
    my ( $self, $value, $skip_verify ) = @_; 
    return if ! $value;
    if ( ! $skip_verify ) {
        $value =~ s{::}{-}g;
        $self->site_name( $value, 1 );
    }
} ;

has [ qw/title author content webpage meta_keywords meta_description/ ] => (
    is  => 'rw',
    isa => 'Any',
);

has images => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { return []; } ,
); 

has data => (
    is      => 'rw',
    isa     => 'Data::News',
    default => sub {
        my ($self) = @_;
        return $self;
    },
);

has csv => (
    is => 'ro',
    isa => 'Text::CSV_XS',
    default => sub {
        my $csv = Text::CSV_XS->new()
          or die "Cannot use CSV: " . Text::CSV_XS->error_diag();
        $csv->eol("\r\n");
        return $csv;
    },
);

sub save {    #saves the data to csv
    my ($self) = @_;
    my @rows = (
        [
            sha1_hex( $self->webpage ),
            $self->webpage,
            decode_entities( $self->data->title ),
            decode_entities( $self->data->author ),
            decode_entities( $self->data->content ),
            decode_entities( $self->data->meta_keywords ),
            decode_entities( $self->data->meta_description ),
            join( '|' , @{ $self->images } ),
        ],
    );
    my $file = './data/NEWS-' . $self->site_name. '-' . $self->filename_csv;

    open my $fh, ">>:encoding(utf8)", "$file" or die "$file: $!";
    $self->csv->print( $fh, $_ ) for @rows;
    close $fh or die "Error on file $file: $!";
}

1;


=head1 NAME
    
    Data::News - Handles the extracted data and saves it

=head1 DESCRIPTION

    Data::News is an example class as to how the extracted data should
    be handled. 
    
    In this case lib/Sites/XYZ will populate Data::News which will
    then handle the saving of this data.

=head1 AUTHOR

    Hernan Lopes
    CPAN ID: HERNAN
    Hernan
    hernanlopes@gmail.com
    http://github.com/hernan

=head1 COPYRIGHT

    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

    The full text of the license can be found in the
    LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

