package App::Oozie::Compare::LocalToHDFS;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.016'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Types::Common qw( IsDir );
use App::Oozie::Constants qw( HDFS_COMPARE_SKIP_FILES );

use Moo;
use MooX::Options prefer_commandline => 0,
                  protect_argv       => 0,
                  usage_string       => <<'USAGE',
Usage: %c %o

Compare the local oozie code path to the deployed HDFS path
USAGE
;

use File::Find ();
use File::Spec::Functions qw( catfile catdir );
use Scalar::Util          qw( blessed );
use Types::Standard       qw( Str );

with qw(
    App::Oozie::Role::Fields::Common
    App::Oozie::Role::Log
);

option local_path => (
    is       => 'rw',
    format   => 's',
    required => 1,
    isa      => IsDir,
    doc      => 'Local path',
);

option hdfs_path => (
    is       => 'rw',
    isa      => Str,
    format   => 's',
    required => 1,
    doc      => 'HDFS path',
);

option delete => (
    is  => 'rw',
    doc => 'Cleanup HDFS based on findings?',
);

sub BUILD {
    my ($self, $args) = @_;

    my $hdfs      = $self->hdfs;
    my $hdfs_path = $self->hdfs_path;

    my $stat = $hdfs->exists( $hdfs_path )
                || die "$hdfs_path does not exist on HDFS";

    if ( $stat->{type} ne 'DIRECTORY' ) {
        die "$hdfs_path exists but it is not a directory";
    }

    return;
}

sub run {
    my $self   = shift;
    my $delete = $self->delete;
    my $logger = $self->logger;

    $logger->info(
        sprintf 'Comparing file://%s to hdfs://%s',
                $self->local_path,
                $self->hdfs_path,
    );

    my($rm_files, $rm_dirs) = $self->compare_local_to_hdfs;

    if ( 0 == @{ $rm_files } + @{ $rm_dirs } ) {
        $logger->info( 'Nothing to delete' );
        return;
    }

    my @hdfs_to_delete = ( @{ $rm_files }, @{ $rm_dirs } );

    if ( ! $delete ) {
        for my $path ( @hdfs_to_delete ) {
            $logger->info( sprintf 'Would have deleted %s', $path );
        }
        return;
    }

    my $hdfs = $self->hdfs;

    for my $path ( @hdfs_to_delete ) {
        $logger->info( sprintf 'Attempting to delete %s', $path );
        eval {
            $hdfs->delete( $path );
            1;
        } or do {
            my $eval_error = $@ || 'Zombie error';
            $logger->warn(
                sprintf 'Skipping. Failed to delete %s: %s',
                        $path,
                        $eval_error,
            );
        };
    }

    return;
}

sub compare_local_to_hdfs {
    my $self = shift;

    my $local_path = $self->local_path;
    my $hdfs_path  = $self->hdfs_path;

    my($local_dirs, $local_files) = $self->find_local_files;
    my($hdfs_dirs,  $hdfs_files ) = $self->find_hdfs_files;

    my %skip_file = map { $_ => 1 } @{ $local_files }, HDFS_COMPARE_SKIP_FILES;
    my %skip_dir  = map { $_ => 1 } @{ $local_dirs };
    my @rm_dirs   = map { catdir  $hdfs_path, $_ } grep { ! $skip_dir{  $_ } } @{ $hdfs_dirs };
    my @rm_files  = map { catfile $hdfs_path, $_ } grep { ! $skip_file{ $_ } } @{ $hdfs_files };

    return \@rm_dirs, \@rm_files;
}

sub find_hdfs_files {
    my $self      = shift;
    my $hdfs_path = $self->hdfs_path;
    my $hdfs      = $self->hdfs;
    my(@hdfs_dirs, @hdfs_files);

    $hdfs->find(
        $hdfs_path,
        sub {
            my($cwd, $path) = @_;
            my $d = $path->{type} eq 'DIRECTORY' ? \@hdfs_dirs : \@hdfs_files;
            $cwd =~ s{ \Q$hdfs_path\E [/]? }{}xms;
            push @{ $d }, $cwd ? catfile $cwd, $path->{pathSuffix} : $path->{pathSuffix};
        },
    );

    return \@hdfs_dirs, \@hdfs_files;
}

sub find_local_files {
    my $self = shift;
    my $local_path = $self->local_path;

    my(@local_dirs, @local_files);
    File::Find::find {
        wanted => sub {
            my $name = $_;
            (my $f = $name) =~ s{ \Q$local_path\E [/]? }{}xms;
            return if ! $f;
            my $d = -d $name ? \@local_dirs : \@local_files;
            push @{ $d }, $f;
        },
        no_chdir => 1,
    }, $local_path;

    return \@local_dirs, \@local_files;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Compare::LocalToHDFS

=head1 VERSION

version 0.016

=head1 SYNOPSIS

TBD

=head1 DESCRIPTION

TBD

=for Pod::Coverage BUILD

=head1 NAME

App::Oozie::Compare::LocalToHDFS - Commpares the local files against the HDFS deployment.

=head1 Methods

=head2 compare_local_to_hdfs

=head2 delete

=head2 find_hdfs_files

=head2 find_local_files

=head2 run

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
