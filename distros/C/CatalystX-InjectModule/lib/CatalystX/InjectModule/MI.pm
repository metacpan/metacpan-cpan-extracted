use utf8;
package CatalystX::InjectModule::MI;
$CatalystX::InjectModule::MI::VERSION = '0.19';
# This plugin is inspired by :
# - CatalystX::InjectComponent
# - Catalyst::Plugin::AutoCRUD
# - Catalyst::Plugin::PluginLoader
# - Catalyst::Plugin::Thruk::ConfigLoader

use Class::Load ':all';
use Data::Clone 'clone';
use File::Find;
use File::Basename qw( dirname );
use File::Path qw( make_path );
use Dependency::Resolver;
use Moose;
use Moose::Util qw/find_meta apply_all_roles/;
use Catalyst::Utils;
use YAML qw(Dump DumpFile LoadFile);
use Term::ANSIColor qw(:constants);
use Path::Tiny;
use Path::Class qw( file );

has debug => (
              is       => 'rw',
              isa      => 'Int',
          );

has regex_conf_name => (
              is       => 'rw',
              isa      => 'Str',
              default  => sub { '^cxim_config.yml$'},
          );

has resolver => (
              is       => 'rw',
              isa      => 'Dependency::Resolver',
          );

has ctx => (
              is       => 'rw',
          );

has catalyst_plugins => (
              is       => 'rw',
              isa      => 'HashRef',
              default  => sub { {} },
          );

has modules_loaded => (
              is       => 'rw',
              isa      => 'ArrayRef',
              default  => sub { [] },
          );

has modules_injected => (
              is       => 'rw',
              isa      => 'HashRef',
              default  => sub { {} },
          );

has _view_files => (
              is       => 'rw',
              isa      => 'ArrayRef',
              default  => sub { [] },
          );

has _static_dirs => (
              is       => 'rw',
              isa      => 'ArrayRef',
              default  => sub { [] },
          );

has libs => (
             is       => 'rw',
             isa      => 'ArrayRef',
             default  => sub { [] },
            );

has packlists => (
             is       => 'rw',
             isa      => 'HashRef',
                  default  => sub { {} },
                 );


sub log {
    my($self, $msg, $level) = @_;

    $level = 1 if ! $level;
    if ( $self->debug > 1){
        my $caller = ( caller(1) )[3];
        $msg = YELLOW.BOLD.$caller.CLEAR.' '.$msg;
    }

    $self->ctx->log->debug( YELLOW."MI".CLEAR.": $msg" ) if ( $self->debug >= $level );
}

sub get_module {
    my($self, $mod, $op , $ver) = @_;

    my $modules = $self->resolver->get_modules($mod, $op, $ver);
    return $modules->[-1];
}

sub resolv {
    my $self      = shift;
    my $module    = shift;
    my $operation = shift;
    my $version   = shift;

    next if ! $module;
    my $Module   = $self->get_module($module, $operation, $version );
    die "Module $module not found !" if ! defined $Module->{name};

    my $resolved = $self->resolver->dep_resolv($Module);

    return $resolved;
}


sub load {
    my $self           = shift;
    my $conf           = shift;
    my $conf_filename  = shift;

    $self->debug($conf->{debug}||0);
    $conf_filename ||= $self->regex_conf_name;
    $self->log("load_modules ...");

    $self->resolver(Dependency::Resolver->new(debug => $self->debug ));

    # By default search also in INC
    my $search_localy_only = 0;

    # search modules in 'path' directories
    for my $dir ( @{ $conf->{path} } ) {
        if ( $dir eq '__NO_INC__' ) {
            $search_localy_only = 1;
            next;
        }
        $self->_load_modules_path($dir, $conf_filename);
    }

    # Search modules in @INC
    if ( ! $search_localy_only ){
        for my $dir ( @INC ) {
            next if ( $dir eq '.');
            $self->_load_modules_path($dir, $conf_filename, 1);
            $self->_add_packlists($dir);
        }
    }

    # Merge config resolved modules ----------------
    $self->_merge_resolved_configs;

    $self->_build_local_config_file;
}



sub modules_to_inject {
    my $self    = shift;
    my $modules_name = shift;

    my $modules = [];
    foreach my $m ( @$modules_name ) {
        my $resolved = $self->resolv($m);

        foreach my $M ( @$resolved ) {
            push(@$modules,$M);
        }
    }
    return $modules;
}

sub inject {
    my $self         = shift;
    my $modules_name = shift;

    foreach my $m (@$modules_name){
        $self->modules_injected->{$m} = 1;
    }
    my $modules = $self->modules_to_inject($modules_name);

    $self->_add_to_modules_loaded($modules);

    for my $m ( @$modules) {
        $self->_inject($m);
    }
}

sub _add_packlists{
    my $self = shift;
    my $dir  = shift;

    my @packlists = @{$self->_search_in_path($dir, '\.packlist')};
    foreach my $pl (@packlists){
        my $module = $pl;
        $module =~ s/\.packlist$//;
        $module =~ s|.*/auto/||;
        $module =~ s|/$||;
        $module =~ s|/|::|g;

        $self->packlists->{$module} = $pl;
    }
}


sub module_files {
    my $self   = shift;
    my $module = shift;

    my $packlist = $self->packlists->{$module};

    open(F, $packlist) or die "Can not open $packlist for $module module\n";
    my (@packlist_files);

    foreach my $file (<F>) {
        chomp($file);
        push(@packlist_files, $file)
    }
    close F;
    return (@packlist_files);
}

sub _add_to_modules_loaded {
    my $self    = shift;
    my $modules = shift;

    # remove dumplicate modules
    my $all = {};
    foreach my $m ( @$modules ) {
        next if ( $all->{$m->{name}} );
        
        push(@{$self->modules_loaded},$m);
        $all->{$m->{name}} = 1;
    }
}

sub _del_persist_file {
    my $self   = shift;
    my $module = shift;

    my $persist_f = $self->_persist_file_name($module);
    unlink $persist_f or die "Can not delete file $persist_f : $!";
}

sub _load_modules_path{
    my $self           = shift;
    my $dir            = shift;
    my $conf_filename  = shift;
    my $from_inc       = shift;
    $self->log("  - search modules in $dir ...");

    my $all_configs = $self->_search_in_path( $dir, "^$conf_filename\$" );
  CONFIG: for my $config ( @$all_configs ) {
        my $cfg = Config::Any->load_files({files => [$config], use_ext => 1 })
          or die "Error (conf: $config) : $!\n";

        my($filename, $mod_config) = %{$cfg->[0]};

        my $path = dirname($config);
        $path =~ s|^\./||;

        # next if module already added ( ex: path=share + share/modules)
        for my $m ( @{$self->resolver->modules->{$mod_config->{name}}} ) {
            if ( $path eq $m->{path}) {
                next CONFIG;
            }
            ;

            die "The module should not be named with Model|View|Controller|TraitFor" if ( grep {/\/Model\/|\/View\/|\/Controller\//} $mod_config->{name} );

        }

        my $msg = "    - find module ". $mod_config->{name};
        $msg .= " v". $mod_config->{version} if defined $mod_config->{version};
        $msg .= " from INC"  if $from_inc;
        $self->log($msg);

        # cxim_config is in share/
        $path =~ s|/?share$||;
        $mod_config->{path} = $path;

        my $all_libs = [];
        # use module localy
        if ( -d $mod_config->{path} . '/lib') {
            $mod_config->{libpath} = $mod_config->{path} . '/lib';
            $all_libs = $self->_search_in_path( $mod_config->{libpath}, '.pm$' );
        }
        # or from installed packages
        elsif ( -d $mod_config->{path} ) {
            my $module_file = $mod_config->{name};
            $module_file =~ s|::|/|g;
            $module_file .= ".pm";

            # Rechercher dans le packlist du module le fichier $module_file
            my @all_module_files = $self->module_files($mod_config->{name});

            foreach my $f ( @all_module_files ) {
                push(@$all_libs,$f) if ( $f =~ /\.pm$/ ); 
                if ( $f =~ s/$module_file$// ) {
                    $mod_config->{libpath} = $f;
                }
            }
            die "The $module_file file of the " . $mod_config->{name} . " module is non found !\n"
              if ( ! $mod_config->{libpath} );
        }
        else {
            return;
        }

        $mod_config->{config}->{all_libs} = $all_libs;

        $self->resolver->add($mod_config);
    }
}

sub _inject {
    my $self   = shift;
    my $module = shift;

    
    $self->log(RED."InjectModule " . $module->{name}.CLEAR);

    # Inject lib and components ----------
    $self->_load_lib($module);

    # Inject catalyse plugin dependencies
    $self->_load_catalyst_plugins($module);

    # Inject templates -------------------
    $self->_load_template($module);

    # Inject static ----------------------
    $self->_load_static($module);

}


sub _merge_resolved_configs {
    my ( $self, $module ) = @_;

    $self->log("  - Merge all resolved modules config (" . $self->regex_conf_name . ')');

    my $conf = $self->ctx->config->{'CatalystX::InjectModule'};
    my $modules = $self->modules_to_inject($conf->{inject});

    for my $module (@$modules) {
        my $mod_conf = clone($module);

        # Merge all keys except these
        map { delete $mod_conf->{$_} } qw /name version deps catalyst_plugins dbix_fixtures /;

        $self->ctx->config( Catalyst::Utils::merge_hashes( $mod_conf, $self->ctx->config ) );
    }
}

sub _build_local_config_file{
    my $self  = shift;

    my ($local_file) = grep $_ =~ /local\.yml/, $self->ctx->find_files;
    my $conf_path   = file( File::Spec->rel2abs($local_file) );
    my $config_file = path($conf_path->relative);

    # Generates the local configuration file if it doesnot exist
    if ( ! -e $local_file ) {
        my $conf = $self->ctx->config;
        $config_file->spew_utf8( Dump($conf) )
    } else {
    # Merge loaded conf with local conf
        my $newconf = LoadFile($config_file);
        $self->ctx->config( Catalyst::Utils::merge_hashes( $newconf, $self->ctx->config ) );
        $config_file->spew_utf8( Dump(Catalyst::Utils::merge_hashes( $newconf, $self->ctx->config) ));
    }
}
sub _load_lib {
    my ( $self, $module ) = @_;

    my $all_libs = $module->{config}->{all_libs};

    # Use same libpath
    unshift( @INC, $module->{libpath} );

    $self->log(BLUE."  - Add lib "  . $module->{libpath} . CLEAR);
    $self->libs(\@INC);

    foreach my $file (@$all_libs) {

        next if grep {/TraitFor/} $file;

        my $app_name = $self->ctx->config->{name};
        die "A file of the module " . $module->{name} ." contains the name of the application ($app_name), which is to be avoided otherwise the components can be loaded without this being desired\nfile: $file\n"
          if ( grep {/$app_name\/Model\/|$app_name\/View\/|$app_name\/Controller\//} $file );

        $self->_load_component( $module, $file )
          if ( grep {/\/Model\/|\/View\/|\/Controller\//} $file );

        push(@{$self->_view_files}, $file)
          if ( grep {/\/View\/\w*\.pm/} $file );
    }
}

sub install_module {
    my $self   = shift;
    my $module = shift;

    my $module_name = $module->{name};
    my $module_path = $module_name;

    $module_path =~ s|::|/|g;

    if ( $self->_is_installed($module) ) {
        $self->log("  - $module_name already installed", 2);
        return;
    }

    my $module_libpath = $module->{libpath};
    my $module_file    = $module_libpath . '/' . $module_path . '.pm';
    if ( -f $module_file ) {
        load_class($module_name);
        my $mod = $module_name->new( mi => $self);
        if ( $mod->can('install') ) {
            $self->log("Install $module_name $module_file...");
            $mod->install($module, $self);
            $self->_add_persist_file($module);
        }
    }
}

sub uninstall_module {
    my $self   = shift;
    my $module = shift;

    my $module_name = $module->{name};
    my $module_path = $module_name;
    $module_path =~ s|::|/|g;

    if ( ! $self->_is_installed($module) ) {
        $self->log("  - $module_name is not installed");
        return;
    }

    my $module_libpath = $module->{libpath};
    my $module_file = $module_libpath . '/' . $module_path . '.pm';

    if ( -f $module_file ) {
        load_class($module_name);
        my $mod = $module_name->new(mi => $self);
        if ( $mod->can('uninstall') ) {
            $self->log("  - UnInstall $module_name $module_file...");
            $mod->uninstall($module, $self);
        }
        $self->_del_persist_file($module);
    }
}

sub _is_installed {
    my $self   = shift;
    my $module = shift;

    return 1 if ( -e $self->_persist_file_name($module) );
    return 0;
}

sub _add_persist_file {
    my $self   = shift;
    my $module = shift;

    my $persist_f = $self->_persist_file_name($module);
    DumpFile($persist_f, $module)
        or die "Can not create file $persist_f : $!";
}


sub _persist_file_name {
    my $self   = shift;
    my $module = shift;

    my $conf = $self->ctx->config->{'CatalystX::InjectModule'};

    my $persist_d = $conf->{persistent_dir} || 'var';

    make_path($persist_d) if ! -d $persist_d;

    my $persist_f = $persist_d . '/' . $module->{name} .  '.yml';
    $persist_f =~ s|//|/|g;
    return $persist_f;
}

sub _load_catalyst_plugins {
    my ( $self, $module ) = @_;

    my $plugins = $module->{catalyst_plugins};
    foreach my $p (@$plugins) {

        # If plugin is not already loaded
        if ( !$self->catalyst_plugins->{$p} ) {
            $self->_load_catalyst_plugin($p);
            $self->catalyst_plugins->{$p} = 1;
        } else {
            $self->log(" - Catalyst plugin $p already loaded !", 2);
        }
    }
}

sub _load_catalyst_plugin {
    my ( $self, $plugin ) = @_;

    $self->log("  - Add Catalyst plugin $plugin\n");

    my $isa = do { no strict 'refs'; \@{ $self->ctx . '::ISA' } };
    my $isa_idx = 0;
    $isa_idx++ while $isa->[$isa_idx] ne 'Catalyst'; #__PACKAGE__;


    if ( $plugin !~ s/^\+(.*)/$1/ ) {
        $plugin = 'Catalyst::Plugin::' . $plugin;
    }

    Catalyst::Utils::ensure_class_loaded($plugin);
    $self->ctx->_plugins->{$plugin} = 1;

    my $meta = find_meta($plugin);

    if ( $meta && blessed $meta && $meta->isa('Moose::Meta::Role') ) {
        apply_all_roles( $self->ctx => $plugin );
    } else {
        splice @$isa, ++$isa_idx, 0, $plugin;
    }

    unshift @$isa, shift @$isa; # necessary to tell perl that @ISA changed
    mro::invalidate_all_method_caches();

    {

        # ->next::method won't work anymore, we have to do it ourselves
        my @precedence_list = $self->ctx->meta->class_precedence_list;

        1 while shift @precedence_list ne 'Catalyst'; #__PACKAGE__;

        my $old_next_method = \&maybe::next::method;

        my $next_method = sub {
            if ( ( caller(1) )[3] !~ /::setup\z/ ) {
                goto &$old_next_method;
            }

            my $code;
            while ( my $next_class = shift @precedence_list ) {
                $code = $next_class->can('setup');
                last if $code;
            }
            return unless $code;

            goto &$code;
        };

        no warnings 'redefine';
        local *next::method        = $next_method;
        local *maybe::next::method = $next_method;

        return $self->ctx->next::method(@_);
    }
}


sub _load_template {
    my ( $self, $module ) = @_;

    foreach my $dir ( 'share/root/src', 'share/root/lib', 'root/src', 'root/lib') {

        my $template_dir = $module->{path} . "/$dir";
        if ( -d $template_dir ) {
            $self->log("  - Add template directory $template_dir");
            $module->{template_dir} = $template_dir;
            # Add template to TT view
            # TODO: Add template to others view ?
            push( @{ $self->ctx->view('TT')->config->{INCLUDE_PATH} }, $template_dir );
        }
    }
}


sub _load_static {
    my ( $self, $module ) = @_;
    
    my $static_dir = $module->{path} . "/root/static";

    foreach my $static_dir ( $module->{path} . "/share/root/static", $module->{path} . "/root/static" ) {

        if ( -d $static_dir ) {
            $self->log("  - Add static directory");
            $module->{static_dir} = $static_dir;
            push(@{$self->_static_dirs}, $static_dir);
        }
    }
}

sub _load_component {
    my ( $self, $module, $file ) = @_;
         
    my $libpath = $module->{libpath};
    my $comp    = $file;
    $comp =~ s|$libpath/?||;
    $comp =~ s|\.pm$||;
    $comp =~ s|/|::|g;
         
    my $into = $self->ctx;
    my $as  = $comp;
    $as =~ s/.*(Model|View|Controller):://;
    $self->log("  - Add Component into: $into comp:$comp as:$as");
         
    Catalyst::Utils::inject_component( into => $into,
                                       component => $comp,
                                       as => $as );
}

sub _search_in_path {
    my $self  = shift;
    my $path  = shift;
    my $regex = shift;

    my @files;
    my $tf_finder = sub {
        return if !-f;
        return if !/$regex/;

        my $file = $File::Find::name;
        push @files, $file;
    };

    find( $tf_finder, $path  );
    return \@files;
}


=head1 NAME

CatalystX::InjectModule::MI Catalyst Module injector

=head1 VERSION

version 0.19

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 resolv

=head2 get_module

=head2 module_files

=head2 load

=head2 inject

=head2 log

=head2 modules_to_inject

=head2 install_module

=head2 uninstall_module



=head1 AUTHOR

Daniel Brosseau, C<< <dabd at catapulse.org> >>

=cut

      1;
