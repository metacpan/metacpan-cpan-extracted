package BSD::Jail;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT = qw/jattach jail get_xprison get_jids/;

our $VERSION = '0.01';

bootstrap BSD::Jail $VERSION;



1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

BSD::Jail - Perl extension for FreeBSD jail()

=head1 SYNOPSIS

  use BSD::Jail;
  
  # Get a list of current prisons
  my @jids = get_jids();

  # Get information on a prision
  my ($pr_version, $pr_id, $pr_path, $pr_host, $pr_ipaddr) =
      get_xprison($jid);

  # Attach to a prison
  jattach($jid);

  # Create a new prision and get locked into it
  jail($path, $hostname, $ipaddr);


=head1 DESCRIPTION

  The BSD::Jail module is an interface to the jail(2) system call found in
  FreeBSD.  It can get information on current prisons, attach to current
  prisons and create new prisons.

  To create or attach to a prison, the process must be running as root.

=head1 AUTHOR

Travis Boucher E<lt>tbone@tbone.caE<gt>

=head1 SEE ALSO

L<perl>.

=cut
