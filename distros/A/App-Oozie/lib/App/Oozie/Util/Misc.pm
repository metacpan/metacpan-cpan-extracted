package App::Oozie::Util::Misc;

use 5.014;
use strict;
use warnings;
use parent qw( Exporter );

our $VERSION = '0.017'; # VERSION

our @EXPORT_OK = qw(
    remove_newline
    resolve_tmp_dir
    trim_slashes
);

sub remove_newline {
    my $s = shift;
    $s =~ s{\n+}{ }xmsg;
    return $s;
}

sub resolve_tmp_dir {
    # Wokaround "/tmp is an existing symbolic link" error.
    # Happens in EMR for example.
    #
    my $tmp = $ENV{TMPDIR} || $ENV{TMP} || '/tmp';
    return $tmp if ! -l $tmp;
    my $real = readlink $tmp;
    return $real;
}

sub trim_slashes {
    my $s = shift;
    return $s if ! $s;
    # removing  both the leading and trailing path separators
    $s =~ s{ \A [/]    }{}xms;
    $s =~ s{    [/] \z }{}xms;
    return $s;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Util::Misc

=head1 VERSION

version 0.017

=head1 SYNOPSIS

    use App::Oozie::Util::Misc qw( remove_newline );

=head1 DESCRIPTION

Internal module.

=head1 NAME

App::Oozie::Util::Misc - Miscellaneous utility functions

=head1 Methods

=head2 remove_newline

=head2 resolve_tmp_dir

=head2 trim_slashes

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
