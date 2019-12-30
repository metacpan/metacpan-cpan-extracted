#!/usr/bin/env perl

use 5.012;
use warnings;
no warnings 'uninitialized';

use Data::Dumper;
use BigIP::GTM::ParseConfig;
use Encode;
use Encode::CN;

use POSIX qw/strftime/;
use Getopt::Long;
use Spreadsheet::WriteExcel;
use File::Slurper qw/read_lines read_dir/;

my ( $opt_V, $opt_h, $opt_d, $opt_f );

sub usage () {
    say encode(
        'cp936',
        decode_utf8(
            "\nperl $0 -d directory(目录) || -f f5_GTM_config(单个配置文件)\n"
        )
    );
    say encode(
        'cp936',
        decode_utf8(
            '使用过程如有任何疑问，请联系careline@126.com')
    );
    exit();
}

#  use Getopt::Long qw(:config no_ignore_case bundling);
Getopt::Long::Configure( "bundling", "no_ignore_case" );
GetOptions(
    'V'   => \$opt_V,
    'h'   => \$opt_h,
    'f=s' => \$opt_f,
    'd=s' => \$opt_d,
) || die usage();

my %dc = (
    "DC_ChaoSuan"  => "超算机房",
    "DC_813"       => "朝阳门机房",
    "DC_PengBoShi" => "鹏博士机房",
    "DC_650"       => "汇天机房",
    "DC_HeFei"     => "合肥机房"
);

# option handling initialization
if ($opt_V) {
    say "F5 DevCenter BIGIP GTM configuration Parser V2.020";
    exit(-1);
}

if ( $opt_h || not( $opt_d || $opt_f ) ) {
    usage();
}

my $dirname = $opt_d;

sub write_excel {
    my $GTM  = shift;
    my $time = strftime( "%Y%m%d", localtime() );

    my $bip     = BigIP::GTM::ParseConfig->new($GTM);
    my $dns_all = $bip->wideips_all();

    # Create a new Excel workbook
    my $workbook
        = Spreadsheet::WriteExcel->new(
        "bigip-GTM-reports_$GTM" . "_$time" . '.xls' );

    # Add a worksheet
    my $worksheet = $workbook->add_worksheet( $GTM . '_DNS_details' );

    # Add and define a format
    my $format = $workbook->add_format();    # Add a format
    $format->set_bold();
    $format->set_color('blue');
    $format->set_bg_color('red');
    $format->set_size(18);
    $format->set_border(1);
    $format->set_align('center');
    $format->set_valign('vcenter');

    my $format_1 = $workbook->add_format();
    $format_1->set_size(12);
    $format_1->set_border(1);
    $format_1->set_align('left');
    $format_1->set_valign('vcenter');

    my $format_2 = $workbook->add_format();
    $format_1->set_size(12);
    $format_2->set_align('center');
    $format_2->set_valign('vcenter');

    # set column and row width;
    $worksheet->set_column( 0, 6, 45, $format_2 );

    # Write a formatted and unformatted string, row and column notation.
    my $excel_array = [
        decode_utf8("DNS条目"),
        decode_utf8("负载模式"),
        decode_utf8("POOL-优先级"),
        decode_utf8("VS映射关系"),
        decode_utf8("DNS解析明细"),
        decode_utf8("健康检查-服务类型"),
        decode_utf8("工单信息"),
    ];
    $worksheet->write_row( 0, 0, $excel_array, $format );

    my ( $result, $dns_attr );
    my $row = 0;
    foreach my $dns ( keys %{$dns_all} ) {
        foreach my $attr ( keys %{ $dns_all->{$dns} } ) {
            $result->{$dns}{"wide_ip"} = $dns;
            my $ret = $dns_all->{$dns}{$attr};

            $result->{$dns}{"report"}     ||= [];
            $result->{$dns}{"server"}     ||= [];
            $result->{$dns}{"monitor"}    ||= [];
            $result->{$dns}{"pool_order"} ||= [];

            if ( $attr =~ /\Apool-lb-mode\z/ ) {
                $result->{$dns}{"mode"} = $ret;
            }
            elsif ( $attr =~ /\Apools\z/ ) {
                my $pool;
                foreach ( keys %{$ret} ) {
                    my $rev = $ret->{$_};
                    $pool = $_;

                    my $order;
                    foreach ( keys %{$rev} ) {
                        $order .= join( " ", $_, '->', $rev->{$_}, ' ' )
                            if exists $rev->{$_};
                    }
                    my $pool_order = $pool . " \( $order \) ";
                    push @{ $result->{$dns}{"pool_order"} }, $pool_order;
                }
            }
            elsif ( $attr =~ /detail/ ) {
                foreach ( keys %{$ret} ) {
                    my $server_info = $ret->{$_}{"server_detail"};
                    my $pool_info   = $ret->{$_}{"pool_detail"};

                    foreach ( @{$server_info} ) {
                        my $location = $_->{"datacenter"}
                            if exists $_->{"datacenter"};
                        $location = $dc{$location};
                        my $monitor = $_->{"monitor"}
                            if exists $_->{"monitor"};
                        my $product = $_->{"product"}
                            if exists $_->{"product"};
                        my $server = $_->{"server"} if exists $_->{"server"};
                        my $vs     = $_->{"vs"}     if exists $_->{"vs"};
                        $vs =~ s/\/Common\///g;
                        my $ip_port
                            = $_->{"virtual-servers"}{$vs}{"destination"}
                            // "无关联IP";
                        $ip_port =~ s/\:/\->/g;

                        my $report = "$location / " . $ip_port;
                        my $mon    = $monitor . "($product)";
                        push @{ $result->{$dns}{"report"} }, $report;
                        push @{ $result->{$dns}{"server"} },
                            $server . " -> " . $vs;
                        push @{ $result->{$dns}{"monitor"} }, $mon;
                    }
                }
            }

            my $munge_report  = join( "\n", @{ $result->{$dns}{"report"} } );
            my $munge_monitor = join( "\n", @{ $result->{$dns}{"monitor"} } );
            my $munge_server  = join( "\n", @{ $result->{$dns}{"server"} } );
            my $munge_pool_order
                = join( "\n", @{ $result->{$dns}{"pool_order"} } );

            $dns_attr = [
                $result->{$dns}{"wide_ip"},
                decode_utf8( $result->{$dns}{"mode"} // '轮询' ),
                $munge_pool_order,
                decode_utf8($munge_server),
                decode_utf8($munge_report),
                decode_utf8($munge_monitor),
            ];
        }
        $row++;

        $worksheet->set_row( $row, 80 );
        $worksheet->write_row( $row, 0, $dns_attr, $format_1 );
    }
}

sub start_checker {
    if ($opt_f) {
        write_excel($opt_f);
        say encode(
            'cp936',
            decode_utf8(
                "BigIP GTM [$opt_f] 已分析完毕，自动生成的报表仅供参考;"
            )
        );
        say encode( 'cp936', decode_utf8("程序已处理完毕 ... ... ") );
    }
    elsif ($opt_d) {
        my $dirname = $opt_d;
        my @files   = grep {/\.cfg$|\.conf$|\.config$/} read_dir($dirname);

        chdir($dirname);
        foreach (@files) {
            write_excel($_);
            say encode(
                'cp936',
                decode_utf8(
                    "BigIP GTM [$_] 已分析完毕，自动生成的报表仅供参考;"
                )
            );
        }
        say encode( 'cp936', decode_utf8("程序已处理完毕 ... ... ") );
    }
}

start_checker();
