package CallBackery::GuiPlugin::AbstractForm;
use Carp qw(carp croak);
use CallBackery::Translate qw(trm);
use CallBackery::Exception qw(mkerror);
use Mojo::Promise;
use Mojo::Util qw(dumper);
use Time::HiRes;

=head1 NAME

CallBackery::GuiPlugin::AbstractForm - form base class

=head1 SYNOPSIS

 use Mojo::Base 'CallBackery::GuiPlugin::AbstractForm', -signatures;

=head1 DESCRIPTION

The base class for gui forms.

=cut

use Mojo::Base 'CallBackery::GuiPlugin::AbstractAction', -signatures;

=head1 ATTRIBUTES

The attributes of the L<CallBackery::GuiPlugin::Abstract> class plus:

=head2 screenCfg

Returns a configuration structure for the form. The output from this
method is fed to the callbackery.ui.form.Auto object to build the
Qooxdoo form.

=cut

has screenCfg => sub ($self) {
    my $cfg = $self->SUPER::screenCfg;
    $cfg->{type} = 'form';
    $cfg->{form} = $self->formCfg;
    return $cfg;
};

=head2 formCfg

Returns the content of  the form.

=cut

has formCfg => sub {
   [];
};

=head2 formCfg

TODOC

=cut

has formCfgMap => sub ($self) {
    my %map;
    for my $row (@{$self->formCfg}){
        next unless $row->{key};
        $map{$row->{key}} = $row;
    }
    return \%map;
};


=head2 formData ()

Return the form data independently from the form phase.

=cut

sub formData ($self) {
    my $args = $self->args || {};
    return $args->{currentFormData} || $args->{formData} || {};
};


=head2 formPhase ()

Return the form phase.

=cut

sub formPhase ($self) {
    my $args = $self->args;

    # if called from CardList or Table plugins
    return 'instantiate' if $args->{selection};

    # data
    if ($args->{currentFormData}) {
        return 'reconfigure' if $args->{triggerField};
        return 'initialize';
    }

    # actions
    if ($args->{formData}) {
        return "action:$args->{key}" if $args->{key};
    }

    # config
    if ( $args and not keys $args->%*) {
        return 'pluginConfig';
    }

    # catch all, if ever reached
    $self->log->warn('Unknown form phase, args=', dumper $args);
    return 'unknown';
};


=head1 METHODS

All the methods of L<CallBackery::GuiPlugin::Abstract> plus:

=cut

=head2 validateData(fieldName,formData)

If the given value is valid for the field, return undef else return
an error message.

=cut

sub validateData {
    my $self = shift;
    my $fieldName = shift;
    my $formData = shift || {};
    my $entry = $self->formCfgMap->{$fieldName};
    if (not ref $entry){
        die mkerror(4095,trm("sorry, don't know the field you are talking about"));
    }
    my $fieldIsEmpty = (not defined $formData->{$fieldName} or length($formData->{$fieldName}) == 0);
    return if not $entry->{set}{required} and $fieldIsEmpty;
    if ($entry->{validator}){
        my $start = time;
        my $data = $entry->{validator}->($formData->{$fieldName},$fieldName,$formData);
        $self->log->debug(sprintf("validator %s: %0.2fs",$fieldName,time-$start));
        return $data;
    }
    # if there is no validator but the field is required, complain
    # if the content is empty
    elsif ($entry->{set}{required} and $fieldIsEmpty){
        return trm('The %1 field is required',$fieldName);
    }
    return;
}

=head2 processData($args)

The default behavior of the method is to validate all the form fields
and then store the data into the config database.

=cut

sub processData ($self, $args, $extraArgs=undef) {
   $self->args($args) if $args;
    my $form = $self->formCfgMap;
    my $formData = $args->{formData};
    # this is only to be sure ... data should be pre-validated
    for my $key (keys %$form){
        if (my $error = $self->validateData($key,$formData)){
            die mkerror(7492,$error);
        }
    }
    if ($args->{key}){
        my $handler = $self->actionCfgMap->{$args->{key}}{actionHandler};
        if (ref $handler eq 'CODE'){
            return $handler->($self,$formData);
        }
        $handler = $self->actionCfgMap->{$args->{key}}{handler};
        if (ref $handler eq 'CODE'){
            $self->log->warn("Using handler properties in actionCfg is deprecated. Use actionHandler instead.");
            return $handler->($formData);
        }
        $self->log->error('Plugin instance '.$self->name." action $args->{key} has a broken handler");
        die mkerror(7623,'Plugin instance '.$self->name." action $args->{key} has a broken handler");
    }
}


=head2 saveFormDataToConfig(data)

Save all the form fields for which is available to the config
database. Keys will be prefixed by the plugin instance name
(C<PluginInstance::keyName>).

=cut

sub saveFormDataToConfig ($self, $formData) {
    my $form = $self->formCfgMap;
    for my $key (keys %$form){
        next if not exists $formData->{$key};
        $self->setConfigValue($self->name.'::'.$key,$formData->{$key});
    }
}

=head2 getFieldValue(field)

Fetch the current value of the field. This will either use the getter
method supplied in the form config or try to fetch the value from the
config database.

=cut

sub getFieldValue ($self, $field) {
    my $entry = $self->formCfgMap->{$field};
    my $log = $self->log;
    return undef unless ref $entry eq 'HASH';
    if ($entry->{getter}){
        if (ref $entry->{getter} eq 'CODE'){
            my $start = time;
            my $data = $entry->{getter}->($self);
            if (eval { blessed $data && $data->isa('Mojo::Promise')}){
                $data = $data->then(sub ($value) {
                    $log->debug(sprintf("async getter %s: %0.2fs",$field,time-$start));
                    return $value;
                });
            }
            else {
                $log->debug(sprintf("getter %s: %0.2fs",$field,time-$start));
            }
            return $data;
        }
        else {
            $log->warn('Plugin instance'.$self->name." field $field has a broken getter\n");
        }
    }
    return $self->getConfigValue($self->name.'::'.$field);
}

=head2 getAllFieldValues

Return all field values of the form.

=cut

sub getAllFieldValues ($self, $parentForm, $currentForm, $args) {
    my %map;
    my @promises;
    $self->args($currentForm) if $currentForm;
    for my $key (keys %{$self->formCfgMap}){
        my $value = $self->getFieldValue($key);
        if (eval { blessed $value && $value->isa('Mojo::Promise')}){
            push @promises, $value;
            $value->then(
                sub{
                    $map{$key} = shift;
                },
                sub {
                    die shift;
                }
            );
        }
        else {
            $map{$key} = $self->getFieldValue($key);
        }
    }
    if (@promises){
        return Mojo::Promise->new->all(@promises)->then(sub {
            return \%map;
        });
    }
    return \%map;
}


=head2 getData (type,field)

Return the value of the given field. If no field name is specified
return a hash with all the current data known to the plugin.

=cut

sub getData ($self, $type, @args) {
    if ($type eq 'field'){
        return $self->getFieldValue(@args);
    }
    elsif ($type eq 'allFields') {
        return $self->getAllFieldValues(@args);
    }
    else {
        die mkerror(38334, 'Requested unknown data type ' . ($type // 'unknown'));
    }
}

1;

__END__

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 COPYRIGHT

Copyright (c) 2013 by OETIKER+PARTNER AG. All rights reserved.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2013-12-16 to 1.0 first version

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et
