# NAME

Catalyst::View::XLSX - Catalyst View for Microsoft Excel file 

# VERSION

version 1.2

# SYNOPSIS

\# Create MyApp::View::XLSX using the helper:

\`script/create.pl view XLSX XLSX\`

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

# SUMMARY

This Catalyst::View::XLSX provides a Catalyst view that generates Microsoft Excel (.xlsx) files.

# DESCRIPTION

This is a very simple module which uses few methods of [Excel::Writer::XLSX](https://metacpan.org/pod/Excel::Writer::XLSX) and creates an Excel file based on the stashed parameters. It also respond the file that has been readily available.

## STASH PARAMETERS



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



## METHODS

### process 

This will respond the Excel file with Content-Type \`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet\`
 

### render

This will generate the Excel file based on the stashed parameters using [Excel::Writer::XLSX](https://metacpan.org/pod/Excel::Writer::XLSX) module.
 

# REPOSITORY

[https://github.com/Virendrabaskar/Catalyst-View-XLSX](https://github.com/Virendrabaskar/Catalyst-View-XLSX)

# SEE ALSO

- [Excel::Writer::XLSX](https://metacpan.org/pod/Excel::Writer::XLSX)
- [Catalyst::View](https://metacpan.org/pod/Catalyst::View) 
- [Catalyst](https://metacpan.org/pod/Catalyst)

# AUTHOR

Baskar Nallathambi <baskarmusiri@gmail.com>

# COPYRIGHT AND LICENSE

This is free module.You can do anything to this module under
the same terms as the Perl 5 programming language system itself.
