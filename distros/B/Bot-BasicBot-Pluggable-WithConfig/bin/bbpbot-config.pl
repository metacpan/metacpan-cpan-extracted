#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Bot::BasicBot::Pluggable::WithConfig;

my $config;
Getopt::Long::GetOptions( '--config=s' => \$config, )
    or pod2usage(2);

Bot::BasicBot::Pluggable::WithConfig->new_with_config( config => $config )
    ->run;

__END__

=head1 SYNOPSIS

    $ bbpbot-config.pl --config /etc/bot.yaml

    Options:
        --config       yaml configuration

=head1 DESCRIPTION


=head1 AUTHORS

Takatoshi Kitano <kitano.tk at gmail.com>.


