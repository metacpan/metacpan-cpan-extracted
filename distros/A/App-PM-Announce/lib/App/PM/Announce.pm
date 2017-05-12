package App::PM::Announce;

use warnings;
use strict;

=head1 NAME

App::PM::Announce - Announce your PM meeting via Meetup and LinkedIn

=head1 VERSION

Version 0.025

=cut

our $VERSION = '0.025';

use Moose;
#with 'MooseX::LogDispatch';

use File::HomeDir;
use Path::Class;
use Config::JFDI;
use Config::General;
use String::Util qw/trim/;
use Data::UUID;
use Document::TriPart;
use DateTimeX::Easy;
use Log::Dispatch;
use Log::Dispatch::Screen;
use Log::Dispatch::File;

use App::PM::Announce::History;
use App::PM::Announce::Feed::meetup;
use App::PM::Announce::Feed::linkedin;
use App::PM::Announce::Feed::greymatter;
use App::PM::Announce::Feed::useperl;

sub BUILD {
    my $self = shift;
    $self->startup;
}

has debug => qw/is ro lazy_build 1/;
sub _build_debug {
    return $ENV{APP_PM_ANNOUNCE_DEBUG} ? 1 : 0;
}

has verbose => qw/is ro lazy_build 1/;
sub _build_verbose {
    return 0;
}

has dry_run => qw/is ro lazy_build 1/;
sub _build_dry_run {
    return 0;
}

has home_dir => qw/is ro lazy_build 1/;
sub _build_home_dir {
    my @home_dir;
    @home_dir = map { exists $ENV{$_} && defined $ENV{$_} ? $ENV{$_} : () } qw/APP_PM_ANNOUNCE_HOME/; # Don't want to write $ENV{...} twice
    @home_dir = ( File::HomeDir->my_data, '.app-pm-announce' ) unless @home_dir;
    return dir( @home_dir );
}

has config_file => qw/is ro lazy_build 1/;
sub _build_config_file {
    return shift->home_dir->file( 'config' );
}

has config_default => qw/is ro isa HashRef lazy_build 1/;
sub _build_config_default {
    return {};
}

#has _config => qw/is ro isa Config::JFDI lazy_build 1/;
#sub _build__config {
#    my $self = shift;
#    return Config::JFDI->new(file => $self->config_file);
#}

#sub config {
#    return shift->_config->get;
#}

has config => qw/is ro isa HashRef lazy_build 1/;
sub _build_config {
    my $self = shift;
    if ($self->config_file) {
        return { Config::General->new(
            -ConfigFile => $self->config_file,
        )->getall };
    }
    else {
        return $self->config_default,
    }
}

has log_file => qw/is ro lazy_build 1/;
sub _build_log_file {
    return shift->home_dir->file( 'log' );
}

has logger => qw/is ro isa Log::Dispatch lazy_build 1/;
sub _build_logger {
    my $self = shift;
    my $logger = Log::Dispatch->new( callbacks => sub {
        my $message = join ' ',
                "[@{[ DateTime->now->set_time_zone( 'local' ) ]}]",
                "[$_[3]]",
                "$_[1]\n",
        ;
#        $message = "# $message" if $_[3] eq 'debug';
        return $message;
    } );
    $logger->add( Log::Dispatch::Screen->new( name => 'screen', min_level => $self->debug ? 'debug' : 'info', stderr => 1 ) ) if $self->debug;
#    $logger->add( Log::Dispatch::File->new( name => 'file', mode => 'append', min_level => 'info', filename => $self->log_file.'' ) );
    return $logger;
}

has feed => qw/is ro isa HashRef lazy_build 1/;
sub _build_feed {
    my $self = shift;
    return { 
        meetup => $self->_build_meetup_feed,
        linkedin => $self->_build_linkedin_feed,
        greymatter => $self->_build_greymatter_feed,
        useperl => $self->_build_useperl_feed,
    };
}

sub _build_meetup_feed {
    my $self = shift;
    return undef unless my $given = $self->config->{feed}->{meetup};
    return App::PM::Announce::Feed::meetup->new(
        app => $self,
        username => $given->{username},
        password => $given->{password},
        uri => $given->{uri},
        venue => $given->{venue},
    );
}

sub _build_linkedin_feed {
    my $self = shift;
    return undef unless my $given = $self->config->{feed}->{linkedin};
    return App::PM::Announce::Feed::linkedin->new(
        app => $self,
        username => $given->{username},
        password => $given->{password},
        uri => $given->{uri},
    );
}

sub _build_greymatter_feed {
    my $self = shift;
    return undef unless my $given = $self->config->{feed}->{greymatter};
    return App::PM::Announce::Feed::greymatter->new(
        app => $self,
        username => $given->{username},
        password => $given->{password},
        uri => $given->{uri},
    );
}

sub _build_useperl_feed {
    my $self = shift;
    return undef unless my $given = $self->config->{feed}->{useperl};
    return App::PM::Announce::Feed::useperl->new(
        app => $self,
        username => $given->{username},
        password => $given->{password},
        promote => $given->{promote},
    );
}

has history => qw/is ro isa App::PM::Announce::History lazy_build 1/;
sub _build_history {
    my $self = shift;
    return App::PM::Announce::History->new( app => $self );
}

sub startup {
    my $self = shift;

    $self->logger->debug( "debug = " . $self->debug );
    $self->logger->debug( "verbose = " . $self->verbose );
    $self->logger->debug( "dry-run = " . $self->dry_run );

    my $home_dir = $self->home_dir;
    $self->logger->debug( "home_dir = $home_dir" );

    unless (-d $home_dir) {
        $self->logger->debug( "Making $home_dir because it does not exist" );
        $home_dir->mkpath;
    }

    # Gotta do this here
    $self->logger->add( Log::Dispatch::File->new( name => 'file', mode => 'append', min_level => 'info', filename => $self->log_file.'' ) );

    my $log_file = $self->log_file;
    $self->logger->debug( "log_file = $log_file" );

    my $config_file = $self->config_file;
    if (defined $config_file) {
        $self->logger->debug( "config_file = $config_file" );

        unless (-f $config_file) {
            $self->logger->debug( "Making $config_file stub because it does not exist" );
            $config_file->openw->print( <<_END_ );
# vim: set filetype=configgeneral:

# Replace 'An-Example-Group' with the real resource for your Meetup group
# Replace <venue> with the venue number you want to be the default

#<feed meetup>
#    username
#    password
#    uri http://www.meetup.com/An-Example-Group/calendar/?action=new
#    venue <venue>
#</feed>

# Replace <gid> with the gid of your group

#<feed linkedin>
#    username
#    password
#    uri http://www.linkedin.com/groupAnswers?start=&gid=<gid>
#</feed>

# Replace 'example.com' with a real host

#<feed greymatter>
#    username
#    password
#    uri http://example.com/cgi-bin/greymatter/gm.cgi
#</feed>

#<feed useperl>
#    username
#    password
#</feed>

_END_
        }
    }
}



sub announce {
    my $self = shift;
    my %event;
    if (ref $_[0]) {
        my $document = $self->parse( @_ );
        %event = %{ $document->header };
        $event{description} = $document->body;
    }
    else {
        %event = @_;
    }

    { # Validate, parse, and filter.

        $event{$_} = trim $event{$_} for qw/title venue/;

        die "Wasn't given a UUID for the event\n" unless $event{uuid};

        die "Wasn't given a title for the event\n" unless $event{title};

#        die "Wasn't given a venue for the event\n" unless $event{venue};

        die "Wasn't given a date & time for the event\n" unless $event{datetime};
        die "The date & time isn't a DateTime object\n" unless $event{datetime}->isa( 'DateTime' );
    }

    my (@report, $event, $result);
    my $uuid = $event{uuid};
    $event = $self->history->find_or_insert( $uuid )->{data};
    $self->history->update( $uuid => %event );

    eval {
        if ($event->{did_meetup}) {
            $self->logger->debug( "Already posted to meetup, skipping" );
            $self->logger->debug( "The Meetup link is " . $event->{meetup_link} ) if $event->{meetup_link};
            push @report, "Already announced on meetup";
        }
        elsif ($self->feed->{meetup}) {
            unless ($self->dry_run) {
                die "Didn't announce on meetup" unless $result = $self->feed->{meetup}->announce( %event );
                my $meetup_link = $event->{meetup_link} = $result->{meetup_link};
                $self->logger->debug( "Meetup link is " . $meetup_link );
                $self->logger->info( "\"$event{title}\" ($uuid) announced to meetup ($meetup_link) " );
                $self->history->update( $uuid => did_meetup => 1, meetup_link => "$meetup_link" );
                push @report, "Announced on meetup";
            }
            else {
                push @report, "Would announce on meetup";
            }
        }
        else {
            $self->logger->debug( "No feed configured for meetup" );
        }

        die "Don't have a Meetup link" unless $self->dry_run || $event->{meetup_link};

#        $event{description} = [
#            $event{description},
#            "\nRSVP at Meetup - <a href=\"$event->{meetup_link}\">$event->{meetup_link}</a>"
#        ];

        if ($event->{did_linkedin}) {
            $self->logger->debug( "Already posted to linkedin, skipping" );
            push @report, "Already announced on linkedin";
        }
        elsif ($self->feed->{linkedin}) {
            unless ($self->dry_run) {
                die "Didn't announce on linkedin" unless $result = $self->feed->{linkedin}->announce(
                    %event,
                    description => [
                        $event{description},
                        "RSVP at Meetup - $event->{meetup_link}",
                    ],
                );
                $self->logger->info( "\"$event{title}\" ($uuid) announced to linkedin" );
                $result = $self->history->update( $uuid => did_linkedin => 1 );
                push @report, "Announced on linkedin";
            }
            else {
                push @report, "Would announce on linkedin";
            }
        }
        else {
            $self->logger->debug( "No feed configured for linkedin" );
        }

        if ($event->{did_greymatter}) {
            $self->logger->debug( "Already posted to greymatter, skipping" );
            push @report, "Already announced on greymatter";
        }
        elsif ($self->feed->{greymatter}) {
            unless ($self->dry_run) {
                die "Didn't announce on greymatter" unless $result = $self->feed->{greymatter}->announce(
                    %event,
                    description => [
                        $event{description},
                        "\nRSVP at Meetup - <a href=\"$event->{meetup_link}\">$event->{meetup_link}</a>"
                    ],
                );
                $self->logger->info( "\"$event{title}\" ($uuid) announced to greymatter" );
                $result = $self->history->update( $uuid => did_greymatter => 1 );
                push @report, "Announced on greymatter";
            }
            else {
                push @report, "Would announce on greymatter";
            }
        }
        else {
            $self->logger->debug( "No feed configured for greymatter" );
        }

        if ($event->{did_useperl}) {
            $self->logger->debug( "Already posted to useperl, skipping" );
            push @report, "Already announced on useperl";
        }
        elsif ($self->feed->{useperl}) {
            unless ($self->dry_run) {
                die "Didn't announce on useperl" unless $result = $self->feed->{useperl}->announce(
                    %event,
                    description => [
                        $event{description},
                        "\nRSVP at Meetup - <a href=\"$event->{meetup_link}\">$event->{meetup_link}</a>"
                    ],
                );
                $self->logger->info( "\"$event{title}\" ($uuid) announced to useperl" );
                $result = $self->history->update( $uuid => did_useperl => 1 );
                push @report, "Announced on useperl";
            }
            else {
                push @report, "Would announce on useperl";
            }
        }
        else {
            $self->logger->debug( "No feed configured for useperl" );
        }
    };
    if ($@) {
        warn "Unable to announce \"$event{title}\" ($uuid)\n";
        die $@;
    }

    $event = $self->history->fetch( $uuid )->{data};
#    $self->logger->info("\"$event{title}\" is announced on", join ', ', map { $event->{"did_$_"} ? $_ : () } qw/meetup linkedin greymatter/);
#    $self->logger->info("Meetup link is $event->{meetup_link}") if $event->{meetup_link};

    return $event, \@report;
    
#    $result{done} = 1;
#    return \%result;
}

use Data::Dump qw/dd pp/;
sub parse {
    my $self = shift;

    die "Couldn't parse" unless my $document = Document::TriPart->read(shift);

    my $datetime = $document->header->{datetime};
    die "You didn't give a datetime" unless $datetime;
    die "Unable to parse ", $document->header->{datetime} unless $datetime = DateTimeX::Easy->parse( $datetime );
    $document->header->{datetime} = $datetime;

    return $document;
}

sub template {
    my $self = shift;
    my %given = @_;

    my $uuid = Data::UUID->new->create_str;
    my $datetime = DateTimeX::Easy->parse( '4th tuesday' );
    my $venue = $self->config->{venue} || '';
    $datetime = DateTimeX::Easy->parse( '3rd tuesday' ) unless $datetime;
    $datetime->set(hour => 20, minute => 0, second => 0);

    return <<_END_;
# App-PM-Announce
# You can leave 'venue' blank to use the default venue (per @{[ $self->config_file ]})
# The 'datetime' field is the date & time that the event will take place. Any reasonable string should do (parsed via DateTimeX::Easy)
---
title: The title of the event
venue: $venue
datetime: $datetime
image: $given{image}
uuid: $uuid
---
Put your multi-line description for the event here.
Everything below the '---' is considered the description.
_END_
}

=head1 SYNOPSIS

    # Initialize and edit the config (only need to do this once)
    pm-announce config edit
    
    # Generate a template for the event
    pm-announce template > event.txt

    # Edit event.txt with your editor of choice...

    # Announce the event
    pm-announce announce < event.txt

=head1 DESCRIPTION

App::PM::Announce is a tool for creating and advertising PM meetings (on Meetup, LinkedIn, and blog software)

            -v, -d,  --verbose  Debugging mode. Be verbose when reporting
            -h, -?,  --help     This help screen

        config              Check the config file ($HOME/.app-pm-announce/config)

        config edit             Edit the config file using $EDITOR

        history                 Show announcement history

        history <query>         Show announcement history for event <query>, where <query> should be enough of the uuid to be unambiguous

        template                Print out a template to be used for input to the 'announce' command

            --image <image>     Attach <image> (can be either a local file or remote URL) to the Meetup event

        announce                Read STDIN for the event information and make a post for each feed

            -n, --dry-run       Don't actually login and announce, just show what would be done

        test                    Post a bogus event to a test meetup account, test linkedin account, and test greymatter account

        help                    This help screen

=cut

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-pm-announce at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-PM-Announce>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::PM::Announce


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-PM-Announce>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-PM-Announce>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-PM-Announce>

=item * Search CPAN

L<http://search.cpan.org/dist/App-PM-Announce/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of App::PM::Announce
