package CPAN::Testers::Common::Article;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = '0.46';

#----------------------------------------------------------------------------
# Library Modules

use CPAN::DistnameInfo;
use Email::Simple;
use MIME::Base64;
use MIME::QuotedPrint;
use Time::Local;

use base qw( Class::Accessor::Fast );

#----------------------------------------------------------------------------
# Variables

my %month = (
	Jan => 1, Feb => 2, Mar => 3, Apr => 4,  May => 5,  Jun => 6,
	Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12,
);

my @perl_extractions = (
    # Summary of my perl5 (revision 5.0 version 6 subversion 1) configuration:
    # Summary of my perl5 (revision 5 version 10 subversion 0) configuration:
    qr/Summary of my (?:perl(?:\d+)?)? \((?:revision )?(\d+(?:\.\d+)?) (?:version|patchlevel) (\d+) subversion\s+(\d+) ?(.*?)\) configuration/,

    # the following is experimental and may provide incorrect data
    qr!/(?:(?:site_perl|perl|perl5|\.?cpanplus)/|perl-)(5)\.?([6-9]|1[0-2])\.?(\d+)/!,

    # this dissects the report introduction and is used in the event that
    # the report gets truncated and no perl -V information is available.
    qr/on Perl (\d+)\.(\d+)(?:\.(\d+))?/i,
);

my %regexes = (
    # with time
    1 => { re => qr/(?:\w+,)?\s+(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+)/,   f => [qw(day month year hour min)] },     # Wed, 13 September 2004 06:29
    2 => { re => qr/(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+)/,               f => [qw(day month year hour min)] },     # 13 September 2004 06:29
    3 => { re => qr/(\w+)?\s+(\d+),?\s+(\d+)\s+(\d+):(\d+)/,            f => [qw(month day year hour min)] },     # September 22, 1999 06:29

    # just the date
    4 => { re => qr/(?:\w+,)?\s+(\d+)\s+(\w+)\s+(\d+)/, f => [qw(day month year)] },  # Wed, 13 September 2004
    5 => { re => qr/(\d+)\s+(\w+)\s+(\d+)/,             f => [qw(day month year)] },  # 13 September 2004
    6 => { re => qr/(\w+)?\s+(\d+),?\s+(\d+)/,          f => [qw(month day year)] },  # September 22, 1999
);

my $OSNAMES = qr/(cygwin|freebsd|netbsd|openbsd|darwin|linux|cygwin|darwin|MSWin32|dragonfly|solaris|MacOS|irix|mirbsd|gnu|bsdos|aix|sco|os2|haiku|beos|midnight)/i;
my %OSNAMES = (
    'MacPPC'    => 'macos',
    'osf'       => 'dec_osf',
    'pa-risc'   => 'hpux',
    's390'      => 'os390',
    'VMS_'      => 'vms',
    'ARCHREV_0' => 'hpux',
    'linuxThis' => 'linux',
    'linThis'   => 'linux',
    'linuThis'  => 'linux',
    'lThis'     => 'linux',
    'openThis'  => 'openbsd',
);

#----------------------------------------------------------------------------
# The Public API

__PACKAGE__->mk_accessors(
    qw(
        raw cooked header body
        postdate date epoch status from distribution version
        perl osname osvers archname subject author filename
        osname_patterns osname_fixes
    )
);

sub new {
    my($class, $article) = @_;
    my $self = {};
    bless $self, $class;

    $self->raw($article);
    $article = decode_qp($article)	if($article =~ /=3D/);
    $self->cooked($article);

    my $mail;
    eval { $mail = Email::Simple->new($article) };
    return unless $mail;

    $self->header($mail->header_obj());
    $self->body($mail->body());

    return if $mail->header("In-Reply-To");

    my $from    = $mail->header("From");
    my $subject = $mail->header("Subject");
    return unless $subject;
    return if $subject =~ /::/; # it's supposed to be a distribution

    $self->osname_patterns( $OSNAMES );
    $self->osname_fixes( \%OSNAMES );

    $self->{mail}    = $mail;
    $self->{from}    = $from;
    $self->{subject} = $subject;

    ($self->{postdate},$self->{date},$self->{epoch}) = $self->_parse_date($mail);

    return $self;
}

sub parse_upload {
    my $self = shift;
    my $mail = $self->{mail};
    my $subject = $self->{subject};

    return 0	unless($subject =~ /CPAN Upload:\s+([-\w\/\.\+]+)/i);
    my $distvers = $1;

    # only record supported archives
    return 0    if($distvers !~ /\.(?:(?:tar\.|t)(?:gz|bz2)|zip)$/);

    # CPAN::DistnameInfo doesn't support .tar.bz2 files ... yet
    $distvers =~ s/\.(?:tar\.|t)bz2$//i;
    $distvers .= '.tar.gz' unless $distvers =~ /\.(?:(?:tar\.|t)gz|zip)$/i;

    # CPAN::DistnameInfo doesn't support old form of uploads
    my @parts = split("/",$distvers);
    if(@parts == 2) {
        my ($first,$second,$rest) = split(//,$distvers,3);
        $distvers = "$first/$first$second/$first$second$rest";
    }

    my $d = CPAN::DistnameInfo->new($distvers);
    $self->distribution($d->dist);
    $self->version($d->version);
    $self->author($d->cpanid);
    $self->filename($d->filename);

    return 1;
}

sub parse_report {
    my $self = shift;
    my $mail = $self->{mail};
    my $from = $self->{from};
    my $subject = $self->{subject};

    my ($status, $distversion, $platform, $osver) = split /\s+/, $subject;
    return 0  unless $status =~ /^(PASS|FAIL|UNKNOWN|NA)$/i;

    $platform ||= "";
    $platform =~ s/[\s&,<].*//;

    $distversion ||= "";
    $distversion =~ s!/$!!;
    $distversion =~ s/\.tar.*/.tar.gz/;
    $distversion .= '.tar.gz' unless $distversion =~ /\.(tar|tgz|zip)/;

    my $d = CPAN::DistnameInfo->new($distversion);
    my ($dist, $version) = ($d->dist, $d->version);
    return 0 unless defined $dist;
    return 0 unless defined $version;

    my $encoding = $mail->header('Content-Transfer-Encoding');
    my $head = $mail->header("X-Test-Reporter-Perl");
    my $body = $mail->body;
    $body = decode_base64($body)  if($encoding && $encoding eq 'base64');

    my $perl = $self->_extract_perl_version($body,$head);

    my ($osname)   = $body =~ /(?:Summary of my perl5|Platform:).*?osname=([^\s\n,<\']+)/s;
    my ($osvers)   = $body =~ /(?:Summary of my perl5|Platform:).*?osvers=([^\s\n,<\']+)/s;
    my ($archname) = $body =~ /(?:Summary of my perl5|Platform:).*?archname=([^\s\n&,<\']+)/s;
    $archname =~ s/\n.*//	if($archname);

    $self->status($status);
    $self->distribution($dist);
    $self->version($version);
    $self->from($from || "");
    $self->perl($perl);
    $self->filename($d->filename);

    unless($archname || $platform) {
  	    if($osname && $osvers)	{ $platform = "$osname-$osvers" }
	    elsif($osname)		    { $platform = $osname }
    }

    unless($osname) {
        my $patterns = $self->osname_patterns;
        my $fixes = $self->osname_fixes;

        for my $text ($platform, $archname) {
            next    unless($text);
            if($text =~ $patterns) {
                $osname = $1;
            } else {
                for my $rx (keys %$fixes) {
                    if($text =~ /$rx/i) {
                        $osname = $fixes->{$rx};
                        last;
                    }
                }
            }
            last    if($osname);
        }
    }

    $osvers ||= $osver;

    $self->osname($osname || "");
    $self->osvers($osvers || "");
    $self->archname($archname || $platform);

    return 1;
}

sub passed {
    my $self = shift;
    return $self->status eq 'PASS';
}

sub failed {
    my $self = shift;
    return $self->status eq 'FAIL';
}

#----------------------------------------------------------------------------
# The Private Methods

sub _parse_date {
    my ($self,$mail) = @_;
    my ($date1,$date2,$date3) = $self->_extract_date($mail->header("Date"));
    my @received  = $mail->header("Received");

    for my $hdr (@received) {
        next    unless($hdr =~ /.*;\s+(.*)\s*$/);
        my ($dt1,$dt2,$dt3) = $self->_extract_date($1);
        if($dt2 > $date2 + 1200) {
            $date1 = $dt1;
            $date2 = $dt2;
            $date3 = $dt3;
        }
    }

#print STDERR "        ... X.[Date: ".($date||'')."]\n";
    return($date1,$date2,$date3);
}

sub _extract_date {
    my ($self,$date) = @_;
    my (%fields,@fields,$index);

#print STDERR "#        ... 0.[Date: ".($date||'')."]\n";

    for my $inx (sort {$a <=> $b} keys %regexes) {
        (@fields) = ($date =~ $regexes{$inx}->{re});
        if(@fields) {
            $index = $inx;
            last;
        }
    }

    return('000000','000000000000',0) unless($index);

    @fields{@{$regexes{$index}->{f}}} = @fields;

    $fields{month} = substr($fields{month},0,3);
    $fields{mon}   = $month{$fields{month}};
    return('000000','000000000000',0) unless($fields{mon} && $fields{year} > 1998);

    $fields{$_} ||= 0          for(qw(sec min hour day mon year));
    my @date = map { $fields{$_} } qw(sec min hour day mon year);

#print STDERR "#        ... 1.[$_][$fields{$_}]\n"   for(qw(year month day hour min));
    my $short = sprintf "%04d%02d",             $fields{year}, $fields{mon};
    my $long  = sprintf "%04d%02d%02d%02d%02d", $fields{year}, $fields{mon}, $fields{day}, $fields{hour}, $fields{min};
    $date[4]--;
    my $epoch = timegm(@date);

    return($short,$long,$epoch);
}

# there are a number of test reports that either omitted the perl version 
# completely, or have had it truncated by the NNTP mail server. In more recent
# reports the perl version number is also listed towards the beginning of the
# report. The cocde below now attempts to find something in all known places.

sub _extract_perl_version {
    my ($self, $body, $head) = @_;
    my ($rev, $ver, $sub, $extra);

    for my $regex (@perl_extractions) {
        ($rev, $ver, $sub, $extra) = $body =~ /$regex/si;
        last    if(defined $rev);
    }

    return 0    unless(defined $rev);

    #$ver ||= 0;    # current patterns require ver and sub values
    #$sub ||= 0;

    my $perl = $rev + ($ver / 1000) + ($sub / 1000000);
    $rev = int($perl);
    $ver = int(($perl*1000)%1000);
    $sub = int(($perl*1000000)%1000);

    # check for a release candidate (classed as a patch)
    if($head && $head =~ /v5\.\d+\.\d+ (RC\d+)/) {
        $extra .= ' '   if($extra);
        $extra .= "$1";
    }

    my $version = sprintf "%d.%d.%d", $rev, $ver, $sub;
    $version .= " $extra" if $extra;
    return $version;
}

1;

__END__

=head1 NAME

CPAN::Testers::Common::Article - Parse a CPAN Testers NNTP article

=head1 DESCRIPTION

Given an NNTP article from the cpan-testers or cpan-uploads feed, will parse
and return the appropriate the data parts via accessors.

=head1 INTERFACE

=head2 The Constructor

=over 4

=item * new

The constructor. Pass in a reference to the article.

=back

=head2 Methods

=over 4

=item * parse_upload

Parses an upload article.

=item * parse_report

Parses a report article.

=item * passed

Whether the report was a PASS

=item * failed

Whether the report was a FAIL

=back

=head2 Accessors

All the following are accessors available through via the object, once an
article has been parsed as a report or upload announcement.

=over 4

=item * postdate

'YYYYMM' representation of the date article was posted.

=item * date

'YYYYMMDDhhmm' representation of the date article was posted.

=item * epoch

Number of seconds since the epoch of when article was posted

=item * status

For reports this will be the grade, for uploads this will be 'CPAN'.

=item * from

Who posted the article.

=item * distribution

The distribution name.

=item * version

The distribution version.

=item * perl

The perl interpreter version used for testing.

=item * osname

Operating system name.

=item * osvers

Operating system version.

=item * archname

Operating system architecture name. This is usually based on the osname and
osvers, but they are not always the same.

=item * subject

Subject line of the original post.

=item * author

Author of uploaded distribution (Upload article only).

=item * filename

File name of uploaded distribution (Upload article only).

=item * osnames_patterns

A regular expression of known operating system coded strings.

=item * osnames_fixes

A hash reference to strings that may have been mangled, and their corrections.

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-Common-Article

=head1 SEE ALSO

L<CPAN::Testers::Data::Generator>,
L<CPAN::Testers::Data::Uploads>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

=head1 AUTHOR

  Original author:    Leon Brocard <acme@astray.com>   (C) 2002-2008
  Current maintainer: Barbie       <barbie@cpan.org>   (C) 2008-2014

=head1 LICENSE

This distribution is free software; you can redistribute it and/or
modify it under the Artistic License v2.
