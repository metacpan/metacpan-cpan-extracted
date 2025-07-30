package Android::ElectricSheep::Automator::XMLParsers;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

use Mojo::Log;
use XML::LibXML;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

# This parser is for parsing UI Automator dump of the screen
# which comes up when you swipe from the bottom up
# which brings all the installed apps, we will find all
# those apps (name+coordinates) and return them as a hash
# keyed on app name.
# e.g. myappname => {'name' => myappname, 'bounds' => [x1,y1,x2,y2]}
# It takes in a UI Automator XML dump either from:
#         a file  : 'xml-filename' => ...
# or from a string: 'xml-string' => ...
# It returns the apps as a HASHref (keyed on appname) on success
# or undef on failure.
#   my $xmlstring = $self->dump_current_screen_ui();
#   my $ret = Android::ElectricSheep::Automator::XMLParsers::XMLParser_find_all_apps(
#    {'xml-string' => $xmlstring}
#   );
# will call fromXML();
# Or make it yourself: adb shell uiautomator dump outfile
# or adb exec-out uiautomator dump /dev/tty | awk '{gsub("UI hierchary dumped to: /dev/tty", "");print}'
sub XMLParser_find_all_apps {
	my $params = $_[0];
	$params //= {};

        my $parent = ( caller(1) )[3] || "N/A";
        my $whoami = ( caller(0) )[3];

	my $log = (exists($params->{'log'}) && defined($params->{'log'})) ? $params->{'log'} : Mojo::Log->new;
	my $verbosity = (exists($params->{'verbosity'}) && defined($params->{'verbosity'})) ? $params->{'verbosity'} : 0;

	my $doc;
	if( exists($params->{'xml-filename'}) && defined($params->{'xml-filename'}) ){
		$doc = eval { XML::LibXML->load_xml(location => $params->{'xml-filename'}) };
		if( $@ || (! defined $doc) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'XML::LibXML->load_xml()'." has failed for file '".$params->{'xml-filename'}."' : $@"); return undef }
	} elsif( exists($params->{'xml-string'}) && defined($params->{'xml-string'}) ){
		$doc = eval { XML::LibXML->load_xml(string => $params->{'xml-string'}) };
		if( $@ || (! defined $doc) ){ $log->error($params->{'xml-string'}."\n${whoami} (via $parent), line ".__LINE__." : error, call to ".'XML::LibXML->load_xml()'." has failed for above XML string: $@"); return undef }
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : error, either 'xml-filename' or 'xml-string' must be specified in the input parameters."); return undef }

	# find a node AT THE TOP for setting the width and height
	#    text=""
	#    content-desc=""
	#    resource-id=""
	#    class="android.view.FrameLayout"
	my $xpath =
		  '/hierarchy/node'
		. '//node[contains(@resource-id, \'id/apps_view\')]'
		. '/node[contains(@resource-id, \'id/apps_list_view\')]'
		. '/node[contains(@resource-id, \'id/icon\') and @class=\'android.widget.TextView\']'
	;
	my @nodes = eval { $doc->findnodes($xpath) };
	if( $@ ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'findnodes()'." has failed for this xpath: $xpath : $@"); return undef };
	my %ret;
	foreach my $anode (@nodes){
		my $appname = $anode->getAttribute('text');
		my $bounds = $anode->getAttribute('bounds');
		$bounds =~ s/\s+//;
		my %item = (
			'name' => $appname
		);
		if( $bounds =~ /^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$/ ){
			$item{'bounds'} = [$1, $2, $3, $4];
		} else { $log->error($anode."\n${whoami} (via $parent), line ".__LINE__." : error, above node has invalid bounds/1."); return undef }
		$ret{$appname} = \%item;
	}
	return \%ret;
}

# this can be registered with XML::LibXML in order to
# allow regex searches
# using
# my $dom = XML::LibXML->load_xml(xml=>string);
# my $xc = XML::LibXML::XPathContext->new($dom);
# $xc->registerFunction('matches', \&grep_nodes);
# $xc->findnodes('//div[@id="aa" and matches(@text,".*[tT]oWn$","i")]');
# see https://stackoverflow.com/a/73270935
sub xpath_matches {
  my ($input,$pattern,$flg) =  @_;
  $flg = '' if !defined ($flg);
  return 1 if $input =~ /(?$flg)$pattern/;
  return undef;
}

# only pod below
=pod

=head1 NAME

Android::ElectricSheep::Automator - The great new Android::ElectricSheep::Automator!

=head1 VERSION

Version 0.06


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Android::ElectricSheep::Automator;

    my $foo = Android::ElectricSheep::Automator->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1



=head2 function2


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-android-adb-automator at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Android-ADB-Automator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Android::ElectricSheep::Automator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Android-ADB-Automator>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Android-ADB-Automator>

=item * Search CPAN

L<https://metacpan.org/release/Android-ADB-Automator>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Android::ElectricSheep::Automator
