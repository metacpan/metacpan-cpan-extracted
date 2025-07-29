package Android::ElectricSheep::Automator::Plugins::Apps::Viber;

use strict;
use warnings;

#use lib ($FindBin::Bin, 'blib/lib');

use parent 'Android::ElectricSheep::Automator::Plugins::Apps::Base';

use Time::HiRes qw/usleep/;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use Android::ElectricSheep::Automator::XMLParsers;

sub new {
	my ($class, $params) = @_;
	my $self = $class->SUPER::new({
		%$params,
		'child-class' => $class,
	});
	$self->{'_private'}->{'appname'} = 'com.viber.voip';

	return $self;
}

# keeps pressing the back-arrow at the top of the app to hopefully
# arrive at the main activity of the app,
# TODO: is there a way to tell it to go to main activity ? WelcomeActivity does not seem to work
# returns 1 on failure, 0 on success.
sub navigate_to_viber_home_activity {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	my ($outbase, $outfile);
	# for debugging purposes, save each UI we get here
	$outbase = exists($params->{'outbase'}) ? $params->{'outbase'} : undef;

	my ($ui, $dom, $xc, $asel, @nodes, $N, $node, $boundstr, $bounds);

	my $repeats = 3;
	my $repeatsUI = 3;
	ONBACKARROW:
	while(--$repeats > 0){
		# we assume the app is open and at the foreground
		# get the UI
		$outfile = defined($outbase) ? $outbase.'_main.xml' : undef;
		do {
			$ui = $self->mother->dump_current_screen_ui({'filename'=>$outfile});
			usleep(0.75);
		} while( ($repeatsUI-- > 0) && ! defined($ui) );
		if( ! defined $ui ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to dump the UI, call to ".'dump_current_screen_ui()'." has failed after a number of repeats. I am not sure what the problem is, most likely a race condition ..."); return undef }

		$dom = $ui->{'XML::LibXML'};
		$xc = $ui->{'XML::LibXML::XPathContext'};
		$asel = '//node'
			. '['
			.   ' matches(@content-desc,\'navigate\s+up\',"i")'
			.   ' and matches(@class,\'ImageButton\',"i")'
			.   ' and @package="com.viber.voip"'
			.   ' and matches(@bounds,\'^\[\',"i")'
			. ']'
		;
		@nodes = $xc->findnodes($asel);
		$N = scalar @nodes;
		if( $N == 0 ){
			if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : no nodes matching this XPath selector (for getting the 'back-arrow' icon, hopefully, this means we reached home-page of the app): ${asel}") }
			last ONBACKARROW;
		} elsif( $N > 1 ){ $log->error("--begin matched nodes:\n".join("\n", @nodes)."\n--end nodes matched.\n\n${whoami} (via $parent), line ".__LINE__." : error, matched more than one node (see above) with this XPath selector (for getting the 'Chats' icon: ${asel}"); return 1 }
		$node = $nodes[0];

		# click the 'back-arrow' at the top
		$boundstr = $node->getAttribute('bounds');
		if( ! defined $boundstr ){ $log->error("${node}\n\n${whoami} (via $parent), line ".__LINE__." : error, above node does not have attribute 'bounds'."); return 1 }
		if( $boundstr !~ /\[\s*(\d+)\s*,\s*(\d+)\]\s*\[\s*(\d+)\s*,\s*(\d+)\]/ ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to parse bounds string: '$boundstr'."); return 1 }
		$bounds = [[$1,$2],[$3,$4]];
		# click it
		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : clicking the back-arrow ...") }
		if( $self->mother->tap({'bounds' => $bounds}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to tap on $bounds."); return 1 }
		usleep(0.75);
	}

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : hopefully we are now at the very first screen of the app.") }
	return 0 # success
}

sub send_message {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	my ($recipient, $message, $outbase, $outfile);
	if( ! exists($params->{'recipient'}) || ! defined($recipient=$params->{'recipient'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'recipient' was not specified."); return undef }
	if( ! exists($params->{'message'}) || ! defined($message=$params->{'message'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'message' was not specified."); return undef }
	# for debugging purposes, save each UI we get here
	$outbase = exists($params->{'outbase'}) ? $params->{'outbase'} : undef;
	# do everything except clicking the send button
	my $mock = exists($params->{'mock'}) ? $params->{'mock'} : 0;

	my ($dom, $xc, $asel, @nodes, $N, $node, $boundstr, $bounds);

	if( $self->navigate_to_viber_home_activity({'outbase'=>$outbase}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'navigate_to_viber_home_activity()'." has failed."); return undef }
	usleep(1.5);

	# we assume the app is open and at the foreground
	# get the UI
	$outfile = defined($outbase) ? $outbase.'_main.xml' : undef;
	# there is always the chance you get 'Is taking too long'...
	# and all will fail TODO!
	my $ui;
	my $repeatsUI = 3;
	do {
		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : calling ".'dump_current_screen_ui()'." for at repeat $repeatsUI ...") }
		$ui = $self->mother->dump_current_screen_ui({'filename'=>$outfile});
		usleep(0.75);
	} while( ($repeatsUI-- > 0) && (! defined($ui)) );
	if( ! defined $ui ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to dump the UI, call to ".'dump_current_screen_ui()'." has failed after a number of repeats. I am not sure what the problem is, most likely a race condition ..."); return undef }

	$dom = $ui->{'XML::LibXML'};
	$asel = '//node[@text="Chats" and @resource-id="com.viber.voip:id/bottomBarItemTitle"]';
	@nodes = $dom->findnodes($asel);
	$N = scalar @nodes;
	if( $N == 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to find any nodes matching this XPath selector (for getting the 'Chats' icon): ${asel}"); return undef }
	elsif( $N > 1 ){ $log->error("--begin matched nodes:\n".join("\n", @nodes)."\n--end nodes matched.\n\n${whoami} (via $parent), line ".__LINE__." : error, matched more than one node (see above) with this XPath selector (for getting the 'Chats' icon): ${asel}"); return undef }
	$node = $nodes[0];

	# click the 'Chats' at the bottom
	$boundstr = $node->getAttribute('bounds');
	if( ! defined $boundstr ){ $log->error("${node}\n\n${whoami} (via $parent), line ".__LINE__." : error, above node does not have attribute 'bounds'."); return undef }
	if( $boundstr !~ /\[\s*(\d+)\s*,\s*(\d+)\]\s*\[\s*(\d+)\s*,\s*(\d+)\]/ ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to parse bounds string: '$boundstr'."); return undef }
	$bounds = [[$1,$2],[$3,$4]];
	# click it
	if( $self->mother->tap({'bounds' => $bounds}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to tap on $bounds."); return undef }
	sleep(1);

	# now we are on the chats screen, in the centre pane there are all our contacts
	# get the ui for this screen
	$outfile = defined($outbase) ? $outbase.'_chats.xml' : undef;
	$ui = $self->mother->dump_current_screen_ui({'filename'=>$outfile});
	$dom = $ui->{'XML::LibXML'};
	$xc = $ui->{'XML::LibXML::XPathContext'};
	$asel = '//node'
		. '['
		.   '@text'
		.   ' and matches(@text,\''.$params->{'recipient'}.'\',"i")'
		.   ' and @resource-id="com.viber.voip:id/from"'
		. ']'
	;
	@nodes = $xc->findnodes($asel);
	$N = scalar @nodes;
	if( $N == 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to find any nodes matching this XPath selector (for getting the recipient (".$params->{'recipient'}.") from the contacts on the central pane: ${asel}"); return undef }
	elsif( $N > 1 ){ $log->error("--begin matched nodes:\n".join("\n", @nodes)."\n--end nodes matched.\n\n${whoami} (via $parent), line ".__LINE__." : error, matched more than one node (see above) with this XPath selector (for getting the recipient (".$params->{'recipient'}.") from the contacts on the central pane: ${asel}"); return undef }
	$node = $nodes[0];

	# click the Recipient contact name at the bottom
	$boundstr = $node->getAttribute('bounds');
	if( ! defined $boundstr ){ $log->error("${node}\n\n${whoami} (via $parent), line ".__LINE__." : error, above node does not have attribute 'bounds'."); return undef }
	if( $boundstr !~ /\[\s*(\d+)\s*,\s*(\d+)\]\s*\[\s*(\d+)\s*,\s*(\d+)\]/ ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to parse bounds string: '$boundstr'."); return undef }
	$bounds = [[$1,$2],[$3,$4]];
	# click it
	if( $self->mother->tap({'bounds' => $bounds}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to tap on $bounds."); return undef }
	usleep(1.5);

	# Put the text into the text-edit Message... (note: ... is unicode ellipses something)
	# get the UI
	$outfile = defined($outbase) ? $outbase.'_chat.xml' : undef;
	$ui = $self->mother->dump_current_screen_ui({'filename'=>$outfile});
	$dom = $ui->{'XML::LibXML'};
	$xc = $ui->{'XML::LibXML::XPathContext'};
	$asel = '//node'
		. '['
		.   ' matches(@class,\'EditText$\',"i")'
		.   ' and @resource-id="com.viber.voip:id/send_text"'
		.   ' and @package="com.viber.voip"'
		. ']'
	;
	@nodes = $xc->findnodes($asel);
	$N = scalar @nodes;
	if( $N == 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to find any nodes matching this XPath selector (for getting the specified recipient (".$params->{'recipient'}."): ${asel}"); return undef }
	elsif( $N > 1 ){ $log->error("--begin matched nodes:\n".join("\n", @nodes)."\n--end nodes matched.\n\n${whoami} (via $parent), line ".__LINE__." : error, matched more than one node (see above) with this XPath selector (for getting the specified recipient (".$params->{'recipient'}.")): ${asel}"); return undef }
	$node = $nodes[0];
	$boundstr = $node->getAttribute('bounds');
	if( ! defined $boundstr ){ $log->error("${node}\n\n${whoami} (via $parent), line ".__LINE__." : error, above node does not have attribute 'bounds'."); return undef }
	if( $boundstr !~ /\[\s*(\d+)\s*,\s*(\d+)\]\s*\[\s*(\d+)\s*,\s*(\d+)\]/ ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to parse bounds string: '$boundstr'."); return undef }
	$bounds = [[$1,$2],[$3,$4]];
	# add the text in the node
	if( $self->mother->input_text({'bounds' => $bounds, 'text' => $message}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to input text on ${boundstr}. Note that there may be a maximum length for the message. Your message was ".length($message)." chars long."); return undef }
	sleep(1);

	# and send!
	# on the same XML we search for the send button
	$asel = '//node'
		. '['
		.   ' matches(@class,\'FrameLayout$\',"i")'
		.   ' and @resource-id="com.viber.voip:id/btn_send"'
		.   ' and @package="com.viber.voip"'
		. ']'
	;
	@nodes = $xc->findnodes($asel);
	$N = scalar @nodes;
	if( $N == 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to find any nodes matching this XPath selector (for getting the recipient (".$params->{'recipient'}.") from the contacts on the central pane: ${asel}"); return undef }
	elsif( $N > 1 ){ $log->error("--begin matched nodes:\n".join("\n", @nodes)."\n--end nodes matched.\n\n${whoami} (via $parent), line ".__LINE__." : error, matched more than one node (see above) with this XPath selector (for getting the recipient (".$params->{'recipient'}.") from the contacts on the central pane: ${asel}"); return undef }
	$node = $nodes[0];
	# click the Send button
	$boundstr = $node->getAttribute('bounds');
	if( ! defined $boundstr ){ $log->error("${node}\n\n${whoami} (via $parent), line ".__LINE__." : error, above node does not have attribute 'bounds'."); return undef }
	if( $boundstr !~ /\[\s*(\d+)\s*,\s*(\d+)\]\s*\[\s*(\d+)\s*,\s*(\d+)\]/ ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to parse bounds string: '$boundstr'."); return undef }
	$bounds = [[$1,$2],[$3,$4]];
	# click it
	if( $verbosity > 0 ){ $log->info("To: '${recipient}'\nMessage:\n${message}\n--end message.\n${whoami} (via $parent), line ".__LINE__." : about to send the above message ...") }
	if( $mock == 0 ){
		if( $self->mother->tap({'bounds' => $bounds}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to tap on $bounds."); return undef }
	} else {
		$log->warn("${whoami} (via $parent), line ".__LINE__." : The 'Send' button was not clicked because mock is ON.")
	}
	usleep(0.8);

	return {};
}

# only pod below
=pod

=encoding utf8

=head1 NAME

Android::ElectricSheep::Automator::Plugins::Apps::Viber - Control the Viber app from your desktop via the ElectricSheep Automator

=head1 VERSION

Version 0.05

=head1 WARNING

Current distribution is extremely alpha. API may change.

=head1 SYNOPSIS

An L<Android::ElectricSheep::Automator> plugin which
interacts with the Viber app from the desktop.

    use Android::ElectricSheep::Automator::Plugins::Apps::Viber;

    my $viber = Android::ElectricSheep::Automator::Plugins::Apps::Viber->new({
      'configfile' => $configfile,
      'verbosity' => 1,
      # we already have a device connected and ready to control
      'device-is-connected' => 1,
    });

    # go to home screen to start fresh
    $plugobj->mother->home_screen();

    # open the viber app
    $plugobj->open_app() or die

    # is the app running now?
    $plugobj->is_app_running() or die

    $plugobj->send_message({
        'recipient' => 'My Notes', # some of your contacts
        # 1) no unicode, 2) each space must be converted to '%s'
        'message' => 'thank%syou'
    }) or die;

=head1 CONSTRUCTOR

=head2 new($params)

Creates a new C<Android::ElectricSheep::Automator::Plugins::Apps::Viber> object. C<$params>
is a hash reference used to pass initialization options. These options are
passed onto the main constructor.
Refer to the documentation of L<Android::ElectricSheep::Automator::new($params)> for

A configuration file or hash is required.

Here is an example configuration file to get you started:

  </* $VERSION = '0.01'; */>
  </* comments are allowed */>
  </* and <% vars %> and <% verbatim sections %> */>
  {
	"Android::ElectricSheep::Automator" : {
		"adb" : {
			"path-to-executable" : "/usr/local/android-sdk/platform-tools/adb"
		},
		"debug" : {
			"verbosity" : 0,
			</* cleanup temp files on exit */>
			"cleanup" : 1
		},
		"logger" : {
			</* log to file if you uncomment this */>
			</* "filename" : "..." */>
		}
		</* config for our plugins (each can go to separate file also) */>
	},
	"Android::ElectricSheep::Automator::Plugins::Apps::Viber" : {
	}
  }

All sections are mandatory. Setting C<"adb"> to the wrong path will
yield in problems.


=head1 METHODS

=over 1

=item send_message($params)

It sends a message to one of your contacts.

It returns C<undef> on failure or a hashref on success.

C<$params> is a HASH_REF which may or should contain:

=over 4

=item B<C<recipient>>

Required name of the recipient which must be in your contacts.
(Note, I am not sure if a recipient not in the contacts can
still be used).

=item B<C<message>>

Require, the message to send. At the moment B<the message can not be unicode>.
And it can not contain any space character unless it is encoded as C< %s >.

=item B<C<mock>>

Optionally, set this flag to C<1> in order to do everything except hitting
the send button. No message will be sent. For debugging purposes.

=item B<C<outbase>>

Optionally, specify the basename to form filenames for saving UI
dumps. For debugging purposes.

=back

It needs that connect_device() to have been called prior to this call.

It returns C<undef> on failure or an (empty) hash on success.

=item navigate_to_viber_home_activity($params)

It navigates to the viber app's home screen. E.g.
if you are in your contacts screen, calling this method
will land you to the app's home screen.
It achieves this by continually pressing
the app's back-button (the left arrow at the top)
until it arrives at the home screen of the viber app.

It returns C<1> on failure or a C<0> on success.

C<$params> is a HASH_REF which may or should contain:

=over 4

=item B<C<outbase>>

Optionally, specify the basename to form filenames for saving UI
dumps. For debugging purposes.

=back

It needs that connect_device() to have been called prior to this call.

It returns C<1> on failure or C<0> on success.

=back

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-Android-ElectricSheep-Automator at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Android-ElectricSheep-Automator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Android::ElectricSheep::Automator::Plugins::Apps::Viber


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Android-ElectricSheep-Automator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Android-ElectricSheep-Automator>

=item * Search CPAN

L<https://metacpan.org/release/Android-ElectricSheep-Automator>

=back

=head1 SEE ALSO

=over 4

=item * L<Android::ADB> is a thin wrapper of the C<adb> command
created by Marius Gavrilescu, C<marius@ieval.ro>.
It is used by current module, albeit modified.

=back

=head1 HUGS

=over 4

=item * Πτηνού, my chicken, now laying in the big coop in the sky ...

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Android::ElectricSheep::Automator::Plugins::Apps::Viber


1;
