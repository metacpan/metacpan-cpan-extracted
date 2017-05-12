#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use File::Spec::Functions qw/catfile/;
use Dancer2;
use Dancer2::Plugin::Email;

set template => 'template_flute';
set views => $Bin;

my $cids = {};

my $mail = template mail => {
                             email_cids => $cids,
                            };

print to_dumper($cids);

my @attachments;
foreach my $cid (keys %$cids) {
    push @attachments, {
                        Id => $cid,
                        Path => catfile($Bin, $cids->{$cid}->{filename}),
                       };
}

my ($from, $to, $subject) = @ARGV;
die "Missing sender and/or recipient" unless $from && $to;

my $email = {
             from    => $from,
             to      => $to,
             subject => $subject || 'Dancer2::Template::Flute test mail',
             body    => $mail,
             type    => 'html',
             attach  => \@attachments,
             multipart => 'related',
            };

print to_dumper($email);

email $email;




