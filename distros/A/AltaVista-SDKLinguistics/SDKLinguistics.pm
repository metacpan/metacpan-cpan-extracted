package AltaVista::SDKLinguistics;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	AVS_DANISH
	AVS_ENGLISH
	AVS_FINNISH
	AVS_FRENCH
	AVS_GERMAN
	AVS_ITALIAN
	AVS_NORWEGIAN
	AVS_PORTUGUESE
	AVS_SPANISH
	AVS_SWEDISH
);
@EXPORT_OK = qw(avsl_thesaurus_init 
		avsl_thesaurus_get 
		avsl_thesaurus_close
                avsl_phrase_init 
		avsl_phrase_get 
		avsl_phrase_close
                avsl_stem_init 
		avsl_stem_get 
		avsl_stem_close
                avsl_spell_init 
		avsl_spellcheck_get 
		avsl_spellcorrection_get 
		avsl_spell_close
);
$VERSION = '3.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined AltaVista::SDKLinguistics macro $constname";
	}
    }
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap AltaVista::SDKLinguistics $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for the AltaVista SDK Linguistics module. 

=head1 NAME

AltaVista::SDKLinguistics - Perl extension for AltaVista SDK Linguistics functionality

=head1 SYNOPSIS

  use AltaVista::SDKLinguistics;

=head1 DESCRIPTION

Stub documentation for AltaVista::SDKLinguistics...

=head1 Exported constants

  AVS_DANISH
  AVS_ENGLISH
  AVS_FINNISH
  AVS_FRENCH
  AVS_GERMAN
  AVS_ITALIAN
  AVS_NORWEGIAN
  AVS_PORTUGUESE
  AVS_SPANISH
  AVS_SWEDISH


=head1 AUTHOR

AltaVista Support, avse-support@av.com

=head1 SEE ALSO

perl, AltaVista Search SDK documentation.

=cut
