package C3000;
use warnings;
use strict;
use Readonly;
use Win32::OLE;
use Win32::OLE::Variant;
use Carp;
use Encode;
use DateTime;
use DateTime::Format::Natural;
use DateTime::Format::Oracle;
use Data::Dumper;
use DateTime::Format::Natural;
use List::MoreUtils qw(none any);
use DBI;
Readonly::Scalar my $DEBUG => 0;
use constant cnNoFlags => 0;
use constant cnNoCheckpoint => -1;
# ABSTRACT: A perl wrap for C3000 API!!!

=head1 NAME

C3000 - A perl wrap for C3000 API
	This is a simple wrap of C3000 API. For more details, please refer to: 
	meter2cash CONVERGE Business Objects Component Interfaces User Guide 

=head1 VERSION

Version 1.02

=cut

our $VERSION = '1.02';

=head1 SYNOPSIS
 
   use C3000;
   my $hl = C3000->new();
   my $value = $hl->accu_LP('ADAS_VAL_RAW', '%', '+A', 'yesterday', 'today');
   my $value = $hl->get_single_LP('ADAS_VAL_RAW', '%', '+A', 'yesterday');



=head1 Methods 

    get_LP
    save_LP
    accu_value
    accu_tariff_value
    get_variable_name
    get_single_value
    get_range_value
    get_last_time
    get_period
    get_BV
    search_device
    search_ADAS_node
    search_group
    set_ADAS_node
    del_paths
    del_meters
    del_VMs
    create_path
    get_tariff
    get_tariff_id
    eval_AMD
    convert_VT_DATE
    CreateMasterAccount
    GetContainerID
    GetDataSegmentID
    GetTemplateID
    exec_jobs
    search_AE
    search_CT
    search_AETempl
    search_CTTempl
    search_meter_by_proxyattr
    search_meter_by_AMD


=cut

my $Empty;
$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI';
sub new {
    my $this              = shift;
	
    #init start
    my $dbh = DBI->connect("dbi:Oracle:AthenaDB", 'system', 'manager', ) or croak $DBI::errstr;
    my $container_manager = Win32::OLE->new('Athena.CT.ContainerManager.1');
    my $active_element_manager =
      Win32::OLE->new('Athena.CT.ActiveElementManager.1');
    my $active_element_template_manager =
      Win32::OLE->new('Athena.CT.ActiveElementTemplateManager.1');
    my $security_token = Win32::OLE->new('AthenaSecurity.UserSessions.1');
    $security_token->ConvergeLogin( 'landisgyr', 'c3000sys', 0, 666 );
    my $adas_instance_manager =
      Win32::OLE->new('Athena.AS.ADASInstanceManager.1')
      or croak;
    my $adas_template_manager =
      Win32::OLE->new('Athena.AS.AdasTemplateManager.1')
      or croak;
    my $container_template_manager =
      Win32::OLE->new('Athena.CT.ContainerTemplateManager.1')
      or croak;
    my $data_segment_helper = Win32::OLE->new('AthenaSecurity.DataSegment.1')
      or croak;
    my $meter_data_interface =
      Win32::OLE->new('DeviceAndMeterdata.ADASDeviceAndMeterdata.1');
    my $LPD =
      Win32::OLE->new('Converge.LoadProfileData.1');
	my $AMD =
	  Win32::OLE->new('Athena.CT.AMD_Utils');
	my $tariff_manager =
	  Win32::OLE->new('Athena.CT.TariffRateManager');
      #init end
    $dbh->do("alter session set nls_date_format = \'YYYY-MM-DD HH24:MI\'"); 

    my $self = {
	    dbh			    			 => $dbh,
        MeterDataInterface           => $meter_data_interface,
        ContainerManager             => $container_manager,
        ContainerTemplateManager     => $container_template_manager,
        ActiveElementManager         => $active_element_manager,
        ActiveElementTemplateManager => $active_element_template_manager,
        UserSessions                 => $security_token,
        ADASInstanceManager          => $adas_instance_manager,
        ADASTemplateManager          => $adas_template_manager,
        DataSegment                  => $data_segment_helper,
		LPD                          => $LPD,
		AMD							 => $AMD,
		TariffManager                => $tariff_manager,
    };
    return bless $self, $this;

}

=head2 get_LP


	my $rs = get_LP(....);
	while(!$rs->EOF){ 
		...
	$rs->MoveNext();
	}


return a recordset of LoadProfile
low function, just ignore it.



=cut

sub get_LP {
    my $self = shift;
    my ( $return_fields, $criteria ) = @_;
    my $rs =
      $self->{'MeterDataInterface'}->GetLoadProfile( $return_fields, $criteria, 0 );
      do{print Win32::OLE->LastError(); croak;}if(Win32::OLE->LastError());
    return $rs;
}
=head2 save_LP



=cut



sub save_LP{

	my $self = shift;
    my ($device_id, $var_id, $rs, $flag) = @_;
    
	$self->{'MeterDataInterface'}->Save_LP($device_id, $var_id, $rs, $flag);
	   do{print Win32::OLE->LastError(); die;}if(Win32::OLE->LastError());
   

}


=head2 accu_LP

		return a accumulation value of LoadProfile
	
		$hl->accu_LP('%', '+A', $dt_yesterday, $dt_today);
	
		$hl->accu_LP('%', '+A', $dt_yesterday, $dt_today);
		 


=cut

sub accu_value {
    my $self = shift;
    my ( $device, $var, $dt_from, $dt_to ) = @_;
      my $from_tag = 'ADAS_TIME_GMT';   #change when lp or bv;
    my $to_tag   = 'ADAS_TIME_GMT';
	my   $LP_return_fields = ['ADAS_VAL_NORM', 'ADAS_TIME_GMT'];
    $dt_to->set_time_zone('UTC');
    $dt_from->set_time_zone('UTC');
    my $date_from            = $self->convert_VT_DATE($dt_from);
    my $date_to              = $self->convert_VT_DATE($dt_to);
    my $device_return_fields = [
        'ADAS_DEVICE',      'ADAS_VARIABLE',
         'ADAS_DEVICE_NAME', 'ADAS_VARIABLE_NAME', 'ADAS_VARIABLE_TYPE',
    ];
    my %LP_values;    #return variable;
    my $LP_key;
	my $value = 0;
    if ( ref $device ne ref [] ) {    # means device name

        my $device_criteria =
          [ [ 'ADAS_DEVICE_NAME', $device ], [ 'ADAS_VARIABLE_NAME', $var ] ];
        my $rs_device =
          $self->search_device( $device_return_fields, $device_criteria );             

        return 0 if $rs_device->RecordCount == 0;
        while ( !$rs_device->EOF ) {
            my $device_id   = $rs_device->Fields('ADAS_DEVICE')->{Value};
            my $var_id      = $rs_device->Fields('ADAS_VARIABLE')->{Value};
			my $handle_name;
			if($rs_device->Fields('ADAS_VARIABLE_TYPE')->{Value} eq 'PROFILE'){
				$handle_name = 'get_LP';
			}
			else{
				$handle_name = 'get_BV';
				$from_tag = 'ADAS_RESET_TIME';
				$to_tag   = 'ADAS_RESET_TIME';
			}
            my $LP_criteria = [
                [ 'ADAS_DEVICE',   $device_id, '=' ],
                [ 'ADAS_VARIABLE', $var_id, '=' ],
                [ $from_tag,       $date_from, '>' ],
                [ $to_tag,         $date_to,   '<=' ]
            ];
            my $rs;
		   	eval '$rs = $self->' . $handle_name . '( $LP_return_fields, $LP_criteria )';
 while ( !$rs->EOF ) {
            $value += $rs->Fields( $LP_return_fields->[0] )->{Value};

            carp $rs->Fields( $LP_return_fields->[1] )->{Value}
              . "meter value is"
              . $value
              if $DEBUG == 1;
            $rs->MoveNext();
        }
            $rs_device->MoveNext();
        }
    }
    else {
		return 0 unless (@{$device});
        for my $dev_ID ( @{$device} ) {

            my $device_criteria =
              [ [ 'ADAS_DEVICE', $dev_ID ], [ 'ADAS_VARIABLE_NAME', $var ] ];
            my $rs_device =
              $self->search_device( $device_return_fields, $device_criteria );

            next if $rs_device->RecordCount == 0;
            while ( !$rs_device->EOF ) {
                my $device_id   = $rs_device->Fields('ADAS_DEVICE')->{Value};
                my $var_id      = $rs_device->Fields('ADAS_VARIABLE')->{Value};
              	my $handle_name;
			if($rs_device->Fields('ADAS_VARIABLE_TYPE')->{Value} eq 'PROFILE'){
				$handle_name = 'get_LP';
			}
			else{
				$handle_name = 'get_BV';
				$from_tag = 'ADAS_RESET_TIME';
				$to_tag   = 'ADAS_RESET_TIME';
			}
            my $LP_criteria = [
                [ 'ADAS_DEVICE',   $device_id, '=' ],
                [ 'ADAS_VARIABLE', $var_id, '=' ],
                [ $from_tag,       $date_from, '>' ],
                [ $to_tag,         $date_to,   '<=' ]
            ];
            my $rs;
		   	eval '$rs = $self->' . $handle_name . '( $LP_return_fields, $LP_criteria )';
                    while ( !$rs->EOF ) {
            			$value += $rs->Fields( $LP_return_fields->[0] )->{Value};

            			carp $rs->Fields( $LP_return_fields->[1] )->{Value}
              					. "meter value is"
              					. $value
              					if $DEBUG == 1;
            			$rs->MoveNext();
        			}
                $rs_device->MoveNext();
            }
        }

    }
    return $value;
}
    

sub accu_tariff_value {             
    my $self = shift;
    my ( $device, $var_str, $dt_from, $dt_to ) = @_;
	my ($var, $AE_ID, $tariff_name) = split(/~/, $var_str);
    my $tariff_ID = $self->get_tariff_id($tariff_name);	
      my $from_tag = 'ADAS_TIME_GMT';   #change when lp or bv;
    my $to_tag   = 'ADAS_TIME_GMT';
	my   $LP_return_fields = ['ADAS_VAL_NORM', 'ADAS_TIME_GMT'];
    $dt_to->set_time_zone('UTC');
    $dt_from->set_time_zone('UTC');
    my $date_from            = $self->convert_VT_DATE($dt_from);
    my $date_to              = $self->convert_VT_DATE($dt_to);
    my $device_return_fields = [
        'ADAS_DEVICE',      'ADAS_VARIABLE',
         'ADAS_DEVICE_NAME', 'ADAS_VARIABLE_NAME', 'ADAS_VARIABLE_TYPE',
    ];
    my %LP_values;    #return variable;
    my $LP_key;
	my $value = 0;
    if ( ref $device ne ref [] ) {    # means device name

        my $device_criteria =
          [ [ 'ADAS_DEVICE_NAME', $device ], [ 'ADAS_VARIABLE_NAME', $var ] ];
        my $rs_device =
          $self->search_device( $device_return_fields, $device_criteria );             

        return 0 if $rs_device->RecordCount == 0;
        while ( !$rs_device->EOF ) {
            my $device_id   = $rs_device->Fields('ADAS_DEVICE')->{Value};
            my $var_id      = $rs_device->Fields('ADAS_VARIABLE')->{Value};
			my $period      = $self->get_period($device_id, $var_id);
			my $tariff_list = $self->get_tariff($AE_ID, $date_from, $date_to, $period);
			my $i = 0;
			my $handle_name;
			if($rs_device->Fields('ADAS_VARIABLE_TYPE')->{Value} eq 'PROFILE'){
				$handle_name = 'get_LP';
			}
			else{
				$handle_name = 'get_BV';
				$from_tag = 'ADAS_RESET_TIME';
				$to_tag   = 'ADAS_RESET_TIME';
			}
            my $LP_criteria = [
                [ 'ADAS_DEVICE',   $device_id, '=' ],
                [ 'ADAS_VARIABLE', $var_id, '=' ],
                [ $from_tag,       $date_from, '>' ],
                [ $to_tag,         $date_to,   '<=' ]
            ];
            my $rs;
		   	eval '$rs = $self->' . $handle_name . '( $LP_return_fields, $LP_criteria )';
 while ( !$rs->EOF ) {
            $value += $rs->Fields( $LP_return_fields->[0] )->{Value} if $tariff_list->[$i][0] eq $tariff_ID;

            carp $rs->Fields( $LP_return_fields->[1] )->{Value}
              . "meter value is"
              . $value
              if $DEBUG == 1;
            $rs->MoveNext();
			$i++;
        }
            $rs_device->MoveNext();
        }
    }
    else {
		return 0 unless (@{$device});
        for my $dev_ID ( @{$device} ) {

            my $device_criteria =
              [ [ 'ADAS_DEVICE', $dev_ID ], [ 'ADAS_VARIABLE_NAME', $var ] ];
            my $rs_device =
              $self->search_device( $device_return_fields, $device_criteria );

            next if $rs_device->RecordCount == 0;
            while ( !$rs_device->EOF ) {
                my $device_id   = $rs_device->Fields('ADAS_DEVICE')->{Value};
                my $var_id      = $rs_device->Fields('ADAS_VARIABLE')->{Value};
				my $period      = $self->get_period($device_id, $var_id);
				my $tariff_list = $self->get_tariff($AE_ID, $date_from, $date_to, $period);
				my $i = 0;
              	my $handle_name;
			if($rs_device->Fields('ADAS_VARIABLE_TYPE')->{Value} eq 'PROFILE'){
				$handle_name = 'get_LP';
			}
			else{
				$handle_name = 'get_BV';
				$from_tag = 'ADAS_RESET_TIME';
				$to_tag   = 'ADAS_RESET_TIME';
			}
            my $LP_criteria = [
                [ 'ADAS_DEVICE',   $device_id, '=' ],
                [ 'ADAS_VARIABLE', $var_id, '=' ],
                [ $from_tag,       $date_from, '>' ],
                [ $to_tag,         $date_to,   '<=' ]
            ];
            my $rs;
		   	eval '$rs = $self->' . $handle_name . '( $LP_return_fields, $LP_criteria )';
                    while ( !$rs->EOF ) {
            			$value += $rs->Fields( $LP_return_fields->[0] )->{Value} if $tariff_list->[$i][0] eq $tariff_ID;

            			carp $rs->Fields( $LP_return_fields->[1] )->{Value}
              					. "meter value is"
              					. $value
              					if $DEBUG == 1;
            			$rs->MoveNext();
						$i++;
        			}
                $rs_device->MoveNext();
            }
        }

    }
    return $value;
}

sub get_variable_name{
	my $self = shift;
    my ( $device, $var ) = @_;
    my $device_return_fields = [
        'ADAS_DEVICE',      'ADAS_VARIABLE',
        'ADAS_DEVICE_NAME', 'ADAS_VARIABLE_NAME', 'ADAS_VARIABLE_TYPE',
    ];
    my @variables_name;    #return variable;

    if ( ref $device ne ref [] ) {    # means device name

        my $device_criteria =
          [ [ 'ADAS_DEVICE_NAME', $device ], [ 'ADAS_VARIABLE_NAME', $var ] ];
        my $rs_device =
          $self->search_device( $device_return_fields, $device_criteria )
          ;                           #record set of device;
        return 0 if $rs_device->RecordCount == 0;
        while ( !$rs_device->EOF ) {
            my $device_id   = $rs_device->Fields('ADAS_DEVICE')->{Value};
            my $var_id      = $rs_device->Fields('ADAS_VARIABLE')->{Value};
	    
               push @variables_name, 
                    $rs_device->Fields('ADAS_DEVICE_NAME')->{Value} . "_"
                  . $rs_device->Fields('ADAS_VARIABLE_NAME')->{Value};
            $rs_device->MoveNext();
        }
    }
    else {
		return 0 unless (@{$device});
        for my $dev_ID ( @{$device} ) {
            my $device_criteria =
              [ [ 'ADAS_DEVICE', $dev_ID ], [ 'ADAS_VARIABLE_NAME', $var ] ];
            my $rs_device =
              $self->search_device( $device_return_fields, $device_criteria );

            next if $rs_device->RecordCount == 0;
            while ( !$rs_device->EOF ) {
                push @variables_name,
                        $rs_device->Fields('ADAS_DEVICE_NAME')->{Value} . "_"
                      . $rs_device->Fields('ADAS_VARIABLE_NAME')->{Value};
                $rs_device->MoveNext();
            }
        }

    }
	return \@variables_name;

}




sub get_single_value {
    my $self = shift;
    my ( $LP_return_fields, $device, $var, $dt_obj ) = @_;
    my $from_tag = 'ADAS_TIME_GMT';   #change when lp or bv;
    my $to_tag   = 'ADAS_TIME_GMT';
    if ( ref($LP_return_fields) ne ref [] ) {
        $LP_return_fields = [$LP_return_fields];
    }
    my $dt_from = $dt_obj->clone();
    $dt_from->subtract( minutes => 1 );
    $dt_obj->set_time_zone('UTC');
    $dt_from->set_time_zone('UTC');
    my $date_from            = $self->convert_VT_DATE($dt_from);
    my $date_to              = $self->convert_VT_DATE($dt_obj);
    my $device_return_fields = [
        'ADAS_DEVICE',      'ADAS_VARIABLE',
        'ADAS_DEVICE_NAME', 'ADAS_VARIABLE_NAME', 'ADAS_VARIABLE_TYPE',
    ];
    my @values;    #return variable;

    if ( ref $device ne ref [] ) {    # means device name

        my $device_criteria =
          [ [ 'ADAS_DEVICE_NAME', $device ], [ 'ADAS_VARIABLE_NAME', $var ] ];
        my $rs_device =
          $self->search_device( $device_return_fields, $device_criteria )
          ;                           #record set of device;
        return 0 if $rs_device->RecordCount == 0;
        while ( !$rs_device->EOF ) {
            my $device_id   = $rs_device->Fields('ADAS_DEVICE')->{Value};
            my $var_id      = $rs_device->Fields('ADAS_VARIABLE')->{Value};
	    
            	my $handle_name;
			if($rs_device->Fields('ADAS_VARIABLE_TYPE')->{Value} eq 'PROFILE'){
				$handle_name = 'get_LP';
			}
			else{
				$handle_name = 'get_BV';
				$from_tag = 'ADAS_RESET_TIME';
				$to_tag   = 'ADAS_RESET_TIME';
			}
            my $LP_criteria = [
                [ 'ADAS_DEVICE',   $device_id, '=' ],
                [ 'ADAS_VARIABLE', $var_id, '=' ],
                [ $from_tag,       $date_from, '>' ],
                [ $to_tag,         $date_to,   '<=' ]
            ];
            my $rs;
		   	eval '$rs = $self->' . $handle_name . '( $LP_return_fields, $LP_criteria )';
            while ( !$rs->EOF ) {
					push @values, join '__', map { $rs->Fields($_)->{Value} } @{$LP_return_fields};
                $rs->MoveNext();
            }
            $rs_device->MoveNext();
    	}
	}
    else {
		
		return 0 unless (@{$device});
        for my $dev_ID ( @{$device} ) {

            my $device_criteria =
              [ [ 'ADAS_DEVICE', $dev_ID ], [ 'ADAS_VARIABLE_NAME', $var ] ];
            my $rs_device =
              $self->search_device( $device_return_fields, $device_criteria );

            next if $rs_device->RecordCount == 0;
            while ( !$rs_device->EOF ) {
                my $device_id   = $rs_device->Fields('ADAS_DEVICE')->{Value};
                my $var_id      = $rs_device->Fields('ADAS_VARIABLE')->{Value};
             	my $handle_name;
			if($rs_device->Fields('ADAS_VARIABLE_TYPE')->{Value} eq 'PROFILE'){
				$handle_name = 'get_LP';
			}
			else{
				$handle_name = 'get_BV';
				$from_tag = 'ADAS_RESET_TIME';
				$to_tag   = 'ADAS_RESET_TIME';
			}
            my $LP_criteria = [
                [ 'ADAS_DEVICE',   $device_id, '=' ],
                [ 'ADAS_VARIABLE', $var_id, '=' ],
                [ $from_tag,       $date_from, '>' ],
                [ $to_tag,         $date_to,   '<=' ]
            ];
            my $rs;
		   	eval '$rs = $self->' . $handle_name . '( $LP_return_fields, $LP_criteria )';
                while ( !$rs->EOF ) {
                        push @values, join '__', map { $rs->Fields($_)->{Value} } @{$LP_return_fields};
                    	$rs->MoveNext();
                }
                $rs_device->MoveNext();
            }
        }

    }
    return @values	== 1 ? $values[0] : \@values;
}

sub get_range_value {
    my $self = shift;
    my ( $LP_return_fields, $device, $var, $dt_from, $dt_to ) = @_;
  my $from_tag = 'ADAS_TIME_GMT';   #change when lp or bv;
    my $to_tag   = 'ADAS_TIME_GMT';
    if ( ref($LP_return_fields) ne ref [] ) {
        $LP_return_fields = [$LP_return_fields];
    }
    $dt_to->set_time_zone('UTC');
    $dt_from->set_time_zone('UTC');
    my $date_from            = $self->convert_VT_DATE($dt_from);
    my $date_to              = $self->convert_VT_DATE($dt_to);
    my $device_return_fields = [
        'ADAS_DEVICE',      'ADAS_VARIABLE',
          'ADAS_DEVICE_NAME', 'ADAS_VARIABLE_NAME', 'ADAS_VARIABLE_TYPE',
    ];
    my %LP_values;    #return variable;
    my $LP_key;

    if ( ref $device ne ref [] ) {    # means device name

        my $device_criteria =
          [ [ 'ADAS_DEVICE_NAME', $device ], [ 'ADAS_VARIABLE_NAME', $var ] ];
        my $rs_device =
          $self->search_device( $device_return_fields, $device_criteria )
          ;                           #record set of device;

        return 0 if $rs_device->RecordCount == 0;
        while ( !$rs_device->EOF ) {
            my $device_id   = $rs_device->Fields('ADAS_DEVICE')->{Value};
            my $var_id      = $rs_device->Fields('ADAS_VARIABLE')->{Value};
            	my $handle_name;
			if($rs_device->Fields('ADAS_VARIABLE_TYPE')->{Value} eq 'PROFILE'){
				$handle_name = 'get_LP';
			}
			else{
				$handle_name = 'get_BV';
				$from_tag = 'ADAS_RESET_TIME';
				$to_tag   = 'ADAS_RESET_TIME';
			}
            my $LP_criteria = [
                [ 'ADAS_DEVICE',   $device_id, '=' ],
                [ 'ADAS_VARIABLE', $var_id, '=' ],
                [ $from_tag,       $date_from, '>' ],
                [ $to_tag,         $date_to,   '<=' ]
            ];
            my $rs;
		   	eval '$rs = $self->' . $handle_name . '( $LP_return_fields, $LP_criteria )';
                $LP_key =
                    $rs_device->Fields('ADAS_DEVICE_NAME')->{Value} . "_"
                  . $rs_device->Fields('ADAS_VARIABLE_NAME')->{Value};
                    $LP_values{$LP_key} = $rs;
            
            $rs_device->MoveNext();
        }
    }
    else {
        for my $dev_ID ( @{$device} ) {

            my $device_criteria =
              [ [ 'ADAS_DEVICE', $dev_ID ], [ 'ADAS_VARIABLE_NAME', $var ] ];
            my $rs_device =
              $self->search_device( $device_return_fields, $device_criteria );

            next if $rs_device->RecordCount == 0;
            while ( !$rs_device->EOF ) {
                my $device_id   = $rs_device->Fields('ADAS_DEVICE')->{Value};
                my $var_id      = $rs_device->Fields('ADAS_VARIABLE')->{Value};
               	my $handle_name;
			if($rs_device->Fields('ADAS_VARIABLE')->{Value} eq 'PROFILE'){
				$handle_name = 'get_LP';
			}
			else{
				$handle_name = 'get_BV';
			}
            my $LP_criteria = [
                [ 'ADAS_DEVICE',   $device_id,'=' ],
                [ 'ADAS_VARIABLE', $var_id, '=' ],
                [ 'ADAS_TIME_GMT', $date_from, '>' ],
                [ 'ADAS_TIME_GMT', $date_to,   '<=' ]
            ];
            my $rs;
		   	eval '$rs = $self->' . $handle_name . '( $LP_return_fields, $LP_criteria )';
                    $LP_key =
                        $rs_device->Fields('ADAS_DEVICE_NAME')->{Value} . "_"
                      . $rs_device->Fields('ADAS_VARIABLE_NAME')->{Value};
                        $LP_values{$LP_key} = $rs;
                $rs_device->MoveNext();
            }
        }

    }
    return \%LP_values;
}

sub get_last_time {
   my $self = shift;
   my ($device_ID, $var_ID) = @_;
   my ($last_date) = $self->{'dbh'}->selectrow_array("select PI_NEWEST_VALUE from adas.pop_info where adas_id = ? and var_code = ?", {}, ($device_ID, $var_ID));
   warn "WARNING!!!: last time doesn't exist!!" if(!defined($last_date));
   $last_date = '1970-01-01 00:00' if(!defined($last_date));
  my $dt = DateTime::Format::Oracle->parse_datetime($last_date);
  return $dt;

}

sub get_period {
   my $self = shift;
   my ($device_ID, $var_ID) = @_;
   my ($period) = $self->{'dbh'}->selectrow_array("select PI_PERIOD from adas.pop_info where adas_id = ? and var_code = ?", {}, ($device_ID, $var_ID));
   warn "WARNING!!!: period doesn't exist!!" if(!defined($period));
   $period = 15 if(!defined($period));
  return $period;

}

sub get_BV {

     my $self = shift;
    my ( $return_fields, $criteria) = @_;
    my $order = [ ["ADAS_TIME_GMT", "A" ] ];
    #converge BIlling API is broken, use database instead.
    my $rs = $self->{'MeterDataInterface'}->GetBillingData( $return_fields, $criteria, $order, 0 );
     do{print Win32::OLE->LastError(); die;}if(Win32::OLE->LastError());
    return $rs;
}




=head2 search_device

		return a recordset of device info fitting criteria 
		low function, please refer test file for more details.



=cut

sub search_device {
    my $self = shift;
    my ( $return_fields, $criteria,$search_string ) = @_;
    my $rs =
      $self->{'MeterDataInterface'}
      ->FindVariable( $return_fields, $criteria, $Empty, 0 )
      or croak $self->{'MeterDataInterface'}->LastError();
  
    return $rs;
}

sub search_ADAS_node{
	my $self = shift;
	my ( $return_fields, $criteria ) = @_;
	my $st = $self->{'UserSessions'};
    my $rs =
      $self->{'ADASInstanceManager'}
      ->Search( $return_fields, $criteria, $Empty, cnNoFlags, cnNoCheckpoint, $st)
      or croak $self->{'ADASInstanceManager'}->LastError();

    return $rs;

}

sub search_group{
 my $grps_ref = $_[0]->{'dbh'}->selectcol_arrayref("select DEVGRP_NAME, DEVGRP_ID from adas.dev_grp where DEVGRP_NAME like ?", {Columns => [1,2]}, ($_[1]));
 my %groups = @{$grps_ref};
  return \%groups;
}

sub set_ADAS_node{
	my $self = shift;
	my ($NodeID, $CharID, $char_type, $new_value) = @_;
	my  $st = $self->{'UserSessions'};
	$self->{'dbh'}->do("update ADAS.AS_DEF_NODE_ATTR_VALUE SET $char_type =  ? where NODEID = ? and DEF_NODE_CHARACTERISTICID = ?", {AutoCommit => 1}, ($new_value, $NodeID, $CharID));
	$self->{'ADASInstanceManager'}->SyncronizeADASNode($NodeID,$st); 

}
sub del_paths{
	my $self = shift;
	my $path_name = shift;
	my $node_return_fields = [ 'NodeID' ];
    my $criteria = [ [ 'PathName', $path_name ], ];
    my $rs = $self->search_ADAS_node($node_return_fields, $criteria); 
	my $st = $self->{'UserSessions'};
	 while ( !$rs->EOF ) {
			my $NodeID = $rs->Fields('NodeID');
   			$self->{'ADASInstanceManager'}->Delete($NodeID, $st);
            $rs->MoveNext();
        }

}



sub del_meters{
	my $self = shift;
	my $meter_name = shift;
	my $node_return_fields = [ 'NodeID' ];
    my $criteria = [ [ 'DeviceName', $meter_name ], ];
    my $rs = $self->search_ADAS_node($node_return_fields, $criteria); 
	my $st = $self->{'UserSessions'};
	 while ( !$rs->EOF ) {
			my $NodeID = $rs->Fields('NodeID');
   			$self->{'ADASInstanceManager'}->Delete($NodeID, $st);
            $rs->MoveNext();
        }

}


sub del_VMs{
	my $self = shift;
	my $VM_name = shift;
	my $node_return_fields = [ 'NodeID' ];
    my $criteria = [ [ 'AdasDeviceName', $VM_name ], ];
    my $rs = $self->search_ADAS_node($node_return_fields, $criteria); 
	my $st = $self->{'UserSessions'};
	 while ( !$rs->EOF ) {
			my $NodeID = $rs->Fields('NodeID');
   			$self->{'ADASInstanceManager'}->Delete($NodeID, $st);
            $rs->MoveNext();
        }

}

sub create_path{
   my $self = shift;
   my ($templ_name, $path_name) = @_;
   


}
sub get_tariff{
	my ($self, $aeID, $dt_from, $dt_to, $period) = @_;
	my $AMD_string = 'active_element->Produced("tariff_profile",#'. DateTime::Format::Oracle->format_datetime($dt_from) .'#,#'. DateTime::Format::Oracle->format_datetime($dt_to) . '#,'. $period .')';
	return $self->eval_AMD($aeID, $AMD_string);

}
sub get_tariff_id{
   my ($self, $tariff_name) = @_;
   my $st = $self->{'UserSessions'};
   my $TariffRateID = $self->{'TariffManager'}->GetTariffRateID($tariff_name, $st );
	return $TariffRateID;
}

sub eval_AMD{

   my ($self ,$aeID, $AMD_string) = @_;
   my $st = $self->{'UserSessions'};
   my $result = $self->{'AMD'}->EvaluateTest($aeID, $AMD_string, $Empty, $st);
   return $result;

}
=head2  convert_VT_DATE 


C3000 utils, pass to a DateTime obj and return a VT_DATE variable.

=cut

sub convert_VT_DATE {
    my $self = shift;
    Readonly::Scalar my $EPOCH       => 25569;
    Readonly::Scalar my $SEC_PER_DAY => 86400;
    my $dt = shift;
    $dt->set_time_zone('UTC');
    return Variant( VT_DATE, $EPOCH + $dt->epoch / $SEC_PER_DAY );
}

      

sub CreateMasterAccount {
	my ($self, $pnParentContainerID, $pnTemplateID, $pnDataSegmentID, $paValues) = @_;

	my $nContainerID;
	my $rsInitValues;
	my @arrayRf;
	for my $nIndex (0 .. $#$paValues){
		$arrayRf[ $nIndex ] = $paValues->[ $nIndex ][0];
	}
	$rsInitValues = $self->{ 'ContainerTemplateManager' }->GetValues($pnTemplateID, \@arrayRf, cnNoFlags, cnNoCheckpoint, $self->{ 'UserSessions' });
	for my $nIndex (0 .. $#$paValues){
		$rsInitValues->Fields($paValues->[ $nIndex ][0])->{'Value'} = $paValues->[ $nIndex ][1];
		}
	$nContainerID = $self->{ 'ContainerManager' }->CreateContainer($pnTemplateID, $self->{ 'ContainerManager' }->GetTopNodeID( cnNoCheckpoint, $self->{ 'UserSessions' }), $rsInitValues, $self->{ 'UserSessions' });
        $self->{ 'ContainerManager' }->MoveContainer($nContainerID, $pnParentContainerID, $self->{ 'UserSessions' });
	$self->{ 'ContainerManager' }->setDataSegment($nContainerID, $pnDataSegmentID, $self->{ 'UserSessions' });
	return $nContainerID;
}

sub GetContainerID {
	my $self       = shift;
	my $paCriteria = shift;
	my $rs;
	$rs = $self->{ 'ContainerManager' }->Search(['ContainerID'], $paCriteria, $Empty, cnNoFlags, cnNoCheckpoint, $self->{ 'UserSessions' });
	return $rs->Fields('ContainerID')->{'Value'};
}

sub GetDataSegmentID {
	my $self	      = shift;
	my $psDataSegmentName = shift;
        my $rs;
	$rs = $self->{ 'DataSegment' }->GetDataSegmentInfo($self->{ 'UserSessions' }->GetInstallationID(), ['DataSegNb'], [['DataSegName', $psDataSegmentName]]);
	return $rs->Fields('DataSegNb')->{'Value'};

}

sub GetTemplateID {
	my $self           = shift;
	my $psTemplatename = shift;
	my ($arrayRf, $arrayCr);
	my $rsTemplate;
	$arrayRf = ['ContainerTemplateID'];
	$arrayCr = [['ContainerTemplateName', $psTemplatename]];
	$rsTemplate = $self->{ 'ContainerTemplateManager' }->Search($arrayRf, $arrayCr, $Empty, cnNoFlags, cnNoCheckpoint, $self->{ 'UserSessions' });
	return $rsTemplate->Fields('ContainerTemplateID')->{'Value'};


}

sub exec_jobs {
	my $self     = shift;
	my ($groupID, $group_name, $dt_from, $dt_to, $duration) = @_;
	my ($wotID) = $self->{'dbh'}->selectrow_array("SELECT ADAS.ADAS_SEQUENCE.NEXTVAL FROM DUAL");
     $self->{'dbh'}->do("insert into adas.wos_timdef(WOT_ID,WOT_NAME,WOT_CYCLE,WOT_START,WOT_DURATION,WOT_RETRY,WOT_TOHANDLE,WOT_HANDLING,WOT_FLAGS,WOT_SHOW) values($wotID,\'QUICKJOB Acquisition Group ($group_name)\',\'00:00:00.00.100Srr\',?,?, \'30:00:00.01.00\',0,0,\'YAYn\',\'S\'", {AutoCommit => 1}, ());
    my ($wojID) = $self->{'dbh'}->selectrow_array("SELECT ADAS.ADAS_SEQUENCE.NEXTVAL FROM DUAL");
	$self->{'dbh'}->do("INSERT INTO ADAS.WOS_JOBDEF (WOJ_ID,TYPE_OF_READING_ID,WOT_ID,WOK_ID,WOJ_INDIVPARAM,WOJ_NAME,WOJ_PRIORITY) VALUES($wojID,\'Remote\',$wotID,\'MTRCOM\',?,?,1)", {AutoCommit => 1}, ());
	my $param = "AutoS=N~AutoT=0~TFrom=\$s 15:59:01.000 SDT Greenwich Standard Time~TTill=\$s 16:01:01.000 SDT Greenwich Standard Time~PLSType=0~GroupID=\$groupId~ChkGrp=1~";
    my $job_name = "QUICKJOB Acquisition Group ($group_name)";

    $self->{'dbh'}->do("INSERT INTO ADAS.WOS_RELJOBACT(WOA_ID,WOJ_ID,WOR_ORDER) VALUES(2, ?, 0)", {AutoCommit => 1}, ($wojID));

}
sub search_AE{
	my $self = shift;
   my ($return_fields, $criteria) = @_;
   my $rs;
	$rs = $self->{ 'ActiveElementManager' }->Search($return_fields, $criteria, $Empty, cnNoFlags, cnNoCheckpoint, $self->{ 'UserSessions' });
	return $rs;	
}
sub search_CT{
   my $self = shift;
   my ($return_fields, $criteria) = @_;
   my $rs;
	$rs = $self->{ 'ContainerManager' }->Search($return_fields, $criteria, $Empty, cnNoFlags, cnNoCheckpoint, $self->{ 'UserSessions' });
	return $rs;
}
sub search_AETempl{
	my $self = shift;
   my ($return_fields, $criteria) = @_;
   my $rs;
	$rs = $self->{ 'ActiveElementTemplateManager' }->Search($return_fields, $criteria, $Empty, cnNoFlags, cnNoCheckpoint, $self->{ 'UserSessions' });
	return $rs;

}
sub search_CTTempl{
	my $self = shift;
   my ($return_fields, $criteria) = @_;
   my $rs;
	$rs = $self->{ 'ContainerTemplateManager' }->Search($return_fields, $criteria, $Empty, cnNoFlags, cnNoCheckpoint, $self->{ 'UserSessions' });
	return $rs;

}

=head2  search_meter_by_proxyattr 


return a ref of ADAS_ID

=cut
sub search_meter_by_proxyattr{
	my ($self, $criteria) = @_;
	return undef if (ref $criteria ne ref [] ) or !defined ($criteria->[0]);
    my $return_fields = ['ADAS_ID'];

	my $rs = $self->search_AE($return_fields, $criteria);
	my @IDs;
      while ( !$rs->EOF ) {
              push @IDs, $rs->Fields( $return_fields->[0] )->{Value};
            $rs->MoveNext();
        }


    return  \@IDs;
}

sub search_meter_by_AMD{
    my $self = shift;
    my $result_ref_ref = $self->eval_AMD(@_);
    my @AE_IDs = @{$$result_ref_ref[0]};
	my @IDs;
	for my $AE_ID (@AE_IDs){
		 push @IDs, @{$self->search_meter_by_proxyattr([['AEID', $AE_ID]])};
	 }
	 return \@IDs;
}


=head1 AUTHOR

Andy Xiao, C<< <xyf.gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-c3000 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=C3000>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 TODO 


=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=C3000>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/C3000>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/C3000>

=item * Search CPAN

L<http://search.cpan.org/dist/C3000/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andy Xiao.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of C3000
