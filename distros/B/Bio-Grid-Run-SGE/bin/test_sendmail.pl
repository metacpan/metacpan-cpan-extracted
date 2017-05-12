#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;
use Mail::Sendmail;
use 5.010;

use Bio::Grid::Run::SGE::Master;

my $mail = 'jo@bargsten.org';
say STDERR "Sending mail to $mail.";
my $log_content = "test";

my $RC_FILE = $Bio::Grid::Run::SGE::Master::RC_FILE;

my $c = eval { Config::Auto::parse($RC_FILE) } if ( $RC_FILE && -f $RC_FILE );

my $smtp_server = $c->{smtp_server};
unshift @{ $Mail::Sendmail::mailcfg{'smtp'} }, $smtp_server if ($smtp_server);
my %mail = (
    To      => $c->{mail},
    Subject => "Bio::Grid::Run::SGE - test",
    From    => (
        $ENV{SGE_O_LOGNAME} && $ENV{SGE_O_HOST}
        ? join( '@', $ENV{SGE_O_LOGNAME}, $ENV{SGE_O_HOST} )
        : join( '@', $ENV{USER},          $ENV{HOSTNAME} )
    ),
    Message => $log_content,
);

sendmail(%mail) or say STDERR $Mail::Sendmail::error;

say STDERR "Mail log says:\n", $Mail::Sendmail::log;

