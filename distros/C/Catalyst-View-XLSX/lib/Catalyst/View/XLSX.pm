package Catalyst::View::XLSX;

use Moose;
extends 'Catalyst::View';

our $VERSION = '1.2';

use File::Temp;
use URI::Escape;
use Path::Class;
use File::Spec;
use Excel::Writer::XLSX;

has 'stash_key' => (
    is	  => 'rw',
    isa	 => 'Str',
    lazy	=> 1,
    default => sub { 'xlsx' }
);

has 'tmpdir' => (
    is	  => 'rw',
    isa	 => 'Str',
    lazy	=> 1,
    default => sub { File::Spec->tmpdir() }
);

has 'filename' => (
    is	  => 'rw',
    isa	 => 'Str',
    lazy	=> 1,
    default => sub { 'output.xlsx' }
);

# ========================================================================== #
# Process to Respond Excel File 
# ========================================================================== #
sub process {
    my ( $self, $c ) = @_;

    my $xlsx =  $c->stash->{ $self->stash_key };
    my $content = $self->render($c, $xlsx);
    my $disposition = $xlsx->{disposition} || 'inline';

    my $filename = uri_escape_utf8( $xlsx->{filename} || $self->filename );
    $c->res->header(
        'Content-Disposition' => "$disposition; filename=$filename",
        'Content-type'		=> 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    $c->res->body($content);
}

# ========================================================================== #
# This method will create and return Excel Sheet content from the stashed data 
# ========================================================================== #
sub render {
    my ( $self, $c, $args ) = @_;

    if ( $args->{file} ) { 
        #Respond the file content
        die "XLSX File Error : Invalid file ". $args->{file} unless -f $args->{file};

        return $self->_get_content($args->{file});
    }


    #Generate a XLSX file using the data 

    # Create a temporary file
    my $temp = File::Temp->new(
        DIR	 => $self->tmpdir,
        SUFFIX  => '.xlsx',
        UNLINK  => 1,
    );
    binmode $temp, ':utf8';
    my $xlsxfn  =  $temp->filename;
    my $workbook = Excel::Writer::XLSX->new( $xlsxfn );
    die "Problems creating new Excel file: $!" unless defined $workbook;
    my $worksheet = $workbook->add_worksheet();
    my $format = $workbook->add_format();

    my $data = $args->{data};
    for (@$data) {
        my $cell_format = $format;
        $cell_format->set_format_properties(%{$_->{format}}) if $_->{format};
        $worksheet->write( $_->{row},$_->{col},$_->{data},$cell_format,$_->{value} );
    }
    $workbook->close();
    return $self->_get_content($xlsxfn);	
}

# ========================================================================== #
# This method will return content 
# ========================================================================== #
sub  _get_content {
    my ($self,$file) = @_;
    # Read the output and return it
    my $xlsxc	  = Path::Class::File->new($file);
    my $content = $xlsxc->slurp();
    $xlsxc->remove();
    return $content;

}

1;


__END__
=pod

=head1 NAME

Catalyst::View::XLSX - Catalyst View for Microsoft Excel file 

=head1 VERSION

version 1.2

=head1 SYNOPSIS

# Create MyApp::View::XLSX using the helper:

`script/create.pl view XLSX XLSX`

In your controller

    package MyApp::Controller::MyController;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller' }

    sub download_excel  : Local :Args(0) {
        my ( $self, $c ) = @_;

        my $format = {
            font => 'Times New Roman',
            size => '15',
            color => 'Black',
            bold  => 1,
            italic => 0,
            underline => 0,
            font_strikeout => 0,
            font_script => 0,
            font_outline => 0,
            font_shadow => 0,
            num_format => '0.00'
        };

        my $xlsx_data = {
            data => [
                {
                    row => 0,
                    col => 0,
                    data => 10,
                    format => $format,
                    value => '10'
                },
                {
                    row => 0,
                    col => 1,
                    data => 20,
                    format => $format,
                    value => '20'
                },
                {
                    row => 0,
                    col => 2,
                    data => '=SUM(A1:B1)',
                    format => $format,
                    value => '30'
                }
            ],
            filename => "ExcelFile.xlsx"
        };
        
        $c->stash(xlsx => $xlsx_data, current_view => 'XLSX');
    }

    1;

=head1 SUMMARY

This Catalyst::View::XLSX provides a Catalyst view that generates Microsoft Excel (.xlsx) files.

=head1 DESCRIPTION

This is a very simple module which uses few methods of L<Excel::Writer::XLSX> and creates an Excel file based on the stashed parameters. It also respond the file that has been readily available.

=head2 STASH PARAMETERS


    $c->stash->{xlsx} = {
        data => [
            { row => 0, col => 0, data => 'Hey! Look at me. I am A1', format => undef, value => undef },
            { row => 0, col => 1, data => 'People call me as  B1',    format => undef, value => undef }
        ],
        filename => 'ExcelFile.xlsx'
    };

    #row,col -> represents the position on the Excel sheet 
    #data    -> represents the content of the field
    #value   -> (OPTIONAL) it will hold the actual value when data has formula
    #format  -> (OPTIONAL) format of the cell, supports the following properties  
 
            #font => 'Times New Roman',
            #size => '15',
            #color => 'Black',
            #bold  => 1,
            #italic => 0,
            #underline => 0,
            #font_strikeout => 0,
            #font_script => 0,
            #font_outline => 0,
            #font_shadow => 0,
            #num_format => '0.00'

            #Please refer L<Excel::Writer::XLSX> for more properties.

or 

    $c->stash->{xlsx} = {
        file => '/opt/git/Files/GeneratedRank.xlsx',
        filename => 'Resulst.xlsx'
    };


=head2 METHODS

=head3 process 

This will respond the Excel file with Content-Type `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
 
=head3 render

This will generate the Excel file based on the stashed parameters using L<Excel::Writer::XLSX> module.
 
=head1 REPOSITORY

L<https://github.com/Virendrabaskar/Catalyst-View-XLSX>

=head1 SEE ALSO

=over 4

=item *

L<Excel::Writer::XLSX>

=item *

L<Catalyst::View> 

=item *

L<Catalyst>

=back

=head1 AUTHOR

Baskar Nallathambi <baskarmusiri@gmail.com>

=head1 COPYRIGHT AND LICENSE

This is free module.You can do anything to this module under
the same terms as the Perl 5 programming language system itself.

=cut
