# $Id: Config.pm 539 2013-12-09 22:28:11Z oetiker $
package CallBackery::Config;

=head1 NAME

CallBackery::Config - get parse configuration file for CallBackery

=head1 SYNOPSIS

 use Nq::Config;
 my $cfg = CallBackery::Config->new(file=>$file);
 my $hash_ref = $cfg->cfgHash();
 my $pod = $cfg->pod();

=head1 DESCRIPTION

CallBackery gets much of its configuration from this config file.

=cut

use Mojo::Base -base;
use CallBackery::Exception qw(mkerror);
use CallBackery::Translate qw(trm);
use Config::Grammar::Dynamic;
use Carp;
use autodie;
use File::Spec;
use Locale::PO;

=head2 file

the name of the config file

=cut

has file => sub { croak "the file parameter is mandatory" };

has secretFile => sub {
    shift->file.'.secret';
};

has app => sub { croak "the app parameter is mandatory" };

has log => sub {
    shift->app->log;
};

=head2 cfgHash

a hash containing the data from the config file

=cut

has cfgHash => sub {
    my $self = shift;
    my $cfg_file = shift;
    my $parser = $self->makeParser();
    my $cfg = $parser->parse($self->file, {encoding => 'utf8'}) or croak($parser->{err});
    $self->postProcessCfg($cfg);
    return $cfg;
};

=head2 pod

returns a pod documenting the config file

=cut

has pod => sub {
    my $self = shift;
    my $parser = $self->makeParser();
    my $E = '=';
    my $footer = <<"FOOTER";

${E}head1 COPYRIGHT

Copyright (c) 2014 by OETIKER+PARTNER AG. All rights reserved.

${E}head1 AUTHOR

S<Tobias Oetiker E<lt>tobi\@oetiker.chE<gt>>
S<Fritz Zaucker E<lt>fritz.zaucker\@oetiker.chE<gt>>

${E}head1 HISTORY

 2014-01-11 to 1.0 first version
 2014-04-29 fz 1.1 implement plugin path

FOOTER
    my $header = <<"HEADER";
${E}head1 NAME

callbackery.cfg - The Apliance FRONTEND Builder config file

${E}head1 SYNOPSIS

 *** BACKEND ***
 log_file = /tmp/nw-tobi.log

 *** FRONTEND ***
 logo = logo.png
 spinner = myspinner.gif
 logo_small = logo-small.png
 title = Appliance Configurator

${E}head1 DESCRIPTION

The afb.cfg provides all the info for afb and its gui modules to interact with your appliance.

${E}head1 CONFIGURATION

HEADER
    return $header.$parser->makepod().$footer;
};

=head2 pluginPath

array of name spaces to look for gui plugins

=cut

has pluginPath => sub { ['CallBackery::GuiPlugin']; };

=head2 B<loadAndNewPlugin>('PluginModule')

Find the given module in the F<pluginPath>, load it and create a first instance.

=cut


sub loadAndNewPlugin {
    my $self   = shift;
    my $plugin = shift;

    my $pluginPath = $self->pluginPath;
    for my $path (@INC){
        for my $pPath (@$pluginPath) {
            my @pDirs = split /::/, $pPath;
            my $fPath = File::Spec->catdir($path, @pDirs, '*.pm');
            for my $file (glob($fPath)) {
                my ($volume, $modulePath, $moduleName) = File::Spec->splitpath($file);
                $moduleName =~ s{\.pm$}{};
                if ($plugin eq $moduleName) {
                    require $file;
                    no strict 'refs';
                    return "${pPath}::${plugin}"->new();
                }
            }
        }
    }
    die mkerror(123, "Plugin Module $plugin not found");
};

has grammar => sub {
    my $self = shift;
    my $pluginList = {};
    my $pluginPath = $self->pluginPath;
    for my $path (@INC){
        for my $pPath (@$pluginPath) {
            my @pDirs = split /::/, $pPath;
            my $fPath = File::Spec->catdir($path, @pDirs, '*.pm');
            for my $file (glob($fPath)) {
                my ($volume, $modulePath, $moduleName) = File::Spec->splitpath($file);
                $moduleName =~ s{\.pm$}{};
                $pluginList->{$moduleName} = 'Plugin Module';
            }
        }
    }
    return {
        _sections => [ qw(BACKEND FRONTEND FRONTEND-COLORS /PLUGIN:\s*\S+/)],
        _mandatory => [qw(BACKEND FRONTEND)],
        BACKEND => {
            _doc => 'BACKEND Settings',
            _vars => [ qw(log_file cfg_db sesame_user sesame_pass) ],
            _mandatory => [ qw(cfg_db sesame_user sesame_user) ],
            log_file => { _doc => 'write a log file to this location (unless in development mode)'},
            cfg_db => { _doc => 'file to store the config database'},
            sesame_user => { _doc => <<'DOC'},
In Open Sesame mode, one has to use this username to get access to the system.
The password you enter does not matter.
DOC
            sesame_pass => { _doc => <<'DOC'},
Using sesame_user and sesame_pass, the system can always be accessed.
In default configuration sesame_pass is NOT set.
DOC
        },
        FRONTEND => {
            _doc => 'Settings for the Web FRONTEND',
            _vars => [ qw(logo logo_small spinner title initial_plugin company_name company_url company_support
			  hide_password hide_release hide_company max_width
			)
                     ],
            logo => {
                _doc => 'url for the logo brand the login sceen',
            },
            company_name => {
                _doc => 'who created the app',
            },
            company_url => {
                _doc => 'link to the company homepage'
            },
            max_width => {
                _doc => 'maximum content width'
            },
            company_support => {
                _doc => 'company support eMail'
            },
            logo_small => {
                _doc => 'url for the small logo brand the UI',
            },
            spinner => {
                _doc => 'url for the busy animation spinner gif',
            },
            title => {
                _doc => 'title string for the application'
            },
            initial_plugin => {
                _doc => 'which tab should be active upon login ?'
            },
            hide_password => {
	        _doc => 'hide password field on login screen',
	        _re => '(yes|no)',
                _re_error => 'pick yes or no',
            },
            hide_release => {
	        _doc => 'hide release string on login screen',
	        _re => '(yes|no)',
                _re_error => 'pick yes or no',
            },
            hide_company => {
	        _doc => 'hide company string on login screen',
	        _re => '(yes|no)',
                _re_error => 'pick yes or no',
            },
        },
        'FRONTEND-COLORS' => {
            _vars => [ '/[a-zA-Z]\S+/' ],
            '/[a-zA-Z]\S+/' => {
                _doc => <<COLORKEYS_END,
Use this section to override any color key used in the qooxdoo simple theme as well as the following:
C<tabview-page-background>,
C<tabview-page-border>,
C<tabview-button-background>,
C<tabview-button-checked-background>,
C<tabview-button-text>,
C<tabview-button-checked-text>,
C<tabview-button-border>,
C<tabview-button-checked-border>.
C<textfield-readonly>.

The keys can be set to standard web colors C<rrggbb> or to other key names.
COLORKEYS_END
                _example => <<EXAMPLE_END,
ff0000
EXAMPLE_END
                _sub => sub {
                    if ($_[0] =~ /^\s*([0-9a-f]{3,6})\s*$/i){
                        $_[0] = '#'.lc($1);
                    }
                    return undef;
                }
            }
        },
        '/PLUGIN:\s*\S+/' => {
            _order => 1,
            _doc => 'Plugins providing appliance specific funtionality',
            _vars => [qw(module)],
            _mandatory => [qw(module)],
            module => {
                _sub => sub {
                    eval {
                        $_[0] = $self->loadAndNewPlugin($_[0]);
                    };
                    if ($@){
                        return "Failed to load Plugin $_[0]: $@";
                    }
                    return undef;
                },
                _dyn => sub {
                    my $var   = shift;
                    my $module = shift;
                    $module = $self->loadAndNewPlugin($module) if not ref $module;
                    my $tree  = shift;
                    my $grammar = $module->grammar();
                    push @{$grammar->{_vars}}, 'module';
                    for my $key (keys %$grammar){
                        $tree->{$key} = $grammar->{$key};
                    }
                },
                _dyndoc => $pluginList,
            },
        }
    };
};

sub makeParser {
    my $self = shift;
    my $parser =  Config::Grammar::Dynamic->new($self->grammar);
    return $parser;
}

=head2 getTranslations

Load translations from po files

=cut

sub getTranslations {
    my $self = shift;
    my $cfg = shift;
    my %lx;
    my $path = $self->app->home->rel_file("share");
    my $po = new Locale::PO();
    for my $file (glob(File::Spec->catdir($path, '*.po'))) {
        my ($volume, $localePath, $localeName) = File::Spec->splitpath($file);
        my $locale = $localeName;
        $locale =~ s/\.po$//;
        my $lang = $locale;
        $lang =~ s/_.+//;
        local $_; # since load_file_ashash modifies $_ and does not localize it
        my $href = Locale::PO->load_file_ashash($file, 'utf8');
        for my $key (keys %$href) {
            my $o = $href->{$key};
            my $id  = $po->dequote($o->msgid);
            my $str = $po->dequote($o->msgstr);
            next unless $id;
            $lx{$locale}{$id} = $str;
        }
    }
#    use Data::Dumper;
#    warn Dumper "lx=", \%lx;
    return \%lx;
}

=head2 postProcessCfg

Post process the configuration data into a format that is easily used
by the application.

=cut

sub postProcessCfg {
    my $self = shift;
    my $cfg = shift;
    my %plugin;
    my @pluginOrder;
    for my $section (keys %$cfg){
        my $sec = $cfg->{$section};
        next unless ref $sec eq 'HASH'; # skip non hash stuff
        for my $key (keys %$sec){
            next unless ref $sec->{$key} eq 'HASH' and $sec->{$key}{_text};
            $sec->{$key} = $sec->{$key}{_text};
        }
        if ($section =~ /^PLUGIN:\s*(.+)/){
            my $name = $1;
            $pluginOrder[$sec->{_order}] = $name;
            delete $sec->{_order};

            my $obj = $cfg->{PLUGIN}{prototype}{$name} = $sec->{module};
            delete $sec->{module};
            $obj->config($sec);
            $obj->name($name);
            $obj->app($self->app);
            $obj->massageConfig($cfg);
            # cleanup the config
            delete $cfg->{$section};
        }
        $cfg->{PLUGIN}{list} = \@pluginOrder;
    }
    # rename section
    # delete returns the value of the deleted hash element
    if (exists $cfg->{'FRONTEND-COLORS'}) {
        $cfg->{FRONTEND}{COLORS} = $cfg->{'FRONTEND-COLORS'};
        delete $cfg->{'FRONTEND-COLORS'};
    }
    $cfg->{FRONTEND}{TRANSLATIONS} = $self->getTranslations();
    return $cfg;
}

=head2 instantiatePlugin(pluginName,userObj,args)

create a new instance of this plugin prototype

=cut

sub instantiatePlugin {
    my $self = shift;
    my $name = shift;

    my $user = shift;
    my $args = shift;

    my $prototype = $self->cfgHash->{PLUGIN}{prototype}{$name};

    # clean the name
    $name =~ s/[^-_0-9a-z]/_/gi;

    die mkerror(39943,"No prototype for $name")
        if not defined $prototype;

    my $obj = $prototype->new(
        user => $user,
        name => $prototype->name,
        config => $prototype->config,
        args => $args // {},
        app => $self->app,
    );
    die mkerror(39944,"No permission to access $name")
        if not $obj->checkAccess;
    return $obj;
}

=head2 $configBlob = $cfg->getConfigBlob()

return the configuration state of the system as a blob

=cut

has configPlugins => sub {
    my $self = shift;
    my $user = $self->app->userObject->new(app=>$self->app,userId=>'__CONFIG');
    my $cfg = $self->cfgHash;
    my @plugins;
    for my $name (@{$cfg->{PLUGIN}{list}}){
        my $obj = eval {
            $self->instantiatePlugin($name,$user);
        } or next;
        push @plugins, $obj;
    }
    return \@plugins;
};

sub getCrypt {
    require Crypt::Rijndael;
    my $self = shift;
    my $password = substr((shift || '').('x' x 32),0,32);
    return Crypt::Rijndael->new( $password,Crypt::Rijndael::MODE_CBC() );
}

sub pack16 {
    my $self = shift;
    my $string = shift;
    my $len = length($string);
    my $mod = 16 - ($len % 16);
    return sprintf("%016x%s",$len,$string.('x' x $mod));
}

sub unpack16 {
    my $self = shift;
    my $string = shift;
    my $len = substr($string,0,16);
    if ( $len !~ /^[0-9a-f]{16}$/ or hex($len) > length($string)-16 ){
        die mkerror(3844,trm("Wrong password!"));
    }
    return substr($string,16,hex($len));
}

sub getConfigBlob {
    my $self = shift;
    my $password = shift;
    require Archive::Zip;

    my $zip = Archive::Zip->new();
    my $cfg = $self->cfgHash;
    # flush all the changes in the database to the db file
    my $dumpfile = '/tmp/cbdump'.$$;
    unlink $dumpfile if -f $dumpfile;
    open my $dump, '|-','/usr/bin/sqlite3',$cfg->{BACKEND}{cfg_db};
    print $dump ".output $dumpfile\n";
    print $dump ".dump\n";
    close $dump; 
    $zip->addFile({
        filename => $dumpfile,
        zipName => '{DATABASEDUMP}',
    });
    for my $obj (@{$self->configPlugins}){
        my $name = $obj->name;
        for my $file (@{$obj->stateFiles}) {
            if (-r $file){
                $zip->addFile({
                    filename => $file,
                    zipName => '{PLUGINSTATE.'.$name.'}'.$file
                })
            }
        }
    }
    my $zipData;
    open(my $fh, ">", \$zipData);
    $zip->writeToFileHandle($fh,0);

    my $crypt = $self->getCrypt($password);
    return $crypt->encrypt($self->pack16($zipData));
}

=head2 $cfg->restoreConfigBlob(configBlob)

retore the confguration state

=cut

sub restoreConfigBlob {
    my $self = shift;
    my $config = shift;
    my $password = shift;
    require Archive::Zip;
    my $crypt = $self->getCrypt($password);
    $config = $self->unpack16($crypt->decrypt($config));

    my $cfg = $self->cfgHash;
    my $user = $self->app->userObject->new(app=>$self->app,userId=>'__CONFIG');
    open my $fh ,'<', \$config;
    my $zip = Archive::Zip->new();
    $zip->readFromFileHandle($fh);
    my %stateFileCache;
    for my $member ($zip->members){
        for ($member->fileName){
            /^\{DATABASE\}$/ && do {
                $self->log->warn("Restoring Database!");
                unlink glob $cfg->{BACKEND}{cfg_db}.'*';
                $member->extractToFileNamed($cfg->{BACKEND}{cfg_db});
                last;
            };
            /^\{DATABASEDUMP\}$/ && do {
                $self->log->warn("Restoring Database Dump!");
                unlink glob $cfg->{BACKEND}{cfg_db}.'*';
                open my $sqlite, '|-', '/usr/bin/sqlite3',$cfg->{BACKEND}{cfg_db};
                my $sql = $member->contents();
                $sql =~ s/0$//; # for some reason the dump ends in 0
                print $sqlite $sql;
                close $sqlite;
                last;
            };
            m/^\{PLUGINSTATE\.([^.]+)\}(.+)/ && do {
                my $plugin = $1;
                my $file = $2;
                if (not $stateFileCache{$plugin}){
                    my $obj = eval {
                         $self->instantiatePlugin($plugin,$user);
                    };
                    if (not $obj){
                        $self->log->warn("Ignoring $file from plugin $plugin since the plugin is not available here.");
                        next;
                    }
                    $stateFileCache{$plugin} = { map { $_ => 1 } @{$obj->stateFiles} };
                };
                if ($stateFileCache{$plugin}{$file}){
                    $member->extractToFileNamed($file);
                }
                else {
                    $self->log->warn("Ignoring $file from archive since it is not listed in $plugin stateFiles.");
                }
            }
        }
    }
    $self->reConfigure;
}

=head2 $cfg->reConfigure()

Regenerate all the template based configuration files using input from the database.

=cut

sub reConfigure {
    my $self = shift;
    my $secretFile = $self->secretFile;
    if (not -f $secretFile){
        open my $rand, '>', $secretFile;
        chmod 0600,$secretFile;
        print $rand sprintf('%x%x',int(rand()*1e14),int(rand()*1e14));
        close $rand;
        chmod 0400,$secretFile;
    }
    for my $obj (@{$self->configPlugins}){
        $obj->reConfigure;
    }
}

=head2 $cfg->unConfigure()

Restore the system to unconfigured state. By removing the
configuration database, unlinking all user supplied configuration
files and regenerating all template based configuration files with
empty input.

=cut

sub unConfigure {
    no autodie;
    my $self = shift;
    my $cfg = $self->cfgHash;
    $self->log->debug("unlinking config database ".$cfg->{BACKEND}{cfg_db});
    unlink $cfg->{BACKEND}{cfg_db} if -f $cfg->{BACKEND}{cfg_db};
    open my $gen, '>', $cfg->{BACKEND}{cfg_db}.'.flush';
    close $gen;
    #get 'clean' config files
    $self->reConfigure();
    # and now remove all state
    for my $obj (@{$self->configPlugins}){
        for my $file (@{$obj->stateFiles},@{$obj->unConfigureFiles}) {
            next if not -f $file;
            $self->log->debug('['.$obj->name."] unlinking $file");
            unlink $file;
        }
    }
    unlink $cfg->{BACKEND}{log_file} if defined $cfg->{BACKEND}{log_file} and -f $cfg->{BACKEND}{log_file} ;
    unlink $self->secretFile if -f $self->secretFile;
    system "sync";
}


1;

__END__

=head1 COPYRIGHT

Copyright (c) 2014 by OETIKER+PARTNER AG. All rights reserved.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>
S<Fritz  Zaucker E<lt>fritz.zaucker@oetiker.chE<gt>>

=head1 HISTORY

 2014-01-11 to 1.0 first version
 2014-04-29 fz 1.1 implement plugin path

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
