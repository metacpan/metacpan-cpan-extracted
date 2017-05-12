package Context::Set::Storage::Split;
use Moose;
extends qw/Context::Set::Storage/;

use Context::Set::Storage::Split::Rule;

=head1 NAME

Context::Set::Storage::Split - Split storage of Context::Set accross different L<Context::Set::Storage>'s

=head1 MANUAL

Contexts are dispatched accross different storage according to a set of rules.

A rule should have:

  - name : This is free and mandatory.
  - test: A Code Ref that test a given context (see example).
  - storage: Where to store the contexts that pass the test. Should be an instance of any subclass of L<Context::Set::Storage>

Rules are tested in the order of the definition, so the default one should
go at the end of the list. If you don't specify a default, this storage will die if
no rule matches the context you make it manage.

For example:

   $users_store and $general_store are instances of L<Context::Set::Storage>

   ## Store the contexts unders 'users' in a special store, all the rest in a general one.
   my $split_store = Context::Set::Storage::Split->new({
                                                     rules => [{
                                                                name => 'users_specific',
                                                                test => sub{ shift->is_inside('users'); },
                                                                storage => $users_store
                                                               },
                                                               {
                                                                name => 'default',
                                                                test => sub{ 1; },
                                                                storage => $general_store
                                                               }]
                                                    });

=cut


has 'rules' => ( is => 'ro', isa => 'ArrayRef[Context::Set::Storage::Split::Rule]', required => 1);
has '_rules_idx' => ( is => 'ro' , isa => 'HashRef[Context::Set::Storage::Split::Rule]', required => 1);


=head2 BUILDARGS

 See L<Moose>

 In moose, we override BUILDARGS, not new.

=cut

sub BUILDARGS{
  my ($class, $args) = @_;

  ## Replace rules by an array of real rules.
  my @new_rules = ();
  my %rules_idx;
  foreach my $rule ( @{ $args->{rules} // confess "Missing rules in args" } ){
    my $new_rule = Context::Set::Storage::Split::Rule->new($rule);
    push @new_rules , $new_rule;
    $rules_idx{$new_rule->name()} = $new_rule;
  }

  $args->{_rules_idx} = \%rules_idx;
  $args->{rules} = \@new_rules;
  return $args;
}

=head2 rule

Returns a rule by name.

Usage:

 $self->rule('myrule')->...

=cut

sub rule{
  my ($self, $name) = @_;
  return $self->_rules_idx->{$name};
}

=head2 populate_context

See super class L<Context::Set::Storage>

=cut

sub populate_context{
  my ($self,$context) = @_;
  return $self->_matching_storage($context)->populate_context($context);
}

=head2 set_context_property

See superclass L<Context::Set::Storage>

=cut

sub set_context_property{
  my ($self, $context, $prop , $v , $after ) = @_;
  return $self->_matching_storage($context)->set_context_property($context,$prop,$v,$after);
}

=head2 delete_context_property

See superclass L<Context::Set::Storage>

=cut

sub delete_context_property{
  my ($self, $context , $prop , $after) = @_;
  return $self->_matching_storage($context)->delete_context_property($context,$prop,$after);
}


## Return the storage for the given context according to
## the rules.
sub _matching_storage{
  my ($self, $context) = @_;

  ## Scan the rules and return the first matching one.
  foreach my $rule ( @{$self->rules() } ){
    if( $rule->test->($context) ){
      return $rule->storage();
    }
  }
  confess("Could NOT find any matching rule for context ".$context->fullname());
}

__PACKAGE__->meta->make_immutable();
1;
