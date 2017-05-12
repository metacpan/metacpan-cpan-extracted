package DNS::BL::cmds::print;

use DNS::BL;

use 5.006001;
use strict;
use warnings;

use IO::File;
use NetAddr::IP;
use DNS::BL::cmds;
use DNS::BL::Entry;

use vars qw/@ISA/;

@ISA = qw/DNS::BL::cmds/;

our $VERSION = '0.00_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

# Preloaded methods go here.

=pod

=head1 NAME

DNS::BL::cmds::print - Print entries matching IP ranges

=head1 SYNOPSIS

  use DNS::BL::cmds::print;

=head1 DESCRIPTION

This module implements the B<print> command, used to lookup entries
from a DNSBL managed by L<DNS::BL>. The general syntax of this
command, is as follows

  print {within|matching} <ip-address> [to <output-file>] [as <format>]

where each argument has the following function:

=over 4

=item B<within E<lt>ip-addressE<gt>>

Controls which entries are to be affected. Only entries that are fully
enclosed within the given IP address network range will be processed.

=item B<matching E<lt>ip-addressE<gt>>

Controls which entries are to be affected. Only entries that fully
enclose the given IP address network range will be processed.

=item B<to E<lt>output-fileE<gt>>

Causes the result to be printed to the file name given as argument.

=item B<as E<lt>formatE<gt>>

Influences the format to be used for producing the output of the
command. Available formats are:

=over 2

=item B<djdnsbl>

Suitable for use in DJDNSBL data files.

=item B<plain>

A simple output format, which is the default.

=item B<comma>

A comma-separated format, suitable for import into other programs.

=item B<internal>

Returns the result in a list. This is useful for programs
incorporating this module without a CLI.

=back

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

    my @r = __PACKAGE__->arg_check($bl, 'print', $command, 
		       [ qw/within matching to as/ ], \%args);
    return wantarray ? (@r) : $r[0]
	if $r[0] != &DNS::BL::DNSBL_OK;

    my $e = new DNS::BL::Entry;
    my $ip;

    if (!exists $args{within} and !exists $args{matching})
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "'$command' requires a valid 'within' or 'matching' IP address")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }
    elsif (exists $args{within} 
	   and not $ip = new NetAddr::IP $args{within})
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "'$command' requires a valid 'within' IP address")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }
    elsif (exists $args{matching} 
	   and not $ip = new NetAddr::IP $args{matching})
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "'$command' requires a valid 'matching' IP address")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    $e->addr($ip);

    # Fetch results from the database
    if (exists $args{within})
    {
	@r = $bl->read($e);
    }
    else
    {
	@r = $bl->match($e);
    }

    return wantarray ? ($r[0], "'" . __PACKAGE__ 
			. "' failed on read: $r[1]") : $r[0]
	if $r[0] != &DNS::BL::DNSBL_OK;

    shift @r;			# Get rid of OK
    my $msg = shift @r;		# Keep our message

    my $fh;

    if ($args{to})
    {
	$fh = new IO::File $args{to}, "w";
	return wantarray ? 
	    (&DNS::BL::DNSBL_EOTHER(), 
	     "Failed to open output file '$args{to}': $!")
	    : &DNS::BL::DNSBL_EOTHER()
	    unless $fh;
    }
    else
    {
	$fh = \*STDOUT;
    }

    if (!defined $args{as} or $args{as} eq 'plain')
    {
	print $fh $_->addr . " (" . ($_->value || '127.0.0.1') . ") " 
	    . ($_->desc || "No text") .  " - " . $_->time . "\n"
	    for @r;
    }
    elsif ($args{as} eq 'comma')
    {
	print $fh 
	    '"' . $_->addr . '", "' 
	    . ($_->value || '127.0.0.1') . '", "' 
	    . ($_->desc || "No text") .  '", "'
	    . $_->time . qq{\"\n}
	for @r;
    }
    elsif ($args{as} eq 'djdnsbl')
    {
	print $fh $_->addr . " :" . ($_->value || '127.0.0.1') . ":\$ " 
	    . ($_->desc || "No text") .  " - " . $_->time . "\n"
	    for @r;
    }
    elsif ($args{as} eq 'internal')
    {
	return wantarray ? (&DNS::BL::DNSBL_OK, $msg, @r) : 
	    &DNS::BL::DNSBL_OK;
    }
    else
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "'$command as' requires a valid output format")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    return wantarray ? (&DNS::BL::DNSBL_OK, $msg) : 
	&DNS::BL::DNSBL_OK;
};

1;
__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

$Log: print.pm,v $
Revision 1.6  2004/10/15 16:02:45  lem
Add "as internal"

Revision 1.5  2004/10/13 18:06:20  lem
Got rid of Carp (unneeded)

Revision 1.4  2004/10/12 18:20:57  lem
Added 'matching'

Revision 1.3  2004/10/12 17:44:46  lem
Updated docs. Added print with format

Revision 1.2  2004/10/12 17:32:30  lem
print to now implemented

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
