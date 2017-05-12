package App::Toodledo::Account;

our $VERSION = '1.00';

use Carp;
use Moose;
use MooseX::Method::Signatures;
use App::Toodledo::AccountInternal;

extends 'App::Toodledo::InternalWrapper';

has object => ( is => 'ro', isa => 'App::Toodledo::AccountInternal',
	        default => sub { App::Toodledo::AccountInternal->new },
	        handles => sub { __PACKAGE__->internal_attributes( $_[1] ) } );

1;

__END__

=head1 NAME

App::Toodledo::Account - class encapsulating a Toodledo account

=head1 SYNOPSIS

  $account = App::Toodledo::Account->new;
  $todo = App::Toodledo->new;

=head1 DESCRIPTION

This class provides accessors for the properties of a Toodledo account.
The following attributes are defined:

XXX

=head1 AUTHOR

Peter J. Scott, C<< <cpan at psdt.com> >>

=head1 SEE ALSO

Toodledo: L<http://www.toodledo.com/>.

Toodledo API documentation: L<http://www.toodledo.com/info/api_doc.php>.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2011 Peter J. Scott, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

