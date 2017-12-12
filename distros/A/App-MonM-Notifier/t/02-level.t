#!/usr/bin/perl -w
#########################################################################
#
# Sergey Lepenkov (Serz Minus), <abalama@cpan.org>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02-level.t 21 2017-11-14 16:47:03Z abalama $
#
#########################################################################
use Test::More tests => 11;
use lib qw(inc);
use FakeCTK;
use App::MonM::Notifier::Util;
use App::MonM::Notifier::Const;

=pod
#
# TODO: Алгоритм определления - отправлять или нет
#
# priority_mask - это маска, по умолчанию   1111111111 - сообщения всех уровней
#  - сообщения только info и выше           1111111110
#  - сообщения только error и выше          1111100000
#  - сообщения только error и except        1000100000
# каждый бит отпределяет свой индекс. по умолчаона определяет
my $config_level = "notice"; # Из конфига. Стартовый уровень
my $config_mask = "none"; # "INFO, ERROR" или "NONE" # Из конфига. Конкретная маска. Приоритетнее!
my $priority_mask = 0; # Результирующая маска
$priority_mask = setPriorityMask($config_mask) if $config_mask;
$priority_mask = getPriorityMask(getLevelByName(lc($config_level))) if !$priority_mask and $config_level;
$priority_mask = getPriorityMask unless ($config_level or $config_mask); # Умолчание - все биты установлены
say sprintf("%010b [%d]", $priority_mask, $priority_mask); # 01111111

# - сообщения error
#$priority_mask = setPriorityMask("error");
#say sprintf("%-20s %010b [%d]", "Message level", $priority_mask, $priority_mask); # 0000010000 [16]

#$priority_mask = getPriorityMask(getLevelByName("error"));
#say sprintf("%-20s %010b [%d]", "Config level", $priority_mask, $priority_mask); #

#say sprintf("%08b", setBit(123, LVL_INFO));
=cut

ok(checkLevel("error", LVL_ERROR),'Level=error');
ok(checkLevel("!error", LVL_ERROR),'Mask=error');
ok(checkLevel("notice,error", LVL_ERROR),'Mask=notice,error');
ok(!checkLevel("notice,error", LVL_INFO),'Mask=notice,error but Message=info');
ok(!checkLevel("error", LVL_INFO),'Level=error but Message=info');
ok(checkLevel("error", LVL_FATAL),'Level=error but Message=fatal');
ok(!checkLevel("none", LVL_FATAL),'Level=none but Message=fatal');
ok(!checkLevel("error", 250),'Level=error but Message=incorrect!');
ok(!checkLevel("error", 32),'Level=error but Message=32');
ok(!checkLevel("foo", LVL_ERROR),'Level=incorrect');
ok(!checkLevel("!foo", LVL_ERROR),'Mask=incorrect');

1;
