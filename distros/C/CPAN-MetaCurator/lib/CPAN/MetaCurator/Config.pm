package CPAN::MetaCurator::Config;

use 5.36.0;
use boolean;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Config::Tiny;

use File::Spec;

use Mojo::Log;
use Moo;

use Types::Standard qw/ArrayRef HashRef Object Str/;

has config =>
(
	default		=> sub{return {} },
	is			=> 'rw',
	isa			=> HashRef,
	required	=> 1,
);

has config_path =>
(
	default		=> sub{return 'data/cpan.metacurator.conf'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);


has database_path =>
(
	default		=> sub{return 'data/cpan.metacurator.sqlite'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has error =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has home_path =>
(
	default		=> '',
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

# Available log levels are trace, debug, info, warn, error and fatal, in that order.

has log_level =>
(
	default		=> sub{return 'info'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has logger =>
(
	is			=> 'rw',
	isa			=> Object,
	required	=> 0,
);

has logo_path =>
(
	default		=> '',
	is			=> 'rw',
	isa			=> Str,
	required	=> 1,
);

has node_types =>
(
	default		=> sub{return [qw/acronym leaf see_also topic unknown/]},
	is			=> 'rw',
	isa			=> ArrayRef,
	required	=> 0,
);

has separator =>
(
	default		=> '-' x 50,
	is			=> 'ro',
	isa			=> Str,
	required	=> 0,
);

# Warning. Order is important because of foreign key constraints.
# The tables are created in this order, and dropped in reverse order.
# Lastly, we process the topics table to extract the module names.
# See also Database.build_pad().

has table_names =>
(
	default		=> sub{return [qw/constants log modules topics/]},
	is			=> 'rw',
	isa			=> ArrayRef,
	required	=> 0,
);

has tiddlers_path =>
(
	default		=> sub{return 'data/tiddlers.json'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

our $VERSION = '1.11';

# -----------------------------------------------

sub init_config
{
	my($self)				= @_;
	my($path)				= File::Spec -> catfile($self -> home_path, $self -> config_path);
	my($config)				= $self -> config($self -> _init_config($path) );
	$$config{config_path}	= $path;
	$$config{log_path}		= File::Spec -> catfile($self -> home_path, $$config{log_path});

	$self -> config($config);
	$self -> logger(Mojo::Log -> new(level => $self -> log_level, path => $$config{log_path}) );

} # End of init_config.

# -----------------------------------------------

sub _init_config
{
	my($self, $path) = @_;

	# Section: [global].

	my($config) = Config::Tiny -> read($path);

	die 'Error: ' . Config::Tiny -> errstr . "\n" if (Config::Tiny -> errstr);

	# Sections: [localhost] and [webhost].

	my($section);

	for my $i (1 .. 2)
	{
		$section = $i == 1 ? 'global' : $$config{$section}{host};

		$self -> error("Error: Config file '$path' does not contain the section [$section]") if (! $$config{$section});
	}

	return $$config{$section};

}	# End of _init_config.

# --------------------------------------------------

1;

=head1 NAME

CPAN::MetaCurator::Config - Manage the cpan.metacurator.sqlite database

=head1 Synopsis

See L<CPAN::MetaCurator/Synopsis>.

=head1 Description

L<CPAN::MetaCurator> implements an interface to the 'levies' database.

=head1 Methods

=head2 config()

Returns a hashref of options read from the config file, which defaults to
C<config_name()> (data/cpan.metacurator.conf) under C<home_path()>.

=head2 config_name()

Returns a string holding the dir/name of the config file.

=head1 Support

Email the author.

=head1 Author

C<CPAN::MetaCurator> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2025.

L<Home page|https://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2025, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License V 2, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
