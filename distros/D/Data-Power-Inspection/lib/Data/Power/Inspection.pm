package Data::Power::Inspection;

use strict;
use warnings;
use Exporter qw(import);
use Data::Dumper;
use List::Util qw(first);
use utf8;
use open qw(:std :utf8);

binmode(STDOUT, ":utf8");

=encoding utf8

=head1 NAME

Data::Power::Inspection - Power Equipment Fault Inspection and Troubleshooting Library

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

our @EXPORT_OK = qw(
    get_inspection_rules
    get_rules_by_device
    get_rules_by_data_source
    get_rules_by_priority
    get_replaceable_inspection_rules
    get_equipment_fault_criteria
);

# 知识库结构化数据
my $inspection_knowledge = {
    # 柱上开关类设备的巡检规则
    '柱上开关' => {
        '开关本体' => {
            # 一级规则：储能指示检查
            '储能指示检查' => {
                description => '观察储能指示牌、调阅储能遥信状态',
                problem => '操动机构未储能',
                replaceable => 1,
                algorithm => '弹簧未储能或弹簧已储能的反信号触发，且30S后信号没有复归，判断异常',
                data => [
                    {
                        content => '开关SOE告警信息（弹簧未储能、弹簧已储能）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            },
            
            # 一级规则：开关分合位置检查
            '开关分合位置检查' => {
                description => '查看开关实际位置和配电终端监测到的位置，核对两者是否一致',
                problem => '接线错误或装置组态配置错误，如取反或关联了错误开入信号，导致开关分合位置错误',
                replaceable => 1,
                algorithm => '分闸遥信与合闸遥信同时存在或同时不存在判断异常',
                data => [
                    {
                        content => '开关SOE告警信息（分闸遥信）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    },
                    {
                        content => '开关SOE告警信息（合闸遥信）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            },
            
            # 一级规则：分位有流检查
            '分位有流检查' => {
                description => '查看开关实际位置和配电终端监测到的位置，核对两者是否一致',
                problem => '接线错误或装置组态配置错误，如取反或关联了错误开入信号，导致开关分合位置错误',
                replaceable => 1,
                algorithm => '分位有流，合位无流（一次电流<3A除外）判断异常',
                data => [
                    {
                        content => '开关SOE告警信息（分闸遥信）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    },
                    {
                        content => '开关SOE告警信息（合闸遥信）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    },
                    {
                        content => '遥测信息（电流值）',
                        source => '配网主站OCS系统',
                        frequency => '15分钟（遥测）',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            },
            
            # 一级规则：控制回路断线检查
            '控制回路断线检查' => {
                description => '人工肉眼观察检查',
                problem => '接线虚接或松动',
                replaceable => 1,
                algorithm => '触发控制回路断线信号判断异常（无法判断是否本体侧）',
                data => [
                    {
                        content => '开关SOE告警信息（控制回路）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            },
            
            # 一级规则：开关操动机构卡涩情况检查
            '开关操动机构卡涩情况检查' => {
                description => '日常巡视时通过肉眼观察外观做初步判断，观察开关结构是否锈蚀，检修时遥控操作试验观察判断',
                problem => '开关操动机构卡涩，分合闸速度变慢',
                replaceable => 1,
                algorithm => '保护动作信号与分闸遥信时间差大于100ms判断异常',
                data => [
                    {
                        content => '开关动作SOE告警信息（保护装置保护动作信号SOE）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    },
                    {
                        content => '开关SOE告警信息（分闸遥信）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            },
            
            # 一级规则：开关拒动情况检查
            '开关拒动情况检查' => {
                description => '开关保护动作却不分闸',
                problem => '开关拒动（保护动作不分闸）',
                replaceable => 1,
                algorithm => '自动化开关上送保护动作信号、未上送分闸遥信信号',
                data => [
                    {
                        content => '保护动作信号',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    },
                    {
                        content => '开关动作SOE告警信息（遥控分闸指令出口SOE）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            },
            
            # 一级规则：开关拒动（遥控执行不分闸）
            '遥控执行不分闸检查' => {
                description => '开关遥控执行却不分闸',
                problem => '开关拒动（遥控执行不分闸）',
                replaceable => 1,
                algorithm => '采集到"开关拒动"告警信号且未上送分闸遥信信号，判为异常',
                data => [
                    {
                        content => '开关拒动告警信号',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                        note => '开关不上送遥控出口信号,2022年后标准有"开关拒动"告警信号',
                    },
                    {
                        content => '开关SOE告警信息（分闸遥信）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            },
            
            # 三级规则：本体红外温度检查
            '本体红外温度检查' => {
                description => '人工红外测温',
                problem => '设备发热严重',
                replaceable => 1,
                algorithm => '参照缺陷库\n设备接头发热烧红、变色（实测温度＞90℃或相间温差＞30K ） 紧急',
                data => [
                    {
                        content => '红外测温信息',
                        source => '物联网系统',
                        frequency => '15分钟',
                        business_mode => '监',
                        priority => 3,
                        note => '物联网平台采集对应设备的信息较少，考虑选配单兵智能测试仪器',
                    }
                ]
            },
            
            # 三级规则：本体局放检查
            '本体局放检查' => {
                description => '人员到现场使用局放仪测量设备本体局放值',
                problem => '设备内部不同电介质之间的界面上产生的高部电荷积聚，可能导致设备的损坏和故障',
                replaceable => 1,
                algorithm => '局放≥20db，判断异常',
                data => [
                    {
                        content => '局放值',
                        source => '物联网系统',
                        frequency => '15分钟',
                        business_mode => '巡',
                        priority => 3,
                        note => '物联网平台采集对应设备的信息较少，考虑选配单兵智能测试仪器',
                    }
                ]
            }
        },
        
        'PT' => {
            # 二级规则：PT断线告警检查
            'PT断线告警检查' => {
                description => '人员到现场通过肉眼观察接线，用适当力度拉扯接线检查是否牢固；或人工检查信号。',
                problem => 'PT连接线缆虚接或松动',
                replaceable => 1,
                algorithm => '触发PT断线告警判断异常',
                data => [
                    {
                        content => '开关SOE告警信息（PT断线信息）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监&巡',
                        priority => 2,
                        note => '只能判断出发生PT断线,具体位置不能确定。建议增加XTU的电压采集功能',
                    }
                ]
            },
            
            # 二级规则：有流无压检查
            '有流无压检查' => {
                description => '人员到现场通过肉眼观察接线，用适当力度拉扯接线检查是否牢固；或人工检查信号。',
                problem => 'PT连接线缆虚接或松动',
                replaceable => 1,
                algorithm => '有流无压判为异常',
                data => [
                    {
                        content => '遥测信息（电流值）',
                        source => '配网主站OCS系统',
                        frequency => '15分钟（遥测）',
                        business_mode => '监&巡',
                        priority => 2,
                        note => '只能判断出发生PT断线,具体位置不能确定。建议增加XTU的电压采集功能',
                    },
                    {
                        content => '遥测信息（电压值）',
                        source => '配网主站OCS系统',
                        frequency => '15分钟（遥测）',
                        business_mode => '监&巡',
                        priority => 2,
                        note => '只能判断出发生PT断线,具体位置不能确定。建议增加XTU的电压采集功能',
                    }
                ]
            },
            
            # 二级规则：PT相序异常告警检查
            'PT相序异常告警检查' => {
                description => '人工相序仪测相序',
                problem => '相序错误导致线路故障或发热',
                replaceable => 1,
                algorithm => '配置有UA/UB/UC三相电压或者配置UAB/UBC两个线电压\n基于基准角度0、-120、120；如果任一相相对其他相偏差大于15度\n满足以上条件保持10s（有些地方程序是3s），产生PT相序异常。\n同一线路开关基准角度应保持一致',
                data => [
                    {
                        content => '遥测信息',
                        source => '配网主站OCS系统',
                        frequency => '15分钟（遥测）',
                        business_mode => '监&巡',
                        priority => 2,
                        note => 'ocs没采集',
                    }
                ]
            }
        },
        
        'FTU' => {
            # 二级规则：就地远方投退状态检查
            '就地远方投退状态检查' => {
                description => '人工检查就地远方投退状态',
                problem => '就地远方投退状态错误',
                replaceable => 1,
                algorithm => '运维数据（远方就地状态）与配网主站OCS系统遥信（远方就地状态）不一致判断异常',
                data => [
                    {
                        content => '运维数据（远方就地状态）',
                        source => 'XTU补采',
                        frequency => '实时',
                        business_mode => '监&巡',
                        priority => 2,
                        additional_channel => 1,
                    }
                ]
            },
            
            # 三级规则：硬压板投退状态检查
            '硬压板投退状态检查' => {
                description => '现场检查硬压板投退状态',
                problem => '硬压板状态与实际运行要求不一致',
                replaceable => 1,
                algorithm => '新标准装置有 压板状态监测功能（双源压板）',
                data => [
                    {
                        content => '压板状态监测信号',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '巡',
                        priority => 3,
                        note => '部分可实现',
                    }
                ]
            },
            
            # 二级规则：对时异常检查
            '对时异常检查' => {
                description => '检查配网自动化终端与主站系统对时正确',
                problem => '装置对时异常，与标准时间存在肉眼可见的误差，导致SOE时标错误',
                replaceable => 1,
                algorithm => '装置时间与主站时间对比，不一致判断异常',
                data => [
                    {
                        content => '运维数据（遥测：装置时间）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监&巡',
                        priority => 2,
                    }
                ]
            },
            
            # 三级规则：零序电流检查
            '零序电流检查' => {
                description => '人员在主站运行界面上，查看零序电流值是否约为零',
                problem => '零序电流值过大，可能存在三相严重不平衡或其他故障',
                replaceable => 1,
                algorithm => '当零序电流＞0.1A时，判断异常',
                data => [
                    {
                        content => '配网主站OCS系统（零序电流值）',
                        source => '配网主站OCS系统',
                        frequency => '15分钟（遥测）',
                        business_mode => '巡',
                        priority => 3,
                    }
                ]
            }
        },
        
        '电源管理模块' => {
            # 二级规则：直流输出电压检查
            '直流输出电压检查' => {
                description => '检查输出电压额定值（±5％）',
                problem => '直流输出电压供电异常',
                replaceable => 1,
                algorithm => '遥测信息（直流输出电压）超过额定值（±20％）判断异常',
                data => [
                    {
                        content => '遥测信息（直流输出电压）',
                        source => '配网主站OCS系统',
                        frequency => '15分钟（遥测）',
                        business_mode => '监&巡',
                        priority => 2,
                        note => '按本地化原则',
                    }
                ]
            },
            
            # 二级规则：交流输入电压检查
            '交流输入电压检查' => {
                description => '检查输出电压额定值（±5％）',
                problem => '交流输入电压供电异常',
                replaceable => 1,
                algorithm => '遥测信息（交流输入电压）超过额定值（±20％）判断异常',
                data => [
                    {
                        content => '遥测信息（交流输入电压）',
                        source => '配网主站OCS系统',
                        frequency => '15分钟（遥测）',
                        business_mode => '监&巡',
                        priority => 2,
                        note => '按本地化原则',
                    }
                ]
            }
        },
        
        '蓄电池' => {
            # 二级规则：蓄电池电压检查
            '蓄电池电压检查' => {
                description => '检查输出电压额定值（±5％）',
                problem => '直流输出电压供电异常',
                replaceable => 1,
                algorithm => '遥测信息（直流输出电压）超过额定值（±20％）判断异常',
                data => [
                    {
                        content => '遥测信息（交直流输入输出电压）',
                        source => '配网主站OCS系统',
                        frequency => '15分钟（遥测）',
                        business_mode => '巡',
                        priority => 3,
                        note => '按本地化原则',
                    }
                ]
            },
            
            # 二级规则：蓄电池内阻检查
            '蓄电池内阻检查' => {
                description => '检查蓄电池内阻健康状态',
                problem => '蓄电池内阻异常无法使用',
                replaceable => 1,
                algorithm => '触发蓄电池内阻异常告警判断异常',
                data => [
                    {
                        content => '遥信信息（蓄电池内阻异常告警）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监&巡',
                        priority => 2,
                        note => '按本地化原则',
                    }
                ]
            }
        },
        
        '通讯加密装置' => {
            # 一级规则：加密装置与配电终端通信状态检查
            '加密装置与配电终端通信状态检查' => {
                description => '检查终端与配网主站通信状态',
                problem => '终端通信异常',
                replaceable => 1,
                algorithm => '通过XTU连接加密装置232/以太网接口，监测加密装置的报文，加密装置能收到主站报文，但没有回复报文给主站',
                data => [
                    {
                        content => '遥信（通信中断）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            },
            
            # 一级规则：通讯加密装置与配网主站通信状态检查
            '通讯加密装置与配网主站通信状态检查' => {
                description => '检查终端与配网主站通信状态',
                problem => '终端通信异常',
                replaceable => 1,
                algorithm => '通过监测装置实时通信状态（在线率）',
                data => [
                    {
                        content => '运维数据（误码率）',
                        source => 'XTU补采',
                        frequency => '实时',
                        business_mode => '监',
                        priority => 1,
                        additional_channel => 1,
                    }
                ]
            }
        }
    },
    
    # 开关柜类设备的巡检规则
    '开关柜' => {
        '外壳' => {
            # 三级规则：锈蚀情况检查
            '锈蚀情况检查' => {
                description => '人员到现场通过肉眼观察设备外观',
                problem => '设备长期在户外运行，导致设备外观破损如掉漆、生锈',
                replaceable => 1,
                algorithm => '通过图片识别设备是否生锈（算法是否能识别到）',
                data => [
                    {
                        content => '可见光摄像机拍摄图片（很少开关箱有采集）',
                        source => '物联网系统',
                        frequency => '15分钟',
                        business_mode => '巡',
                        priority => 3,
                        note => '图片较少,无对照识别或无摄像头,摄像头拍不到',
                    }
                ]
            },
            
            # 三级规则：变形情况检查
            '变形情况检查' => {
                description => '人员到现场通过肉眼观察设备外观',
                problem => '设备长期在户外运行，导致设备柜门变形或被打开等情况',
                replaceable => 1,
                algorithm => '通过图片识别设备箱门是否被打开或变形等。（算法是否能识别到）',
                data => [
                    {
                        content => '可见光摄像机拍摄图片（很少开关箱有采集）',
                        source => '物联网系统',
                        frequency => '15分钟',
                        business_mode => '巡',
                        priority => 3,
                        note => '图片较少,无对照识别或无摄像头,摄像头拍不到',
                    }
                ]
            }
        },
        
        '开关本体' => {
            # 二级规则：开门告警检查
            '开门告警检查' => {
                description => '人员到现场检查开门情况',
                problem => '设备异常开门',
                replaceable => 1,
                algorithm => '触发开门异常告警判断异常',
                data => [
                    {
                        content => '遥信信息（开门告警）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监&巡',
                        priority => 2,
                    }
                ]
            },
            
            # 一级规则：开关操动机构卡涩情况检查
            '开关操动机构卡涩情况检查' => {
                description => '日常巡视时通过肉眼观察外观做初步判断，观察开关结构是否锈蚀，检修时遥控操作试验观察判断',
                problem => '开关操动机构卡涩，分合闸速度变慢',
                replaceable => 1,
                algorithm => '保护动作信号与分闸遥信时间差大于100ms判断异常',
                data => [
                    {
                        content => '开关动作SOE告警信息（保护装置保护动作信号SOE）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    },
                    {
                        content => '开关SOE告警信息（分闸遥信）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            }
        },
        
        'DTU' => {
            # 三级规则：终端内部异常情况检查
            '终端内部异常情况检查' => {
                description => '检查硬盘可用容量、各种进程运行正常',
                problem => '终端设备内部异常',
                replaceable => 1,
                algorithm => '运维数据（硬盘可用容量）>80%判断异常',
                data => [
                    {
                        content => '运维数据（硬盘可用容量）',
                        source => 'XTU补采',
                        frequency => '实时',
                        business_mode => '巡',
                        priority => 3,
                        note => '硬件私有规约',
                        additional_channel => 1,
                    }
                ]
            },
            
            # 二级规则：对时异常检查
            '对时异常检查' => {
                description => '检查配网自动化终端与主站系统对时正确',
                problem => '装置对时异常，与标准时间存在肉眼可见的误差，导致SOE时标错误',
                replaceable => 1,
                algorithm => '通过计算同一告警的SOE、COS时标差，当差值＞30s时，判定对时异常',
                data => [
                    {
                        content => 'SOE和COS',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监&巡',
                        priority => 2,
                    }
                ]
            }
        },
        
        '直流电源' => {
            # 三级规则：输入电压情况检查
            '输入电压情况检查' => {
                description => '人员到现场读取直流屏上输入电压表计值',
                problem => '可能存在直流屏输入电压低情况',
                replaceable => 1,
                algorithm => '输入电压＜85%额定值时，判断异常',
                data => [
                    {
                        content => '装置直流屏输入电压（需要XTU具备采集这些量）',
                        source => 'XTU补采',
                        frequency => '实时',
                        business_mode => '巡',
                        priority => 3,
                        note => '增加采集传感模块',
                        additional_channel => 1,
                    }
                ]
            },
            
            # 二级规则：直流输出电压检查
            '直流输出电压检查' => {
                description => '检查输出电压额定值（±5％）',
                problem => '直流输出电压供电异常',
                replaceable => 1,
                algorithm => '遥测信息（直流输出电压）超过额定值（±20％）判断异常',
                data => [
                    {
                        content => '遥测信息（交直流输入输出电压）',
                        source => '配网主站OCS系统',
                        frequency => '15分钟（遥测）',
                        business_mode => '监&巡',
                        priority => 2,
                        note => '按本地化原则',
                    }
                ]
            }
        }
    },
    
    # 变压器类设备的巡检规则
    '变压器' => {
        '台变' => {
            # 三级规则：隔离刀闸分合位置检查
            '隔离刀闸分合位置检查' => {
                description => '人员在现场肉眼检查判断',
                problem => '隔离刀闸分合位置异常或虚接',
                replaceable => 1,
                algorithm => '触发隔离刀闸分合位置异常判断异常',
                data => [
                    {
                        content => '遥信（分合位置）',
                        source => 'XTU补采',
                        frequency => '实时',
                        business_mode => '巡',
                        priority => 3,
                        note => '结合智能网关3.0上送辅助触点数据',
                        additional_channel => 1,
                    }
                ]
            },
            
            # 三级规则：跌落式熔断器完整性检查
            '跌落式熔断器完整性检查' => {
                description => '人员在现场肉眼检查判断',
                problem => '跌落式熔断器位置异常',
                replaceable => 1,
                algorithm => '触发跌落式熔断器分合位置异常判断异常',
                data => [
                    {
                        content => '遥信（分合位置）',
                        source => 'XTU补采',
                        frequency => '实时',
                        business_mode => '巡',
                        priority => 3,
                        note => '结合智能网关3.0上送辅助触点数据',
                        additional_channel => 1,
                    }
                ]
            }
        },
        
        '箱变' => {
            # 二级规则：开门告警检查
            '开门告警检查' => {
                description => '人员到现场检查开门情况',
                problem => '设备异常开门',
                replaceable => 1,
                algorithm => '触发开门异常告警判断异常',
                data => [
                    {
                        content => '遥信信息（开门告警）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监&巡',
                        priority => 2,
                    }
                ]
            },
            
            # 一级规则：开关操动机构卡涩情况检查
            '开关操动机构卡涩情况检查' => {
                description => '现场观察开关结构是否锈蚀',
                problem => '开关操动机构卡涩，分合闸速度变慢',
                replaceable => 1,
                algorithm => '保护动作信号与分闸遥信时间差大于100ms判断异常',
                data => [
                    {
                        content => '开关动作SOE告警信息（保护装置保护动作信号SOE）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    },
                    {
                        content => '开关SOE告警信息（分闸遥信）',
                        source => '配网主站OCS系统',
                        frequency => '实时（遥信）',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            }
        },
        
        '变压器相同部分' => {
            # 二级规则：变压器重过载告警检查
            '变压器重过载告警检查' => {
                description => '检查变压器的负载是否在正常范围内，避免负载过高导致的设备故障',
                problem => '变压器重过载',
                replaceable => 1,
                algorithm => '高压侧/低压侧：功率＞***，判断异常',
                data => [
                    {
                        content => '遥测信息（功率）',
                        source => '配网主站OCS系统、计量系统',
                        frequency => '15分钟（遥测）',
                        business_mode => '监&巡',
                        priority => 2,
                    }
                ]
            },
            
            # 二级规则：高压侧电压异常检查
            '高压侧电压异常检查' => {
                description => '使用电子检测仪等检查变压器电压电气参数，确保其在正常范围内',
                problem => '可能存在电压异常情况',
                replaceable => 1,
                algorithm => '高压侧/低压侧：电压＞110%Un或电压＜90%Un，判断异常',
                data => [
                    {
                        content => '遥测信息（电压值）',
                        source => '配网主站OCS系统、计量系统',
                        frequency => '15分钟（遥测）',
                        business_mode => '监&巡',
                        priority => 2,
                    }
                ]
            }
        }
    },
    
    # 地极类设备的巡检规则
    '地极' => {
        '变压器' => {
            # 一级规则：设备绝缘检查
            '设备绝缘检查' => {
                description => '现场人工仪器测量',
                problem => '绝缘漏电隐患发现不及时、绝缘下降原因不明、绝缘配合有效性不清楚',
                replaceable => 1,
                algorithm => "1、泄漏电流>1000mA判断异常\n2、接地反击电压>10kV",
                data => [
                    {
                        content => '全景监测数据（泄漏电流值、反击电压值）',
                        source => 'XTU补采',
                        frequency => '泄漏电流1分钟/次；接地反击电压触发采集',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            },
            
            # 一级规则：接地点检查
            '接地点检查' => {
                description => '现场人工检查',
                problem => '接地不可靠、绝缘漏电隐患发现不及时',
                replaceable => 1,
                algorithm => "1、泄漏电流<1mA判断异常\n2、反击电压/泄放电流比值>设定值判断异常\n3、接地反击电压>10kV",
                data => [
                    {
                        content => '全景监测数据（泄漏电流值、反击电压值、泄放雷电流值）',
                        source => 'XTU补采',
                        frequency => '泄漏电流5分钟/次；接地反击电压、泄放电流触发采集',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            }
        },
        
        '开关' => {
            # 一级规则：设备绝缘检查
            '设备绝缘检查' => {
                description => '现场人工仪器测量',
                problem => '绝缘漏电隐患发现不及时、绝缘下降原因不明、绝缘配合有效性不清楚',
                replaceable => 1,
                algorithm => "1、泄漏电流>10A判断异常\n2、接地反击电压>10kV",
                data => [
                    {
                        content => '全景监测数据（泄漏电流值、反击电压值）',
                        source => 'XTU补采',
                        frequency => '泄漏电流1分钟/次；接地反击电压触发采集',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            },
            
            # 一级规则：接地点检查
            '接地点检查' => {
                description => '现场人工仪器测量',
                problem => '接地不可靠、绝缘漏电隐患发现不及时',
                replaceable => 1,
                algorithm => "1、泄漏电流<1mA判断异常\n2、反击电压/泄放电流比值>设定值判断异常\n3、接地反击电压>10kV",
                data => [
                    {
                        content => '全景监测数据（泄漏电流值、反击电压值、泄放雷电流值）',
                        source => 'XTU补采',
                        frequency => '泄漏电流5分钟/次；接地反击电压、泄放电流触发采集',
                        business_mode => '监',
                        priority => 1,
                    }
                ]
            }
        }
    }
};

# 用于获取所有巡检规则
sub get_inspection_rules {
    return $inspection_knowledge;
}

# 用于按设备类型获取巡检规则
sub get_rules_by_device {
    my ($device_type) = @_;
    
    return $inspection_knowledge->{$device_type} if exists $inspection_knowledge->{$device_type};
    return;
}

# 用于按数据来源获取巡检规则
sub get_rules_by_data_source {
    my ($source) = @_;
    my %result;
    
    foreach my $device_type (keys %$inspection_knowledge) {
        foreach my $equipment (keys %{$inspection_knowledge->{$device_type}}) {
            foreach my $rule_name (keys %{$inspection_knowledge->{$device_type}{$equipment}}) {
                my $rule = $inspection_knowledge->{$device_type}{$equipment}{$rule_name};
                
                foreach my $data (@{$rule->{data}}) {
                    if ($data->{source} eq $source) {
                        $result{"$device_type.$equipment.$rule_name"} = $rule;
                    }
                }
            }
        }
    }
    
    return \%result;
}

# 用于按优先级获取巡检规则
sub get_rules_by_priority {
    my ($priority) = @_;
    my %result;
    
    foreach my $device_type (keys %$inspection_knowledge) {
        foreach my $equipment (keys %{$inspection_knowledge->{$device_type}}) {
            foreach my $rule_name (keys %{$inspection_knowledge->{$device_type}{$equipment}}) {
                my $rule = $inspection_knowledge->{$device_type}{$equipment}{$rule_name};
                
                foreach my $data (@{$rule->{data}}) {
                    if ($data->{priority} == $priority) {
                        $result{"$device_type.$equipment.$rule_name"} = $rule;
                    }
                }
            }
        }
    }
    
    return \%result;
}

# 获取可被系统替代的巡检规则
sub get_replaceable_inspection_rules {
    my %result;
    
    foreach my $device_type (keys %$inspection_knowledge) {
        foreach my $equipment (keys %{$inspection_knowledge->{$device_type}}) {
            foreach my $rule_name (keys %{$inspection_knowledge->{$device_type}{$equipment}}) {
                my $rule = $inspection_knowledge->{$device_type}{$equipment}{$rule_name};
                
                if ($rule->{replaceable}) {
                    $result{"$device_type.$equipment.$rule_name"} = $rule;
                }
            }
        }
    }
    
    return \%result;
}

# 获取设备故障判断标准
sub get_equipment_fault_criteria {
    my ($device_type, $equipment, $inspection_name) = @_;
    
    if (exists $inspection_knowledge->{$device_type} && 
        exists $inspection_knowledge->{$device_type}{$equipment} &&
        exists $inspection_knowledge->{$device_type}{$equipment}{$inspection_name}) {
        
        return $inspection_knowledge->{$device_type}{$equipment}{$inspection_name}{algorithm};
    }
    
    return;
}

1;

=head1 SYNOPSIS

The module provides the following functions for use:

1. get_inspection_rules

Retrieves all available inspection rules in the system.

2. get_rules_by_device

Retrieves inspection rules specific to a given device type or name.

3. get_rules_by_data_source

Retrieves inspection rules based on the data sources required by the rules.

4. get_rules_by_priority

Retrieves inspection rules filtered by their priority level.

5. get_replaceable_inspection_rules

Retrieves inspection rules that are marked as replaceable.

6. get_equipment_fault_criteria

Retrieves the fault criteria for specific equipment or device types.


=head1 Usage Example

    use Data::Power::Inspection qw(get_rules_by_device);
    use utf8;
    use open qw(:std :utf8);

    binmode(STDOUT, ":utf8");

    # Retrieve inspection rules for a specific device type
    my $pole_switch_rules = get_rules_by_device('柱上开关');

    # Process and display the rules

    foreach my $equipment (sort keys %$pole_switch_rules) {
        print "== $equipment ==\n";

        foreach my $rule_name (sort keys %{$pole_switch_rules->{$equipment}}) {
            my $rule = $pole_switch_rules->{$equipment}{$rule_name};

            print "\n- 巡检项目: $rule_name\n";
            print "  巡检内容: $rule->{description}\n";
            print "  可能问题: $rule->{problem}\n";
            print "  可替代性: " . ($rule->{replaceable} ? "可替代" : "不可替代") . "\n";
            print "  判断算法: $rule->{algorithm}\n";

            print "  数据要求:\n";
            foreach my $data (@{$rule->{data}}) {
                print "    - 内容: $data->{content}\n";
                print "      来源: $data->{source}\n";
                print "      频率: $data->{frequency}\n";
                print "      业务: $data->{business_mode}\n";
                print "      优先级: $data->{priority}\n";

                print "      说明: $data->{note}\n" if exists $data->{note};

                print "      需要额外通道: 是\n" if exists $data->{additional_channel} && $data->{additional_channel};
            }

            print "\n";
        }

        print "\n";
    }

=head1 AUTHOR

Y Peng, C<< <ypeng at t-online.de> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Y Peng.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
