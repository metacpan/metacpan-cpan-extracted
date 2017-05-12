package Config::Param::FileWorker;

use Config::Param;
use IO::File;
use Storable qw(dclone);

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->{config} = shift;
	$self->{config}{nofinals} = 1;
	$self->{pardef} = shift;
	$self->{pars} = Config::Param->new($self->{config},$self->{pardef});	
	$self->{defpars} = dclone($self->{pars}{param});
	return $self;
}

sub init_with_args
{
	my $self = shift;
	my $args = shift;
	$args = \@ARGV unless defined $args;
	$self->{pars}->parse_args($args);
	$self->{pars}->use_config_files();
	$self->{pars}->apply_args();
	my $good = (not @{$self->{pars}{errors}});
	$self->{pars}{errors} = [];
	return $good;
}

sub store_defaults
{
	my $self = shift;
	$self->{defpars} = dclone($self->{pars}{param});
}

sub load_defaults
{
	my $self = shift;
	$self->{pars}{param} = dclone($self->{defpars});
}

sub param
{
	my $self = shift;
	# Yes, it's a direct reference.
	return $self->{pars}{param};
}

sub load_file
{
	my $self = shift;
	my $file = shift;
	$self->{pars}->parse_file($file);
	my $good = (not @{$self->{pars}{errors}});
	$self->{pars}{errors} = [];
	return $good;
}

sub store_file
{
	my $self = shift;
	my $file = shift;
	$file = undef if defined $file and $file eq '';
	my $fh = \*STDOUT;
	if(defined $file)
	{
		$fh = IO::File->new();
		$fh->open($file, '>') or return 0;
	}
	$self->{pars}->print_file($fh);
	$fh->close();
	my $good = (not @{$self->{pars}{errors}});
	$self->{pars}{errors} = [];
	return $good;
}

1;

__END__

=head1 NAME

Config::Param::FileWorker - work with L<Config::Param|Config::Param>-style configuration files for this program

=head1 SYNOPSIS

	my $pfw = Config::Param::FileWorker->new(\%config, \@pardef);
	$param = $pfw->param();
	$pfw->load_file($filename);	
	print "Got value $param->{key} for parameter key out of file $filename.\n";

=head1 DESCRIPTION

This facilitates changes to the configuration of a program while running by reading different config files on demand. See L<Config::Param|Config::Param> for background and also on configuration syntax.

=head1 METHODS

=over 2

=item B<new>

The constructor, taking L<Config::Param|Config::Param>-style config hash and parameter definition.

	my $pfw = Config::Param::FileWorker->new(\%config, \@pardef);

=item B<param>

Access the internal parameter storage for retrieval or modification.

	$param = $pfw->param();
	$param->{key} = $something;

=item B<load_file>

Load values from a configuration file.

	$pfw->load_file($filename);

=item B<store_file>

Store values in a configuration file (overwrite it).

	$pfw->store_file($filename);

=item B<init_with_args>

Parse command line arguments (@ARGV if none given explicitly) and indicated/automatically found configuration files. Basically this is how a normal program using L<Config::Param|Config::Param> starts.

	$pfw->init_with_args(); # uses @ARGV
	$pfw->init_with_args(\@args);

=item B<load_defaults>

Reset parameter storage to default values.

	$pfw->load_defaults();

=item B<store_defaults>

Store current state of parameter storage as defaults.

	$pfw->store_defaults();

=back

=head1 AUTHOR

Thomas Orgis <thomas@orgis.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2012, Thomas Orgis.

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut
