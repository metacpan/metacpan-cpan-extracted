package Alien::Plotly::Kaleido;

# ABSTRACT: Finds or installs plotly kaleido

use 5.010;
use strict;
use warnings;

our $VERSION = '0.003'; # VERSION

use parent 'Alien::Base';

use File::Which qw(which);
use IPC::Run ();
use JSON ();
use Path::Tiny ();

sub bin_dir {
    my ($class) = @_;
    if ( $class->install_type eq 'system' ) {
        return Alien::Base::bin_dir($class);
    }
    else {
        return Path::Tiny->new( $class->dist_dir );
    }
}

sub version {
    my ($self) = @_;
    if ( $self->install_type eq 'system' ) {
        state $version;
        unless ($version) {
            $version = $self->detect_kaleido_version;
        }
        return $version;
    }
    else {
        return $self->SUPER::version;
    }
}

sub detect_kaleido_version {
    my ($class) = @_;

    my $kaleido = which('kaleido');
    if ($kaleido) {
        my $decode_json_safe = sub {
            my ($out) = @_;
            my $data;
            eval { $data = JSON::decode_json($out); };
            $@ = '' if ($@);
            return $data;
        };

        my @cmd = ( $kaleido, 'plotly', '--disable-gpu', '--no-sandbox' );
        eval {
            require Chart::Plotly;
            my $plotlyjs =
              File::ShareDir::dist_file( 'Chart-Plotly',
                'plotly.js/plotly.min.js' );
              if ( -r $plotlyjs ) {
                push @cmd, "--plotlyjs=$plotlyjs";
            }
        };
        my $h;
        my $data;
        eval {
            my ( $in, $out, $err );
            $h = IPC::Run::start( \@cmd, \$in, \$out, \$err,
                my $t = IPC::Run::timer(30) );
            while ( not $data and not $t->is_expired ) {
                $h->pump;
                $data = $decode_json_safe->($out);
            }
            $h->finish;
        };
        if ($@) {
            warn $@;
            $h->kill_kill;
        }
        if ( $data and exists $data->{version} ) {
            return $data->{version};
        }
    }

    die "Failed to detect kaleido version";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Plotly::Kaleido - Finds or installs plotly kaleido

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Alien::Plotly::Kaleido;
    use Config;

    if (Alien::Plotly::Kaleido->install_type eq 'share') {
        $ENV{PATH} = join(
            $Config{path_sep},
            Alien::Plotly::Kaleido->bin_dir,
            $ENV{PATH}
        );

        # get version
        my $version = Alien::Plotly::Kaleido->version;
    }

    # If install_type is not 'share' then it means kaleido
    # was detected from PATH when Alien::Plotly::Kaleido was installed.
    # So in either case now you has 'kaleido' in PATH.

=head1 DESCRIPTION

This module finds L<plotly's kaleido|https://github.com/plotly/Kaleido>
from your system, or installs it.

It supports 3 OS platforms: Windows, Linux and OSX.

=head1 KALEIDO VERSION

0.2.1

=head1 INSTALLATION

By default if it cannot detect Kaleido from your environment,
it will download Kaleido package from
L<kaleido's github release page|https://github.com/plotly/Kaleido/releases>.

If you want to install from a different url, or from locally downloaded
zipball, you can use environment variable =ALIEN_PLOTLY_KALEIDO_DOWNLOAD_URL=.
For example, to install from a local zipball,

    ALIEN_PLOTLY_KALEIDO_DOWNLOAD_URL=file:///your/local/kaleido/zip cpanm Alien::Plotly::Kaleido

=head1 SEE ALSO

L<https://github.com/plotly/Kaleido>

L<Alien>, 
L<Chart::Plotly>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Carlos D. Álvaro

Carlos D. Álvaro <github@cdalvaro.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
