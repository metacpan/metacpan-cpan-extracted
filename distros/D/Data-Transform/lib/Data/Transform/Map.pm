# vim: ts=3 sw=3 expandtab

package Data::Transform::Map;
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

Data::Transform::Map - transform input and/or output within a filter stack

=head1 SYNOPSIS

   use Data::Transform::Map;
   use Test::More plan => 'no_plan';

   my $filter = Data::Transform::Map( Code => \&uc );
   my $out = $filter->get( [qw(foo bar baz)] );
   is_deeply ( $out, [qw(FOO BAR BAZ)], "shouting it!");

=head1 DESCRIPTION

Data::Transform::Map transforms data inside the filter stack.  It may be
used to transform input, output, or both depending on how it is
constructed.  This filter is named and modeled after Perl's built-in
map() function.

=head1 PUBLIC FILTER METHODS

Data::Transform::Map implements the L<Data::Transform> API. Only
differences and addition to the API are documented here.

=cut

=head2 new

new() constructs a new Data::Transform::Map object.  It must either be
called with a single Code parameter, or both a Put and a Get
parameter.  The values for Code, Put and Get are code references that,
when invoked, return transformed versions of their sole parameters.  A
Code function will be used for both input and ouput, while Get and Put
functions allow input and output to be filtered in different ways.

  # Decrypt rot13.
  sub decrypt_rot13 {
    my $encrypted = shift;
    $encrypted =~ tr[a-zA-Z][n-za-mN-ZA-M];
    return $encrypted;
  }

  # Encrypt rot13.
  sub encrypt_rot13 {
    my $plaintext = shift;
    $plaintext =~ tr[a-zA-Z][n-za-mN-ZA-M];
    return $plaintext;
  }

  # Decrypt rot13 on input, and encrypt it on output.
  my $rot13_transcrypter = Data::Transform::Map->new(
    Get => \&decrypt_rot13,
    Put => \&encrypt_rot13,
  );

Rot13 is symmetric, so the above example can be simplified to use a
single Code function.

  my $rot13_transcrypter = Data::Transform::Map->new(
    Code => sub {
      local $_ = shift;
      tr[a-zA-Z][n-za-mN-ZA-M];
      return $_;
    }
  );


=cut

sub new {
   my $type = shift;
   croak "$type must be given an even number of parameters" if @_ & 1;
   my %params = @_;

   croak "$type requires a Code or both Get and Put parameters" unless (
             defined($params{Code})
         or (defined($params{Get}) and defined($params{Put}))
      );

   croak "Code element is not a subref"
      unless (defined $params{Code} ? ref $params{Code} eq 'CODE' : 1);

   croak "Get or Put element is not a subref"
         unless ((defined $params{Get} ? (ref $params{Get} eq 'CODE') : 1)
            and  (defined $params{Put} ? (ref $params{Put} eq 'CODE') : 1)
      );

   my $self = bless [
      [ ],           # BUFFER
      $params{Code} || $params{Get},  # CODEGET
      $params{Code} || $params{Put},  # CODEPUT
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

   return unless defined $data;
   return $self->[CODEGET]->($data);
}

sub _handle_put_data {
  my ($self, $data) = @_;

   return $self->[CODEPUT]->($data);
}


=head2 modify

modify() changes a Data::Transform::Map object's behavior at runtime.  It
accepts the same parameters as new(), and it replaces the existing
transforms with new ones.

  # Switch to "reverse" encryption for testing.
  $rot13_transcrypter->modify(
    Code => sub { return scalar reverse shift }
  );

=cut

sub modify {
   my ($self, %params) = @_;

   for (keys %params) {
      die "Modify $_ element must be given a coderef"
         unless (ref $params{$_} eq 'CODE');

      if (lc eq 'code') {
         $self->[CODEGET] = $params{$_};
         $self->[CODEPUT] = $params{$_};
      } elsif (lc eq 'put') {
         $self->[CODEPUT] = $params{$_};
      } elsif (lc eq 'get') {
         $self->[CODEGET] = $params{$_};
      }
   }
}

1;

__END__

=head1 SEE ALSO

L<Data::Transform> for more information about filters in general.

=head1 AUTHORS & COPYRIGHTS

The Map filter was contributed by Dieter Pearcey.  Documentation is
provided by Rocco Caputo.

=cut
