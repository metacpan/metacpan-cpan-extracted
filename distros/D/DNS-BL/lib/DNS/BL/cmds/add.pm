package DNS::BL::cmds::add;

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

DNS::BL::cmds::add - Add an  entry to the database

=head1 SYNOPSIS

  use DNS::BL::cmds::add;

=head1 DESCRIPTION

This module implements the B<add> command, used to include entries
into a DNSBL managed by L<DNS::BL>. The general syntax of this
command, is as follows

  add ip <ip-address> [code <return-code>] [text <text>] [time <timestamp>]

where each argument has the following function:

=over 4

=item B<ip E<lt>ip-addressE<gt>>

Specifies which IP address or network this command refers
to. Essentially, anything that L<NetAddr::IP> will understand.

=item B<code E<lt>return-codeE<gt>>

The value returned by the DNSBL when a match with this entry is
found. Usually, this is something that can be returned in a DNS A RR,
an IP address. If not specified, '127.0.0.1' will be used as a
default.

=item B<text E<lt>textE<gt>>

The text associated with this entry in the DNSBL. Usually this is
associated with a DNS TXT RR. Defaults to an empty string.

=item B<time E<lt>timestampE<gt>>

The time associated with this entry in seconds since the
epoch. Defaults to the current time. Some converters might add this
item to the text description.

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

    my @known 	= qw/ip code text time/;

    my @r = __PACKAGE__->arg_check($bl, 'add', $command, 
		       [ qw/ip code text time without/ ], \%args);
    return wantarray ? (@r) : $r[0]
	if $r[0] != &DNS::BL::DNSBL_OK;
    
    my $e = new DNS::BL::Entry;
    my $ip;

    unless (exists $args{ip} and $ip = new NetAddr::IP $args{ip})
    {
	return wantarray ? (&DNS::BL::DNSBL_ESYNTAX(), 
			    "'add' requires a valid 'ip' address")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    $e->addr($args{ip});

    # Check wether we can add this entry to the database or not

    if (!exists $args{without})
    {
	@r = $bl->read($e);
	return wantarray ? 
	    (&DNS::BL::DNSBL_ECOLLISSION, 
	     "Collision with existing entry - Use 'print' to locate") : 
	     &DNS::BL::DNSBL_ECOLLISSION
	     if $r[0] != &DNS::BL::DNSBL_ENOTFOUND;

	@r = $bl->match($e);
	return wantarray ? 
	    (&DNS::BL::DNSBL_ECOLLISSION, 
	     "Collision with existing entry - Use 'print' to locate") : 
	     &DNS::BL::DNSBL_ECOLLISSION
	     if $r[0] != &DNS::BL::DNSBL_ENOTFOUND;
    }
    elsif ($args{without} ne 'checking')
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "'add' checks can be spared using 'without checking'")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    $e->desc($args{text}) if exists $args{text};
    $e->time($args{time}) if exists $args{time};
    $e->value($args{code} || '127.0.0.1');

    # At this point, we should store the entry in the database
    @r = $bl->write($e);

    return wantarray ? ($r[0], "'add' failed on write: $r[1]") : $r[0]
	if $r[0] != &DNS::BL::DNSBL_OK;

    return wantarray ? (&DNS::BL::DNSBL_OK, "Entry added") : 
	&DNS::BL::DNSBL_OK;
};

1;
__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

$Log: add.pm,v $
Revision 1.3  2004/10/12 18:14:27  lem
Added collision check

Revision 1.2  2004/10/12 17:44:46  lem
Updated docs. Added print with format

Revision 1.1  2004/10/11 21:16:34  lem
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
