
=head1 NAME

App::Basis::ConvertText2::Plugin::Text

=head1 SYNOPSIS

Handle a few simple text code blocks

    my $obj = App::Basis::ConvertText2::Plugin::Text->new() ;
    my $content = "" ;
    my $params = { } ;
    # new page
    my $out = $obj->process( 'page', $content, $params) ;

    # yamlasjson
    $content = "list:
      - array: [1,2,3,7]
        channel: BBC3
        date: 2013-10-20
        time: 20:30
      - array: [1,2,3,9]
        channel: BBC4
        date: 2013-11-20
        time: 21:00
    " ;
    $out = $obj->process( 'yamlasjson', $content, $params) ;

    # table
    $content = "row1,entry 1,cell2
    row2,cell1, entry 2
    " ;
    $out = $obj->process( 'table', $content, $params) ;

    # version
    $content = "0.1 2014-04-12
      * removed ConvertFile.pm
      * using Path::Tiny rather than other things
      * changed to use pandoc fences ~~~~{.tag} rather than xml format <tag>
    0.006 2014-04-10
      * first release to github" ;
    $out = $obj->process( 'table', $content, $params) ;

    $content = "BBC | http://bbc.co.uk
    DocumentReference  | #docreference
    27escape | https://github.com/27escape" ;
    $out = $obj->process( 'table', $content, $params) ;

=head1 DESCRIPTION

Various simple text transformations

=cut

# ----------------------------------------------------------------------------

package App::Basis::ConvertText2::Plugin::Text;
$App::Basis::ConvertText2::Plugin::Text::VERSION = '0.4';
use 5.10.0;
use strict;
use warnings;
use YAML qw(Load);
use JSON;

use Moo;
use App::Basis::ConvertText2::Support;
use namespace::clean;

has handles => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { [qw{yamlasjson table version page links}] }
);

# ----------------------------------------------------------------------------

=item yamlasjson

Convert a YAML block into a JSON block

 parameters

=cut

sub yamlasjson {
    my $self = shift;
    my ( $tag, $content, $params, $cachedir ) = @_;

    # make sure we have an extra linefeed at the end to make sure
    # YAML is correct
    $content .= "\n\n" ;

    $content =~ s/~~~~{\.yaml}//gsm;
    $content =~ s/~~~~//gsm;

    my $data = Load($content);
    return "\n~~~~{.json}\n" . to_json( $data, { utf8 => 1, pretty => 1 } ) . "\n~~~~\n\n";
}

# ----------------------------------------------------------------------------

sub _split_csv_data {
    my ( $data, $separator ) = @_;
    my @d = ();

    $separator ||= ',';

    my $j = 0;
    foreach my $line ( split( /\n/, $data ) ) {
        last if ( !$line );
        my @row = split( /$separator/, $line );

        for ( my $i = 0; $i <= $#row; $i++ ) {
            undef $row[$i] if ( $row[$i] eq 'undef' );

            # dont' bother with any zero values either
            undef $row[$i] if ( $row[$i] =~ /^0\.?0?$/ );
            push @{ $d[$j] }, $row[$i];
        }
        $j++;
    }

    return @d;
}

# ----------------------------------------------------------------------------

=item table

create a basic html table

 parameters
    data   - comma separated lines of table data

    hashref params of
        class   - HTML/CSS class name
        id      - HTML/CSS class
        width   - width of the table
        style   - style the table if not doing anything else
        legends - flag to indicate that the top row is the legends
        separator - characters to be used to separate the fields

=cut

sub table {
    my $self = shift;
    my ( $tag, $content, $params, $cachedir ) = @_;

    $params->{title} ||= "";

    $content =~ s/^\n//gsm;
    $content =~ s/\n$//gsm;

    # open the csv file, read contents, calc max, add into data array
    my @data = _split_csv_data( $content, $params->{separator} );

    my $out = "<table ";
    $out .= "class='$params->{class}' " if ( $params->{class} );
    $out .= "id='$params->{id}' "       if ( $params->{id} );
    $out .= "width='$params->{width}' " if ( $params->{width} );
    $out .= "class='$params->{style}' " if ( $params->{style} );
    $out .= ">\n";

    for ( my $i = 0; $i < scalar(@data); $i++ ) {
        $out .= "<tr>";

        # decide if the top row has the legends
        my $tag = ( !$i && $params->{legends} ) ? 'th' : 'td';
        map { $out .= "<$tag>$_</$tag>"; } @{ $data[$i] };
        $out .= "</tr>\n";
    }

    $out .= "</table>\n";
    return $out;
}

# ----------------------------------------------------------------------------

=item version

create a version table

 parameters
    data   - sections of version information
        version YYYY-MM-DD
          change text
          more changes


    hashref params of
        class   - HTML/CSS class name
        id      - HTML/CSS class
        width   - width of the table
        style   - style the table if not doing anything else
        separator - characters to be used to separate the fields

=cut

sub version {
    my $self = shift;
    my ( $tag, $content, $params, $cachedir ) = @_;

    $content =~ s/^\n//gsm;
    $content =~ s/\n$//gsm;

    my $out = "<table ";
    $out .= "class='$params->{class}' " if ( $params->{class} );
    $out .= "id='$params->{id}' "       if ( $params->{id} );
    $out .= "width='$params->{width}' " if ( $params->{width} );
    $out .= "class='$params->{style}' " if ( $params->{style} );
    $out .= ">\n";

    $out .= "<tr><th>Version</th><th>Date</th><th>Changes</th></tr>\n";

    my $section = '^(.*?)\s+(\d{2,4}[-\/]\d{2}[-\/]\d{2,4})' ;

    my @data = split( /\n/, $content );
    for ( my $i = 0; $i < scalar(@data); $i++ ) {
        if ( $data[$i] =~ /$section/ ) {
            my $vers = $1;
            my $date = $2;
            $i++;
            my $c = "";

            # get all the lines in this section
            while ( $i < scalar(@data) && $data[$i] !~ /$section/ ) {
                $c .= "$data[$i]\n";
                $i++;
            }
            $out .= "<tr><td valign='top'>$vers</td><td valign='top'>$date</td><td valign='top'>$c</td></tr>\n";
            # adjust $i back so we are either at the wnd correctly or on the next section
            $i-- ;
        }
    }

    $out .= "</table>\n";
    return $out;
}

# ----------------------------------------------------------------------------

# start a new HTML page

sub page {
    my $self = shift;
    my ( $tag, $content, $params, $cachedir ) = @_;

    return "<div style='page-break-before: always;'></div>" ;
}


# ----------------------------------------------------------------------------

=item ~~~~{.links }

create a list of website links
links are one per line and the link name is separated from the link with a 
pipe '|' symbol

 parameters
    class   - name of class for the list, defaults to weblinks

=cut

sub links {
    my $self = shift;
    my ( $tag, $content, $params, $cachedir ) = @_;

    # strip any ending linefeed
    chomp $content;
    return "" if ( !$content );

    $params->{class} ||= "weblinks";
    my $references = "";
    my $ul         = "<ul class='$params->{class}'>\n";
    my %refs       = ();
    my %uls        = ();

    foreach my $line ( split( /\n/, $content ) ) {
        my ( $ref, $link ) = split( /\|/, $line );
        next if ( !$link );

        # trim the items
        $ref  =~ s/^\s+//;
        $link =~ s/^\s+//;
        $ref  =~ s/\s+$//;
        $link =~ s/\s+$//;

        # if there is nothing to link to ignore this
        next if ( !$ref || !$link );

        $references .= "[$ref]: $link\n";

        # links that reference inside the document do not get added to the
        # list of weblinks
        if ( $link !~ /^#/ ) {
            $uls{ lc($ref) } = "<li><a href='$link'>$ref</a><ul><li>$link</li></ul></li>\n";
        }
    }

    # make them nice and sorted
    map { $ul .= $uls{$_} } sort keys %uls;
    $ul .= "</ul>\n";

    return "\n" . $references . "\n" . $ul . "\n";
}

# ----------------------------------------------------------------------------
# decide which simple hanlder should process this request

sub process {
    my $self = shift;
    my ( $tag, $content, $params, $cachedir ) = @_;

    if ( $self->can($tag) ) {
        return $self->$tag(@_);
    }
    return undef;
}

# ----------------------------------------------------------------------------

1;

