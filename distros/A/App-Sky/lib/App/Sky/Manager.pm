package App::Sky::Manager;

use strict;
use warnings;

our $VERSION = '0.2.1';


use Carp ();

use Moo;
use MooX 'late';

use List::Util qw(first);

use URI;
use File::Basename qw(basename);

use App::Sky::Module;

# For defined-or - "//".
use 5.010;

has config => (isa => 'HashRef', is => 'ro',);


sub _calc_site_conf
{
    my ($self, $args) = @_;

    my $config = $self->config;

    return $config->{sites}->{ $config->{default_site} };
}

sub _calc_sect_name
{
    my ($self, $args, $sections) = @_;

    my $bn = $args->{basename};

    my $sect_name = $args->{section};

    if (!defined ($sect_name))
    {
        if ($args->{is_dir})
        {
            $sect_name = $self->_calc_site_conf($args)->{dirs_section};
        }
        else
        {
            $sect_name =
            (first
                {
                    my $re = $sections->{$_}->{basename_re};
                    $bn =~ /$re/;
                }
                (keys(%$sections))
            );
        }
    }

    if (!defined( $sect_name ))
    {
        Carp::confess ("Unknown section for basename '$bn'");
    }

    if (!exists( $sections->{$sect_name} ))
    {
        Carp::confess ("Section '$sect_name' does not exist.");
    }

    return $sect_name;
}

sub _calc_target_dir
{
    my ($self, $args) = @_;

    if (defined( $args->{target_dir} ))
    {
        return $args->{target_dir};
    }
    else
    {
        my $sections = $self->_calc_site_conf($args)->{sections};

        my $sect_name = $self->_calc_sect_name( $args, $sections );

        return $sections->{$sect_name}->{target_dir};
    }
}

sub _perform_upload_generic
{
    my ($self, $is_dir, $args) = @_;

    my $filenames = $args->{filenames}
        or Carp::confess ("Missing argument 'filenames'");

    if (@$filenames != 1)
    {
        Carp::confess ("More than one file passed to 'filenames'");
    }

    my $site_conf = $self->_calc_site_conf($args);

    my $backend = App::Sky::Module->new(
        {
            base_upload_cmd => $site_conf->{base_upload_cmd},
            dest_upload_prefix => $site_conf->{dest_upload_prefix},
            dest_upload_url_prefix => $site_conf->{dest_upload_url_prefix},
        }
    );

    my $fn = $filenames->[0];
    my $bn = basename($fn);

    my @dir = ($is_dir ? (is_dir => 1) : ());

    return $backend->get_upload_results(
        {

            filenames =>
            (
                $is_dir
                ?  [map { my $s = $_; $s =~ s#/+\z##ms; $s } @$filenames ]
                : $filenames,
            ),
            target_dir => $self->_calc_target_dir({
                    %$args,
                    basename => $bn,
                    @dir,
            }),
            @dir,
        }
    );

}


sub get_upload_results
{
    my ($self, $args) = @_;

    return $self->_perform_upload_generic(0, $args);
}


sub get_recursive_upload_results
{
    my ($self, $args) = @_;

    return $self->_perform_upload_generic(1, $args);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Sky::Manager - manager for the configuration.

=head1 VERSION

version 0.2.1

=head1 METHODS

=head2 config

The configuration of the app as passed through the configuration file.

=head2 my $results = $sky->get_upload_results({ filenames => ["Shine4U.webm"], });

Gives the recipe to execute for the upload commands.

Accepts one argument that is a hash reference with these keys:

=over 4

=item * 'filenames'

An array reference containing strings to upload. Currently only supports
one filename.

=item * 'section'

An optional section that will override the target section. If not specified,
the uploader will try to guess based on the file’s basename and the manager
configuration.

=item * 'target_dir'

Overrides the target directory for the upload, to ignore that dictated by
the sections. Should point to a string.

=back

Returns a L<App::Sky::Results> reference containing:

=over 4

=item * upload_cmd

The upload command to execute (as an array reference of strings).

=back

=head2 my $results = $sky->get_recursive_upload_results({ filenames => ['/home/music/Music/mp3s/Basic Desire/'], });

Gives the recipe to execute for the recursive upload commands.

Accepts one argument that is a hash reference with these keys:

=over 4

=item * 'filenames'

An array reference containing paths to directories. Currently only supports
one filename.

=item * 'section'

An optional section that will override the target section. If not specified,
the uploader will try to use the 'dirs_section' section.

=item * 'target_dir'

Overrides the target directory for the upload, to ignore that dictated by
the sections. Should point to a string.

=back

Returns a L<App::Sky::Results> reference containing:

=over 4

=item * upload_cmd

The upload command to execute (as an array reference of strings).

=back

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
