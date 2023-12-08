package CallBackery::Model::ConfigJsonSchema;

=head1 NAME

CallBackery::Model::ConfigJsonSchema - get parse configuration file for CallBackery

=head1 SYNOPSIS

 use CallBackery::Model::ConfigYAML;
 my $cfg = CallBackery::Config->new(file=>$file);
 my $hash_ref = $cfg->cfgHash();
 my $pod = $cfg->pod();

=head1 DESCRIPTION

CallBackery gets much of its configuration from this config file.

=cut

use Mojo::Base 'CallBackery::Config', -signatures;
use JSON::Validator;
use Mojo::Exception;
use Mojo::Util qw(dumper);
use Mojo::Loader qw(data_section);
use YAML::XS qw(LoadFile Load);
use Mojo::JSON qw(true false);
use CallBackery::Translate qw(trm);

$YAML::XS::Boolean = 'JSON::PP';

=head2 cfgHash

a hash containing the data from the config file

=cut

my $walker;
$walker = sub ($data, $cb, $path='' ) {
    if (ref $data eq 'HASH') {
        for my $key (keys %$data) {
            $data->{$key} = $walker->($data->{$key},$cb,$path.'/'.$key);
        }
    }
    elsif (ref $data eq 'ARRAY') {
        my $i = 0;
        for my $item (@$data) {
            $item = $walker->($item, $cb, $path.'/'.$i);
            $i++;
        }
    }
    else {
        return $cb->($path,$data);
    }
    return $data;
};

=head2 cfgHash

a hash containing the data from the config file. If the environment
variable CM_CB_OVERRIDE_... is set, the value from the config file is
overridden with the value from the environment.

Example config file:

  BACKEND:
    cfg_db: 'dbi:SQLite:dbname=/opt/running/cb.db'
  LIST:
    - hello
    - world
    
Example environment override:
    
    export CB_CFG_OVERRIDE_BACKEND_CFG_DB='dbi:SQLite:dbname=/tmp/cb.db'
    export CB_CFG_OVERRIDE_LIST_0='goodbye'

=cut

has cfgHash => sub ($self) {
    my $cfgRaw = eval { LoadFile($self->file) };
    if ($@) {
        Mojo::Exception->throw("Loading ".$self->file.": $@");
    }
    my $cfg = $walker->($cfgRaw, sub ($path,$data) {
        my $env = 'CB_CFG_OVERRIDE'.$path;
        $env =~ s/\//_/g;
        if (exists $ENV{$env} and my $override = $ENV{$env}) {
            $self->log->debug("overriding cfg $path ($data) with ENV \$$env ($override)");
            return $override;
        }
        return $data;
    });
    if (my @errors = $self->validator->validate($cfg)){
        Mojo::Exception->throw("Validating ".$self->file.":\n".join "\n",@errors);
    }
    return $cfg;
};

=head2 pod

returns a pod documenting the config file

=cut

has pod => sub ($self) {
    return "pod output for YAML is not supported";
};


has grammar => sub ($self) {
    die "The grammar is now described in the 'schema' attribute. Please upgrade!";
};

has schema => sub ($self) {
    my $yaml = data_section __PACKAGE__, 'config-schema.yaml';
    my $schema = eval {
        Load($yaml);
    };
    if ($@) {
        Mojo::Exception->throw("$@");
    }
    return $schema;
};

sub validator ($self) {
    my $validator = JSON::Validator->new();
    $validator->schema($self->schema);
    return $validator;
}


=head2 postProcessCfg

Post process the configuration data into a format that is easily used
by the application.

=cut

sub postProcessCfg ($self) {
    my $cfg = $self->cfgHash;
    my $schema = $self->schema;
    my @items;
    my %pluginMap;
    my @fullPluginList;
    my @pluginList;
    for my $prop (keys %{$schema->{properties}{BACKEND}{properties}}) {
        my $default = $schema->{properties}{BACKEND}{properties}{$prop}{default};
        $cfg->{BACKEND}{$prop} //= $default if $default;
    }
    for my $prop (keys %{$schema->{properties}{FRONTEND}{properties}}) {
        my $default = $schema->{properties}{FRONTEND}{properties}{$prop}{default};
        $cfg->{FRONTEND}{$prop} //= $default if $default;
    }
    for my $item (@{$cfg->{PLUGIN}}) {
        my ($name) = keys %$item;
        push @fullPluginList, $name;
        push @pluginList, $name
            if not $item->{$name}{unlisted};
        Mojo::Exception->throw("Duplicated plugin instance $name")
          if exists $pluginMap{$name};
        my $obj = eval { 
            $self->loadAndNewPlugin($item->{$name}{module});
        };
        if ($@){
            warn "Failed to load Plugin $name: $@";
            next;
        }
        $obj->config($item->{$name});
        $obj->name($name);
        $obj->app($self->app);
        $pluginMap{$name} = $obj;
        push @items, {
            type => 'object',
            properties => {
                $name => $obj->schema,
            },
            required => [ $name ],
            additionalProperties => false,
        };
    }

    $schema->{properties}{PLUGIN}{items} = {
        anyOf => \@items
    };

    $schema->{properties}{FRONTEND}{properties}{$_.'_popup'}
        {properties}{plugin}{enum} = \@fullPluginList 
            for qw(registration passwordreset);

    # warn YAML::XS::Dump $schema;
    # second pass with data structures from plugins integrated
    if (my @errors = $self->validator->validate($cfg)){
        Mojo::Exception->throw(join "\n",@errors);
    }

    $cfg->{PLUGIN} = {
        prototype => \%pluginMap,
        list => \@pluginList
    };

    for (qw(registration passwordreset)) {
        if (my $popup = $cfg->{FRONTEND}{$_.'_popup'}){
            my $plugin = delete $popup->{plugin};
            my $obj = $pluginMap{$plugin};
            $cfg->{FRONTEND}{$_.'_popup'} = {
                popupTitle => $obj->config->{'tab-name'},
                name => $plugin,
                %$popup,
            };
        }
    }
    #warn YAML::XS::Dump($cfg->{FRONTEND})
    for my $name (@fullPluginList) {
        $pluginMap{$name}->massageConfig($cfg);
    }

    $cfg->{FRONTEND}{TRANSLATIONS} = $self->getTranslations();
    return $cfg;
}

1;

__DATA__

@@ config-schema.yaml

$id: https://callbackery.org/config-schema.yaml
$schema: http://json-schema.org/draft2019/schema#
definitions:
  plugin:
    type: object
    additionalProperties: false
    required:
      - plugin
    properties:
      plugin:
        type: string
      set:
        type: object

type: object
additionalProperties: false
required:
  - BACKEND
  - FRONTEND
  - PLUGIN
properties:
  BACKEND:
    type: object
    additionalProperties: false
    required:
      - cfg_db
    properties:
      log_file:
        type: string
      cfg_db:
        type: string
      sesame_user:
        type: string
      sesame_pass:
        type: string
  FRONTEND:
    type: object
    additionalProperties: false
    properties:
      logo:
        type: string
        format: uri
        description: url for the logo brand the login screen
      company_name:
        type: string
        description: who created the app
      company_url:
        type: string
        format: uri
        description: link to the company homepage
      max_width:
        type: integer
        description: maximum content width
      company_support:
        type: string
        format: uri
        description: company support eMail
      logo_small:
        description: for the small logo brand the UI
        type: string
        format: uri
      logo_noscale:
        type: boolean
        description: don't scale the login window logo
        default: false
      spinner:
        type: string
        format: uri
        description: url for the busy animation spinner gif
      title:
        type: string
        description: title string for the application
      initial_plugin:
        type: string
        description: which tab should be active upon login ?
      hide_password:
        type: boolean
        description: hide password field on login screen
      hide_password_icon:
        type: boolean
        description: hide password dialog icon
        default: false
      hide_release:
        type: boolean
        description: hide release string on login screen
        default: false
      hide_company:
        type: boolean
        description: hide company string on login screen
        default: false
      registration_popup:
        $ref: "#/definitions/plugin"
      passwordreset_popup:
        $ref: "#/definitions/plugin"

  PLUGIN:
    type: array
    items:
        type: object
        maxProperties: 1
        minProperties: 1
        patternProperty:
            ^\S+$:
                type: object
                required:
                - module
                properties:
                module:
                    type: string
                unlisted:
                    description: do not add this plugin to the plugin list.
                    type: boolean




__END__

=head1 COPYRIGHT

Copyright (c) 2020 by OETIKER+PARTNER AG. All rights reserved.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2020-02-18 to 1.0 first version
 2020-11-20 fz 1.1 call postProcessCfg from CallBackery.pm

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
