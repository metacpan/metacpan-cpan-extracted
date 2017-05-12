package Benchmark::Featureset::SetOps::Config;

use strict;
use warnings;

use Config::Tiny;

use File::HomeDir;

use Moo;

use Path::Class;

use Types::Standard qw/Any Str/;

has config =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has config_file_path =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has section =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.06';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;
	my($path) = Path::Class::file(File::HomeDir -> my_dist_config('Benchmark-Featureset-SetOps'), '.htbenchmark.featureset.setops.conf');

	$self -> read($path);

} # End of BUILD.

# -----------------------------------------------

sub read
{
	my($self, $path) = @_;

	$self -> config_file_path($path);

	# Check [global].

	$self -> config(Config::Tiny -> read($path) );

	if (Config::Tiny -> errstr)
	{
		die Config::Tiny -> errstr;
	}

	$self -> section('global');

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]\n";
	}

	# Check [x] where x is host=x within [global].

	$self -> section(${$self -> config}{$self -> section}{'host'});

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]\n";
	}

	# Move desired section into config, so caller can just use $self -> config to get a hashref.

	$self -> config(${$self -> config}{$self -> section});

}	# End of read.

# --------------------------------------------------

1;

=pod

=head1 NAME

Benchmark::Featureset::SetOps::Config - Compare various array/set handling modules

=head1 Synopsis

See L<Benchmark::Featureset::SetOps>.

=head1 Description

L<Benchmark::Featureset::SetOps> compares verious array/set handling modules.

=head1 Methods

=head2 init()

For use by subclasses.

Sets default values for object attributes.

=head2 new()

For use by subclasses.

=head2 read()

read() is called by new(). It does the actual reading of the config file.

If the file can't be read, die is called.

The path to the config file is determined by:

	Path::Class::file(File::HomeDir -> my_dist_config('Benchmark-Featureset-SetOps'), '.htbenchmark.featureset.setops.conf');

During installation, you should have run scripts/copy.config.pl, which uses the same code, to move the config file
from the config/ directory in the disto into an OS-dependent directory.

The run-time code uses this module to look in the same directory as used by scripts/copy.config.pl.

=head1 Repository

L<https://github.com/ronsavage/Benchmark-Featureset-SetOps>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Benchmark::Featureset::SetOps>.

=head1 Author

L<Benchmark::Featureset::SetOps> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
