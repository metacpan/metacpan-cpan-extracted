use strict;
use warnings;

package C600;
{
    $C600::VERSION = '0.02';
}
use Encode;
use REST::Client;
use JSON;
use DBI;
use DateTime;
use DateTime::Format::Natural;
use DateTime::Format::Oracle;
use Data::Dumper;
use File::Spec;
use YAML qw/DumpFile LoadFile/;
use List::AllUtils qw( :all );
use File::ShareDir qw/:ALL/;

# ABSTRACT:  Wrap of C600
$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI';
my $DB_TYPE = 'C600';
my $dir   = dist_dir('Win32'); 
my $file  = "ID.yml";
my $path  = File::Spec->catfile($dir,$file);    

sub new {
    my $class = shift;
	my $self;
	if (-f $path){
		$self = LoadFile($path);
	}
	else{
		warn "can't open $path !!";
	}

    my $init_headers = {
        Accept         => 'application/json',
        'Content-type' => 'application/json',
    };
	my $user_name = $_[1] || "admin";
	my $password  = $_[2] || "Landisgyr_01";
    my $init_body = '{"username":"' . $user_name . '","password":"' . $password . '"}';
    my $host      = $_[0] || 'http://localhost';
    my $client    = REST::Client->new();
    $client->setHost($host);
    $client->POST( '/api/login', $init_body, $init_headers );
    die "error!!" . $client->responseCode . $client->responseContent()
      if $client->responseCode != 200;
    my $response      = from_json( $client->responseContent() );
    my $access_header = {
        'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8',
        Authorization  => 'Bearer ' . $response->{'access_token'},
    };
     $self->{'client'} = $client;
     $self->{'access_header'} = $access_header;
     return bless $self, $class;
}

sub get_single_value {
    my $self = shift;
    my ( $meter, $var, $dt ) = @_;
	my $deviceID = $self->{$meter}[0];
	my $meterID = $self->{$meter}[1];
	my $varID = $self->{$var};
    
	my $dt_str = __date2str($dt);
    my $body = <<"EOF";
		{"devices":[{ "deviceId":  $deviceID,
		 "meters":[$meterID] }],
		 "vars":[$varID],
		 "t1":"$dt_str",
		 "t2":"$dt_str", 
		 "profileType":1,
		 "valueTypes":["2"] }
EOF
	my $values_ref = $self-> __get_values($body);
    my $value = $values_ref->{'meterValues'}[0]{$meterID . "-" . $varID . "-2"};
    return $value ? $value : 'undef';
}

sub get_accu_value {
    my $self = shift;
    my ( $meter, $var, $dt_from, $dt_to ) = @_;
	my $deviceID = $self->{$meter}[0];
	my $meterID = $self->{$meter}[1];
	my $varID = $self->{$var};
    
	my $dt_from_str =  __date2str($dt_from);
	my $dt_to_str =  __date2str($dt_to);
    my $body = <<"EOF";
		{"devices":[{ "deviceId":  $deviceID,
		 "meters":[$meterID] }],
		 "vars":[$varID],
		 "t1":"$dt_from_str",
		 "t2":"$dt_to_str", 
		 "profileType":1,
		 "valueTypes":["3"],
		 "pageSize": 10000}
EOF
	my $values_ref = $self-> __get_values($body);
    my $sum_value = 0;
$sum_value +=$_->{$meterID. "-" . $varID . "-3"}  for @{ $values_ref->{'meterValues'}}; 
#   warn $_->{$meterID. "-" . $varID . "-3"}  for @{ $values_ref->{'meterValues'}}; 
    return sprintf("%.4f", $sum_value);          

}
sub get_range_value { 1 }
sub get_event        { 1 }
sub get_audit_record{
my $self = shift;
    my ( $dt_from, $dt_to ) = @_;
	$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
	my $dt_from_str =  __date2str($dt_from);
	my $dt_to_str =  __date2str($dt_to);
    my $body = <<"EOF";
		{
		 "t1":"$dt_from_str",
		 "t2":"$dt_to_str", 
		 "targets": ["dataView", "manualAcquisition"],
		 "pageSize": 10000}
EOF
	my $logs_ref = $self-> __get_operation_log($body);
	warn Dumper $logs_ref;
	warn Dumper $self->__get_diff($logs_ref->{'rows'}[0]{'id'});
1;

}
=pod  audit body
{
"from": 1,
"t1": "2020-04-25 09:15:38", // 记录开始时间
"t2": "2021-04-23 09:15:38", // 记录结束时间
"targets": ["dataView", "manualAcquisition"] // 操作类别
}
=cut
sub __get_operation_log {
    my $self = shift;
	my $body          = shift;
	$self->{'access_header'}{'Content-Type'} = 'application/json;charset=UTF-8';
	$self->{client}->POST('api/log/action/getOperationLog', $body, $self->{access_header});
    warn "get operationlog error!!" . $self->{client}->responseCode
      if $self->{client}->responseCode != 200;
    my $json = JSON->new->utf8;
    return $json->decode( $self->{client}->responseContent() );
}
sub __get_diff{
my $self = shift;
my $logID = shift;
    $self->{client}->GET( '/api/log/action/content?id=' . $logID, $self->{access_header} );
    warn "get vars error!!" . $self->{client}->responseCode
      if $self->{client}->responseCode != 200;

    my $json = JSON->new->utf8;
    return $json->decode( $self->{client}->responseContent() );


}
=pod get value body
here is get value body:
{
"devices": [{ "deviceId": 5866, "meters": [5871] }], // 可同时请求多个终端的多个表
数据
"vars": [2680, 2682, 2681, 2683], // 测量点过滤，如 +A +R -A
-R
"t1": "2021-04-20 13:24", // 开始时间
"t2": "2021-04-21 13:24", // 结束时间
"profileType": 1, // 负荷曲线数据
"valueTypes": ["2", "3", "4"], // 1 - 原始值，2 - 表底值，3
- 报表值，4 - 状态
"from": 101 // 数据条数偏移
}
=cut

sub __get_values {
	my $self = shift;
	my $body          = shift;
	$self->{'access_header'}{'Content-Type'} = 'application/json;charset=UTF-8';
	$self->{client}->POST('/api/dataView/action/getMeterValues', $body, $self->{access_header});
    warn "get vars error!!" . $self->{client}->responseCode
      if $self->{client}->responseCode != 200;

    my $json = JSON->new->utf8;
    return $json->decode( $self->{client}->responseContent() );

}
sub __get_vars {
    my $self = shift;
    $self->{client}->GET( '/api/variable', $self->{access_header} );
    warn "get vars error!!" . $self->{client}->responseCode
      if $self->{client}->responseCode != 200;

    my $json = JSON->new->utf8;
    return $json->decode( $self->{client}->responseContent() );
}

sub __get_meters {

    my $self = shift;
    $self->{client}->GET( '/api/meter', $self->{access_header} );
    die "get meters error!!" . $self->{client}->responseCode
      if $self->{client}->responseCode != 200;

    my $json = JSON->new->utf8;
    return $json->decode( $self->{client}->responseContent() );

}

sub __get_devices {

    my $self = shift;
    $self->{client}->GET( '/api/device', $self->{access_header} );
    die "get devices error!!" . $self->{client}->responseCode
      if $self->{client}->responseCode != 200;

    my $json = JSON->new->utf8;
    return $json->decode( $self->{client}->responseContent() );

}

sub __store_vmmid {
	 my %vmmid = ();
	 my $self       = shift;
     my $vars_ref   = $self->__get_vars();
	for ( my $i = 0 ; $i <= $#{ $vars_ref->{rows} } ; $i++ ) {
        utf8::encode( $vars_ref->{rows}[$i]{'name'} );
        $vmmid{$vars_ref->{rows}[$i]{'displayName'}} = $vars_ref->{rows}[$i]{'id'}
    }
     my $meters_ref   = $self->__get_meters();
for ( my $i = 0 ; $i <= $#{ $meters_ref->{rows} } ; $i++ ) {
     utf8::encode( $meters_ref->{rows}[$i]{'name'} );
        $vmmid{$meters_ref->{rows}[$i]{'name'}} = [$meters_ref->{rows}[$i]{'deviceId'}, $meters_ref->{rows}[$i]{'id'}];
    }
DumpFile($path, \%vmmid) or warn "can't write YAML";
return 0;

}

sub __list_vars {
    my $self       = shift;
    my $vars_ref   = $self->__get_vars();
    my @vars_array = ();
    for ( my $i = 0 ; $i <= $#{ $vars_ref->{rows} } ; $i++ ) {
        utf8::encode( $vars_ref->{rows}[$i]{'name'} );
        push @vars_array, $vars_ref->{rows}[$i]{'name'};
    }
    return @vars_array;
}

sub __list_meters {

    my $self       = shift;
    my $meters_ref = $self->__get_meters();

    my @meters_array = ();
    for ( my $i = 0 ; $i <= $#{ $meters_ref->{rows} } ; $i++ ) {
        utf8::encode( $meters_ref->{rows}[$i]{'name'} );
        push @meters_array, $meters_ref->{rows}[$i]{'name'};
    }
    return @meters_array;
}

sub __list_devices {
    my $self          = shift;
	    my $device_ref    = $self->__get_meters();
    my @devices_array = ();
    for ( my $i = 0 ; $i <= $#{ $device_ref->{rows} } ; $i++ ) {
        utf8::encode( $device_ref->{rows}[$i]{'name'} );
        push @devices_array, $device_ref->{rows}[$i]{'name'};
    }
    return @devices_array;
}

sub __date2str { DateTime::Format::Oracle->format_datetime(shift) }
sub __str2date { DateTime::Format::Oracle->parse_datetime(shift) }

1;

__END__

=pod

=head1 NAME

C600 - Wrap of C600

=head1 VERSION

version 0.02

=head1 AUTHOR

xiaoyafeng <xyf.xiao@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by xiaoyafeng.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
