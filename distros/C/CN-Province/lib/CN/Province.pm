package CN::Province;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(abbr2province province2abbr all_province all_abbr);

our $VERSION = '0.02';

my %abbr_province = ( 
    'AH' => '安徽',
    'LN' => '辽宁',
    'BJ' => '北京',
    'NM' => '内蒙古',
    'FJ' => '福建',
    'NX' => '宁夏',
    'GD' => '广东',
    'QH' => '青海',
    'GS' => '甘肃',
    'SC' => '四川',
    'GX' => '广西',
    'SD' => '山东',
    'GZ' => '贵州',
    'SH' => '上海',
    'HB' => '湖北',
    'SN' => '陕西',
    'HEB'=> '河北',
    'SX' => '山西',
    'HEN'=> '河南',
    'TJ' => '天津',
    'HI' => '海南',
    'TW' => '台湾',
    'HL' => '黑龙江',
    'XJ' => '新疆',
    'HN' => '湖南',
    'XZ' => '西藏',
    'JL' => '吉林',
    'YN' => '云南',
    'JS' => '江苏',
    'ZJ' => '浙江',
    'JX' => '江西',
);

my %province_abbr = map({$abbr_province{uc $_} => $_} keys %abbr_province);

sub abbr2province {
    my $self = shift;
    my $abbr = shift or die "must have the abbreviation of province argument";
    return $abbr_province{uc($abbr)};
} 

sub province2abbr {
    my $self = shift;
    my $state = shift or die "must have the name of province argument";
    return $province_abbr{$state};
} 

sub all_province {
    my $self = shift;
    sort keys %province_abbr;
}

sub all_abbr {
    my $self = shift;
    sort keys %abbr_province;
}

1;

__DATA__

=encoding utf8

=head1 NAME

CN::Provice - China Province names and abbreviations

=head1 SYNOPSIS

    use CN::Province;
    
    my $province = CN::Provice->abbr2province('JS');
    my $abbr     = CN::Provice->province2abbr('江苏');
    
    my @province = CN::Provice->all_province;
    my @abbr     = CN::Provice->all_abbr; 

=head1 DESCRIPTIONS

=head2 province2abbr

Returns the abbreviation for the given province name. Returns undefined if the name is unknown.

    my $abbr = CN::Province->province2abbr('江苏');

=head2 abbr2province

Returns the province name for the given abbreviation.

    my $province = CN::Province->abbr2province('JS');

=head2 all_province

Returns all province names.

    my @province = CN::Provice->all_province;

=head2 all_abbr

Returns all abbreviative names.

    my @abbr = CN::Provice->all_abbr;

=head1 AUTHOR

Wayne Zhou <cumtxhzyy@gmail.com>

=head1 COPYRIGHT

Copyright 2012 by Wayne Zhou.

=head1 LICENSE
