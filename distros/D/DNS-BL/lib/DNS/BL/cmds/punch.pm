package DNS::BL::cmds::punch;

use DNS::BL;

use 5.006001;
use strict;
use warnings;

use NetAddr::IP;
use DNS::BL::cmds;
use DNS::BL::Entry;

use vars qw/@ISA/;

@ISA = qw/DNS::BL::cmds/;

use Carp;

our $VERSION = '0.00_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

# Preloaded methods go here.

=pod

=head1 NAME

DNS::BL::cmds::punch - Punch holes in entries within the database

=head1 SYNOPSIS

  use DNS::BL::cmds::punch;

=head1 DESCRIPTION

This module implements the B<punch> command, used to punch holes in
existing DNSBL entries managed by L<DNS::BL>. The general syntax of
this command, is as follows

    punch hole <ip-address>

where each argument has the following function:

=over 4

=item B<hole E<lt>ip-addressE<gt>>

Specifies which IP address or network this command refers
to. Essentially, anything that L<NetAddr::IP> will understand. Entries
falling entirely within this range, will be deleted. Entries that
partially overlap with the given range, will be fragmented.

=back

This functionality is provided by the following method:

=over

=item C<-E<gt>execute()>

See L<DNS::BL::cmds> for information on this method's general purpose
and calling convention.

This method implements the behavior specified above.

=cut

sub execute 
{ 
    my $bl	= shift;
    my $command	= shift;
    my %args	= @_;

    my @r = __PACKAGE__->arg_check($bl, 'punch', $command, 
		       [ qw/hole/ ], \%args);
    return wantarray ? (@r) : $r[0]
	if $r[0] != &DNS::BL::DNSBL_OK;
    
    my $e = new DNS::BL::Entry;
    my $ip;

    return wantarray ? 
	(&DNS::BL::DNSBL_ESYNTAX(), 
	 "'punch' requires a valid 'hole' IP address")
	: &DNS::BL::DNSBL_ESYNTAX()
	unless exists $args{hole} and 
	$ip = new NetAddr::IP $args{hole};

    $e->addr($args{hole});

    # First, find out wether any space is covered by our hole. In
    # this case, remove it

    @r = $bl->erase($e);

    # Now, find entries that cover our hole.

    @r = $bl->match($e);
    shift @r;
    shift @r;

    # For each entry, split it progressively...
    while (my $r = shift @r)
    {
	my @t = $bl->erase($r);
	if ($r->addr->masklen < $e->addr->masklen)
	{			# Split and keep...
	    my @p = $r->addr->split($r->addr->masklen + 1);
	    for my $p (@p)
	    {
		if ($p->contains($e->addr))
		{
		    my $c = $r->clone;
		    $c->addr($p);
		    push @r, $c;
		}
		else
		{
		    my $c = $r->clone;
		    $c->addr($p);
		    my @t = $bl->write($c);
		    return wantarray ? 
			($t[0], "'" . __PACKAGE__ 
			 . "' failed on add $p (" . $r->addr 
			 . " dropped): $t[1]") : $t[0]
			 if $t[0] != &DNS::BL::DNSBL_OK;
		}
	    }
	}
    }

    return wantarray ? (&DNS::BL::DNSBL_OK, "Hole punched") : 
	&DNS::BL::DNSBL_OK;
};

1;
__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

$Log: punch.pm,v $
Revision 1.1  2004/10/13 13:54:17  lem
Functional punch()



=head1 SEE ALSO

Perl(1), L<DNS::BL>.

=head1 AUTHOR

Luis Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Luis Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
