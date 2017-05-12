package Carp::Mailer;

# Copyright (C) 2006 Igor Sutton Lopes <igor@izut.com>
#  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#  
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#  

use strict;
use warnings;
use Carp;
use Data::Dumper;
use File::Spec;
use Mail::Mailer;
use Text::Template;

our $VERSION = 0.1;

my $application = undef;
my $body = <<'EOM'
An error occurred while executing {$application}:

{$message}
EOM
;
my $method = 'sendmail';
my $recipients = undef;
my $relay = undef;
my $subject = "An error occurred when executing %s";

sub import {
    my ($class, %options) = @_;

    $subject = $options{'subject'} if exists $options{'subject'};
    $body = $options{'body'} if exists $options{'body'};
    $recipients = $options{'recipients'} if exists $options{'recipients'};
    $method = $options{'method'} if exists $options{'method'};
    $relay = $options{'relay'} if exists $options{'relay'};
    $application = File::Spec->rel2abs($0);

    if ($method eq 'smtp' and not defined $relay) {
        croak "Can't use method 'smtp' without define 'relay'.";
    }

    if (scalar @$recipients == 0) {
        croak "Please specify at least one recipient.";
    }
}

sub _dispatch_message {
    my ($message) = @_;
    my $mailer = undef;

    $mailer = new Mail::Mailer(
        $method, 
        ($method eq 'smtp' ? 
            $relay : undef));

    $mailer->open({
            'To' => $recipients,
            'Subject' => sprintf($subject, $application),
        });

    my $template = new Text::Template(
        TYPE => 'STRING', 
        SOURCE => $body
    );

    print $mailer $template->fill_in(HASH => {
            application => $application,
            message => $message,
        });

    $mailer->close;
}

$SIG{__DIE__}  = \&_dispatch_message;
$SIG{__WARN__} = \&_dispatch_message;

__END__

=head1 NAME

Carp::Mailer - Traps die and warn signals and dispatch emails to someone.

=head1 AUTHOR

Igor Sutton Lopes <igor@izut.com>

=head1 SYNOPSIS

Use it to notify someone if an error occurrs in your application.

 use Carp::Mailer (
    recipients => [qw/igor@izut.com/],
    subject    => "%s execution had errors! Check it!",
 )

=head1 REQUIRES

Text::Template, Mail::Mailer

=head1 DESCRIPTION

Carp::Mailer is an error reporting module. It will trap any C<warn> or
C<die> signals and then dispatch an email to specified recipients the 
message the signal threw.

=head1 OPTIONS

=over

=item recipients

Must be a list reference to all recipients the errors should be sent.

Example

 use Carp::Mailer (
   recipients => [qw/first@domain.com second@domain.com/],
 );

=item subject

The format of the subject the message will have. The placeholder C<%s> will be
substituted by the application's file path.

Example

 use Carp::Mailer (
   subject => "An error occurred when executing %s";
 );

=item body

The format of the body the message will have. At this time, it's available only 
C<{$application}> and C<{$message}> placeholders.

Example

 use Carp::Mailer (
   message => 'An error occurred while executing {$application}:\n\n{$message}',
 );

=item method

The method Mail::Mailer will use to deliver the messages. Check Mail::Mailer 
documentation to check the available methods.

Example

 use Carp::Mailer (
   method => 'sendmail',
 );

=item relay

This option is used if the method option was set as I<smtp>. It specifies the
mail relay server Mail::Mailer will use to deliver the messages.

Example

 use Carp::Mailer (
   method => 'smtp',
   relay => 'mail.domain.com',
 );

=back
