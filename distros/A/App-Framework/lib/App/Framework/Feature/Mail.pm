package App::Framework::Feature::Mail ;

=head1 NAME

App::Framework::Feature::Mail - Send mail

=head1 SYNOPSIS

  use App::Framework '+Mail' ;


=head1 DESCRIPTION

Provides a simplified mail interface, and application error auto-mailing.

When used as a mail interface, this feature is accessed in the same manner as any other (e.g. see L<App::Framework::Feature::Args>).

The accessor function (L</mail>) returns the mail object if no parameters are specified; otherwise it will send a mail:

	$app->Mail("This is a test",
		'from'		=> 'someone@domain.co.uk',
		'to'		=> 'afriend@domain.com',
		'subject'	=> 'a test',
	) ;
 
Default settings may be set at the start of an application so that only specific parameters need to be added:

	$app->Mail()->set(
		'from'		=> 'someone@domain.co.uk',
		'error_to'	=> 'someone@domain.co.uk',
		'err_level' => 'warning',
	) ;

	## send a mail to 'afriend@domain.com'
	$app->Mail("This is a test",
		'to'		=> 'afriend@domain.com',
		'subject'	=> 'a test',
	) ;

	...
	
	## send another - still goers to 'afriend@domain.com'
	$app->Mail("This is another test",
		'subject'	=> 'another test',
	) ;

An additional capability is that this feature can automatically send emails of any errors. To do this you first of all
need to specify the 'error_to' recipient, and then set the 'err_level'. The 'err_level' setting specifies the type of
error that will generate an email. For example, setting 'err_level' to "warning" means all warnings AND errors will result
in emails; but notes will not (see L<App::Framework::Base::Object::ErrorHandle> for types).

This feature also automatically adds mail-related command line options to allow a user to specify the field settings for themselves
(or an application may over ride with their own defaults).   

Note that the 'to' and 'error_to' fields may be a comma seperated list of mail recipients.

=cut

use strict ;
use Carp ;

our $VERSION = "1.002" ;


#============================================================================================
# USES
#============================================================================================
use App::Framework::Feature ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(App::Framework::Feature) ; 

#============================================================================================
# GLOBALS
#============================================================================================

=head2 ADDITIONAL COMMAND LINE OPTIONS

This extension adds the following additional command line options to any application:

=over 4

=item B<-mail-from> - Mail sender (required)

Email sender

=item B<-mail-to> - Mail recipient(s) (required)

Email recipient. Where there are multiple recipients, they should be set as a comma seperated list of email addresses

=item B<-mail-error-to> - Error mail recipient(s)

Email recipient for errors. If set, program errors are sent to this email.

=item B<-mail-err-level> - Error level for mails

Set the minium error level that triggers an email. Level can be: note, warning, error

=item B<-mail-subject> - Mail subject

Optional mail subject line

=item B<-mail-host> - Mail host 

Mailing host. If not specified uses 'localhost'

=back

=cut

# Set of script-related default options
my @OPTIONS = (
	['mail-from=s',			'Mail sender', 				'Email sender', ],
	['mail-to=s',			'Mail recipient',			'Email recipient(s). Where there are multiple recipients, they should be set as a comma seperated list of email addresses', ],
	['mail-error-to=s',		'Error mail recipient',		'Email recipient(s) for errors. If set, program errors are sent to this email.'],
	['mail-err-level=s',	'Error level for mails',	'Set the minium error level that triggers an email (must have error-to set). Level can be: note, warning, error', 'error'],
	['mail-subject=s',		'Mail subject',				'Optional mail subject line'],
	['mail-host=s',			'Mail host',				'Mailing host.', 'localhost'],
) ;



=head2 FIELDS

The following fields should be defined either in the call to 'new()', as part of a 'set()' call, or called by their accessor method
(which is the same name as the field):


=over 4


=item B<from> - Mail sender (required)

Email sender

=item B<to> - Mail recipient(s) (required)

Email recipient. Where there are multiple recipients, they should be set as a comma seperated list of email addresses

=item B<error_to> - Error mail recipient(s)

Email recipient for errors. If set, program errors are sent to this email.

=item B<err_level> - Error level for mails

Set the minium error level that triggers an email. Level can be: note, warning, error

=item B<subject> - Mail subject

Optional mail subject line

=item B<host> - Mail host 

Mailing host. If not specified uses 'localhost'


=back

=cut

my %FIELDS = (
	'from'			=> '',
	'to'			=> '',
	'error_to'		=> '',
	'err_level'		=> 'error',
	'subject'		=> '',
	'host'			=> 'localhost',
	
	## Private
	'_caught_error'	=> 0,
) ;

#============================================================================================

=head2 CONSTRUCTOR

=over 4

=cut

#============================================================================================


=item B< new([%args]) >

Create a new Mail.

The %args are specified as they would be in the B<set> method (see L</Fields>).

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $this = $class->SUPER::new(%args,
		'requires' 				=> [qw/Net::SMTP/],
		'registered'			=> [qw/application_entry catch_error_entry/],
		'feature_options'		=> \@OPTIONS,
	) ;
	

	## If associated with an app, set options
	my $app = $this->app ;
	if ($app)
	{
		## Set options
		$app->feature('Options')->append_options(\@OPTIONS) ;
		
		## Update option defaults
		$app->feature('Options')->defaults_from_obj($this, [keys %FIELDS]) ;
	}

	
	return($this) ;
}



#============================================================================================

=back

=head2 CLASS METHODS

=over 4

=cut

#============================================================================================


#-----------------------------------------------------------------------------

=item B< init_class([%args]) >

Initialises the Mail object class variables.

=cut

sub init_class
{
	my $class = shift ;
	my (%args) = @_ ;

	# Add extra fields
	$class->add_fields(\%FIELDS, \%args) ;

	# init class
	$class->SUPER::init_class(%args) ;

}

#============================================================================================

=back

=head2 OBJECT METHODS

=over 4

=cut

#============================================================================================


#--------------------------------------------------------------------------------------------

=item B< mail($content [, %args]) >

Send some mail stored in $content. $content may either be a string (containing newlines), or an
ARRAY ref.

Optionally %args may be specified (to set 'subject' etc).

If no arguments are specified then just returns the mail object.

=cut

sub mail
{
	my $this = shift ;
	my ($content, %args) = @_ ;

	return $this unless $content ;
	
$this->_dbg_prt(["mail() : content=\"$content\"\n"]) ;
	
	$this->set(%args) ;
	
	my $from = $this->from ;
	my $mail_to = $this->to ;
	my $subject = $this->subject ;
	my $host = $this->host ;
	
	
	## error check
	$this->throw_fatal("Mail: not specified 'from' field") unless $from ;
	$this->throw_fatal("Mail: not specified 'to' field") unless $mail_to ;
	$this->throw_fatal("Mail: not specified 'host' field") unless $host ;

	my @content ;
	if (ref($content) eq 'ARRAY')
	{
		@content = @$content ;
	}
	elsif (!ref($content))
	{
		@content = split /\n/, $content ;
	}

	## For each recipient, need to send a separate mail
	my @to = split /,/, $mail_to ;
	foreach my $to (@to)
	{
		my $smtp = Net::SMTP->new($host); # connect to an SMTP server
		$this->throw_fatal("Mail: unable to connect to '$host'") unless $smtp ;
		
		$smtp->mail($from);     # use the sender's address here
		$smtp->to($to);	# recipient's address
		$smtp->data();      # Start the mail
		
		# Send the header.
		$smtp->datasend("To: $mail_to\n");
		$smtp->datasend("From: $from\n");
		$smtp->datasend("Subject: $subject\n") if $subject ;
		
		# Send the body.
		$smtp->datasend("$_\n") foreach (@content) ;
		
		$smtp->dataend();   # Finish sending the mail
		$smtp->quit;        # Close the SMTP connection
	}
}

#----------------------------------------------------------------------------

=item B< Mail([%args]) >

Alias to L</mail>

=cut

*Mail = \&mail ;


#----------------------------------------------------------------------------

=item B<application_entry()>

Called by the application framework at the start of the application.
 
This method checks for the user specifying any of the options described above (see L</ADDITIONAL COMMAND LINE OPTIONS>) and handles
them if so.

=cut


sub application_entry
{
	my $this = shift ;

$this->_dbg_prt(["application_entry()\n"], 2) ;

	## Handle special options
	my $app = $this->app ;
	my %opts = $app->options() ;
$this->_dbg_prt(["mail options=",\%opts], 2) ;


	## Map from options to object data
	foreach my $opt_entry_aref (@OPTIONS)
	{
		my $opt = $opt_entry_aref->[0] ;
		if ($opts{$opt})
		{
			my $field = $opt ;
			$field =~ s/[-]/_/g ;
			$field =~ s/^mail\-// ;
			
			$this->set($field => $opts{$opt}) ;
		}
	}
}


#--------------------------------------------------------------------------------------------

=item B< catch_error_entry($error) >

Send some mail stored in $content. $content may either be a string (containing newlines), or an
ARRAY ref.

Optionally %args may be specified (to set 'subject' etc)

=cut

sub catch_error_entry
{
	my $this = shift ;
	my ($error) = @_ ;

	## skip if already inside an error
	return if $this->_caught_error ;
	
	my $from = $this->from ;
	my $error_to = $this->error_to ;
	my $app = $this->app ;

$this->_dbg_prt(["catch_error_entry() : from=$from error-to=$error_to app=$app\n"]) ;
$this->_dbg_prt(["error=", $error], 5) ;
	
	# skip if required fields not set
	return unless $from && $error_to && $app ;

	my $appname = $app->name ;
	my $level = $this->err_level ;
	
$this->_dbg_prt(["mail level=$level, app=$appname\n"]) ;
	
	## See if we mail it
	my ($msg, $exitcode, $error_type) ;
	
	# If it's an error, mail it
	if ($this->is_error($error))
	{
		($msg, $exitcode) = $this->error_split($error) ;
		$error_type = "fatal error" ;
	}
	if ($this->is_warning($error) && (($level eq 'warning') || ($level eq 'note')))
	{
		($msg, $exitcode) = $this->error_split($error) ;
		$error_type = "warning" ;
	}
	if ( $this->is_note($error) && ($level eq 'note') )
	{
		($msg, $exitcode) = $this->error_split($error) ;
		$error_type = "note" ;
	}

$this->_dbg_prt(["type=$error_type, exit=$exitcode, msg=\"$msg\"\n"]) ;

	if ($msg)
	{
		$this->_caught_error(1) ;
		my $orig_to = $this->to ;
		$this->mail(
			$msg,
			'to'		=> $error_to,
			'subject'	=> "$appname $error_type",
		) ;
		$this->to($orig_to) ;
		$this->_caught_error(0) ;
	}
}

# ============================================================================================
# PRIVATE METHODS
# ============================================================================================


# ============================================================================================
# END OF PACKAGE

=back

=head1 DIAGNOSTICS

Setting the debug flag to level 1 prints out (to STDOUT) some debug messages, setting it to level 2 prints out more verbose messages.

=head1 AUTHOR

Steve Price C<< <sdprice at cpan.org> >>

=head1 BUGS

None that I know of!

=cut

1;

__END__


