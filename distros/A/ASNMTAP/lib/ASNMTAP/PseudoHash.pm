# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::PseudoHash
# ----------------------------------------------------------------------------------------------------------

# package ASNMTAP::PseudoHash;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw/$FixedKeys $Obj $Proxy/;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Constants = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

use constant NO_SUCH_FIELD => 'No such pseudohash field "%s"';
use constant NO_SUCH_INDEX => 'Bad index while coercing array into hash';

# SET ASNMTAP::PseudoHash VARIABLES - - - - - - - - - - - - - - - - - - -

our $FixedKeys = 1;

# Constructor & initialisation  - - - - - - - - - - - - - - - - - - - - -

unless ( $] < 5.010000 ) {
  eval {
    use overload (
      '%{}'  => sub { $$Obj = $_[0]; return $Proxy },
      '""'   => sub { overload::AddrRef($_[0]) },
      '0+'   => sub { no warnings;
                      my $str = overload::AddrRef($_[0]);
                      hex(substr($str, index($str, '(') + 1, -1));
                    },
      'bool' => sub { 1 },
      'cmp'  => sub { "$_[0]" cmp "$_[1]" },
      '<=>'  => sub { "$_[0]" cmp "$_[1]" }, # for completeness' sake
      'fallback' => 1,
    );

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    INIT {
      no strict 'refs';

      my $class = __PACKAGE__;
      tie %{$Proxy}, $class;
  
      *{'fields::phash'} = sub { $class->new(@_); } unless defined $_[0];
    }

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    sub FETCH {
      my ($self, $key) = @_;

      $self = $$$self;
      my $index = ( ( defined $self->[0]{$key} and $self->[0]{$key} >= 1 ) ? $self->[0]{$key} : ( defined $self->[0]{$key} ? _cluck(NO_SUCH_INDEX) : ( $FixedKeys ? _cluck(NO_SUCH_FIELD, $key) : @$self ) ) );
      return $self->[ $index ];
    }

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    sub STORE {
      my ($self, $key, $value) = @_;

      $self = $$$self;
      my $index = ( ( defined $self->[0]{$key} and $self->[0]{$key} >= 1 ) ? $self->[0]{$key} : ( defined $self->[0]{$key} ? _cluck(NO_SUCH_INDEX) : ( $FixedKeys ? _cluck(NO_SUCH_FIELD, $key) : @$self ) ) );
      return $self->[ $index ] = $value;
    }

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    sub TIEHASH {
      bless \$Obj => shift;
    }

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    sub FIRSTKEY {
      scalar keys %{$${$_[0]}->[0]};
      each %{$${$_[0]}->[0]};
    }

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    sub NEXTKEY {
      each %{$${$_[0]}->[0]};
    }

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    sub EXISTS {
      exists $${$_[0]}->[0]{$_[1]};
    }

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    sub DELETE {
      delete $${$_[0]}->[0]{$_[1]};
    }

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    sub CLEAR {
      @{$${$_[0]}} = ();
    }

    # Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - -

    sub _cluck {
      require Carp;
      Carp::cluck(sprintf(shift, @_));
    }

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::PseudoHash is a Perl module that emulates Pseudo-Hash behaviour via overload used by ASNMTAP and ASNMTAP-based applications and plugins.

=head1 SEE ALSO

ASNMTAP::Asnmtap::Applications, ASNMTAP::Asnmtap::Applications::CGI, ASNMTAP::Asnmtap::Applications::Collector, ASNMTAP::Asnmtap::Applications::Display

ASNMTAP::Asnmtap::Plugins, ASNMTAP::Asnmtap::Plugins::Nagios

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

ASNMTAP is based on 'Process System daemons v1.60.17-01', Alex Peeters [alex.peeters@citap.be]

 Purpose: CronTab (CT, sysdCT),
          Disk Filesystem monitoring (DF, sysdDF),
          Intrusion Detection for FW-1 (ID, sysdID)
          Process System daemons (PS, sysdPS),
          Reachability of Remote Hosts on a network (RH, sysdRH),
          Rotate Logfiles (system activity files) (RL),
          Remote Socket monitoring (RS, sysdRS),
          System Activity monitoring (SA, sysdSA).

'Process System daemons' is based on 'sysdaemon 1.60' written by Trans-Euro I.T Ltd

ASNMTAP::PseudoHash is based on 'Class::PseudoHash v1.10' written by Audrey Tang

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut