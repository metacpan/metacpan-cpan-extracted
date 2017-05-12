# vim: ts=3 sw=3 expandtab
# 2001/01/25 shizukesa@pobox.com
package Data::Transform::Grep;
use strict;
use Data::Transform;

use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = qw(Data::Transform);

use Carp qw(croak carp);

sub BUFFER   () { 0 }
sub CODEGET  () { 1 }
sub CODEPUT  () { 2 }

=head1 NAME

Data::Transform::Grep - select or remove items based on simple rules

=head1 SYNOPSIS

   my $filter = Data::Transform::Grep->new(
         Put => sub { 1 },
         Get => sub { $_[0] =~ /ba/ },
      );
   
   my $out = $filter->get([qw(foo bar baz)]);
   # is($out, [qw(bar baz)], "only stuff with 'ba' in it");

=head1 DESCRIPTION

Data::Transform::Grep selects or removes items based on simple tests.  It
may be used to filter input, output, or both.  This filter is named
and modeled after Perl's built-in grep() function.

=head1 PUBLIC FILTER METHODS

Data::Transform::Grep implements the L<Data::Transform> API. Only
differences and additions to the API are documented here.

=cut

=head2 new

new() constructs a new Data::Transform::Grep object.  It must either be
called with a single Code parameter, or both a Put and a Get
parameter.  The values for Code, Put, and Get are code references
that, when invoked, return true to select an item or false to reject
it.  A Code function will be used for both input and output, while Get
and Put functions allow input and output to be filtered in different
ways.  The item in question will be passed as the function's sole
parameter.

sub reject_bidoofs {
   my $pokemon = shift;
   return 1 if $pokemon ne "bidoof";
   return;
}

my $gotta_catch_nearly_all = Data::Transform::Grep->new(
      Code => \&reject_bidoofs,
      );

Enforce read-only behavior:

my $read_only = Data::Transform::Grep->new(
      Get => sub { 1 },
      Put => sub { 0 },
      );

=cut

sub new {
   my $type = shift;
   croak "$type must be given an even number of parameters" if @_ & 1;
   my %params = @_;

   croak "$type requires a Code or both Get and Put parameters" unless (
         defined($params{Code}) or
         (defined($params{Get}) and defined($params{Put}))
         );
   croak "Code element is not a subref"
      unless (defined $params{Code} ? ref $params{Code} eq 'CODE' : 1);
   croak "Get or Put element is not a subref"
      unless ((defined $params{Get} ? (ref $params{Get} eq 'CODE') : 1)
            and   (defined $params{Put} ? (ref $params{Put} eq 'CODE') : 1));

   my $self = bless [
      [ ],                             # BUFFER
      $params{Code} || $params{Get},   # CODEGET
      $params{Code} || $params{Put},   # CODEPUT
      ], $type;
}

sub clone {
   my $self = shift;

   my $new = [
      [],
      $self->[CODEGET],
      $self->[CODEPUT],
   ];

   return bless $new, ref $self;
}

# get()           is inherited from Data::Transform.
# get_one_start() is inherited from Data::Transform.
# get_one()       is inherited from Data::Transform.

sub _handle_get_data {
   my ($self, $data) = @_;

# Must be a loop so that the buffer will be altered as items are
# tested.
   return unless (defined $data);
   return $data if ($self->[CODEGET]->($data));
   return;
}

sub _handle_put_data {
   my ($self, $data) = @_;
   return $data if $self->[CODEPUT]->($data);
   return;
}

=head2 modify

modify() changes a Data::Transform::Grep object's behavior at runtime.  It
accepts the same parameters as new(), and it replaces the existing
tests with new ones.

# Don't give away our Dialgas.
$gotta_catch_nearly_all->modify(
      Get => sub { 1 },
      Put => sub { return shift() ne "dialga" },
      );

=cut

sub modify {
   my ($self, %params) = @_;

   for (keys %params) {
      (carp("Modify $_ element must be given a coderef") and next) unless (ref $params{$_} eq 'CODE');
      if (lc eq 'code') {
         $self->[CODEGET] = $params{$_};
         $self->[CODEPUT] = $params{$_};
      }
      elsif (lc eq 'put') {
         $self->[CODEPUT] = $params{$_};
      }
      elsif (lc eq 'get') {
         $self->[CODEGET] = $params{$_};
      }
   }
}

1;

__END__

=head1 SEE ALSO

L<Data::Transform> for more information about filters in general.

L<Data::Transform::Stackable> for more details on stacking filters.

=head1 AUTHORS & COPYRIGHTS

The Grep filter was contributed by Dieter Pearcey.  Documentation is
provided by Rocco Caputo.

=cut
