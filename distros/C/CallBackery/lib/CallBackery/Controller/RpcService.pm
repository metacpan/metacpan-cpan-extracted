package CallBackery::Controller::RpcService;

use Mojo::Base qw(Mojolicious::Plugin::Qooxdoo::JsonRpcController);
use CallBackery::Exception qw(mkerror);
use CallBackery::User;
# use Data::Dumper;
use Scalar::Util qw(blessed weaken);
use Mojo::JSON qw(encode_json decode_json);

=head1 NAME

CallBackery::RpcService - RPC services for CallBackery

=head1 SYNOPSIS

This module gets instantiated by L<CallBackery> and provides backend functionality.

=head1 DESCRIPTION

This module provides the following methods

=cut

# the name of the service we provide
has service => 'default';

=head2 allow_rpc_access(method)

is this method accessible?

=cut

my %allow = (
    getBaseConfig => 1,
    login => 1,
    logout => 1,
    ping => 1,
    getUserConfig => 2,
    getPluginConfig => 2,
    validatePluginData => 2,
    processPluginData => 2,
    getPluginData => 2,
    getSessionCookie => 2
);

has config => sub {
    shift->app->config;
};

has user => sub {
    my $self = shift;
    my $obj = $self->app->userObject->new(controller=>$self);
    #
    weaken $obj->{controller};
    return $obj;
};

has log => sub {
    my $log = shift->app->log;
    return $log;
};

has pluginMap => sub {
    my $map = shift->config->cfgHash->{PLUGIN};
    return $map;
};


sub allow_rpc_access {
    my $self = shift;
    my $method = shift;
    return (exists $allow{$method} and ($allow{$method} == 1 or $self->user->isUserAuthenticated));
}

=head2 ping()

check if the server is happy with our authentication state

=cut

sub ping {
    return 'pong';
}

=head2 getSessionCookie()

Return a timeestamped session cookie. For use in the X-Session-Cookie header or as a xsc field
in form submissions. Note that session cookies for form submissions are only valid for 2 seconds.
So you have to get a fresh one from the server before submitting your form.

=cut

sub getSessionCookie {
    shift->user->makeSessionCookie();
}

=head2 getConfig()

get some gloabal configuration information into the interface

=cut

sub getBaseConfig {
    my $self = shift;
    return $self->config->cfgHash->{FRONTEND};
}

=head2 login(user,password)

Check login and provide the user specific interface configuration as a response.

=cut

sub login { ## no critic (RequireArgUnpacking)
    my $self = shift;
    my $login = shift;
    my $password = shift;
    my $cfg = $self->config->cfgHash->{BACKEND};
    if ($self->user->login($login,$password)){
        return {
            sessionCookie => $self->user->makeSessionCookie()
        };
    }
    return undef;
}

=head2 logout

Kill the session.

=cut

sub logout {
    my $self = shift;
    $self->session(expires=>1);
    return 'http://youtu.be/KGsTNugVctI';
}



=head2 instanciatePlugin

get an instance for the given plugin

=cut

sub instanciatePlugin {
    my $self = shift;
    my $name = shift;
    my $args = shift;
    my $user = $self->user;
    return $self->config->instanciatePlugin($name,$user,$args);
}

=head2 processPluginData(plugin,args)

handle form sumissions

=cut

sub processPluginData {
    my $self = shift;
    my $plugin = shift;
    # creating two statements will make things
    # easier to debug since there is only one
    # thing that can go wrong per line.
    my $instance = $self->instanciatePlugin($plugin);
    return $instance->processData(@_);
}

=head2 validateField(plugin,args)

validate the content of the given field for the given plugin

=cut

sub validatePluginData {
    my $self = shift;
    my $plugin = shift;
    return $self->instanciatePlugin($plugin)
        ->validateData(@_);
}

=head2 getPluginData(plugin,args);

return the current value for the given field

=cut

sub getPluginData {
    my $self = shift;
    my $plugin = shift;
    return $self->instanciatePlugin($plugin)
        ->getData(@_);
}


=head2 getUserConfig

returns user specific configuration information

=cut

sub getUserConfig {
    my $self = shift;
    my @plugins;
    my $ph = $self->pluginMap;
    for my $name (@{$ph->{list}}){
        my $obj = eval {
            $self->instanciatePlugin($name);
        };
        warn "$@" if $@;
        next unless $obj;
        push @plugins, {
            tabName => $obj->tabName,
            name => $obj->name,
            instanciationMode => $obj->instanciationMode
        };
    }
    return {
        userInfo => $self->user->userInfo,
        plugins => \@plugins,
    };
}

=head2 getPluginConfig(plugin,args)

returns a plugin configuration removing all the 'backend' keys and non ARRAY or HASH
references in the process.

=cut

sub getPluginConfig {
    my $self = shift;
    my $plugin = shift;
    my $args = shift;
    my $obj = $self->instanciatePlugin($plugin,$args);
    return $obj->filterHashKey($obj->screenCfg,'backend');
}

=head2 runEventActions(event[,args])

Call the eventAction handlers of all configured plugins. Currently the following events
are known.

   changeConfig

=cut

sub runEventActions {
    my $self = shift;
    my $event = shift;
    for my $obj (@{$self->config->configPlugins}){
        weaken $obj->controller($self)->{controller};
        if (my $action = $obj->eventActions->{$event}){
            $action->(@_)
        }
    }
}

=head2 setPreDestroyAction(key,callback);

This can be used to have tasks completed at the end of a webtransaction since
the controller gets instanciated per transaction.
An example application would be backing up the configuration changes only
once even if more than one configChange event has occured.

=cut

my $runPreDestroyActions = sub {
    my $self = shift;
    my $actions = $self->{preDestroyActions} // {};
    $self->log->debug('destroying controller');
    for my $key (keys %$actions){
        $self->log->debug('running preDestroyAction '.$key);
        eval {
            $actions->{$key}->();
        };
        if ($@){
            $self->log->error("preDestoryAction $key: ".$@);
        }
        # and thus hopefully releasing the controller
        delete $actions->{$key};
    }
    delete $self->{preDestroyActions}
};

sub setPreDestroyAction {
    my $self = shift;
    my $key = shift;
    my $cb = shift;
    if (not $self->{preDestroyActions}){
        # we want to run these pretty soon, basically as soon as
        # controll returns to the ioloop
        Mojo::IOLoop->timer("0.2" => sub{ $self->$runPreDestroyActions });
    }
    $self->{preDestroyActions}{$key} = $cb;
}

sub DESTROY {
    my $self = shift;
    $self->log->debug('Destroying RpcService controller');
}



=head2 handleUpload

Process incoming upload request. This is getting called via a route and NOT
in the usual way, hence we  have to render our own response!

=cut


sub handleUpload {
    my $self = shift;
    if (not $self->user->isUserAuthenticated){
        return $self->render(text=>encode_json({exception=>{message=>'Access Denied',code=>4922}}));
    }
    my $name = $self->param('name');
    if (not $name){
        return self->render(text=>encode_json({exception=>{message=>'Plugin Name missing',code=>3934}}));
    }

    my $upload = $self->req->upload('file');
    if (not $upload){
        return $self->render(text=>encode_json({exception=>{message=>'Upload Missing',code=>9384}}));
    }
    my $obj = $self->config->instanciatePlugin($name,$self->user);

    my $form;
    if (my $formData = $self->req->param('formData')){
        $form = eval { decode_json($formData) };
        if ($@){
           return $self->render(text=>encode_json({exception=>{message=>'Data Decoding Problem '.$@,code=>7932}}));
        }
    }
    $form->{uploadObj} = $upload;

    my $return = eval {
        $obj->processData({
            key => $self->req->param('key'),
            formData => $form,
        });
    };
    if ($@){
        if (blessed $@){
            if ($@->isa('CallBackery::Exception')){
                return $self->render(text=>encode_json({exception=>{message=>$@->message,code=>$@->code}}));
            }
            elsif ($@->isa('Mojo::Exception')){
                return $self->render(text=>encode_json({exception=>{message=>$@->message,code=>9999}}));
            }
        }
        return $self->render(text=>encode_json({exception=>{message=>$@,code=>9999}}));
    }
    #warn Dumper $return;
    $self->render(text=>encode_json($return));
}

=head2 handleDownload

Process incoming download request. The handler expects two parameters: name
for the plugin instance and formData for the data of the webform.

The handler getting the request must return a hash with the following elements:

=over

=item filename

name of the download when saved

=item type

mime-type of the download

=item asset

a L<Mojo::Asset>. eg C<Mojo::Asset::File->new(path => '/etc/passwd')>.

=back

=cut

sub handleDownload {
    my $self = shift;

    if (not $self->user->isUserAuthenticated){
        return $self->render(text=>encode_json({exception=>{message=>'Access Denied',code=>3928}}));
    }

    my $name = $self->param('name');
    my $key = $self->param('key');
    if (not $name){
        return $self->render(text=>encode_json({exception=>{message=>'Plugin Name missing',code=>3923}}));
    }

    my $obj = $self->config->instanciatePlugin($name,$self->user);

    my $form;
    if (my $formData = $self->req->param('formData')){
        $form = eval { decode_json($formData) };
        if ($@){
            return $self->render(text=>encode_json({exception=>{message=>'Data Decoding Problem '.$@,code=>3923}}));
        }
    }
    my $map = eval {
        $obj->processData({
            key => $key,
            formData => $form,
        });
    };
    if ($@){
        if (blessed $@){
            if ($@->isa('CallBackery::Exception')){
                return $self->render(text=>encode_json({exception=>{message=>$@->message,code=>$@->code}}));
            }
            elsif ($@->isa('Mojo::Exception')){
                return $self->render(text=>encode_json({exception=>{message=>$@->message,code=>9999}}));
            }
        }
        return $self->render(text=>encode_json({exception=>{message=>$@,code=>9999}}));
    }
    #warn Dumper $return;
    $self->res->headers->content_type($map->{type}.';name=' .$map->{filename});
    $self->res->headers->content_disposition('attachment;filename='.$map->{filename});
    $self->res->content->asset($map->{asset});
    $self->rendered(200);
}


1;
__END__

=head1 BUGS

The idea was to implement preDestoryActions via a DESTROY method, but
it seems that the datastructures in the controller are not letting it
DESTORY itself as the handle goes out of scope. For now I am using the
finish event on tx ... not pretty.

=head1 COPYRIGHT

Copyright (c) 2013 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2013-01-01 to Initial

=cut

1;

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
