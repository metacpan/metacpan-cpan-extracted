package App::SpamcupNG;
use warnings;
use strict;
use HTML::Form 6.11;
use Getopt::Std;
use YAML::XS 0.88 qw(LoadFile);
use File::Spec;
use Hash::Util qw(lock_hash);
use Exporter 'import';
use Log::Log4perl 1.57 qw(get_logger :levels);
use Carp qw(confess);

use App::SpamcupNG::HTMLParse (
    'find_next_id',       'find_errors',
    'find_warnings',      'find_spam_header',
    'find_best_contacts', 'find_receivers',
    'find_message_age',   'find_header_info'
);
use App::SpamcupNG::Summary;
use App::SpamcupNG::UserAgent;
use App::SpamcupNG::Summary::Recorder;

use constant TARGET_HTML_FORM => 'sendreport';

our @EXPORT_OK =
  qw(read_config main_loop %OPTIONS_MAP config_logger TARGET_HTML_FORM);
our %OPTIONS_MAP = (
    'check_only' => 'n',
    'all'        => 'a',
    'stupid'     => 's',
    'alt_code'   => 'c',
    'alt_user'   => 'l',
    'verbosity'  => 'V',
    'database'   => { enabled => 0 }
);

my %regexes = (
    no_user_id => qr/\>No userid found\</i,
    next_id    => qr/sc\?id\=(.*?)\"\>/i,
);

lock_hash(%OPTIONS_MAP);

our $VERSION = '0.018'; # VERSION

=head1 NAME

App::SpamcupNG - module to export functions for spamcup program

=head1 SYNOPSIS

    use App::SpamcupNG qw(read_config get_browser main_loop config_logger %OPTIONS_MAP);

=head1 DESCRIPTION

App-SpamcupNG is a Perl web crawler for finishing Spamcop.net reports
automatically. This module implements the functions used by the spamcup
program.

See the README.md file on this project for more details.

=head1 EXPORTS

=head2 read_config

Reads a YAML file, sets the command line options and return the associated
accounts.

Expects as parameter a string with the full path to the YAML file and a hash
reference of the command line options read (as returned by L<Getopts::Std>
C<getopts> function).

The hash reference options will set as defined in the YAML file. Options
defined in the YAML have preference of those read on the command line then.

It will also return all data configured in the C<Accounts> section of the YAML
file as a hash refence. Check the README.md file for more details about the
configuration file.

=cut

sub read_config {
    my ( $cfg, $cmd_opts ) = @_;
    my $data = LoadFile($cfg);
    confess 'second parameter must be a hash reference'
      unless ( ref($cmd_opts) eq 'HASH' );

    # sanity checking
    for my $opt ( keys( %{ $data->{ExecutionOptions} } ) ) {
        confess
"'$opt' is not a valid option for configuration files. Check the documentation."
          unless ( exists( $OPTIONS_MAP{$opt} ) );
    }

    for my $opt ( keys(%OPTIONS_MAP) ) {

        if ( $opt eq 'database' ) {
            $cmd_opts->{$opt} = $data->{ExecutionOptions}->{$opt};
            next;
        }

        if ( $opt eq 'verbosity' ) {
            $cmd_opts->{'V'} = $data->{ExecutionOptions}->{$opt};
            next;
        }

        if ( exists( $data->{ExecutionOptions}->{$opt} )
            and ( $data->{ExecutionOptions}->{$opt} eq 'y' ) )
        {
            $cmd_opts->{$opt} = 1;
        }
        else {
            $cmd_opts->{$opt} = 0;
        }

    }

    return $data->{Accounts};
}

sub _report_form {
    my ( $html_ref, $base_uri ) = @_;
    confess 'Must receive an scalar reference of the HTML response'
      unless ( ref($html_ref) );

    my @forms = HTML::Form->parse( $$html_ref, $base_uri );

    foreach my $form (@forms) {
        my $name = $form->attr('name');
        next unless defined($name);
        return $form if ( $name eq TARGET_HTML_FORM );
    }

    return undef;
}

=pod

=head2 config_logger

Configures a L<Log::Log4perl> object, as defined by the verbosity parameter (-V
in the command line).

Expected parameters:

=over

=item *

level

=item *

path to a log file

=back

If the verbosity is set to DEBUG, all messages will be sent to a log file
opened as C<spamcup.log> in append mode.

Otherwise, all messages will be sent to C<STDOUT>.

Verbosity modes are:

=over

=item *

DEBUG

=item *

INFO

=item *

WARN

=item *

ERROR

=item *

FATAL

=back

Depending on the verbosity level, more or less information you be provided. See
L<Log::Log4perl> for more details about the levels.

=cut

sub config_logger {
    my ( $level, $log_file ) = @_;
    confess "Must receive a string for the level parameter"
      unless ( ( defined($level) ) and ( $level ne '' ) );
    confess "Must receive a string for the log file parameter"
      unless ( ( defined($log_file) ) and ( $log_file ne '' ) );

# :TODO:21/01/2018 12:07:01:ARFREITAS: Do we need to import :levels from Log::Log4perl at all?
    my %levels = (
        DEBUG => $DEBUG,
        INFO  => $INFO,
        WARN  => $WARN,
        ERROR => $ERROR,
        FATAL => $FATAL
    );
    confess "The value '$level' is not a valid value for level"
      unless ( exists( $levels{$level} ) );

    my $conf;

    if ( $level eq 'DEBUG' ) {
        $conf = qq(
log4perl.category.SpamcupNG = DEBUG, Logfile
log4perl.appender.Logfile          = Log::Log4perl::Appender::File
log4perl.appender.Logfile.filename = $log_file
log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Logfile.layout.ConversionPattern = [%d] - %p - %F %L - %m%n
	);
    }
    else {
        $conf = qq(
log4perl.category.SpamcupNG = $level, Screen
log4perl.appender.Screen = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr = 0
log4perl.appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
		);
    }

    Log::Log4perl::init( \$conf );
}

sub _error_handling {
    my $content_ref = shift;
    my $logger      = get_logger('SpamcupNG');

    if ( my $errors_ref = find_errors($content_ref) ) {

        foreach my $error ( @{$errors_ref} ) {
            if ( $error->is_fatal() ) {
                $logger->warn( $error->message() );

                # must stop processing the HTML for this report and move to next
                return 1;
            }
            else {
                $logger->error( $error->message() );
            }

        }

    }

    return 0;
}

=pod

=head2 main_loop

Processes all the pending SPAM reports in a loop until finished.

Expects as parameter (in this sequence):

=over

=item *

a L<LWP::UserAgent> instance

=item *

A hash reference with the following key/values:

=over

=item *

ident => The identity to Spamcop

=item *

pass => The password to Spamcop

=item *

delay => time in seconds to wait for next iteration with Spamcop website

=item *

verbosity => defines what level of information should be provided. Uses the
same values as defined by L<Log::Log4perl>.

As confusing as it seems, current implementation may accept debug messages
B<and> disable other messages.

=item *

check_only => true (1) or false (0) to only check for unreported SPAM, but not
reporting them

=back

=back

Returns true if everything went right, or C<die> if a fatal error happened.

=cut

sub main_loop {
    my ( $ua, $opts_ref ) = @_;
    my $logger = get_logger('SpamcupNG');
    binmode( STDOUT, ":utf8" );

    # last seen SPAM id
    my $last_seen;

    # Get first page that contains link to next one...

    if ( $logger->is_debug ) {
        $logger->debug( "Sleeping for " . $opts_ref->{delay} . ' seconds' );
    }

    sleep $opts_ref->{delay};
    my $response_ref = $ua->login( $opts_ref->{ident}, $opts_ref->{pass} );
    return 0 if ( _error_handling($response_ref) );
    $logger->debug('Log in completed');
    my $next_id;
    my $summary = App::SpamcupNG::Summary->new;

    if ($response_ref) {
        $next_id = find_next_id($response_ref);

        if ( $logger->is_debug ) {
            $logger->debug("ID of next SPAM report found: $next_id")
              if ($next_id);
        }

        $summary->set_tracking_id($next_id);
        return -1 unless ( defined($next_id) );
    }
    else {
        return 0;
    }

    # avoid loops
    if ( ($last_seen) and ( $next_id eq $last_seen ) ) {
        $logger->fatal(
            'I have seen this ID earlier, we do not want to report it again.'
              . 'This usually happens because of a bug in Spamcup.'
              . 'Make sure you use latest version!'
              . "You may also want to go check from Spamcop what is happening: http://www.spamcop.net/sc?id=$next_id"
        );
    }

    $last_seen = $next_id;    # store for comparison

    # Fetch the SPAM report form
    if ( $logger->is_debug ) {
        $logger->debug( 'Sleeping for ' . $opts_ref->{delay} . ' seconds' );
    }

    sleep $opts_ref->{delay};

    # Getting a SPAM report
    $response_ref = $ua->spam_report($next_id);
    return 0 unless ($response_ref);

    if ( my $age_info_ref = find_message_age($response_ref) ) {
        if ($age_info_ref) {

            if ( $logger->is_info ) {
                $logger->info( 'Message age: '
                      . $age_info_ref->[0]
                      . ', unit: '
                      . $age_info_ref->[1] );
            }

            $summary->set_age( $age_info_ref->[0] );
            $summary->set_age_unit( $age_info_ref->[1] );
        }
        else {
            $logger->warn('Failed to parse SPAM age information');
        }
    }

    if ( my $warns_ref = find_warnings($response_ref) ) {

        if ( @{$warns_ref} ) {

            foreach my $warning ( @{$warns_ref} ) {
                $logger->warn( $warning->message() );
            }

        }
        else {
            $logger->info('No warnings found in response');
        }
    }

    if ( my $errors_ref = find_errors($response_ref) ) {

        foreach my $error ( @{$errors_ref} ) {
            if ( $error->is_fatal() ) {
                $logger->fatal( $error->message() );

                # must stop processing the HTML for this report and move to next
                return 0;
            }
            else {
                $logger->error( $error->message() );
            }

        }

    }

    # parsing the SPAM
    my $_cancel  = 0;
    my $base_uri = $ua->base();

    unless ($base_uri) {
        $logger->fatal(
'No base URI found. Internal error? Please report this error by registering an issue on Github'
        );
    }

    if ( $logger->is_debug ) {
        $logger->debug("Base URI is $base_uri");
    }

    my $best_ref = find_best_contacts($response_ref);
    $summary->set_contacts($best_ref);
    if ( $logger->is_info ) {
        if ( @{$best_ref} ) {
            my $best_as_text = join( ', ', @$best_ref );
            $logger->info("Best contacts for SPAM reporting: $best_as_text");
        }
    }

    my $form = _report_form( $response_ref, $base_uri );
    $logger->fatal(
'Could not find the HTML form to report the SPAM! May be a temporary Spamcop.net error, try again later! Quitting...'
    ) unless ( defined($form) );

    my $spam_header_info = find_header_info($response_ref);
    $summary->set_mailer( $spam_header_info->{mailer} );
    $summary->set_content_type( $spam_header_info->{content_type} );
    $summary->set_charset( $spam_header_info->{charset} );

    if ( $logger->is_info ) {
        $logger->info( 'X-Mailer: ' . $summary->to_text('mailer') );
        $logger->info( 'Content-Type: ' . $summary->to_text('content_type') );

        my $spam_header_ref = find_spam_header($response_ref);

        if ($spam_header_ref) {
            my $as_string = join( "\n", @$spam_header_ref );
            $logger->info("Head of the SPAM follows:\n$as_string");
        }
        else {
            $logger->warn('No SPAM header found');
        }

        # how many recipients for reports
        my $max = $form->value("max");
        my $willsend;
        my $wontsend;

        # iterate targets
        for ( my $i = 1 ; $i <= $max ; $i++ ) {
            my $send   = $form->value("send$i");
            my $type   = $form->value("type$i");
            my $master = $form->value("master$i");
            my $info   = $form->value("info$i");

            # convert %2E -style stuff back to text, if any
            if ( $info =~ /%([A-Fa-f\d]{2})/g ) {
                $info =~ s/%([A-Fa-f\d]{2})/chr hex $1/eg;
            }

            if (
                $send
                and (  ( $send eq 'on' )
                    or ( $type =~ /^mole/ and $send == 1 ) )
              )
            {
                $willsend .= "$master ($info)\n";
            }
            else {
                $wontsend .= "$master ($info)\n";
            }
        }

        my $message =
'Would send the report to the following addresses (reason in parenthesis): ';

        if ($willsend) {
            $message .= $willsend;
        }
        else {
            $message .= '--none--';
        }

        $logger->info($message);
        $message = 'Following addresses would not be used: ';

        if ($wontsend) {
            $message .= $wontsend;
        }
        else {
            $message .= '--none--';
        }

        $logger->info($message);
    }
    else {
        if ( ( $logger->is_debug ) and ($form) ) {
            $logger->debug( 'Form data follows: ' . $form->dump );
        }
    }

    $logger->fatal(
'Could not find the HTML form to report the SPAM! May be a temporary Spamcop website error, try again later! Quitting...'
    ) unless ($form);

    # Run without confirming each spam? Stupid. :)
    unless ( $opts_ref->{stupid} ) {
        print "* Are you sure this is SPAM? [y/N] ";

        my $reply = <>;    # this should be done differently!
        if ( $reply && $reply !~ /^y/i ) {
            print "* Cancelled.\n";
            $_cancel = 1;    # mark to be cancelled
        }
        elsif ( !$reply ) {
            print "* Accepted.\n";
        }
        else {
            print "* Accepted.\n";
        }
    }
    else {

        # little delay for automatic processing
        sleep $opts_ref->{delay};
    }

# this happens rarely, but I've seen this; spamcop does not show preview headers for some reason
    if ( $$response_ref =~ /Send Spam Report\(S\) Now/gi ) {

        unless ( $opts_ref->{stupid} ) {
            print
"* Preview headers not available, but you can still report this. Are you sure this is SPAM? [y/N] ";

            my $reply = <>;
            chomp($reply);

            if ( $reply && $reply !~ /^y/i ) {

                # not Y
                print "* Cancelled.\n";
                $_cancel = 1;    # mark to be cancelled
            }
            else {

                # Y
                print "* Accepted.\n";
            }
        }

    }
    elsif ( $$response_ref =~
/click reload if this page does not refresh automatically in \n(\d+) seconds/gs
      )

    {
        my $delay = $1;
        $logger->warn(
"Spamcop seems to be currently overloaded. Trying again in $delay seconds. Wait..."
        );
        sleep $opts_ref->{delay};

        # fool it to avoid duplicate detector
        $last_seen = 0;

        # fake that everything is ok
        return 1;
    }
    elsif ( $$response_ref =~
        /No source IP address found, cannot proceed. Not full header/gs )
    {
        $logger->warn(
'No source IP address found. Your report might be missing headers. Skipping.'
        );
        return 0;
    }
    else {

        # Shit happens. If you know it should be parseable, please report a bug!
        $logger->warn(
"Can't parse Spamcop.net's HTML. If this does not happen very often you can ignore this warning. Otherwise check if there's new version available. Skipping."
        );
        return 0;
    }

    if ( $opts_ref->{check_only} ) {
        $logger->info(
'You gave option -n, so we\'ll stop here. The SPAM was NOT reported.'
        );
        exit;
    }

    # Submit the form to Spamcop OR cancel report
    unless ($_cancel) {    # SUBMIT spam

        if ( $logger->is_debug ) {
            $logger->debug(
                'Submitting form. We will use the default recipients.');
            $logger->debug(
                'Sleeping for ' . $opts_ref->{delay} . ' seconds.' );
        }

        sleep $opts_ref->{delay};

        # click default button, submit
        $response_ref = $ua->complete_report( $form->click() );
    }
    else {    # CANCEL SPAM
        $logger->debug('About to cancel report.');
        $response_ref = $ua->complete_report( $form->click('cancel') );
    }

    return 0 unless ($response_ref);

    if ($_cancel) {
        return 1;    # user decided this mail is not SPAM
    }

    # parse response
    my $receivers_ref = find_receivers($response_ref);
    $summary->set_receivers($receivers_ref);

    if ( scalar( @{$receivers_ref} ) > 0 ) {

        if ( $logger->is_info ) {
            $logger->info( 'Spamcop.net sent following SPAM reports: '
                  . $summary->to_text('receivers') );
            $logger->info('Finished processing.');
        }

    }
    else {
        my $msg = <<'EOM';
Spamcop.net returned unexpected content (no SPAM report id, no receiver).
Please make check if there new version of App-SpamcupNG available and upgrade it.
If you already have the latest version, please open a bug report in the
App-SpamcupNG homepage and provide the next lines with the HTML response
provided by Spamcop.
EOM
        $logger->warn($msg);
        $logger->warn($response_ref);
    }

    $logger->debug( 'SPAM report summary: ' . $summary->as_text )
      if ( $logger->is_debug );

    if ( $opts_ref->{database}->{enabled} ) {
        $logger->info( 'Persisting summary to SQLite database at '
              . $opts_ref->{database}->{path} )
          if ( $logger->is_info );
        my $recorder = App::SpamcupNG::Summary::Recorder->new(
            $opts_ref->{database}->{path} );
        $recorder->init;
        $recorder->save($summary);
    }

    return 1;

    # END OF THE LOOP
}

=head1 SEE ALSO

=over

=item *

L<Log::Log4perl>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 of Alceu Rodrigues de Freitas Junior,
E<lt>glasswalk3r@yahoo.com.brE<gt>

This file is part of App-SpamcupNG distribution.

App-SpamcupNG is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

App-SpamcupNG is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
App-SpamcupNG. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
