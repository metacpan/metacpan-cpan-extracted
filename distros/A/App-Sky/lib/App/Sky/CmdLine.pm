package App::Sky::CmdLine;

use strict;
use warnings;

our $VERSION = '0.2.1';


use Carp ();

use Moo;
use MooX 'late';

use Getopt::Long qw(GetOptionsFromArray);

use App::Sky::Config::Validate;
use App::Sky::Manager;
use File::HomeDir;

use YAML::XS qw(LoadFile);

use Scalar::Util qw(reftype);

has 'argv' => (isa => 'ArrayRef[Str]', is => 'rw', required => 1,);


sub _basic_help
{
    my ($self) = @_;

    print <<'EOF';
sky upload /path/to/myfile.txt
sky up-r /path/to/directory
EOF

    exit(0);
}

sub _basic_usage
{
    my ($self) = @_;

    print "Usage: sky [up|upload] /path/to/myfile.txt\n";
    exit(-1);
}

sub run
{
    my ($self) = @_;

    if (! @{$self->argv()})
    {
        return $self->_basic_usage();
    }

    my $verb = shift(@{$self->argv()});

    if (($verb eq '--help') or ($verb eq '-h'))
    {
        return $self->_basic_help();
    }

    my $_calc_manager = sub {
        my $dist_config_dir = File::HomeDir->my_dist_config( 'App-Sky', {create => 1}, );

        my $config_fn = File::Spec->catfile($dist_config_dir, 'app_sky_conf.yml');

        my $config = LoadFile($config_fn);

        my $validator = App::Sky::Config::Validate->new({ config => $config });
        $validator->is_valid();

        return App::Sky::Manager->new(
            {
                config => $config,
            }
        );
    };

    my $_handle_results = sub {
        my ($results) = @_;

        my $upload_cmd = $results->upload_cmd();
        my $urls = $results->urls();

        if ((system { $upload_cmd->[0] } @$upload_cmd) != 0)
        {
            die "Upload cmd <<@$upload_cmd>> failed with $!";
        }

        print "Got URL:\n" , $urls->[0]->as_string(), "\n";

        exit(0);
    };

    my $op;
    if ((($verb eq 'up') || ($verb eq 'upload')))
    {
        $op = 'upload';
    }
    elsif (($verb eq 'up-r') || ($verb eq 'upload-recursive'))
    {
        $op = "up-r";
    }
    else
    {
        return $self->_basic_usage();
    }


    # GetOptionsFromArray(
    #     $self->argv(),
    # );

    my $filename = shift(@{$self->argv()});

    if (not (($op eq 'upload') ? (-f $filename) : (-d $filename)))
    {
        die "Can only upload directories. '$filename' is not a valid directory name.";
    }

    my $meth = $op eq 'upload' ? 'get_upload_results' : 'get_recursive_upload_results';

    $_handle_results->(
        scalar(
            $_calc_manager->()->$meth(
                {
                    filenames => [$filename],
                }
            )
        )
    );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Sky::CmdLine - command line program

=head1 VERSION

version 0.2.1

=head1 METHODS

=head2 argv

The array of command line arguments - should be supplied to the constructor.

=head2 run()

Run the application.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Sky or by email to
bug-app-sky@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::Sky

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/App-Sky>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-Sky>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Sky>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/App-Sky>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-Sky>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/App-Sky>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/App-Sky>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-Sky>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-Sky>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::Sky>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-sky at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Sky>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Sky-uploader>

  git clone git://github.com/shlomif/Sky-uploader.git

=cut
