# ============================================================================
package Business::UPS::Tracking::Role::Print;
# ============================================================================
use utf8;
use 5.0100;

use Moose::Role;
no if $] >= 5.017004, warnings => qw(experimental::smartmatch);

use Text::SimpleTable;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Role::Serialize - Serialize objects
  
=head1 DESCRIPTION

This role provides methods to serialize objects into a L<Text::SimpleTable>
object. 

=head1 METHODS

=head3 printall

 $tale = $self->printall($tale);
 say $tale->draw();

Serialize an object into a table.

=cut

sub printall {
    my ($self,$table) = @_;
    
    $table ||= Text::SimpleTable->new(27,44);
    
    foreach my $attribute ($self->meta->get_all_attributes) {
        next 
            unless $attribute->does('Printable');
        
        my $value = $attribute->get_value($self);
        
        next 
            unless defined $value;
        
        my $name =  $attribute->has_documentation ? 
            $attribute->documentation() :
            $attribute->name;
        
#        if ($attribute->has_printer) {
#            $value = $attribute->printer->($self);
#        }
        
        $self->_print_value(
            table   => $table,
            value   => $value,
            name    => $name,
        );
    }
    return $table;
}

sub _print_value {
    my ($self,%params) = @_;
    
    
    my $table = $params{table};
    my $value = $params{value};
    my $name = $params{name};
    
    return unless $value;

    $name = $params{index}.'. '.$name
        if $params{index};
    
    given (ref $value) {
        when('') {
            $table->row($name,$value);
        }
        when('ARRAY') {
            my $index = 1;
            foreach my $element (@$value) {
                $self->_print_value(
                    table   => $table,
                    value   => $element,
                    name    => $name,
                    index   => $index,
                );
                $index ++;
            }
        }
        when('HASH') {
            # TODO
        }
        when(['CODE','IO','GLOB','FORMAT']) {
            warn('Cannot print $_');
        }
        when('DateTime') {
            if ($value->hour == 0 
                && $value->minute == 0 
                && $value->second == 0) {
                $table->row($name,$value->ymd('.'));
            } else {
                $table->row($name,$value->ymd('.').' '.$value->hms(':'));
            }
        }
        # Some object 
        default {
            if ($value->can('meta')
                && $value->meta->does_role('Business::UPS::Tracking::Role::Print')
                && $value->can('printall')) {
                $table->hr();
                $table->row($name,'');
                $table->hr();
                $value->printall($table);
            } elsif ($value->can('printall')) {
                my $output = $value->printall;
                return
                    unless $output;
                $table->row($name,$output)
            } else {
                $table->row($name,$value);
            }
        }
    } 
    return;  
}

no Moose::Role;
1;