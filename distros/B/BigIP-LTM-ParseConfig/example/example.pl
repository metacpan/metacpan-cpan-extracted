#!/usr/bin/env perl

use 5.012;

#use warnings;
#no warnings 'uninitialized';

use Data::Dumper;
use BigIP::LTM::ParseConfig;
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
            "\nperl $0 -d directory(目录) || -f f5_ltm_config(单个配置文件)\n"
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

# option handling initialization
if ($opt_V) {
    say "F5 DevCenter BIGIP LTM configuration Parser V2.020";
    exit(-1);
}

if ( $opt_h || not( $opt_d || $opt_f ) ) {
    usage();
}

my $dirname = $opt_d;

sub write_excel {
    my $ltm  = shift;
    my $time = strftime( "%Y%m%d", localtime() );

    my $bip            = BigIP::LTM::ParseConfig->new($ltm);
    my $virtual_server = $bip->virtuals_all();

    # Create a new Excel workbook
    my $workbook
        = Spreadsheet::WriteExcel->new(
        "bigip-ltm-reports_$ltm" . "_$time" . '.xls' );

    # Add a worksheet
    my $worksheet = $workbook->add_worksheet( $ltm . '_Virtual_Server' );

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
    $format_1->set_align('center');
    $format_1->set_valign('vcenter');

    my $format_2 = $workbook->add_format();
    $format_1->set_size(12);
    $format_2->set_align('center');
    $format_2->set_valign('vcenter');

    # set column and row width;
    $worksheet->set_column( 0, 13, 28, $format_2 );

    # Write a formatted and unformatted string, row and column notation.
    my $excel_array = [
        decode_utf8("VS名称"),           decode_utf8("IP协议"),
        decode_utf8("VS地址->端口"),   decode_utf8("POOL名称"),
        decode_utf8("POOL地址->端口"), decode_utf8("负载模式"),
        decode_utf8("SNAT"),               decode_utf8("SNAT->POOL"),
        decode_utf8("健康检查"),       decode_utf8("长链接"),
        decode_utf8("长链接-模式"),   decode_utf8("IRULE"),
        decode_utf8("PROFILES"),           decode_utf8("工单信息"),
    ];
    $worksheet->write_row( 0, 0, $excel_array, $format );

    my ( $result, $vs_attr, $vs_info, $vs_member );
    my $row = 0;
    for my $vs ( keys %{$virtual_server} ) {
        for my $attr ( keys %{ $virtual_server->{$vs} } ) {
            $result->{$vs}{"virtual_server"} = $vs;
            my $ret = $virtual_server->{$vs}{$attr};

            if ( $attr =~ /\Apool\z/ ) {
                $result->{$vs}{"pool"} = $ret;
            }
            elsif ( $attr =~ /destination/ ) {
                $result->{$vs}{"destination"} = $ret =~ s/\:/\-\>/r;
            }
            elsif ( $attr =~ /persist_mode/ ) {
                $result->{$vs}{"persist_mode"} = $ret;
            }
            elsif ( $attr =~ /ip-protocol/ ) {
                $result->{$vs}{"ip-protocol"} = $ret;
            }
            elsif ( $attr =~ /\Apersist\z/ ) {
                $result->{$vs}{"persist"}
                    = join( '', map {s@\/Common\/@@r} ( keys %{$ret} ) );
            }
            elsif ( $attr =~ /pool_details/ ) {
                if ( exists $ret->{"load-balancing-mode"}
                    && defined $ret->{"load-balancing-mode"} )
                {
                    $result->{$vs}{"load-balancing-mode"}
                        = $ret->{"load-balancing-mode"};
                }
                if ( exists $ret->{"monitor"} && defined $ret->{"monitor"} ) {
                    $result->{$vs}{"monitor"} = $ret->{monitor};
                }
                if ( exists $ret->{"members"} && defined $ret->{"members"} ) {
                    $result->{$vs}{"members"} = join( "\n",
                        ( map {s/\:/\-\>/r} ( keys %{ $ret->{members} } ) ) );
                }
            }
            elsif ( $attr =~ /profiles/ ) {
                $result->{$vs}{"profiles"}
                    = join( "\n", map {s@\/Common\/@@r} ( keys %{$ret} ) );
            }
            elsif ( $attr =~ /rules/ ) {
                $result->{$vs}{"rules"}
                    = join( "\n", map {s@\/Common\/@@r} ( keys %{$ret} ) );
            }
            elsif ( $attr =~ /service-down-immediate-action/ ) {
                $result->{$vs}{"service-down-immediate-action"} = $ret;
            }
            elsif ( $attr =~ /source-address-translation/ ) {
                if ( exists $ret->{"pool"} ) {
                    $result->{$vs}{"snat_pool"} = $ret->{pool};
                }
                if ( exists $ret->{"type"} ) {
                    $result->{$vs}{"snat_type"} = $ret->{type};
                }
            }
            elsif ( $attr =~ /description/ ) {
                $result->{$vs}{"description"} = $ret;
            }
        }

        $row++;

        #my $munge_host = $host =~ s/(.*)\.cfg/$1/r;

        $vs_attr = [
            $result->{$vs}{"virtual_server"} =~ s@\/Common\/@@r,
            $result->{$vs}{"ip-protocol"},
            $result->{$vs}{"destination"} =~ s@\/Common\/@@r,
            $result->{$vs}{"pool"}        =~ s@\/Common\/@@r,
            $result->{$vs}{"members"}     =~ s@\/Common\/@@gr,
            $result->{$vs}{"load-balancing-mode"} ||= "default",
            $result->{$vs}{"snat_type"},
            $result->{$vs}{"snat_pool"} ||= "default",
            $result->{$vs}{"monitor"} =~ s@\/Common\/@@r // "none",
            $result->{$vs}{"persist"} =~ s@\/Common\/@@r // "none",
            $result->{$vs}{"persist_mode"} // "none",
            $result->{$vs}{"rules"}        // "none",
            $result->{$vs}{"profiles"}     // "default",
            decode_utf8(
                $result->{$vs}{"description"}
                    // "存量配置未关联工单号",
            ),
            ,
        ];
        $worksheet->set_row( $row, 35.5 );
        $worksheet->write_row( $row, 0, $vs_attr, $format_1 );
    }
}

sub start_checker {
    if ($opt_f) {
        write_excel($opt_f);
        say encode(
            'cp936',
            decode_utf8(
                "BigIP LTM [$opt_f] 已分析完毕，自动生成的报表仅供参考;"
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
                    "BigIP LTM [$_] 已分析完毕，自动生成的报表仅供参考;"
                )
            );
        }
        say encode( 'cp936', decode_utf8("程序已处理完毕 ... ... ") );
    }
}

start_checker();
