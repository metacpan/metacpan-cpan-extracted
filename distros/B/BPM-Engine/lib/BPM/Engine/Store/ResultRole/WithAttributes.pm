package BPM::Engine::Store::ResultRole::WithAttributes;
BEGIN {
    $BPM::Engine::Store::ResultRole::WithAttributes::VERSION   = '0.01';
    $BPM::Engine::Store::ResultRole::WithAttributes::AUTHORITY = 'cpan:SITETECH';
    }

# ABSTRACT: attribute creator and accessor role for ProcessInstance and ActivityInstance

use namespace::autoclean;
use Moose::Role;
use JSON;
use BPM::Engine::Util::ExpressionEvaluator;
use BPM::Engine::Exceptions qw/throw_store throw_param/;

sub attribute {
    my ($self, $name, $value) = @_;
    
    throw_param("Need a name") unless $name;
    my $attr = $self->attributes->find({ name => $name }) 
        or throw_store error => "Attribute named '$name' not found";
    
    if(defined $value) {
        die("Attribute '$name' is read-only") if($attr->is_readonly);
        #$value = $attr->validate($value);
        if($attr->type eq 'BasicType' && !$attr->is_array) {
            $value = [$value];
            }
        throw_param("Attribute value not a reference") unless(ref($value));
        $attr->update({ value => $value });
        }
    
    return $attr;
    }

sub attribute_hash {
    my $self = shift;
    return { 
        map { 
            $_->name => $_->value 
            } $self->attributes->all
        };
    }

sub create_attributes {
    my ($self, $scope, $data_fields) = @_;

    throw_param error => "Need scope and data fields" 
        unless($scope && $data_fields && ref($data_fields) eq 'ARRAY');
    
    my $expr = BPM::Engine::Util::ExpressionEvaluator->load(
        process           => $self->process,
        process_instance  => ref($self) =~ /Activity/ ?
            $self->process_instance : $self,
        );
    
    my $build_value = sub {
        my $init = shift || {};
        ## no critic (ProhibitExplicitReturnUndef)
        return undef unless defined $init->{content};
        my $ivalue = $init->{content};
        throw_param error => "InitialValue is not a string" if(ref($ivalue));

        $init->{ScriptType} ||= '';
        if($init->{ScriptType} eq 'json') {
            $ivalue = decode_json($ivalue);
            }
        else {
            $ivalue = $expr->render($ivalue);
            }
        
        return $ivalue;
        };

    my $guard = $self->result_source->schema->txn_scope_guard;

    foreach my $param(@{$data_fields}) {
        # Only the SchemaType DataType is not declared when XPDL is parsed
        my $type = (keys %{ $param->{DataType} })[0] || 'SchemaType';
        my $value = &$build_value($param->{InitialValue});
        if($value && $type eq 'BasicType' && !$param->{IsArray}) {
            $value = [$value];
            }
        $self->add_to_attributes({
            name           => $param->{Id},
            mode           => $param->{Mode},
            scope          => $scope,
            type           => $type,
            type_attr      => $type ? $param->{DataType}->{$type} : undef,
            is_readonly    => $param->{ReadOnly} || 0,
            is_array       => $param->{IsArray} || 0,
            is_correlation => $param->{Correlation} || 0,
            'length'       => $param->{Length} || 0,
            value          => $value,
            });
        }
    
    $guard->commit;
    
    return;
    }

no Moose::Role;

1;
__END__