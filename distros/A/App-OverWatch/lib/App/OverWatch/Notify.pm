
package App::OverWatch::Notify;
# ABSTRACT: Notify base class

use strict;
use warnings;
use utf8;

use App::OverWatch::DB;
use App::OverWatch::Notification;

use Module::Load qw( load );

sub new {
    my $class = shift;
    my $rh_options = shift || {};

    my $DB = $rh_options->{db} // die "Require 'db'";

    my $type = $DB->type();

    my $subclass = $class . '::' . $type;
    load($subclass);

    my $self = bless( {}, $subclass );

    $self->{DB} = $DB;

    return $self;
}

sub create_notification {
    my $self    = shift;
    my $rh_args = shift;

    my $system    = $rh_args->{system}    || die "Error: require 'system'";
    my $subsystem = $rh_args->{subsystem} || die "Error: require 'subsystem'";
    my $worker    = $rh_args->{worker}    || die "Error: require 'worker'";

    my $sql =<<"SQL";
INSERT INTO
    notifications ( system, subsystem, worker, ctime, mtime )
VALUES
    ( ?, ?, ?, NOW(), NOW() )
SQL

    my $ret = $self->{DB}->dbix_run( $sql, $system, $subsystem, $worker );
    return $ret;
}

sub delete_notification {
    my $self    = shift;
    my $rh_args = shift;

    my $system    = $rh_args->{system}    || die "Error: require 'system'";
    my $subsystem = $rh_args->{subsystem} || die "Error: require 'subsystem'";
    my $worker    = $rh_args->{worker}    || die "Error: require 'worker'";

    my $sql =<<"SQL";
DELETE FROM
    notifications
WHERE
    system = ? AND
    subsystem = ? AND
    worker = ?
SQL

    my $ret = $self->{DB}->dbix_run( $sql, $system, $subsystem, $worker );
    return $ret;
}

sub delete_all_notifications {
    my $self    = shift;
    my $rh_args = shift;

    my $worker    = $rh_args->{worker} || die "Error: require 'worker'";

    my $sql =<<"SQL";
DELETE FROM
    notifications
WHERE
    worker = ?
SQL

    my $ret = $self->{DB}->dbix_run( $sql, $worker );
    return $ret;
}

sub check_notifications {
    my $self    = shift;
    my $rh_args = shift;

    my $worker    = $rh_args->{worker} || die "Error: require 'worker'";

    my $sql =<<"SQL";
SELECT
    *
FROM
    notifications
WHERE
    worker = ?
SQL

    my $sth = $self->{DB}->dbix_select( $sql );
    return undef if (!defined($sth));
    my @notifications;
    while ( my $rh_row = $sth->fetchrow_hashref() ) {
        my $Notification = App::OverWatch::Notification->new($rh_row);
        push(@notifications, $Notification);
    }
    return \@notifications;
}

sub notify {
    my $self    = shift;
    my $rh_args = shift;

    my $system    = $rh_args->{system}    || die "Error: require 'system'";
    my $subsystem = $rh_args->{subsystem} || die "Error: require 'subsystem'";
    my $text      = $rh_args->{text}      || die "Error: require 'text'";

    my $sql =<<"SQL";
UPDATE
    notifications
SET
    fired = 1,
    text = ?,
    mtime = NOW()
WHERE
    system = ? AND
    subsystem = ?
SQL

    my $ret = $self->{DB}->dbix_run( $sql, $text, $system, $subsystem);
    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OverWatch::Notify - Notify base class

=head1 VERSION

version 0.1

=head1 SYNOPSIS

  use App::OverWatch;
  my $OverWatch = App::OverWatch->new();
  [...]
  my $Notify = $OverWatch->Notify();

=head1 NAME

App::OverWatch::Notify - App::OverWatch Notification System

=head1 METHODS

=head2 new

Create an App::OverWatch::Notify object - usually handled by App::OverWatch.

=head2 create_notification

Create a notification to allow systems to notify you of events.

   $Notify->create_notification({
      system    => 'global',
      subsystem => 'uk',
      worker    => 'myworkerid',
   });

=head2 delete_notification

Destroy a notification.

   $Notify->delete_notification({
      system    => 'global',
      subsystem => 'uk',
      worker    => 'myworkerid',
   });

=head2 delete_all_notifications

Destroy all notifications for a worker.

   $Notify->delete_all_notifications({
      worker    => 'myworkerid',
   });

=head2 check_notifications

Check to see if notification have been flagged for a worker.

   my @Notifications = $Notify->check_notifications({
      worker    => 'myworkerid',
   });

=head2 notify

Fire any notifications for a given system/subsystem.

   $Notify->notify({
      system    => 'global',
      subsystem => 'uk',
      text      => 'Some textual information',
   });

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
