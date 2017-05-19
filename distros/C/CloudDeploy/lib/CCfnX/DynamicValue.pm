package CCfnX::DynamicValue {
  use Moose;
  extends 'Cfn::Value';
  has '+Value' => (isa => 'CodeRef');

  sub to_value {
    my $self = shift;
    return Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value')->coerce($self->resolve_value(@_));
    #Cfn::Value->new(Value => $self->resolve_value(@_));
  }

  sub resolve_value {
    my $self = shift;
    my @args = reverse @_;
    my (@ret) = ($self->Value->(@args));
    @ret = map { (not ref($_) or ref($_) eq 'HASH')?$_:$_->as_hashref(@args) } @ret;
    return (@ret);
  }

  override as_hashref => sub {
    my $self = shift;
    return $self->resolve_value(@_);
  };
}

1;
