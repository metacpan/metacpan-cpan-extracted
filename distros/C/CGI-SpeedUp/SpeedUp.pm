package CGI::SpeedUp;

use strict;
use File::Spec;
use vars qw( $VERSION $File_base $Control $Done $DEBUG );
$VERSION = 0.11;

BEGIN
{
    $DEBUG = 0;  # <-- DEBUG

    sub import_error { $Done = 1; }

	require 'CGI.pm';
    $CGI::NO_DEBUG = 1; #Do not use STDIN debugging!

    ($File_base = File::Spec->catfile(File::Spec->tmpdir(),__PACKAGE__)) =~ s/::/-/g;

	open (STDERR, File::Spec->devnull());

    $/ ||= "\n"; # Bug in perl 5.005_02 !!!
}


END
{
    return if $Done; # This avoids a perl core dump under 5.005_02
	my ($out_ref) = &header_control;
	print $$out_ref if defined $$out_ref;
}


sub import
{
    my( $self, @list ) = @_;

    (my $module_name = __PACKAGE__ ) =~ s/::/-/g;
    foreach( CGI::cookie("${module_name}-header"), (exists $ENV{"${module_name}-header"} and $ENV{"${module_name}-header"})) {
		$_ and $Control->{'header'}{$_} = 1 and last;
    }

    open(OLDOUT, ">&STDOUT");  # Save real STDOUT
    open(STDOUT, ">${File_base}-out-$$");
}

sub header_control
{
    my $outfile = "";

	# Retrieve real STDOUT
	open( STDOUT, ">&OLDOUT" );

	open(my $fh, '<', "${File_base}-out-$$");

	$outfile = join '', <$fh>;
	unlink "${File_base}-out-$$";

    return(\$outfile);
}

1;

=head1 NAME

CGI::SpeedUp


=head1 SYNOPSIS

	# ONLY THIS
	use CGI::SpeedUp;
	
=head1 DESCRIPTION

The CGI::SpeedUp module provides a simple way to speed up any CGI application by managing its STDOUT and STDERR. This module was tested in a production environment.

=head1 SUBROUTINES/METHODS

All is done automagicaly. You shoud only C<use> it :-)

=head1 DEPENDENCIES

=over 4

=item CGI

=item File::Spec

=back


=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Strzelecki Łukasz <lukasz@strzeleccy.eu>

=head1 LICENCE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

