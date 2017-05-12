package DCE::Registry;

use vars qw($VERSION @ISA);
use DynaLoader ();
use DCE::rgybase ();
use DCE::UUID ();

@ISA = qw(DynaLoader DCE::rgybase);

$VERSION = "1.02";

#why the heck doesn't this get inherited?
*AUTOLOAD = \&DCE::rgybase::AUTOLOAD;

sub sec_passwd_none{0}
sub sec_passwd_plain{1}
sub sec_passwd_des{2}
sub no_more_entries{387063929} #for now

sub p {0}
sub g {1}
sub o {2}

my(%domain) = (user => 0, group => 1, org => 3);
sub domain { $domain{$_[1]} }

# The bind_auth definitions are from an enum in binding.h.
sub bind_auth_none {0}
sub bind_auth_dce {1}

bootstrap DCE::Registry;

1;
__END__

=head1 NAME

DCE::Registry - Perl interface to DCE Registry API

=head1 SYNOPSIS

  use DCE::Registry;

  my $rgy = DCE::Registry->site_open($site_name);

=head1 DESCRIPTION

This module provides an OO Perl interface to the DCE Registry API.
The sec_rgy_ prefix has been dropped and methods are invoked via a
blessed registry_context object.


=head1 AUTHOR

Doug MacEachern <dougm@osf.org>

=head1 SEE ALSO

perl(1), DCE::rgybase(3), DCE::Status(3), DCE::Login(3), DCE::UUID(3).

=cut
