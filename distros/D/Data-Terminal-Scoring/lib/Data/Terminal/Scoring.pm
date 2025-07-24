package Data::Terminal::Scoring;

use strict;
use warnings;
use Carp;
use utf8;

our $VERSION = '0.01';


# 构造函数
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

# 主要计算函数 - 计算终端最终得分
sub calculate_score {
    my ($self, %params) = @_;
    
    # 验证输入参数
    $self->_validate_params(%params);
    
    # 提取参数
    my $service_years = $params{service_years};          # 服役年限
    my $online_rate = $params{online_rate};              # 在线率(百分比)
    my $remote_control_failures = $params{remote_control_failures} || 0;  # 遥控失败次数
    my $morning_check_failures = $params{morning_check_failures} || 0;    # 晨操失败次数
    my $abnormal_soe_signals = $params{abnormal_soe_signals} || 0;        # 异常SOE信号数量
    my $device_alarms = $params{device_alarms} || [];     # 本体信号告警数组
    
    # 计算各项扣分
    my $service_years_deduction = $self->_calculate_service_years_deduction($service_years);
    my $online_rate_deduction = $self->_calculate_online_rate_deduction($online_rate);
    my $remote_control_deduction = $self->_calculate_remote_control_deduction($remote_control_failures);
    my $morning_check_deduction = $self->_calculate_morning_check_deduction($morning_check_failures);
    my $soe_signal_deduction = $self->_calculate_soe_signal_deduction($abnormal_soe_signals);
    
    # 计算总扣分
    my $total_deduction = $service_years_deduction + $online_rate_deduction + 
                         $remote_control_deduction + $morning_check_deduction + 
                         $soe_signal_deduction;
    
    # 计算开关系数
    my $switch_coefficient = $self->_calculate_switch_coefficient($device_alarms);
    
    # 计算最终得分: 满分100 - 总扣分数 * 开关系数
    my $final_score = 100 - ($total_deduction * $switch_coefficient);
    
    # 异常处理：确保得分在0-100范围内
    $final_score = 0 if $final_score < 0;
    $final_score = 100 if $final_score > 100;
    
    # 返回详细结果
    return {
        final_score => sprintf("%.2f", $final_score),
        service_years_deduction => $service_years_deduction,
        online_rate_deduction => $online_rate_deduction,
        remote_control_deduction => $remote_control_deduction,
        morning_check_deduction => $morning_check_deduction,
        soe_signal_deduction => $soe_signal_deduction,
        total_deduction => $total_deduction,
        switch_coefficient => $switch_coefficient
    };
}

# 验证输入参数
sub _validate_params {
    my ($self, %params) = @_;
    
    # 检查必要参数
    croak "服役年限(service_years)是必需参数" unless defined $params{service_years};
    croak "在线率(online_rate)是必需参数" unless defined $params{online_rate};
    
    # 检查参数范围
    croak "服役年限必须大于等于0" if $params{service_years} < 0;
    croak "在线率必须在0-100之间" if $params{online_rate} < 0 || $params{online_rate} > 100;
    
    # 检查可选参数
    if (defined $params{remote_control_failures}) {
        croak "遥控失败次数必须大于等于0" if $params{remote_control_failures} < 0;
    }
    
    if (defined $params{morning_check_failures}) {
        croak "晨操失败次数必须大于等于0" if $params{morning_check_failures} < 0;
    }
    
    if (defined $params{abnormal_soe_signals}) {
        croak "异常SOE信号数量必须大于等于0" if $params{abnormal_soe_signals} < 0;
    }
    
    if (defined $params{device_alarms}) {
        croak "设备告警必须是数组引用" unless ref $params{device_alarms} eq 'ARRAY';
    }
}

# 计算服役年限扣分 (共10分)
sub _calculate_service_years_deduction {
    my ($self, $years) = @_;
    
    if ($years > 8) {
        return 10;  # 服役年限 > 8年 扣10分
    } elsif ($years > 5) {
        return 8;   # 5年 < 运行年限 <= 8年 扣8分
    } elsif ($years > 3) {
        return 6;   # 3年 < 运行年限 <= 5年 扣6分
    } elsif ($years > 1) {
        return 2;   # 1年 < 运行年限 <= 3年 扣2分
    } else {
        return 0;   # 运行年限<=1年 扣0分
    }
}

# 计算在线率扣分 (共30分)
sub _calculate_online_rate_deduction {
    my ($self, $rate) = @_;
    
    if ($rate <= 70) {
        return 30;  # 终端在线率<=70% 扣30分
    } elsif ($rate <= 80) {
        return 20;  # 终端在线率>70%, <=80% 扣20分
    } elsif ($rate <= 90) {
        return 10;  # 终端在线率>80%, <=90% 扣10分
    } elsif ($rate <= 95) {
        return 5;   # 终端在线率>90%, <=95% 扣5分
    } else {
        return 0;   # 终端在线率> 95% 扣0分
    }
}

# 计算遥控扣分 (共30分)
sub _calculate_remote_control_deduction {
    my ($self, $failures) = @_;
    
    if ($failures >= 3) {
        return 30;  # 指定周期内发生三次及以上遥控不成功 扣30分
    } elsif ($failures == 2) {
        return 20;  # 指定周期内发生二次遥控不成功 扣20分
    } elsif ($failures == 1) {
        return 10;  # 指定周期内发生一次遥控不成功 扣10分
    } else {
        return 0;   # 指定周期内遥控全部正确或未发生遥控 扣0分
    }
}

# 计算晨操扣分 (共10分)
sub _calculate_morning_check_deduction {
    my ($self, $failures) = @_;
    
    if ($failures >= 3) {
        return 10;  # 指定周期内发生三次及以上晨操不成功 扣10分
    } elsif ($failures == 2) {
        return 5;   # 指定周期内发生二次晨操不成功 扣5分
    } elsif ($failures == 1) {
        return 2;   # 指定周期内发生一次晨操不成功 扣2分
    } else {
        return 0;   # 指定周期内晨操都正确 扣0分
    }
}

# 计算SOE信号扣分 (共20分)
sub _calculate_soe_signal_deduction {
    my ($self, $abnormal_count) = @_;
    
    if ($abnormal_count > 25) {
        # 超出25个的部分每一条扣1分，最多扣20分
        my $excess = $abnormal_count - 25;
        return $excess > 20 ? 20 : $excess;
    } else {
        return 0;   # SOE信号数量不超过25个不扣分
    }
}

# 计算开关系数
sub _calculate_switch_coefficient {
    my ($self, $alarms) = @_;
    
    # 定义本体信号告警类型
    my %alarm_types = (
        'power_module_outage' => '电源模块失电信号',
        'power_module_battery_low' => '电源模块电池欠压告警',
        'power_module_battery_fault' => '电源模块电池故障告警',
        'device_abnormal_alarm' => '装置异常告警/控制器异常告警',
        'charging_module_abnormal' => '充电模块异常',
        'power_module_status_abnormal' => '电源模块运行状态异常',
        'frequency_abnormal' => '频率异常',
        'pt_disconnection' => 'pt断线',
        'ct_disconnection' => 'ct断线',
        'switch_input_abnormal' => '开入异常',
        'reclosing_abnormal' => '重合闸异常',
        'terminal_fault_alarm' => '终端故障告警',
        'terminal_battery_low' => '终端电池欠压',
        'control_circuit_disconnection' => '控制回路断线',
        'control_circuit_status_abnormal' => '控制回路状态异常',
        'ad_abnormal' => 'ad异常',
        'digital_board_abnormal' => '数字板卡异常',
        'analog_board_abnormal' => '模拟板卡异常',
        'close_abnormal_flag' => '合异常标志',
        'open_abnormal_flag' => '分异常标志',
        'operation_circuit_abnormal' => '操作回路异常',
        'complete_device_status_abnormal' => '成套装置运行状态异常',
        'spring_not_charged' => '弹簧未储能'
    );
    
    # 基础系数为1
    my $coefficient = 1.0;
    
    # 统计有效告警数量（去重）
    my %unique_alarms;
    for my $alarm (@$alarms) {
        if (exists $alarm_types{$alarm}) {
            $unique_alarms{$alarm} = 1;
        }
    }
    
    # 每个有效告警增加0.1系数
    my $alarm_count = scalar keys %unique_alarms;
    $coefficient += ($alarm_count * 0.1);
    
    return $coefficient;
}

# 获取支持的告警类型列表
sub get_supported_alarm_types {
    my $self = shift;
    
    return [
        'power_module_outage',              # 电源模块失电信号
        'power_module_battery_low',         # 电源模块电池欠压告警
        'power_module_battery_fault',       # 电源模块电池故障告警
        'device_abnormal_alarm',            # 装置异常告警/控制器异常告警
        'charging_module_abnormal',         # 充电模块异常
        'power_module_status_abnormal',     # 电源模块运行状态异常
        'frequency_abnormal',               # 频率异常
        'pt_disconnection',                 # pt断线
        'ct_disconnection',                 # ct断线
        'switch_input_abnormal',            # 开入异常
        'reclosing_abnormal',               # 重合闸异常
        'terminal_fault_alarm',             # 终端故障告警
        'terminal_battery_low',             # 终端电池欠压
        'control_circuit_disconnection',    # 控制回路断线
        'control_circuit_status_abnormal',  # 控制回路状态异常
        'ad_abnormal',                      # ad异常
        'digital_board_abnormal',           # 数字板卡异常
        'analog_board_abnormal',            # 模拟板卡异常
        'close_abnormal_flag',              # 合异常标志
        'open_abnormal_flag',               # 分异常标志
        'operation_circuit_abnormal',       # 操作回路异常
        'complete_device_status_abnormal',  # 成套装置运行状态异常
        'spring_not_charged'                # 弹簧未储能
    ];
}

1;

__END__

=encoding utf8

=head1 NAME

Data::Terminal::Scoring - Distribution network terminal scoring module

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Data::Terminal::Scoring;
    
    my $scorer = Data::Terminal::Scoring->new();
    
    my $result = $scorer->calculate_score(
        service_years => 6,                    # 服役年限
        online_rate => 85,                     # 在线率(%)
        remote_control_failures => 1,         # 遥控失败次数
        morning_check_failures => 0,          # 晨操失败次数
        abnormal_soe_signals => 30,           # 异常SOE信号数量
        device_alarms => ['pt_disconnection', 'ct_disconnection']  # 设备告警
    );
    
    print "最终得分: " . $result->{final_score} . "\n";

=head1 DESCRIPTION

这个模块用于计算配网终端的综合评分，基于服役年限、在线率、遥控成功率、
晨操成功率、SOE信号异常数量以及各种设备告警信号来进行评分。

=head1 METHODS

=head2 new()

创建一个新的评分对象。

=head2 calculate_score(%params)

计算终端最终得分。参数包括：
- service_years: 服役年限（必需）
- online_rate: 在线率百分比（必需）
- remote_control_failures: 遥控失败次数（可选，默认0）
- morning_check_failures: 晨操失败次数（可选，默认0）
- abnormal_soe_signals: 异常SOE信号数量（可选，默认0）
- device_alarms: 设备告警数组引用（可选，默认空数组）

=head2 get_supported_alarm_types()

返回支持的告警类型列表。

=head1 AUTHOR

ypeng at t-online.de

=cut
