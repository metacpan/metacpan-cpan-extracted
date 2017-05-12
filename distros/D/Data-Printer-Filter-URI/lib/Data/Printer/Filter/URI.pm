package Data::Printer::Filter::URI;
# ABSTRACT: pretty-printing URI objects

use strict;
use utf8;
use warnings qw(all);

use Data::Printer::Filter;
use Term::ANSIColor;

our $VERSION = '0.008'; # VERSION


our @schemes = qw(
    URL
    data
    file
    ftp
    gopher
    http
    https
    ldap
    ldapi
    ldaps
    mailto
    mms
    news
    nntp
    pop
    rlogin
    rsync
    rtsp
    rtspu
    sip
    sips
    snews
    ssh
    telnet
    tn3270
    urn
    urn::oid
);

filter $_ => sub {
    my ($obj, $p) = @_;

    my $str = qq($obj);

    $str =~ s{^
        \b
        @{[$obj->scheme]}
        \b
    }{
        colored(
            $obj->scheme,
            exists($p->{color}{uri_scheme})
                ? $p->{color}{uri_scheme}
                : q(bright_green)
        )
    }ex if defined $obj->scheme;

    $str =~ s{
        \b
        \Q@{[$obj->host]}\E
        \b
    }{
        colored(
            $obj->host,
            exists($p->{color}{uri_host})
                ? $p->{color}{uri_host}
                : q(bold)
        )
    }ex if $obj->can(q(host))
        and defined $obj->host;

    return $str;
} for qw(Mojo::URL), map +qq(URI::$_), @schemes, qw(
    scp
    sftp
    urn::isbn
    urn::uuid
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Printer::Filter::URI - pretty-printing URI objects

=head1 VERSION

version 0.008

=head1 SYNOPSIS

# In your program:

    use Data::Printer filters => {
        -external => [ 'URI' ],
    };

# or, in your C<.dataprinter> file:

    {
        filters => {
            -external => [ 'URI' ],
        },
    };

# You can also setup color and display details:

    use Data::Printer {
        filters => {
            -external   => [ 'URI' ],
        }, color => {
            uri_scheme  => 'bright_green',
            uri_host    => 'bold',
        },
    };

=head1 DESCRIPTION

This is a filter plugin for L<Data::Printer>.
It filters through several L<URI> manipulation classes and displays the L<URI> as a fancy string.

=head2 Parsed Protocols

=over 4

=item *

data

=item *

file

=item *

ftp

=item *

gopher

=item *

http

=item *

https

=item *

ldap

=item *

ldapi

=item *

ldaps

=item *

mailto

=item *

mms

=item *

news

=item *

nntp

=item *

pop

=item *

rlogin

=item *

rsync

=item *

rtsp

=item *

rtspu

=item *

scp (if L<URI::scp> is present)

=item *

sftp (if L<URI::sftp> is present)

=item *

sip

=item *

sips

=item *

snews

=item *

ssh

=item *

telnet

=item *

tn3270

=item *

urn

=back

L<Mojo::URL> is also supported.

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
