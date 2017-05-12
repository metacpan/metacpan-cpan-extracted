#!/usr/bin/perl -w
use strict;

use CPAN::Testers::Data::Uploads::Mailer;
use File::Basename;
use File::Path;
use IO::File;
use Test::More tests => 21;

my %default = (
    source      => 'logs/uploads.log',
    lastfile    => 'logs/uploads-mailer.txt',
    logfile     => 'logs/uploads-mailer.log',
    debug       => 0,
    test        => 1
);

my %params = (
    source      => 't/samples/uploads.log',
    lastfile    => 't/test/uploads-mailer.txt',
    logfile     => 't/test/uploads-mailer.log',
    debug       => 1,
    test        => 0
);

{
    my $mailer;
    #eval { $mailer = CPAN::Testers::Data::Uploads::Mailer->new(); };
    #like($@,qr/No uploads source log file \[logs\/uploads.log\] found/,'.. source log not found');

    is(mkfile($default{source}),1,'.. create source file');

    eval { $mailer = CPAN::Testers::Data::Uploads::Mailer->new(); };
    for my $opt (keys %default) {
        is($mailer->{options}{$opt},$default{$opt},".. default option $opt");
    }
}

{
    my $mailer;
    eval { $mailer = CPAN::Testers::Data::Uploads::Mailer->new(); };
    for my $opt (keys %default) {
        is($mailer->{options}{$opt},$default{$opt},".. default option $opt");
    }
}

{
    my $mailer;
    eval { $mailer = CPAN::Testers::Data::Uploads::Mailer->new(%params); };
    for my $opt (keys %params) {
        is($mailer->{options}{$opt},$params{$opt},".. params option $opt");
    }
}

{
    push @ARGV, "--$_=$params{$_}"  for(qw(source lastfile logfile));
    push @ARGV, "--$_"              for(grep {$params{$_}} qw(test debug));
    push @ARGV, "--no$_"            for(grep {!$params{$_}} qw(test debug));
    my $mailer;
    eval { $mailer = CPAN::Testers::Data::Uploads::Mailer->new(); };
    for my $opt (keys %params) {
        is($mailer->{options}{$opt},$params{$opt},".. args option $opt");
    }
}

sub mkfile {
    my $file = shift;
    mkpath(dirname($file));
    my $fh = IO::File->new($file,'w+') or return 0;
    $fh->close;
    return 1;
}
