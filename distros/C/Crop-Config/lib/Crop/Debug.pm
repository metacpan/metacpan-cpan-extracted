package Crop::Debug;
use base qw/ Crop Exporter /;

=begin nd
Class: Crop::Debug
	Debug output.

	Each message has a specific Layer. Layers are independent one with other.
	
	There're Layers:
	
	DL_APP - "APPlication" layer. This is a default layer for general purpose. Don't leave such messages in the production code to avoid huge number of dirty stuffs.
	DL_SRV - "SeRVer" layer. This describes the main server logic (<Crop::Server>).
	DL_SQL  - serves database logic.

	To switch On output layer you have to include an element <layer name="SRV"/> to the main config file.
	<output="off"> disables output at all.

Example:
(start code)
# print dump
debug $hash_ref;

# layer specified
debug DL_SRV, "\$var=$var; object=", $object;
(end)
=cut

use v5.14;
use warnings;
no warnings 'experimental::smartmatch';

use Encode qw/ encode /;
use Data::Dumper;
use Time::Stamp -stamps => {dt_sep => ' ', ms => 1};

use vars qw/ @EXPORT /;
@EXPORT = qw/ &debug DL_APP DL_SRV DL_SQL /;

=begin nd
Constant: Prefix
	common prefix for all exported layers constants
=cut
use constant {
	Prefix => 'DL_',
};

=begin nd
Constants: Layers to export:

Constant: DL_APP
		application layer (default)

Constant: DL_SRV
		Server logic

Constant: DL_SQL
		database
=cut
use constant {
	DL_APP => Prefix . 'APP',
	DL_SRV => Prefix . 'SRV',
	DL_SQL => Prefix . 'SQL',
};

=begin nd
Constant: DefaultLayer
	<debug (@messages)> without the layer spicified <debug (@messages) will use this layer.
=cut
use constant {
	DefaultLayer => DL_APP,
};

=begin nd
Variable: my @Layer_const
	All the debugging Layers with.
=cut
my @Layer_const = qw/ DL_APP DL_SRV DL_SQL /;

=begin nd
Function: debug ($layer, @messages)
	Print debug message according to the settings in the config.

Parameters:
	$layer    - output Layer; optional
	@messages - output items; if item is a reference, will print dump
=cut
sub debug {
	my $layer = $_[0] && $_[0] ~~ @Layer_const ? shift : DefaultLayer;

	# drop the layer prefix to print in a config-fasion manner
	my $prefix = Prefix;
	(my $short) = $layer =~ /^$prefix(\w+)$/;
	
	return unless _verbose($short);
	
	my $script = $0 =~ /public_html(\S+)/ ? $1 : ''; # script name
	my $output = localstamp() . " $script (pid=$$) Debug[$short]: ";
	for my $arg (@_) {
		$arg = '' unless defined $arg;
		$output .= ref $arg ? Dumper $arg : $arg;
	}
	$output .= "\n";

	print STDERR encode 'utf8', $output;
	flush STDERR;
}

=begin nd
Function: _verbose ($layer)
	Is the layer has to be printed?
	
Parameters:
	$layer - a layer name in form of a global.xml config, for example, 'SRV'.

Returns:
	true  - output ON
	false - output OFF
=cut
sub _verbose {
	my $layer = shift;

	my $conf = Crop->C->{debug};
	return 1 unless $conf->{output} eq 'On';
	
	return unless exists $conf->{layer};
	
	$layer ~~ @{$conf->{layer}};
}

1;
