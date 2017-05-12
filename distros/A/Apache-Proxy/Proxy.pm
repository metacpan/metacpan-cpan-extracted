package Apache::Proxy;

use strict;
use vars qw($VERSION @ISA);

use DynaLoader ();

@ISA = qw(DynaLoader);

$VERSION = '0.02';

if($ENV{MOD_PERL}) {
    bootstrap Apache::Proxy $VERSION;
}

1;
__END__

=head1 NAME

Apache::Proxy - Perl interface to mod_proxy

=head1 SYNOPSIS

  use Apache::Proxy ();

=head1 DESCRIPTION

    my $status = Apache::Proxy->pass($r, "http://perl.apache.org/"); 
    my $hashfile = Apache::Proxy->proxy_hash($r, $url);

=head1 AUTHOR

Doug MacEachern, Ilya Obshadko

=head1 SEE ALSO

perl(1).

=cut
