package App::MBUtiny::Util; # $Id: Util.pm 120 2019-07-01 11:57:45Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MBUtiny::Util - Internal utilities used by App::MBUtiny module

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use App::MBUtiny::Util qw/
            filesize explain hide_password md5sum
            resolv sha1sum
        /;

    my $fsize = filesize( $file );
    print explain( $object );
    print hide_password('http://user:password@example.com');
    my $md5 = md5sum( $file );
    my $name = resolv( $IPv4 );
    my $sha1 = sha1sum( $filename );

=head1 DESCRIPTION

Internal utility functions

=over 8

=item B<explain>

    print explain( $object );

Returns Data::Dumper dump

=item B<filesize>

    my $fsize = filesize( $file );

Returns file size

=item B<hide_password>

    print hide_password('http://user:password@example.com'); # 'http://user:*****@example.com'

Returns specified URL but without password

=item B<md5sum>

    my $md5 = md5sum( $filename );

See L<Digest::MD5>

=item B<node2anode>

    my $anode = node2anode({});

Returns array of nodes

=item B<parse_credentials>

    my ($user, $password) = parse_credentials( 'http://user:password@example.com' );
    my ($user, $password) = parse_credentials( new URI('http://user:password@example.com') );

Returns credentials pair by URL or URI object

=item B<resolv>

    my $name = resolv( $IPv4 );
    my $ip = resolv( $name );

Resolv ip to a hostname or hostname to ip. See L<Sys::Net/"resolv">, L<Socket/"inet_ntoa">
and L<Socket/"inet_aton">

=item B<set2attr>

    my $hash = set2attr({set => ["AttrName Value"]}); # {"AttrName" => "Value"}

Converts attributes from the "set" format to regular hash

=item B<sha1sum>

    my $sha1 = sha1sum( $filename );

See L<Digest::SHA1>

=item B<xcopy>

    xcopy( $src_dir, $dst_dir, [ ... exclude rel. paths ... ] );

Exclusive copying all objects (files/directories) from $src_dir directory into $dst_dir
directory without specified relative paths. The function returns status of work

    xcopy( "/source/folder", "/destination/folder" )
        or die "Can't copy directory";

    # Copying without foo and bar/baz files/directories
    xcopy( "/source/folder", "/destination/folder", [qw( foo bar/baz )] )
        or die "Can't copy directory";

=back

=head1 HISTORY

See C<Changes> file

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION @EXPORT_OK /;
$VERSION = '1.02';

our $DEBUG = 0;

use Carp;
use URI;
use URI::Escape qw/uri_unescape/;
use File::Find;
use File::Copy;
use Digest::MD5;
use Digest::SHA1;
use Socket qw/inet_ntoa inet_aton AF_INET/;
use Data::Dumper; #$Data::Dumper::Deparse = 1;
use CTK::ConfGenUtil;

use constant {
    DIRMODE => 0777,
};

use base qw/Exporter/;
@EXPORT_OK = qw/
        filesize sha1sum md5sum
        resolv
        explain
        xcopy
        node2anode set2attr
        parse_credentials hide_password
    /;

sub sha1sum {
    my $f = shift;
    my $sha1 = new Digest::SHA1;
    my $sum = '';
    return $sum unless -e $f;
    open( my $sha1_fh, '<', $f) or (carp("Can't open '$f': $!") && return $sum);
    if ($sha1_fh) {
        binmode($sha1_fh);
        $sha1->addfile($sha1_fh);
        $sum = $sha1->hexdigest;
        close($sha1_fh);
    }
    return $sum;
}
sub md5sum {
    my $f = shift;
    my $md5 = new Digest::MD5;
    my $sum = '';
    return $sum unless -e $f;
    open( my $md5_fh, '<', $f) or (carp("Can't open '$f': $!") && return $sum);
    if ($md5_fh) {
        binmode($md5_fh);
        $md5->addfile($md5_fh);
        $sum = $md5->hexdigest;
        close($md5_fh);
    }
    return $sum;
}
sub filesize {
    my $f = shift;
    my $filesize = 0;
    $filesize = (stat $f)[7] if -e $f;
    return $filesize;
}
sub resolv { # Resolving. See Socket::inet_ntoa
    # Original: Sys::Net::resolv
    my $name = shift;
    # resolv ip to a hostname
    if ($name =~ m/^\s*[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\s*$/) {
        return scalar gethostbyaddr(inet_aton($name), AF_INET);
    }
    # resolv hostname to ip
    else {
        return inet_ntoa(scalar gethostbyname($name));
    }
}
sub explain {
    my $dumper = new Data::Dumper( [shift] );
    $dumper->Indent(1)->Terse(1);
    $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
    return $dumper->Dump;
}
sub xcopy {
    my $object = shift || ''; # from
    my $target = shift || ''; # to
    my $exclude = shift;      # exclude files

    carp("Source directory not exists: $object") && return
        unless $object && (-e $object and -d $object);

    carp("Target directory not defined: $target") && return
        unless $target;

    if ($exclude && ref($exclude) ne 'ARRAY') {
        carp("The third argument must be reference to array containing list of files for excluding");
        return;
    } else {
        $exclude = [] unless $exclude;
    }

    my $ob = File::Spec->canonpath($object);
    my $tg = File::Spec->canonpath($target);
    my (@exf, @exd);
    foreach (@$exclude) {
        my $tf = File::Spec->canonpath(File::Spec->catfile($ob, $_));
        my $td = File::Spec->canonpath(File::Spec->catdir($ob, $_));
        if (-e $td && -d $td) {
            push @exd, $td;
        } else {
            push @exf, $tf;
        }
    };

    if ($DEBUG) {
        printf("#F: %s\n", $_) for @exf;
        printf("#D: %s\n", $_) for @exd;
    }

    find({
        wanted => sub
            {
                my $f = File::Spec->canonpath($_);
                my $p = File::Spec->abs2rel( $f, $ob );
                if ((-e $f and -f $f) && (grep {$_ eq $f} @exf)) {
                    print ">F [SKIP] $f\n" if $DEBUG;
                    return 1;
                } elsif (@exd && grep {_td($_,$f)} @exd) {
                    print ">D [SKIP] $f\n" if $DEBUG;
                    return 1;
                } else {
                    if (-d $f) {
                        my $end = File::Spec->catdir($tg, $p);
                        print ">D        $f -> $end\n" if $DEBUG;
                        unless (-e $end) {
                            mkdir($end,DIRMODE) or carp(sprintf("Can't create directoy \"%s\": ", $end, $!)) && return;
                            chmod scalar((stat($f))[2]), $end;
                        }
                    } else {
                        my $end = File::Spec->catfile($tg, $p);
                        print ">F        $f -> $end\n" if $DEBUG;
                        unless (-e $end) {
                            copy($f,$end) or carp(sprintf("Copy failed \"%s\" -> \"%s\": %s", $f, $end, $!)) && return;
                            chmod scalar((stat($f))[2]), $end;
                        }
                    }
                }
            },
        no_chdir => 1,
        }, $ob,
    );

    print "\n" if $DEBUG;
    return 1;
}
sub node2anode {
    my $n = shift;
    return [] unless $n && ref($n) =~ /ARRAY|HASH/;
    return [$n] if ref($n) eq 'HASH';
    return $n;
}
sub parse_credentials {
    my $url = shift || return ();
    my $uri = (ref($url) eq 'URI') ? $url : URI->new($url);
    my $info = $uri->userinfo() // "";
    my $user = $info;
    my $pass = $info;
    $user =~ s/:.*//;
    $pass =~ s/^[^:]*://;
    return (uri_unescape($user // ''), uri_unescape($pass // ''));
}
sub hide_password {
    my $url = shift || return "";
    my $full = shift || 0; # 0 - starts, 1 - no_credentials; 2 - user_only
    my $uri = new URI($url);
    my ($u,$p) = parse_credentials($uri);
    return $url unless defined($p) && length($p);
    $uri->userinfo($full ? ($full == 1 ? undef : $u) : sprintf("%s:*****", $u));
    return $uri->canonical->as_string;
}
sub set2attr {
    my $in = shift;
    my $attr = array($in => "set");
    my %attrs;
    foreach (@$attr) {
        $attrs{$1} = $2 if $_ =~ /^\s*(\S+)\s+(.+)$/;
    }
    return {%attrs};
}


sub _td { # Test of base directory
    my $d = shift; # exclude directory
    my $o = shift; # test object

    my @t;
    my @sd;
    my $ret = 0;
    my ($volume,$dirs,$file) = File::Spec->splitpath( $o );
    return 0 unless $dirs;
    if (-f $o) {
        @sd = File::Spec->splitdir(File::Spec->catdir($volume, $dirs));
        #print join("#",@sd),"\n";
    } elsif (-d $o) {
        @sd = File::Spec->splitdir($o);
    } else {
        return 1; # undefined object - skipped!
    }
    for (@sd) {
        push @t, $_;
        if (File::Spec->catdir(@t) eq $d) {
            $ret = 1;
            last;
        }
    }
    return $ret;
}

1;
