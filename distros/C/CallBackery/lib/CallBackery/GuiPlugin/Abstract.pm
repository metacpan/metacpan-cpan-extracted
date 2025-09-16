package CallBackery::GuiPlugin::Abstract;
use strict;
use warnings;
use Carp qw(carp croak);
use Storable qw(dclone);
use Data::Dumper;
use Mojo::Template;
use Mojo::Util qw(monkey_patch);
use CallBackery::Exception qw(mkerror);
use autodie;
use Scalar::Util 'blessed';
use IPC::Open3;
use POSIX qw<F_SETFD F_GETFD FD_CLOEXEC>;
use Time::HiRes qw(usleep);
use Mojo::JSON qw(encode_json decode_json true false);
use Mojo::File;
use Scalar::Util 'weaken';
# disable warnings below, otherwise testing will give warnings
eval { local $^W=0; require "sys/ioctl.ph" };

=head1 NAME

CallBackery::GuiPlugin::Abstract - GuiPlugin base class

=head1 SYNOPSIS

 use Mojo::Base 'CallBackery::GuiPlugin::Abstract';

=head1 DESCRIPTION

The abstract base class for callbackery gui classes.

=cut

use Mojo::Base -base, -signatures, -async_await;


=head1 ATTRIBUTES

=head2 config

The Plugin instance specific config section from the master config file.

=cut

has 'config';

=head2 name

The PLUGIN instance 'name' as specified in the C<*** PLUGIN:... ***> section.

=cut

has 'name';

=head2 user

The current user object

=cut

has 'user';


has 'dbHandle' => sub ($self) {
    $self->user->db;
};

    
=head2 tabName

What should the tab holding this plugin be called

=cut

has tabName => sub {
    return shift->config->{'tab-name'};
};

=head2 instantiationMode

Should the plugin in the webui be instantiated immediately or only when the tab gets selected

=cut

has instantiationMode => sub {
    return 'onTabSelection'; # or onStartup
};

=head2 grammar

Returns the L<Config::Grammar> parser for the configuration of this plugin.

=cut

has grammar => sub ($self) {
    return {
        _doc => 'Base class documentation string. Should be overwritten by the child class',
        _vars => [qw(tab-name)],
        _mandatory => [qw(tab-name)],
        'tab-name' => {
            _doc => 'Title of the Plugin Tab'
        },
    };
};

=head2 schema

A very simple minded grammar to json-schema convertor with no magic.
Better supply a proper schema.

=cut

has schema => sub {
    my $self = shift;
    my $grammar = $self->grammar;
    return {
        type => 'object',
        properties => {
            module => {
                type => 'string'
            },
            unlisted => {
                type => 'boolean'
            },
            map {
                $_ => {
                    type => 'string',
                    $grammar->{$_}{_doc} ?
                        ( description => $grammar->{$_}{_doc} ) : (),
                    $grammar->{$_}{_re} ?
                        ( pattern => $grammar->{$_}{_re} ) : (),
                    $grammar->{$_}{_default} ?
                        ( default => $grammar->{$_}{_default} ) : (),
                }
            } @{$grammar->{_vars}},
            map {
                $_ => {
                    type => 'object',
                    $grammar->{$_}{_doc} ?
                        ( description => $grammar->{$_}{_doc} ) : (),
                }
            } @{$grammar->{_sections}},
        },
        required => [
            'module',
            ( $grammar->{_mandatory} ? (
                @{$grammar->{_mandatory}} ) : ()
            )
        ],
        additionalProperties => false
    }
};

=head2 controller

the current controller

=cut

has controller => sub ($self) {
    return $self->user->controller if $self->user;
};

=head2 app

the app object

=cut

has app => sub ($self) {
    return $self->user->app if $self->user;
}, weak => 1;

=head2 log

the log object

=cut

has log => sub ($self) {
    return $self->controller->log if $self->controller;
    return $self->app->log if $self->app
};

=head2 args

some meta information provided when instantiating the plugin.
for example when buidling the response to getUserConfig, args will contain the output of getUrlConfig from the frontend in the key urlConfig, which will allow to pass information from the url to calls like checkAccess.

=cut

has 'args' => sub { {} };

=head2 screenCfg

Returns the information for building a plugin configuration screen.

=cut

has screenCfg => sub {
    return {
        type => '*unknown*',
        options => {},
        # followed by type dependent keys
    }
};

=head2 checkAccess()

Check if the current user may access the Plugin. Override in the Child
class to limit accessibility. By default plugins are not accessible
unless you have numeric UID or the word C<__CONFIG>.

The L<CallBackery::Command::shell> sets the userId to C<__SHELL>. If a
plugin should be configurable interactively it must allow access to
the C<__SHELL> user.

checkAccess can also return a promise or be an async method

=cut

has checkAccess => sub {
    my $self = shift;
    my $userId = $self->user->userId;
    return (defined $userId and ($userId eq '__CONFIG' or $userId =~ /^\d+$/));
};

=head2 mayAnonymous

may this gui plugin run for unauthenticated users ?

=cut

has mayAnonymous => sub {
    return 0;
};

=head2 stateFiles

A list of files that contain the state of the settings configured by
this plugin this is used both for backup purposes and to replicate the
settings to a second installation.

=cut

has stateFiles => sub {
    [];
};

=head2 unconfigureFiles

a list of files to be removed when 'unConfiguring' a device

=cut

has unConfigureFiles => sub {
    [];
};

=head2 eventActions

A map of callbacks that will be called according to events in the
system.  The following events are available:

    configChanged

=cut

has eventActions => sub {
    {};
};

=head1 METHODS

All the methods of L<Mojo::Base> plus:

=cut


=head2 makeRxValidator(rx,error)

Create a regular expression base validator function.  The supplied
regular expression gets anchored front and back automatically.

=cut

sub createRxValidator {
    my $self = shift;
    my $rx = shift;
    my $error = shift;
    return sub {
        my $value = shift;
        return undef if $value =~ /^${rx}$/;
        return $error;
    };
}

=head2 filterHashKey(data,key)

Walks a hash/array structure and removes all occurrences of the given
key.

CODE references get turned into 'true' values and JSON true/false get
passed on.

=cut

sub filterHashKey {
    my $self = shift;
    my $data = shift;
    my $filterKey = shift;
    my $ref = ref $data;
    if (not $ref
        or $ref eq ref true
        or $ref eq 'CallBackery::Translate'){
        return $data;
    }
    elsif ($ref eq 'CODE'){
        return true;
    }
    elsif ($ref eq 'ARRAY'){
        return [ map { $self->filterHashKey($_,$filterKey) } @$data ];
    }
    elsif ($ref eq 'HASH'){
        return {
            map {
                $_ ne $filterKey
                ? ( $_ => $self->filterHashKey($data->{$_},$filterKey) )
                : ();
            } keys %$data
        }
    }
    return undef;
}

=head2 processData(arguments)

Take the data from the plug-in screen and process them.

=cut

sub processData {
    my $self = shift;
    warn "Processing ".Dumper(\@_);
}

=head2 getData(arguments)

Receive current data for plug-in screen content.

=cut

sub getData {
}

=head2 reConfigure

Re-generate all configuration that does not require direct user
input. This function may be called from within action handlers to
apply newly acquired data to to the running system.

=cut

sub reConfigure {
}

=head2 validateData(arguments)

Validate user supplied data prior to acting on it.

=cut

sub validateData {
}

=head2 mergeGrammar

A very simpleminded grammar merger with no recursion. For identical
keys, the later instance wins.

=cut

sub mergeGrammar {
    my $self = shift;
    my $grammar = dclone shift;
    my $newGrammar = shift;
    for my $key (keys %$newGrammar){
        my $existing = $grammar->{$key};
        my $ref = ref $existing // 'NONE';
        $ref eq 'ARRAY' && do {
            push @$existing, @{$newGrammar->{$key}};
            next;
        };
        $ref eq 'HASH' && do {
            for my $subKey (keys %{$newGrammar->{$key}}) {
                $existing->{$subKey} = $newGrammar->{$key}{$subKey};
            };
            next;
        };
        $grammar->{$key} = $newGrammar->{$key};
    }
    return $grammar;
}

=head2 varCompiler

Returns a compiler sub reference for use in configuration variables or
_text sections with perl syntax. The resulting sub will provide access
to a hash called $variableName.

=cut

sub varCompiler {
    my $self = shift;
    return sub {
        my $code = $_[0] // '';
        # check and modify content in place
        my $perl = 'sub {'.$code.'}';
        my $sub = eval $perl; ## no critic (ProhibitStringyEval)
        if ($@){
            return "Failed to compile $code: $@ ";
        }
        eval { $sub->({}) };
        if ($@){
            return "Failed to run $code: $@ ";
        }
        # MODIFY the calling argument
        $_[0] = $sub;
        return;
    };
}

=head2 massageConfig($cfg)

Allow the plugin to 'massage' the config hash ... doing this requires
deep knowledge of the cfg structure ...

=cut

sub massageConfig {
    my $self = shift;
    my $cfg = shift;
}

=head2 renderTemplate(template,destination)

Render the given template and write the result into the given
file. These templates support the L<Mojo::Template> language enhanced
by the command C<L('Plugin::key')> which looks up values from the
config database. The convention is that each plugin writes data in
it's own namespace.

If the destination already exists, the method compares the current
content with the new one. It will only update the file if the content
differs.

The method returns 0 when there was no change and 1 when a new version
of the file was written.

These additional commands are available to the templates.

=over

=item *

slurp(file)

=back

=cut

has cfgHash => sub {
    my $self = shift;
    return $self->app->config->cfgHash;
}, weak => 1;

has template => sub {
    my $self = shift;
    my $mt = Mojo::Template->new();
    $self->dbHandle;   
    my $dbLookup = sub { $self->getConfigValue(@_) // ''};
 
    # don't use L, use dbLookup instead
    monkey_patch $mt->namespace,
        L => $dbLookup;

    monkey_patch $mt->namespace,
        dbLookup => $dbLookup;

    monkey_patch $mt->namespace,
        app => sub { $self->app };

    monkey_patch $mt->namespace,
        slurp => sub {
            my $filename = shift;
            return Mojo::File->new($filename)->slurp;
        };
    monkey_patch $mt->namespace,
        cfgHash => sub { $self->cfgHash };

    monkey_patch $mt->namespace,
        pluginCfg => sub { my $instance = shift;
            my $cfg = $self->cfgHash->{PLUGIN}{prototype}{$instance}->config;
            weaken $cfg;
            return $cfg;
        };
    return $mt;
};


has homeDir => sub {
    [getpwuid $>]->[7];
};

sub renderTemplate{
    my $self = shift;
    my $template = shift;
    my $destination = Mojo::File->new(shift);
    $self->log->debug('['.$self->name.'] processing template '.$template);
    my $newData = $self->template->render($self->app->home->rel_file('templates/system/'.$template)->slurp);
    if (-r $destination){
        my $oldData = Mojo::File->new($destination)->slurp;
        if ($newData eq $oldData){
            return 0
        }
    }
    my $dir = $destination->dirname;
    if (not -d $dir){
        Mojo::File->new($dir)->make_path({mode => 755});
    }

    $self->log->debug('['.$self->name."] writing $destination\n$newData");
    eval {
        local $SIG{__DIE__};
        $destination->spew($newData);
    };
    if ($@){
        if (blessed $@ and $@->isa('autodie::exception')){
            $self->log->error('['.$self->name."] writing $template -> $destination: ".$@->errno);
        }
        else {
            die $@;
        }
    }
    if ($self->controller and $self->controller->can('runEventActions')){
        $self->controller->runEventActions('changeConfig');
    }
    return 1;
}

=head2 getConfigValue(key)

Read a config value from the database.

=cut

sub getConfigValue {
    my $self = shift;
    my $key = shift;
    my $value = $self->dbHandle->getConfigValue($key);
    return undef if not defined $value;
    my $ret = eval { decode_json($value) };
    # warn "GET $key -> ".Dumper($ret);
    if ($@){
        die mkerror (3984,$@);
    }
    return $ret->[0];
}

=head2 setConfigValue(key)

Save a config value to the database.

=cut

sub setConfigValue {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    # warn "SET $key -> ".Dumper([$value]);
    $self->dbHandle->setConfigValue($key,encode_json([$value]));
    if ($self->controller->can('runEventActions')){
        $self->controller->runEventActions('changeConfig');
    }
    return $value;
}

=head2 systemNoFd(args)

A version of the system function that makes sure to NOT to inherit any
extra filehandles to the kids and sends the output of the call system
log file. I would suggest to use this in preference to the normal
system function. Especially when launching daemons since Mojo seems to
fiddle with $^F and will thus inherit open sockets to child processes.

If the binary name starts with -, the output will be ignored ... this
can be necessary for programs starting daemons that do not close their
output. Otherwhise you will read the output of the daemon and NOT
terminate. We are also using kill 0 to check if the process is still
active.

=cut

sub systemNoFd {
    my $self = shift;
    my $binary = shift;
    my $logoutput = 1;
    if ($binary =~ s/^-//){
        $logoutput = 0;
    }
    my $rdr;
    my $wtr;

    # make sure there is no inheriting any sockets
    # mojo should actually take care of this
    for my $path (glob '/proc/self/fd/*'){
        no autodie;
        my ($fd) = $path =~ m{/proc/self/fd/(\d+)} or next;
        $fd > 3 or next;
        my $link = readlink $path or next;
        $link =~ /socket/ or next;
        if (open my $fh, q{>&=}, int($fd)){
            # $self->log->debug("Setting FIOCLEX on fd $fd ($link)");
            if (defined &FIOCLEX){
                ioctl $fh, FIOCLEX(),0;
            }
            elsif ($^O eq 'linux'){
                # it seems we did not load the ioctl headers ...
                # let's try this blindly since we are on linux after all
                ioctl $fh, 21585, 0;
            }
            else {
                die "investigate this (FD_CLOEXEC) since it should work but does not!";
                fcntl($fh, F_SETFD, FD_CLOEXEC);
            }
        }
    }
    my $pid = eval {
        open3($wtr, $rdr, undef,$binary,@_);
    };
    my $args = join " ",@_;
    if ($@){
        $self->log->warn("exec '$binary $args' failed: $!");
    }
    else {
        $self->log->debug("running $binary($pid) $args");
        if ($logoutput){
            while (my $line = <$rdr>){
                $line =~ s/[\r\n]//g;
                $self->log->debug("$binary($pid) out: $line");
                usleep 200; # give the process a chance to quit
                last if not kill 0,$pid; # dead yet?
            }
        }
        my $ret = waitpid( $pid, 0 );
        $self->log->debug("running $binary($pid) done $ret");
        return $ret;
    }
    return undef;
}

sub DESTROY ($self) {
    # we are only interested in objects that get destroyed during
    # global destruction as this is a potential problem
    my $class = ref($self) // "child of ". __PACKAGE__;
    if (${^GLOBAL_PHASE} ne 'DESTRUCT') {
        # $self->log->debug($class." DESTROYed");
        return;
    }
    if (blessed $self && ref $self->log){
        $self->log->debug("late destruction of $class object during global destruction")
            unless $self->{prototype};
        return;
    }
    warn "extra late destruction of $class object during global destruction\n"
        unless $self->{prototype};
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
