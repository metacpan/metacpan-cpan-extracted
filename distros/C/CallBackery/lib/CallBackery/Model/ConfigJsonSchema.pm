# $Id: Config.pm 539 2013-12-09 22:28:11Z oetiker $
package CallBackery::Model::ConfigJsonSchema;

=head1 NAME

CallBackery::ConfigYAML - get parse configuration file for CallBackery

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
use Mojo::JSON qw(false);
use CallBackery::Translate qw(trm);


=head2 cfgHash

a hash containing the data from the config file

=cut

has cfgHash => sub ($self) {
    my $cfg = eval { LoadFile($self->file) };
    if ($@) {
      Mojo::Exception->throw("Loading ".$self->file.": $@");
    }
    if (my @errors = $self->validator->validate($cfg)){
      Mojo::Exception->throw("Validating ".$self->file.":\n".join "\n",@errors);
    }
    $self->postProcessCfg($cfg);
    
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
    my $validator = JSON::Validator->new(version=>7);
    $validator->schema($self->schema);
    return $validator;
}


=head2 postProcessCfg

Post process the configuration data into a format that is easily used
by the application.

=cut

sub postProcessCfg ($self,$cfg) {
    my $schema = $self->schema;
    my @items;
    my %pluginMap;
    for my $item (@{$cfg->{PLUGIN}}) {
        my ($name) = keys %$item;
        Mojo::Exception->throw("Duplicated plugin instance $name")
         if exists $pluginMap{$name};
        my $obj = eval { 
            $self->loadAndNewPlugin($item->{$name}{module});
        };
        $pluginMap{$name} = $obj;
        if ($@){
            warn "Failed to load Plugin $_[0]: $@";
            next;
        }
        push @items, {
            type => 'object',
            properties => {
                $name => $obj->schema,
            },
            required => [ $name ],
            additionalProperties => false,
        }
    }
    
    $schema->{properties}{PLUGIN}{items} = {
        anyOf => \@items
    };
    # second pass with data structures from plugins integrated
    if (my @errors = $self->validator->validate($cfg)){
        Mojo::Exception->throw(join "\n",@errors);
    }
    my @pluginOrder;
    my $PLUGIN = delete $cfg->{PLUGIN};
    $cfg->{PLUGIN}{prototype} = \%pluginMap;
    for my $item (@$PLUGIN) {
        my ($name) = keys %$item;
        push @{$cfg->{PLUGIN}{list}}, $name;
        my $obj = $pluginMap{$name};
        $obj->config($item->{$name});
        $obj->name($name);
        $obj->app($self->app);
        $obj->massageConfig($cfg);
    }
    $cfg->{FRONTEND}{TRANSLATIONS} = $self->getTranslations();
    return $cfg;
}

1;

__DATA__

@@ config-schema.yaml

$id: https://callbackery.org/config-schema.yaml
$schema: http://json-schema.org/draft-07/schema#
type: object
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
        type: number
        format: integer
        description: maximum content width
      company_support:
        type: string
        format: uri
        description: company support eMail
      logo_small:
        description: for the small logo brand the UI
        type: string
        format: uri
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
      hide_release:
        type: boolean
        description: hide release string on login screen
      hide_company:
        type: boolean
        description: hide company string on login screen
    PLUGIN:
      type: array
      items:
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




__END__

=head1 COPYRIGHT

Copyright (c) 2020 by OETIKER+PARTNER AG. All rights reserved.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2020-02-18 to 1.0 first version

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
