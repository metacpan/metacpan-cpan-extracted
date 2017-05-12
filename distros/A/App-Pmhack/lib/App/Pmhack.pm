package App::Pmhack;
BEGIN {
  $App::Pmhack::VERSION = '0.002';
}

# ABSTRACT: Hack on installed Perl modules

use strict;
use warnings;

use Perl6::Export::Attrs;
use English        qw($OSNAME);
use Carp           qw(carp croak);
use File::Copy     qw(copy);
use Module::Load   qw();
use Module::Locate qw();
use File::Path     qw();
use Params::Util   qw();
use Try::Tiny      qw(try catch);

sub pmhack :Export
{
	my $module_name   = Params::Util::_CLASS(shift) or croak "Please supply a valid module name";
	my $hacklib       = $ENV{PERL5HACKLIB}          or croak "PERL5HACKLIB environment variable not set, aborting";
	
	# SAMPLE VALUES
	# =============
	# $module_name:     Some::Interesting::Module
	# $inc_filename:    /usr/lib/perl5/Some/Interesting/Module.pm
	# $hacklib:         /usr/supermario/pmhacklib
	# $target_filename: /usr/supermario/pmhacklib/Some/Interesting/Module.pm
	# $target_path:     /usr/supermario/pmhacklib/Some/Interesting

	my $target_filename = File::Spec->catfile($hacklib, Module::Locate::mod_to_path($module_name));
	my ($target_volume, $target_dir, $target_basename) 
	                    = File::Spec->splitpath( $target_filename );
	my $target_path     = File::Spec->catdir($target_volume, $target_dir);

	# skip PERL5HACKLIB when searching for modules
	my @inc_filenames = Module::Locate::locate($module_name);
	@inc_filenames = grep { $_ ne $target_filename } @inc_filenames;
	@inc_filenames ? my $inc_filename = shift @inc_filenames : croak "Cannot find source for $module_name";
	
	# create all necessary directories
	unless ( -e $target_path && -d $target_path )
	{
		File::Path::make_path($target_path) or croak "Could not create path: $!";
	}

	# copy, overwriting if necessary
	open  (my $target_fh, '>', $target_filename) or croak "Could not open target $target_filename for writing: $!";
	copy  ($inc_filename, $target_fh)            or croak "Copy failed: $!";
	close ($target_fh)                           or carp "Could not close target filehandle";

	# on Win32, unset the READONLY attribute
	if ($OSNAME eq 'MSWin32')
	{
		try 
		{ 
			Module::Load::load('Win32::File'); 
			Win32::File::SetAttributes($target_filename, Win32::File::NORMAL());
		}
		catch
		{
			carp "Failed removing read-only attributes, make sure you have Win32::File installed";
		};
		
	}
	
	return $target_filename;
}

1;

=head1 NAME

App::Pmhack

=head1 ABSTRACT

Hack on installed Perl modules

=head1 SYNOPSIS

  use App::Pmhack qw(pmhack);
  my $new_location = pmhack('Some::Module::Name');

=head1 DESCRIPTION

This module is used internally by teh C<pmhack> utility.

=head1 FUNCTIONS

=head2 pmhack

Given a perl module name, finds the module in @INC, copies it into a directory specified in C<$ENV{PERL5HACKLIB}> and returns the resulting filename.

=head1 AUTHOR

Peter Shangov <pshangov at yahoo dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

