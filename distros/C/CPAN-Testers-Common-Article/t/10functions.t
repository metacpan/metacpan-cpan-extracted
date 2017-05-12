#!/usr/bin/perl -w
use strict;

use Test::More tests => 62;
use CPAN::Testers::Common::Article;
use IO::File;

my @perls = (
  {
    text => 'Summary of my perl5 (revision 5.0 version 6 subversion 1) configuration',
    perl => '5.6.1'
  },
  {
    text => 'Summary of my perl5 (revision a version b subversion c) configuration',
    perl => '0'
  },
  {
    text => 'Summary of my perl5 (revision 5.0 version 8 subversion 0 patch 17332) configuration',
    perl => '5.8.0 patch 17332',
  },
  {
    text => 'Summary of my perl5 (revision 5.0 version 8 subversion 1 RC3) configuration',
    perl => '5.8.1 RC3',
  },
  {
    text => 'Summary of my perl5 (revision 5 patchlevel 6 subversion 1) configuration',
    perl => '5.6.1',
  },
  {
    text => 'on Perl 5.8.8, created by CPAN-Reporter',
    perl => '5.8.8',
  },
  {
    text => '/site_perl/5.8.8/',
    perl => '5.8.8',
  },
  {
    text => 'on perl 5.8.8, created by CPAN-Reporter',
    perl => '5.8.8',
  },
  {
    head => 'v5.12.0 RC1',
    text => 'Summary of my perl5 (revision 5.0 version 12 subversion 0) configuration',
    perl => '5.12.0 RC1',
  },
  {
    head => 'v5.12.0',
    text => 'Summary of my perl5 (revision 5.0 version 12 subversion 0) configuration',
    perl => '5.12.0',
  },

  {
    text => 'on perl 5, created by CPAN-Reporter',
    perl => '0',
  },
  {
    text => 'Summary of my perl5 (revision 5.0) configuration',
    perl => '0'
  },
  {
    text => 'Summary of my perl5 (revision 5.0 version 8) configuration',
    perl => '0'
  },
  {
    text => '/site_perl/5.8/',
    perl => '0'
  },
#  {
#    text => '',
#    perl => '',
#  },
);

my $article = readfile('t/nntp/126015.txt');
my $ctca = CPAN::Testers::Common::Article->new($article);
isa_ok($ctca,'CPAN::Testers::Common::Article');

for(@perls) {
  my $text = $_->{text};
  my $perl = $_->{perl};
  my $head = $_->{head};

  my $version = $ctca->_extract_perl_version($text,$head);
  is($version, $perl,".. matches perl $perl");
}

my @dates = (
    { date => 'Wed, 13 September 2004 06:29',   result => ['200409','200409130629',1095056940] },
    { date => '13 September 2004 06:29',        result => ['200409','200409130629',1095056940] },
    { date => 'September 22, 1999 06:29',       result => ['199909','199909220629',937981740] },
    { date => 'Wed, 13 September 2004',         result => ['200409','200409130000',1095033600] },
    { date => '13 September 2004',              result => ['200409','200409130000',1095033600] },
    { date => 'September 22, 1999',             result => ['199909','199909220000',937958400] },
    { date => 'Sep 22, 1999',                   result => ['199909','199909220000',937958400] },

    { date => 'September 22, 1995',             result => ['000000','000000000000',0] },
    { date => 'Month 22, 1999',                 result => ['000000','000000000000',0] },

    { date => '13/09/2004',                     result => ['000000','000000000000',0] },
    { date => '13-09-2004T06:29:00Z',           result => ['000000','000000000000',0] },
    { date => '',                               result => ['000000','000000000000',0] },
);

for my $date (@dates) {
    my @extract = $ctca->_extract_date($date->{date});
    #diag("$date->{date}: " . Dumper(\@extract));
    is_deeply(\@extract, $date->{result}, ".. test for $date->{date}");
}

my @subjects = (
    { subject => '',                                            result => 0, dist => undef,  version => undef,  author => undef,    file => undef },
    { subject => 'CPAN Upload: blah',                           result => 0, dist => undef,  version => undef,  author => undef,    file => undef },
    { subject => 'CPAN Upload: blah-1.00',                      result => 0, dist => undef,  version => undef,  author => undef,    file => undef },
    { subject => 'CPAN Upload: blah-1.00.tar.bz2',              result => 1, dist => 'blah', version => '1.00', author => undef,    file => 'blah-1.00.tar.gz' }, # DistnameInfo doesn't do bz2
    { subject => 'CPAN Upload: blah-1.00.tar.gz',               result => 1, dist => 'blah', version => '1.00', author => undef,    file => 'blah-1.00.tar.gz' },
    { subject => 'CPAN Upload: BARBIE/blah-1.00.tar.gz',        result => 1, dist => 'blah', version => '1.00', author => 'BARBIE', file => 'blah-1.00.tar.gz' },
    { subject => 'CPAN Upload: B/BA/BARBIE/blah-1.00.tar.gz',   result => 1, dist => 'blah', version => '1.00', author => 'BARBIE', file => 'blah-1.00.tar.gz' },
);

for my $subject (@subjects) {
    $ctca->{subject} = $subject->{subject};
    is($ctca->parse_upload(),$subject->{result},".. parse upload for '$subject->{subject}'");

    is($ctca->distribution(),$subject->{dist});
    is($ctca->version(),$subject->{version});
    is($ctca->author(),$subject->{author});
    is($ctca->filename(),$subject->{file});
}

sub readfile {
    my $file = shift;
    my $text;
    my $fh = IO::File->new($file)   or return;
    while(<$fh>) { $text .= $_ }
    $fh->close;
    return $text;
}
