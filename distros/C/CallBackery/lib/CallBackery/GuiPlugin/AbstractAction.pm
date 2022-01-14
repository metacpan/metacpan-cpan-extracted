package CallBackery::GuiPlugin::AbstractAction;
use Carp qw(carp croak);
use CallBackery::Translate qw(trm);
use CallBackery::Exception qw(mkerror);
use Mojo::Promise;
use Mojo::JSON qw(encode_json);
use Mojo::Util qw(dumper);

=head1 NAME

CallBackery::GuiPlugin::AbstractAction - action form base class

=head1 SYNOPSIS

 use Mojo::Base 'CallBackery::GuiPlugin::AbstractAction';

=head1 DESCRIPTION

The base class for gui forms with actions.

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
    $self->__fixActionCfg;
    return {
        type    => 'action',
        options => $self->screenOpts,
        action  => $self->actionCfg,
    }
};

=head2 screenOpts

Returns a hash of options for the screen Options

=cut

has screenOpts => sub {
    {
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
        next unless $row->{action} =~ /^(submit|upload|download|autoSubmit|save)/;
        next unless $row->{key};
        $map{$row->{key}} = $row;
    }
    return \%map;
};


=head1 METHODS

All the methods of L<CallBackery::GuiPlugin::Abstract> plus:

=cut

=head2 massageConfig

Function to integrate the plugin configuration recursively into the main config
hash.

=cut

sub massageConfig {
    my $self = shift;
    my $cfg = shift;
    $self->__fixActionCfg;
    my $actionCfg = $self->actionCfg;
    for my $button (@$actionCfg){
        if ($button->{action} =~ /popup|wizzard/) {
            my $name = $button->{name};
            # allow same plugin multiple times
            $button->{name} = $name;
            if ($cfg->{PLUGIN}{prototype}{$name}) {
                my $newCfg = encode_json($button->{backend});
                my $oldCfg = encode_json($cfg->{PLUGIN}{prototype}{$name}{backend});
                if ($oldCfg ne 'null' and $newCfg ne $oldCfg) {
                    $self->log->warn("oldCfg=" . dumper $oldCfg);
                    $self->log->warn("newCfg=", dumper $newCfg);
                    die "Not unique plugin instance name $name not allowed as backend config is different\n";
                }
            }
            my $popup = $cfg->{PLUGIN}{prototype}{$name}
                = $self->app->config->loadAndNewPlugin($button->{backend}{plugin});
            $popup->config($button->{backend}{config});
            $popup->name($name);
            $popup->app($self->app);
            $popup->massageConfig($cfg);
        }
    }
    return;
}

=head2 __fixActionCfg

make sure actionCfg buttons only have keys and no names
add properly constructed name properties

=cut

sub __fixActionCfg {
    my $self = shift;
    return $self if $self->{__action_cfg_fixed};
    my $name = $self->name;
    my $pkg = ref $self;
    for my $action (@{$self->actionCfg}) {
        next if $action->{action} eq 'separator'
            or $action->{action} eq 'refresh'
            or $action->{action} eq 'logout';
        if ($action->{name}) {
            $self->log->warn(
               $pkg . " action should not have a name attribute:"
             . " name=$action->{name}"
            );
        }
        if (not $action->{key}) {
            $self->log->warn(
               $pkg . " action should have a key attribute,"
             . " created a key from name=$action->{name} instead"
            );
            $action->{key} = $action->{name};
        }
        # popups and wizzards do need a name internally
        if ($action->{action} =~ /popup|wizzard/) {
            $action->{name} = "${name}_$action->{key}";
        }
    }
    $self->{__action_cfg_fixed} = 1;
    return $self;
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
