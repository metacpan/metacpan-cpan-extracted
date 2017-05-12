package Catalyst::Plugin::Compress;

use strict;
use Catalyst::Utils;
use MRO::Compat;

our $VERSION = '0.006';

my $_method;
my %_compression_lib = (
    gzip => 'Compress::Zlib',
    deflate => 'Compress::Zlib',
    bzip2 => 'Compress::Bzip2',
);

sub _gzip_compress {
    Compress::Zlib::memGzip(shift);
}

sub _bzip2_compress {
    Compress::Bzip2::memBzip(shift);
}

sub _deflate_compress {
    my $content = shift;
    my $result;

    my ($d, $out, $status);
    ($d, $status) = Compress::Zlib::deflateInit(
        -WindowBits => -Compress::Zlib::MAX_WBITS(),
    );
    unless ($status == Compress::Zlib::Z_OK()) {
        die("Cannot create a deflation stream. Error: $status");
    }

    ($out, $status) = $d->deflate($content);
    unless ($status == Compress::Zlib::Z_OK()) {
        die("Deflation failed. Error: $status");
    }
    $result .= $out;

    ($out, $status) = $d->flush;
    unless ($status == Compress::Zlib::Z_OK()) {
        die("Deflation failed. Error: $status");
    }

    return $result . $out;
}

sub setup {
    my $c = shift;
    if ($_method = $c->config->{compression_format}) {
        $_method = 'gzip'
            if $_method eq 'zlib';

        my $lib_name = $_compression_lib{$_method};
        die qq{No compression_format named "$_method"}
            unless $lib_name;
        Catalyst::Utils::ensure_class_loaded($lib_name);

        *_do_compress = \&{"_${_method}_compress"};
    }
    if ($c->debug) {
        $_method
            ? $c->log->debug(qq{Catalyst::Plugin::Compress sets compression_format to '$_method'})
            : $c->log->debug(qq{Catalyst::Plugin::Compress has no compression_format config - disabled.});
    }
    $c->maybe::next::method(@_);
}

use List::Util qw(first);
sub should_compress_response {
    my ($self) = @_;
    my ($ct) = split /;/, $self->res->content_type;
    my @compress_types = qw(
        application/javascript
        application/json
        application/x-javascript
        application/xml
    );
    return 1
        if ($ct =~ m{^text/})
            or ($ct =~ m{\+xml$}
            or (first { lc($ct) eq $_ } @compress_types));
}

sub finalize {
    my $c = shift;

    if ((not defined $_method)
        or $c->res->content_encoding
        or (not $c->res->body)
        or ($c->res->status != 200)
        or (not $c->should_compress_response)
    ) {
        return $c->maybe::next::method(@_);
    }

    my $accept = $c->request->header('Accept-Encoding') || '';

    unless (index($accept, $_method) >= 0) {
        return $c->maybe::next::method(@_);
    }

    # Hack to support newer Catalyst.  We need to invokce the encoding stuff
    # Now since after the content encoding header is set, we can no longer
    # call that method. (jnap, to support 590080+)
    $c->finalize_encoding if($c->can('encoding') and $c->can('clear_encoding'));

    my $body = $c->res->body;
    if (ref $body) {
        eval { local $/; $body = <$body> };
        die "Unknown type of ref in body."
            if ref $body;
    }

    my $compressed = _do_compress($body);
    $c->response->body($compressed);
    $c->response->content_length(length($compressed));
    $c->response->content_encoding($_method);
    $c->response->headers->push_header('Vary', 'Accept-Encoding');

    $c->maybe::next::method(@_);
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Compress - Compress response

=head1 SYNOPSIS

    use Catalyst qw/Compress/;

or (Catalyst pre Unicode Merge, and If you want to use this plugin with
L<Catalyst::Plugin::Unicode>.)

    use Catalyst qw/
        Unicode
        Compress
    /;

or (Catalyst 5.90080 and later)

    use Catalyst qw/
        Compress
    /;


Remember to specify compression_format with:

    __PACKAGE__->config(
        compression_format => $format,
    );

$format can be either gzip bzip2 zlib or deflate.  bzip2 is B<*only*> supported
by lynx and some other console text-browsers.

=head1 DESCRIPTION

This module combines L<Catalyst::Plugin::Deflate> L<Catalyst::Plugin::Gzip>
L<Catalyst::Plugin::Zlib> into one.

It compress response to [gzip bzip2 zlib deflate] if client supports it.  In other
works the client should send the Accept-Encoding HTTP header with a supported
compression like 'gzip'.

B<NOTE>: If you are using an older version of L<Catalyst> that requires the Unicode
plugin and if you want to use this module with L<Catalyst::Plugin::Unicode>, You
B<MUST> load this plugin B<AFTER> L<Catalyst::Plugin::Unicode>.

    use Catalyst qw/
        Unicode
        Compress
    /;

If you don't, You'll get error which is like:

[error] Caught exception in engine "Wide character in subroutine entry at
/usr/lib/perl5/site_perl/5.8.8/Compress/Zlib.pm line xxx."

If you upgrade to any version of L<Catalyst> 5.90080+ the unicode support has been
integrated into core code and this plugin is designed to work with that.

=head1 INTERNAL METHODS

=head2 should_compress_response

This method determine wether compressing the reponse using this plugin.

=head1 SEE ALSO

L<Catalyst>.

=head1 AUTHOR

Yiyi Hu C<yiyihu@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

