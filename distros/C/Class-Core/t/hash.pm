#!/usr/bin/perl -w
package hash;

use strict;
use Class::Core;
use vars qw/$spec/;
$spec = <<DONE;
<func name='runhash'>
    <sig>
        <in name='recurse' type='bool' optional/>
        <in name='path' type='path' isdir/>
        <set name='mode' val='dir'/>
    </sig>
    <sig>
        <in name='path' type='path' isfile/>
        <set name='mode' val='file'/>
    </sig>
</func>

<func name='hashfile'>
    <in name='path' type='path' isfile/>
</func>
DONE

sub new {
    return wrap_class( 'hash' );
}

sub runhash {
    my ( $uni, $self ) = @_;
    my $path = $uni->get('path');
    $self->hashfile( path => $path );
}

sub hashfile {
    my ( $uni, $self ) = @_;
    my $path = $uni->get('path');
    my $result = `./fsum.exe -md5 "$path" 2>/dev/null`;
    my @lines = split( /\n/, $result );
    my %types = (
        md2 => 'MD2',
        md4 => 'MD4',
        md5 => '',
        sha1 => 'SHA1',
        sha256 => 'SHA256',
        sha384 => 'SHA384',
        sha512 => 'SHA512',
        rmd => 'RIPEMD160',
        tiger => 'TIGER',
        panama => 'PANAMA',
        adler => 'ADLER32',
        crc32 => 'CRC32',
        edonkey => 'EDONKEY'
        );
    
    for my $line ( @lines ) {
        next if( $line =~ m/^;/ );
        $line =~ m/(.+)(\?.+)?\*(.+)/;
        
        my $hash = $1;
        my $type = $2 || 'md5';
        my $file = $3;
        print "Hash:$hash\nType:$type\nFile:$file\n";
        #print "$line\n";
    }
}


1;