package AnyData2::Format::Fixed;

use 5.008001;
use strict;
use warnings FATAL => 'all';

use base qw(AnyData2::Format AnyData2::Role::GuessImplementation);

use Carp qw/croak/;
use List::Util '1.29', qw(pairkeys pairvalues);
use Module::Runtime qw(require_module);

=head1 NAME

AnyData2::Format::Fixed - fixed length format class for AnyData2

=cut

our $VERSION = '0.002';

=head1 METHODS

=head2 new

  # pure invocation
  my $af = AnyData2::Format::Fixed->new(
    $storage,
    cols => [ # important: hash changes order!
      "first" => 20,
      "second" => 15,
      ...
    ]
  );
  
  my $af = AnyData2->new(
    Fixed => {
        cols => [ Id => 3, Name => 10, Color => 7, Newline => 1 ]
    },
    # a File::Linewise example should do, either
    "File::Blockwise" => {
        filename  => File::Spec->catfile( $test_dir, "simple.blocks" ),
        blocksize => 3 + 10 + 7 + 1,
        filemode  => "<:raw"
    }
  );

constructs a storage, passes all options down to C<html_table_class>
beside C<html_table_class>, which is used to instantiate the parser.
C<html_table_class> prefers L<HTML::TableExtract> by default.

=cut

sub new
{
    my ( $class, $storage, %options ) = @_;
    my $self = $class->SUPER::new($storage);

    $self->{cols} = [ @{ delete $options{cols} } ];

    $self;
}

=head2 cols

Deliver the keys of the specification array

=cut

sub cols
{
    my $self = shift;
    [ pairkeys @{ $self->{cols} } ];
}

=head2 fetchrow

Extract the values from storages based on the values of the specification array

=cut

sub fetchrow
{
    my $self = shift;
    my $buf  = $self->{storage}->read();
    defined $buf or return;
    my @data;
    foreach my $len ( pairvalues @{ $self->{cols} } )
    {
        push @data, substr $buf, 0, $len, "";
    }
    \@data;
}

=head2 pushrow

Construct buffer based on the values of the specification array and write it into storage (unimplemented)

=cut

sub pushrow
{
    my ( $self, $fields ) = @_;
    croak "Write support unimplemented. Patches welcome!";
}

=head1 LICENSE AND COPYRIGHT

Copyright 2015,2016 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

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
direct or contributory patent infringement, then this License
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

1;
