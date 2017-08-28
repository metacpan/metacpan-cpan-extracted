#!/usr/bin/env perl
# ABSTRACT: tool to convert between various formats and encodings
#
# muter - a data transformation tool
#
# Copyright © 2016–2017 brian m. carlson
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
package App::Muter;
$App::Muter::VERSION = '0.002002';
require 5.010001;

use strict;
use warnings;
use feature ':5.10';

my $experimental;
BEGIN {
    $experimental = 1 if exists $warnings::Offsets{'experimental::smartmatch'};
}
no if $experimental, warnings => 'experimental::smartmatch';


## no critic(ProhibitMultiplePackages)
package App::Muter::Main;
$App::Muter::Main::VERSION = '0.002002';
use App::Muter::Backend ();
use App::Muter::Chain   ();
use FindBin             ();
use Getopt::Long        ();
use IO::Handle          ();
use IO::File            ();

use File::stat;

sub script {
    my (@args) = @_;

    my $chain = '';
    my $help;
    my $verbose;
    my $reverse;
    Getopt::Long::GetOptionsFromArray(
        \@args,
        'chain|c=s'  => \$chain,
        'verbose|v'  => \$verbose,
        'reverse|r!' => \$reverse,
        'help'       => \$help
        ) or
        return usage(1);

    load_backends();

    return usage(0, $verbose) if $help;
    return usage(1) unless $chain;

    run_chain($chain, $reverse, load_handles(\@args), \*STDOUT);

    return 0;
}

sub _uniq {    ## no critic(RequireArgUnpacking)
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

sub load_backends {
    App::Muter::Registry->instance->load_backends();
    return;
}

sub load_handles {
    my ($files) = @_;
    my @handles = map { IO::File->new($_, 'r') } @$files;
    @handles = (\*STDIN) unless @handles;
    return \@handles;
}

sub run_chain {
    my ($chain, $reverse, $handles, $stdout, $blocksize) = @_;

    $chain = App::Muter::Chain->new($chain, $reverse);
    $blocksize ||= 512;

    foreach my $io (@$handles) {
        $io->binmode(1);
        while ($io->read(my $buf, $blocksize)) {
            $stdout->print($chain->process($buf));
        }
    }
    $stdout->print($chain->final(''));
    return;
}

sub usage {
    my ($ret, $verbose) = @_;
    my $fh = $ret ? \*STDERR : \*STDOUT;
    $fh->print(<<'EOM');
muter [-r | --reverse] -c CHAIN | --chain CHAIN [FILES...]
muter [--verbose] --help

Modify the bytes in the concatentation of FILES (or standard input) by using the
specification in CHAIN.

CHAIN is a colon-separated list of encoding transform.  A transform can be
prefixed with - to reverse it (if possible).  A transform can be followed by one
or more comma-separated parenthesized arguments as well.  Instead of
parentheses, a single comma may be used.

For example, '-hex:hash(sha256):base64' (or '-hex:hash,sha256:base64') decodes a
hex-encoded string, hashes it with SHA-256, and converts the result to base64.

If --reverse is specified, reverse the order of transforms in order and in sense.

The following transforms are available:
EOM
    my $reg = App::Muter::Registry->instance;
    foreach my $name ($reg->backends) {
        $fh->print("  $name\n");
        my $meta = $reg->info($name);
        if ($meta->{args} && ref($meta->{args}) eq 'HASH') {
            my @keys = sort keys %{$meta->{args}};
            if ($verbose) {
                $fh->printf("    %-10s: %s\n", $_, $meta->{args}->{$_})
                    for @keys;
            }
            else {
                $fh->print("    ", join(', ', sort keys %{$meta->{args}}),
                    "\n");
            }
        }
    }
    return $ret;
}

package App::Muter::Interface;
$App::Muter::Interface::VERSION = '0.002002';
sub process {
    my ($chain, $data) = @_;

    $chain = App::Muter::Chain->new($chain);
    my $result = $chain->process($data);
    $result .= $chain->final('');

    return $result;
}

package App::Muter::Registry;
$App::Muter::Registry::VERSION = '0.002002';
use File::Spec;

my $instance;

sub instance {
    my $class = shift;
    $class = ref($class) || $class;
    my $self = {names => {}};
    return $instance ||= bless $self, $class;
}

sub register {
    my ($self, $class) = @_;
    my $info = $class->metadata;
    $self->{names}{$info->{name}} = {%$info, class => $class};
    return 1;
}

sub info {
    my ($self, $name) = @_;
    my $info = $self->{names}{$name};
    die "No such transform '$name'" unless $info;
    return $info;
}

sub backends {
    my ($self) = @_;
    my @backends = sort keys %{$self->{names}};
    return @backends;
}

sub load_backends {
    my ($self) = @_;
    my @modules = map { /^([A-Za-z0-9]+)\.pm$/ ? ($1) : () } map {
        my $dh;
        opendir($dh, $_) ? readdir($dh) : ()
    } map { File::Spec->catfile($_, qw/App Muter Backend/) } @INC;
    eval "require App::Muter::Backend::$_;"    ##no critic(ProhibitStringyEval)
        for @modules;
    return;
}

package App::Muter::Backend::Chunked;
$App::Muter::Backend::Chunked::VERSION = '0.002002';
our @ISA = qw/App::Muter::Backend/;

sub new {
    my ($class, $args, %opts) = @_;
    my $self = $class->SUPER::new($args, %opts);
    $self->{chunk}       = '';
    $self->{enchunksize} = $opts{enchunksize} || $opts{chunksize};
    $self->{dechunksize} = $opts{dechunksize} || $opts{chunksize};
    return $self;
}

sub encode {
    my ($self, $data) = @_;
    return $self->_with_chunk($data, $self->{enchunksize}, 'encode_chunk');
}

sub decode {
    my ($self, $data) = @_;
    return $self->_with_chunk($data, $self->{dechunksize}, 'decode_chunk');
}

sub encode_final {
    my ($self, $data) = @_;
    return $self->encode_chunk($self->{chunk} . $data);
}

sub decode_final {
    my ($self, $data) = @_;
    return $self->decode_chunk($self->{chunk} . $data);
}

sub _with_chunk {
    my ($self, $data, $chunksize, $code) = @_;
    my $chunk = $self->{chunk} . $data;
    my $len   = length($chunk);
    my $rem   = $len % $chunksize;
    if ($rem) {
        $self->{chunk} = substr($chunk, -$rem);
        $chunk = substr($chunk, 0, -$rem);
    }
    else {
        $self->{chunk} = '';
    }
    return $self->$code($chunk);
}

package App::Muter::Backend::ChunkedDecode;
$App::Muter::Backend::ChunkedDecode::VERSION = '0.002002';
our @ISA = qw/App::Muter::Backend/;

sub new {
    my ($class, $args, %opts) = @_;
    my $self = $class->SUPER::new($args, %opts);
    $self->{chunk}  = '';
    $self->{regexp} = $opts{regexp};
    return $self;
}

sub encode {
    my ($self, $data) = @_;
    return $self->encode_chunk($data);
}

sub decode {
    my ($self, $data) = @_;
    $data = $self->{chunk} . $data;
    if ($data =~ $self->{regexp}) {
        $data = $1 // '';
        $self->{chunk} = $2;
    }
    else {
        $self->{chunk} = '';
    }
    return $self->decode_chunk($data);
}

sub encode_final {
    my ($self, $data) = @_;
    return $self->encode_chunk($self->{chunk} . $data);
}

sub decode_final {
    my ($self, $data) = @_;
    return $self->decode_chunk($self->{chunk} . $data);
}

package App::Muter::Backend::Base64;
$App::Muter::Backend::Base64::VERSION = '0.002002';
use MIME::Base64 ();

our @ISA = qw/App::Muter::Backend::Chunked/;

sub new {
    my ($class, $args, %opts) = @_;
    my $nl = (grep { $_ eq 'mime' } @$args) ? "\n" : '';
    my $self = $class->SUPER::new(
        $args, %opts,
        enchunksize => $nl ? 57 : 3,
        dechunksize => 4
    );
    $self->{nl} = $nl;
    if (grep { $_ eq 'yui' } @$args) {
        $self->{exfrm} = sub { (my $x = shift) =~ tr{+/=}{._-}; return $x };
        $self->{dxfrm} = sub { (my $x = shift) =~ tr{._-}{+/=}; return $x };
    }
    else {
        $self->{exfrm} = sub { return shift };
        $self->{dxfrm} = sub { return shift };
    }
    return $self;
}

sub encode_chunk {
    my ($self, $data) = @_;
    return $self->{exfrm}->(MIME::Base64::encode($data, $self->{nl}));
}

sub _filter {
    my ($self, $data) = @_;
    $data =~ tr{A-Za-z0-9+/=}{}cd;
    return $data;
}

sub decode {
    my ($self, $data) = @_;
    $data = $self->{dxfrm}->($data);
    return $self->SUPER::decode($self->_filter($data));
}

sub decode_chunk {
    my (undef, $data) = @_;
    return MIME::Base64::decode($data);
}

App::Muter::Registry->instance->register(__PACKAGE__);

package App::Muter::Backend::URL64;
$App::Muter::Backend::URL64::VERSION = '0.002002';
use MIME::Base64 3.11 ();
our @ISA = qw/App::Muter::Backend::Base64/;

sub encode_chunk {
    my (undef, $data) = @_;
    return MIME::Base64::encode_base64url($data);
}

sub _filter {
    my (undef, $data) = @_;
    return $data;
}

sub decode_chunk {
    my (undef, $data) = @_;
    return MIME::Base64::decode_base64url($data);
}

App::Muter::Registry->instance->register(__PACKAGE__);

package App::Muter::Backend::Hex;
$App::Muter::Backend::Hex::VERSION = '0.002002';
our @ISA = qw/App::Muter::Backend::Chunked/;

sub new {
    my ($class, $args, %opts) = @_;
    my $self = $class->SUPER::new(
        $args, %opts,
        enchunksize => 1,
        dechunksize => 2
    );
    $self->{upper} = 1 if defined $args->[0] && $args->[0] eq 'upper';
    return $self;
}

sub metadata {
    my $self = shift;
    my $meta = $self->SUPER::metadata;
    return {
        %$meta,
        args => {
            upper => 'Use uppercase letters',
            lower => 'Use lowercase letters',
        }
    };
}

sub encode_chunk {
    my ($self, $data) = @_;
    my $result = unpack("H*", $data);
    return uc $result if $self->{upper};
    return $result;
}

sub decode_chunk {
    my (undef, $data) = @_;
    return pack("H*", $data);
}

App::Muter::Registry->instance->register(__PACKAGE__);

package App::Muter::Backend::Base16;
$App::Muter::Backend::Base16::VERSION = '0.002002';
our @ISA = qw/App::Muter::Backend::Hex/;

sub new {
    my ($class, $args, %opts) = @_;
    my $self = $class->SUPER::new(['upper'], %opts);
    return $self;
}

sub metadata {
    my $self = shift;
    my $meta = $self->SUPER::metadata;
    delete $meta->{args};
    return $meta;
}

App::Muter::Registry->instance->register(__PACKAGE__);

package App::Muter::Backend::Base32;
$App::Muter::Backend::Base32::VERSION = '0.002002';
our @ISA = qw/App::Muter::Backend::Chunked/;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args, enchunksize => 5, dechunksize => 8);
    $self->{ftr} =
        sub { my $val = shift; $val =~ tr/\x00-\x1f/A-Z2-7/; return $val };
    $self->{rtr} =
        sub { my $val = shift; $val =~ tr/A-Z2-7/\x00-\x1f/; return $val };
    $self->{func} = 'base32';
    $self->{manual} =
        grep { $_ eq 'manual' } @args ||
        !eval { require MIME::Base32; MIME::Base32->VERSION(1.0) };
    return $self->_initialize;
}

sub _initialize {
    my ($self) = @_;
    unless ($self->{manual}) {
        $self->{eref} = MIME::Base32->can("encode_$self->{func}");
        $self->{dref} = MIME::Base32->can("decode_$self->{func}");
    }
    return $self;
}

sub encode_chunk {
    my ($self, $data) = @_;
    return '' unless length($data);
    return $self->{eref}->($data) if $self->{eref};
    my $len      = length($data);
    my $rem      = $len % 5;
    my $lenmap   = [0, 2, 4, 5, 7, 8];
    my $lm       = $lenmap->[$rem];
    my @data     = (unpack('C*', $data), ($rem ? ((0) x (5 - $rem)) : ()));
    my $result   = '';
    my $truncate = int($len / 5) * 8 + $lm;
    while (my @chunk = splice(@data, 0, 5)) {
        my @converted = map { $_ & 0x1f } (
            $chunk[0] >> 3,
            ($chunk[0] << 2) | ($chunk[1] >> 6),
            ($chunk[1] >> 1),
            ($chunk[1] << 4) | ($chunk[2] >> 4),
            ($chunk[2] << 1) | ($chunk[3] >> 7),
            ($chunk[3] >> 2),
            ($chunk[3] << 3) | ($chunk[4] >> 5),
            $chunk[4]
        );
        $result .= pack('C*', @converted);
    }
    $result = substr($result, 0, $truncate);
    $result .= $lm ? ('=' x (8 - $lm)) : '';
    return $self->{ftr}->($result);
}

sub decode_chunk {
    my ($self, $data) = @_;
    return '' unless length($data);
    return $self->{dref}->($data) if $self->{dref};
    my $lenmap = [5, 4, undef, 3, 2, undef, 1];
    my $trailing = $data =~ /(=+)$/ ? length $1 : 0;
    my $truncate = $lenmap->[$trailing];
    my $result   = '';
    my @data     = unpack('C*', $self->{rtr}->($data));
    use bytes;

    while (my @chunk = splice(@data, 0, 8)) {
        my @converted = (
            ($chunk[0] << 3) | ($chunk[1] >> 2),
            ($chunk[1] << 6) | ($chunk[2] << 1) | ($chunk[3] >> 4),
            ($chunk[3] << 4) | ($chunk[4] >> 1),
            ($chunk[4] << 7) | ($chunk[5] << 2) | ($chunk[6] >> 3),
            ($chunk[6] << 5) | $chunk[7],
        );
        my $chunk = pack('C*', map { $_ & 0xff } @converted);
        $result .= substr($chunk, 0, (@data ? 5 : $truncate));
    }
    return $result;
}

sub metadata {
    my $self = shift;
    my $meta = $self->SUPER::metadata;
    return {
        %$meta,
        args => {
            'manual' => 'Disable use of MIME::Base32',
        }
    };
}

App::Muter::Registry->instance->register(__PACKAGE__);

package App::Muter::Backend::Base32Hex;
$App::Muter::Backend::Base32Hex::VERSION = '0.002002';
our @ISA = qw/App::Muter::Backend::Base32/;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->{ftr} =
        sub { my $val = shift; $val =~ tr/\x00-\x1f/0-9A-V/; return $val };
    $self->{rtr} =
        sub { my $val = shift; $val =~ tr/0-9A-V/\x00-\x1f/; return $val };
    $self->{func} = 'base32hex';
    return $self->_initialize;
}

App::Muter::Registry->instance->register(__PACKAGE__);

package App::Muter::Backend::URI;
$App::Muter::Backend::URI::VERSION = '0.002002';
our @ISA = qw/App::Muter::Backend::ChunkedDecode/;

sub new {
    my ($class, $args, %opts) = @_;
    my $self = $class->SUPER::new($args, %opts, regexp => qr/^(.*)(%.?)$/s);
    my $lower = grep { $_ eq 'lower' } @$args;
    $self->{chunk}  = '';
    $self->{format} = '%%%02' . ($lower ? 'x' : 'X');
    $self->{form}   = grep { $_ eq 'form' } @$args;
    return $self;
}

sub metadata {
    my $self = shift;
    my $meta = $self->SUPER::metadata;
    return {
        %$meta,
        args => {
            'upper' => 'Use uppercase letters',
            'lower' => 'Use lowercase letters',
            'form'  => 'Encode space as +',
        }
    };
}

sub encode_chunk {
    my ($self, $data) = @_;
    $data =~ s/([^A-Za-z0-9-._~])/sprintf $self->{format}, ord($1)/ge;
    $data =~ s/%20/+/g if $self->{form};
    return $data;
}

sub decode_chunk {
    my ($self, $data) = @_;
    $data =~ tr/+/ /;
    $data =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/ge;
    return $data;
}

App::Muter::Registry->instance->register(__PACKAGE__);

package App::Muter::Backend::XML;
$App::Muter::Backend::XML::VERSION = '0.002002';
our @ISA = qw/App::Muter::Backend::ChunkedDecode/;

sub new {
    my ($class, $args, %opts) = @_;
    my $self = $class->SUPER::new($args, %opts, regexp => qr/^(.*)(&[^;]*)$/);
    no warnings 'qw';    ## no critic (ProhibitNoWarnings)
    my $maps = {
        default => [qw/quot amp apos lt gt/],
        html    => [qw/quot amp #x27 lt gt/],
        hex     => [qw/#x22 #x26 #x27 #x3c #x3e/],
    };
    my $type = $args->[0] // 'default';
    $type = 'default' unless exists $maps->{$type};
    @{$self->{fmap}}{qw/" & ' < >/} = map { "&$_;" } @{$maps->{$type}};
    @{$self->{rmap}}{@{$maps->{default}}} = qw/" & ' < >/;
    return $self;
}

sub metadata {
    my $self = shift;
    my $meta = $self->SUPER::metadata;
    return {
        %$meta,
        args => {
            default => 'Use XML entity names',
            html    => 'Use HTML-friendly entity names for XML entities',
            hex     => 'Use hexadecimal entity names for XML entities',
        }
    };
}

# XML encodes Unicode characters.  However, muter only works on byte sequences,
# so immediately encode these into UTF-8.
sub _decode_char {
    my ($self, $char) = @_;
    return chr($1)              if $char =~ /^#([0-9]+)$/;
    return chr(hex($1))         if $char =~ /^#x([a-fA-F0-9]+)$/;
    return $self->{rmap}{$char} if exists $self->{rmap}{$char};
    die "Unknown XML entity &$char;";
}

sub encode_chunk {
    my ($self, $data) = @_;
    $data =~ s/(["&'<>])/$self->{fmap}{$1}/ge;
    return $data;
}

sub decode_chunk {
    my ($self, $data) = @_;
    require Encode;
    $data =~ s/&([^;]+);/Encode::encode('UTF-8', $self->_decode_char($1))/ge;
    return $data;
}

App::Muter::Registry->instance->register(__PACKAGE__);

package App::Muter::Backend::QuotedPrintable;
$App::Muter::Backend::QuotedPrintable::VERSION = '0.002002';
our @ISA = qw/App::Muter::Backend::ChunkedDecode/;

sub new {
    my ($class, $args, %opts) = @_;
    my $self =
        $class->SUPER::new($args, %opts, regexp => qr/\A(.*)(=[^\n]?)\z/);
    $self->{curlen} = 0;
    $self->{smtp} = 1 if grep { $_ eq 'smtp' } @$args;
    return $self;
}

sub encode {
    my ($self, $data) = @_;
    $data = $self->{chunk} . $data;
    $self->{chunk} = '';
    if (length($data) < 7) {
        $self->{chunk} = $data;
        return '';
    }
    if ($data =~ /\A(.*)(\n.{0,6})\z/) {
        $self->{chunk} = $2;
        $data = $1;
    }
    return $self->encode_chunk($data);
}

sub encode_final {
    my ($self, $data) = @_;
    $data = $self->{chunk} . $data;
    $self->{chunk} = '';
    return $self->encode_chunk($data);
}

sub encode_chunk {
    my ($self, $data) = @_;
    $data =~ s/([^\x20-\x3c\x3e-\x7e])/sprintf '=%02X', ord($1)/ge;
    $data =~ s/(^|=0A)\./$1=2E/g        if $self->{smtp};
    $data =~ s/(^|=0A)F(rom )/$1=46$2/g if $self->{smtp};
    my $result = '';
    my $maxlen = 75;
    while ($self->{curlen} + length($data) > $maxlen) {
        my $chunk = substr($data, 0, $maxlen - $self->{curlen});
        $chunk = $1 if $chunk =~ /^(.*)(=.?)$/;
        $data = substr($data, length($chunk));
        $result .= $chunk;
        if ($data) {
            $result .= "=\n";
            $self->{curlen} = 0;
        }
    }
    $result .= $data;
    $self->{curlen} += length($data);
    return $result;
}

sub decode_chunk {
    my ($self, $data) = @_;
    $data =~ s/=\n//g;
    $data =~ s/=([0-9A-F]{2})/chr(hex($1))/ge;
    return $data;
}

sub metadata {
    my $self = shift;
    my $meta = $self->SUPER::metadata;
    return {
        %$meta,
        args => {
            smtp => 'Encode "." and "From " at beginning of line',
        }
    };
}

App::Muter::Registry->instance->register(__PACKAGE__);

package App::Muter::Backend::Vis;
$App::Muter::Backend::Vis::VERSION = '0.002002';
our @ISA = qw/App::Muter::Backend::ChunkedDecode/;

sub new {
    my ($class, $args, %opts) = @_;
    my $self = $class->SUPER::new($args, %opts,
        regexp => qr/\A(.*?[^^\\-])?(\\.{0,3})\z/);
    $self->_setup_maps(map { $_ => 1 } @$args);
    $self->{chunk} = '';
    return $self;
}

sub _setup_maps {
    my ($self, %flags) = @_;
    $self->{flags} = \%flags;
    my $standard = {_id_map(0x21 .. 0x7e), 0x5c => "\\\\"};
    my $default = {_meta_map(0x00 .. 0x20, 0x7f .. 0xff)};
    my $octal = {_octal_map(0x00 .. 0x20, 0x7f .. 0xff)};
    my $cstyle = {
        %$default,
        0x00 => "\\000",
        0x07 => "\\a",
        0x08 => "\\b",
        0x09 => "\\t",
        0x0a => "\\n",
        0x0b => "\\v",
        0x0c => "\\f",
        0x0d => "\\r",
        0x20 => "\\s",
    };
    my $wanted_map =
        $flags{cstyle} ? $cstyle : $flags{octal} ? $octal : $default;
    my @chars = (
        ($flags{sp} || $flags{space} || $flags{white} ? () : (0x20)),
        ($flags{tab} || $flags{white} ? () : (0x09)),
        ($flags{nl}  || $flags{white} ? () : (0x0a)),
    );
    my %glob_chars = _octal_map($flags{glob} ? (0x23, 0x2a, 0x3f, 0x5b) : ());
    my $extras = {_id_map(0x09, 0x0a, 0x20)};
    my $map = {%$standard, %$wanted_map, %glob_chars, _id_map(@chars)};
    $self->{map} = [map { $map->{$_} } sort { $a <=> $b } keys %$map];
    $self->{rmap} = {
        reverse(%$standard), reverse(%$wanted_map),
        reverse(%$extras),   reverse(%$octal),
        reverse(%$cstyle),   reverse(%glob_chars),
        "\\0" => 0x00
    };
    return;
}

sub _id_map {    ## no critic(RequireArgUnpacking)
    return map { $_ => chr($_) } @_;
}

sub _octal_map {    ## no critic(RequireArgUnpacking)
    return map { $_ => sprintf('\%03o', $_) } @_;
}

sub _meta_map {     ## no critic(RequireArgUnpacking)
    return map { $_ => _encode($_) } @_;
}

sub _encode {
    my ($byte) = @_;
    use bytes;
    my $ascii = $byte & 0x7f;
    for ($byte) {
        when ([0x00 .. 0x1f, 0x7f]) { return '\^' . chr($ascii ^ 0x40) }
        when ([0x80 .. 0x9f, 0xff]) { return '\M^' . chr($ascii ^ 0x40) }
        when ([0xa1 .. 0xfe]) { return '\M-' . chr($ascii) }
        when (0x20)           { return '\040' }
        when (0xa0)           { return '\240' }
        default { die sprintf 'Found byte value %#02x', $byte; }
    }
    return;
}

sub encode {
    my ($self, $data) = @_;
    $data = $self->{chunk} . $data;
    if (length $data && substr($data, -1) eq "\0") {
        $data = substr($data, 0, -1);
        $self->{chunk} = "\0";
    }
    else {
        $self->{chunk} = '';
    }
    return $self->SUPER::encode($data);
}

sub encode_chunk {
    my ($self, $data) = @_;
    my $result = join('', map { $self->{map}[$_] } unpack('C*', $data));
    if ($self->{flags}{cstyle}) {
        # Do this twice to fix multiple consecutive NUL bytes.
        $result =~ s/\\000($|[^0-7])/\\0$1/g for 1 .. 2;
    }
    return $result;
}

sub _decode {
    my ($self, $val) = @_;
    use bytes;
    return '' if !length $val;
    return chr($self->{rmap}{$val} // die "val '$_'") if $val =~ /^\\/;
    return pack('C*', map { $self->{rmap}{$_} } split //, $val);
}

sub decode_chunk {
    my ($self, $data) = @_;
    return join('',
        map { $self->_decode($_) }
            split /(\\(?:M[-^].|\^.|[0-7]{3}|\\|[0abtnvfrs]))/,
        $data);
}

sub metadata {
    my $self = shift;
    my $meta = $self->SUPER::metadata;
    return {
        %$meta,
        args => {
            sp     => 'Encode space',
            space  => 'Encode space',
            tab    => 'Encode tab',
            nl     => 'Encode newline',
            white  => 'Encode space, tab, and newline',
            cstyle => 'Encode using C-like escape sequences',
            octal  => 'Encode using octal escape sequences',
            glob   => 'Encode characters recognized by glob(3) and hash mark',
        }
    };
}

App::Muter::Registry->instance->register(__PACKAGE__);

package App::Muter::Backend::Ascii85;
$App::Muter::Backend::Ascii85::VERSION = '0.002002';
our @ISA = qw/App::Muter::Backend::Chunked/;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args, enchunksize => 4, dechunksize => 5);
    $self->{start} = '';
    return $self;
}

sub encode {
    my ($self, $data) = @_;
    return '' unless length $data;
    my $prefix = defined $self->{start} ? '<~' : '';
    $self->{start} = undef;
    return $prefix . $self->SUPER::encode($data);
}

sub encode_final {
    my ($self, $data) = @_;
    return $self->SUPER::encode_final($data) .
        (defined $self->{start} ? '' : '~>');
}

sub _encode_seq {
    my ($x, $flag) = @_;
    return (89) if !$x && !$flag;
    my @res;
    for (0 .. 4) {
        push @res, $x % 85;
        $x = int($x / 85);
    }
    return reverse @res;
}

sub encode_chunk {
    my (undef, $data) = @_;
    my $rem = length($data) % 4;
    my $pad = $rem ? (4 - $rem) : 0;
    $data .= "\0" x $pad;
    my @chunks = unpack("N*", $data);
    my @last = $pad ? (pop @chunks) : ();
    my $res = pack('C*', map { _encode_seq($_) } @chunks);
    $res .= pack('C*', map { _encode_seq($_, 1) } @last);
    $res =~ tr/\x00-\x54\x59/!-uz/;
    $res = substr($res, 0, -$pad) if $pad;
    return $res;
}

sub decode {
    my ($self, $data) = @_;

    return '' unless length $data;

    if (defined $self->{start}) {
        $self->{start} .= $data;
        return '' unless length $self->{start} > 2;

        ($data = $self->{start}) =~ s/^<~// or die 'Invalid Ascii85 prefix';
        $self->{start} = undef;
    }
    return $self->decode_chunk($self->{chunk} . $data);
}

sub _decode_seq {
    my ($s) = @_;
    return 0 if $s eq 'z';
    die 'Invalid Ascii85 encoding' if $s gt 's8W-!';
    my $val = List::Util::reduce { $a * 85 + ($b - 33) } (0, unpack('C*', $s));
    return $val;
}

sub decode_chunk {
    my ($self, $data) = @_;
    my @chunks;
    push @chunks, _decode_seq($1) while $data =~ s/^(z|[^~]{5})//s;
    $self->{chunk} = $data;
    return pack('N*', @chunks);
}

sub decode_final {
    my ($self, $data) = @_;
    $data = $self->{chunk} . $data;
    return '' if defined $self->{start} && !length $data;
    my $res = $self->decode_chunk($data);
    $data = $self->{chunk};
    $data =~ s/~>$// or die "Missing Ascii85 trailer";
    my $rem = length($data) % 5;
    my $pad = $rem ? (5 - $rem) : 0;
    $res .= $self->decode_chunk($data . 'u' x $pad);
    $res = substr($res, 0, -$pad) if $pad;
    return $res;
}

App::Muter::Registry->instance->register(__PACKAGE__);

package App::Muter::Backend::Hash;
$App::Muter::Backend::Hash::VERSION = '0.002002';
use Digest::MD5;
use Digest::SHA;

our @ISA = qw/App::Muter::Backend/;

my $hashes = {};

sub new {
    my ($class, $args, @args) = @_;
    my ($hash) = @$args;
    my $self = $class->SUPER::new($args, @args);
    $self->{hash} = $hashes->{$hash}->();
    return $self;
}

sub encode {
    my ($self, $data) = @_;
    $self->{hash}->add($data);
    return '';
}

sub encode_final {
    my ($self, $data) = @_;
    $self->{hash}->add($data);
    return $self->{hash}->digest;
}

sub metadata {
    my ($self, $data) = @_;
    my $meta = $self->SUPER::metadata;
    $meta->{args} = {map { $_ => "Use the $_ hash algorithm" } keys %$hashes};
    return $meta;
}

sub register_hash {
    my ($name, $code) = @_;
    return $hashes->{$name} unless $code;
    return $hashes->{$name} = $code;
}

register_hash('md5',      sub { Digest::MD5->new });
register_hash('sha1',     sub { Digest::SHA->new });
register_hash('sha224',   sub { Digest::SHA->new(224) });
register_hash('sha256',   sub { Digest::SHA->new(256) });
register_hash('sha384',   sub { Digest::SHA->new(384) });
register_hash('sha512',   sub { Digest::SHA->new(512) });
register_hash('sha3-224', sub { require Digest::SHA3; Digest::SHA3->new(224) });
register_hash('sha3-256', sub { require Digest::SHA3; Digest::SHA3->new(256) });
register_hash('sha3-384', sub { require Digest::SHA3; Digest::SHA3->new(384) });
register_hash('sha3-512', sub { require Digest::SHA3; Digest::SHA3->new(512) });
App::Muter::Registry->instance->register(__PACKAGE__);

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Muter - tool to convert between various formats and encodings

=head1 VERSION

version 0.002002

=head1 DESCRIPTION

App::Muter provides the C<muter> command, which converts data between various
formats.

For more information, see L<muter>.

=head1 AUTHOR

brian m. carlson <sandals@crustytoothpaste.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016–2017 by brian m. carlson.

This is free software, licensed under:

  The MIT (X11) License

=cut
