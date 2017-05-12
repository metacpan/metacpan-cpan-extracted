#!/usr/bin/env perl

#############################################
##                                         ##
## notify_expiring_members.pl              ##
##                                         ## 
## Perl script to send email to Members of ##
## a Drupal website when their Membership  ##
## is getting close to expiration.         ##
##                                         ##
## See notify_expiring_members.README      ##
##                                         ##
#############################################

use strict;
use warnings;

use Cwd qw/ realpath /;
use Config::Tiny;
use POSIX qw/ strftime /;
use DBI;
use DBD::mysql;
use MIME::Lite::TT;
use Carp;

my $path = realpath($0);
$path =~ s/\/notify_expiring_members\.pl$//x;

my $conf = Config::Tiny->new;
$conf    = Config::Tiny->read( "$path/notify_expiring_members.config" )
             or croak("Died: Config:" . Config::Tiny->errstr); 

my $DEBUG = $conf->{'program'}->{'debug'};

print("\nInitializing at " . strftime("%F %T", localtime $^T) . "\n");
$DEBUG > 0 && print("Running in DEBUG mode.\n");

my $dsn = "dbi:mysql:" . join( ';', $conf->{'database'}->{'database'},
                                    $conf->{'database'}->{'host'},
                                    $conf->{'database'}->{'port'} );

my $dbh = DBI->connect( $dsn,
                        $conf->{'database'}->{'user'},
                        $conf->{'database'}->{'password'},
                        { RaiseError => 1 } );

## nested subselect because a user may have a Membership Term that is about
## to expire but already have another active one ready to begin

my $sql = <<"end_of_sql";

SELECT
  active.uid   AS uid,
  active.user  AS user,
  active.email AS email,
  active.name  AS name,
  DATE_FORMAT(active.end_date, '%W, %M %D, %Y') AS end_date
FROM
  (
   SELECT
     users.uid  AS uid,
     users.name AS user,
     users.mail AS email,
     field_data_field_first_name.field_first_name_value AS name,
     MAX(membership_entity_term.end) AS end_date
   FROM
     membership_entity_term
   INNER JOIN
     membership_entity
    ON
     membership_entity.mid = membership_entity_term.mid
   LEFT JOIN
     users
    ON
     users.uid = membership_entity.uid
   LEFT JOIN
     field_data_field_first_name
    ON
     field_data_field_first_name.entity_id = membership_entity.uid
   WHERE
     membership_entity_term.status IN  ('0', '1')
   GROUP BY users.uid, membership_entity.type
  )
  AS active
WHERE
  DATEDIFF(end_date, CURRENT_DATE) = ?  

end_of_sql

my $query = $dbh->prepare($sql);

foreach my $num_days($DEBUG > 2 ? (1..31) : (sort {$a <=> $b} keys %{ $conf->{'notifications'} })) {
 
  print("  ", "-" x 62, "\n"); 
  print("  Processing for $num_days ...\n");

  $query->execute($num_days);
  while (my $row = $query->fetchrow_hashref) {
    
    print "    $row->{'uid'} $row->{'user'} $row->{'end_date'}\n";

    my %template_options = ();
    my %template_params  = (
                             'name'         => $row->{'name'},
                             'organization' => $conf->{'organization'}->{'long_name'},
                             'date'         => $row->{'end_date'},
                             'website'      => $conf->{'organization'}->{'website'},
                             'user'         => $row->{'user'},
                             'signature'    => $conf->{'email'}->{'signature'},
                           );
    
    my $msg = MIME::Lite::TT->new(
            'From'        => $conf->{'email'}->{'sender'},
            'To'          => $row->{'email'},
            'CC'          => $conf->{'email'}->{'copy_to'},
            'Subject'     => "$row->{'user'}, your $conf->{'organization'}->{'short_name'} Membership " .
                               ($num_days < 1 ? "expired " : "expires in ") .
                               abs($num_days) . " " . (abs($num_days) == 1 ? "day" : "days") .
                               ($num_days < 1 ? " ago" : ""),
            'Template'    => join('/', $path, $conf->{'notifications'}->{ $DEBUG > 2 ? 7 : $num_days }),
            'TmplOptions' => \%template_options,
            'TmplParams'  => \%template_params,
     ) or croak($!);

     print("      Sending email ...");
     $DEBUG > 1 && $msg->print();

     unless ($DEBUG) { $msg->send() or croak($!); }

     print(" email sent." . ($DEBUG > 0 ? " (Not really. We're debugging.)\n" : "\n"));
  }
  print("  Finished.\n");
}
print("  ", "-" x 62, "\n");
print("Finished at " . strftime("%F %T", localtime $^T) . ".\n");
print("#" x 64, "\n");

exit 1;

=pod

=head1 SYNOPSIS

This is a Perl program to automate sending reminder notifications via email to 
Members of a Drupal website whose Membership is soon to expire. It works with
the Membership Entity Drupal contributed modules, which do not, as of 12/3/2014,
expose expiration dates to work with Drupal Rules.

The program uses an external configuration file for setting options and the Perl
Template Toolkit to keep the content of the notification emails out of the 
program code. You will have to edit the configuration file, and may edit the 
templates to customize your reminder notifications, but you don't have to edit 
any code or even know anything about it to use this program.

To repeat: you will have to copy notify_expiring_members.config.sample to 
notify_expiring_members.config and then edit it. But you can use the provided 
template files out of the box if you wish.

=head1 CONTENTS

This program should have been distributed with the following files:

    notify_expiring_member.pl               <- the script, must be executable
    notify_expiring_members.config.sample   <- sample config file
    initial.notification                    <- sample notification template
    final.notification                      <- sample notification template
    notify_expiring_members.README          <- documentation; this file

=head1 INSTALLATION

Copy the files in this distribution to a directory where you have permission to
execute files. If you download and unpack the .tar.gz archive, it will create
create a directory called notify_expiring_members in which all the files will be
placed.

Copy the file notify_expiring_members.config.sample to
notify_expiring_members.config and then configure for your system.

Set a daily cron job to run the script.

=head2 Dependencies

This program depends on the following Perl modules:
 
L<DBI>

L<DBD::mysql>

L<Config::Tiny>

L<MIME::Lite::TT>
 
The modules listed above have other dependencies, including L<MIME::Lite> and
L<Template::Toolkit>, but these are installed on most shared hosting servers.
L<MIME::Lite::TT> and L<Config::Tiny> do not require compilation so you should be
able to install them in your local Perl lib directory even without root access.

=head1 USAGE

=head2 Configuration
 
This program stores all its configuration information in the file
notify_expiring_members.config . The file is in the .ini format, like so:
 
B<[section]>

conf_option = value

Note that no comments are allowed in the config file.

The following are the configuration options:

----------------------------------------------------

B<[program]>

debug      = switch to output debugging data at runtime

B<[database]>

database   = your database name

host       = the host your database runs on
               (leave blank to use localhost)

port       = the port your database listens on
               (leave blank to use 3306)

user       = the database user
               (leave blank if MySQL uses your system username)

password   = the database password for the database user
               (leave blank if none)

B<[organization]>

short_name = short name for your organization used in email Subject

long_name  = long name for your organization used in email body

website    = URL of the website to which the Member has a Membership

B<[email]>

sender     = the email address from which to send notifications

signature  = a one-line signature appended to email body

copy_to    = a comma-separated list of email addresses to cc

B<[notifications]>

n          = /path/to/template (where the email sent to Members with
               n days remaining will be created with the named 
               template)

-------------------------------

B<A note about [notifications]>

You can send reminder notifications on any number of days before Membership
expiration. For each number of days before expiration for which you want the
program to search for soon-to-expire Members, you must include a configuration
option in the [notifications] section. The option name should be the number of
days and the value should be the path to the template file to be used. You can
use a negative number for the number of days if you want to send a notification
after expiration has occurred.

You can create a different notification template for each number of days on
which notification is to be sent, or you can use the same template for more than
one notification. For example, my config file contains this:

B<[notifications]>

31 = initial.notification

14 = initial.notification

7  = initial.notification

1  = final.notification

-2 = expired.notification

=head2 Templates

The values for the options in the [notifications] section of the config file
are the paths to the template files. You can name the files anything and put
them anywhere so long as the path is valid and the file is readable.

The template is used by the program to build the notification email. It
contains tokens so that you don't have to edit the script code. The following
tokens are available for use in the templates:

[% name %]         The first name of the Member
                   (from the database)

[% organization %] The name of the organization to which the Member belongs
                   (from the config file)

[% date %]         The date on which the Membership will expire
                   (from the database)

[% website %]      The URL of the website to which the Member belongs
                   (from the config file)

[% user %]         The user name of the Member on the Drupal site
                   (from the database)

[% signature %]    The signature of the sender of the notification
                   (from the config file)

=head2 Logging/Error checking

The program prints a report as it goes, so if you direct the output of
the program to a file, it will effectively serve as a log. If you are 
running it from cron, do something like this:

32 3 * * * /path/to/notify_expiring_members.pl >> /path/to/your.log

The output of the program that will be logged looks like this: 

################################################################

Initializing at 2015-06-07 03:32:01
  --------------------------------------------------------------
  Processing for 1 ...
    12855 rastus Monday, June 8th, 2015
      Sending email ... email sent.
    11678 user007 Monday, June 8th, 2015
      Sending email ... email sent.
  Finished.
  --------------------------------------------------------------
  Processing for 7 ...
  Finished.
  --------------------------------------------------------------
  Processing for 14 ...
    13067 smcleod Sunday, June 21st, 2015
      Sending email ... email sent.
  Finished.
  --------------------------------------------------------------
  Processing for 31 ...
  Finished.
  --------------------------------------------------------------
Finished at 2015-06-07 03:32:01.
################################################################

Of course you can always include yourself on the list of copy_to email 
addresses in the configuration file, so that you see all the emails
that the program sends.

=head1 SUPPORT

At the moment you can get support for this program at
http://tinyurl.com/wbs-nem (the author's blog) or at the Drupal.org
thread https://www.drupal.org/node/2385155

=head1 AUTHOR

Nick Tonkin <nick@websitebackendsolutions.com>

=head1 COPYRIGHT

Copyright 2014-2015 and All Rights Reserved Nick Tonkin. You may use this
software freely and may redistribute it as long as the AUTHOR and COPYRIGHT
sections of this file are not removed or changed.

