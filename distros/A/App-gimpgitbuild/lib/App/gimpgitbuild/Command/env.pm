package App::gimpgitbuild::Command::env;
$App::gimpgitbuild::Command::env::VERSION = '0.30.0';
use strict;
use warnings;
use 5.014;

use App::gimpgitbuild -command;

use Path::Tiny qw/ path tempdir tempfile cwd /;

use App::gimpgitbuild::API::GitBuild ();

sub description
{
    return "set the environment for building GIMP-from-git";
}

sub abstract
{
    return shift->description();
}

sub opt_spec
{
    return ();


}

sub execute
{
    my ( $self, $opt, $args ) = @_;

    my $output_fn = $opt->{output};
    my $exe       = $opt->{exec} // [];

    my $obj = App::gimpgitbuild::API::GitBuild->new;

    my $env = $obj->new_env;
    print <<"EOF";
export PATH="$env->{PATH}" ;
export PKG_CONFIG_PATH="$env->{PKG_CONFIG_PATH}" ;
export XDG_DATA_DIRS="$env->{XDG_DATA_DIRS}" ;
EOF

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.30.0

=begin foo return (
        [ "output|o=s", "Output path" ],
        [ "title=s",    "Chart Title" ],
        [ 'exec|e=s@',  "Execute command on the output" ]
    );
=end foo

=head1 NAME

gimpgitbuild env - set the environment vars for building gimp-from-git

=head1 SYNOPSIS

    # In your sh-compatible shell:
    eval "$(gimpgitbuild env)"


=end foo

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-gimpgitbuild>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-gimpgitbuild>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-gimpgitbuild>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-gimpgitbuild>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-gimpgitbuild>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::gimpgitbuild>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-gimpgitbuild at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-gimpgitbuild>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/App-gimpgitbuild>

  git clone git://github.com/shlomif/App-gimpgitbuild.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/App-gimpgitbuild/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Shlomi Fish.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
