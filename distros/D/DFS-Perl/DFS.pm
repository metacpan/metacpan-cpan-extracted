#
# DFS-Perl version 0.50
#
# Paul Henson <henson@acm.org>
#
# Copyright (c) 1997-2001 Paul Henson -- see COPYRIGHT file for details
#

package DCE::DFS;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);

use DCE::ACL;
use DCE::Registry;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw();

$VERSION = '0.50';

sub AUTOLOAD {
    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else {
                croak "Your vendor has not defined DCE::DFS macro $constname";
        }
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap DCE::DFS $VERSION;

sub DCE::DFS::flserver::status_endoflist {676372514}
sub DCE::DFS::ftserver::status_endoflist {676372514}

sub DCE::DFS::flserver::type_rw {0}
sub DCE::DFS::flserver::type_ro {1}
sub DCE::DFS::flserver::type_bk {2}

sub DCE::DFS::fileset::type_rw {0}
sub DCE::DFS::fileset::type_ro {1}
sub DCE::DFS::fileset::type_bk {2}

sub type_object {0}
sub type_default_object {1}
sub type_default_container {2}

sub acl {
    my ($path, $acl_type, $rgy) = @_;
    my $self = {};
    $self->{acl_type} = ($acl_type ne "") ? ($acl_type) : type_object;
    my $entry;
    my $uuid;
    my $fuuid;
    my $cell;
    my $entry_key;
    my $status;

    ($self->{acl_h}, $status) = DCE::ACL->bind($path);
    return (undef, $status) if $status;

    $self->{manager} = $self->{acl_h}->get_manager_types->[0];
    
    if (!($self->{rgy} = $rgy)) {
        ($self->{rgy}, $status) = DCE::Registry->site_default();
        return (undef, $status) if $status;
    }

    ($self->{acl_list}, $status) = $self->{acl_h}->lookup($self->{manager}, $self->{acl_type});
    return (undef, $status) if $status;

    $self->{acls} = $self->{acl_list}->acls;

    foreach $entry ($self->{acls}->entries) {
        $entry_key = $self->{acl_h}->type($entry->entry_info->{entry_type});
        if (($entry_key eq "user") || ($entry_key eq "group") || ($entry_key eq "foreign_other")) {
	    $cell = "";
	    $uuid = $entry->entry_info->{id}{uuid};
	    $fuuid = "";
	    $entry_key .= ":" . $uuid;
	}
	elsif (($entry_key eq "foreign_user") || ($entry_key eq "foreign_group")) {
	    $cell = $entry->entry_info->{foreign_id}{realm}{uuid};
	    $uuid = "";
	    $fuuid = $entry->entry_info->{foreign_id}{id}{uuid};
	    $entry_key .= ":" . $fuuid;
	}
	else {
	    $cell = "";
	    $uuid = "";
	    $fuuid = "";
	}

	$self->{entries}{$entry_key} = { entry_type => $entry->entry_info->{entry_type},
					 cell => $cell,
					 uuid => $uuid,
					 fuuid => $fuuid,
					 perms => $entry->perms,
				     };
    }

    bless($self, "DCE::DFS::acl");
    return ($self, 0);
}

sub DCE::DFS::acl::entries {
    my $self = shift;
    my %entries;
    my $entry_key;
    my $entry_type;
    my $entry_uuid;
    my $pgo_name;
    my $cell_name;
    my $status;

    foreach $entry_key (keys %{$self->{entries}}) {
	($entry_type, $entry_uuid) = split(/:/, $entry_key);

	if ($entry_uuid) {
	    if (!($pgo_name = $self->{entries}{$entry_key}{name})) {
		if ($entry_type eq "user") {
		    ($pgo_name, $status ) = $self->{rgy}->pgo_id_to_name($self->{rgy}->domain_person, $entry_uuid);
		}
		elsif ($entry_type eq "group") {
		    ($pgo_name, $status ) = $self->{rgy}->pgo_id_to_name($self->{rgy}->domain_group, $entry_uuid);
		}
		elsif ($entry_type eq "foreign_other") {
		    ($pgo_name, $status ) = $self->{rgy}->pgo_id_to_name($self->{rgy}->domain_person, $entry_uuid);
		    $pgo_name = "/..." . substr($pgo_name,6);
		}
		elsif ($entry_type eq "foreign_user") {
		    ($cell_name, $status) = id_to_cell_name($self, $self->{entries}{$entry_key}{cell});
		    if (!$status) {
			($pgo_name, $status) = $self->{cells}{$cell_name}->pgo_id_to_name($self->{rgy}->domain_person,
											  $self->{entries}{$entry_key}{fuuid});
			$pgo_name = $cell_name . "/" . $pgo_name;
		    }
		}
		elsif ($entry_type eq "foreign_group") {
		    ($cell_name, $status) = id_to_cell_name($self, $self->{entries}{$entry_key}{cell});
		    if (!$status) {
			($pgo_name, $status) = $self->{cells}{$cell_name}->pgo_id_to_name($self->{rgy}->domain_group,
											  $self->{entries}{$entry_key}{fuuid});
			$pgo_name = $cell_name . "/" . $pgo_name;
		    }
		}

		$pgo_name = $entry_uuid if $status;
		$self->{entries}{$entry_key}{name} = $pgo_name;
	    }
	    $entry_type .= ":" . $pgo_name;
	}

	$entries{$entry_type} = perms_to_text($self->{entries}{$entry_key}{perms});
    }

    return \%entries;
}

sub DCE::DFS::acl::entry {
    my $self = shift;
    my ($entry_key) = @_;
    my $entry_type;
    my $entry_name;
    my $entry_uuid;
    my $status;

    ($entry_type, $entry_name) = split(/:/, $entry_key);

    if ($entry_name) {
	($entry_uuid, $status) = name_to_id($self, $entry_type, $entry_name);
	return (undef, $status) if $status;
	$entry_key = $entry_type . ":" . $entry_uuid;
    }
    
    if ($self->{entries}{$entry_key}) {
	return (perms_to_text($self->{entries}{$entry_key}{perms}), 0);
    }
    else {
	return (undef, 387063834); # sec_acl_object_not_found
    }
}

sub DCE::DFS::acl::modify {
    my $self = shift;
    my ($entry_key, $text) = @_;
    my $entry_type;
    my $entry_name;
    my $entry_uuid;
    my $status;

    ($entry_type, $entry_name) = split(/:/, $entry_key);

    if ($entry_name) {
	($entry_uuid, $status) = name_to_id($self, $entry_type, $entry_name);
	return $status if $status;
	$entry_key = $entry_type . ":" . $entry_uuid;
    }

    if ($self->{entries}{$entry_key}) {
	$self->{entries}{$entry_key}{perms} = text_to_perms($text);
    }
    else {
	if (($self->{entries}{$entry_key}{entry_type} = DCE::ACL->type($entry_type)) eq "") {
	    return -1;
	}
	if (($entry_type eq "user") || ($entry_type eq "group") || ($entry_type eq "foreign_other")) {
	    $self->{entries}{$entry_key}{uuid} = $entry_uuid;
	}
	elsif (($entry_type eq "foreign_user") || ($entry_type eq "foreign_group")) {
	    $self->{entries}{$entry_key}{fuuid} = $entry_uuid;

	    $entry_name =~ s#^/\.\.\./##;
	    ($entry_name) = split("/", $entry_name);
	    $entry_name = "/.../" . $entry_name;
	    
	    ($entry_uuid, $status) = name_to_id($self, "foreign_other", $entry_name);
	    return $status if $status;

	    $self->{entries}{$entry_key}{cell} = $entry_uuid;
	}

	$self->{entries}{$entry_key}{cell} = "" unless ($self->{entries}{$entry_key}{cell});
	$self->{entries}{$entry_key}{uuid} = "" unless ($self->{entries}{$entry_key}{uuid});
	$self->{entries}{$entry_key}{fuuid} = "" unless ($self->{entries}{$entry_key}{fuuid});
	$self->{entries}{$entry_key}{perms} = text_to_perms($text),
    }

    return 0;
}

sub DCE::DFS::acl::delete {
    my $self = shift;
    my ($entry_key) = @_;
    my $entry_type;
    my $entry_name;
    my $entry_uuid;
    my $status;

    ($entry_type, $entry_name) = split(/:/, $entry_key);

    if ($entry_name) {
	($entry_uuid, $status) = name_to_id($self, $entry_type, $entry_name);
	return $status if $status;
	$entry_key = $entry_type . ":" . $entry_uuid;
    }

    if ($self->{entries}{$entry_key}) {
	delete $self->{entries}{$entry_key};

	return 0;
    }

    return 387063834; # sec_acl_object_not_found
}

sub DCE::DFS::acl::deleteall {
    my $self = shift;

    delete $self->{entries};
}

sub DCE::DFS::acl::calc_mask {
    my $self = shift;
    my $entry_key;
    my $mask_perms;

    foreach $entry_key (keys %{$self->{entries}}) {
	next if (($self->{entries}{$entry_key}{entry_type} == DCE::ACL->type_user_obj) ||
		 ($self->{entries}{$entry_key}{entry_type} == DCE::ACL->type_mask_obj));
	$mask_perms |= $self->{entries}{$entry_key}{perms};
    }

    if (!($self->{entries}{mask_obj})) {
	$self->{entries}{mask_obj}{entry_type} = DCE::ACL::type_mask_obj;
        $self->{entries}{mask_obj}{uuid} = "";
    }

    $self->{entries}{mask_obj}{perms} = $mask_perms;

}

sub DCE::DFS::acl::commit {
    my $self = shift;
    my $entry;
    my $entry_key;
    my $status;

    if (!($self->{entries}{user_obj})) {
	$self->{entries}{user_obj}{entry_type} = DCE::ACL::type_user_obj;
	$self->{entries}{user_obj}{cell} = "";
	$self->{entries}{user_obj}{uuid} = "";
	$self->{entries}{user_obj}{fuuid} = "";
	$self->{entries}{user_obj}{perms} = 0;
    }

    $self->{entries}{user_obj}{perms} |= DCE::ACL->perm_control;

    if (!($self->{entries}{group_obj})) {
        $self->{entries}{group_obj}{entry_type} = DCE::ACL::type_group_obj;
	$self->{entries}{user_obj}{cell} = "";
	$self->{entries}{user_obj}{uuid} = "";
	$self->{entries}{user_obj}{fuuid} = "";
	$self->{entries}{group_obj}{perms} = 0;
    }

    if (!($self->{entries}{other_obj})) {
        $self->{entries}{other_obj}{entry_type} = DCE::ACL::type_other_obj;
	$self->{entries}{user_obj}{cell} = "";
	$self->{entries}{user_obj}{uuid} = "";
	$self->{entries}{user_obj}{fuuid} = "";
	$self->{entries}{other_obj}{perms} = 0;
    }

    if (!($self->{entries}{mask_obj})) {
	$self->calc_mask;
    }

    $self->{acls}->delete;

    foreach $entry_key (keys %{$self->{entries}}) {
	$entry = $self->{acls}->new_entry;
	$entry->entry_info({ entry_type => $self->{entries}{$entry_key}{entry_type},
			     id => {
				 uuid => $self->{entries}{$entry_key}{uuid},
				 name => "",
			     },
			     foreign_id => {
				 realm => {
				     uuid => $self->{entries}{$entry_key}{cell},
				     name => "",
				 },
				 id => {
				     uuid => $self->{entries}{$entry_key}{fuuid},
				     name => "",
				 },
			     }
			 });
	$entry->perms($self->{entries}{$entry_key}{perms});
	$status = $self->{acls}->add($entry);
	return $status if $status;
    }

    $status = $self->{acl_h}->replace($self->{manager}, $self->{acl_type}, $self->{acl_list});
    return $status;
}

sub name_to_id {
    my ($self, $entry_type, $entry_name) = @_;
    my $cell_name;
    my $pgo_name;
    my $entry_uuid;
    my $status;

    if ($self->{pgo_uuids}{$entry_type}{$entry_name}) {
	return ($self->{pgo_uuids}{$entry_type}{$entry_name}, 0);
    }

    if ($entry_type eq "user") {
	($entry_uuid, $status) = $self->{rgy}->pgo_name_to_id($self->{rgy}->domain_person, $entry_name);
    }
    elsif ($entry_type eq "group") {
	($entry_uuid, $status) = $self->{rgy}->pgo_name_to_id($self->{rgy}->domain_group, $entry_name);
    }
    elsif ($entry_type eq "foreign_other") {
	$entry_name =~ s#^/\.\.\.#krbtkt#;
	($entry_uuid, $status) = $self->{rgy}->pgo_name_to_id($self->{rgy}->domain_person, $entry_name);
    }
    elsif ($entry_type eq "foreign_user") {
	$entry_name =~ s#^/\.\.\./##;
	($cell_name, $pgo_name) = split("/", $entry_name, 2);
	$cell_name = "/.../" . $cell_name;

	if (!$self->{cells}{$cell_name}) {
	    ($self->{cells}{$cell_name}, $status) = $self->{rgy}->site_open_query($cell_name);
	    return (undef, $status) if $status;
	}
	($entry_uuid, $status) = $self->{cells}{$cell_name}->pgo_name_to_id($self->{rgy}->domain_person, $pgo_name);
    }
    elsif ($entry_type eq "foreign_group") {
	$entry_name =~ s#^/\.\.\./##;
	($cell_name, $pgo_name) = split("/", $entry_name, 2);
	$cell_name = "/.../" . $cell_name;

	if (!$self->{cells}{$cell_name}) {
	    ($self->{cells}{$cell_name}, $status) = $self->{rgy}->site_open_query($cell_name);
	    return (undef, $status) if $status;
	}
	($entry_uuid, $status) = $self->{cells}{$cell_name}->pgo_name_to_id($self->{rgy}->domain_group, $pgo_name);
    }
    else {
	return (undef, -1);
    }

    return (undef, $status) if $status;

    $self->{pgo_uuids}{$entry_type}{$entry_name} = $entry_uuid;

    return ($entry_uuid, 0);
}

sub id_to_cell_name {
    my ($self, $cell) = @_;
    my $cell_name;
    my $status;

    ($cell_name, $status) = $self->{rgy}->pgo_id_to_name($self->{rgy}->domain_person, $cell);
    return (undef, $status) if $status;

    $cell_name = "/..." . substr($cell_name,6);

    if (!$self->{cells}{$cell_name}) {
	($self->{cells}{$cell_name}, $status) = $self->{rgy}->site_open_query($cell_name);
	return (undef, $status) if $status;
    }
    return ($cell_name, 0);
}

sub perms_to_text {
    my ($perms) = @_;
    my $text;

    $text .= ($perms & DCE::ACL->perm_read) ? "r" : "-";
    $text .= ($perms & DCE::ACL->perm_write) ? "w" : "-";
    $text .= ($perms & DCE::ACL->perm_execute) ? "x" : "-";
    $text .= ($perms & DCE::ACL->perm_control) ? "c" : "-";
    $text .= ($perms & DCE::ACL->perm_insert) ? "i" : "-";
    $text .= ($perms & DCE::ACL->perm_delete) ? "d" : "-";

    return $text;
}

sub text_to_perms {
    my ($text) = @_;
    my $perms;

    $perms |= DCE::ACL->perm_read if ($text =~ /r/);
    $perms |= DCE::ACL->perm_write if ($text =~ /w/);
    $perms |= DCE::ACL->perm_execute if ($text =~ /x/);
    $perms |= DCE::ACL->perm_control if ($text =~ /c/);
    $perms |= DCE::ACL->perm_insert if ($text =~ /i/);
    $perms |= DCE::ACL->perm_delete if ($text =~ /d/);

    return $perms;
}


1;
__END__


=head1 NAME

DCE::DFS - Perl module interface to DFS internals

=head1 SYNOPSIS

use DCE::DFS;

=head1 DESCRIPTION



=head1 General DFS methods



=over 4

=item $cellname = DCE::DFS::cellname(path)



=item $status = DCE::DFS::crmount(path, fileset, read_write = 0)



=item $status = DCE::DFS::delmount(path)



=item ($fid, $status) = DCE::DFS::fid(path)



=back

=head1 ACL stuff



=over 4

=item ($acl, $status) = DCE::DFS::acl(path, acl_type, registry_handle);



=item $acl->entries()



=item $acl->entry(entry_key)



=item $acl->modify(entry_key, permissions)



=item $acl->delete(entry_key)



=item $acl->deleteall()



=item $acl->calc_mask()



=item $acl->commit()



=back

=head1 FLDB methods



=over 4

=item $flserver->status_endoflist

=item $flserver->type_rw
=item $flserver->type_ro
=item $flserver->type_bk


=item $id = $fid->id



=item ($flserver, $status) = DCE::DFS::flserver(cell_fs = "/.:/fs")



=item $flserver->ftserver()



=item $flserver->ftserver_by_name(name)



=item $flserver->fileset_reset()



=item $flserver->fileset_mask_ftserver(ftserver)



=item $flserver->fileset_mask_aggregate(aggregate)



=item $flserver->fileset_mask_type(type)


=item $flserver->fileset()



=item $flserver->fileset_by_name(name)



=item $flserver->fileset_by_id(fid)



=back

=head1 ftserver methods

=item $ftserver->status_endoflist


=over 4

=item $ftserver->address()



=item $ftserver->hostname()



=item $ftserver->aggregate()



=back

=head1 aggregate methods



=over 4

=item $aggregate->ftserver()


=item $aggregate->name()



=item $aggregate->device()



=item $aggregate->id()



=item $aggregate->type()



=item $aggregate->size()



=item $aggregate->free()



=back

=head1 fileset methods



=over 4

=item $fileset->type_rw
=item $fileset->type_ro
=item $fileset->type_bk

=item $fileset->ftserver(ftserver_index = -1)

=item $fileset->aggregate(ftserver_index = -1)

=item $fileset->name()

=item $fileset->ftserver_count()

=item $fileset->ftserver_index(ftserver)

=item $fileset->exists(fileset_type, ftserver_index = -1)

=item $fileset->usage(ftserver_index = -1, fileset_type = 0)

=item $fileset->quota()

=item $fileset->set_quota(quota)


=back

=head1 AUTHOR

Paul Henson <henson@acm.org>

=head1 SEE ALSO

perl(1), DCE::*.

=cut
