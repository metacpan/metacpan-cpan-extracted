package Catalyst::Utils::StructuredParameters;

use Moose;
use Storable qw(dclone);
use Catalyst::Utils;
use Catalyst::Exception::MissingParameter;
use Catalyst::Exception::InvalidArrayPointer;
use Catalyst::Exception::InvalidArrayLength;

our $MAX_ARRAY_DEPTH = 1000;

has context => (is=>'ro', required=>1);
has _namespace => (is=>'rw', required=>0, isa=>'ArrayRef', predicate=>'has_namespace', init_arg=>'namespace');
has _flatten_array_value => (is=>'rw', required=>1, init_arg=>'flatten_array_value');
has _current => (is=>'rw', required=>0, init_arg=>undef);
has _required => (is=>'rw', required=>0, init_arg=>undef);
has _src => (is=>'ro', required=>1, init_arg=>'src');
has _max_array_depth => (is=>'ro', required=>1, init_arg=>'max_array_depth', default=>$MAX_ARRAY_DEPTH);

sub namespace {
  my ($self, $arg) = @_;
  $self->_namespace($arg) if defined($arg);
  return $self;
}

sub flatten_array_value {
  my ($self, $arg) = @_;
  $self->_flatten_array_value($arg) if defined($arg);
  return $self;
}

sub max_array_depth {
  my ($self, $arg) = @_;
  $self->_max_array_depth($arg) if defined($arg);
  return $self;
}

sub permitted {
  my ($self, @proto) = @_;
  my $namespace = $self->_namespace ||[];
  $self->_required(0);

  if(ref $proto[0]) {
    my $namespace_affix = shift @proto;
    $namespace = [ @$namespace, @$namespace_affix ];
  }

  my $context = dclone($self->context);
  my $parsed = $self->_parse($context, $namespace, [@proto]);
  my $current = $self->_current ||+{};
  $current = Catalyst::Utils::merge_hashes($current, $parsed);
  $self->_current($current);

  return $self;
}

sub required {
  my ($self, @proto) = @_;
  my $namespace = $self->_namespace ||[];
  $self->_required(1);

  if(ref $proto[0]) {
    my $namespace_affix = shift @proto;
    $namespace = [ @$namespace, @$namespace_affix ];
  }

  my $context = dclone($self->context);
  my $parsed = $self->_parse($context, $namespace, [@proto]);
  my $current = $self->_current ||+{};
  $current = Catalyst::Utils::merge_hashes($current, $parsed);
  $self->_current($current);

  return $self;
}

sub to_hash {
  my $self = shift;
  return %{ $self->_current || +{} };
}

sub keys {
  my $self = shift;
  return CORE::keys %{ $self->_current || +{} };
}

sub get {
  my $self = shift;
  return @{ $self->_current || +{} }{@_};
}

sub _sorted {
  return 1 if $a eq '';
  return -1 if $b eq '';
  return $a <=> $b;
}

sub _normalize_array_value {
  my ($self, $value) = @_;
  return $value unless $self->_flatten_array_value;
  return ((ref($value)||'') eq 'ARRAY') ? $value->[-1] : $value;
}

sub _parse {
  my ($self, @args) = @_;
  return $self->_src eq 'data' ? $self->_parse_data(@args) : $self->_parse_formlike(@args);
}

sub _parse_formlike {
  my ($self, $context, $ns, $rules) = @_;

  use Devel::Dwarn;
  
  my $current = +{};
  while(@{$rules}) {
    my $rule = shift @{$rules};
    if(ref($rule)||'' eq 'HASH') {
      my ($local_ns, $rules) = %$rule;
      my $key = join('.', @$ns, $local_ns);
      my %indexes = ();
      foreach my $context_field (CORE::keys %$context) {
        my ($i, $under) = ($context_field =~m/^\Q$key\E\[(\d*)\]\.?(.*)$/);
        next unless defined $i;
        $indexes{$i} = $under;
      }

      my $found_array_depth = scalar CORE::keys %indexes;
      Catalyst::Exception::InvalidArrayLength->throw(
        pointer=>$local_ns,
        max=>$self->max_array_depth,
        attempted=>$found_array_depth
      ) if $found_array_depth > $self->max_array_depth;

      foreach my $index(sort _sorted CORE::keys %indexes) {
        my $cloned_rules = dclone($rules); # each iteration in the loop needs its own copy of the rules;
        $cloned_rules = [''] unless @$cloned_rules; # to handle the bare array case
        my $old = $self->_flatten_array_value;
        $self->_flatten_array_value(0) if $index eq '';
        my $value = $self->_parse_formlike( $context, [@$ns, "${local_ns}[$index]"], $cloned_rules);
        if(($index eq '') && $old) {
          $self->_flatten_array_value($old);
          if( (ref($value)||'') eq 'ARRAY') {
            push @{$current->{$local_ns}}, $_ for @$value;
          } elsif((ref($value)||'') eq 'HASH') {            
            if(ref $value->{$indexes{$index}}) {
              my @values = map { +{ $indexes{$index} => $_ }  } @{ $value->{$indexes{$index}} };
              push @{$current->{$local_ns}}, @values;
            } else {
              push @{$current->{$local_ns}}, $value;
            }
          }
        } else {
          ## I don't think these are missing params, just a row with invalid fields
          next if( (ref($value)||'') eq 'HASH') && !%$value;
          push @{$current->{$local_ns}}, $value;
        }
      }
    } else {
      if((ref($rules->[0])||'') eq 'ARRAY') {
        my $value = $self->_parse_formlike( $context, [@$ns, $rule], shift(@$rules) );
        next unless %$value; # For 'permitted';
        $current->{$rule} = $value;
      } else {
        if($rule eq '') {
          my $key = join('.', @$ns);
          unless(defined $context->{$key}) {
            $self->_required ? Catalyst::Exception::MissingParameter->throw(param=>$key) : next;
          }
          $current = $self->_normalize_array_value($context->{$key});
        } else {
          my $key = join('.', @$ns, $rule);
          unless(defined $context->{$key}) {
            $self->_required ? Catalyst::Exception::MissingParameter->throw(param=>$key)  : next;
          } 
          $current->{$rule} = $self->_normalize_array_value($context->{$key});
        }
      }
    }
  }
  return $current;
}

sub _parse_data {
  my ($self, $context, $ns, $rules) = @_;
  my $current = +{};
  MAIN: while(@{$rules}) {
    my $rule = shift @{$rules};
    if(ref($rule)||'' eq 'HASH') {
      my ($local_ns, $rules) = %$rule;
      my $value = $context;
      foreach my $pointer (@$ns, $local_ns) {
        if(exists($value->{$pointer})) {
          $value = $value->{$pointer};
        } else {
          $self->_required ? Catalyst::Exception::MissingParameter->throw(param=>join('.', (@$ns, $local_ns)))  : next MAIN;
        }
      }

      Catalyst::Exception::InvalidArrayPointer->throw(pointer=>join('.', (@$ns, $local_ns))) unless (ref($value)||'') eq 'ARRAY';

      my $found_array_depth =  scalar @$value;
      Catalyst::Exception::InvalidArrayLength->throw(
        pointer=>$local_ns,
        max=>$self->max_array_depth,
        attempted=>$found_array_depth
      ) if $found_array_depth > $self->max_array_depth;
      
      my @gathered = ();

      foreach my $item (@$value) {
        my $cloned_rules = dclone($rules); # each iteration in the loop needs its own copy of the rules;
        $cloned_rules = [''] unless @$cloned_rules; # to handle the bare array case
        my $value = $self->_parse_data($item, [], $cloned_rules);
        ## I don't think these are missing params, just a row with invalid fields
        next if( (ref($value)||'') eq 'HASH') && !%$value;
        push @gathered, $value;
      }
      $current->{$local_ns} = \@gathered;
    } else {
      if((ref($rules->[0])||'') eq 'ARRAY') {
        my $value = $self->_parse_data( $context, [@$ns, $rule], shift(@$rules) );
        next unless %$value; # For 'permitted';
        $current->{$rule} = $value;
      } else {
        if($rule eq '') {
          my $value = $context;
          foreach my $pointer (@$ns) {
            if(((ref($value)||'') eq 'HASH') && exists($value->{$pointer})) {
              $value = $value->{$pointer};
            } else {
              $self->_required ? Catalyst::Exception::MissingParameter->throw(param=>join('.', (@$ns, $rule)))  : next MAIN;
            }
          }
          $current = $self->_normalize_array_value($value);
        } else {
          my $value = $context;
          foreach my $pointer (@$ns, $rule) {
            if(((ref($value)||'') eq 'HASH') && exists($value->{$pointer})) {
              $value = $value->{$pointer};
            } else {
              $self->_required ? Catalyst::Exception::MissingParameter->throw(param=>join('.', (@$ns, $rule)))  : next MAIN;
            }
          }
          $current->{$rule} = $self->_normalize_array_value($value);
        }
      }
    }
  }
  return $current;
}


__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Catalyst::Utils::StructuredParameters - Enforce structural rules on your body and data parameters

=head1 SYNOPSIS

=head1 DESCRIPTION

See L<Catalyst::TraitFor::Request::StructuredParameters> for usage.  These are just utility classes
and not likely useful for end user unless you are rolling your own parsing or something.  All
the publically useful docs are there.   

=head1 ATTRIBUTES

This role defines the following attributes:

    TBD

=head1 METHODS

This role defines the following methods:

    TBD

=head1 AUTHOR

See L<Catalyst::TraitFor::Request::StructuredParameters>

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Request>

=head1 COPYRIGHT & LICENSE

See L<Catalyst::TraitFor::Request::StructuredParameters>

=cut
