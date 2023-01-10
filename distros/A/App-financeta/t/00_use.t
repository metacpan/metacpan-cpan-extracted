use strict;
use warnings;
use Test::More;

use_ok('App::financeta::mo');
use_ok('App::financeta::utils');
foreach (qw(dumper log_filter get_icon_path)) {
    can_ok('App::financeta::utils', $_);
}
use_ok('App::financeta::language');

use_ok('App::financeta::indicators');
foreach (qw(calculate_pnl get_plot_args_buysell get_plot_args buysell
    execute_ohlcv get_params get_funcs get_groups 
    price group_name group_key statistic colors next_color
    overlaps ma_name volatility momentum hilbert volume candlestick)) {
    can_ok('App::financeta::indicators', $_);
}
use_ok('App::financeta::editor');
foreach (qw(execute compile get_text update_editor close)) {
    can_ok('App::financeta::editor', $_);
}
use_ok('App::financeta::tradereport');
foreach (qw(save close update)) {
    can_ok('App::financeta::tradereport', $_);
}
use_ok('App::financeta::gui');
foreach (qw(run)) {
    can_ok('App::financeta::gui', $_);
}
use_ok('App::financeta');
foreach (qw(print_banner print_version_and_exit get_version run)) {
    can_ok('App::financeta', $_);
}

done_testing();

__END__
### COPYRIGHT: 2013-2023. Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 15th Aug 2014
### LICENSE: Refer LICENSE file

