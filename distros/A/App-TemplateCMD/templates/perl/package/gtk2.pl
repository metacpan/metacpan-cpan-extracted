[% IF not vars %][% vars = [ 'search' ] %][% END -%]
[% IF not module %][% module = 'Module::Name' %][% END -%]
[% IF not super %][% super = 'Gtk2::Button::' %][% END -%]
package [% module %];

=head1 NAME

[% module %] - <One-line description of module's purpose>

[% INCLUDE perl/pod/VERSION.pl %]
[% INCLUDE perl/pod/SYNOPSIS.pl %]
[% INCLUDE perl/pod/DESCRIPTION.pl %]
[% INCLUDE perl/pod/METHODS.pl %]
[% INCLUDE perl/pod/detailed.pl %]
=head1 AUTHOR

[% contact.fullname %] - ([% contact.email %])

=head1 LICENSE AND COPYRIGHT
[% INCLUDE licence.pl %]
=cut

# Created on: [% date %] [% time %]
# Create by:  [% contact.fullname or user %]

use strict;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;

use Scalar::Util;
use List::Util;
#use List::MoreUtils;

use CGI;
use Gtk2;
use base qw/Exporter/;

our $VERSION = 0.0.1;
our @EXPORT = qw//;
our @EXPORT_OK = qw//;

use Glib::Object::Subclass (
	[% super %],
	signals		=> {
		signal	=> {} or \&sub,
	},
	properties	=> [
		Glib::ParamSpec->init(
			'', 	# name
			'', 	# nickname/label?
			'', 	# description
			0,		# min
			'inf',	# max
			0,		# default
			[qw/readable writable/],	# flags
		),
	],
);

[% INCLUDE perl/pod.pl return => module -%]

# effectively serves as new
sub INIT_INSTANCE {
	my $self = shift;

}


1;

 =__END__

