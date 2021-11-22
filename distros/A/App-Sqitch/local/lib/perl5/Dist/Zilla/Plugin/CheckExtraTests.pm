use strict;
use warnings;

package Dist::Zilla::Plugin::CheckExtraTests;
# ABSTRACT: check xt tests before release

our $VERSION = '0.029';

# Dependencies
use Dist::Zilla 4.3 ();
use Moose 2;
use namespace::autoclean 0.09;

# extends, roles, attributes, etc.

with 'Dist::Zilla::Role::BeforeRelease';

#pod =attr default_jobs
#pod
#pod This attribute is the default value that should be used as the C<jobs> argument
#pod for prerelease tests.
#pod
#pod =cut

has default_jobs => (
    is      => 'ro',
    isa     => 'Int', # non-negative
    default => 1,
);

# methods

sub before_release {
    my ( $self, $tgz ) = @_;
    $tgz = $tgz->absolute;

    { require Path::Tiny; Path::Tiny->VERSION(0.013) }

    my $build_root = Path::Tiny::path( $self->zilla->root )->child('.build');
    $build_root->mkpath unless -d $build_root;

    my $tmpdir = Path::Tiny->tempdir( DIR => $build_root );

    $self->log("Extracting $tgz to $tmpdir");

    require Archive::Tar;

    my @files = do {
        my $wd = File::pushd::pushd($tmpdir);
        Archive::Tar->extract_archive("$tgz");
    };

    $self->log_fatal( [ "Failed to extract archive: %s", Archive::Tar->error ] )
      unless @files;

    # Run tests on the extracted tarball:
    my $target = $tmpdir->child( $self->zilla->dist_basename );

    local $ENV{RELEASE_TESTING} = 1;
    local $ENV{AUTHOR_TESTING}  = 1;

    {
        # chdir in
        require File::pushd;
        my $wd = File::pushd::pushd($target);

        # make
        my @builders = @{ $self->zilla->plugins_with( -BuildRunner ) };
        die "no BuildRunner plugins specified" unless @builders;
        $_->build for @builders;

        my $jobs = $self->default_jobs;
        my @v = $self->zilla->logger->get_debug ? ('-v') : ();

        require App::Prove;
        App::Prove->VERSION('3.00');

        my $app = App::Prove->new;
        $app->process_args( '-j', $jobs, @v, qw/-r -b xt/ );
        $app->run or $self->log_fatal("Fatal errors in xt tests");
    }

    $self->log("all's well; removing $tmpdir");
    $tmpdir->remove_tree( { safe => 0 } );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CheckExtraTests - check xt tests before release

=head1 VERSION

version 0.029

=head1 SYNOPSIS

In your dist.ini:

  [CheckExtraTests]

=head1 DESCRIPTION

Runs all xt tests before release.  Dies if any fail.  Sets RELEASE_TESTING
and AUTHOR_TESTING.

If you use L<Dist::Zilla::Plugin::TestRelease>, you should consider using
L<Dist::Zilla::Plugin::RunExtraTests> instead, which enables xt tests to
run as part of C<[TestRelease]> and is thus a bit more efficient as the
distribution is only built once for testing.

=head1 ATTRIBUTES

=head2 default_jobs

This attribute is the default value that should be used as the C<jobs> argument
for prerelease tests.

=for Pod::Coverage::TrustPod before_release

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Dist-Zilla-Plugin-CheckExtraTests/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Dist-Zilla-Plugin-CheckExtraTests>

  git clone https://github.com/dagolden/Dist-Zilla-Plugin-CheckExtraTests.git

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Jesse Luehrs <doy@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Christopher J. Madsen David Golden H. Adler Karen Etheridge Kent Fredric Olivier Mengué Ricardo Signes

=over 4

=item *

Christopher J. Madsen <cjm@cpan.org>

=item *

David Golden <xdg@xdg.me>

=item *

David H. Adler <dha@pobox.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
