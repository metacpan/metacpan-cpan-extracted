package Archive::Any::Plugin::Zip;
our $VERSION = '0.0946';
use strict;
use warnings;
use base qw(Archive::Any::Plugin);

use Archive::Zip qw(:ERROR_CODES);

sub can_handle {
    return ( 'application/x-zip', 'application/x-jar', 'application/zip', );
}

sub files {
    my ( $self, $file ) = @_;

    my $z = Archive::Zip->new($file);
    return $z->memberNames;
}

sub extract {
    my ( $self, $file ) = @_;

    my $z = Archive::Zip->new($file);
    $z->extractTree;

    return 1;
}

sub type {
    my $self = shift;
    return 'zip';
}

1;

# ABSTRACT: Archive::Any wrapper around Archive::Zip

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::Any::Plugin::Zip - Archive::Any wrapper around Archive::Zip

=head1 VERSION

version 0.0946

=head1 SYNOPSIS

B<DO NOT USE THIS MODULE DIRECTLY>

Use L<Archive::Any> instead.

=head1 DESCRIPTION

Wrapper around L<Archive::Zip> for L<Archive::Any>.

=head1 AUTHORS

=over 4

=item *

Clint Moore

=item *

Michael G Schwern (author emeritus)

=item *

Olaf Alders (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Michael G Schwern, Clint Moore, Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
