package CPAN::MetaCurator::Config;

use boolean;
use feature 'say';

use Config::Tiny;

use Data::Dumper::Concise; # For Dumper().

use File::Spec;

use Mew;
use Mojo::Log;

use utf8;

has config => (HashRef, default => sub {return {} }, chained => 1);

has -config_path => (Str, default => 'data/cpan.metacurator.conf');

has database_path => (Str, default => 'data/cpan.metacurator.sqlite');

has -error => (Str, default => '', chained => 1);

has home_path => (Str, default => '', chained => 1);

# Available log levels are trace, debug, info, warn, error and fatal, in that order.

has -log_level => (Str, default => 'info', chained => 1);

has -logger => (Object, chained => 1);

has metapackager_config => (HashRef, default => sub {return {} }, chained => 1);

has -metapackager_config_path => (Str, default => 'data/cpan.metapackager.conf');

has -metapackager_database_path => (Str, default => '/tmp/cpan.metapackager.sqlite');

has -node_types => (ArrayRef, default => sub {return [qw/acronym known leaf see_also topic unknown/]});

# Warning. Order is important because of foreign key constraints.
# The tables are created in this order, and dropped in reverse order.
# Lastly, we process the topics table to extract the module names.
# See also Database.build_pad().

has -table_names => (ArrayRef, default => sub{return [qw/constants log modules topics/]});

has -tiddlers_path => (Str, default => 'data/tiddlers.json');

has -visual_break => (Str, default => sub{return '-' x 50});

our $VERSION = '1.27';

# -----------------------------------------------

sub init_config
{
	my($self)			= @_;
	my($path)			= File::Spec -> catfile($self -> home_path, $self -> config_path);
	my($conf)			= Config::Tiny -> read($path);
	$conf				= $conf -> {_};
	$$conf{config_path}	= $path;
	$$conf{log_path}	= File::Spec -> catfile($self -> home_path, $$conf{log_path});

	$self -> config($conf);
	$self -> logger(Mojo::Log -> new(level => $self -> log_level, path => $$conf{log_path}) );

	# Fix me. Test UTF8 char handling.

	$self -> logger -> info("Testing write of utf8 chars to logger. I ♥ Mojolicious");
	$self -> logger -> debug("Leaving Config.init_config()");

} # End of init_config.

# -----------------------------------------------

sub init_metapackager_config
{
	my($self)			= @_;
	my($path)			= File::Spec -> catfile($self -> home_path, $self -> metapackager_config_path);
	my($conf)			= Config::Tiny -> read($path);
	$conf				= $conf -> {_};
	$$conf{config_path}	= $path;

	$self -> metapackager_config($conf);
	$self -> logger -> debug("Leaving Config.init_metapackager_config()");

} # End of init_metapackager_config.

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
