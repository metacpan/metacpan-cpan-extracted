package Android::ElectricSheep::Automator::ScreenLayout;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

use Mojo::Log;
use Config::JSON::Enhanced;
use XML::XPath;
use XML::LibXML;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use overload ( '""'  => \&toString );

sub new {
	my $class = $_[0];
	my $params = $_[1] // {};

        my $parent = ( caller(1) )[3] || "N/A";
        my $whoami = ( caller(0) )[3];

	my $self = {
		'_private' => {
			'xml' => undef,
			'logger-object' => undef,
			'verbosity' => 0,
		},
		'data' => {
			'w' => 0,
			'h' => 0,
					# x1,y1,x2,y2,w,h
			'top-area' => [0, 0, 0, 0, 0, 0],
					# x1,y1,x2,y2,w,h
			'app-icons-area' => [0, 0, 0, 0, 0, 0],
					# x1,y1,x2,y2,w,h
			'dock-divider-area' => [0, 0, 0, 0, 0, 0],
					# x1,y1,x2,y2,w,h
			# these are some common apps which don't change if you swipe screens i think
			'hotseat-area' => [0, 0, 0, 0, 0, 0],
					# x1,y1,x2,y2,w,h
			'home-buttons-area' => [0, 0, 0, 0, 0, 0],
			'apps' => {}, # appname => [bounds x1,y1,x2,y2]
			'screen-name' => '',
		}
	};
	bless $self => $class;

	if( exists $params->{'logger-object'} ){ $self->{'_private'}->{'logger-object'} = $params->{'logger-object'} } else { $self->{'_private'}->{'logger-object'} = Mojo::Log->new() }
	if( exists $params->{'verbosity'} ){ $self->{'_private'}->{'verbosity'} = $params->{'verbosity'} } else { $self->{'_private'}->{'verbosity'} = Mojo::Log->new() }
	# we now have a log and verbosity

	my $log = $self->log;
	my $verbosity = $self->verbosity;

	if( exists $params->{'data'} ){
		my $d = $self->{'data'}; 
		my $p = $params->{'data'};
		for my $k (sort keys %$d){
			if( exists($p->{$k}) && defined($p->{$k}) ){
				if( $self->set($k, $p->{$k}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'set()'." has failed for input parameter '$k', is its type as expected (".ref($d->{$k}).")?"); return undef }
			}
		}
	}

	if( exists $params->{'xml-string'} ){
		if( ! defined $self->fromXML({'xml-string' => $params->{'xml-string'}}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'fromXML()'." has failed."); return undef }
	} elsif( exists $params->{'xml-filename'} ){
		if( ! defined $self->fromXML({'xml-filename' => $params->{'xml-filename'}}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'fromXML()'." has failed this XML file: '".$params->{'xml-filename'}."'."); return undef }
	}

	return $self;
}

# parses a UI Automator XML dump either from
# file: 'xml-filename' => ...
# or from a string: 'xml-string' => ...
# It returns 1 on error, 0 on success
# The big problem is incompatibility of the XML between Android API versions
# if you specify 'fully' => 1, it works fine with our real phone
# but it fails with API 30. So, we are happy only to find the width and
# height from that XML. That means that all fields except 'w' and 'h'
# will not be found here.
#   my $xmlstring = $self->dump_current_screen_ui();
#   my $sl = Android::ElectricSheep::Automator::ScreenLayout->new({'xml-string' => $xmlstring});
# will call fromXML();
# Or make it yourself: adb shell uiautomator dump outfile
# or adb exec-out uiautomator dump /dev/tty | awk '{gsub("UI hierchary dumped to: /dev/tty", "");print}'
sub fromXML {
	my ($self, $params) = @_;
	$params //= {};

        my $parent = ( caller(1) )[3] || "N/A";
        my $whoami = ( caller(0) )[3];

	my $log = $self->log;
	my $verbosity = $self->verbosity;

	my $doc;
	if( exists $params->{'xml-filename'} ){
		$doc = XML::LibXML->load_xml(location => $params->{'xml-filename'});
	} elsif( exists $params->{'xml-string'} ){
		$doc = XML::LibXML->load_xml(string => $params->{'xml-string'});
	}
	if( ! defined $doc ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'XML::XPath->new()'." has failed."); return undef }

	# find a node AT THE TOP for setting the width and height
	#    text=""
	#    content-desc=""
	#    resource-id=""
	#    class="android.view.FrameLayout"
	my $xpath = '/hierarchy/node[@text=\'\' and @resource-id=\'\' and @class=\'android.widget.FrameLayout\']';
	my $numframes = 0; # paranoid check how many frames found?
	my @nodes = eval { $doc->findnodes($xpath) };
	if( $@ ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'findnodes()'." has failed for this xpath: $xpath : $@"); return undef };
	foreach my $anode (@nodes){
		# the whole screen size is in bounds
		my $bounds = $anode->getAttribute('bounds');
		$bounds =~ s/\s+//;
		if( $bounds =~ /^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$/ ){
			my ($x1, $y1, $x2, $y2) = ($1, $2, $3, $4);
			$self->set('w', $x2-$x1);
			$self->set('h', $y2-$y1);
		} else { $log->error($anode."\n${whoami} (via $parent), line ".__LINE__." : error, above node has invalid bounds/1."); return undef }
		$numframes++;
	}
	if( $numframes != 1 ){ $log->error($doc."\n${whoami} (via $parent), line ".__LINE__." : error, failed to find exactly one node with XPath=${xpath} but found ${numframes} instead, see above xml."); return undef }

	if( exists($params->{'fully'}) && defined($params->{'fully'}) && ($params->{'fully'}==1) ){
		# find the app-icons-area, it may not be there
		#    text=""
		#    content-desc=""
		#    resource-id="com.huawei.android.launcher:id/workspace_screen" <<<< we will filterout huawei
		#    class="android.view.ViewGroup"
		# ONLY XPATH1 is supported, so no ends-with or matching regex, we have to filter ourselves
		#my $xpath = '//node[@text=\'\' and @class=\'android.view.ViewGroup\' and ends-with(@resource-id, \'/workspace_screen\')]';
		$xpath = '//node[@text=\'\' and @content-desc=\'\' and @class=\'android.view.ViewGroup\' and contains(@resource-id, \'/workspace_screen\')]';
		$numframes = 0; # paranoid check how many frames found?
		@nodes = eval { $doc->findnodes($xpath) };
		if( $@ ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'findnodes()'." has failed for this xpath: $xpath"); return undef };
		foreach my $anode (@nodes){
			my $resource_id = $anode->getAttribute('resource-id');
			if( $resource_id =~ /\/workspace_screen$/i ){
				my $bounds = $anode->getAttribute('bounds');
				$bounds =~ s/\s+//;
				if( $bounds =~ /^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$/ ){
					my ($x1, $y1, $x2, $y2) = ($1, $2, $3, $4);
					$self->set('app-icons-area', [$x1, $y1, $x2, $y2, $x2-$x1, $y2-$y1]);
				} else { $log->error($anode."\n${whoami} (via $parent), line ".__LINE__." : error, above node has invalid bounds/2."); return undef }
				$numframes++;
			} else { $log->error($anode."\n${whoami} (via $parent), line ".__LINE__." : error, above node has unexpected 'resource-id' ($resource_id), does not end in 'workspace_screen'."); return undef }
		}
		if( $numframes != 1 ){ $log->warn($doc."\n${whoami} (via $parent), line ".__LINE__." : error, failed to find exactly one node with XPath=${xpath} but found ${numframes} instead, see above xml.") }

		# now search for dock_divider to find its dimensions, it may not be there
		#  text=""
		#  resource-id="com.huawei.android.launcher:id/dock_divider"
		#  class="android.widget.ImageView"
		#  content-desc="Page indicator"
		$xpath = '//node[@text=\'\' and @class=\'android.widget.ImageView\' and @content-desc=\'Page indicator\' and contains(@resource-id, \'id/dock_divider\')]';
		$numframes = 0;
		@nodes = eval { $doc->findnodes($xpath) };
		if( $@ ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'findnodes()'." has failed for this xpath: $xpath"); return undef };
		foreach my $anode (@nodes){
			my $resource_id = $anode->getAttribute('resource-id');
			if( $resource_id =~ /\/dock_divider$/i ){
				# the app-icons space is inside a frame
				my $bounds = $anode->getAttribute('bounds');
				$bounds =~ s/\s+//;
				if( $bounds =~ /^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$/ ){
					my ($x1, $y1, $x2, $y2) = ($1, $2, $3, $4);
					$self->set('dock-divider-area', [$x1, $y1, $x2, $y2, $x2-$x1, $y2-$y1]);
				} else { $log->error($anode."\n${whoami} (via $parent), line ".__LINE__." : error, above node has invalid bounds/3."); return undef }
				$numframes++;
			} else { $log->error($anode."\n${whoami} (via $parent), line ".__LINE__." : error, above node has unexpected 'resource-id' ($resource_id), does not end in 'dock_divider'."); return undef }
		}
		if( $numframes != 1 ){ $log->warn($doc."\n${whoami} (via $parent), line ".__LINE__." : error, failed to find exactly one node with XPath=${xpath} but found ${numframes} instead, see above xml.") }

		# now search for hotseat (the common apps at the bottom invariant to swiping)
		#  text=""
		#  resource-id="com.huawei.android.launcher:id/hotseat"
		#  class="android.widget.FrameLayout"
		#  content-desc=""
		$xpath = '//node[@text=\'\' and @class=\'android.widget.FrameLayout\' and @content-desc=\'\' and contains(@resource-id, \'id/hotseat\')]';
		$numframes = 0;
		@nodes = eval { $doc->findnodes($xpath) };
		if( $@ ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'findnodes()'." has failed for this xpath: $xpath"); return undef };
		foreach my $anode (@nodes){
			my $resource_id = $anode->getAttribute('resource-id');
			if( $resource_id =~ /\/hotseat$/i ){
				# the app-icons space is inside a frame
				my $bounds = $anode->getAttribute('bounds');
				$bounds =~ s/\s+//;
				if( $bounds =~ /^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$/ ){
					my ($x1, $y1, $x2, $y2) = ($1, $2, $3, $4);
					$self->set('hotseat-area', [$x1, $y1, $x2, $y2, $x2-$x1, $y2-$y1]);
				} else { $log->error($anode."\n${whoami} (via $parent), line ".__LINE__." : error, above node has invalid bounds/4."); return undef }
				$numframes++;
			} else { $log->error($anode."\n${whoami} (via $parent), line ".__LINE__." : error, above node has unexpected 'resource-id' ($resource_id), does not end in 'hotseat'."); return undef }
		}
		if( $numframes != 1 ){ $log->warn($doc."\n${whoami} (via $parent), line ".__LINE__." : error, failed to find exactly one node with XPath=${xpath} but found ${numframes} instead, see above xml.") }

		# the screen name, it may not be there
		# find a node with
		#    text=""
		#    content-desc="Screen 2 of 5"
		#    resource-id="com.huawei.android.launcher:id/workspace" <<<< we will filterout huawei
		#    class="android.view.ViewGroup"
		# ONLY XPATH1 is supported, so no ends-with or matching regex, we have to filter ourselves
		#my $xpath = '//node[@text=\'\' and @class=\'android.view.ViewGroup\' and ends-with(@resource-id, \'/workspace\')]';
		$xpath = '//node[@text=\'\' and @text=\'\' and @class=\'android.view.ViewGroup\' and contains(@resource-id, \'/workspace\')]';
		$numframes = 0; # paranoid check how many frames found?
		@nodes = eval { $doc->findnodes($xpath) };
		if( $@ ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'findnodes()'." has failed for this xpath: $xpath"); return undef };
		foreach my $anode (@nodes){
			my $resource_id = $anode->getAttribute('resource-id');
			if( $resource_id =~ /\/workspace$/i ){
				my $screenname = $anode->getAttribute('content-desc');
				if( ! defined($screenname) || ($screenname =~ /^\s*$/) ){ $log->error("$anode\n${whoami} (via $parent), line ".__LINE__." : error, above node has the right class (android.widget.TextView) but its text is empty and it should have been the screen-name instead."); return undef }
				$self->set('screen-name', $screenname);
				$numframes++;
			}
		}
		if( $numframes != 1 ){ $log->warn($doc."\n${whoami} (via $parent), line ".__LINE__." : error, failed to find exactly one node with XPath=${xpath} but found ${numframes} instead, see above xml.") }

		# now search for the apps
		#  text=""
		#  resource-id="com.huawei.android.launcher:id/workspace_screen"
		#  class="android.view.ViewGroup"
		#  content-desc=""
		# and then it has a child of 
		#  class="android.widget.TextView"
		#  content-desc=""
		#  resource-id=""
		#  text="<appname>" 
		$xpath = '//node[@text=\'\' and @class=\'android.view.ViewGroup\' and @content-desc=\'\' and contains(@resource-id, \'id/workspace_screen\')]/node[@class=\'android.view.ViewGroup\']/node[@class=\'android.widget.TextView\']';
		@nodes = eval { $doc->findnodes($xpath) };
		if( $@ ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'findnodes()'." has failed for this xpath: $xpath"); return undef };
		my %apps = ();
		foreach my $anode (@nodes){
			my $class = $anode->getAttribute('class');
			if( $class =~ /^android.widget.TextView$/ ){
				# the app-icons space is inside a frame
				my $appname = $anode->getAttribute('text');
				if( ! defined($appname) || ($appname =~ /^\s*$/) ){ $log->error("$anode\n${whoami} (via $parent), line ".__LINE__." : error, above node has the right class (android.widget.TextView) but its text is empty and it should have been the app-name instead."); return undef }
				my $bounds = $anode->getAttribute('bounds');
				$bounds =~ s/\s+//;
				if( $bounds =~ /^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$/ ){
					$apps{$appname} = [$1,$2,$3,$4];
				} else { $log->error($anode."\n${whoami} (via $parent), line ".__LINE__." : error, above node has invalid bounds/4."); return undef }
			} else { $log->error($anode."\n${whoami} (via $parent), line ".__LINE__." : error, above node has unexpected 'class', it is not 'android.widget.TextView'."); return undef }
		}
		$self->set('apps', \%apps);
	} # end 'fully' params exists

	return 0; # success
}

sub get { return $_[0]->has($_[1]) ? $_[0]->{'data'}->{$_[1]} : undef }
sub set {
	# set a new value even if it is not in our store,
	# but if it is, then check the types match
	if( exists($_[0]->{'data'}->{$_[1]})
	 && (ref($_[2]) ne ref($_[0]->{'data'}->{$_[1]}))
	){ $_[0]->log()->error(__PACKAGE__."::set(), line ".__LINE__." : error, the type of parameter '$_[1]' is '".ref($_[2])."' but '".ref($_[0]->{'data'}->{$_[1]})."' was expected."); return 1 }
	$_[0]->{'data'}->{$_[1]} = $_[2];
	return 0; # success
}
sub has { exists $_[0]->{'data'}->{$_[1]} }

sub toString {
	# unfortunately as a hash it is unsorted
	return perl2dump($_[0]->{'data'}, {terse=>1,pretty=>1});
}
sub toJSON { return perl2json($_[0]->{'data'}, {pretty=>1}); }
sub TO_JSON { return $_[0]->{'data'} }

sub log { return $_[0]->{'_private'}->{'logger-object'} }
sub verbosity { return $_[0]->{'_private'}->{'verbosity'} }

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
