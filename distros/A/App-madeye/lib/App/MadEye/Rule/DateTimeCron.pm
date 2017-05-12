package App::MadEye::Rule::DateTimeCron;
use strict;
use warnings;
use base qw/App::MadEye::Rule/;

use DateTime;
use DateTime::Event::Cron;

sub dispatch {
    my ($self, $context, $args) = @_;

    my $crontab = $self->config->{crontab} or die "missing crontab";

    my $cron = DateTime::Event::Cron->new_from_cron( cron => $crontab );
    my $now = DateTime->now(time_zone => 'local')->set_second(0);
    return $cron->valid($now);
}

1;

