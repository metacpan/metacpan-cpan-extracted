package Context::Set::Storage::DBIC;
use Moose;
extends qw/Context::Set::Storage/;

use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

=head1 NAME

Context::Set::Storage::DBIC - Manage context persistence in a L<DBIx::Class::ResultSet>

=head1 MANUAL

This storage allows you to store your contexts and their values in a DBIC Resultset.

This resultset MUST have the following columns:

  id: A unique numeric ID. Be generous (BIG NUM) as this will be incremented each time there's
     a new value for a property. This is the only unique key.

  context_name: NOT NULL - A long enough VARCHAR. 512 is a good size. It must be able to contain
                the longest context fullname possible for your application. No default.

  key         : NOT NULL - A long enough VARCHAR. Must be able to contain the longest possible
                property name for your application. No default.

  is_array : NOT NULL - A boolean. No default.

  value: CAN BE NULL. Something capable of holding any Perl string or number. VARCHAR(512) Is a good starting point.


Additionaly you may want to consider adding the following indices:

  (context_name)  and (context_name, key)


Usage:

  my $storage = Context::Set::Storage::DBIC->new({ resultset => $schema->resultset('Context::SetValues') });
  my $cm = Context::Set::Manager->new({ storage => $storage });
  ...


=cut

has 'resultset' => ( is => 'rw', isa => 'DBIx::Class::ResultSet' , required => 1 );

=head2 populate_context

See super class L<Context::Set::Storage>

=cut

sub populate_context{
  my ($self,$context) = @_;

  my $rs = $self->resultset();
  my $fullname = $context->fullname();

  $LOGGER->debug("LOADING ".$fullname." from DBIC Rs ".$rs->result_source->name());

  my $kvs = $self->resultset->search_rs({ context_name => $context->fullname() },
                                        { order_by => [ 'key' , 'id' ] }
                                       );
  my $properties = {};
  while( my $kv = $kvs->next() ){
    my ($k ,$v) = ( $kv->key() , $kv->value() );
    $properties->{$k} //= [];
    if( $kv->is_array() ){
      push @{$properties->{$k}} , $v;
    }else{
      $properties->{$k} = $v;
    }
  }

  ## Inject all of that in the context.
  $context->properties($properties);
}

=head2 set_context_property

See superclass L<Context::Set::Storage>

=cut

sub set_context_property{
  my ($self, $context, $prop , $v , $after ) = @_;

  my $stuff = sub{
    my $is_array = 1;
    ## Normalize v
    unless( ref($v // 'nothing') eq 'ARRAY' ){
      $v = [ $v ];
      $is_array = 0;
    }

    my $fullname = $context->fullname();

    my $rs =  $self->resultset();

    $LOGGER->debug("SETTING On Rs:'".$rs->result_source->name()."' context:'".$fullname."' key:'".$prop."' value:[".join(',', map{ $_ // 'UNDEF' } @$v).']');

    ## Blat the key
    $rs->search_rs({ context_name => $fullname,
                     key => $prop
                   })->delete();
    ## And record each value (can be an array)
    foreach my $value ( @$v ){
      $rs->create({ context_name => $fullname,
                    key => $prop,
                    value => $value,
                    is_array => $is_array
                  });
    }
    return &{$after}();
  };
  return $self->resultset->result_source->schema()->txn_do($stuff);
}

=head2 delete_context_property

See superclass L<Context::Set::Storage>

=cut

sub delete_context_property{
  my ($self, $context, $prop, $after) = @_;
  my $rs  = $self->resultset();
  my $stuff = sub{
    my $fullname = $context->fullname();
    $LOGGER->debug("DELETING On RS '".$rs->result_source->name()."' context:'".$fullname."' key:'".$prop."'");
    $rs->search_rs({ context_name => $fullname,
                     key => $prop
                   })->delete();
    return &{$after}();
  };
  return $rs->result_source->schema()->txn_do($stuff);
}

__PACKAGE__->meta->make_immutable();
1;
