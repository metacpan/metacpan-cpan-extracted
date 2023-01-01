package CatalystX::RequestModel::ContentBodyParser;

use warnings;
use strict;
use Module::Runtime ();
use CatalystX::RequestModel::Utils::InvalidJSONForValue;
use CatalystX::RequestModel::Utils::InvalidRequestNamespace;
use CatalystX::RequestModel::Utils::InvalidRequestNotIndexed;
use Catalyst::Utils;

sub content_type { die "Must be overridden" }

sub default_attr_rules { die "Must be overridden" }

sub parse {
  my ($self, $ns, $rules) = @_;
  my %parsed = %{ $self->handle_data_encoded($self->{context}, $ns, $rules) };
  return %parsed;
}

sub _sorted {
  return 1 if $a eq '';
  return -1 if $b eq '';
  return $a <=> $b;
}

sub handle_data_encoded {
  my ($self, $context, $ns, $rules, $indexed) = @_;
  my $response = +{};

  # point $context to the namespace or die if not a valid namespace
  foreach my $pointer (@$ns) {
    if(exists($context->{$pointer})) {
      $context = $context->{$pointer};
    } else {
      return $response
      ## TODO maybe need a 'namespace_required 1' or something?
      ##CatalystX::RequestModel::Utils::InvalidRequestNamespace->throw(ns=>join '.', @$ns);
    }
  }

  while(@$rules) {
    my $current_rule = shift @{$rules};
    my ($attr, $attr_rules) = %$current_rule;
    my $data_name = $attr_rules->{name};
    $attr_rules = $self->default_attr_rules($attr_rules);

    next unless exists $context->{$data_name}; # required handled by Moo/se required attribute

    if( !$indexed && $attr_rules->{indexed}) {

      # TODO move this into stand alone method and set some sort of condition
      unless((ref($context->{$data_name})||'') eq 'ARRAY') {
        if((ref($context->{$data_name})||'') eq 'HASH') {
          my @values = ();
          foreach my $index (sort _sorted keys %{$context->{$data_name}}) {
            push @values, $context->{$data_name}{$index};
          }
          $context->{$data_name} = \@values;
        } else {
          CatalystX::RequestModel::Utils::InvalidRequestNotIndexed->throw(param=>$data_name);
        }
      }
      
      my @response_data;
      foreach my $indexed_value(@{$context->{$data_name}}) {
        my $indexed_response = $self->handle_data_encoded(+{ $data_name => $indexed_value}, [], [$current_rule], 1);
        push @response_data, $indexed_response->{$data_name};
      }

      if(@response_data) {
        $response->{$data_name} = \@response_data;
      } elsif(!$attr_rules->{omit_empty}) {
        $response->{$data_name} = [];
      }

    } elsif(my $nested_model = $attr_rules->{model}) { 
        $response->{$attr} = $self->{ctx}->model(
          $self->normalize_nested_model_name($nested_model), 
          current_parser=>$self,
          context=>$context->{$data_name},
        );
    } else {
      my $value = $context->{$data_name};
      $response->{$data_name} = $self->normalize_value($data_name, $value, $attr_rules);
    }
  }

  return $response;
}

sub normalize_value {
  my ($self, $param, $value, $key_rules) = @_;

  if($key_rules->{always_array}) {
    $value = $self->normalize_always_array($value);
  } elsif($key_rules->{flatten}) {
    $value = $self->normalize_flatten($value);
  }

  $value = $self->normalize_json($value, $param) if (($key_rules->{expand}||'') eq 'JSON');
  $value = $self->normalize_boolean($value) if ($key_rules->{boolean}||'');

  return $value;
}

sub normalize_always_array {
  my ($self, $value) = @_;
  $value = [$value] unless (ref($value)||'') eq 'ARRAY';
  return $value;
}

sub normalize_flatten{
  my ($self, $value) = @_;
    $value = $value->[-1] if (ref($value)||'') eq 'ARRAY';
  return $value;
}

sub normalize_boolean {
  my ($self, $value) = @_;
  return $value ? 1:0
}

sub normalize_nested_model_name {
  my ($self, $nested_model) = @_;
  if($nested_model =~ /^::/) {
    my $model_class_base = ref($self->{request_model});
    my $prefix = Catalyst::Utils::class2classprefix($model_class_base);
    $model_class_base =~s/^${prefix}\:\://;
    $nested_model = "${model_class_base}${nested_model}";
  }

  return $nested_model;
}

my $_JSON_PARSER;
sub get_json_parser {
  my $self = shift;
  return $_JSON_PARSER ||= Module::Runtime::use_module('JSON::MaybeXS')->new(utf8 => 1);
}

sub normalize_json {
  my ($self, $value, $param) = @_;

  eval {
    $value = $self->get_json_parser->decode($value);
  } || do {
    CatalystX::RequestModel::Utils::InvalidJSONForValue->throw(param=>$param, parsing_error=>$@);
  };

  return $value;
}

1;

=head1 NAME

CatalystX::RequestModel::ContentBodyParser - Content Parser base class

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

Base class for content parsers.   Basically we need the ability to take a given POSTed
or PUTed (or PATCHed even I guess) content body and normalized it to a hash of data that
can be used to instantiate the request model.  As well you need to be able to read the 
meta data for each field and do things like flatten arrays (or inflate them, etc) and 
so forth.

This is lightly documented for now but there's not a lot of code and you can refer to the
packaged subclasses of this for hints on how to deal with your odd incoming content types.

=head1 EXCEPTIONS

This class can throw the following exceptions:

=head2 Invalid JSON in value

If you mark an attribute as "expand=>'JSON'" and the value isn't valid JSON then we throw
an L<CatalystX::RequestModel::Utils::InvalidJSONForValue> exception which if you are using
L<CatalystX::Errors> will be converted into a HTTP 400 Bad Request response (and also logging
to the error log the JSON parsing error).

=head2 Invalid request parameter not indexed

If a request parameter is marked as indexed but no indexed values (not arrayref) are found
we throw L<CatalystX::RequestModel::Utils::InvalidRequestNamespace>

=head2 Invalid request no namespace

If your request model defines a namespace but there's no matching namespace in the request
we throw a L<CatalystX::RequestModel::Utils::InvalidRequestNamespace>.

=head1 METHODS

This class defines the following public API

=head2

=head1 AUTHOR

See L<CatalystX::RequestModel>.
 
=head1 COPYRIGHT
 
See L<CatalystX::RequestModel>.

=head1 LICENSE
 
See L<CatalystX::RequestModel>.
 
=cut
