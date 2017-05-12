package App::Sky::Config::Validate;

use strict;
use warnings;

our $VERSION = '0.2.1';


use Carp ();

use Moo;
use MooX 'late';

use Scalar::Util qw(reftype);
use List::MoreUtils qw(notall);

has 'config' => (isa => 'HashRef', is => 'ro', required => 1,);


sub _sorted_keys
{
    my $hash_ref = shift;

    return sort {$a cmp $b } keys(%$hash_ref);
}

sub _validate_section
{
    my ($self, $site_name, $sect_name, $sect_conf) = @_;

    foreach my $string_key (qw( basename_re target_dir))
    {
        my $v = $sect_conf->{$string_key};

        if (not (
                defined($v)
                &&
                ref($v) eq ''
                &&
                $v =~ /\S/
            ))
        {
        die "Section '$sect_name' at site '$site_name' must contain a non-empty $string_key";
        }
    }

    return;
}

sub _validate_site
{
    my ($self, $site_name, $site_conf) = @_;

    my $base_upload_cmd = $site_conf->{base_upload_cmd};
    if (ref ($base_upload_cmd) ne 'ARRAY')
    {
        die "base_upload_cmd for site '$site_name' is not an array.";
    }

    if (notall { defined($_) && ref($_) eq '' } @$base_upload_cmd)
    {
        die "base_upload_cmd for site '$site_name' must contain only strings.";
    }

    foreach my $kk (qw(dest_upload_prefix dest_upload_url_prefix))
    {
        my $s = $site_conf->{$kk};
        if (not
            (
                defined($s) && (ref($s) eq '') && ($s =~ m/\S/)
            )
        )
        {
            die "$kk for site '$site_name' is not a string.";
        }
    }



    my $sections = $site_conf->{sections};
    if (ref ($sections) ne 'HASH')
    {
        die "Sections for site '$site_name' is not a hash.";
    }

    foreach my $sect_name (_sorted_keys($sections))
    {
        $self->_validate_section(
            $site_name, $sect_name, $sections->{$sect_name}
        );
    }

    return;
}

sub is_valid
{
    my ($self) = @_;

    my $config = $self->config();

    # Validate the configuration
    {
        if (! exists ($config->{default_site}))
        {
            die "A 'default_site' key must be present in the configuration.";
        }

        my $sites = $config->{sites};
        if (ref($sites) ne 'HASH')
        {
            die "sites key must be a hash.";
        }

        foreach my $name (_sorted_keys($sites))
        {
            $self->_validate_site($name, $sites->{$name});
        }
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Sky::Config::Validate - validate the configuration.

=head1 VERSION

version 0.2.1

=head1 METHODS

=head2 $self->config()

The configuration to validate.

=head2 $self->is_valid()

Determines if the configuration is valid. Throws an exception if not valid,
and returns FALSE (in both list context and scalar context if it is valid.).

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
