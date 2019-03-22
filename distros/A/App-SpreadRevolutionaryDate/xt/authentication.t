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
use App::SpreadRevolutionaryDate::Target::Freenode::Bot;

{
    no strict 'refs';
    no warnings 'redefine';

    *App::SpreadRevolutionaryDate::Target::Freenode::Bot::tick = undef;
    *App::SpreadRevolutionaryDate::Target::Freenode::Bot::said = sub {
        my $self = shift;
        my $message = shift;
        return if $message->{who} eq 'freenode-connect';
        ok($message->{who} eq 'NickServ' && $message->{body} =~ /^You are now identified for/, 'Freenode connection with actual credentials in user conf');
        $self->shutdown('Shutdown overridden said');
    };
}

@ARGV = ('--test');
my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new;

eval { $spread_revolutionary_date->targets->{twitter}->obj->verify_credentials };
ok(!$@, 'Twitter connection with actual credentials in user conf');

eval { $spread_revolutionary_date->targets->{mastodon}->obj->get_account };
ok(!$@, 'Mastodon connection with actual credentials in user conf');

$spread_revolutionary_date->targets->{freenode}->spread('Test authentication');
