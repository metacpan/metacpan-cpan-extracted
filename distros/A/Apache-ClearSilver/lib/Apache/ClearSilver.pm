package Apache::ClearSilver;
use strict;
use warnings;

use Apache::Constants qw(:common);
use Apache::ModuleConfig;
use DynaLoader ();
use ClearSilver;

our $VERSION = '0.01';

if ($ENV{MOD_PERL}) {
    no strict;
    @ISA = qw(DynaLoader);
    __PACKAGE__->bootstrap($VERSION);
}

sub handler ($$) {
    my ($class, $r) = @_;
    my $cfg = Apache::ModuleConfig->get($r) || {};
    $class->render($r, $cfg);
}

sub render {
    my ($class, $r, $cfg) = @_;
    my $hdf = $class->create_hdf($r, $cfg);
    return DECLINED unless $hdf;
    my $cs = ClearSilver::CS->new($hdf);
    unless ($cs->parseFile($r->filename)) {
        $r->log_reason("cannot parse file " . $r->filename . '.');
        return DECLINED;
    }
    my $output = $cs->render;
    my $type = $cfg->{CSContentType} || 'text/html';
    $r->content_type($type);
    $r->header_out('Content-Length' => length $output);
    $r->send_http_header;
    $r->print($output);
    return OK;
}

sub create_hdf {
    my ($class, $r, $cfg) = @_;
    my $hdf = ClearSilver::HDF->new;
    $cfg->{HDFLoadPath} ||= [];
    _hdf_setValue($hdf, 'hdf.loadpaths', $cfg->{HDFLoadPath});
    for my $file (@{$cfg->{HDFFile}}) {
        my $ret = $hdf->readFile($file);
        unless ($ret) {
            $r->log_reason("cannot open file $file.");
            return;
        }
    }
    while (my ($key, $val) = each(%{$cfg->{HDFValue}})) {
        $hdf->setValue($key, $val);
    }
    my %query = $r->args;
    _hdf_setValue($hdf, 'Query', \%query);
    my $http = {
        Accept         => $ENV{HTTP_ACCEPT}          || '',
        AcceptEncoding => $ENV{HTTP_ACCEPT_ENCODING} || '',
        AcceptLanguage => $ENV{HTTP_ACCEPT_LANGUAGE} || '',
        Cookie         => $ENV{HTTP_COOKIE}          || '',
        Host           => $ENV{HTTP_HOST}            || '',
        UserAgent      => $ENV{HTTP_USER_AGENT}      || '',
        Referer        => $ENV{HTTP_REFERER}         || '',
    };
    _hdf_setValue($hdf, 'HTTP', $http);
    my $cgi = {
        DocumentRoot   => $ENV{DOCUMENT_ROOT}   || '',
        QueryString    => $ENV{QUERY_STRING}    || '',
        RemoteAddress  => $ENV{REMOTE_ADDR}     || '',
        RemotePort     => $ENV{REMOTE_PORT}     || '',
        RequestMethod  => $ENV{REQUEST_METHOD}  || '',
        RequestURI     => $ENV{REQUEST_URI}     || '',
        ScriptFilename => $ENV{SCRIPT_FILENAME} || '',
        ScriptName     => $ENV{SCRIPT_NAME}     || '',
        ServerAddress  => $ENV{SERVER_ADDR}     || '',
        ServerAdmin    => $ENV{SERVER_ADMIN}    || '',
        ServerName     => $ENV{SERVER_NAME}     || '',
        ServerPort     => $ENV{SERVER_PORT}     || '',
        ServerProtocol => $ENV{SERVER_PROTOCOL} || '',
        ServerSoftware => $ENV{SERVER_SOFTWARE} || '',
    };
    _hdf_setValue($hdf, 'CGI', $cgi);
    $hdf;
}

sub _hdf_setValue {
    my ($hdf, $key, $val) = @_;
    if (ref $val eq 'ARRAY') {
        my $index = 0;
        for my $v (@$val) {
            _hdf_setValue($hdf, "$key.$index", $v);
            $index++;
        }
    } elsif (ref $val eq 'HASH') {
        while (my ($k, $v) = each %$val) {
            _hdf_setValue($hdf, "$key.$k", $v);
        }
    } elsif (ref $val eq 'SCALAR') {
        _hdf_setValue($hdf, $key, $$val);
    } elsif (ref $val eq '') {
        $hdf->setValue($key, $val);
    }
}

sub HDFLoadPath($$@) {
    my ($cfg, $params, $arg) = @_;
    my $paths = $cfg->{HDFLoadPath} ||= [];
    push @$paths, $arg;
}

sub HDFFile($$@) {
    my ($cfg, $params, $arg) = @_;
    my $paths = $cfg->{HDFFile} ||= [];
    push @$paths, $arg;
}

sub HDFSetValue($$$$) {
    my ($cfg, $parms, $name, $value) = @_;
    $cfg->{HDFValue}->{$name} = $value;
}

sub CSContentType($$$) {
    my ($cfg, $params, $arg) = @_;
    $cfg->{CSContentType} = $arg;
}

1;
__END__

=head1 NAME

Apache::ClearSilver - Apache/mod_perl interface to the ClearSilver template system.

=head1 SYNOPSIS

    # add the following to your httpd.conf
    PerlModule          Apache::Template

    # set various configuration options, e.g.
    HDFLoadPath /path/to/loadpath /path/to/anotherpath
    HDFFile     /path/to/mydata.hdf /path/to/mydata2.hdf
    HDFSetValue Foo bar
    CSContentType "text/html; charset=utf-8"

    # now define Apache::Clearsilver as a PerlHandler, e.g.
    <Files *.cs>
      SetHandler   perl-script
      PerlHandler  Apache::Template
    </Files>

=head1 DESCRIPTION

Apache::ClearSilver is Apache/mod_perl interface to the ClearSilver template system.

implementing ClearSilver CGI Kit.

=head1 CONFIGURATION

=over 4

=item HDFLoadPath

added to hdf.loadpaths.

=item HDFFile

HDF Dataset files into the current HDF object.

=item HDFSetValue

set HDF value.

=item CSContentType

set Content-Type. (default text/html)

=back

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache>

ClearSilver Documentation:  L<http://www.clearsilver.net/docs/>

=cut
