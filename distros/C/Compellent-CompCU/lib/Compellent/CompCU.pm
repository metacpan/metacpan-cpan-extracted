=begin lip

=cut

package Compellent::CompCU;

=head2 Includes

=cut

use 5.008009;
use strict;
use warnings;
use Lip::Pod;
use IPC::Cmd qw(can_run run run_forked);

use constant FIRST => 9;#first line of output (after the headers) for most commands is 9
use constant FIRST_SHOW => 10;#For 'show' commands the irst line of output is 10
use constant FOOTER_LENGTH => 3;#if the command is successful then it will have 3 lines at the end of the output

=head2 Exported Symbols

=cut

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw();
our $VERSION = '0.06';

=head2 Subroutines

All subroutines (except for C<modify_lines()>, C<check_success()>, and C<build_command()> which 
arenE<0x0027>t for public consumption anyway) take an array reference as an 
argument. See each subroutines documentation for details on return values.

=cut

=head3 new()

Constructor. Creates the object and sets some default attribute values.

=cut

sub new{
    my ($pkg,$attributes)=@_;

    my $self={};
    $self->{host}="";
    $self->{user}="";
    $self->{password}="";
    $self->{java_path}="java";#assumes is somewhere in $PATH
    $self->{java_args}="-client";
    $self->{compcu_path}="./CompCU.jar";#default to being in the cwd

    bless($self,$pkg);
    foreach my $field (keys %$self){
        if(exists $attributes->{$field}){
            $self->{$field}=$attributes->{$field};
        }
    }
    can_run("$self->{java_path}") or die 'java not found';
    $self->{command}="$self->{java_path} $self->{java_args} -jar $self->{compcu_path} -c \"COMMAND\" -host $self->{host} -user $self->{user} -password $self->{password}";
    return $self;
}

=head3 alert acknowledge

Sets the alert as having been acknowledged. Doing this indicates to Storage
Center that you are aware of the alert message.

=over 8 

Takes three required parameters and one optional parameters.

=item *

controller - An integer specifying the controller for the alert.

=item *

index - An integer specifying the index of the alert.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8 

=cut

sub alert_acknowledge{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(controller index);
    my $c=$self->{command};
    my $s="alert acknowledge".build_command($arguments,\@command_parameters);
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 alert show 

Retrieves Storage Center alerts.

=over 8

Takes 17 parameters. Only two are required. 

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

acknowledged - Optional. A string to specify acknowledgement status on which to filter.

=item *

alert_type - Optional. A string to specify the type of alert on which to filter.

=item *

category - Optional. A string to specify an alert category on which to filter.

=item *

controller - Optional. An integer to specify the controller index on which to filter.

=item *

count - Optional. An integer to specify the alert count(number times generated) on which 
to filter.

=item *

csv - Optional. A string to specify a filename in which to save csv formatted output.

=item *

date_cleared - Optional. A string to specify a cleared date and time on which to filter.

=item *

date_created - Optional. A string to specify a creation date and time on which to filter.

=item *

index - Optional. An integer to specify an alert index on which to filter.

=item *

message - Optional. A string to specify an alert message on which to filter.

=item *

object_name - Optional. A string to specify an object name on which to filter.

=item *

reference_number - Optional. A string to specify a reference number on which to filter.

=item *

status - Optional. A string to specify an alert status on which to filter.

=item *

txt - Optional. A string to specify a filename in which to save output.

=item *

xml - Optional. A string to specify a filename in which to save xml formatted output.

=item *

output - A array reference to hold the CompCU output. Required for this 'show' command

=back 8

=cut

sub alert_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(acknowledged alert_type category controller count csv date_cleared date_created index message object_name reference_number status txt xml);
    my $s="alert show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 cache modify

Enables read/write of the StorageCenter cache.

=over 8

Takes four parameters. One is purely optional and only one of the read/write 
parameters is required at a time.

=item *

readcache - A String or Integer indicating "true"(or 1) or "false"(or 0) to 
enable/disable the global read cache.

=item *

writecache - A String or Integer indicating "true"(or 1) or "false"(or 0) to 
enable/disable the global read cache.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub cache_modify{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(readcache writecache);
    my $c=$self->{command};
    my $s="cache modify".build_command($arguments,\@command_parameters);
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 cache show

Shows the StorageCenter cache settings.

=over 8

Takes seven parameters. Five are optional.

=item *

csv - Optional. A String giving the filename in which to save csv formatted output.

=item *

readcache - Optional. A String specifying the readcache setting on which to filter.

=item *

txt - Optional. A String giving the filename in which to save output.

=item *

writecache - Optional. A String specifying the writecache setting on which to filter.

=item *

xml - Optional. A String giving the filename in which to save xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - A array reference to hold the CompCU output. 

=back 8

=cut

sub cache_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(csv readcache txt writecache xml);
    my $s="cache show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 cmm copy 

Creates a new CMM copy operation in StorageCenter.

=over 8

Takes six parameters. Three are required.

=item *

copyhistory - Optional. String indicating "true" or "false" specifying whether the Replay history
of the source volume is copied to the destination volume.

=item *

destvolumeindex - Integer specifying the index of teh detsination volume.

=item *

priority - Optional. String indicating "High", "Medium", or "Low".

=item *

sourcevolumeindex - Integer speciyfing the index of the source volume.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub cmm_copy{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(copyhistory destvolumeindex priority sourcevolumeindex);
    my $s="cmm copy".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 cmm delete

Aborts a StorageCenter cmm operation.

=over 8

Takes three parameters. Two are required.

=item *

index - An integer specifying the index of the cmm operation to abort.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub cmm_delete{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index);
    my $s="cmm delete".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 cmm migrate

Creates a cmm migrate operation.

=over 8

Takes eight parameters. Three are requred.

=item *

copyhistory - Optional. String indicating "true" or "false" specifying whether the Replay
history of the source volumeis copied to the destination volume.

deletesource - Optional. String indicating "true" or "false" specifying whether to delete the
source after igration.

destvolumeindex - Integer specifying the index of the destination volume.

priority - Optional. String indicating "High", Medium", or "Low" priority.

reversemirror - Optional. String indicating "true" or "false" specifying
whether to mirror back to the source volume.

sourcevolumeindex - Integer specifying the index of teh source volume.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub cmm_migrate{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(destvolumeindex sourcevolumeindex);
    my $s="cmm migrate".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 cmm mirror

Creates a cmm mirror operation in StorageCenter. 

=over 8

Takes six parameters. Three are optional.   

=item *

copyhistory - Optional. String indicating "true" or "false". Specifies whether
the Replay history of the source volume is copie to the destinatin volume.

destvolumeindex - Integer specifying the index of the destination volume.

priority - Optional. String indicating "High", "Medium", or "Low".

sourcevolumeindex - Integer specifying the index of the source volume.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub cmm_mirror{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(destvolumeindex sourcevolumeindex);
    my $s="cmm mirror".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 cmm modify

Modifies the priority of a cmm operation.

=over 8

Takes four parameters. Only one is optional.

=item *

index - Integer specifying the index of the cmm operation.

=item * 

priority - String indicating "High", Medium", or "Low".

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub cmm_modify{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index priority);
    my $s="cmm modify".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 cmm show

Shows the attributes of cmm operations.

=over 8

Takes 19 parameters. Only two are required.

=item *

copy_history - Optional. String specifying a copy history on which to filter.

=item *

csv - Optional. String indicating a filename to save csv formatted output.

=item *

current_position - Optional. String indicating the current position of a cmm operation on which to filter.

=item *

current_replay - Optional. String Specifying a cmm current Replay being copied on which to filter.

=item *

delete_source - Optional. String specifying the delete source on which to filter.

=item *

destination_volume_index  - Optional. Integer specifying a destination volume on which to filter.

=item *

destination_volume_name - Optional. String specifying the destination  volume name on which to filter.

=item *

index - Optional. String specifying the index of a cmm operation on which to filter.

=item *

priority - Optional. String indicating a priority (i.e. "High", Medium", or "Low") on which to filter.

=item *

reverse_mirror - Optional.  String specifying the reverse mirror value on which to filter.

=item *

source_volume_index - Optional. Integer specifying a source volume on which to filter.

=item *

source_volume_name - Optional. String specifying the source volume name on which to filter.

=item *

state - Optional. String  specifying state(i.e. "Down", "Running", or "Synced") of the cmm operation on which to filter.

=item * 

total_copy_size - Optional. Specifies the total size of a cmm operation on which to filter the display. 

=item *

txt - Optional. String indicating a filename in which to save output.

=item *

type - Optional. String specifying the type (i.e. "Copy", "Migrate", or "Mirror") of cmm operation on which to filter the display.

=item *

xml - Optional. String indicating a filename in which to save xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - A array reference to hold the CompCU output. 

=back 8

=cut

sub cmm_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(copy_history csv current_position current_replay delete_source destination_volume_index destination_volume_name index priority reverse_mirror source_volume_index source_volume_name state total_copy_size txt type xml);
    my $s="cmm show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 consistencygroup show

Shows the grups of Replays that are created with and associated with a consistency group. 

=over 8

Takes 12 parameters. Two are required.

=item *

csv - Optional. String specifying a filename in which to save csv formatted output.

=item *

expectedgroupsize - Optional. Integer indicating the number of Replays on which to filter.

=item *

expire - Optional. String specifying a timestamp on which to filter Replays.

=item *

freeze - Optional. String specifying a freeze timestamp on which to filter.

=item * 

groupsize - Optional. Integer indicating the number of Replays in the consistency group on which to filter.

=item *

index - Optional. Specifies the index of groups of Replays on which to filter.

=item *

name - Optional. String specifying a Replay name on which to filter.

=item * 

txt - Optional. String indicating a filename on whcih to save output.

=item *

writeholdduration - Optional. String indicating how longthe writes were held when creating the consistency group.

=item *

xml - Optional. String indicating a filename in which to store xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - A array reference to hold the CompCU output. 

=back 8

=cut

sub consistencygroup_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(csv expectedgroupsize expire freeze groupsize index name txt writeholdduration xml);
    my $s="consistencygroup show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 controller show

Shows configuration informatin for each controller. 

=over 8

Takes 20 parameters. Two are required.

=item *

controllerindex - Optional. Integer specifying a controller index on which to filter.

=item *

controlleripaddress - Optional. String indicating the IP address of the controller on which to filter.

=item *

controlleripgateway - Optional. String indicating the network gateway on which to filter.

=item *

controlleripmask - Optional. String indicating a netmask on which to filter.

=item *

csv - Optional. String indicating a filename in which to save csv formatted output.

=item *

domainname - Optional. String specifying a domain name on which to filter.

=item *

ipciaddress - Optional. String indicating a controller IPC port on which to filter.

=item *

ipcigateway - Optional. String indicating a controller IPC gateway on which to filter.

=item *

ipcimask - Optional. String indicating a controller IPC netmask on which to filter.

=item *

lastboottime - Optional.  String indicating a boot timestamp on which to filter.

=item *

leader - Optional. String Indicating if the controler is the current leader. Values can be "Yes" or "No".

=item *

localportcondition - Optional. String specifying a balanced status on whcih to filter.  Values can be "Balanced" or "Unbalanced".

=item *

name - Optional. String indicating a controller name on whcih to filter.

=item *

primarydns - Optional. String indicating an ip address of the primary DNS on which to filter.

=item *

status - Optional. String indicating a controller status on which tol filter. Values can be "Down" or "Up".

=item *

txt - Optional. String indicating a filename in which to save output.

=item *

version - Optional.  String indicating the four part controller version on which to filter.

=item *

xml - Optional. String indicating a filename in whcih to save xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - A array reference to hold the CompCU output. 

=back 8

=cut

sub controller_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(controllerindex controlleripaddress controlleripgateway controlleripmask csv domainname ipciaddress ipcigateway ipcimask lastboottime leader localportcondition name primarydns status txt version xml);
    my $s="controller show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 diskfolder show

Shows Storage Center disk folder information.

=over 8

Takes 14 parameters. Two are required.

=item *

allocatedspace - Optional. Integer indicating the allocated space on which to filter.

=item *

allocatedspaceblocks - Optional. Integer specifying (in blocks) the space on which to filter.

=item *

availablespaceblocks - Optional. Integer specifying (in blocks) the available space on which to filter.

=item *

csv - Optional. String indicating a filename in which to save csv formatted output.

=item *

index - Optional. Integer indicating the disk folder index on which filter.

=item * 

name - Optional. String specifying the name of a disk folder on which to filter.

=item *

nummanaged - Optional. Integer specifying the number of managed disks in the disk folder in which to display.

=item *

numspare - Optional. Integer indicating the number of spare disks in the disk folder in which to filter.

=item *

numstoragetype - Optional. Integer specifying the number of storage types in which to filter.

=item *

totalavailablespace - Optional. Inetegr specifying the avalable space in which to filter.

=item *

txt - Optional. String indicating a filename in which to store output.

=item *

xml - Optional. String indicating a filename in which to save xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - A array reference to hold the CompCU output. 

=back 8

=cut

sub diskfolder_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(allocatedspace allocatedspaceblocks availablespaceblocks csv index name nummanaged numspare numstoragetype totalavailablespace txt xml);
    my $s="diskfolder show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 mapping show

Gets the volume mapping information from Storage Center

=over 8 

Takes up to 14 parameters. Two are required. 

=item *

csv - Optional. String indicating a filename to save csv formatted output.

=item *

deviceid - Optional. String giving a device id in which to filter.

=item *

localport - Optional. Specifies localport on which to filter.

=item *

lun - Optional. Integer specifying a LUN on which to filter.

=item *

remoteport - Optional. Integer. Specifies remoteport on which to filter.

=item *

serialnumber - Optional. String indicating the volume serial number on which to filter.

=item *

server - Optional. String indicating a server name on which to filter.

=item *

serverindex - Optional. Integer indicating the index of the server in which to filter.

=item *

txt - Optional. String indicating a filename in which to save output.

=item *

volume - Optional. String indicating a volume name on which to filter.

=item *

volumeindex - Optional. Integer indicating a volume index on which to filter.

=item *

xml - Optional. String indicating a filename in which to save xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - A array reference to hold the CompCU output. 

=back 8 

=cut

sub mapping_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(csv deviceid localport lun remoteport serialnumber server serverindex txt volume volumeindex xml);
    my $s="mapping show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 os show

Retrieves OS information.

=over 8

Takes 10 parameters. Two are required.

=item *

csv - Optional. String indicating a filename in which to store csv formatted output.

=item *

index - Optional. Integer specifying the OS index on which to filter.

=item *

multipath - Optional. String. Indicates the OSs that support multiple paths for filtering purposes. Allowable values are "True" or "False".

=item *

name - Optional. String specifing the name of the OS on which to filter.

=item *

product - Optional. String specifying the OS product on which to filter.

=item *

txt - Optional. String indicating a filename in which to save output.

=item *

version - Optional. String indicating the OS version on which to filter.

=item *

xml - Optional. String indicating a filename in which to save xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - A array reference to hold the CompCU output. 

=back 8 

=cut

sub os_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(csv index multipath name product txt version xml);
    my $s="os show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 replay checkviews

Checks for and deletes expired views.

=over 8

Takes two parameters. One is optional.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8 

=cut

sub replay_checkviews{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw();
    my $s="replay checkviews".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 replay create

Creates a Replay of a volume. Optionally xreates and maps a view volume from the Replay.

=over 8

Takes 21 parameters. Only one of volumeindex, deviceid, serialnumber, or volume is strictly required.
All other parameters, aside from the always required success parameter, are optional.

=item *

deviceid - String specifying the device id.

=item *

expire - Optional. Integer specifying the number of minutes after which the Replay expires.

=item *

folder - Optional. String specifying a folder for the volume.

=item *

folderindex - Optional. Integer indicating the folder index for the volume.

=item *

localport - Optional. String for specifying localport information.

=item *

lun - Optional. Integer for setting the logical unit number. Default is the first LUN.

=item *

move - Optional. Required if using the 'view' parameter, however. If used this 
parameter causes the Replay to be taken off the existing volume 
before making the new view volume the active view for the created Replay.

=item *

name - Optional. String for setting the Replay name.

=item *

nomovereplay - Optional. If the view volume created by the 'view' option already exists
then makes the new view volume the active view for the created Replay without first
taking a Replay of the existing view volume.

=item *

purge - Optional. Indicates that expired views should be permanently deleted. Default
otherwise is to move to recycle bin.

=item *

readonly - Optional. Sets the Replay to be read only.

=item *

remoteport - Optional. String for setting the remote port name.

=item *

serialnumber - String for specifying the volume serial number.

=item *

server - Optional. Integer that specifies the server to map the view to.

=item *

singlepath - Optional. Indicates that only a single port can be used for mapping.

=item *

view - Optional. String that sets the volume on which the Replay is located.

=item *

viewexpire - Optional. Integer that sets the number of minutes to wait before unmapping and deleting an expire view.

=item *

volume - String that specifies the vlume on which to locate the replay.

=item *

volumeindex - Inetegr that specifes the index of the volume on which the Replay
is to be located.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8 

=cut

sub replay_create{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(deviceid expire folder folderindex localport lun move name nomovereplay purge readonly remoteport serialnumber server singlepath view viewexpire volume volumeindex);
    my $s="replay create".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 replay createview

Creates a view volume on an existing Replay. Optionally maps the new view volume
to a server.

=over 8

Takes 23 parameters. Only one of index, volumeindex, deviceid, serialnumber, or volume is strictly required.
All other parameters, aside from the always required success parameter, are optional.

=item *

boot - Optional. Sets the view volume on a Replay as a boot volume.

=item * 

deviceid - String specifying the device id.

=item *

folder - Optional. String specifying a folder for the volume.

=item *

folderindex - Optional. Integer indicating the folder index for the volume.

=item *

index - Integer that specifies the Replay index.

=item *

last - Optional. Creates a view from the last frozen Replay.

=item *

localport - Optional. String for specifying localport information.

=item *

lun - Optional. Integer for setting the logical unit number. Default is the first LUN.

=item *

move - Optional. Required if using the 'view' parameter, however. If used this 
parameter causes the Replay to be taken off the existing volume 
before making the new view volume the active view for the created Replay.

=item *

name - Optional. String for setting the Replay name.

=item *

nomovereplay - Optional. If the view volume created by the 'view' option already exists
then makes the new view volume the active view for the created Replay without first
taking a Replay of the existing view volume.

=item *

purge - Optional. Indicates that expired views should be permanently deleted. Default
otherwise is to move to recycle bin.

=item *

readonly - Optional. Sets the Replay to be read only.

=item *

remoteport - Optional. String for setting the remote port name.

=item *

serialnumber - String for specifying the volume serial number.

=item *

server - Optional. Integer that specifies the server to map the view to.

=item *

singlepath - Optional. Indicates that only a single port can be used for mapping.

=item *

view - Optional. String that sets the volume on which the Replay is located.

=item *

viewexpire - Optional. Integer that sets the number of minutes to wait before unmapping and deleting an expire view.

=item *

volume - String that specifies the vlume on which to locate the replay.

=item *

volumeindex - Inetegr that specifes the index of the volume on which the Replay
is to be located.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut 

sub replay_createview{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(boot deviceid folder folderindex index last localport lun move name nomovereplay purge readonly remoteport serialnumber server singlepath view viewexpire volume volumeindex);
    my $s="replay createview".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 replay delete

Deletes a specified Replay.

=over 8

Takes eight parameters. Only one of index, name, volume, deviceid, or serial number
is strictly required. All the others, except the always required success parameter are optional.

=item *

deviceid - String specifying the volume's device id.

=item *

index - Integer specifying the Replay index.

=item *

name - Optional. String to set the Replay name.

=item *

serialnumber - Integer that specifies the volume serial number.

=item *

volume - Specifies the volume name on which the Replay is located.

=item 

volumeindex - Optional. Integer to specify the volume where the Replay is located.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub replay_delete{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(deviceid index name serialnumber volume volumeindex);
    my $s="replay delete".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 replay show

Retrieves Reaply information.

=over 8

Takes 12 parameters. Only two are required.

=item *

consistencygroup - Optional. String to provide the consistency group on which to filter.

=item *

csv - Optional. String that specifies the filename for storing csv formatted output.

=item *

expire - Optional. String that sets a Replay expiration timestamp on which to filter.

=item *

freeze - Optional. String that sets a Replay freeze timestamp on which to filter.

=item *

index - Optional. Integer to specify a Replay index on which to filter.

=item *

name - Optional. String that specifies the Replay name on which to filter.

=item *

txt - Optional. String that specifies a filename for storing output.

=item *

volume - Optional. String for setting a volume name on which to filter.

=item *

volumeindex - Optional. Integer for setting the volume index on which to filter.

=item *

xml - Optional. String that specifies the filename for storing xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - A array reference to hold the CompCU output. 

=back 8

=cut

sub replay_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(consistencygroup csv expire freeze index name txt volume volumeindex xml);
    my $s="replay show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 replayprofile createreplay 

Creates a Replay on all volumes in a Replay profile.

=over 8

Takes six parameters. Only one of index or name is strictly required (along with the always
required success parameter).

=item *

expire - Optional. Integer which specifies the number of minutes after which the Replay profile expires.

=item *

index - Integer to set the index of the Replay profile.

=item *

name - String that sets the name of the Replay profile.

=item *

replayname - Optional. String to specify the name of the Replay.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub replayprofile_createreplay{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(expire index name replayname);
    my $s="replayprofile createreplay".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 replayprofile show

Retrieves Replay profile information.

=over 8

Takes 11 parameters. Two are required.

=item *

csv - Optional. String that specifies the filename for storing csv formatted output.

=item *

index - Optional. Integer to specify a Replay profile index on which to filter.

=item *

name - Optional. String which specifies a Replay profile name on which to filter.

=item *

numrules - Optional. String which specifies the number of rules associated with a specified Replay profile.

=item *

numvolumes - Optional. Integer that sets the number of volumes using the profile.

=item *

schedule - Optional. String that sets the rules and associated schedules for the profile.

=item *

txt - Optional. String that specifies the filename for storing formatted output.

=item *

type - Optional. String for setting the Replay profile type.

=item *

xml - Optional. String that specifies the filename for storing xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - A array reference to hold the CompCU output. 

=back 8

=cut

sub replayprofile_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(csv index name numrules numvolumes schedule txt type xml);
    my $s="replayprofile show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 server addhba

Configures a new HBA for an existing server in Storage Center.

=over 8 

Takes seven parameters. Two are required.

=item * 

index - Integer specifying the server index.

=item *

manual - Optional. Flag to configure the requested HBAs before they are are discovered.

=item *

name - String for setting the server name.

=item *

porttype - Optional. String which pecifies the transport type for all the HBAs being added. 
Allowed values are "FibreChannel" or "iSCSI".

=item *

WWN - Optional. String to specify one or more HBA world wide names for the server.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut 

sub server_addhba{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index manual name porttype WWN);
    my $s="server addhba".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 server addtocluster

Assigns an existing physical or virtual server to an existing server cluster.

=over 8

Takes six parameters. Two are required.

=item *

index - Integer to specify the server index.

=item *

name - String to set the server name.

=item *

parent - String to specify the server or cluster on which to host the new virtual server.

=item *

parentindex - Integer in which to specify the index of the parent server.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub server_addtocluster{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index name parent parentindex);
    my $s="server addtocluster".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 server create

Configures a physical server into the Storage Center system.

=over 8

Takes nine parameters. Three are required.

=item *

folder - Optional. String to specify a folder for the server.

=item *

folderindex - Optional. Integer to specify the server folder index.

=item *

name - String to set the server name.

=item *

notes - Optional. String to set user notes associated with the server.

=item *

os - Optional. String to specify the name of the OS hosted on the server.

=item *

osindex - Optional. Integer to set the index of the OS hosted on the server.

=item *

WWN - String to specify a globally unique WWN for the HBA.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub server_create{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(folder folderindex name notes os osindex WWN);
    my $s="server create".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 server createcluster

Creates a server cluster with no underlying physical or virtual servers.
Takes seven parameters. Three are required.

=over 8

=item *

folder - Optional. String to specify a server folder name.

=item *

folderindex - Optional. Integer to set the server folder index.

=item *

name - String to set the server name.

=item *

os - String to specify the name os the OS for the new cluster.

=item *

osindex - Optional. Integer to specify the index of the OS for the new cluster.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut 

sub server_createcluster{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(folder folderindex name os osindex);
    my $s="server createcluster".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 server delete

Deletes a server from the Storage Center system.

=over 8

Takes four parameters. Two are required. Use either index or name.

=item *

index - Integer to specify the index of the server.

=item *

name - String to specify the server name. 

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8


=cut

sub server_delete{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index name);
    my $s="server delete".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 server modify

Modifies a server.

=over 8

Takes eight parameters. Two are required. Use either of index or name.

=item *

folder - Optional. String to specify a folder.

=item *

folderindex - Optional. Integer to specify a folder index.

=item *

index - Integer to specify the server index.

=item * 

name - String. Specifies the server name.

=item *

os - Optional. String to set the name of the OS.

=item *

osindex - Optional. Integer to set the OS index of the OS hosted on the server.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub server_modify{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(folder folderindex index name os osindex);
    my $s="server modify".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}


=head3 server removehba

Removes an existing HBA assignment from an attached server.

=over 8

Takes five parameters. Three are required. Use either of name or index.

=item *

index - Integer to specify the server index.

=item *

name - String to set the server name.

=item *

WWN - String to specify the HBA to remove from the server.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub server_removehba{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index name WWN);
    my $s="server removehba".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}


=head3 server removefromcluster 

Removes a physical or virtual server from a server cluster.

=over 8

Takes four parameters. Two are required. Use either of index or name.

=item *

index - Integer to specify the server index.

=item *

name - String to specify the server name.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. A array reference to hold the CompCU output. 

=back 8

=cut

sub server_removefromcluster{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index name);
    my $s="server removefromcluster".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 server show

Retrieves the attributes of known attached servers.

=over 8

Takes 15 parameters. Two are required.

=item *

connectstatus - Optional. String to specify connection status. Allowed values are "Connected", "Disconnected", or "Partially Connected".

=item *

csv - Optional. String to specify a filename in which to store csv formatted output.

=item *

folder - Optional. String to specify a server folder on which to filter.

=item *

folderindex - Optional. Integer to set a folder index on which to filter.

=item *

index - Optional. Integer wich sets a server index on which to filter.

=item *

name - Optional. String to specify a server name on which to filter.

=item *

os - Optional. String to specify the name of the OS on which to filter.

=item *

osindex - Optional. Integer to set the server index on which to filter.

=item *

parent - Optional. String to set the parent host name on which to filter.

=item *

parentindex - Optional. Integer to set the index of the parent host on which to filter.

=item *

transporttype - Optional. String to specify the transport type on whcih to filter. 
Allowed values are "FibreChannel", "iSCSI", or "Both".

=item *

txt - Optional. String to specify a filename in which to store output.

=item *

type - Optional. String to specify teh server type on which to filter.
Allowed values are "Physical", "Virtual", "Cluster", or "'Remote Storage Center'".

=item *

wwn_list - Optional. String to specify one or more HBAs on which to filter.

=item *

xml - Optional. String to specify a filename in which to store xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - A array reference to hold the CompCU output. 

=back 8

=cut

sub server_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(connectstatus csv folder folderindex index name os osindex parent parentindex transporttype txt type wwn_list xml);
    my $s="server show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 server showhba

Shows server HBA information for each attached server.

=over 8

Takes 14 parameters. Two are required.

=item *

connectstatus - Optional. String to specify connection status. Allowed values are "Connected", "Disconnected", or "Partially Connected".

=item *

csv - Optional. String to specify a filename in which to store csv formatted output.

=item *

hbatype - Optional. String to specify the transport type of the HBA. Allowed values
are "iSCSI" or "FibreChannel".

=item *

ipaddress - Optional. String to specify the ip address ofr the HBA on which to filter.

=item *

iscsi_name - Optional. String to specify the iSCSI transport name on which to filter.

=item *

portinfo - Optional. Strig to specify additional port information on which to filter.

=item *

server - Optional. Integer to specify the server index on which to filter. 

=item *

servername - Optional. String to specify the server name on which to filter. 

=item *

status - Optional. String to specify the operational on which to filter. 
Allowed values are either "Up" or "Down".

=item *

txt - Optional. String to specify a filename in which to store output.

=item *

wwn - Optional. String to specify one or more HBAs on which to filter.

=item *

xml - Optional. String to specify a filename in which to store xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - A array reference to hold the CompCU output. 

=back 8

=cut

sub server_showhba{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(connectstatus csv hbatype ipaddress iscsi portinfo server servername status txt wwn xml);
    my $s="server showhba".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 serverfolder create

Creates a server folder.

=over 8

Takes five parameters. Two are required.

=item *

name - String to specifythe server folder name.

=item * 

parent - Optional. String to specify the parent folder of the server folder.

=item *

parentindex - Optional. Integer to specify the index of the serverfolder's parent. 

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub serverfolder_create{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(name parent parentindex);
    my $s="serverfolder create".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 serverfolder delete

Deletes a server folder.

=over 8

Takes five parameters. Two are required. Use any one of index or name.

=item *

index - Integer to specify the index of the server. 

=item *

name - String to specifythe server folder name.

=item * 

parent - Optional. String to specify the parent folder of the server folder.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub serverfolder_delete{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index name parent);
    my $s="serverfolder delete".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 serverfolder modify

=over 8

Takes five parameters. Three are required. Use any one of index or name and
any one of parent or parentindex.

=item *

index - Integer to specify the index of the server. 

=item *

name - String to specifythe server folder name.

=item * 

parent - String to specify the parent folder of the server folder.

=item *

parentindex - Integer to specify the index of the serverfolder's parent. 

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub serverfolder_modify{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index name parent parentindex);
    my $s="serverfolder modify".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 serverfolder show

Retrieves information about a server folder.

=over 8

Takes nine parameters. Two are required.

=item *

csv - Optional. String to specify a filename in which to save csv formatted output.

=item *

index - Optional. Integer to set the server folder index on which to filter.

=item *

name - Optional. String to set the server folder name on which to filter.

=item *

numservers - Optional. Integer. Shows the number of servers in the path.

=item *

path - Optional. String to specify the path of the server folder name.

=item *

txt - Optional. String that names a file in which to store output.

=item *

xml - Optional. String that names a file in which to store xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - An array reference to hold the CompCU output. 

=back 8


=cut

sub serverfolder_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(csv index name numservers path txt xml);
    my $s="serverfolder show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 storageprofile show 

Retrieves Storgae Profile information.

=over 8

Takes 15 parameters. Two are required. 

=item *

csv - Optional. String to specify a filename in which to save csv formatted output.

=item *

dualhistorical - Optional. String to show the storage tier and RAID level for dual redundant Replay data.

=item *

dualredundantwritable - Optional. String to show the storage tier and RAID level for dual redundant writeable data.

=item *

index - Optional. Integer to specify a storage profile index on which to filter.

=item *

name - Optional. Integer to specify a storage profile name on which to filter.

=item *

nonredundanthistorical - Optional. String on which to filter the storage tier and RAID level for nonredundant Replay data.

=item *

nonredundantwritable - Optional. String on which to filter the storage tier and RAID level for nonredundant writeable data.

=item *

numvolumes - Optional. Integer to specify the number of volumes used by the Storage Profile on which to filter.

=item *

redundanthistorical - Optional. String to show the storage tier and RAID level for redundant Replay data. 

=item *

redundantwritable - Optional. String to show the storage tier and RAID level for redundant writable data.

=item *

txt - Optional. String to specify a filename in which to store output.

=item *

xml - Optional. String to specify a filename in which to store xml formatted output. 

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - An array reference to hold the CompCU output. 

=back 8

=cut

sub storageprofile_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(csv dualhistorical dualredundantwritable index name nonredundanthistorical nonredundantwritable numvolumes redundanthistorical redundantwritable txt xml);
    my $s="storageprofile show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 storagetype show 

Retrieves storage type information.

=over 8

Takes 15 parameters. Two are required.

=item *

csv - Optional. String to specify a filename in which to save csv formatted output.

=item *

diskfolder - Optional. String to specify a diskfolder on which to filter.

=item * 

index - Optional. Integer to specify a storage type index to filter on.

=item *

name - Optional. String to specify a storage type name to filter on.

=item *

pagesize - Optional. Integer to provide a pagesize to filter on.

=item *

pagesize - Optional. Integer to provide a pagesize (in blocks) to filter on.

=item *

redundancy - Optional. Integer to specify a redundancy type to filter on. Allowed values
are 0, 1, or 2. These correspond, respectively, to non-redundant, redundant, dual-redundant.

=item *

spaceallocated - Optional. Integer to provide a space allocated size to filter on.

=item *

spaceallocatedblocks - Optional. Integer to provide a space allocated size (in blocks) to filter on.

=item *

spaceused - Optional. Optional. Integer to provide a space used size to filter on.

=item *

spaceusedblocks - Optional. Integer to provide a space used size (in blocks) to filter on.

=item *

txt - Optional. String to specify a filename in which to store output.

=item *

xml - Optional. String to specify a filename in which to store xml formatted output. 

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - An array reference to hold the CompCU output. 

=back 8

=cut

sub storagetype_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(csv diskfolder index name pagesize pagesizeblocks redundancy spaceallocated spaceallocatedblocks spaceused spaceusedblocks txt xml);
    my $s="storagetype show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 system restart

Restarts Storage Center.

=over 8

Takes three parameters. Only 'success' is required.

=item *

simultaneous - Optional. If set then both controllers on a dual-controlled system will be restarted simulataneously.
The default is restart them in sequence starting with the leader controller.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub system_restart{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(simultaneous);
    my $s="system restart".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 system show

Retrieves the Storage Center management configuration information.

=over 8

Takes 13 parameters. Two are required.

=item *

backupmailserver - Optional. String to specify a back up mail server IP on which to filter.

=item *

csv - Optional. String to set a filename in which to store csv formatted output.

=item *

mailserver - Optional. String to set a mail server IP to filter on.

=item *

managementip - Optional. String to specify a Storage Center IP address to filter on.

=item *

name - Optional. String to specify a Storage Center name to filter on.

=item *

operationmode - Optional. String to specify an operation mode to filter on.
Allowed values are "Install", "Maintenance", "Normal", or "PreProduction".

=item *

portsbalanced - Optional. String to specify a Ports Balanced status to filter on.
Allowed values are "Yes" or "No".

=item *

serialnumber - Optional. String to specifu a Storage Center serial number to filter on.

=item *

txt - Optional. String secifying a filename to store output.

=item *

version - Optional. String to specify a four part Storage Center version to filter on.

=item *

xml - Optional. String to specify a filename to store xml formatted output in.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - An array reference to hold the CompCU output. 

=back 8

=cut

sub system_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(backupmailserver csv mailserver managementip name operationmode portsbalanced serialnumber txt version xml);
    my $s="system show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 system shutdown

Shuts Storage Center down.

=over 8

Takes two parameters. Only 'success' is required.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub system_shutdown{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw();
    my $s="system shutdown".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}


=head3 user create

Creates a new Storage Enter user account.

=over 8

Takes 10 parameters. Four are required.

=item *

email - Optional. String to specify the user's email address.

=item *

notes - Optional. String stating some notes on the user to be created.

=item *

password - String to set the user's password.

=item *

privilege - String to set the user's priviledge level. Allowed values are "Admin", "VolumeManager", or "Reporter". 

=item *

realname - Optional. String to specify the user's real name.

=item *

usergroup - Optional. Specifies user group(s) for the new user.

=item *

usergroupindex - Optional. String to specify the index of groups to add the user too.  

=item *

username - String to set the name of the user to be created.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub user_create{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(email notes password privilege realname usergroup usergroupindex username);
    my $s="user create".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}


=head3 user delete

Deletes an existing Storage Center user account.

=over 8

Takes four parameters.  Two are required. Use any one of 'index' or 'username'.

=item *

index - Integer to specify the user's index.

=item *

username - String to specify the username of the user to be deleted.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub user_delete{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index username);
    my $s="user delete".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 user modify

Modifies a Storage Center user account information.

=over 8

Takes 12 parameters. Two are required. Use any one of 'index' or 'username'.

=item *

email - Optional. String to specify a user's email address.

=item *

enabled - Optional. String (either "true" or "false") to specify if the account is enabled.

=item *

index - Integer to set the index of the user's account.

=item *

notes - Optional. String to specify any notes about the user.

=item *

password - Optional. String to set the user's password.

=item *

privilege - Optional. String to specify the user's privilege level. Allowed values are "Admin", VolumeManager", or "Reporter".

=item *

realname - Optional. String to set the user's real name.

=item *

usergroup - Optional. String specifying which group(s) the user should belong to. 

=item *

usergroupindex - Optional. String specifying which group(s) (by index) the user should belong to. 

=item *

username - String specifying the user name. 

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub user_modify{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(email enabled index notes password privilege realname usergroup usergroupindex username);
    my $s="user modify".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 user show

Retrieves Storage Center user information.

=over 8

Takes 13 parameters. Two are required.

=item *

csv - Optional. String to specify a file in which to store csv formatted output.

=item *

email - Optional. String to specify a user's email address.

=item *

enabled - Optional. String (either "true" or "false") to specify if the account is enabled.

=item *

index - Optional. Integer to set the index of the user's account.

=item *

privilege - Optional. String to specify the user's privilege level. Allowed values are "Admin", VolumeManager", or "Reporter".

=item *

realname - Optional. String to set the user's real name.

=item *

showgroupindex - Optional. Flag that if set will cause the user groups to be displayed by index instead of name.

=item *

txt - Optional. String to specify a file in which to store output. 

=item *

user_groups - Optional. String specifying which group(s) the user should belong to. 

=item *

username - String specifying the user name. 

=item *

xml - Optional. String to specify a file in which to store xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - An array reference to hold the CompCU output. 

=back 8

=cut

sub user_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(csv email enabled index privilege realname showgroupindex txt user_groups username xml);
    my $s="user show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 usergroup create 

Creates a new Storage Center user group.

=over 8

Takes nine parameters. Five are required. Use any one of 'volumefolder' or 'volumeindex'.
Similarily, use any one of 'serverfolder'/'serverfolderindex' and 'diskfolder'/'diskfolderindex'.

=item *

diskfolder - Optional. String to specify the name of the disk folder(s) for the user group.

=item *

diskfolderindex - Optional. String to specify the index/indices of the disk folder(s) for the user group.

=item *

name - Optional. String to specify the name of the user group.

=item *

serverfolder - Optional. String to specify the server folders by name.

=item *

serverfolderindex - Optional. String to specify the server folders by index.

=item *

volumefolder - Optional. String to specify the volumefolders by name.

=item *

volumefolderindex - Optional. String to specify the volumefolders by index.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub usergroup_create{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(diskfolder diskfolderindex name serverfolder serverfolderindex volumefolder volumefolderindex);
    my $s="usergroup create".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 usergroup delete 

Deletes an existing Storage Center user group.

=over 8

Takes four parameters. Two are required. Use one of 'index' or 'name'.

=item *

index - Integer to specify the group by index.

=item *

name - String to specify the group by name.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub usergroup_delete{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index name);
    my $s="usergroup delete".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 usergroup modify

Modifies the details of an existing usergroup.

=over 8

Takes 10 parameters. Three are required. Use one of 'index' or 'name'.

=item *

diskfolder - Optional. String to specify the name of the disk folder(s) for the user group.

=item *

diskfolderindex - Optional. String to specify the index/indices of the disk folder(s) for the user group.

=item *

index - Integer to specify the group by index. 

=item *

name - String to specify the name of the user group.

=item *

serverfolder - Optional. String to specify the server folders by name.

=item *

serverfolderindex - Optional. String to specify the server folders by index.

=item *

volumefolder - Optional. String to specify the volumefolders by name.

=item *

volumefolderindex - Optional. String to specify the volumefolders by index.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub usergroup_modify{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(diskfolder diskfolderindex index name serverfolder serverfolderindex volumefolder volumefolderindex);
    my $s="usergroup modify".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 usergroup show 

Retrieves Storage Center user group information.

=over 8

Takes 11 parameters. Two are required.

=item *

csv - Optional. String to specify a filename in which to store csv formatted output.

=item *

disk_folders - Optional. String to specify the folders assigned to the user group.

=item *

index - Optional. Integer to specify a user group by index to filter on.

=item *

name - Optional. String to specify a user group name on which to filter.

=item *

server_folders - Optional. String to set which server folders to filter on.

=item *

showfolderindex - Optional. Flag that if set retrieves folder indices instead of names.

=item *

txt - Optional. String which names a file inw hcih to save output.

=item *

volume_folders - Optional. String to specify volume folders assigned to the user group in which to filter.

=item *

xml - Optional. String to specify a filename in which to save xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - An array reference to hold the CompCU output. 

=back 8

=cut

sub usergroup_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(csv disk_folders index name server_folders showfolderindex txt volume_folders xml);
    my $s="usergroup show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 volume create 

Creates a new volume.

=over 8

Takes 26 parameters. Three are required.

=item *

boot - Optional. Flag to designate the mapped volume as a boot volume.

=item *

controller - Optional. String to specify the controller by name.

=item *

diskfolder - Optional.  String to specify a disk folder for the volume.

=item *

folder - Optional. String to specify the name of an existing volume folder.

=item *

folderindex - Optional. String to specify the index of an existing volume folder.

=item *

localport - Optional. String to set the WWN of the local port to use for the mapping.

=item *

lun - Optional. Integer to set the Logical Unit Number.

=item *

maxwrite - Optional. Integer to set the maximum size for volume writes.

=item *

name - String to specify the volume name.

=item *

notes - Optional. String to specify some notes for the volume.

=item *

pagesize - Optional. Integer to set the pagesize to use for the volume.

=item *

readcache - Optional. String to enable/disable the volume read cache. Allowed values are "true" or "false".

=item *

redundancy - Optional. Integer to set volume storage type. allowed values are 0, 
1, or 2 and correspeonf, respectively, to non-redundant, redundant, or dual-redundant.

=item *

remoteport - Optional. String to specify the WWN of the remore port.

=item *

replayprofile - Optional. String to specify one or more Replay profiles for the volume.

=item *

server - Optional. String to specify the server for the volume.

=item *

serverindex - Optional. Integer to specify a server by index.

=item *

singlepath - Optional. Flag to indicate that only a single port can be used for ampping.

=item * 

size - Integer to specify the volume size.

=item *

storageprofile - Optional. String to specify a Storage Profile by name for the volume.

=item *

storageprofileindex - Optional. String to specify a Storage Profile by index for the volume.

=item *

storagetype - Optional. String to specify a storage type by name.

=item *

storagetypeindex - Optional. String to specify a storage type by index.

=item *

writecache - Optional. String to enable/disable writecache. Allowed values are "true" or "false".
Alternatively, respectively, 0 or 1 may be used.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub volume_create{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(boot controller diskfolder folder folderindex localport lun maxwrite name notes pagesize readcache redundancy remoteport replayprofile server serverindex singlepath size storageprofile storageprofileindex storagetype storagetypeindex writecache);
    my $s="volume create".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 volume delete

Deletes a Storage Center volume.

=over 8

Takes seven parameters. Two are required. Use any one of 'deviceid', 'index', 'name', or 'serialnumber'.

=item *

deviceid - String to specify the volume's device id.

=item *

index - Integer to specify a volume by index.

=item *

name - String to specify a volume by name.

=item *

purge - Optional. Flag to indicate if the volume should be purged.

=item *

serialnumber - String to specify the volume by serial number.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub volume_delete{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(deviceid index name purge serialnumber);
    my $s="volume delete".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}


=head3 volume erase

Erases all data from a volume.

=over 8

Takes six paramters. Two are required. Use any one of 'deviceid', 'index', 'name', or 'serialnumber'.

=item *

deviceid - String to specify the volume's device id.

=item *

index - Integer to specify a volume by index.

=item *

name - String to specify a volume by name.

=item *

serialnumber - String to specify the volume by serial number.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub volume_erase{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(deviceid index name serialnumber);
    my $s="volume erase".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 volume expand

Expands the size of the volume.

=over 8

Takes seven parameters. Three are required. Use any one of 'deviceid', 'index', 'name', or 'serialnumber'.

=item *

deviceid - String to specify the volume's device id.

=item *

index - Integer to specify a volume by index.

=item *

name - String to specify a volume by name.

=item *

serialnumber - String to specify the volume by serial number.

=item *

size - Integer to specify the amount by which to expand the volume.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub volume_expand{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(deviceid index name serialnumber size);
    my $s="volume expand".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 volume map

Maps an existing volume to a server.

=over 8

Takes 16 parameters. Four are required. Use any one of 'deviceid', 'index', 'name', 
or 'serialnumber'. Similarily, use any one of 'server' and 'serverindex' as well as
any one of 'boot' or 'lun'.


=item *

boot - Flag to designate the mapped volume as a boot volume.

=item *

controller - Optional. String to specify the controller by name.

=item *

deviceid - String to specify the volume device id.

=item *

force - Optional. Flag to force mapping even if another mapping exists.

=item *

index - Integer to specify the index of an existing volume.

=item *

localport - Optional. String to set the WWN of the local port to use for the mapping.

=item *

lun - Integer to set the Logical Unit Number.

=item *

name - String to specify the volume name.

=item *

readonly - Optional. Flag to set the map as read only.

=item *

remoteport - Optional. String to specify the WWN of the remote port.

=item *

serialnumber - String to specify the volume by serialnumber.

=item *

server - String to specify the server for the volume.

=item *

serverindex - Integer to specify a server by index.

=item *

singlepath - Optional. Flag to indicate that only a single port can be used for a mapping.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub volume_map{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(boot controller deviceid force index localport lun name readonly remoteport serialnumber server serverindex singlepath);
    my $s="volume map".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 volume modify

Modifies a volumeE<0x0027>s details.

=over 8

Takes 14 parameters. Two are required. Use one of 'deviceid', 'index', 'name',
or 'serialnumber'.

=item *

deviceid - String to specify the volume's device id.

=item *

folder - Optional. String to specify the name of an existing volume folder.

=item *

folderindex - Optional. String to specify the index of an existing volume folder.

=item *

index - Integer to specify the volume by index.

=item *

maxwrite - Optional. Integer to set the maximum size for volume writes.

=item *

name - String to specify the volume name.

=item *

readcache - Optional. String to enable/disable the volume read cache. Allowed values are "true" or "false".

=item *

replayprofile - Optional. String to specify one or more Replay profiles for the volume.

=item * 

serialnumber - String to specify the volume by serial number.

=item *

storageprofile - Optional. String to specify a Storage Profile by name for the volume.

=item *

storageprofileindex - Optional. String to specify a Storage Profile by index for the volume.

=item *

writecache - Optional. String to enable/disable writecache. Allowed values are "true" or "false".
Alternatively, respectively, 0 or 1 may be used.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub volume_modify{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(deviceid folder folderindex index maxwrite name readcache replayprofile serialnumber storageprofile storageprofileindex writecache);
    my $s="volume modify".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 volume show

Retrieves volume information.

=over 8

Takes 19 parameters. Two are required.

=item *

activesize - Optional. Integer to specify an activesize to filter on.

=item *

activesizeblocks - Optional. Integer to specify an activesize (in blocks) to filter on.

=item *

csv - Optional. String to specify a filename in which to store csv formatted output.

=item *

deviceid - Optional. String to specify a device id to filter on.

=item *

folder - Optional. String to specify a folder name to filter on.

=item *

index - Optional. Integer to specify a volume's index to filter on.

=item *

maxwritesizeblocks - Optional. Integer to specify a maximum write size (in blocks)
to filter on.

=item *

name - Optional. String to specify a volume's name to filter on.

=item *

readcache - Optional. String to specify a read cache setting to filter on. Allowed values
are "true" or "false".

=item *

replaysize - Optional. Integer to specify a Replay size to filter on.

=item *

replaysize - Optional. Integer to specify a Replay size (in blocks) to filter on.

=item *

serialnumber - Optional. String to specify a volume's serial number on which to filter.

=item *

status - Optional. String to specify a volume status to filter on. Allowed values are
"Up", "Down", "Inactive", or "Recycled".

=item *

storageprofile - Optional. String to specify a Storage Profile to filter on.

=item *

txt - Optional. String to specify a filename to store output in.

=item *

writecache - Optional. String to specify a write cache setting to filter on. Allowed values
are "true" or "false".

=item *

xml - Optional. String to specify a filename in which to store xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - An array reference to hold the CompCU output. 

=back 8

=cut

sub volume_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(activesize activesizeblocks csv deviceid folder index maxwriteblocksize name readcache replaysize replaysizeblocks serialnumber status storageprofile txt writecache xml);
    my $s="volume show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 volume unmap

Deletes mappings for a volume.

=over 8

Takes six paramters. Two are required. Use any one of 'deviceid', 'index', 'name', or 'serialnumber'.

=item *

deviceid - String to specify the volume's device id.

=item *

index - Integer to specify a volume by index.

=item *

name - String to specify a volume by name.

=item *

serialnumber - String to specify the volume by serial number.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub volume_unmap{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(deviceid index name serialnumber);
    my $s="volume unmap".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 volumefolder create

Creates a volume folder.

=over 8 

Takes five parameters. Two are required.

=item *

name - String to set the volume folder name.

=item *

parent - Optional. String to specify the parent folder for this volume folder.

=item *

parentindex - Optional. Integer to specify the parent folder for this volume folder by index.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub volumefolder_create{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(name parent parentindex);
    my $s="volumefolder create".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 volumefolder delete

Deletes a volume folder.

=over 8 

Takes five parameters. Three are required. Use one of 'index' or 'name'.

=item *

index - Integer to specify the volume folder by index.

=item *

name - String to specify the volume folder by name.

=item *

parent - String to specify the parent folder.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub volumefolder_delete{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index name parent);
    my $s="volumefolder delete".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}


=head3 volumefolder modify

Modifies a volume folder.

=over 8

Takes six parameters. Three are required. Use one of 'index' or 'name'
and one of 'parent' or 'parentindex'.

=item *

index - Integer to specify the index of the volume folder to modify.

=item *

name - String that specifies the volume folder to modify by name.

=item *

parent - String to specify the parent folder by name.

=item *

parentindex - Integer to specify the parent folder by its index.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub volumefolder_modify{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(index name parent parentindex);
    my $s="volumefolder modify".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute($c,$arguments->{success},$arguments->{output});
}

=head3 volumefolder show

Retrieves volume folder information.

=over 8

Takes nine parameters. Two are required.

=item *

csv - Optional. String to specify a filename to store csv formatted output.

=item *

index - Optional. Integer to specify a volume folder index to filter on.

=item *

name - Optional. String to specify the name of a volume folder to filter on.

=item *

numvolumes - Optional. Integer to specify a number of volumes to filter on.

=item *

path - Optional. String to specify a volume folder path to filter on.

=item *

txt - Optional. String to specify a filename to store formatted output.

=item *

xml - Optional. String to specify a filename to store xml formatted output.

=item *

success - A scalar reference which will be either set to true or false based on 
the success/failure of the command.

=item *

output - Optional. An array reference to hold the CompCU output. 

=back 8

=cut

sub volumefolder_show{
    my $self=shift;
    my $arguments=shift;
    my @command_parameters=qw(csv index name numvolumes path txt xml);
    my $s="volumefolder show".build_command($arguments,\@command_parameters);
    my $c=$self->{command};
    $c=~s/COMMAND/$s/; 
    execute_show($c,$arguments->{success},$arguments->{output});
}

=head3 build_command

Builds the command string to be passed to CompCU.

=over 8 

Takes 2 required parameters.

=item *

arguments - A hash reference containing the arguments passed to the calling subroutine.

=item *

parameters - An array reference containing the parametrs allowed for a given command.

=back 8

=cut

sub build_command{
    my $arguments=shift;
    my $parameters=shift;
    my $s="";
    foreach my $k (keys %$arguments){
        my @a=grep {/$k/} @$parameters;
        unless(!@a){
            $s.=" -$k $arguments->{$k}";
        }
    }
    return $s;
}

=head3 execute

Executes the CompCU commands for non "show" functions.

=over 8

Takes 3 required parameters.

=item *

command - A String containing the command to execute.

=item *

success - A scalar reference to the caller's $success

=item *

output - An array reference to the caller's $success

=back 8

=cut

sub execute{
    my ($command,$success,$output)=@_;
    my $buffer;
    my $command_ok=scalar run(command => $command,verbose => 0,buffer =>\$buffer);
    my @lines=modify_lines($buffer);
    if($command_ok) {
        if(check_success(\@lines)){
            $$success=1;
        }
        else{
            $$success=0;
        }
        if($output){
            my $l=@lines;
            my @a=@lines[(FIRST..$l - FOOTER_LENGTH)];#the first lines and the last few lines aren't important. 
            unshift @$output, @a;                     #they just contain header/footer infor from CompCU. The +2 skips the "---" seperator.
        }
    }
    else{
        $$success=0;
        unshift @$output, $lines[FIRST];#just send the only output line, it will contain information about what went wrong
    }
}

=head3 execute_show

Executes the CompCU commands for "show" functions.

=over 8

Takes 3 required parameters.

=item *

command - A String containing the command to execute.

=item *

success - A scalar reference to the caller's $success

=item *

output - An array reference to the caller's $success

=back 8

=cut

sub execute_show{
    my ($command,$success,$output)=@_;
    my $buffer;
    my $command_ok=scalar run(command => $command,verbose => 0,buffer =>\$buffer);
    my @lines=modify_lines($buffer);
    if($command_ok) {
        if(check_success(\@lines)){
            $$success=1;
        }
        else{
            $$success=0;
        }
        if($output){
            my $l=@lines;
            my @a=@lines[(FIRST_SHOW,FIRST_SHOW+2..$l - FOOTER_LENGTH)];#the first lines and the last few lines aren't important. 
            unshift @$output, @a;                                       #they just contain header/footer infor from CompCU. The +2 skips the "---" seperator.
        }
    }
    else{
        $$success=0;
        unshift @$output, $lines[FIRST_SHOW];#just send the only output line, it will contain information about what went wrong
    }
}

=head3 modify_lines

Output from CompCU is formatted so that each line ends with a "\r\n".
Also, IPC::Cmd output buffering is buggy. So we get output as a single string
and use this subroutine for preparing the lines of output into an array.

=over 8 

Takes 1 required parameter.

=item *

output - A string containing all the output.

=back 8

=cut

sub modify_lines{
    my $output=shift;
    $output=~tr/\r//d;
    return split(/\n/,$output);
}

=head3 check_success

When CompCU executes a command it will always end with the line
"Successfully finished running Compellent Command Utility (CompCU) application."
If the command was successful. Otherwise this message is not printed.
Returns a true/false value based on whether this success message is found.
This subroutine is redundant in that IPC::CmdE<0x0027>s C<run()> will not return 
true if not successful. I decided to include this subroutine more out of
paranoia than anything else.

=over 8 

Takes 1 required parameter.

=item *

output - An array reference containing all the output.

=back 8

=cut

sub check_success{
    my $output=shift;
    foreach my $line (@$output){
        if($line=~/Successfully finished/){
            return 1;
        }
    }
    return 0;
}

1;

=end lip

=cut

__END__

=head1 NAME

Compellent::CompCU - Perl interface to the Compellent command line tool.

=head1 SYNOPSIS

  use Compellent::CompCU;
  my $cli=new Compellent::CompCU({host=>"compellent.myorg.org",
                                  user=>"user",
                                  password=>"passwd",
                                  java_path=>"/usr/bin/java",
                                  java_args=>"-client",
                                  compcu_path=>"/Users/ar881/Downloads/CU050501_004A/CompCU.jar"});
  my $success;
  my $output=[];
  $cli->alert_acknowledge({controller=>8432,index=>6,success=>\$success,output=>$output});
  $cli->mapping_show({success=>\$success,output=>$output);
  $cli->volume_create({name=>"myvolume",size=>"1000000000m",success=>\$success,output=>$output});

=head1 DESCRIPTION

Compellent::CompCU provides a Perl wrapper around Compellent's command line tool.
The Compellent command line tool is distributed in the jar file CompCU.jar. Consequently, you must have Java and the CompCU.jar file in order for this to work.

Note that since we are wrapping a Java application each function called invokes a new instance of the JVM and so scripts using this module may seem slower than one may initially expect. This shouldn't be a problem since raw blistering performance is seldom required for these types of tasks but this idiosyncrasy should be made clear.

Every one of the CompCU functions is available through this interface. 
Each function takes a hash reference as its single argument. Parameters to each function
are provided as key/value pairs as shown in the examples. 

This module is written in the pseudo literate programming style provided by
L<Lip::Pod|Lip::Pod>. As such it comes with internal and external documentation.
The documentation on each and every function and the acceptable parameters for each
is contained in the internal documentation. The internal documentation is generated by the
C<lip2pod> command installed with the C<Lip::Pod> module.
Once installed run the following command:

C<lip2pod Compellent/CompCU.pm | pod2html --title=Compellent::CompCU E<gt> compcu-i.html>

And then view compcu-i.html in a web browser.

This page is obtained by pod2html directly:

C<pod2html --title=Compellent::CompCU --noindex Compellent/CompCU.pm E<gt> compcu-e.html>

Of course you may use other pod translators if you would prefer a format other than html.

=head1 SEE ALSO

Whenever in doubt the authoritative reference is
the vendor's documentation: "Storage Center Command Utility User Guide".
This is distributed as a .pdf file by Dell.

=head1 AUTHOR

Adam Russell, E<lt>ac.russell@live.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Adam Russell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
