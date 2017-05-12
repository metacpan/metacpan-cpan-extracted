package CHI::Driver::DBIC;

use 5.008;
use strict;
use warnings;
use Params::Validate qw/:all/;
use Moose;
extends 'CHI::Driver';

=head1 NAME

CHI::Driver::DBIC - DBIx::Class Driver for CHI.

=head1 VERSION

Version 0.002

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

This module allow the CHI caching interface to use a database as a backend 
via DBIx::Class.

It implements the methods which are required by a CHI::Driver: store, fetch, 
remove and clear. It should not be necessary to access these methods directly.

It should be noted that most database supported by DBIx::Class are slower 
than caches or NoSQL databases.

=head2 Example Object Creation

  $chi = CHI->new(
    driver             => 'DBIC',
    resultset          => $schema->resultset('Mbfl2Session'),
    expires_on_backend => 1,
    expires_in         => 30
  ),

=head2 Example get and set

  $val = $chi->get($key);

  $chi->set( $key, $val );

=head2 Example Table Definition (Oracle)

  SQL> desc mbfl2_sessions
   Name                                      Null?    Type
   ----------------------------------------- -------- ----------------------------
   ID                                        NOT NULL VARCHAR2(72)
   SESSION_DATA                                       BLOB
   EXPIRES                                            NUMBER

=head1 EXPORT

Nothing.

=head1 METHODS

=cut

=head2 Attributes

=over 

=item resultset

The DBIx::Class ResultSet which will be use to operate on the database table.
Internally the calls will be $self->schema->($self->resultset) etc.

=item column_map

A hash ref with the keys key, data and expires_in. Used to map to the table columns.
Defaults to:

        {
            key        => 'id',
            data       => 'session_data',
            expires_in => 'timestamp'
        }

=item expiry_calc_in

=item expiry_calc_out

=back

=cut

has 'resultset' => ( 'is' => 'ro', 'isa' => 'Object', 'required' => 1 );
has 'expiry_calc_in' => (
  'is'    => 'ro',
  'isa'   => 'CodeRef',
  default => sub {
    my $self = shift;
    return sub { my $expiry = shift; $expiry += time(); }
  },
  lazy => 1
);
has 'expiry_calc_out' => (
  'is'    => 'ro',
  'isa'   => 'CodeRef',
  default => sub {
    return sub { my ( $self, $expiry ); return $expiry; }
  },
  lazy => 1
);

has 'column_map' => (
  'is'    => 'ro',
  'isa'   => 'HashRef',
  default => sub {
    return {
      key        => 'id',
      data       => 'session_data',
      expires_in => 'expires'
    };
  }
);

has '_rs' => (
  'is'      => 'ro',
  'isa'     => 'Object',
  'lazy'    => 1,
  'default' => sub { my $self = shift; $self->resultset; }
);

=head2 store

=cut

sub store {
  my ( $self, $key, $data, $expires_in ) = validate_pos( @_, 1, 1, 1, 0 );
  my $cm = $self->column_map;
  my $hr = {
    $cm->{key}  => $key,
    $cm->{data} => $data
  };

  $hr->{ $cm->{expires_in} } = $self->expiry_calc_in->($expires_in);
  $self->_rs->update_or_create($hr);
  return 1;
}

=head2 fetch

=cut

sub fetch {
  my ( $self, $key ) = validate_pos( @_, 1, 1 );

  my $id = $self->column_map->{key};
  my $result = $self->_rs->find( { $id => $key } );
  return $result->session_data if $result;
  return;
}

=head2 remove

=cut

sub remove {
  my ( $self, $key ) = validate_pos( @_, 1, 1 );
  my $result = $self->_rs->find( { $self->column_map->{key} => $key } );
  $result->delete if $result;
  return 1;
}

=head2 clear

=cut

sub clear {
  my ($self) = validate_pos( @_, 1 );
  $self->_rs->search( {} )->delete;
  return 1;
}

=head1 AUTHOR

Motortrak Ltd, C<< <duncan.garland at motortrak.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-chi-driver-dbic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CHI-Driver-DBIC>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CHI::Driver::DBIC


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CHI-Driver-DBIC>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CHI-Driver-DBIC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CHI-Driver-DBIC>

=item * Search CPAN

L<http://search.cpan.org/dist/CHI-Driver-DBIC/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Motortrak Ltd.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__->meta->make_immutable;

1;    # End of CHI::Driver::DBIC
