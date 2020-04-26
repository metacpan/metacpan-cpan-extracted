package Code::TidyAll::Git::Util;

use strict;
use warnings;

use File::pushd qw(pushd);
use IPC::System::Simple qw(capturex);
use List::SomeUtils qw(uniq);
use Path::Tiny qw(path);

use Exporter qw(import);

our $VERSION = '0.78';

our @EXPORT_OK = qw(git_files_to_commit git_modified_files);

sub git_files_to_commit {
    my ($dir) = @_;
    return _relevant_files_from_status( $dir, 1 );
}

sub git_modified_files {
    my ($dir) = @_;
    return _relevant_files_from_status( $dir, 0 );
}

sub _relevant_files_from_status {
    my ( $dir, $index_only ) = @_;

    $dir = path($dir);
    my $pushed = pushd( $dir->absolute );
    my $status = capturex(qw( git status --porcelain -z -uno ));

    return unless $status;

    return map { $dir->child($_) } _parse_status( $status, $index_only );
}

sub _parse_status {
    my ( $status, $index_only ) = @_;

    local $_ = $status;

    # There can't possibly be more records than nuls plus one, so we use this
    # as an upper bound on passes.
    my $times = tr/\0/\0/;

    my @files;

    for my $i ( 0 .. $times ) {
        last if /\G\Z/gc;

        /\G(..) /g;
        my $mode = $1;

        /\G([^\0]+)\0/g;
        my $name = $1;

        # on renames, parse but throw away the "renamed from" filename
        if ( $mode =~ /[CR]/ ) {
            /\G([^\0]+)\0/g;
        }

        # deletions and renames don't cause tidying
        next unless $mode =~ /[MA]/;
        next if $index_only && $mode =~ /^ /;

        push @files, $name;
    }

    return @files;
}

1;

# ABSTRACT: Utilities for the git hook classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Git::Util - Utilities for the git hook classes

=head1 VERSION

version 0.78

=head1 SUPPORT

Bugs may be submitted at
L<https://github.com/houseabsolute/perl-code-tidyall/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Code-TidyAll can be found at
L<https://github.com/houseabsolute/perl-code-tidyall>.

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2020 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut
