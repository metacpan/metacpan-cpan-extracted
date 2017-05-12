package Alien::BatToExeConverter;

=pod

=head1 NAME

Alien::BatToExeConverter - Convert a DOS Batch Script to an Executable

=head1 SYNOPSIS

  # Convert a batch script to an executable that won't show a DOS box
  Alien::BatToExeConverter::bat2exe(
      bat => 'C:\strawberry\perl\bin\foo.bat',
      exe => 'C:\strawberry\perl\bin\foo.exe',
  );

=head1 DESCRIPTION

F<Bat_To_Exe_Converter.exe> is a nice little Windows Freeware program,
built from open source elements, that will take a batch script and
convert it into an executable (both as a command-line form, and as a
GUI form).

=head1 FUNCTIONS

=cut

use 5.008;
use strict;
use warnings;
use Carp           ();
use File::Which    ();
use File::ShareDir ();
use IPC::Run3      ();

our $VERSION = '0.01';

=pod

=head2 bat2exe_path

The C<bat2exe> function is used to locate the F<Bat_To_Exe_Converter.exe>
tool on the host. The Alien module will look in the local binary search
path, and then if a local version can't be found, it will instead return
the path to a bundled version.

=cut

sub bat2exe_path {
	# Check for the installed version
	my $installed = File::Which::which('Bat_To_Exe_Converter');
	return $installed if $installed;

	# Default to the bundled version
	File::ShareDir::dist_file(
		'Alien-BatToExeConverter',
		'Bat_To_Exe_Converter.exe',
	);
}

=pod

=head2 bat2exe

  # Convert a batch script to an executable that will have an icon,
  # won't show a DOS box, and will suppress to the command line.
  Alien::BatToExeConverter::bat2exe(
      bat => 'C:\strawberry\perl\bin\foo.bat',
      exe => 'C:\strawberry\perl\bin\foo.exe',
      ico => 'C:\strawberry\perl\bin\foo.ico',
      dos => 0,
  );

The C<bat2exe> function is used to execute F<Bat_To_Exe_Converter.exe> and
generate an executable from the batch script. It takes a series of named
params, returning true on success or throwing an exception on failure.
The default settings are intended to produce an .exe script for launching
a GUI application.

The compulsory C<bat> param should be the name of the source batch script.

The compulsory C<exe> param should be the path to white the executable to,
and must NOT already exist.

The optional C<ico> param will bind an icon to the executable.

The optional C<dos> param will indicate that the executable is intended
for the command line. If C<not> supplied, STDOUT and STDERR will be
supressed and a "DOS box" will not be shown on execution.

=cut

sub bat2exe {
	my %param = @_;

	# Required input batch script
	my $bat = $param{bat};
	unless ( $bat and $bat =~ /\.bat$/ and -f $bat ) {
		Carp::croak("Missing or invalid bat file");
	}

	# Required output executable application
	my $exe = $param{exe};
	unless ( $exe and $exe =~ /\.exe$/ ) {
		Carp::croak("Missing or invalid exe file");
	}
	if ( -f $exe ) {
		Carp::croak("The target exe '$exe' already exists");
	}

	# Optional icon file
	my $ico = $param{ico} || '';
	if ( $ico and not -f $ico ) {
		Carp::croak("Invalid ico file");
	}

	# DOS or GUI application?
	my $dos = !! $param{dos};

	# Hand off to the executable
	my $bat2exe = bat2exe_path();
	my $stdin   = '';
	my $stdout  = '';
	my $stderr  = '';
	my $rv      = IPC::Run3::run3( [
		$bat2exe, $bat, $exe, $ico, $dos,
	], \$stdin, \$stdout, \$stderr );

	

	1;
}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-BatToExeConverter>

For general comments, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

B<Alien::BatToExeConverter> Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

B<Bat_To_Exe_Converter.exe> Copyright 2006 - 2009 Fatih Kodak.

In order to use this program, you must read and agree with this
license agreement.

You may not translate, reverse program, disassemble, decompile or otherwise
reverse engineer this program.

No warranty. The software is licensed to you "as is" and without any
warranty.

If you do not agree with this agreement, please do not use this software.

B<Flat Assembler> Copyright 1999 - 2007 Tomasz Grysztar. All rights reserved.

This program is free for commercial and non-commercial use as long as
the following conditions are adhered to.

Copyright remains Tomasz Grysztar, and as such any Copyright notices
in the code are not to be removed.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The licence and distribution terms for any publically available
version or derivative of this code cannot be changed. i.e. this code
cannot simply be copied and put under another distribution licence
(including the GNU Public Licence).

=cut
