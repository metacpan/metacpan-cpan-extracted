package Crypt::HC128;

use 5.006000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Crypt::HC128 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	HC128_ENC_TYPE
	Hc128_Process
	Hc128_SetKey
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	HC128_ENC_TYPE
);

our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Crypt::HC128::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Crypt::HC128', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Crypt::HC128 - Perl extension for HC-128 stream cipher

=head1 SYNOPSIS

  use Crypt::HC128;

=head1 DESCRIPTION

Stub documentation for Crypt::HC128, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.

=head2 Exportable constants

  HC128_ENC_TYPE

=head2 Exportable functions

  int Hc128_Process(HC128*, byte*, const byte*, word32)
  int Hc128_SetKey(HC128*, const byte* key, const byte* iv)

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Li ZHOU, E<lt>lzhou@pcbsd.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Li ZHOU

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
