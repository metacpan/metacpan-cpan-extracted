package App::Toodledo::Location;
use strict;
use warnings;

our $VERSION = '1.00';

use Carp;
use Moose;
use MooseX::Method::Signatures;
use App::Toodledo::LocationInternal;

use Moose::Util::TypeConstraints;
BEGIN { class_type 'App::Toodledo' };

extends 'App::Toodledo::InternalWrapper';

has object => ( is => 'ro', isa => 'App::Toodledo::LocationInternal',
	        default => sub { App::Toodledo::LocationInternal->new },
	        handles => sub { __PACKAGE__->internal_attributes( $_[1] ) } );


method add ( App::Toodledo $todo! ) {
  my @args = ( name => $self->name );
  $self->$_ and push @args, ( $_ => $self->$_ ) for qw(description lat lon);
  my $added_ref = $todo->call_func( location => add => { @args } );
  $added_ref->[0]{id};
}


1;

__END__

=head1 NAME

App::Toodledo::Location - class encapsulating a Toodledo location

=head1 SYNOPSIS

  $location = App::Toodledo::Location->new;
  $location->name( 'Sydney' )
  $todo = App::Toodledo->new;
  $todo->add_location( $location );

=head1 DESCRIPTION

This class provides accessors for the properties of a Toodledo location.
The attributes of a location are defined in the L<App::Toodledo::LocationRole>
module.

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
