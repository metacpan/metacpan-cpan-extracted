package Authen::CAS::External::Library;

use 5.008001;
use strict;
use utf8;
use warnings 'all';

# Module metadata
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.08';

use MooseX::Types 0.08 -declare => [qw(
	ServiceTicket
	TicketGrantingCookie
)];

# Import built-in types
use MooseX::Types::Moose qw(Int Str);

# Clean the imports are the end of scope
use namespace::clean 0.04 -except => [qw(meta)];

# Type definitions
subtype ServiceTicket,
	as Str,
	where { m{\A ST-.{1,256}}msx };

subtype TicketGrantingCookie,
	as Str,
	where { m{\A (?:TGC-)? [A-Za-z0-9-]+ (?:-[A-Za-z0-9\.-]+)? \z}msx };

1;

__END__

=head1 NAME

Authen::CAS::External::Library - Types library

=head1 VERSION

This documentation refers to version 0.08.

=head1 SYNOPSIS

  use Authen::CAS::External::Library qw(ServiceTicket);
  # This will import ServiceTicket type into your namespace as well as some
  # helpers like to_ServiceTicket and is_ServiceTicket. See MooseX::Types
  # for more information.

=head1 DESCRIPTION

This module provides types for Authen::CAS::External

=head1 METHODS

No methods.

=head1 TYPES PROVIDED

=head2 ServiceTicket

B<Provides no coercions.>

=head2 TicketGrantingCookie

B<Provides no coercions.>

This is the ticket-granting cookie as defined in section 3.6 of the
L<CAS Protocol|http://www.jasig.org/cas/protocol>. This also allows for a domain
name to be present at the end as per discussed in
L<Clustering CAS|http://www.ja-sig.org/wiki/display/CASUM/Clustering+CAS>.

=head1 DEPENDENCIES

This module is dependent on the following modules:

=over 4

=item * L<MooseX::Types|MooseX::Types> 0.08

=item * L<MooseX::Types::Moose|MooseX::Types::Moose>

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-authen-cas-external at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Authen-CAS-External>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I highly encourage the submission of bugs and enhancements to my modules.

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Douglas Christopher Wilson.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
