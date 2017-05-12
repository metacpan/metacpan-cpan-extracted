package Archive::SimpleExtractor::Rar;

use warnings;
use strict;
use Archive::Rar;
use File::Copy;
use File::Path qw/rmtree/;
use Cwd 'abs_path';

=head1 NAME

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

=cut

=head1 METHODS

=head2 new

=cut

sub extract {
    my $self = shift;
    my %arguments = @_;
    my ($archive_file) = $arguments{archive} =~ /\/?([^\/]+)$/;
    my $old_dir = abs_path($0);
    my $old_cwd = $0;
    if ($old_cwd eq $old_dir) {
        $old_dir =~ s/[^\/]+$//;
    } else {
        $old_cwd =~ s/^\.\///;
        $old_dir =~ s/$old_cwd$//;
    }
    $arguments{dir} = abs_path($arguments{dir}).'/';
    copy($arguments{archive}, $arguments{dir}.$archive_file);
    chdir $arguments{dir};
    my $rar = Archive::Rar->new( -archive => $archive_file );
    if ( $rar->List() ) {
        unlink $archive_file;
        chdir $old_dir;
        return (0, 'Can not read archive file '.$arguments{archive})
    }
    $rar->Extract(-quiet => 1);
    if ($arguments{tree}) {
        unlink $archive_file;
        chdir $old_dir;
        return (1, 'Extract finished with directory tree');
    } else {
        if (ref $rar->{list} && ref $rar->{list} eq 'ARRAY') {
            foreach my $file (@{$rar->{list}}) {
                next unless $file->{name} =~ /\//;
                my ($filename) = $file->{name} =~ /\/([^\/]+)$/;
                copy($file->{name}, $filename);
            }
        }
        foreach my $item (<*>) {if (-d $item) {rmtree($item)}}
        unlink $archive_file;
        chdir $old_dir;
        return (1, 'Extract finished without directory tree');
    }
}

1;
