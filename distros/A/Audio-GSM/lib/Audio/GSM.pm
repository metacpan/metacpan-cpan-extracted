package Audio::GSM;

use 5.010000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Audio::GSM ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	GSM_MAGIC
	GSM_MAJOR
	GSM_MINOR
	GSM_OPT_FAST
	GSM_OPT_FRAME_CHAIN
	GSM_OPT_FRAME_INDEX
	GSM_OPT_LTP_CUT
	GSM_OPT_VERBOSE
	GSM_OPT_WAV49
	GSM_PATCHLEVEL
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	GSM_MAGIC
	GSM_MAJOR
	GSM_MINOR
	GSM_OPT_FAST
	GSM_OPT_FRAME_CHAIN
	GSM_OPT_FRAME_INDEX
	GSM_OPT_LTP_CUT
	GSM_OPT_VERBOSE
	GSM_OPT_WAV49
	GSM_PATCHLEVEL
);

our $VERSION = '0.04';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Audio::GSM::constant not defined" if $constname eq 'constant';
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
XSLoader::load('Audio::GSM', $VERSION);

# Preloaded methods go here.

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $gsm = gsm_create();
    my $self = sub {$gsm};
    bless($self, $class);
    return $self;
}

sub DESTROY {
    my $self = shift;
    gsm_destroy(&$self);
}

sub option {
    my $self   = shift;
    my $option = shift;
    my $value  = shift;
    if (defined $value) {
        return gsm_setoption(&$self, $option, $value);
    } else {
        return gsm_getoption(&$self, $option);
    }
}

sub encode {
    my $self    = shift;
    my $pcmData = shift || '';
    $pcmData .= 0x00 x (640 - length($pcmData));
    my $gsmData = 0x00 x 65;
    gsm_encode2(&$self, $pcmData, $gsmData);
    return $gsmData;
}

sub decode {
    my $self    = shift;
    my $gsmData = shift || '';
    $gsmData .= 0x00 x (65 - length($gsmData));
    my $pcmData = 0x00 x 640;
    gsm_decode2(&$self, $gsmData, $pcmData);
    return $pcmData;
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Audio::GSM - Perl extension for libgsm

=head1 SYNOPSIS

  use Audio::GSM;
  $gsm = new Audio::GSM;
  $wav49 = $gsm->option(GSM_OPT_WAV49);
  $gsm->option(GSM_OPT_WAV49, $wav49);
  $gsmData = $gsm->encode($pcmData);
  $pcmData = $gsm->decode($gsmData);

=head1 DESCRIPTION

Audio::GSM is an OO wrapper for libgsm.

=head2 Methods

B<$gsm-E<gt>option(OPTION, [EXPR])>

=over

Sets the OPTION and returns its previous value if EXPR is present, returns
its current value otherwise. See gsm_option(3).

=back

B<$gsm-E<gt>encode(PCMDATA)>

=over

Encodes raw PCM data and returns GSM frames. PCMDATA is 640 bytes length
portion of 16-bit mono PCM data.

Return value is a pair of 32 and 33 bytes length GSM frames. See gsm(3).

=back

B<$gsm-E<gt>decode(GSMDATA)>

=over

Decodes GSM frames and returns raw PCM data. GSMDATA is a pair of 32 and
33 bytes length GSM frames. See gsm(3).

Return value is 640 bytes length portion of 16-bit mono PCM data.

=back

=head2 Exported constants

  GSM_MAGIC
  GSM_MAJOR
  GSM_MINOR
  GSM_OPT_FAST
  GSM_OPT_FRAME_CHAIN
  GSM_OPT_FRAME_INDEX
  GSM_OPT_LTP_CUT
  GSM_OPT_VERBOSE
  GSM_OPT_WAV49
  GSM_PATCHLEVEL


=head1 SEE ALSO

gsm(3), gsm_option(3)

=head1 AUTHOR

Alexander Frolov, E<lt>froller@froller.netE<gt>

=cut
