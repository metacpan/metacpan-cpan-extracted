package DNS::BL::cmds::delete;

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

DNS::BL::cmds::delete - Delete entries matching IP ranges

=head1 SYNOPSIS

  use DNS::BL::cmds::delete;

=head1 DESCRIPTION

This module implements the B<delete> command, used to remove entries
from a DNSBL managed by L<DNS::BL>. The general syntax of this
command, is as follows

  delete within <ip-address>

where each argument has the following function:

=over 4

=item B<within E<lt>ip-addressE<gt>>

Controls which entries are to be affected. Only entries that are fully
enclosed within the given IP address network range will be processed.

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

    my @r = __PACKAGE__->arg_check($bl, 'delete', $command, 
		       [ qw/within/ ], \%args);
    return wantarray ? (@r) : $r[0]
	if $r[0] != &DNS::BL::DNSBL_OK;

    my $e = new DNS::BL::Entry;
    my $ip;

    unless (exists $args{within} and $ip = new NetAddr::IP $args{within})
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "'$command' requires a valid 'within' IP address")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    $e->addr($ip);

    # Fetch results from the database
    @r = $bl->erase($e);

    return wantarray ? ($r[0], "'" . __PACKAGE__ 
			. "' failed on delete: $r[1]") : $r[0]
	if $r[0] != &DNS::BL::DNSBL_OK;

    return wantarray ? @r : $r[0];
};

1;
__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

$Log: delete.pm,v $
Revision 1.2  2004/10/12 17:44:46  lem
Updated docs. Added print with format

Revision 1.1  2004/10/11 21:16:59  lem
Basic db and commands added



=head1 SEE ALSO

Perl(1), L<DNS::BL>.

=head1 AUTHOR

Luis Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Luis Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
