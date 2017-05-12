package DNS::BL::cmds::connect;

use DNS::BL;

use 5.006001;
use strict;
use warnings;

use vars qw/@ISA/;

@ISA = qw/DNS::BL::cmds/;

use Carp;

our $VERSION = '0.00_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

# Preloaded methods go here.

=pod

=head1 NAME

DNS::BL::cmds::connect - Implement the connect command for DNS::BL

=head1 SYNOPSIS

  use DNS::BL::cmds::connect;

=head1 DESCRIPTION

This module implements the connect command, to be used by
L<DNS::BL>. This command uses a backend class to perform low level
operations on the L<DNS::BL> stable storage.

The following methods are implemented by this module:

=over

=item C<-E<gt>execute()>

See L<DNS::BL::cmds> for information on this method's purpose.

The connect command follows a syntax such as

  connect <method> ...

Where <method> must be defined in a class such as

  DNS::BL::cmds::connect::<method>

This class will be C<use>d and then, its C<execute()> method invoked
following the same protocol outlined in L<DNS::BL>. The B<connect>
token will be removed before invoking the C<execute()> method of the
specific class.

Any prior C<connect()> information will be destroyed before attempting
the C<use>.

=cut

sub execute 
{ 
    my $bl	= shift;
    my $command	= shift;

    unless (@_)
    {
	return wantarray ? (&DNS::BL::DNSBL_ESYNTAX(), 
			    "Must supply a back end type (dbi, etc)")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    my $type	= shift;

    # Start by removing any previous handler. _connect is used to store
    # a possible reference to an object or handle
    {
	no strict 'refs';
	$bl->set('_' . $_, undef) for qw(_connect read match write 
					 erase commit);
    }

    # Attempt to load the required module
    eval "use " . __PACKAGE__ . "::$type;";

    if ($@)
    {
	return wantarray ? (&DNS::BL::DNSBL_ESYNTAX(), 
			    "Failed to connect to $type: $@")
	    : &DNS::BL::DNSBL_ESYNTAX();
	
    }

    # If succesful, eat the 'connect' token and pass control
    # to the corresponding class
    {
	no strict 'refs';
	my $name = __PACKAGE__ . "::${type}::execute";
	return *{$name}->($bl, $type, @_);
    }
};

1;
__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

$Log: connect.pm,v $
Revision 1.1.1.1  2004/10/08 15:08:32  lem
Initial import


=head1 SEE ALSO

Perl(1), L<DNS::BL>.

=head1 AUTHOR

Luis Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Luis Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
