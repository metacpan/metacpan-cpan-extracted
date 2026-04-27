package BATsh::Env;
######################################################################
#
# BATsh::Env - Shared environment variable store
#
# Both CMD and SH interpreters read/write through this module.
# Variables are stored in a Perl hash, separate from %ENV.
# %ENV is synced on demand (for child processes).
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use vars qw($VERSION);
$VERSION = '0.01';
$VERSION = $VERSION;

# The environment store: plain hash, accessible as package variable
# Initial values seeded from %ENV at startup.
use vars qw(%STORE);

# Initialize from %ENV
sub init {
    %STORE = %ENV;
}

# Get a variable value (undef if not set)
sub get {
    my ($class, $name) = @_;
    return $STORE{$name};
}

# Set a variable
sub set {
    my ($class, $name, $value) = @_;
    $STORE{$name} = defined $value ? $value : '';
}

# Unset a variable
sub unset {
    my ($class, $name) = @_;
    delete $STORE{$name};
}

# Check if variable exists
sub exists_var {
    my ($class, $name) = @_;
    return exists $STORE{$name} ? 1 : 0;
}

# Export all variables to %ENV (for child process spawning)
sub sync_to_env {
    %ENV = %STORE;
}

# Snapshot the entire store (for SETLOCAL)
sub snapshot {
    my %snap = %STORE;
    return \%snap;
}

# Restore from snapshot (for ENDLOCAL)
sub restore {
    my ($class, $snap) = @_;
    %STORE = %{$snap};
}

# SETLOCAL scope stack (package-level, accessible from any module)
use vars qw(@SETLOCAL_STACK);
@SETLOCAL_STACK = ();

sub setlocal {
    my %snap = %STORE;
    push @SETLOCAL_STACK, \%snap;
}

sub endlocal {
    unless (@SETLOCAL_STACK) {
        warn "[BATsh] Warning: ENDLOCAL without matching SETLOCAL\n";
        return;
    }
    %STORE = %{pop @SETLOCAL_STACK};
}

# Expand %VAR% references in a CMD string
# %% is literal % in a batch file context
sub expand_cmd {
    my ($class, $str) = @_;
    return '' unless defined $str;
    # Replace %%VAR%% (double-percent FOR variables) with their values
    $str =~ s/%%([A-Za-z])/defined($STORE{"%%$1"}) ? $STORE{"%%$1"} : "%%$1"/ge;
    # Replace %VAR%
    $str =~ s/%([^%\r\n]+)%/defined($STORE{$1}) ? $STORE{$1} : ''/ge;
    # %% -> % (literal percent in batch files)
    $str =~ s/%%/%/g;
    return $str;
}

# Expand $VAR and ${VAR} references in a SH string
# Also handles $? (last exit code), handled by caller
sub expand_sh {
    my ($class, $str) = @_;
    return '' unless defined $str;
    # ${VAR}
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/defined($STORE{$1}) ? $STORE{$1} : ''/ge;
    # $VAR (not followed by alphanumeric/underscore)
    $str =~ s/\$([A-Za-z_][A-Za-z0-9_]*)/defined($STORE{$1}) ? $STORE{$1} : ''/ge;
    return $str;
}
1;

__END__

=head1 NAME

BATsh::Env - Shared variable store for BATsh

=head1 SYNOPSIS

  use BATsh::Env;

  BATsh::Env::init();           # seed from %ENV
  BATsh::Env::set('FOO', 'bar');
  my $v = BATsh::Env::get('FOO');
  BATsh::Env::setlocal();       # snapshot (SETLOCAL)
  BATsh::Env::endlocal();       # restore  (ENDLOCAL)
  BATsh::Env::sync_to_env();    # export to %ENV for child processes

=head1 DESCRIPTION

BATsh::Env is the single variable table shared by BATsh::CMD and BATsh::SH.
Variables set via C<SET> in CMD mode and via C<export> in SH mode both
read and write the same C<%STORE> hash.

C<setlocal()> and C<endlocal()> implement the SETLOCAL / ENDLOCAL scope
stack, supporting arbitrary nesting.

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

=head1 LICENSE

Same as Perl itself.

=cut
