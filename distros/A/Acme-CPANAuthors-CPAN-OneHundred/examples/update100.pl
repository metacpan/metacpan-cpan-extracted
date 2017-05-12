#!/usr/bin/perl
use strict;
$|++;

my $VERSION = '1.06';

#----------------------------------------------------------------------------

=head1 NAME

update100.pl - preps the OneHundred module for release, if required.

=head1 SYNOPSIS

  perl update100.pl

=head1 DESCRIPTION

Downloads the latest copy of the cpan100.csv file from CPAN Testers Statistics
site. Compares with the previous download, and if there is a change, takes the 
module template and inserts the appropriate data ready for the next release.

=cut

# -------------------------------------
# Library Modules

use CPAN::Changes;
#use Data::Dumper;
use DateTime;
use File::Basename;
use Getopt::Long;
use IO::File;
use Template;
use WWW::Mechanize;

# -------------------------------------
# Variables

my (%options,%old,%new,%tvars,%pause,%changes);
my $changed = 0;
my $max = 4;

my @files = qw(
    lib/Acme/CPANAuthors/CPAN/OneHundred.pm
    LICENSE
    META.json
    META.yml
    README
    t/10cpanauthor.t
);

my %config = (                              # default config info
    RELATIVE        => 1,
    ABSOLUTE        => 1,
    INTERPOLATE     => 0,
    POST_CHOMP      => 1,
    TRIM            => 0,
    INCLUDE_PATH    => 'templates',
    OUTPUT_PATH     => '..'
);

my %groups = (
    'insert' => 'New Authors',
    'update' => 'Updated Counts',
    'delete' => 'See You Again?',
);

# -------------------------------------
# Program

GetOptions(\%options, 'local', 'build', 'release') or die "Usage: $0 [--local] [--build] [--release]\n";

my $base = dirname($0);
chdir($base);
#print "dir=$base\n";

unless($options{local}) {
    my $mech = WWW::Mechanize->new();
    my $source = 'http://stats.cpantesters.org/stats/cpan100.csv';
    my $target = basename($source);
    $mech->mirror($source,$target);
}

# read old file
my $inx = 0;
my $file = 'data/cpan100.csv';
if(my $fh = IO::File->new($file,'r')) {
    while(<$fh>) {
        s/\s+$//;
        next    if(!$_ or $_ =~ /^#/);
        my ($pause,$cnt,$name) = split(',');
        next unless($pause);

        $inx++;
        $old{$inx} = { count => $cnt, pause => $pause, name => $name };
        $pause{$pause} = $cnt;
    }
    $fh->close;
}

#print "pause=" . Dumper(\%pause);
#print "old=" . Dumper(\%old);

# read new file
$inx = 0;
$file = 'cpan100.csv';
my $fh = IO::File->new($file,'r') or die "Cannot open file [$file]: $!\n";
while(<$fh>) {
    s/\s+$//;

    if($_ && $_ =~ /^# DATE: (.*)/) {
        $tvars{WHEN} = $1;
    }

    next    if(!$_ or $_ =~ /^#/);
    my ($pause,$cnt,$name) = split(',');
    next unless($pause);

    $inx++;
    $new{$inx} = { count => $cnt, pause => $pause, name => $name };

    if($inx == 1) {
        $tvars{TOPDOG} = $pause;
        $tvars{TOPCAT} = $name;
    }

    # check whether anything has changed
    if(!$pause{$pause}) {
        push @{$changes{insert}}, $pause;
        $changed = 1;
    } elsif($pause{$pause} != $cnt) {
        push @{$changes{update}}, $pause;
        delete $pause{$pause};
        $changed = 1;
    } elsif($old{$inx} && ($old{$inx}{name} ne $name || $old{$inx}{pause} ne $pause)) {
        delete $pause{$pause};
        $changed = 1;
    } else {
        delete $pause{$pause};
    }

    $max = length $new{$inx}{pause} if($max < length $new{$inx}{pause});
}
$fh->close;

$tvars{COUNT} = scalar(keys %new);
#print "new=" . Dumper(\%new);
#print "pause=" . Dumper(\%pause);

# counts can go down as well as up
if(scalar(keys %pause)) {
    $changed = 1;
    push @{$changes{delete}}, $_
        for(keys %pause);
}

#print "max=$max, changed=$changed\n";

# bail if nothing has changed
unless($changed) {
    print "Nothing has changed, bailing\n";
    exit 0;
}

$max = (int($max/4) + 1) * 4    if($max % 4);
$max+=2;

# create lists
for my $inx (sort {$new{$a}{pause} cmp $new{$b}{pause}} keys %new) {
    my $pad = $max - length $new{$inx}{pause};
    push @{$tvars{LIST1}}, sprintf "    '%s'%s=> '%s',", $new{$inx}{pause}, (' ' x $pad), $new{$inx}{name};
}

my $cnt = 1;
for my $inx (sort {$new{$b}{count} <=> $new{$a}{count} || $new{$a}{pause} cmp $new{$b}{pause}} keys %new) {
    my $pad = $max - length $new{$inx}{pause};
    push @{$tvars{LIST2}}, sprintf "  %2d.  %3d  %s%s%s", $cnt++, $new{$inx}{count}, $new{$inx}{pause}, (' ' x $pad), $new{$inx}{name};
}

# calculate copyright
$tvars{COPYRIGHT} = '2014';
my $year = DateTime->now->year;
$tvars{COPYRIGHT} .= "-$year"  if($year > 2014);

# calculate version
$file = '../Changes';
my $changes = CPAN::Changes->load( $file );

my @releases = $changes->releases();
my $version  = $releases[-1]->{version};
$version += 0.01;
$tvars{VERSION} = sprintf "%.2f", $version;

# update Changes file
my $release = CPAN::Changes::Release->new( version => $tvars{VERSION}, date => DateTime->now->ymd );
for my $group (qw(insert update delete)) {
    next    unless($changes{$group});

    $release->add_changes(
        { group => $groups{$group} },
        join(', ',@{$changes{$group}})
    );

    push @releases, $release;
}

$changes->releases( @releases );

$fh = IO::File->new($file,'w+') or die "Cannot open file [$file]: $!\n";
my $content = $changes->serialize;
my @content = split("\n",$content);
$content = '';
for my $line (@content) {
    $line =~ s/^([\d.]+)\s+(.*?)$/$1    $2/;
    $line =~ s/^\s+(.*?)/        $1/;
    $line =~ s/^\s+(.*?)/        - $1/ unless($line =~ /^\s+[\[\-]/);
    $content .= "$line\n";
}
print $fh $content;
$fh->close;

# update other files
my $parser = Template->new(\%config);        # initialise parser
for my $template (@files) {
    eval {
        # parse to text
        $parser->process($template,\%tvars,$template) or die $parser->error();
    };

    die "TT PARSER ERROR: eval=$@, error=" . $parser->error  if($@);
}

# now store new data
system("cp data/cpan100.csv data/cpan100.old.csv ");
system("mv cpan100.csv data");

if($options{build}) {
    # build tarball
    system("perl Makfile.PL");
    system("make dist");

    if($options{release}) {
        # submit tarball
        system("cpan-upload Acme-CPANAuthors-CPAN-OneHundred-$tvars{VERSION}.tar.gz");
    }
}

print "Done!\n";

__END__

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-CPAN-OneHundred

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2014 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
