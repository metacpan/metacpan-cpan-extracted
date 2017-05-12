package DNS::BL::cmds;

use DNS::BL;

use 5.006001;
use strict;
use warnings;

use Carp;

our $VERSION = '0.00_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

# Preloaded methods go here.

=pod

=head1 NAME

DNS::BL::cmds - Base class for DNS::BL commands

=head1 SYNOPSIS

  use DNS::BL::cmds;

=head1 DESCRIPTION

This module provides template functions that must be overriden by the
actual C<DNS::BL> commands, as well as its documentation. This behaves
as a pure-virtual class.

The following methods are implemented by this module:

=over

=item C<-E<gt>execute($dns_bl, $verb, @arguments)>

This method is invoked by C<DNS::BL> whenever parsing of a command
line with a given verb is requested. The first argument, is a
reference to the invoking C<DNS::BL> object. The second argument is
the verb that caused this invocation. Any additional parameters, are
passed along as a list or arguments.

In scalar context, this method must return one of the C<DNSBL_*>
constants defined in L<DNS::BL>. In list context, the first element of
the return value must be this constant. The second argument, must be
an explanation message suitable for presenting to an end user.

=cut

sub execute { croak "Must override ->execute()"; }

=pod

=item C<-E<gt>arg_check($caller, $dns_bl, $handler, $verb, \@known, \%arguments)>

This method is provided as a courtesy to subclasses. It tests
automatically wether passed arguments are understood by the
implementation. See the various subclasses for examples of its use.

=cut

sub arg_check
{
    my $caller	= shift;
    my $bl	= shift;
    my $command	= shift;
    my $handler	= shift;
    my $r_known	= shift;
    my $r_args	= shift;

    unless ($command eq $handler)
    {
	return
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "'$caller' invoked by command '$command'");
    }

    for my $k (keys %$r_args)
    {
	unless (grep { $k eq $_ } @$r_known)
	{
	    return (&DNS::BL::DNSBL_ESYNTAX(), 
		    "Unknown argument '$k' to command '$command'");
	}
    }

    return (&DNS::BL::DNSBL_OK(), "OK");
}

1;
__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.00_01

Original version; created by h2xs 1.22

=back



=head1 SEE ALSO

Perl(1), L<DNS::BL>.

=head1 AUTHOR

Luis Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Luis Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
