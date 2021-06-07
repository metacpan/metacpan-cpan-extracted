#!/usr/bin/perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

use Test::More;
use File::HomeDir;

unless(   -f File::HomeDir->my_home . '/.config/spread-revolutionary-date/spread-revolutionary-date.conf'
       || -f File::HomeDir->my_home . '/.spread-revolutionary-date.conf') {
  plan skip_all => 'No user config file found';
} else {
  plan tests => 3;
}

use App::SpreadRevolutionaryDate;
use App::SpreadRevolutionaryDate::Target::Liberachat::Bot;

{
    no strict 'refs';
    no warnings 'redefine';

    *App::SpreadRevolutionaryDate::Target::Liberachat::Bot::tick = undef;
    *App::SpreadRevolutionaryDate::Target::Liberachat::Bot::said = sub {
        my ($self, $message) = @_;

        return if $message->{who} eq 'liberachat-connect';
        return if $message->{body} =~ /^Last login from/;
        ok($message->{who} eq 'NickServ' && $message->{body} =~ /^You are now identified for/, 'Liberachat connection with actual credentials in user conf');
        $self->shutdown('Shutdown overridden said');
    };
}

@ARGV = ('--test');
my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new;

eval { $spread_revolutionary_date->targets->{twitter}->obj->verify_credentials };
ok(!$@, 'Twitter connection with actual credentials in user conf');

eval { $spread_revolutionary_date->targets->{mastodon}->obj->get_account };
ok(!$@, 'Mastodon connection with actual credentials in user conf');

$spread_revolutionary_date->targets->{liberachat}->spread('Test authentication');
