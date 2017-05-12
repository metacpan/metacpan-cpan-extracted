package DJabberd::RosterStorage::SQLite::Fixed;
use strict;
use warnings;
use base 'DJabberd::RosterStorage::SQLite';
use DJabberd::Log;
use DJabberd::Util;
our $logger = DJabberd::Log->get_logger();

=head1 NAME

DJabberd::RosterStorage::SQLite::Fixed - a shared roster implementation for the SQLite roster storage

=head1 VERSION

Version 0.02
=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    <VHost mydomain.com>

	[...]

	<Plugin DJabberd::RosterStorage::SQLite::Fixed>
	    Database jabberroster.sqlite
	    FixedGuestOK yes
	</Plugin>
    </VHost>

Valid command are all command valid in DJabberd::RosterStorage::SQLite Plus the following

FixedGuestOK - Populate accounts with the shared roster if they are not in the roster itself?
 Setting this to yes will populate a user who is not in the shared roster with everyone in the shared roster
 The default is to only populate rosters for users that are part of the shared roster

=head1 AUTHOR

Edward Rudd, C<< <urkle at outoforder.cc> >>

=cut

=head2 set_config_fixedguestok($self, $guest)

Called to specify if guests should have the shared roster added to their roster

=cut

sub set_config_fixedguestok {
    my ($self, $guest) = @_;
    $self->{fixed_guestok} = as_bool $guest;
}

=head2 finalize($self)

Set defaults for the configuration

=cut

sub finalize {
    my $self = shift;
    $self->{fixed_guestok} = 0 unless $self->{fixed_guestok};
    $self->SUPER::finalize;
}

=head2 get_roster($self, $cb, $jid)

Gets the Roster for the user

=cut

sub get_roster {
    my ($self, $cb, $jid) = @_;
    # cb can '->set_roster(Roster)' or decline

    my $myself = lc $jid->as_bare_string;
    $logger->info("Fixed loading roster for $myself ...");

    my $on_load_roster = sub {
        my (undef, $roster) = @_;

        my $pre_ct = $roster->items;
        $logger->info("  $pre_ct roster items prior to population...");

        # see which shared contacts already in roster
        my %has;
        foreach my $it ($roster->items) {
            my $jid = $it->jid;
            $has{lc $jid->as_bare_string} = $it;
        }

        # add missing shared contacts to the roster
        my $req_roster = $self->_roster();
        if ($self->{fixed_guestok}==0) {
    	    my $guestok = 0;
    	    foreach my $user ( @$req_roster) {
    		if ($user->{jid} eq $myself) {
    		    $guestok = 1;
    		    last;
    		}
    	    }
    	    # Bail if guestOK == 0 && user it not in the roster
    	    return if $guestok == 0;
        }

        foreach my $user ( @$req_roster) {
            next if $user->{jid} eq $myself;

            my $name = $user->{name};
            my $ri = $has{$user->{jid}} || DJabberd::RosterItem->new(jid  => $user->{jid},
                                                             name => ($user->{name} || $user->{jid}),
                                                             groups => [$user->{group}]);


            $ri->subscription->set_from;
            $ri->subscription->set_to;
            $roster->add($ri);
        }

        my $post_ct = $roster->items;
        $logger->info("  $post_ct roster items post population...");

        $cb->set_roster($roster);
    };

    my $cb2 = DJabberd::Callback->new({set_roster => $on_load_roster,
                                      decline    => sub { $cb->decline }});
    $self->SUPER::get_roster($cb2, $jid);
}

=head2 check_install_schema($self)

Checks the SQL ite Schema

=cut

sub check_install_schema {
    my $self = shift;

    $self->SUPER::check_install_schema();

    my $dbh = $self->{dbh};

    eval {
        $dbh->do(qq{
            CREATE TABLE requiredusers (
        			 jid VARCHAR(255) NOT NULL,
        			 fullname VARCHAR(255) NOT NULL,
        			 groupname VARCHAR(255) NOT NULL,
                                 UNIQUE (jid)
                                 )});
    };
    if ($@ && $@ !~ /table \w+ already exists/) {
        $logger->logdie("SQL error $@");
        die "SQL error: $@\n";
    }
    eval {
	$dbh->do(qq{
	    CREATE VIEW RosterPreview AS
		SELECT ju.jid AS UserID, g.name AS [Group], 
		    jr.jid AS ContactID, r.name AS Contact, r.subscription AS Subscription
	        FROM roster r
	            JOIN jidmap ju ON r.userid=ju.jidid
	            JOIN jidmap jr ON r.contactid = jr.jidid
                    JOIN groupitem gi ON gi.contactid=r.contactid
                    JOIN rostergroup g ON g.userid=r.userid AND g.groupid=gi.groupid
                    UNION SELECT r1.jid, r2.groupname, r2.jid, r2.fullname, 3
                    FROM requiredusers r1, requiredusers r2
                        WHERE r1.jid != r2.jid});
    };
    if ($@ && $@ !~ /table \w+ already exists/) {
	$logger->logdie("SQL error $@");
	die "SQL error: $@\n";
    }
    eval {
	$dbh->do(qq{
	    CREATE VIEW RosterList AS
		SELECT J.jidid as LID, J2.jidid as RID, 
		    G.groupid as GID,
	            J.jid AS Local, J2.jid AS Remote,
	            G.name AS [Group]
                FROM jidmap J
                    JOIN rostergroup G ON G.userid=J.jidid
            	    JOIN groupitem M ON G.groupid = M.groupid
            	    JOIN jidmap J2 ON J2.jidid = M.contactid
            	ORDER BY J.jid, J2.jid});
    };
    if ($@ && $@ !~ /table \w+ already exists/) {
	$logger->logdie("SQL error $@");
	die "SQL error: $@\n";
    }
    $logger->info("Created all roster tables");
}

my $last_roster;
my $last_roster_time = 0;  # unixtime of last SQL suck
sub _roster {
    my $self = shift;
    my $now = time();

    # Cache list for 1 minute(s)
    if ($last_roster && $last_roster_time > $now - 60) {
        return $last_roster;
    }

    my $dbh = $self->{dbh};

    my $sql = qq{
	SELECT jid, fullname, groupname FROM requiredusers
    };

    my $roster = eval {
        $dbh->selectall_arrayref($sql);
    };
    $logger->logdie("Failed to load roster: $@") if $@;

    $logger->info("Found ".($#{ @$roster}+1)." Roster users");

    my @info = ();
    foreach my $item ( @$roster ) {
	my $rec = {};
	$rec->{'jid'} = $item->[0];
	$rec->{'name'} = $item->[1];
	$rec->{'group'} = $item->[2];
	push @info, $rec;
    }
    $logger->info("Loaded ".($#info+1)." Roster users");
    $last_roster_time = $now;
    return $last_roster = \@info;
}

=head2 load_roster_item($self, $jid, $contact_jid, $cb)

Called when a roster item is added

=cut

sub load_roster_item {
    my ($self, $jid, $contact_jid, $cb) = @_;

    my $is_shared = sub {
        my $jid = shift;
        my $roster = $self->_roster();
        foreach my $user (@$roster) {
    	    if (lc $user->{jid} eq lc $jid->as_bare_string) { return 1; }
        }
        return 0;
    };

    if ($is_shared->($jid) && $is_shared->($contact_jid)) {
        my $both = DJabberd::Subscription->new;
        $both->set_from;
        $both->set_to;
        my $rit = DJabberd::RosterItem->new(jid  => $contact_jid,
                                            subscription => $both);
        $cb->set($rit);
        return;
    }

    $self->SUPER::load_roster_item($jid, $contact_jid, $cb);
}

=head1 COPYRIGHT & LICENSE

Original work Copyright 2006 Alexander Karelas, Martin Atkins, Brad Fitzpatrick and Aleksandar Milanov. All rights reserved.
Copyright 2007 Edward Rudd. All rights reserved. 
 
This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself. 

=cut

1;
