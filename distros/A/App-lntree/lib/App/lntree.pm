package App::lntree;
BEGIN {
  $App::lntree::VERSION = '0.0013';
}
# ABSTRACT: Create a best-effort symlink-based mirror of a directory

use strict;
use warnings;

# TODO Source as file, target as file?
# TODO Absolute source, absolute target?
# TODO Test file/directory/symlink overwriting

use Path::Class;
use File::Spec;
use File::Spec::Link;
use Getopt::Usaginator <<_END_;

    Usage: lntree <source> <target>

_END_

sub run {
    my $self = shift;
    my @arguments = @_;

    usage 0 unless @arguments;
    usage "Missing <source> or <target>" unless @arguments > 1;

    my $source = shift @arguments;
    my $target = shift @arguments;

    usage "Missing <source>" unless defined $source;
    usage "Source directory ($source) does not exist or is not a directory" unless -d $source;
    usage "Target directory ($target) already exists and is a file" if -f $target;

    $self->lntree( $source, $target );
}

sub lntree {
    my $self = shift;
    my $source = shift;
    my $target = shift;

    die "Missing source" unless defined $source;
    die "Missing target" unless defined $target;
    die "Source directory ($source) does not exist or is not a directory" unless -d $source;
    die "Target directory ($target) already exists and is a file" if -f $target;

    my $dry_run = 0;

    $source = dir $source;
    $target = dir $target;
    my $absolute = $target->is_absolute;
    $source->recurse( callback => sub {
        my $file = shift;
        my ( $from_path, $to_path ) = App::lntree->resolve( $source, $target, $file );
        if ( -d $file ) {
            my $dir = $target->subdir( $to_path );
            $dry_run or $dir->mkpath;
        }
        else {
            my $file = $target->file( $to_path );
            my $link_path = $from_path;
            if ( -l $file ) {
                $dry_run or unlink $file or warn "Unable to unlink symlink \"$to_path\": $!\n";
            }
            elsif ( -e $file ) {
                return;
            }
            $dry_run or symlink $link_path, $file or die "Unable to symlink \"$link_path -> \"$to_path\": $!\n";
        }
    } );
}

sub resolve {
    my $self = shift;
    my $from = dir shift;
    my $to = dir shift;
    my $path = shift;

    my $absolute = File::Spec->file_name_is_absolute( $to );

    my $from_path;
    if ( $absolute ) {
        $from_path = File::Spec->rel2abs( $path );
    }
    else {
        my @path = File::Spec->splitdir( $path );
        my $depth = @path - ( 1 + $from->dir_list );
        $from_path = File::Spec->canonpath( join '/', ( ( '..' ) x $depth ), File::Spec->abs2rel( $path, $to ) );
    }

    my $to_path = File::Spec->canonpath( join '/', File::Spec->abs2rel( $path, $from ) );

    return ( $from_path, $to_path );
}

1;



=pod

=head1 NAME

App::lntree - Create a best-effort symlink-based mirror of a directory

=head1 VERSION

version 0.0013

=head1 SYNOPSIS

    lntree ~/project1 target/
    lntree ~/project2 target/

    # target/ is now a combination of project1 & project2, with project2 taking precedence

=head1 DESCRIPTION

App::lntree is a utility for making a best-effort symlink-based mirror of a directory. The algorithm is:

    - Directories are always recreated, NOT symlinked
    - A symlink conflict will be resolved by removing the original symlink
    - Regular files (including directories) are left untouched

=head1 USAGE

=head2 lntree <source> <target>

Create a symlink mirror of <source> into <target>, creating <target> if necessary

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

