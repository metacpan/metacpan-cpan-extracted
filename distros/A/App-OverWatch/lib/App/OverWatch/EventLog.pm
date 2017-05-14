package App::OverWatch::EventLog;
# ABSTRACT: EventLog base class

use strict;
use warnings;

use App::OverWatch::DB;
use App::OverWatch::Event;

use Module::Load qw( load );

sub new {
    my $class = shift;
    my $rh_options = shift || {};

    my $DB = $rh_options->{db} // die "Require 'db'";

    my $type = $DB->type();

    my $subclass = "$class::$type";
    load($subclass);

    my $self = bless( {}, $subclass );

    $self->{DB} = $DB;

    return $self;
}

my @EventTypes = qw( START PROGRESS END POINT );

sub create_event {
    my $self    = shift;
    my $rh_args = shift;

    my $system    = $rh_args->{system}    // die "Error: require 'system'";
    my $subsystem = $rh_args->{subsystem} // die "Error: require 'subsystem'";
    my $worker    = $rh_args->{worker}    // die "Error: require 'worker'";
    my $type      = $rh_args->{type}      // die "Error: require 'type'";
    my $data      = $rh_args->{data}      // '';

    die "Error: Bad type '$type'"
        if (grep { /^$type$/ } @EventTypes == 0);

    my $sql =<<"SQL";
INSERT INTO
    events ( system, subsystem, worker, eventtype, ctime, data )
VALUES
    ( ?, ?, ?, ?, NOW(), ? )
SQL

    my $ret = $self->{DB}->dbix_run( $sql, $system, $subsystem, $worker,
                                     $type, $data );
    return $ret;
}

sub get_events {
    my $self = shift;
    my $rh_args = shift;

    my $sql =<<"SQL";
SELECT
    *
FROM
    events
SQL

    my $sth = $self->{DB}->dbix_select( $sql );
    return undef if (!defined($sth));

    my @events;
    while ( my $rh_row = $sth->fetchrow_hashref() ) {
        my $Event = App::OverWatch::Event->new($rh_row);
        push(@events, $Event);
    }
    return \@events;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OverWatch::EventLog - EventLog base class

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use App::OverWatch;
  my $OverWatch = App::OverWatch->new();
  [...]
  my $EventLog = $OverWatch->EventLog();

=head1 NAME

App::OverWatch::EventLog - App::OverWatch Events System

=head1 METHODS

=head2 new

Create an App::OverWatch::EventLog object - usualy handled by App::OverWatch.

=head2 create_event

Log an event in the database.

  $EventLog->create_event({
      system    => 'global',
      subsystem => 'uk',
      worker    => 'myworkerid',
      type      => 'START',      ## START / PROGRESS / END / POINT
      data      => 'some data',
  });

=head2 get_events

Retrieve all events in the DB.

  my @Events = $EventLog->get_events();

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
