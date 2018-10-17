package App::XML::DocBook::Docmake;
$App::XML::DocBook::Docmake::VERSION = '0.0601';
use strict;
use warnings;

use 5.008;

use Getopt::Long qw(GetOptionsFromArray);
use File::Path;
use Pod::Usage;

use parent 'Class::Accessor';


__PACKAGE__->mk_accessors(
    qw(
        _base_path
        _has_output
        _input_path
        _make_like
        _mode
        _output_path
        _stylesheet
        _trailing_slash
        _verbose
        _real_mode
        _xslt_mode
        _xslt_stringparams
        )
);


my %modes = (
    'fo'   => {},
    'help' => {
        standalone => 1,
    },
    'xhtml'     => {},
    'xhtml-1_1' => {
        real_mode => "xhtml",
    },
    'xhtml5' => {
        real_mode => "xhtml",
    },
    'rtf' => {
        xslt_mode => "fo",
    },
    'pdf' => {
        xslt_mode => "fo",
    },
);

sub new
{
    my $class = shift;
    my $self  = {};

    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my ( $self, $args ) = @_;

    my $argv = $args->{'argv'};

    my $output_path;
    my $verbose = 0;
    my $stylesheet;
    my @in_stringparams;
    my $base_path;
    my $make_like = 0;
    my ( $help, $man );
    my $trailing_slash = 1;

    my $ret = GetOptionsFromArray(
        $argv,
        "o=s"              => \$output_path,
        "v|verbose"        => \$verbose,
        "x|stylesheet=s"   => \$stylesheet,
        "stringparam=s"    => \@in_stringparams,
        "basepath=s"       => \$base_path,
        "make"             => \$make_like,
        'help|h'           => \$help,
        'man'              => \$man,
        'trailing-slash=i' => \$trailing_slash,
    );

    if ( !$ret )
    {
        pod2usage(2);
    }
    if ($help)
    {
        pod2usage(1);
    }
    if ($man)
    {
        pod2usage( -exitstatus => 0, -verbose => 2 );
    }

    my @stringparams;
    foreach my $param (@in_stringparams)
    {
        if ( $param =~ m{\A([^=]+)=(.*)\z}ms )
        {
            push @stringparams, [ $1, $2 ];
        }
        else
        {
            die "Wrong stringparam argument '$param'! Does not contain a '='!";
        }
    }

    $self->_has_output( $self->_output_path($output_path) ? 1 : 0 );

    $self->_verbose($verbose);
    $self->_stylesheet($stylesheet);
    $self->_xslt_stringparams( \@stringparams );
    $self->_make_like($make_like);
    $self->_base_path($base_path);
    $self->_trailing_slash($trailing_slash);

    my $mode = shift(@$argv);

    my $mode_struct = $modes{$mode};

    if ($mode_struct)
    {
        $self->_mode($mode);

        my $assign_secondary_mode = sub {
            my ( $struct_field, $attr ) = @_;
            $self->$attr( $mode_struct->{$struct_field} || $mode );
        };

        $assign_secondary_mode->( 'real_mode', '_real_mode' );
        $assign_secondary_mode->( 'xslt_mode', '_xslt_mode' );
    }
    else
    {
        die "Unknown mode \"$mode\"";
    }

    my $input_path = shift(@$argv);

    if ( !( defined($input_path) || $mode_struct->{standalone} ) )
    {
        die "Input path not specified on command line";
    }
    else
    {
        $self->_input_path($input_path);
    }

    return;
}


sub _exec_command
{
    my ( $self, $cmd ) = @_;

    if ( $self->_verbose() )
    {
        print( join( " ", @$cmd ), "\n" );
    }

    if ( system(@$cmd) )
    {
        die qq/<<@$cmd>> failed./;
    }

    return 0;
}

sub run
{
    my $self = shift;

    my $real_mode = $self->_real_mode();

    my $mode_func = '_run_mode_' . $self->_real_mode;

    return $self->$mode_func(@_);
}

sub _run_mode_help
{
    my $self = shift;

    print <<"EOF";
Docmake version $App::XML::DocBook::Docmake::VERSION
A tool to convert DocBook/XML to other formats

Available commands:

    help - this help screen.

    fo - convert to XSL-FO.
    rtf - convert to RTF (MS Word).
    pdf - convert to PDF (Adobe Acrobat).
    xhtml - convert to XHTML.
    xhtml-1_1 - convert to XHTML-1.1.
EOF
}

sub _is_older
{
    my $self = shift;

    my $file1 = shift;
    my $file2 = shift;

    my @stat1 = stat($file1);
    my @stat2 = stat($file2);

    if ( !@stat2 )
    {
        die "Input file '$file1' does not exist.";
    }
    elsif ( !@stat1 )
    {
        return 1;
    }
    else
    {
        return ( $stat1[9] <= $stat2[9] );
    }
}

sub _should_update_output
{
    my $self = shift;
    my $args = shift;

    return $self->_is_older( $args->{output}, $args->{input} );
}

sub _run_mode_fo
{
    my $self = shift;
    return $self->_run_xslt();
}

sub _mkdir
{
    my ( $self, $dir ) = @_;

    mkpath($dir);
}

sub _run_mode_xhtml
{
    my $self = shift;

    # Create the directory, because xsltproc requires it.
    if ( $self->_trailing_slash )
    {
        $self->_mkdir( $self->_output_path() );
    }

    return $self->_run_xslt();
}

sub _calc_default_xslt_stylesheet
{
    my $self = shift;

    my $mode = $self->_xslt_mode();

    return
"http://docbook.sourceforge.net/release/xsl/current/${mode}/docbook.xsl";
}

sub _is_xhtml
{
    my $self = shift;

    return (   ( $self->_mode() eq "xhtml" )
            || ( $self->_mode() eq "xhtml-1_1" )
            || ( $self->_mode() eq "xhtml5" ) );
}

sub _calc_output_param_for_xslt
{
    my $self = shift;
    my $args = shift;

    my $output_path = $self->_output_path();
    if ( defined( $args->{output_path} ) )
    {
        $output_path = $args->{output_path};
    }

    if ( !defined($output_path) )
    {
        die "Output path not specified!";
    }

    # If it's XHTML, then it's a directory and xsltproc requires that
    # it will have a trailing slash.
    if ( $self->_is_xhtml )
    {
        if ( $self->_trailing_slash )
        {
            if ( $output_path !~ m{/\z} )
            {
                $output_path .= "/";
            }
        }
    }

    return $output_path;
}

sub _calc_make_output_param_for_xslt
{
    my $self = shift;
    my $args = shift;

    my $output_path = $self->_calc_output_param_for_xslt($args);

    # If it's XHTML, then we need to compare against the index.html
    # because the directory is freshly made.
    if ( $self->_is_xhtml )
    {
        $output_path .= "index.html";
    }

    return $output_path;
}

sub _pre_proc_command
{
    my ( $self, $args ) = @_;

    my $input_file  = $args->{input};
    my $output_file = $args->{output};
    my $template    = $args->{template};

    return [
        map {
                  ( ref($_) eq '' ) ? $_
                : $_->is_output()   ? $output_file
                : $_->is_input()    ? $input_file

                # Not supposed to happen
                : do { die "Unknown Argument in Command Template."; }
        } @$template
    ];
}

sub _run_input_output_cmd
{
    my $self = shift;
    my $args = shift;

    my $input_file       = $args->{input};
    my $output_file      = $args->{output};
    my $make_output_file = $args->{make_output};

    if ( !defined($make_output_file) )
    {
        $make_output_file = $output_file;
    }

    if (
        ( !$self->_make_like() )
        || $self->_should_update_output(
            {
                input  => $input_file,
                output => $make_output_file,
            }
        )
        )
    {
        $self->_exec_command( $self->_pre_proc_command($args), );
    }
}

sub _on_output
{
    my ( $self, $meth, $args ) = @_;

    return $self->_has_output() ? $self->$meth($args) : ();
}

sub _calc_output_params
{
    my ( $self, $args ) = @_;

    return (
        output      => $self->_calc_output_param_for_xslt($args),
        make_output => $self->_calc_make_output_param_for_xslt($args),
    );
}

sub _calc_template_o_flag
{
    my ( $self, $args ) = @_;

    return ( "-o", $self->_output_cmd_comp() );
}

sub _calc_template_string_params
{
    my ($self) = @_;

    return [ map { ( "--stringparam", @$_ ) }
            @{ $self->_xslt_stringparams() } ];
}

sub _run_xslt
{
    my $self = shift;
    my $args = shift;

    my @stylesheet_params = ( $self->_calc_default_xslt_stylesheet() );

    if ( defined( $self->_stylesheet() ) )
    {
        @stylesheet_params = ( $self->_stylesheet() );
    }

    my @base_path_params = ();

    if ( defined( $self->_base_path() ) )
    {
        @base_path_params =
            ( "--path", ( $self->_base_path() . '/' . $self->_xslt_mode() ), );
    }

    return $self->_run_input_output_cmd(
        {
            input => $self->_input_path(),
            $self->_on_output( '_calc_output_params', $args ),
            template => [
                "xsltproc",
                $self->_on_output( '_calc_template_o_flag', $args ),
                @{ $self->_calc_template_string_params() },
                @base_path_params,
                @stylesheet_params,
                $self->_input_cmd_comp(),
            ],
        },
    );
}

sub _run_xslt_and_from_fo
{
    my $self = shift;
    my $args = shift;

    my $xslt_output_path = $self->_output_path();

    if ( !defined($xslt_output_path) )
    {
        die "No -o flag was specified. See the help.";
    }

    # TODO : do something meaningful if a period (".") is not present
    if ( $xslt_output_path !~ m{\.}ms )
    {
        $xslt_output_path .= ".fo";
    }
    else
    {
        $xslt_output_path =~ s{\.([^\.]*)\z}{\.fo}ms;
    }

    $self->_run_xslt( { output_path => $xslt_output_path } );

    return $self->_run_input_output_cmd(
        {
            input    => $xslt_output_path,
            output   => $self->_output_path(),
            template => [
                "fop", ( "-" . $args->{fo_out_format} ),
                $self->_output_cmd_comp(), $self->_input_cmd_comp(),
            ],
        },
    );
}

sub _run_mode_pdf
{
    my $self = shift;

    return $self->_run_xslt_and_from_fo(
        {
            fo_out_format => "pdf",
        },
    );
}

sub _run_mode_rtf
{
    my $self = shift;

    return $self->_run_xslt_and_from_fo(
        {
            fo_out_format => "rtf",
        },
    );
}

sub _input_cmd_comp
{
    my $self = shift;

    return App::XML::DocBook::Docmake::CmdComponent->new(
        {
            is_input  => 1,
            is_output => 0,
        }
    );
}

sub _output_cmd_comp
{
    my $self = shift;

    return App::XML::DocBook::Docmake::CmdComponent->new(
        {
            is_input  => 0,
            is_output => 1,
        }
    );
}

package App::XML::DocBook::Docmake::CmdComponent;
$App::XML::DocBook::Docmake::CmdComponent::VERSION = '0.0601';
use base 'Class::Accessor';

__PACKAGE__->mk_accessors(
    qw(
        is_input
        is_output
        )
);

1;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::XML::DocBook::Docmake

=head1 VERSION

version 0.0601

=head1 SYNOPSIS

    use App::XML::DocBook::Docmake;

    my $docmake = App::XML::DocBook::Docmake->new({argv => [@ARGV]});

    $docmake->run()

=head1 NAME

App::XML::DocBook::Docmake - translate DocBook/XML to other formats

=head1 VERSION

version 0.0601

=head1 FUNCTIONS

=head2 my $obj = App::XML::DocBook::Docmake->new({argv => [@ARGV]})

Instantiates a new object.

=head2 $docmake->run()

Runs the object.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-docbook-xml-docmake at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App::XML::DocBook::Docmake>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::XML::DocBook::Docmake

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App::XML::DocBook::Docmake>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App::XML::DocBook::Docmake>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::XML::DocBook::Docmake>

=item * Search CPAN

L<http://search.cpan.org/dist/App::XML::DocBook::Docmake>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Shlomi Fish.

This program is released under the following license: MIT/X11 License.
( L<http://www.opensource.org/licenses/mit-license.php> ).

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-XML-DocBook-Builder>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-XML-DocBook-Builder>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-XML-DocBook-Builder>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/App-XML-DocBook-Builder>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-XML-DocBook-Builder>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-XML-DocBook-Builder>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-XML-DocBook-Builder>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-XML-DocBook-Builder>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::XML::DocBook::Builder>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-xml-docbook-builder at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-XML-DocBook-Builder>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/app-xml-docbook-builder>

  git clone http://bitbucket.org/shlomif/docmake

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/Public/Dist/Display.html?Name=App-XML-DocBook-Builder>
or by email to
L<bug-app-xml-docbook-builder@rt.cpan.org|mailto:bug-app-xml-docbook-builder@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
