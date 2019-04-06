package Archive::Any::Zip;
our $VERSION = '0.0946';
use strict;
use warnings;

use base 'Archive::Any';

use Archive::Zip qw(:ERROR_CODES);
use Cwd;

sub new {
    my ( $class, $file ) = @_;

    my $self = bless {}, $class;

    Archive::Zip::setErrorHandler( sub { } );
    $self->{handler} = Archive::Zip->new($file);
    return unless $self->{handler};

    $self->{file} = $file;

    return $self;
}

sub files {
    my ($self) = shift;

    $self->{handler}->memberNames;
}

sub extract {
    my ( $self, $dir ) = @_;

    my $orig_dir;
    if ($dir) {
        $orig_dir = getcwd;
        chdir $dir;
    }

    $self->{handler}->extractTree;

    if ($dir) {
        chdir $orig_dir;
    }

    return 1;
}

sub type {
    return 'zip';
}

=pod

=encoding UTF-8

=head1 NAME

Archive::Any::Zip - Archive::Any wrapper around Archive::Zip

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

__END__


1;

# ABSTRACT: Archive::Any wrapper around Archive::Zip
