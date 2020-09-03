package CTK::Plugin::Net;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin::Net - Net plugin

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use CTK;
    my $ctk = new CTK(
            plugins => "net",
        );

    $ctk->fetch(
        -url     => 'ftp://anonymous:anonymous@192.168.200.8/path/srs?Timeout=30&Passive=1',
        -command => "copy", # copy / move
        -uniq    => "off",
        -dirdst  => "/path/to/destination/dir", # Destination directory
        -regexp  => qr/tmp$/,
    );

    $ctk->store(
        -url     => 'ftp://anonymous:anonymous@192.168.200.8/path/dst?Timeout=30&Passive=1',
        -command => "copy", # copy / move
        -uniq    => "off",
        -dirsrc => "/path/to/source/dir", # Source directory
        -regexp   => qr/tmp$/,
    )

=head1 DESCRIPTION

Net plugin. This plugin is proxy to L<CTK::Plugin::FTP> and L<CTK::Plugin::SFTP> plugins

=head1 METHODS

=over 8

=item B<fetch>

Download specified files from remote resource

See related modules description

=item B<store>

Upload files from local directory to remote resource by mask

See related modules description

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<CTK::Plugin>

=head1 TO DO

* Use SSH (SFTP)

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>, L<CTK::Plugin::SFTP>, L<CTK::Plugin::FTP>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2020 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.01';

use base qw/
        CTK::Plugin::FTP
        CTK::Plugin::SFTP
    /;

use CTK::Util qw/:API/;
use URI;

__PACKAGE__->register_method(
    method    => "fetch",
    callback  => sub {
    my $self = shift;
    my %args = @_;
    my ($url, $op) =
        read_attributes([
            ['URL', 'URI'],
            ['OP', 'OPER', 'OPERATION', 'CMD', 'COMMAND'],
        ], @_);

    # Valid data
    my $uri;
    if (ref($url) && $url->isa("URI")) { $uri = $url->clone }
    elsif ($url) { $uri = new URI($url) }
    else {
        $self->error("Incorrect URL or URI object!");
        return;
    }
    $op ||= '';
    $args{"uri"} = $uri;
    $args{"uniq"} = 1 if $op =~ /uniq/;

    # Proxy
    if ($uri->scheme eq 'ftp') {
        return $self->fetch_ftp(%args);
    } elsif ($uri->scheme eq 'sftp') {
        return $self->fetch_sftp(%args);
    }

    $self->error("Scheme not allowed");
    return;
});

__PACKAGE__->register_method(
    method    => "store",
    callback  => sub {
    my $self = shift;
    my %args = @_;
    my ($url, $op) =
        read_attributes([
            ['URL', 'URI'],
            ['OP', 'OPER', 'OPERATION', 'CMD', 'COMMAND'],
        ], @_);

    # Valid data
    my $uri;
    if (ref($url) && $url->isa("URI")) { $uri = $url->clone }
    elsif ($url) { $uri = new URI($url) }
    else {
        $self->error("Incorrect URL or URI object!");
        return;
    }
    $op ||= '';
    $args{"uri"} = $uri;
    $args{"uniq"} = 1 if $op =~ /uniq/;

    # Proxy
    if ($uri->scheme eq 'ftp') {
        return $self->store_ftp(%args);
    } elsif ($uri->scheme eq 'sftp') {
        return $self->store_sftp(%args);
    }

    $self->error("Scheme not allowed");
    return;
});

1;

__END__
