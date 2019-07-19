package CallBackery::GuiPlugin::AbstractForm;
use Carp qw(carp croak);
use CallBackery::Translate qw(trm);
use CallBackery::Exception qw(mkerror);
use Mojo::Promise;

=head1 NAME

CallBackery::GuiPlugin::AbstractForm - form base class

=head1 SYNOPSIS

 use Mojo::Base 'CallBackery::GuiPlugin::AbstractForm';

=head1 DESCRIPTION

The base class for gui forms.

=cut

use Mojo::Base 'CallBackery::GuiPlugin::Abstract';

=head1 ATTRIBUTES

The attributes of the L<CallBackery::GuiPlugin::Abstract> class plus:

=head2 screenCfg

Returns a configuration structure for the form. The output from this
method is fed to the callbackery.ui.form.Auto object to build the
Qooxdoo form.

=cut

has screenCfg => sub {
    my $self = shift;
    return {
        type => 'form',
        options => $self->screenOpts,
        form => $self->formCfg,
        action => $self->actionCfg,
    }
};

=head2 screenOpts

Returns a hash of options for the screen Options

=cut

has screenOpts => sub {
    {
        warnAboutUnsavedData => 1
    }
};

=head2 actionCfg

Returns a list of action buttons to place at the top of the form.

=cut

has actionCfg => sub {
   [];
};

=head2 actionCfgMap

TODOC

=cut

has actionCfgMap => sub {
    my $self = shift;
    my %map;
    for my $row (@{$self->actionCfg}){
        next unless $row->{action} =~ /^(submit|upload|download)/;
        next unless $row->{key};
        $map{$row->{key}} = $row;
    }
    return \%map;
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

has formCfgMap => sub {
    my $self = shift;
    my %map;
    for my $row (@{$self->formCfg}){
        next unless $row->{key};
        $map{$row->{key}} = $row;
    }
    return \%map;
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
    my $formData = shift;
    my $entry = $self->formCfgMap->{$fieldName};
    if (not ref $entry){
        die mkerror(4095,trm("sorry, don't know the field you are talking about"));
    }
    return undef if not $entry->{set}{required} and (not defined $formData->{$fieldName} or length($formData->{$fieldName}) == 0);
    return ($entry->{validator} ? $entry->{validator}->($formData->{$fieldName},$fieldName,$formData) : undef);
}

=head2 processData($args)

The default behavior of the method is to validate all the form fields
and then store the data into the config database.

=cut

sub processData {
    my $self = shift;
    my $args = shift;
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
            $self->log->warn("Using handler properties in actionCfg is deprecated. User actionHandler instead.");
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

sub saveFormDataToConfig {
    my $self = shift;
    my $formData = shift;
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

sub getFieldValue {
    my $self = shift;
    my $field = shift;
    my $entry = $self->formCfgMap->{$field};
    return undef unless ref $entry eq 'HASH';
    if ($entry->{getter}){
        if (ref $entry->{getter} eq 'CODE'){
            return $entry->{getter}->($self);
        }
        else {
            warn 'Plugin instance'.$self->name." field $field has a broken getter\n";
        }
    }
    return $self->getConfigValue($self->name.'::'.$field);
}

=head2 getAllFieldValues

Return all field values of the form.

=cut

sub getAllFieldValues {
    my $self = shift;
    my $parentForm = shift;
    my $currentForm = shift;
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

sub getData {
    my $self = shift;
    my $type = shift;
    if ($type eq 'field'){
        return $self->getFieldValue(@_);
    }
    elsif ($type eq 'allFields') {
        return $self->getAllFieldValues(@_);
    }
    else {
        die mkerror(38334, 'Requested unknown data type' . ($type // 'unknown'));
    }
}

=head2 massageConfig

Function to integrate the plugin configuration recursively into the main config
hash.

=cut

sub massageConfig {
    my $self = shift;
    my $cfg = shift;
    my $actionCfg = $self->actionCfg;
    for my $button (@$actionCfg){
        if ($button->{action} eq 'popup'){
            my $name = $button->{name};
            die "Plugin instance name $name is not unique\n"
                if $cfg->{PLUGIN}{prototype}{$name};
            my $popup = $cfg->{PLUGIN}{prototype}{$name}
                = $self->app->config->loadAndNewPlugin($button->{backend}{plugin});
            $popup->config($button->{backend}{config});
            $popup->name($button->{name});
            $popup->app($self->app);
            $popup->massageConfig($cfg);
        }
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
