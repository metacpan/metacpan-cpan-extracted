package Data::Transpose::Validator::Subrefs;
use strict;
use warnings;
use Moo;
extends 'Data::Transpose::Validator::Base';
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

=head1 NAME

Data::Transpose::Validator::Subrefs Validator using custom subroutines

  sub custom_sub {
      my $field = shift;
      return $field
        if $field =~ m/\w/;
      return (undef, "Not a \\w");
  }
  
  my $vcr = Data::Transpose::Validator::Subrefs->new( \&custom_sub );
  
  ok($vcr->is_valid("H!"), "Hi! is valid");
  ok(!$vcr->is_valid("!"), "! is not");
  is($vcr->error, "Not a \\w", "error displayed correctly");
  

=cut

=head2 new(\&subroutine)

The constructor accepts only one argument, a reference to a
subroutine. The class will provide the variable to validate as the
first and only argument. The subroutine is expected to return a
true value on success, or a false value on failure.

To set a custom error, the subroutine in case of error should return 2
elements, where the first should be undefined (see the example above).


=cut

has call => (is => 'rw', isa => CodeRef, required => 1);

=head2 call

Accessor to the subroutine

=head2 is_valid($what)

The call to the validator.

=cut


sub is_valid {
    my ($self, $arg) = @_;
    $self->reset_errors;
    my ($result, $error) = $self->call->($arg);
    if ($error) {
        $self->error($error);
        return undef;
    } else {
        return $result;
    }
}

sub BUILDARGS {
    # straight from the manual
    my ($class, @args) = @_;
    unshift @args, 'call' if @args % 2 == 1;
    return { @args };
};


1; # the last famous words

