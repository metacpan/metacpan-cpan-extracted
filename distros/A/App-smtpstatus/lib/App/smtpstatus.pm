package App::smtpstatus;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.07'; # VERSION

# from RFC 1893

our $data = [

    ['2.X.X', 'Success',

         'Success specifies that the DSN is reporting a positive delivery
          action.  Detail sub-codes may provide notification of
          transformations required for delivery.'

     ],

    ['4.X.X', 'Persistent Transient Failure',

         'A persistent transient failure is one in which the message as
          sent is valid, but some temporary event prevents the successful
          sending of the message.  Sending in the future may be successful.'

     ],

    ['5.X.X', 'Permanent Failure',

         'A permanent failure is one which is not likely to be resolved by
          resending the message in the current form.  Some change to the
          message or the destination must be made for successful delivery.'

     ],

    ['X.0.X', 'Other or Undefined Status',

         'There is no additional subject information available.'

     ],

    ['X.1.X', 'Addressing Status',

         'The address status reports on the originator or destination
          address.  It may include address syntax or validity.  These
          errors can generally be corrected by the sender and retried.'

     ],

    ['X.2.X', 'Mailbox Status',

         'Mailbox status indicates that something having to do with the
          mailbox has cause this DSN.  Mailbox issues are assumed to be
          under the general control of the recipient.'

     ],

    ['X.3.X', 'Mail System Status',

         'Mail system status indicates that something having to do
          with the destination system has caused this DSN.  System
          issues are assumed to be under the general control of the
          destination system administrator.'

     ],

    ['X.4.X', 'Network and Routing Status',

         'The networking or routing codes report status about the
          delivery system itself.  These system components include any
          necessary infrastructure such as directory and routing
          services.  Network issues are assumed to be under the
          control of the destination or intermediate system
          administrator.'

     ],

    ['X.5.X', 'Mail Delivery Protocol Status',

         'The mail delivery protocol status codes report failures
          involving the message delivery protocol.  These failures
          include the full range of problems resulting from
          implementation errors or an unreliable connection.  Mail
          delivery protocol issues may be controlled by many parties
          including the originating system, destination system, or
          intermediate system administrators.'

     ],

    ['X.6.X', 'Message Content or Media Status',

         'The message content or media status codes report failures
          involving the content of the message.  These codes report
          failures due to translation, transcoding, or otherwise
          unsupported message media.  Message content or media issues
          are under the control of both the sender and the receiver,
          both of whom must support a common set of supported
          content-types.'

     ],

    ['X.7.X', 'Security or Policy Status',

         'The security or policy status codes report failures
          involving policies such as per-recipient or per-host
          filtering and cryptographic operations.  Security and policy
          status issues are assumed to be under the control of either
          or both the sender and recipient.  Both the sender and
          recipient must permit the exchange of messages and arrange
          the exchange of necessary keys and certificates for
          cryptographic operations.'

     ],

    ['X.0.0', 'Other undefined Status',

         'Other undefined status is the only undefined error code. It
          should be used for all errors for which only the class of the
          error is known.'

     ],

    ['X.1.0', 'Other address status',

         'Something about the address specified in the message caused
          this DSN.'

     ],

    ['X.1.1', 'Bad destination mailbox address',

         'The mailbox specified in the address does not exist.  For
          Internet mail names, this means the address portion to the
          left of the "@" sign is invalid.  This code is only useful
          for permanent failures.'

     ],

    ['X.1.2', 'Bad destination system address',

         'The destination system specified in the address does not
          exist or is incapable of accepting mail.  For Internet mail
          names, this means the address portion to the right of the
          "@" is invalid for mail.  This codes is only useful for
          permanent failures.'

     ],

    ['X.1.3', 'Bad destination mailbox address syntax',

         'The destination address was syntactically invalid.  This can
          apply to any field in the address.  This code is only useful
          for permanent failures.'

     ],

    ['X.1.4', 'Destination mailbox address ambiguous',

         'The mailbox address as specified matches one or more
          recipients on the destination system.  This may result if a
          heuristic address mapping algorithm is used to map the
          specified address to a local mailbox name.'

     ],

    ['X.1.5', 'Destination address valid',

         'This mailbox address as specified was valid.  This status
          code should be used for positive delivery reports.'

     ],

    ['X.1.6', 'Destination mailbox has moved, No forwarding address',

         'The mailbox address provided was at one time valid, but mail
          is no longer being accepted for that address.  This code is
          only useful for permanent failures.'

     ],

    ['X.1.7', q[Bad sender's mailbox address syntax],

         q[The sender's address was syntactically invalid.  This can
          apply to any field in the address.]

     ],

    ['X.1.8', q[Bad sender's system address],

         q[The sender's system specified in the address does not exist
          or is incapable of accepting return mail.  For domain names,
          this means the address portion to the right of the "@" is
          invalid for mail.]

     ],

    ['X.2.0', 'Other or undefined mailbox status',

         'The mailbox exists, but something about the destination
          mailbox has caused the sending of this DSN.'

     ],

    ['X.2.1', 'Mailbox disabled, not accepting messages',

         'The mailbox exists, but is not accepting messages.  This may
          be a permanent error if the mailbox will never be re-enabled
          or a transient error if the mailbox is only temporarily
          disabled.'

     ],

    ['X.2.2', 'Mailbox full',

         'The mailbox is full because the user has exceeded a
          per-mailbox administrative quota or physical capacity.  The
          general semantics implies that the recipient can delete
          messages to make more space available.  This code should be
          used as a persistent transient failure.'

     ],

    ['X.2.3', 'Message length exceeds administrative limit',

         'A per-mailbox administrative message length limit has been
          exceeded.  This status code should be used when the
          per-mailbox message length limit is less than the general
          system limit.  This code should be used as a permanent
          failure.'

     ],

    ['X.2.4', 'Mailing list expansion problem',

         'The mailbox is a mailing list address and the mailing list
          was unable to be expanded.  This code may represent a
          permanent failure or a persistent transient failure.'

     ],

    ['X.3.0', 'Other or undefined mail system status',

         'The destination system exists and normally accepts mail, but
          something about the system has caused the generation of this
          DSN.'

     ],

    ['X.3.1', 'Mail system full',

         'Mail system storage has been exceeded.  The general
          semantics imply that the individual recipient may not be
          able to delete material to make room for additional
          messages.  This is useful only as a persistent transient
          error.'

     ],

    ['X.3.2', 'System not accepting network messages',

         'The host on which the mailbox is resident is not accepting
          messages.  Examples of such conditions include an immanent
          shutdown, excessive load, or system maintenance.  This is
          useful for both permanent and permanent transient errors.'

     ],

    ['X.3.3', 'System not capable of selected features',

         'Selected features specified for the message are not
          supported by the destination system.  This can occur in
          gateways when features from one domain cannot be mapped onto
          the supported feature in another.'

     ],

    ['X.3.4', 'Message too big for system',

         'The message is larger than per-message size limit.  This
          limit may either be for physical or administrative reasons.
          This is useful only as a permanent error.'

     ],

    ['X.3.5', 'System incorrectly configured',

         'The system is not configured in a manner which will permit
          it to accept this message.'

     ],

    ['X.4.0', 'Other or undefined network or routing status',

         'Something went wrong with the networking, but it is not
          clear what the problem is, or the problem cannot be well
          expressed with any of the other provided detail codes.'

     ],

    ['X.4.1', 'No answer from host',

         'The outbound connection attempt was not answered, either
          because the remote system was busy, or otherwise unable to
          take a call.  This is useful only as a persistent transient
          error.'

     ],

    ['X.4.2', 'Bad connection',

         'The outbound connection was established, but was otherwise
          unable to complete the message transaction, either because
          of time-out, or inadequate connection quality. This is
          useful only as a persistent transient error.'

     ],

    ['X.4.3', 'Directory server failure',

         'The network system was unable to forward the message,
          because a directory server was unavailable.  This is useful
          only as a persistent transient error.

          The inability to connect to an Internet DNS server is one
          example of the directory server failure error.'

     ],

    ['X.4.4', 'Unable to route',

         'The mail system was unable to determine the next hop for the
          message because the necessary routing information was
          unavailable from the directory server. This is useful for
          both permanent and persistent transient errors.

          A DNS lookup returning only an SOA (Start of Administration)
          record for a domain name is one example of the unable to
          route error.'

     ],

    ['X.4.5', 'Mail system congestion',

         'The mail system was unable to deliver the message because
          the mail system was congested. This is useful only as a
          persistent transient error.'

     ],

    ['X.4.6', 'Routing loop detected',

         'A routing loop caused the message to be forwarded too many
          times, either because of incorrect routing tables or a user
          forwarding loop. This is useful only as a persistent
          transient error.'

     ],

    ['X.4.7', 'Delivery time expired',

         'The message was considered too old by the rejecting system,
          either because it remained on that host too long or because
          the time-to-live value specified by the sender of the
          message was exceeded. If possible, the code for the actual
          problem found when delivery was attempted should be returned
          rather than this code.  This is useful only as a persistent
          transient error.'

     ],

    ['X.5.0', 'Other or undefined protocol status',

         'Something was wrong with the protocol necessary to deliver
          the message to the next hop and the problem cannot be well
          expressed with any of the other provided detail codes.'

     ],

    ['X.5.1', 'Invalid command',

         'A mail transaction protocol command was issued which was
          either out of sequence or unsupported.  This is useful only
          as a permanent error.'

     ],

    ['X.5.2', 'Syntax error',

         'A mail transaction protocol command was issued which could
          not be interpreted, either because the syntax was wrong or
          the command is unrecognized. This is useful only as a
          permanent error.'

     ],

    ['X.5.3', 'Too many recipients',

         'More recipients were specified for the message than could
          have been delivered by the protocol.  This error should
          normally result in the segmentation of the message into two,
          the remainder of the recipients to be delivered on a
          subsequent delivery attempt.  It is included in this list in
          the event that such segmentation is not possible.'

     ],

    ['X.5.4', 'Invalid command arguments',

         'A valid mail transaction protocol command was issued with
          invalid arguments, either because the arguments were out of
          range or represented unrecognized features. This is useful
          only as a permanent error.'

     ],

    ['X.5.5', 'Wrong protocol version',

         'A protocol version mis-match existed which could not be
          automatically resolved by the communicating parties.'

     ],

    ['X.6.0', 'Other or undefined media error',

         'Something about the content of a message caused it to be
          considered undeliverable and the problem cannot be well
          expressed with any of the other provided detail codes.'

     ],

    ['X.6.1', 'Media not supported',

         'The media of the message is not supported by either the
          delivery protocol or the next system in the forwarding path.
          This is useful only as a permanent error.'

     ],

    ['X.6.2', 'Conversion required and prohibited',

         'The content of the message must be converted before it can
          be delivered and such conversion is not permitted.  Such
          prohibitions may be the expression of the sender in the
          message itself or the policy of the sending host.'

     ],

    ['X.6.3', 'Conversion required but not supported',

         'The message content must be converted to be forwarded but
          such conversion is not possible or is not practical by a
          host in the forwarding path.  This condition may result when
          an ESMTP gateway supports 8bit transport but is not able to
          downgrade the message to 7 bit as required for the next hop.'

     ],

    ['X.6.4', 'Conversion with loss performed',

         'This is a warning sent to the sender when message delivery
          was successfully but when the delivery required a conversion
          in which some data was lost.  This may also be a permanant
          error if the sender has indicated that conversion with loss
          is prohibited for the message.'

     ],

    ['X.6.5', 'Conversion Failed',

         'A conversion was required but was unsuccessful.  This may be
          useful as a permanent or persistent temporary notification.'

     ],

    ['X.7.0', 'Other or undefined security status',

         'Something related to security caused the message to be
          returned, and the problem cannot be well expressed with any
          of the other provided detail codes.  This status code may
          also be used when the condition cannot be further described
          because of security policies in force.'

     ],

    ['X.7.1', 'Delivery not authorized, message refused',

         'The sender is not authorized to send to the destination.
          This can be the result of per-host or per-recipient
          filtering.  This memo does not discuss the merits of any
          such filtering, but provides a mechanism to report such.
          This is useful only as a permanent error.'

     ],

    ['X.7.2', 'Mailing list expansion prohibited',

         'The sender is not authorized to send a message to the
          intended mailing list. This is useful only as a permanent
          error.'

     ],

    ['X.7.3', 'Security conversion required but not possible',

         'A conversion from one secure messaging protocol to another
          was required for delivery and such conversion was not
          possible. This is useful only as a permanent error.'

     ],

    ['X.7.4', 'Security features not supported',

         'A message contained security features such as secure
          authentication which could not be supported on the delivery
          protocol. This is useful only as a permanent error.'

     ],

    ['X.7.5', 'Cryptographic failure',

         'A transport system otherwise authorized to validate or
          decrypt a message in transport was unable to do so because
          necessary information such as key was not available or such
          information was invalid.'

     ],

    ['X.7.6', 'Cryptographic algorithm not supported',

         'A transport system otherwise authorized to validate or
          decrypt a message was unable to do so because the necessary
          algorithm was not supported.'

     ],

    ['X.7.7', 'Message integrity failure',

         'A transport system otherwise authorized to validate a
          message was unable to do so because the message was
          corrupted or altered.  This may be useful as a permanent,
          transient persistent, or successful delivery code.'

     ],

];

for (@$data) {
    # unindent & unwrap text first, Text::Wrap doesn't do those
    $_->[2] =~ s/^[ \t]+//mg;
    $_->[2] =~ s/\n(\n?)(\S)/$1 ? "\n\n$2" : " $2"/mge;
}

# dump: display data as table
#use Data::Format::Pretty::Text qw(format_pretty);
#say format_pretty($data, {
#    table_column_formats=>[{description=>[[wrap=>{columns=>40}]]}],
#    table_column_orders=>[[qw/code summary description/]],
#});

# debug: dump data
#use Data::Dump::Color;
#dd $data;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

my $res = gen_read_table_func(
    name       => 'list_smtp_statuses',
    summary    => 'List SMTP statuses',
    table_data => $data,
    table_spec => {
        summary => 'List of SMTP statuses',
        fields  => {
            code => {
                schema   => 'str*',
                index    => 0,
                sortable => 1,
            },
            summary => {
                schema   => 'str*',
                index    => 1,
            },
            description => {
                schema   => 'str*',
                index    => 2,
            },
        },
        pk => 'code',
    },
);
die "Can't generate list_smtp_statuses function: $res->[0] - $res->[1]"
    unless $res->[0] == 200;

1;
# ABSTRACT: List SMTP statuses

__END__

=pod

=encoding UTF-8

=head1 NAME

App::smtpstatus - List SMTP statuses

=head1 VERSION

This document describes version 0.07 of App::smtpstatus (from Perl distribution App-smtpstatus), released on 2016-01-18.

=head1 FUNCTIONS


=head2 list_smtp_statuses(%args) -> [status, msg, result, meta]

List SMTP statuses.

REPLACE ME

This function is not exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.contains> => I<str>

Only return records where the 'code' field contains specified text.

=item * B<code.in> => I<array[str]>

Only return records where the 'code' field is in the specified values.

=item * B<code.is> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.isnt> => I<str>

Only return records where the 'code' field does not equal specified value.

=item * B<code.max> => I<str>

Only return records where the 'code' field is less than or equal to specified value.

=item * B<code.min> => I<str>

Only return records where the 'code' field is greater than or equal to specified value.

=item * B<code.not_contains> => I<str>

Only return records where the 'code' field does not contain specified text.

=item * B<code.not_in> => I<array[str]>

Only return records where the 'code' field is not in the specified values.

=item * B<code.xmax> => I<str>

Only return records where the 'code' field is less than specified value.

=item * B<code.xmin> => I<str>

Only return records where the 'code' field is greater than specified value.

=item * B<description> => I<str>

Only return records where the 'description' field equals specified value.

=item * B<description.contains> => I<str>

Only return records where the 'description' field contains specified text.

=item * B<description.in> => I<array[str]>

Only return records where the 'description' field is in the specified values.

=item * B<description.is> => I<str>

Only return records where the 'description' field equals specified value.

=item * B<description.isnt> => I<str>

Only return records where the 'description' field does not equal specified value.

=item * B<description.max> => I<str>

Only return records where the 'description' field is less than or equal to specified value.

=item * B<description.min> => I<str>

Only return records where the 'description' field is greater than or equal to specified value.

=item * B<description.not_contains> => I<str>

Only return records where the 'description' field does not contain specified text.

=item * B<description.not_in> => I<array[str]>

Only return records where the 'description' field is not in the specified values.

=item * B<description.xmax> => I<str>

Only return records where the 'description' field is less than specified value.

=item * B<description.xmin> => I<str>

Only return records where the 'description' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<query> => I<str>

Search.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<str>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<summary> => I<str>

Only return records where the 'summary' field equals specified value.

=item * B<summary.contains> => I<str>

Only return records where the 'summary' field contains specified text.

=item * B<summary.in> => I<array[str]>

Only return records where the 'summary' field is in the specified values.

=item * B<summary.is> => I<str>

Only return records where the 'summary' field equals specified value.

=item * B<summary.isnt> => I<str>

Only return records where the 'summary' field does not equal specified value.

=item * B<summary.max> => I<str>

Only return records where the 'summary' field is less than or equal to specified value.

=item * B<summary.min> => I<str>

Only return records where the 'summary' field is greater than or equal to specified value.

=item * B<summary.not_contains> => I<str>

Only return records where the 'summary' field does not contain specified text.

=item * B<summary.not_in> => I<array[str]>

Only return records where the 'summary' field is not in the specified values.

=item * B<summary.xmax> => I<str>

Only return records where the 'summary' field is less than specified value.

=item * B<summary.xmin> => I<str>

Only return records where the 'summary' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hash/associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-smtpstatus>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-App-smtpstatus>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-smtpstatus>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

RFC 1893

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
