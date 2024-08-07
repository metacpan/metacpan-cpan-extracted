package CPAN::Packager::Downloader;
use Mouse;
use CPANPLUS::Backend;
use Path::Class qw(file dir);
use URI;
with 'CPAN::Packager::Role::Logger';

has 'fetcher' => (
    is      => 'rw',
    default => sub {
        CPANPLUS::Backend->new;
    }
);

sub set_cpan_mirrors {
    my ( $self, $cpan_mirrors ) = @_;
    my $hosts = [];
    foreach my $mirror (@$cpan_mirrors) {
        my $uri  = URI->new($mirror);
        my $host = {
            path   => $uri->path,
            scheme => $uri->scheme,
            host   => $uri->host,
        };
        push @{$hosts}, $host;
    }
    my $cpanp_conf = $self->fetcher->configure_object;
    $cpanp_conf->set_conf( 'hosts' => $hosts );
}

sub download {
    my ( $self, $module ) = @_;
    $self->log( info => "Downloading $module ..." );
    my $dist = $self->fetcher->parse_module( module => $module );
    return unless $dist;

    my ( $archive, $where );
    my $is_force = $dist->is_uptodate ? 0 : 1;
    eval {
        $archive = $dist->fetch( force => $is_force ) or next;
        $where = $dist->extract( force => $is_force ) or next;
    };

    return () unless $archive;

    $archive =~ /([^\/]+)\-([^-]+)\.t(ar\.)?gz$/;
    my $dist_name = $1;
    my $version   = $2;

    $dist_name =~ s/-/::/g;
    $self->log( info => "Downloaded $module ! dist is $dist_name " );
    return {
        tgz_path  => $archive,
        src_dir   => $where,
        version   => $version,
        dist_name => $dist_name
    };
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

CPAN::Packager::Downloader - Download cpan module tarball from CPAN

=head1 SYNOPSIS

  use CPAN::Packager::Downloader;
  my $d = CPAN::Packager::Downloader;
  $d->download('HTTP::Engine');

=head1 DESCRIPTION

CPAN::Packager::Downloader fetches a cpan module tarball from CPAN.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
