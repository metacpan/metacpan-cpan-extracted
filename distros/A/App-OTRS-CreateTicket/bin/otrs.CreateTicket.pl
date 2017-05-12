#! /usr/bin/perl

use strict;
use warnings;

use Encode;
use Encode::Locale;
use File::Basename;
use File::MimeInfo;
use Getopt::Long;
use MIME::Base64;
use Pod::Usage;
use SOAP::Lite;
use Time::Piece;

our $VERSION = '1.16';

print "$0 version $VERSION \n\n";

@ARGV = map { decode(locale => $_, 1) } @ARGV if -t STDIN;
binmode STDOUT, ":encoding(console_out)" if -t STDOUT;
binmode STDERR, ":encoding(console_out)" if -t STDERR;

my @TicketFields
    = qw ( Title CustomerUser Queue Priority State Type Service SLA Owner Responsible );
my @ArticleFields = qw ( Subject Body ContentType ArticleType SenderType TimeUnit );

my @TicketOptions  = map { $_ . '=s' } @TicketFields;
my @ArticleOptions = map { $_ . '=s' } @ArticleFields;

my %Param = ();
GetOptions(
    \%Param,
    # options for connection
    'UserLogin=s',
    'Password=s',
    'Server=s',
    'Operation=s',
    'Namespace=s',
    'Url=s',
    'BodyFile=s',
    'Ssl',
    'help',
    # options for ticket
    @TicketOptions,
    'PendingTime=s',
    # options for article
    @ArticleOptions,
    # dynamic fields; can be multiple
    'DynamicField=s%',
    # attachments; can be multiple
    'Attachment=s@',
);

if ( $Param{help} || !$Param{Url} && !$Param{Server} ) {
    pod2usage( -exitstatus => 0 );
}

my $URL;

# if we do not have a URL, compose one
if ( !$Param{Url} ) {
    my $Server = $Param{Server} || 'localhost';
    my $HTTPType = $Param{Ssl} ? 'https://' : 'http://';
    $URL = $HTTPType . $Server . '/otrs/nph-genericinterface.pl/Webservice/GenericTicketConnector'
}
else {
    $URL = $Param{Url};
}

# handle attachments
my @Attachments;
if (defined $Param{Attachment}) {

    for my $File ( @{$Param{Attachment}} ) {
        die "Can't find attachment '$File'.\n" if !-f $File;

        # open attachment && read in
        open my $fh, "<:unix", $File or die "Couldn't open $File: $!\n";
        read $fh, my $Content, -s $fh or die "Couldn't read $File: $!";
        close $fh;

        # add to array with  basename of file and filename
        push @Attachments, \SOAP::Data->name(Attachment => SOAP::Data->value(
         SOAP::Data->name(Content     => encode_base64($Content)),
         SOAP::Data->name(ContentType => mimetype($File)),
         SOAP::Data->name(Filename    => basename($File)),
        ));
  }
}

# this name space should match the specified name space in the SOAP transport for the web service
my $NameSpace = $Param{Namespace} || 'http://www.otrs.org/TicketConnector/';

# this is operation to execute, it could be TicketCreate, TicketUpdate, TicketGet, TicketSearch
# or SessionCreate. and they must to be defined in the web service.
my $Operation = $Param{Operation} || 'TicketCreate';

# assign values for ticket and article data if undefined
$Param{Queue}    ||= 'Postmaster';
$Param{Priority} ||= '3 normal';
$Param{Type}     ||= 'default';
$Param{Title}    ||= 'No title';
$Param{State}    ||= 'new';

$Param{ContentType} ||= 'text/plain; charset=utf8';
$Param{Subject}     ||= $Param{Title};
$Param{SenderType}  ||= 'customer';
$Param{TimeUnit}    ||= 0;

if ( $Param{BodyFile} ) {
    open my $Filehandle, '<', $Param{BodyFile} or die "Can't open file $Param{BodyFile}: $!";
    # read in file at once as in PBP
    $Param{Body} = do { local $/; <$Filehandle> };
    close $Filehandle;
} elsif ( !$Param{Body} ) {
    binmode STDIN;
    while ( my $Line = <> ) {
        $Param{Body} .= $Line;
    }
}

# handle PendingTime, if it's a number, add it as minutes to current time.
# otherwise, parse it as a string in YYYY-MM-DDTHH:MM format
my $PendingTime;
if ( defined $Param{PendingTime} && $Param{PendingTime} =~ /^\d*$/) {
    $PendingTime = localtime;
    $PendingTime += (60 * $Param{PendingTime});
}
elsif (defined $Param{PendingTime} ) {

    $PendingTime = Time::Piece->strptime($Param{PendingTime}, "%Y-%m-%dT%R");
}

# Converting Ticket and Article data into SOAP data structure
my @TicketData;
for my $Element (@TicketFields) {
    if ( defined $Param{$Element} ) {
        my $Param = SOAP::Data->name( $Element => $Param{$Element} );
        $Param->type('string');
        push @TicketData, $Param;
    }
}

if ( $PendingTime ) {

    # create SOAP datastructure containing time elements
    my @PendingData;
    push @PendingData, SOAP::Data->name( Year => $PendingTime->year);
    push @PendingData, SOAP::Data->name( Month => $PendingTime->mon);
    push @PendingData, SOAP::Data->name( Day => $PendingTime->mday);
    push @PendingData, SOAP::Data->name( Hour => $PendingTime->hour);
    push @PendingData, SOAP::Data->name( Minute => $PendingTime->minute);

    # add datastructure to ticket tree
    push @TicketData, SOAP::Data->name( PendingTime => \SOAP::Data->value(@PendingData));
}

my @ArticleData;
for my $Element (@ArticleFields) {
    if ( defined $Param{$Element} ) {
        my $Param = SOAP::Data->name( $Element => $Param{$Element} );
        $Param->type('string');
        push @ArticleData, $Param;
    }
}

my @DynamicFields;
if ($Param{DynamicField}) {
    for my $DynamicField ( keys %{$Param{DynamicField}} ) {
        push @DynamicFields, \SOAP::Data->name(DynamicField => SOAP::Data->value(
            SOAP::Data->name(Name => $DynamicField),
            SOAP::Data->name(Value => $Param{DynamicField}->{$DynamicField}),
        ));
    }
}

my @SOAPData;
push @SOAPData, SOAP::Data->name('UserLogin')->value($Param{UserLogin});
push @SOAPData, SOAP::Data->name('Password')->value($Param{Password});
push @SOAPData, SOAP::Data->name(Ticket       => \SOAP::Data->value(@TicketData));
push @SOAPData, SOAP::Data->name(Article      => \SOAP::Data->value(@ArticleData));
push @SOAPData, SOAP::Data->name(Attachment   => @Attachments) if @Attachments;
push @SOAPData, SOAP::Data->name(DynamicField => @DynamicFields) if @DynamicFields;

my $SOAPObject = SOAP::Lite
    ->uri($NameSpace)
    ->proxy($URL)
    ->$Operation(@SOAPData);

# check for a fault in the soap code
if ( $SOAPObject->fault ) {
    print $SOAPObject->faultcode, "\n";
    print $SOAPObject->faultstring, "\n";
    exit 0;
}

# otherwise print the results
else {
    # get the XML response part from the SOAP message
    my $XMLResponse = $SOAPObject->context()->transport()->proxy()->http_response()->content();
    # deserialize response (convert it into a perl structure)
    my $Deserialized = eval {
        SOAP::Deserializer->deserialize($XMLResponse);
    };

    # remove all the headers and other not needed parts of the SOAP message
    my $Body = $Deserialized->body();

    # just output relevant data and no the operation name key (like TicketCreateResponse)
    if ( defined $Body->{TicketCreateResponse}->{Error} ) {
        print "Could not create ticket.\n\n";
        print "ErrorCode:    $Body->{TicketCreateResponse}->{Error}->{ErrorCode}\n";
        print "ErrorMessage: $Body->{TicketCreateResponse}->{Error}->{ErrorMessage}\n\n";
        exit 0;
    }
    else {
        print "Created ticket $Body->{TicketCreateResponse}->{TicketNumber}\n";
    }
}

exit 1;

__END__

=head1 NAME

otrs.CreateTicket.pl - create tickets in OTRS via web services.

=head1 SYNOPSIS

Example 1: all arguments on the command line, add attachment

otrs.CreateTicket.pl --Server otrs.example.com --Ssl --UserLogin myname  \
--Password secretpass --Title 'The ticket title' \
--CustomerUser customerlogin --Body 'The ticket body' \
--DynamicField Branch="Sales UK" --DynamicField Source=Monitoring \
--Attachment demo.xls --Attachment screenshot.png

Example 2: read body in from a file

otrs.CreateTicket.pl --Server otrs.example.com --Ssl --UserLogin myname  \
--Password secretpass --Title 'The ticket title' \
--CustomerUser customerlogin --BodyFile description.txt

Example 3: read body in from STDIN, pending at some date

otrs.CreateTicket.pl --Server otrs.example.com --Ssl --UserLogin myname  \
--State 'pending reminder' --PendingTime 2014-10-03T15:00 \
--Password secretpass --Title 'The ticket title' \
--CustomerUser customerlogin < description.txt

Example 4: read body in from STDIN, pending in two hours

otrs.CreateTicket.pl --Server otrs.example.com --Ssl --UserLogin myname  \
--State 'pending reminder' --PendingTime 120 \
--Password secretpass --Title 'The ticket title' \
--CustomerUser customerlogin < description.txt

Please note that if you do not specify a --BodyFile or pipe in a file, the
command will expect your input as the ticket body; this is typically not
what you want.

=head1 SYNTAX

otrs.CreateTicket.pl command syntax:

    otrs.CreateTicket.pl [arguments]

Arguments:

    SERVER CONNECTION
    --Server        Name of OTRS server.
    --Ssl (boolean) If SSL (https) should be used.

    Alternatively:
    --Url           Full URL to GenericTicket web service.

    USER AUTHENTICATION
    --UserLogin     Login name of valid Agent account.
    --Password      Password for user.

    TICKET DATA
    --Title         Title of ticket.
    --CustomerUser  Customer of ticket (mandatory!).
    --Priority      Defaults to '3 normal' if not specified.
    --Queue         Defaults to 'Postmaster' if not specified.
    --Owner         Optional.
    --Responsible   Optional, and only if activated on the server.
    --Service       Optional, and only if activated on the server.
    --SLA           Optional, and only if activated on the server.
    --Type          Optional, and only if activated on the server.
                     PLEASE NOTE: on version 3.3 or later you might need to
                      use the value 'Unclassified' as the default changed.

    --PendingTime   If a number, # of minutes after current time. Otherwise,
                    should be a string in 'YYYY-MM-DDTHH:MM' format.

    ARTICLE DATA
    --Subject       Optional, defaults to title if not defined.
    --BodyFile      Name of file that contains body text of the message
    --Body          Body text of the message.
    --SenderType    Optional, defaults to 'Customer'.
    --ArticleType   Optional, defaults to 'web-request'.
    --TimeUnit      Can be optional or required depending on the server.

    DYNAMIC FIELDS
    --DynamicField  Optional. Can be passed multiple times.
                    Takes Name=Value pairs.

    ATTACHMENTS
    --Attachment    Optional. Can be passed multiple times.
                    Takes filenames as values.

=cut

