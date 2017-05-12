package DCE::Login;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require DCE::login_base;
@ISA = qw(DynaLoader DCE::login_base);

$VERSION = '1.01';

bootstrap DCE::Login $VERSION;

# Preloaded methods go here.

#why the heck doesn't this get inherited?
*AUTOLOAD = \&DCE::login_base::AUTOLOAD;

sub auth_src_network {0}
sub auth_src_local {1}
sub auth_src_overridden {2}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

DCE::Login - Perl extension for interfacing to the DCE login API

=head1 SYNOPSIS

  use DCE::Login;
  my($l, $status) = DCE::Login->get_current_context;
  my $pwent = $l->get_pwent;

=head1 DESCRIPTION

Perl extension for interfacing to the DCE login API.

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>

=head1 SEE ALSO

perl(1), DCE::login_base(3), DCE::Registry(3).

=cut
