package MooseX::Attribute::Catalyst::Scoped;
 
use Moose::Role;

has 'context' => (is=>'ro', predicate=>'has_context');
has 'from_key' => (is=>'ro');
has 'to_key' => (is=>'ro');

around '_process_options' => sub {
  my ($orig, $self, $name, $options) = (@_);
  $options = $self->_process_context($name, $options) if exists $options->{context};
  return $self->$orig($name, $options);
};

sub _process_context {
  my ($self, $name, $options) = @_;
  my $from_key = $options->{context};
  $from_key = $name if $from_key eq '1';

  $options->{to_key} = $name;
  $options->{from_key} = $from_key;
  $options->{lazy} = 1;
  $options->{default} = sub {
    my $self = shift;
    my $value = sub {
      my $ctx = $self->ctx;
      return $ctx->stash->{$from_key} if exists $ctx->stash->{$from_key};
      return $ctx->$from_key if $ctx->can($from_key);
      die "Could not find value for $from_key";
    }->();
    return $self->ctx->stash->{$name} = $value;
  };
  return $options;
}

around 'install_accessors' => sub { 
  my $orig = shift;
  my $attr = shift;
  my $class = $attr->associated_class; 

  $attr->$orig(@_);

  if($attr->has_context) {
    if(my $writer_name = $attr->get_write_method) {
      $class->add_before_method_modifier($writer_name, sub {
        my ($self, $value) = @_;
        return unless defined $value;
        $self->ctx->stash->{$attr->to_key} = $value;
      });
    }
  }


  # This seems like a fragile hack, if anyone has a better way to
  # trigger the lazy builder, please let me know.

  if(my $reader_name = $attr->get_read_method) {
    my $sub = sub {
      my ($self) = @_;
      $self->$reader_name;
    };
    $class->can('BUILD') ?
      $class->add_after_method_modifier('BUILD', $sub) :
        $class->add_method('BUILD', $sub);
  }
};


package Moose::Meta::Attribute::Custom::Trait::Catalyst::Scoped;
sub register_implementation { 'MooseX::Attribute::Catalyst::Scoped' }

package CatalystX::Moose::Object;

use Moose;
use MooseX::MethodAttributes;

package CatalystX::Moose;

our $VERSION = '0.007';
 
use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use MooseX::Attribute::Catalyst::Scoped; 

Moose::Exporter->setup_import_methods( also => 'Moose' );

sub init_meta {
    my ($class, %args) = (@_);

    Moose->init_meta(%args, base_class => 'CatalystX::Moose::Object');
    Moose::Util::MetaRole::apply_metaroles(
        for             => $args{for_class},
        class_metaroles => {
          attribute  => ['MooseX::Attribute::Catalyst::Scoped'],
        },
    );
 
    return $args{for_class}->meta();
}

1;