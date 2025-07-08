package Data::Power::FaultDetectorBase;

use strict;
use warnings;
use JSON;

=encoding utf8

=head1 NAME

Data::Power::FaultDetectorBase - Medium Voltage Grid Equipment Fault Detection Baseline

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Data::Power::FaultDetectorBase;

  # 创建分析器实例
  my $analyzer = Data::Power::FaultDetectorBase->new(
      thresholds_file => 'thresholds.json',
      output_file => 'faults.csv'
  );

  # 从文件加载数据并分析
  $analyzer->analyze_data_file('input_data.csv');

  # 或者直接处理数据记录
  $analyzer->process_record({
      device_id => 'FTU00123',
      timestamp => '2025-07-01 12:34:56',
      I0 => 0.5,
      IA => 12.3,
      IB => 11.5,
      IC => 11.7,
      UA => 5.9,
      UB => 5.8,
      UC => 5.9,
      UAB => 10.1,
      UBC => 10.0,
      UCA => 10.0,
      P => 180.5,
      Q => 15.2,
      COS => 0.95
  });

  # 获取故障汇总结果
  my $fault_summary = $analyzer->get_fault_summary();

  # 导出故障报告
  $analyzer->export_fault_report();

=head1 DESCRIPTION

Data::Power::FaultDetectorBase模块用于分析中压配电网设备的故障情况。通过分析各种电气参数
（如电流、电压、功率和功率因数等），该模块能够识别潜在故障并生成报告。

=head1 METHODS

=cut

# 故障代码常量定义
use constant {
    # 电流相关故障
    FAULT_OVERCURRENT => 'E001',        # 过流
    FAULT_UNDERCURRENT => 'E002',       # 欠流
    FAULT_CURRENT_UNBALANCE => 'E003',  # 三相电流不平衡
    FAULT_EXTREME_OVERCURRENT => 'E004', # 极端过流
    FAULT_LEAKAGE_CURRENT => 'E005',    # 漏电流异常

    # 电压相关故障
    FAULT_OVERVOLTAGE => 'E101',        # 过压
    FAULT_UNDERVOLTAGE => 'E102',       # 欠压
    FAULT_VOLTAGE_UNBALANCE => 'E103',  # 三相电压不平衡
    FAULT_EXTREME_UNDERVOLTAGE => 'E104', # 极端欠压
    FAULT_LINE_VOLTAGE_ABNORMAL => 'E105', # 线电压异常

    # 功率相关故障
    FAULT_ACTIVE_POWER_HIGH => 'E201',  # 有功功率过高
    FAULT_ACTIVE_POWER_LOW => 'E202',   # 有功功率过低
    FAULT_REACTIVE_POWER_HIGH => 'E203', # 无功功率过高
    FAULT_REACTIVE_POWER_LOW => 'E204',  # 无功功率过低
    FAULT_EXTREME_POWER => 'E205',      # 极端功率值

    # 功率因数相关故障
    FAULT_LOW_POWER_FACTOR => 'E301',   # 低功率因数
    FAULT_NEGATIVE_POWER_FACTOR => 'E302', # 负功率因数
};

=head2 new

创建新的故障分析器实例

参数:
  thresholds_file - 包含阈值设置的JSON文件路径
  output_file - 输出故障报告的文件路径（可选）

返回:
  Data::Power::FaultDetectorBase对象实例

=cut

sub new {
    my ($class, %args) = @_;

    my $self = {
        thresholds => {},
        fault_records => {},
        device_faults => {},
        fault_counts => {},
        output_file => $args{output_file} || 'fault_report.csv',
    };

    bless $self, $class;

    # 加载阈值配置
    if ($args{thresholds_file}) {
        $self->load_thresholds($args{thresholds_file});
    } elsif ($args{thresholds_json}) {
        $self->set_thresholds_from_json($args{thresholds_json});
    }

    return $self;
}

=head2 load_thresholds

从JSON文件加载阈值配置

参数:
  file_path - JSON文件路径

返回:
  成功返回1，失败返回0

=cut

sub load_thresholds {
    my ($self, $file_path) = @_;

    open my $fh, '<', $file_path or do {
        warn "Cannot open threshold file $file_path: $!";
        return 0;
    };

    local $/;
    my $json_text = <$fh>;
    close $fh;

    return $self->set_thresholds_from_json($json_text);
}

=head2 set_thresholds_from_json

从JSON字符串设置阈值配置

参数:
  json_text - 包含阈值配置的JSON字符串

返回:
  成功返回1，失败返回0

=cut

sub set_thresholds_from_json {
    my ($self, $json_text) = @_;

    my $thresholds;
    eval {
        $thresholds = decode_json($json_text);
    };

    if ($@) {
        warn "Error parsing threshold JSON: $@";
        return 0;
    }

    # 在eval外部赋值，确保只有当解析成功后才修改对象
    $self->{thresholds} = $thresholds;
    return 1;
}

=head2 analyze_data_file

分析包含多条记录的数据文件

参数:
  file_path - CSV文件路径，每行包含一条设备数据记录

返回:
  处理的记录数量

=cut

sub analyze_data_file {
    my ($self, $file_path) = @_;

    open my $fh, '<', $file_path or do {
        warn "Cannot open data file $file_path: $!";
        return 0;
    };

    my $header = <$fh>;
    chomp $header;
    my @fields = split /,/, $header;

    my $count = 0;
    while (my $line = <$fh>) {
        chomp $line;
        my @values = split /,/, $line;

        my %record;
        for (my $i = 0; $i < @fields; $i++) {
            $record{$fields[$i]} = $values[$i] if $i < @values;
        }

        $self->process_record(\%record);
        $count++;
    }

    close $fh;
    return $count;
}

=head2 process_record

处理单条设备记录并检测潜在故障

参数:
  record - 包含设备数据的哈希引用，需包含device_id和timestamp字段，
           以及I0, IA, IB, IC, UA, UB, UC, UAB, UBC, UCA, P, Q, COS等测量值

返回:
  该记录检测到的故障代码数组引用

=cut

sub process_record {
    my ($self, $record) = @_;

    # 验证必要字段
    unless ($record->{device_id} && $record->{timestamp}) {
        warn "Record missing required fields (device_id or timestamp)";
        return [];
    }

    my @faults;

    # 检查零序电流故障 (I0)
    if (defined $record->{I0}) {
        if ($record->{I0} > $self->{thresholds}->{I0}->{extreme_high}) {
            push @faults, FAULT_LEAKAGE_CURRENT;
        } elsif ($record->{I0} > $self->{thresholds}->{I0}->{high_threshold}) {
            push @faults, FAULT_LEAKAGE_CURRENT;
        }
    }

    # 检查相电流故障 (IA, IB, IC)
    foreach my $phase ('IA', 'IB', 'IC') {
        if (defined $record->{$phase}) {
            if ($record->{$phase} > $self->{thresholds}->{$phase}->{extreme_high}) {
                push @faults, FAULT_EXTREME_OVERCURRENT;
            } elsif ($record->{$phase} > $self->{thresholds}->{$phase}->{upper_threshold}) {
                push @faults, FAULT_OVERCURRENT;
            } elsif ($record->{$phase} < $self->{thresholds}->{$phase}->{lower_threshold}) {
                push @faults, FAULT_UNDERCURRENT;
            }
        }
    }

    # 检查三相电流不平衡
    if (defined $record->{IA} && defined $record->{IB} && defined $record->{IC}) {
        my $avg_current = ($record->{IA} + $record->{IB} + $record->{IC}) / 3;
        my $max_deviation = 0;

        foreach my $phase ('IA', 'IB', 'IC') {
            my $deviation = abs($record->{$phase} - $avg_current) / $avg_current;
            $max_deviation = $deviation if $deviation > $max_deviation;
        }

        if ($max_deviation > 0.2) {  # 20%以上视为不平衡
            push @faults, FAULT_CURRENT_UNBALANCE;
        }
    }

    # 检查相电压故障 (UA, UB, UC)
    foreach my $phase ('UA', 'UB', 'UC') {
        if (defined $record->{$phase}) {
            if ($record->{$phase} > $self->{thresholds}->{$phase}->{upper_threshold}) {
                push @faults, FAULT_OVERVOLTAGE;
            } elsif ($record->{$phase} < $self->{thresholds}->{$phase}->{lower_threshold}) {
                push @faults, FAULT_UNDERVOLTAGE;
            } elsif ($record->{$phase} < $self->{thresholds}->{$phase}->{extreme_low}) {
                push @faults, FAULT_EXTREME_UNDERVOLTAGE;
            }
        }
    }

    # 检查线电压故障 (UAB, UBC, UCA)
    foreach my $line ('UAB', 'UBC', 'UCA') {
        if (defined $record->{$line}) {
            if ($record->{$line} > $self->{thresholds}->{$line}->{upper_threshold}) {
                push @faults, FAULT_LINE_VOLTAGE_ABNORMAL;
            } elsif ($record->{$line} < $self->{thresholds}->{$line}->{lower_threshold}) {
                push @faults, FAULT_LINE_VOLTAGE_ABNORMAL;
            } elsif ($record->{$line} < $self->{thresholds}->{$line}->{extreme_low}) {
                push @faults, FAULT_EXTREME_UNDERVOLTAGE;
            }
        }
    }

    # 检查三相电压不平衡
    if (defined $record->{UA} && defined $record->{UB} && defined $record->{UC}) {
        my $avg_voltage = ($record->{UA} + $record->{UB} + $record->{UC}) / 3;
        my $max_deviation = 0;

        foreach my $phase ('UA', 'UB', 'UC') {
            my $deviation = abs($record->{$phase} - $avg_voltage) / $avg_voltage;
            $max_deviation = $deviation if $deviation > $max_deviation;
        }

        if ($max_deviation > 0.1) {  # 10%以上视为不平衡
            push @faults, FAULT_VOLTAGE_UNBALANCE;
        }
    }

    # 检查有功功率故障 (P)
    if (defined $record->{P}) {
        if ($record->{P} > $self->{thresholds}->{P}->{extreme_high}) {
            push @faults, FAULT_EXTREME_POWER;
        } elsif ($record->{P} > $self->{thresholds}->{P}->{upper_threshold}) {
            push @faults, FAULT_ACTIVE_POWER_HIGH;
        } elsif ($record->{P} < $self->{thresholds}->{P}->{lower_threshold}) {
            push @faults, FAULT_ACTIVE_POWER_LOW;
        } elsif ($record->{P} < $self->{thresholds}->{P}->{extreme_low}) {
            push @faults, FAULT_EXTREME_POWER;
        }
    }

    # 检查无功功率故障 (Q)
    if (defined $record->{Q}) {
        if ($record->{Q} > $self->{thresholds}->{Q}->{extreme_high}) {
            push @faults, FAULT_EXTREME_POWER;
        } elsif ($record->{Q} > $self->{thresholds}->{Q}->{upper_threshold}) {
            push @faults, FAULT_REACTIVE_POWER_HIGH;
        } elsif ($record->{Q} < $self->{thresholds}->{Q}->{lower_threshold}) {
            push @faults, FAULT_REACTIVE_POWER_LOW;
        } elsif ($record->{Q} < $self->{thresholds}->{Q}->{extreme_low}) {
            push @faults, FAULT_EXTREME_POWER;
        }
    }

    # 检查功率因数故障 (COS)
    if (defined $record->{COS}) {
        if ($record->{COS} < $self->{thresholds}->{COS}->{lower_threshold}) {
            push @faults, FAULT_LOW_POWER_FACTOR;
        } elsif ($record->{COS} < $self->{thresholds}->{COS}->{extreme_low}) {
            push @faults, FAULT_NEGATIVE_POWER_FACTOR;
        }
    }

    # 记录故障信息
    if (@faults) {
        my $device_id = $record->{device_id};
        my $timestamp = $record->{timestamp};

        $self->{fault_records}->{$device_id} ||= [];
        push @{$self->{fault_records}->{$device_id}}, {
            timestamp => $timestamp,
            faults => [@faults],
            data => { %$record }
        };

        # 更新设备故障统计
        $self->{device_faults}->{$device_id} ||= {};
        foreach my $fault (@faults) {
            $self->{device_faults}->{$device_id}->{$fault}++;
            $self->{fault_counts}->{$fault}++;
        }
    }

    return \@faults;
}

=head2 get_fault_summary

获取故障统计汇总

返回:
  包含故障统计信息的哈希引用

=cut

sub get_fault_summary {
    my ($self) = @_;

    my $summary = {
        total_devices => scalar(keys %{$self->{fault_records}}),
        total_faults => 0,
        fault_types => $self->{fault_counts},
        device_with_most_faults => '',
        max_faults => 0
    };

    # 计算总故障数和找出故障最多的设备
    foreach my $device_id (keys %{$self->{fault_records}}) {
        my $device_fault_count = scalar(@{$self->{fault_records}->{$device_id}});
        $summary->{total_faults} += $device_fault_count;

        if ($device_fault_count > $summary->{max_faults}) {
            $summary->{max_faults} = $device_fault_count;
            $summary->{device_with_most_faults} = $device_id;
        }
    }

    return $summary;
}

=head2 export_fault_report

导出故障报告到CSV文件

参数:
  file_path - 输出文件路径（可选，默认使用初始化时设置的输出文件）

返回:
  成功返回1，失败返回0

=cut

sub export_fault_report {
    my ($self, $file_path) = @_;

    $file_path ||= $self->{output_file};

    open my $fh, '>', $file_path or do {
        warn "Cannot open output file $file_path: $!";
        return 0;
    };

    # 写入标题行
    print $fh "device_id,timestamp,fault_codes\n";

    # 写入每条故障记录
    foreach my $device_id (sort keys %{$self->{fault_records}}) {
        foreach my $record (@{$self->{fault_records}->{$device_id}}) {
            my $fault_codes = join(',', @{$record->{faults}});
            print $fh "$device_id,$record->{timestamp},\"$fault_codes\"\n";
        }
    }

    close $fh;
    return 1;
}

=head2 get_device_faults

获取特定设备的故障记录

参数:
  device_id - 设备ID

返回:
  故障记录数组引用

=cut

sub get_device_faults {
    my ($self, $device_id) = @_;

    return $self->{fault_records}->{$device_id} || [];
}

=head2 get_devices_with_fault

获取具有特定故障代码的所有设备

参数:
  fault_code - 故障代码

返回:
  设备ID数组

=cut

sub get_devices_with_fault {
    my ($self, $fault_code) = @_;

    my @devices;
    foreach my $device_id (keys %{$self->{device_faults}}) {
        if (exists $self->{device_faults}->{$device_id}->{$fault_code}) {
            push @devices, $device_id;
        }
    }

    return \@devices;
}

=head1 FAULT CODES

模块使用以下故障代码:

电流相关故障:
  E001 - 过流
  E002 - 欠流
  E003 - 三相电流不平衡
  E004 - 极端过流
  E005 - 漏电流异常

电压相关故障:
  E101 - 过压
  E102 - 欠压
  E103 - 三相电压不平衡
  E104 - 极端欠压
  E105 - 线电压异常

功率相关故障:
  E201 - 有功功率过高
  E202 - 有功功率过低
  E203 - 无功功率过高
  E204 - 无功功率过低
  E205 - 极端功率值

功率因数相关故障:
  E301 - 低功率因数
  E302 - 负功率因数

=head1 AUTHOR

Y Peng, C<< <ypeng at t-online.de> >>

=cut

1;
