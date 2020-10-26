#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Exception;

use App::timecalc;

is(App::timecalc::eval_time_expr("+01:23"), "+01:23:00");
is(App::timecalc::eval_time_expr("+1:23") , "+01:23:00");
is(App::timecalc::eval_time_expr("+0123") , "+01:23:00");
is(App::timecalc::eval_time_expr("+123")  , "+01:23:00");

is(App::timecalc::eval_time_expr("+03:00 -01:23"), "+01:37:00");
is(App::timecalc::eval_time_expr("+03:00 -1:23") , "+01:37:00");
is(App::timecalc::eval_time_expr("+03:00 -0123") , "+01:37:00");
is(App::timecalc::eval_time_expr("+03:00 -123")  , "+01:37:00");

is(App::timecalc::eval_time_expr("00:26-05:16"), "+04:50:00");
is(App::timecalc::eval_time_expr("0026-0516")  , "+04:50:00");
is(App::timecalc::eval_time_expr("026-516")    , "+04:50:00");

done_testing;
