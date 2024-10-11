package MooseX::Attribute::Catalyst::Shared;
 
use Moose::Role;

has 'shared' => (is=>'ro', predicate=>'has_shared');

around '_process_options' => sub {
  my ($orig, $self, $name, $options) = (@_);
  $options = $self->_process_shared($name, $options)
    if exists($options->{shared});
  return $self->$orig($name, $options);
};

# When an attibute is shared, set its default to the value in the shared
# context key, if it exists UNLESS the programmer is setting a default or
# builder manually.

sub _process_shared {
  my ($self, $name, $options) = @_;
  unless($options->{default} || $options->{builder}) {
    $options->{lazy} = 1;
    $options->{default} = sub {
      my $self = shift;
      my $ctx = $self->ctx; # This only works for per-request controllers
      return $ctx->stash->{__MXACShared}{$name}
        if exists($ctx->stash->{__MXACShared}{$name});
    };
    return $options;
  }
  if(my $default = $options->{default}) {
    $options->{lazy} = 1;
    $options->{default} = sub {
      my $self = shift;
      my $ctx = $self->ctx; # This only works for per-request controllers
      my $default_value = ref($default) ? $default->($self) : $default;
      
      $ctx->stash->{__MXACShared}{$name} = $default_value;

      return $default_value;
    };
  }
  # if there's a builder, around it and store in the stash
  if(my $builder = delete $options->{builder}) {
    $options->{lazy} = 1;
    $options->{default} = sub {
      my $self = shift;
      my $ctx = $self->ctx; # This only works for per-request controllers
      my $default_value = $self->$builder;
      
      $ctx->stash->{__MXACShared}{$name} = $default_value;

      return $default_value;
    };

  }
  return $options;
}

# If someone tries to update a shared attribute, sync that with the stash

around 'install_accessors' => sub { 
  my $orig = shift;
  my $attr = shift;
  my $class = $attr->associated_class; 

  $attr->$orig(@_);

  if($attr->has_shared) {
    if(my $writer_name = $attr->get_write_method) {
      $class->add_before_method_modifier($writer_name, sub {
        my ($self, $value) = @_;
        return unless defined $value;

        my $name = $attr->name;
        my $ctx = $self->ctx;
        $ctx->stash->{__MXACShared}{$name} = $value;
      });
    }

    if(my $reader_name = $attr->get_read_method) {
      my $sub = sub {
        my ($self) = @_;
        $self->$reader_name; # Trigger the lazy builder if necessary
      };
      $class->can('BUILD') ?
        $class->add_after_method_modifier('BUILD', $sub) :
          $class->add_method('BUILD', $sub);
    }
  }

};

package Moose::Meta::Attribute::Custom::Trait::Catalyst::Shared;
sub register_implementation { 'MooseX::Attribute::Catalyst::Shared' }

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
use MooseX::Attribute::Catalyst::Shared; 

Moose::Exporter->setup_import_methods( also => 'Moose' );

sub init_meta {
    my ($class, %args) = (@_);

    Moose->init_meta(%args, base_class => 'CatalystX::Moose::Object');
    Moose::Util::MetaRole::apply_metaroles(
        for             => $args{for_class},
        class_metaroles => {
          attribute  => ['MooseX::Attribute::Catalyst::Scoped',
            'MooseX::Attribute::Catalyst::Shared'],
        },
    );
 
    return $args{for_class}->meta();
}

1;
