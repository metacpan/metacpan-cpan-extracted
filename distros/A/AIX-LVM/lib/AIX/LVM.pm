package AIX::LVM;
use strict;
use warnings;
use Carp;
use IPC::Open3;
use IO::Select;
use IO::Handle;


use vars qw( @ISA $VERSION);
our $VERSION = '1.1';

my @lslv_prop = (
					"LOGICAL VOLUME:",
					"VOLUME GROUP:", 
					"LV IDENTIFIER:",
					"PERMISSION:",
					"VG STATE:",
					"LV STATE:",
					"TYPE:",
					"WRITE VERIFY:",
					"MAX LPs:",
					"PP SIZE:",
					"COPIES:",
					"SCHED POLICY:",
					"LPs:",
					"PPs:",
					"STALE PPs:",
					"BB POLICY:",
					"INTER-POLICY:",
					"RELOCATABLE:",
					"INTRA-POLICY:",
					"UPPER BOUND:",
					"MOUNT POINT:",
					"LABEL:",
					"MIRROR WRITE CONSISTENCY:",
					"EACH LP COPY ON A SEPARATE PV ?:",
					"Serialize IO ?:"
				);

my @lsvg_prop = (
					"VOLUME GROUP:", 
					"VG IDENTIFIER:",
					"VG PERMISSION:",
					"VG STATE:",
					"PP SIZE:",
					"TOTAL PPs:",
					"MAX LVs:",
					"FREE PPs:",
					"USED PPs:",
					"OPEN LVs:",
					"QUORUM:",
					"TOTAL PVs:",
					"STALE PVs:",
					"STALE PPs:",
					"ACTIVE PVs:",
					"AUTO ON:",
					"MAX PPs per VG:",
					"MAX PPs per PV:",
					"MAX PVs:",
					"LTG size (Dynamic):",
					"AUTO SYNC:",
					"HOT SPARE:",
					"BB POLICY:",
					"PV RESTRICTION:",
					"VG DESCRIPTORS:",
					"LVs:"
				);


my @lspv_prop = (
					"PHYSICAL VOLUME:",
					"VOLUME GROUP:",
					"PV IDENTIFIER:",
					"VG IDENTIFIER",
					"PV STATE:",
					"STALE PARTITIONS:",
					"ALLOCATABLE:",
					"PP SIZE:",
					"LOGICAL VOLUMES:",
					"TOTAL PPs:",
					"VG DESCRIPTORS:",
					"FREE PPs:",
					"HOT SPARE:",
					"USED PPs:",
					"MAX REQUEST:",
					"FREE DISTRIBUTION:",
					"USED DISTRIBUTION:",
					"MIRROR POOL:"
				);


sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self->init(@_);
}


sub init 
{
    my $self = shift;
    my ($result, %lslv, %lspv, %lsvg, @lslv, @lsvg, @lspv);
    my ($lsvg, $lsvg_error) = $self->_exec_open3("lsvg -o");
	croak "Error found during execution of lsvg -o: $lsvg_error\n" if $lsvg_error;
	@lsvg = $self->_splitter($lsvg, qr'\n+');
	foreach my $lvg (@lsvg) {
		$self->{$lvg}= $self->_get_lv_pv_props($lvg);  #Hierarchy is lsvg -> lslv and lspv
	}
    return $self;
}


sub get_logical_volume_group
{
	my $self = shift;
	return sort keys %{$self};
}


sub get_logical_volumes
{
	my $self = shift;
	return map {keys %{$self->{$_}->{lvol}}}keys %{$self};
}


sub get_physical_volumes
{
	my $self = shift;
	return map {keys %{$self->{$_}->{pvol}}}keys %{$self};
}


sub get_volume_group_properties
{
	my $self = shift;
	my $vg   = shift;
	croak "Pass values for Volume Group\n" unless $vg;
	exists $self->{$vg}->{prop}? %{$self->{$vg}->{prop}}:undef;
}


sub get_logical_volume_properties
{
	my $self        = shift;
	my ($vg, $lv)   = (shift, shift);
	croak "Pass values for Volume Group\n" unless $vg;
	croak "Pass values for Logical Volume Group\n" unless $lv;
	exists $self->{$vg}->{lvol}->{$lv}->{prop}? %{$self->{$vg}->{lvol}->{$lv}->{prop}} : undef;
}


sub get_physical_volume_properties
{
	my $self        = shift;
	my ($vg, $pv)   = (shift, shift);
	croak "Pass values for Volume Group\n" unless $vg;
	croak "Pass values for Physical Volume Group\n" unless $pv;
	exists $self->{$vg}->{pvol}->{$pv}->{prop}? %{$self->{$vg}->{pvol}->{$pv}->{prop}} : undef;
}


sub get_PV_PP_command 
{
	my $self        = shift;
	my ($vg, $pv)   = (shift, shift);
	croak "Pass values for Volume Group\n" unless $vg;
	croak "Pass values for Physical Volume Group\n" unless $pv;
	exists $self->{$vg}->{pvol}->{$pv}->{PV_PP_CMD_OUT}? $self->{$vg}->{pvol}->{$pv}->{PV_PP_CMD_OUT} : undef;
}


sub get_PV_LV_command
{
	my $self        = shift;
	my ($vg, $pv)   = (shift, shift);
	croak "Pass values for Volume Group\n" unless $vg;
	croak "Pass values for Physical Volume Group\n" unless $pv;
	exists $self->{$vg}->{pvol}->{$pv}->{PV_LV_CMD_OUT}? $self->{$vg}->{pvol}->{$pv}->{PV_LV_CMD_OUT} : undef;
}


sub get_LV_logical_command
{
	my $self        = shift;
	my ($vg, $lv)   = (shift, shift);
	croak "Pass values for Volume Group\n" unless $vg;
	croak "Pass values for Logical Volume Group\n" unless $lv;
	exists $self->{$vg}->{lvol}->{$lv}->{LV_LOGICAL_CMD_OUT}? $self->{$vg}->{lvol}->{$lv}->{LV_LOGICAL_CMD_OUT} : undef;
}


sub get_LV_M_command
{
	my $self        = shift;
	my ($vg, $lv)   = (shift, shift);
	croak "Pass values for Volume Group\n" unless $vg;
	croak "Pass values for Logical Volume Group\n" unless $lv;
	exists $self->{$vg}->{lvol}->{$lv}->{LV_MIRROR_CMD_OUT}? $self->{$vg}->{lvol}->{$lv}->{LV_MIRROR_CMD_OUT} : undef;
}


#### Private methods ####

# This subroutine is used to populate LV Values, PV Values and Properties of Volume Groups

sub _get_lv_pv_props 
{
    my $self = shift;
    my $lvg  = shift;
    croak "Logical volume group is not found\n" unless $lvg;
    my (@lv, @pv, %lvg_hash);
    my ($lslv, $lslv_error) = $self->_exec_open3("lsvg -l $lvg");    # Populate LV Values
	croak "Error found during execution of lsvg -l $lvg: $lslv_error\n" if $lslv_error;
    my @lslv = $self->_splitter($lslv, qr'\n+');
	foreach my $lslv_l (@lslv[2..$#lslv]) {
		push @lv, $1 if ($lslv_l=~/^(\S+)/);
	}
	foreach my $lv (@lv) {
		$lvg_hash{lvol}->{$lv}= $self->_get_lslv_l_m_prop($lv);
	}
    my ($lspv, $lspv_error) = $self->_exec_open3("lsvg -p $lvg");   # Populate PV Values
	croak "Error found during execution of lsvg -p $lvg: $lspv_error\n" if $lspv_error;
	my @lspv = $self->_splitter($lspv, qr'\n+');
	foreach my $lspv_l (@lspv[2..$#lspv]) {
		push @pv, $1 if ($lspv_l=~/^(\S+)/);
	}
	foreach my $pv (@pv) {
		$lvg_hash{pvol}->{$pv}= $self->_get_lspv_l_m_prop($pv);
	}
    my ($prop, $prop_error) = $self->_exec_open3("lsvg $lvg");    # Populate Properties
	croak "Error found during execution of lsvg $lvg: $prop_error\n" if $prop_error;
	$lvg_hash{prop} = $self->_parse_properties($prop, @lsvg_prop);
	return \%lvg_hash;
}

# This subroutine is used to populate LV Logical Values, LV Physical Values and Properties of Logical Volumes

sub _get_lslv_l_m_prop 
{
    my $self = shift;
	my $lv   = shift;
    croak "Logical volume is not found\n" unless $lv;
    my (@lv, @pv, %lslv);
    my ($lslv, $lslv_error) = $self->_exec_open3("lslv -l $lv");    # Populate LV Logical Values
	croak "Error found during execution of lslv -l $lv: $lslv_error\n" if $lslv_error;
    $lslv{"LV_LOGICAL_CMD_OUT"} = $lslv;
    my ($lspv, $lspv_error) = $self->_exec_open3("lslv -m $lv");    # Populate LV Mirror Values
	croak "Error found during execution of lslv -m $lv: $lspv_error\n" if $lspv_error;
    $lslv{"LV_MIRROR_CMD_OUT"} = $lspv;
    my ($prop, $prop_error) = $self->_exec_open3("lslv $lv");    # Populate LV Properties
	croak "Error found during execution of lslv $lv: $prop_error\n" if $prop_error;
	$lslv{prop} = $self->_parse_properties($prop, @lslv_prop);
	return \%lslv;    
}

# # This subroutine is used to populate PV Logical Values, PV PP Values and Properties of Physical Volumes

sub _get_lspv_l_m_prop 
{
    my $self = shift;
	my $pv   = shift;
    croak "Physical volume is not found\n" unless $pv;
    my (@lv, @pv, %lspv);
    my ($lslv, $lslv_error) = $self->_exec_open3("lspv -l $pv");    # Populate PV Logical Values
	croak "Error found during execution of lspv -l $pv: $lslv_error\n" if $lslv_error;
    $lspv{"PV_LOGICAL_CMD_OUT"} = $lslv;
    my ($lspv, $lspv_error) = $self->_exec_open3("lspv -M $pv");    # Populate PV in LV Values
	croak "Error found during execution of lspv -M $pv: $lspv_error\n" if $lspv_error;
    $lspv{"PV_LV_CMD_OUT"} = $lspv;
    my ($lspp, $lspp_error) = $self->_exec_open3("lspv -p $pv");    # Populate PV Physical Partitions Values
	croak "Error found during execution of lspv -p $pv: $lspp_error\n" if $lspp_error;
    $lspv{"PV_PP_CMD_OUT"} = $lspp;
    my ($prop, $prop_error) = $self->_exec_open3("lspv $pv");    # Populate PV Properties
	croak "Error found during execution of lspv $pv: $prop_error\n" if $prop_error;
	$lspv{prop} = $self->_parse_properties($prop, @lspv_prop);
	return \%lspv;    
}

# This subroutine performs parsing the output of the commands for passed array values.

sub _parse_properties 
{
    my $self = shift;
	my $prop = shift;
	my @defp = @_;
    my %prop;
	foreach my $defp (@defp) {
		my $str = join '|', grep {"$_" ne $defp} @defp;
		if ($prop=~/\Q$defp\E([^\n]*?)($str|\n|$)/s) {
            my $value = $1;
			$value =~s/^\s+|\s+$//g;
			$prop{$defp} = $value;
		} else {
			carp "Property $defp not have value. Probably due to inconsistent identifier output\n";
		}
	}
	return \%prop;
}

# This subroutine is used to execute the commands using open3 to capture Error stream.

sub _exec_open3
{
    my $self = shift;
	my ($result, $error);
    my $writer_h  = new IO::Handle;
    my $reader_h  = new IO::Handle;
    my $error_h   = new IO::Handle;  
    my $pid = open3($writer_h, $reader_h, $error_h,  @_) or croak "Not able to open3: $! \n";
    $reader_h->autoflush();
    $error_h->autoflush();
    my $selector = IO::Select->new();
    $selector->add($reader_h, $error_h);    ## Add the handlers to select call ##
    while( my @ready = $selector->can_read ){
        foreach my $fh ( @ready ){
           if( fileno($fh) == fileno($reader_h) ){
               my $ret = $reader_h->sysread($_, 1024);
	           $result .= $_;
	           $selector->remove($fh) unless $ret;
           }
           if( fileno($fh) == fileno($error_h) ){
               my $ret = $error_h->sysread($_, 1024);
	           $error .= $_;
               $selector->remove($fh) unless $ret;
           }
        }
    }
    $reader_h->autoflush();
    $error_h->autoflush();  
    waitpid $pid, 0;
    my $rc = $? >> 8;
    carp "Error in executing the command\n" if ($rc);
    return $result, $error;
}

# Splitter based on pattern

sub _splitter 
{
    my $self           =  shift;
    my ($string, $pat) = (shift, shift);
    return split /$pat/, $string;
}


__END__


=head1 NAME

AIX::LVM - Perl extension to handle AIX LVM Structure.

=head1 SYNOPSIS

  use AIX::LVM;

   my $lvm = AIX::LVM->new;

   my @volume_group = $lvm->get_logical_volume_group(); #List all the Volume groups present.

   my @pvs = $lvm->get_physical_volumes(); #List all the Physical volumes present.

   my @lvs = $lvm->get_logical_volumes(); #List all the Physical volumes present.

   #%vg_props consist of all the volume group properties in key=>value format.
   my %vg_props = $lvm->get_volume_group_properties("rootvg"); 

   #%lv_props consist of all the properties for logical volume "x" under volume group "rootvg";
   my %lv_props = $lvm->get_logical_volume_properties("rootvg","x");  

   my $lslv_l_cmd = $lvm->get_LV_logical_command("rootvg","x") #Equivalent to lslv -l x

   my $lslv_m_cmd = $lvm->get_LV_M_command("rootvg","x") #Equivalent to lslv -m x


=head1 DESCRIPTION

This Module is a Perl wrapper for AIX LVM and provides access to the properties
of Volume groups, Logial Volumes, Physical Volumes, Physical Partitions. This provides
access to LVM command equivalents.

=head1 METHODS

=over 4

=item get_logical_volume_group();

Returns an array of volume groups present.

=item get_physical_volumes();

Returns an array of Physical volumes present.

=item get_logical_volumes();

Returns an array of Logical volumes present.

=item get_volume_group_properties("rootvg")

Returns a hash of properties for volume group "rootvg"

=item get_logical_volume_properties("rootvg","hd5")

Returns a hash of properties for logical volume "hd5" present under volume group "rootvg"

=item get_physical_volume_properties("rootvg","hdisk0")

Returns a hash of properties for physical volume "hdisk0" present under volume group "rootvg"

=item get_LV_logical_command("rootvg","hd5")

Returns output as scalar for command equivalent of lslv -l hd5

=item get_LV_ M_command("rootvg","hd5")

Returns output as scalar for command equivalent of lslv -m hd5

=item get_PV_PP_command("rootvg","hdisk0")

Returns output as scalar for command equivalent of lspv -p hd5

=item get_PV_LV_command("rootvg","hdisk0")

Returns output as scalar for command equivalent of lspv -l hd5

=head1 CAVEATS

Needed to be executed as root user.

VG IDENTIFIER property for physical volume doesn't have proper format i.e Missing : at the end.
This may differ for different versions of AIX.

=head1 SEE ALSO

L<IO::Select>

L<IPC::Open3>

=head1 AUTHOR

Murugesan Kandasamy E<lt>Murugesan.Kandasamy@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Murugesan Kandasamy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

