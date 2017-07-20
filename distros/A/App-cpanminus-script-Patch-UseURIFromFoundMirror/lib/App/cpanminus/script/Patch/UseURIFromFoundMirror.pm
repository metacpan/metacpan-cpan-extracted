package App::cpanminus::script::Patch::UseURIFromFoundMirror;

our $DATE = '2017-07-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

my $_search_module = sub {
    my($self, $module, $version) = @_;
    if ($self->{mirror_index}) {
        $self->mask_output( chat => "Searching $module on mirror index $self->{mirror_index} ...\n" );
        my $pkg = $self->search_mirror_index_file($self->{mirror_index}, $module, $version);
        return $pkg if $pkg;
        unless ($self->{cascade_search}) {
            $self->mask_output( diag_fail => "Finding $module ($version) on mirror index $self->{mirror_index} failed." );
            return;
        }
    }
    unless ($self->{mirror_only}) {
        my $found = $self->search_database($module, $version);
        return $found if $found;
    }
  MIRROR: for my $mirror (@{ $self->{mirrors} }) {
        $self->mask_output( chat => "Searching $module on mirror $mirror ...\n" );
        my $name = '02packages.details.txt.gz';
        my $uri  = "$mirror/modules/$name";
        my $gz_file = $self->package_index_for($mirror) . '.gz';
        unless ($self->{pkgs}{$uri}) {
            $self->mask_output( chat => "Downloading index file $uri ...\n" );
            $self->mirror($uri, $gz_file);
            $self->generate_mirror_index($mirror) or next MIRROR;
            $self->{pkgs}{$uri} = "!!retrieved!!";
        }
        {
            # only use URI from the found mirror
            local $self->{mirrors} = [$mirror];
            my $pkg = $self->search_mirror_index($mirror, $module, $version);
            return $pkg if $pkg;
        }
        $self->mask_output( diag_fail => "Finding $module ($version) on mirror $mirror failed." );
    }
    return;
};

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'replace',
                sub_name    => 'search_module',
                code        => $_search_module,
            },
        ],
   };
}

1;
# ABSTRACT: Only use URI from mirror where we found the module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cpanminus::script::Patch::UseURIFromFoundMirror - Only use URI from mirror where we found the module

=head1 VERSION

This document describes version 0.001 of App::cpanminus::script::Patch::UseURIFromFoundMirror (from Perl distribution App-cpanminus-script-Patch-UseURIFromFoundMirror), released on 2017-07-14.

=head1 SYNOPSIS

In the command-line:

 % perl -MModule::Load::In::INIT=App::cpanminus::script::Patch::UseURIFromFoundMirror `which cpanm` ...

=head1 DESCRIPTION

This is
L<https://github.com/perlancar/operl-App-cpanminus/commit/09fc2da14bc19da508375b8c75a0156e39f5931c>
in patch form, so it can be used with stock L<cpanm>.

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cpanminus-script-Patch-UseURIFromFoundMirror>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cpanminus-script-Patch-UseURIFromFoundMirror>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cpanminus-script-Patch-UseURIFromFoundMirror>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
