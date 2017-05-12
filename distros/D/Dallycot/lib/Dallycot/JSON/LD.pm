package Dallycot::JSON::LD;
our $AUTHORITY = 'cpan:JSMITH';

use Moose;

use utf8;

use Carp qw(croak);
use Promises qw(deferred);

use experimental qw(switch);

sub to_rdf {
  my($self, $input, %options) = @_;

  return $self -> expand($input) -> then(
    sub {
      $self -> generate_node_map(@_);
    }
  ) -> then(
    sub {

    }
  );
}

sub expand {
  my($self, $element, $active_context, $active_property) = @_;


  my $xp = $self -> _expand($element, $active_context, $active_property);
  if(blessed $xp) {
    return $xp;
  }
  else {
    my $d = deferred;
    $d -> resolve($xp);
    return $d -> promise;
  }
}

sub _expand {
  my($self, $element, $active_context, $active_property) = @_;

  if(!defined($element)) {
    return;
  }
  else {
    given(reftype $element) {
      when(undef) {
        if(!defined($active_property) || $active_property eq '@graph') {
          return;
        }
        else {
          return $self -> expand_value($element, $active_context, $active_property);
        }
      }
      when('ARRAY') {
        my @result;
        foreach my $el (@$element) {
          my @xp = $self->_expand($el, $active_context, $active_property);
          if(@xp > 1) {
            if($active_property eq '@list' || container_mapping($active_property) eq '@list') {
              croak "List of lists detected in JSON-LD";
            }
          }
          push @result, grep { defined } @xp;
        }
        if(any { blessed $_ } @result) {
          return collect( grep { blessed $_ } @result )->then(sub {
            my(@finally) = map { @$_ } @_;
            return (@finally, grep { !blessed $_ } @result);
          });
        }
        else {
          return @result;
        }
      }
      when('SCALAR') {
        if(!defined($active_property) || $active_property eq '@graph') {
          return;
        }
        else {
          return $self -> expand_value($$element, $active_context, $active_property);
        }
      }
    }
    when('HASH') {
      my $ctx_promise;
      if(exists($element->{'@context'}) && defined($element->{'@context'})) {
        $ctx_promise = $self->process_context($element->{'@context'}, $active_context);
      }
      else {
        $ctx_promise = deferred;
        $ctx_promise -> resolve($active_context);
        $ctx_promise = $ctx_promise -> promise;
      }
      return $ctx_promise -> then(sub {
        my($new_context) = @_;
        my $result = {};

        foreach my $key (keys %$element) {
          next if $key eq '@context';

          my $value = $element->{$key};
          my $xv = $value;

          my $xp = expand_iri($key, $new_context, vocab => 1);
          next if !defined($xp) || !$xp =~ /^@/ && !$xp =~ /:/;

          if($xp =~ /^@/ && $active_property eq '@reverse') {
            croak "invalid reverse property map ($key)";
          }

          if(defined $result->{$xp}) {
            croak "colliding keywords ($xp) for $key";
          }

          given($xp) {
            when('@id') {
              if(!defined($value) || ref $value) {
                croak "invalid \@id value ($value) for $key";
              }
              $xv = $self->expand_iri($value, $new_context, document_relative => 1);
            }
            when('@type') {
              if(!defined($value) || ref($value) && reftype($value) ne 'ARRAY' || reftype($value) eq 'ARRAY' && !all { defined && !ref } @$value) {
                croak "invalid \@type value";
              }
              if(ref $value) {
                $xv = [ map { $self->expand_iri($_, $new_context, document_relative => 1, vocab => 1) } @$value ];
              }
              else {
                $xv = $self -> expand_iri($value, $new_context, document_relative => 1, vocab => 1);
              }
            }
            when('@graph') {
              $xv = $self->_expand($value, $new_context, '@graph');
            }
            when('@value') {
              if(defined($value) && ref($value)) {
                croak "invalid value object value for $key";
              }
              if(!defined($value)) {
                $result->{'@value'} = undef;
                next;
              }
            }
            when('@language') {
              if(!defined($value) || ref($value)) {
                croak "invalid language-tagged string for $key";
              }
              $xv = lc($value);
            }
            when('@index') {
              if(!defined($value) || ref($value)) {
                croak "invalid \@index value for $key";
              }
            }
            when('@list') {
              if(!defined($active_property) || $active_property eq '@graph') {
                next;
              }
              $xv = $self -> _expand($value, $new_context, $active_property);
              if(blessed($xv) && $xv->can('then')) {
                $xv = $xv -> then(sub {
                  my(@val) = @_;
                  if(@val > 1) {
                    croak "list of lists detected for $key";
                  }
                  return @val;
                });
              }
            }
            when('@set') {
              $xv = $self -> _expand($value, $new_context, $active_property);
            }
            when('@reverse') {
              if('HASH' ne reftype($value)) {
                croak "invalid \@reverse value for $key";
              }

            }
          }
        }
      });
    }
    default {
      croak "Unable to expand ($element)";
    }
  }
}

sub generate_node_map {
  my($self, $expanded_input) = @_;

  my $node_map = { '@default' => {} };

  $self -> _generate_node_map($expanded_input, $node_map);

  return $node_map;
}

sub _generate_node_map {
  my($self, $input, $node_map) = @_;

  return;
}

1;
