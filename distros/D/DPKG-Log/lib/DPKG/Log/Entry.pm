=head1 NAME

DPKG::Log::Entry - Describe a log entry in a dpkg.log

=head1 VERSION

version 1.20

=head1 SYNOPSIS

use DPKG::Log::Entry;

$dpkg_log_entry = DPKG::Log::Entry->new( line => $line, $lineno => 1)

$dpkg_log_entry->timestamp($dt);

$dpkg_log_entry->associated_package("foo");


=head1 DESCRIPTION

This module is used to describe one line in a dpkg log
by parameterizing every line into generic parameters like

=over 3

=item * Type of log entry (startup-, status-, action-lines)

=item * Timestamp

=item * Subject of log entry (e.g. package, packages or archives)

=item * Package name (if log entry refers to a package subject)

=back

and so on.

The various parameters are described below together with
the various methods to access or modify them. 

=head1 METHODS


=over 4

=cut
package DPKG::Log::Entry;
BEGIN {
  $DPKG::Log::Entry::VERSION = '1.20';
}

use strict;
use warnings;
use overload ( '""' => 'line' );

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( $valid_types $valid_actions );

our $valid_types = {
    status => 1,
    action => 1,
    startup => 1,
    conffile_action => 1
    
};

our $valid_actions = {
   'install' => 1,
   'configure' => 1,
   'trigproc' => 1,
   'upgrade' => 1,
   'remove' => 1,
   'purge' => 1,
};

use Params::Validate qw(:all);

=item $dpkg_log_entry = PACKAGE->new( 'line' => $line, 'lineno' => $lineno )

Returns a new DPKG::Log::Entry object.
The arguments B<line> and B<lineno> are mandatore. They store the complete line
as stored in the log and the line number.

Additionally its possible to specify every attribute the object can store,
as 'key' => 'value' pairs.

=back

=cut
sub new {
    my $package = shift;
    $package = ref($package) if ref($package);

    my %params = validate( 
        @_, { 
                'line' => { 'type' => SCALAR },
                'lineno' => { 'type' => SCALAR },
                'timestamp' => '',
                'associated_package' => '',
                'action' => '',
                'status' => '',
                'subject' => '',
                'type' => '',
                'installed_version' => '',
                'available_version' => '',
                'decision' => '',
                'conffile' => '',
             }
    );
    my $self = {
        %params
    };
    bless($self, $package);
    return $self;
}

=head1 ATTRIBUTES

=over 4

=item $dpkg_log_entry->line() / line

Return the full log line. This attribute is set on object initialization.

=cut
sub line {
    my $self = shift;
    return $self->{line};
}

=item $dpkg_log_entry->lineno() / lineno

Return the line number of this entry. This attribute is set on object initialization.

=cut
sub lineno {
    my $self = shift;
    return $self->{lineno};
}

=item $dpkg_log_entry->timestamp() / timestamp

Get or set the timestamp of this object. Should be a DateTime object.

=cut
sub timestamp {
    my ($self, $timestamp) = @_;

    if ($timestamp) {
        if ((not ref($timestamp)) or (ref($timestamp) ne "DateTime")) {
            croak("timestamp has to be a DateTime object");
        }
        $self->{timestamp} = $timestamp;
    } else {
        $timestamp = $self->{timestamp};
    }
    return $timestamp;
}

=item $dpkg_log_entry->type() / type

Get or set the type of this entry. Specifies weither this is a startup,
status or action line.

=cut 
sub type {
    my ($self, $type) = @_;

    if ($type) {
        if (not defined($valid_types->{$type})) {
            croak("$type is not a valid type. has to be one of ".join(",", keys %{$valid_types}));
        }
        $self->{type} = $type;
    } else {
        $type = $self->{type}
    }
    return $type;
}

=item $dpkg_log_entry->associated_package() / associated_package

Get or set the associated_package of this entry. This is for lines that are associated to a certain
package like in action or status lines. Its usually unset for startup and status lines.

=cut 
sub associated_package {
    my ($self, $associated_package) = @_;

    if ($associated_package) {
        $self->{associated_package} = $associated_package;
    } else {
        $associated_package = $self->{associated_package};
    }
    return $associated_package;
}

=item $dpkg_log_entry->action() / action

Get or set the action of this entry. This is for lines that have a certain action,
like in startup-lines (unpack, configure) or action lines (install, remove).
It is usally unset for status lines.

=cut 
sub action {
    my ($self, $action) = @_;

    if ($action) {
        if (not defined($valid_actions->{$action})) {
            croak("$action is not a valid action. has to be one of ".join(",", keys %{$valid_actions}));
        }
        $self->{action} = $action;
    } else {
        $action = $self->{action};
    }
    return $action;
}

=item $dpkg_log_entry->status() / status

Get or set the status of the package this entry refers to.

=cut 
sub status {
    my ($self, $status) = @_;

    if ($status) {
        $self->{'status'} = $status;
    } else {
        $status = $self->{status}
    }
    return $status;
}

=item $dpkg_log_entry->subject() / subject

Gets or Defines the subject of the entry. For startup lines this is usually 'archives' or 'packages'
for all other lines its 'package'.

=cut 

sub subject {
    my ($self, $subject) = @_;

    if ($subject) {
        $self->{subject} = $subject;
    } else {
        $subject = $self->{subject};
    }
    return $subject;
}

=item $dpkg_log_entry->installed_version() / installed_version

Gets or Defines the installed_version of the package this entry refers to.
It refers to the current installed version of the package depending on the
current status. Is "<none>" (or similar) if action is 'install', old version in
case of an upgrade.
=cut 
sub installed_version {
    my ($self, $installed_version) = @_;

    if ($installed_version) {
        $self->{'installed_version'} = $installed_version;
    } else {
        $installed_version = $self->{installed_version};
    }
    return $installed_version;
}

=item $dpkg_log_entry->available_version() / available_version

Gets or Defines the available_version of the package this entry refers to.
It refers to the currently available version of the package depending on the
current status. Is different from installed_version if the action is install or upgrade.
=cut 
sub available_version {
    my ($self, $available_version) = @_;
    if ($available_version) {
       $self->{'available_version'} = $available_version;
    } else {
        $available_version = $self->{available_version};
    }
    return $available_version;
}

=item $dpkg_log_entry->conffile() / conffile

Get or set a conffile for a line indicating a conffile change.

=cut
sub conffile {
    my ($self, $conffile) = @_;
    if ($conffile) {
        $self->{conffile} = $conffile;
    } else {
        $conffile = $self->{conffile};
    }
}

=item $dpkg_log_entry->decision() / decision

Gets or defines the decision for a line indicating a conffile change.

=cut
sub decision {
    my ($self, $decision) = @_;
    if ($decision) {
        $self->{decision} = $decision;
    } else {
        $decision = $self->{decision}
    }
}

=back

=head1 SEE ALSO

L<DateTime>

=head1 AUTHOR

Patrick Schoenfeld <schoenfeld@debian.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Patrick Schoenfeld <schoenfeld@debian.org>

This library is free software.
You can redistribute it and/or modify it under the same terms as perl itself.

=cut

1;
# vim: expandtab:ts=4:sw=4