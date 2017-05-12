#
# Courier::Message class
#
# (C) 2003-2008 Julian Mehnle <julian@mehnle.net>
# $Id: Message.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Message - Class implementing an interface to a mail message in the
Courier MTA's message queue.

=cut

package Courier::Message;

=head1 VERSION

0.200

=cut

use version; our $VERSION = qv('0.200');

use warnings;
use strict;

use overload
    '""' => \&text;

use Encode;
use IO::File;
#use MIME::Words::Better;

use Error ':try';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant fallback_8bit_char_encoding => 'windows-1252';

=head1 SYNOPSIS

    use Courier::Message;
    
    my $message = Courier::Message->new(
        file_name           => $message_file_name,
        control_file_names  => \@control_file_names,
    );
    
    # File names:
    my $message_file_name   = $message->file_name;
    my @control_file_names  = $message->control_file_names;
    
    # Message data properties:
    my $raw_message_text    = $message->text;
    my $header_hash         = $message->header;
    my $header_field        = $message->header($field);
    my $raw_body            = $message->body;
    
    # Control properties:
    my $control_hash        = $message->control;
    my $is_authenticated    = $message->authenticated;
    my $authenticated_user  = $message->authenticated_user;
    my $is_trusted          = $message->trusted;
    my $sender              = $message->sender;
    my @recipients          = $message->recipients;
    my $remote_host         = $message->remote_host;
    my $remote_host_name    = $message->remote_host_name;

=head1 DESCRIPTION

B<Courier::Message> encapsulates a mail message that is stored in the Courier
MTA's message queue, including the belonging control file(s), and provides an
easy to use, read-only interface through its message data and control
properties.  For light-weight calling of library functions or external
commands, the message and control file names may be retrieved without causing
the files to be parsed by B<Courier::Message>.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Message>

Creates a new C<Courier::Message> object from the given message file name and
zero or more control file names.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<file_name>

I<Required>.  The absolute file name of the message file.

=item B<control_file_names>

I<Required>.  An array-ref containing the absolute file name(s) of zero or more
control files belonging to the message.

=back

=cut

sub new {
    my ($class, %options) = @_;
    my $self = { %options };
    return bless($self, $class);
}

=back

=head2 Instance methods

=head3 File names

The following file name accessors are provided:

=over

=item B<file_name>: returns I<string>

Returns the absolute file name of the message file.

=cut

sub file_name {
    my ($self) = @_;
    return $self->{file_name};
}

=item B<control_file_names>: returns I<list> of I<string>

Returns the absolute file names of the control files belonging to the message.

=cut

sub control_file_names {
    my ($self) = @_;
    return @{$self->{control_file_names}};
}

=back

=head3 Message data properties

=over

=item B<text>: returns I<string>; throws Perl exceptions

Reads the message text from the message file into memory once.  Returns the raw
message text as bytes (see L<bytes>, and L<PerlIO/"bytes">).  Throws a Perl
exception if the message file cannot be read.

=cut

sub text {
    my ($self) = @_;
    
    if (not defined($self->{text})) {
        # Read message text from file:
        local $/;
        my $message_file = IO::File->new($self->{file_name}, '<:bytes');
        $self->{text} = <$message_file>;
    }
    
    return $self->{text};
}

=begin comment

=item B<parse>: returns I<Courier::Message>

Parses the message text once by doing the following: splits the message text
into header and body; tries to interpret the header as UTF-8, falling back to
a legacy 8-bit character encoding; parses header fields from the header;
decodes any MIME encoded words in field values.  Saves the parsed header fields
and the message text in the message object.  Returns the message object.

=end comment

=cut

sub parse {
    my ($self) = @_;
    
    if (
        not defined($self->{header}) or
        not defined($self->{body})
    ) {
        # Parse header and body from message text:
        my $text = $self->text;
        my ($header_text, $body_text) = ($text =~ /^(.*?\n)\n(.*)$/s);
        
        my $header = {};
        if (defined($header_text)) {
            # UTF-8-ify the header text,
            # trying to interpret it as UTF-8 first,
            # falling back to the preset 8-bit character encoding if unsuccessful:
            my $header_text_utf8 = eval {
                Encode::decode('UTF-8', $header_text, Encode::FB_CROAK)
                # We explicitly use the strict form of UTF-8 introduced in Perl 5.8.7
                # in order to sanitize input data and prevent invalid UTF-8 code.
            };
            $header_text =
                (not $@) ?
                    $header_text_utf8
                :   Encode::decode($self->fallback_8bit_char_encoding, $header_text);
            
            # Unfold header lines:
            $header_text =~ s/\n(?=\s)//g;
            
            # Parse header lines into a hash of arrays:
            while ($header_text =~ /^([\w-]+):[ \t]*(.*)$/mg) {
                my ($field, $value) = (lc($1), $2);
                try {
                    $value = MIME::Words::Better::decode($value, $self->fallback_8bit_char_encoding);
                };
                push(@{$header->{$field}}, $value);
            }
        }
        
        $self->{header} = $header;
        $self->{body} = $body_text;
    }
    
    return $self;
}

=item B<header>: returns I<hash-ref> of I<string>

=item B<header($field)>: returns I<list> of I<string>

Parses the message header once by doing the following: tries to interpret the
header as I<UTF-8>, falling back to the 8-bit legacy encoding I<Windows-1252>
(a superset of I<ISO-8859-1>) and decoding that to I<UTF-8>; parses header
fields from the header; and decodes any MIME encoded words in field values.  If
no field name is specified, returns a hash-ref containing all header fields and
array-refs of their values.  If a (case I<in>sensitive) field name is
specified, in list context returns a list of the values of all header fields of
that name, in the order they occurred in the message header, or in scalar
context returns the value of the first header field of that name (or B<undef>
if no such header field exists).

=cut

sub header {
    my ($self, @field) = @_;
    
    my $header = $self->parse()->{header};
    if (@field) {
        my $field_values = $header->{lc($field[0])} || [];
        return wantarray ? @$field_values : $field_values->[0];
    }
    else {
        return $header;
    }
}

=item B<body>: returns I<string>

Returns the raw message body as bytes (see L<bytes>, and L<PerlIO/"bytes">).

=cut

sub body {
    my ($self) = @_;
    return $self->parse()->{body};
}

=begin comment

=item B<subject>: returns I<string>

Returns the decoded value of the message's "Subject" header field.

=end comment

=cut

sub subject {
    my ($self) = @_;
    return $self->header('subject');
}

=back

=head3 Control properties

=over

=item B<control>: returns I<hash-ref> of I<string>; throws Perl exceptions

=item B<control($field)>: returns I<list> of I<string>; throws Perl exceptions

Reads and parses all of the message's control files once.  If a (case
sensitive) field name (i.e. record type) is specified, returns a list of the
values of all control fields of that name, in the order they occurred in the
control file(s).  If no field name is specified, returns a hash-ref containing
all control fields and array-refs of their values.  Throws a Perl exception if
any of the control files cannot be read.

=cut

sub control {
    my ($self, @field) = @_;
    
    my $control = $self->{control};
    
    if (not defined($control)) {
        # Read control files:
        foreach my $control_file_name (@{$self->{control_file_names}}) {
            my $control_file = IO::File->new($control_file_name);
            while (my $record = <$control_file>) {
                $record =~ /^(\w)(.*)$/;
                my ($field, $value) = ($1, $2);
                push(@{$control->{$field}}, $value);
            }
        }
        
        # Store control information:
        $self->{control} = $control;
    }
    
    if (@field) {
        my $field_values = $control->{$field[0]} || [];
        return wantarray ? @$field_values : $field_values->[0];
    }
    else {
        return $control;
    }
}

=begin comment

=item B<control_f>: returns I<string>

Parses the HELO string, the remote host, and the remote host name from the C<f>
control record and stores them into the message object.

=end comment

=cut

sub control_f {
    my ($self, @field) = @_;
    
    if (
        not defined($self->{remote_host}) or
        not defined($self->{remote_host_name}) or
        not defined($self->{remote_host_helo})
    ) {
        $self->control('f') =~ /^dns; (.*) \((?:(.*?) )?\[(.*?)\]\)$/;
        $self->{remote_host} = $3;
        $self->{remote_host_name} = $2;
        $self->{remote_host_helo} = $1;
    }
    
    return @field ? $self->{$field[0]} : $self->control('f');
}

=item B<authenticated>: returns I<boolean>

Returns the authentication information (guaranteed to be a B<true> value) if
the message has been submitted by an authenticated user.  Returns B<false>
otherwise.

I<Note>:  The authentication status and information is currently determined and
taken from the message's first (i.e. the trustworthy) "Received" header field.
This is guaranteed to work correctly, but is not very elegant, so this is
subject to change.  As soon as Courier supports storing the complete
authentication info (including the authenticated user name) in a control field,
I<that> will be the preferred source.  This mostly just means that the
I<format> of the authentication info will probably change in the future.

=cut

sub authenticated {
    my ($self) = @_;
    
    return $self->{authenticated}
        if defined($self->{authenticated});
    
    # Starting from Courier 0.57.1, the mere authentication status could be
    # determined from the 'u' control field ("smtp" vs. "authsmtp") -- but not
    # the authenticated user name.  So we do not make use of it for now.
    
    TRY: {
        # Get first "Received" header (and only the first!):
        my $received = $self->header('received');
        
        last TRY if not defined($received);
        last TRY if not $received =~ /^from\s+\S+\s+\(.*?\)\s+\((.*?)\)\s+by/i;
                                     # from   HELO  (HOST+IP)  (PARAMS)   by ...
        my %params = map(
            /^([\w-]+):\s*(.*)$/ ? (lc($1) => $2) : (),
            split(/,\s+/, $1)
        );
        
        return $self->{authenticated} = $params{auth}
            # Authenticated!
            if defined($params{auth});
    }
    
    return $self->{authenticated} = '';
        # Not authenticated.
}

=item B<authenticated_user>: returns I<string>

Returns the user name that was used for authentication during submission of the
message.  Returns B<undef> if no authentication took place.

=cut

sub authenticated_user {
    my ($self) = @_;
    
    return $self->{authenticated_user}
        if defined($self->{authenticated_user});
    
    my $authenticated = $self->authenticated;
    
    if (
        defined($self->authenticated) and
        $self->authenticated =~ /^\S+\s+(\S+)$/
                                # METHOD IDENTITY
    ) {
        return $self->{authenticated_user} = $1;
    }
    else {
        return $self->{authenticated_user} = undef;
    }
}

=item B<trusted>: returns I<boolean>

Returns a boolean value indicating whether the message is trusted.  Currently,
trusted messages are defined to be messages directly submitted by an
authenticated user.  For details on how the authenticated status is determined,
see the description of the C<authenticated> property.

=cut

sub trusted {
    my ($self) = @_;
    return $self->authenticated ? TRUE : FALSE;
}

=item B<sender>: returns I<string>

Returns the message's envelope sender (from the "MAIL FROM" SMTP command).

=cut

sub sender {
    my ($self) = @_;
    return $self->control('s');
}

=item B<recipients>: returns I<list> of I<string>

Returns all of the message's envelope recipients (from the "RCPT TO" SMTP
commands).

=cut

sub recipients {
    my ($self) = @_;
    return $self->control('r');
}

=item B<remote_host>: returns I<string>

Returns the IP address of the SMTP client that submitted the message.

=cut

sub remote_host {
    my ($self) = @_;
    return $self->control_f('remote_host');
}

=item B<remote_host_name>: returns I<string>

Returns the host name (gained by Courier through a DNS reverse lookup) of the
SMTP client that submitted the message, if available.

=cut

sub remote_host_name {
    my ($self) = @_;
    return $self->control_f('remote_host_name');
}

=item B<remote_host_helo>: returns I<string>

Returns the HELO string that the SMTP client specified, if available.

=cut

sub remote_host_helo {
    my ($self) = @_;
    return $self->control_f('remote_host_helo');
}

=back

=head1 SEE ALSO

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut


#
# MIME::Words replacement functions
#
# (C) 2004-2008 Julian Mehnle <julian@mehnle.net>
#
###############################################################################

package MIME::Words::Better;

use warnings;
use strict;

use base 'Exporter';

our @EXPORT = qw(decode_mimewords);

use Encode ();
use MIME::Base64 ();
use MIME::QuotedPrint ();

use Error ':try';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant fallback_char_encoding => 'utf-8';

# MIME encoded words grammar (RFC 2047, section 2):
use constant encoded_word_pattern   => qr{
    =\? ([\w-]+) (?:\*([\w-]+))? \? ([\w]) \? ([^?]*?) \?=
    #   Charset     Language       Encoding    Chunk
}ox;

sub decode_mimewords {
    my ($text, $fallback_char_encoding) = @_;
    
    # Drop whitespace between two encoded words:
    $text =~ s/(${\encoded_word_pattern})\s+(${\encoded_word_pattern})/$1$6/;
    
    $text =~ s[(${\encoded_word_pattern})] {
        my ($encoded_word, $char_enc, $xfer_enc, $chunk) = ($1, $2, lc($4), $5);
        my $decoded_word;
        
        $char_enc =
            Encode::resolve_alias($char_enc) ||
            $fallback_char_encoding ||
            fallback_char_encoding;
        
        try {
            if ($xfer_enc eq 'b') {
                # Base 64!
                $chunk = MIME::Base64::decode($chunk);
            }
            elsif ($xfer_enc eq 'q') {
                # Quoted Printable!
                $chunk =~ tr/_/\x{20}/;
                $chunk = MIME::QuotedPrint::decode($chunk);
            }
            
            $decoded_word = Encode::decode($char_enc, $chunk);
        }
        otherwise {
            # The chunk contains invalid characters, leave the encoded word as is:
            $decoded_word = $encoded_word;
        };
        
        $decoded_word;
    }eg;
    
    return $text;
}

BEGIN {
    no warnings 'once';
    *decode = \&decode_mimewords;
}

TRUE;
