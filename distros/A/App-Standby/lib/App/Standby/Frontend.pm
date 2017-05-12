package App::Standby::Frontend;
$App::Standby::Frontend::VERSION = '0.04';
BEGIN {
  $App::Standby::Frontend::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Plack based web frontend for App::Standby

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

use Template;
use Try::Tiny;
use List::Util ();
use Module::Pluggable;

use Plack::Request;
use File::ShareDir;

use Config::Yak;
use Log::Tree;

use App::Standby::DB;
use App::Standby::Group;

# extends ...
extends 'App::Standby';
# has ...
has 'dbh' => (
    'is'      => 'ro',
    'isa'     => 'App::Standby::DB',
    'lazy'    => 1,
    'builder' => '_init_dbh',
);

has 'config' => (
    'is'      => 'ro',
    'isa'     => 'Config::Yak',
    'lazy'    => 1,
    'builder' => '_init_config',
);

has 'logger' => (
    'is'      => 'ro',
    'isa'     => 'Log::Tree',
    'lazy'    => 1,
    'builder' => '_init_logger',
);

has 'tt' => (
    'is'      => 'ro',
    'isa'     => 'Template',
    'lazy'    => 1,
    'builder' => '_init_tt',
);

has 'finder' => (
    'is'        => 'rw',
    'isa'       => 'Module::Pluggable::Object',
    'lazy'      => 1,
    'builder'   => '_init_finder',
);

has 'services' => (
    'is'    => 'rw',
    'isa'   => 'ArrayRef[Str]',
    'lazy'  => 1,
    'builder' => '_init_services',
);
# with ...
# initializers ...
sub _init_dbh {
    my $self = shift;

    my $DBH = App::Standby::DB::->new({
        'config'        => $self->config(),
        'logger'        => $self->logger(),
    });

    return $DBH;
}

sub _init_config {
    my $self = shift;

    my $Config = Config::Yak::->new({
        'locations'     => [qw(conf/standby-mgm.conf /etc/standby-mgm)],
    });

    return $Config;
}

sub _init_logger {
    my $self = shift;

    my $Logger = Log::Tree::->new('standby-mgm');

    return $Logger;
}

sub _init_tt {
    my $self = shift;

    my $dist_dir;
    try {
        $dist_dir = File::ShareDir::dist_dir('App-Standby');
    };
    my @inc = ( 'share/tpl', '../share/tpl', );
    if($dist_dir && -d $dist_dir) {
        push(@inc, $dist_dir.'/tpl');
    }
    my $cfg_dir = $self->config()->get('App::Standby::Frontend::TemplatePath');
    if($cfg_dir && -d $cfg_dir) {
        unshift(@inc,$cfg_dir);
    }

    my $tpl_config = {
        INCLUDE_PATH => [ @inc ],
        POST_CHOMP   => 1,
        FILTERS      => {
            'currency' => sub { sprintf( '%0.2f', @_ ) },
            'substr'   => [
                sub {
                    my ( $context, $len ) = @_;

                    return sub {
                        my $str = shift;
                        if ($len) {
                            $str = substr $str, 0, $len;
                        }
                        return $str;
                      }
                },
                1,
            ],

            # dynamic filter factory, see TT manpage
            'highlight' => [
                sub {
                    my ( $context, $search ) = @_;

                    return sub {
                        my $str = shift;
                        if ($search) {
                            $str =~ s/($search)/<span style='background-color: lightgreen'>$1<\/span>/g;
                        }
                        return $str;
                      }
                },
                1,
            ],
            'ucfirst'       => sub { my $str = shift; return ucfirst($str); },
            # A localization filter. Turn the english text into the localized counterpart using Locale::Maketext
            'l10n' => [
                sub {
                    my ( $context, @args ) = @_;

                    return sub {
                        my $str = shift;

                        if(@args) {
                            foreach my $i (0 .. $#args) {
                                my $n = $i+1;
                                my $r = $args[$i];
                                $str =~ s/\[_$n\]/$r/;
                            }
                        }

                        return $str;
                      }
                },
                1,
            ],
        },
    };
    my $TT = Template::->new($tpl_config);

    return $TT;
}

sub _init_finder {
    my $self = shift;

    # The finder is the class that finds our available services
    my $Finder = Module::Pluggable::Object::->new('search_path' => 'App::Standby::Service');

    return $Finder;
}

sub _init_services {
    my $self = shift;

    return [$self->finder()->plugins()];
}

sub _log_request {
    my $self = shift;
    my $request_ref = shift;

    my $remote_addr = $request_ref->{'remote_addr'};
    # turn key => value pairs into smth. like key1=value1,key2=value2,...
    my $args = join(',', map { $_.'='.$request_ref->{$_} } keys %{$request_ref});

    $self->logger()->log( message => 'New Request from '.$remote_addr.'. Args: '.$args, level => 'debug', );

    return 1;
}

sub _verify_group_key {
    my $self = shift;
    my $request = shift;

    my $sql = 'SELECT COUNT(*) FROM groups WHERE id = ? AND key = ?';
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare SQL '.$sql.' w/ error: '.$self->dbh()->errstr, level => 'error', );
        return;
    }
    if(!$sth->execute($request->{'group_id'},$request->{'group_key'})) {
        $self->logger()->log( message => 'Failed to execute stmt w/ error: '.$sth->errstr, level => 'error', );
        return;
    }
    my $cnt = $sth->fetchrow_array();
    if($cnt > 0) {
        # key valid
        return 1;
    } else {
        # key invalid
        return;
    }
}

sub _filter_params {
    my $self = shift;
    my $request = shift;

    my $params = $request->parameters();

    my $request_ref = {};
    foreach my $key (qw(
            janitor group_id rm config_id name
            cellphone key value group_key gs_id desc class new_group_key
            cconfig_id contact_id
            )) {
        if (defined($params->{$key})) {
            $request_ref->{$key} = $params->{$key};
        }
    }

    # set default value for group_id
    if(!defined($request_ref->{'group_id'})) {
        $request_ref->{'group_id'} = 1;
    }

    # add the remote_addr
    $request_ref->{'remote_addr'} = $request->address();

    # add the path
    $request_ref->{'path'} = $request->path_info;

    return $request_ref;
}


sub groups {
    my $self = shift;

    # intatiate the apt class and call update
    # the method returns the new user ordering, set this to the DB
    my $sql = 'SELECT id,name FROM groups';
    my $sth = $self->dbh()->prepare($sql);

    $sth->execute();
    my %groups = ();
    while(my ($id,$name) = $sth->fetchrow_array()) {
        my $grp = try {
            my $Group = App::Standby::Group::->new({
                'group_id' => $id,
                'name' => $name,
                'dbh' => $self->dbh(),
                'logger' => $self->logger(),
            });
            $groups{$id} = $Group;
        } catch {
            $self->logger()->log( message => 'Failed to instantiate the new class due to an error: '.$_, level => 'warning', );
        };
    }

    return \%groups;
}

sub _get_group_array {
    my $self = shift;

    my @garr;

    foreach my $id (sort keys %{$self->groups()}) {
        my $name = $self->groups()->{$id}->name();
        push(@garr, { 'id' => $id, 'name' => $name, });
    }

    return \@garr;
}

sub _get_contacts_array {
    my $self = shift;
    my $group_id = shift;

    # Contacts
    my @args = ();
    my $sql = 'SELECT id,name,cellphone,is_enabled FROM contacts WHERE 1 ';
    if(defined($group_id)) {
        $sql .= 'AND group_id = ? ';
        push(@args,$group_id);
    }
    $sql .= 'ORDER BY name';
    $self->logger()->log( message => 'SQL: '.$sql.' - Args: '.join(",",@args), level => 'debug', );
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute(@args);
    my @users = ();
    while(my ($id,$name,$cellphone,$is_enabled) = $sth->fetchrow_array()) {
        push(@users,{
            'id' => $id,
            'name' => $name,
            'cellphone' => $cellphone,
            'is_enabled' => $is_enabled,
        });
    }
    $sth->finish();

    return \@users;
}

sub _get_service_classes {
    my $self = shift;
    my @classes;

    foreach my $svc (@{$self->services()}) {
        my $class = $svc;
        $class =~ s/^App::Standby::Service:://;
        push(@classes,$class);
    }
    return \@classes;
}


sub run {
    my $self = shift;
    my $env = shift;

    my $plack_request = Plack::Request::->new($env);
    my $request = $self->_filter_params($plack_request);

    # log request and ip
    $self->_log_request($request);

    # The following ugly if-else chain dispatches the request
    # to the appropriate sub.
    # It's ugly but much less painfull than any of the existing
    # web frameworks.

    ## no critic (ProhibitCascadingIfElse)
    if ( !$request->{'rm'} || $request->{'rm'} eq 'overview' ) {
        return $self->_render_overview($request);
    }
    #
    # Janitor
    #
    elsif ( $request->{'rm'} eq 'update_janitor' && $request->{'janitor'} ) {
        return $self->_render_update_janitor($request);
    }
    #
    # Contacts
    #
    elsif ( $request->{'rm'} eq 'list_contacts' && $request->{'group_id'} ) {
        return $self->_render_list_contacts($request);
    }
    elsif ( $request->{'rm'} eq 'add_contact' && $request->{'group_id'} ) {
        return $self->_render_add_contact($request);
    }
    elsif ( $request->{'rm'} eq 'insert_contact' && $request->{'group_id'} ) {
        return $self->_render_insert_contact($request);
    }
    elsif ( $request->{'rm'} eq 'edit_contact' && $request->{'contact_id'} ) {
        return $self->_render_edit_contact($request);
    }
    elsif ( $request->{'rm'} eq 'update_contact' && $request->{'contact_id'} ) {
        return $self->_render_update_contact($request);
    }
    elsif ( $request->{'rm'} eq 'delete_contact_ask' && $request->{'contact_id'} ) {
        return $self->_render_delete_contact_ask($request);
    }
    elsif ( $request->{'rm'} eq 'delete_contact' && $request->{'contact_id'} ) {
        return $self->_render_delete_contact($request);
    }
    elsif ( $request->{'rm'} eq 'enable_contact_ask' && $request->{'contact_id'} ) {
        return $self->_render_enable_contact_ask($request);
    }
    elsif ( $request->{'rm'} eq 'enable_contact' && $request->{'contact_id'} ) {
        return $self->_render_enable_contact($request);
    }
    elsif ( $request->{'rm'} eq 'disable_contact_ask' && $request->{'contact_id'} ) {
        return $self->_render_disable_contact_ask($request);
    }
    elsif ( $request->{'rm'} eq 'disable_contact' && $request->{'contact_id'} ) {
        return $self->_render_disable_contact($request);
    }
    #
    # Config
    #
    elsif ( $request->{'rm'} eq 'list_config' && $request->{'group_id'}) {
        return $self->_render_list_config($request);
    }
    elsif ( $request->{'rm'} eq 'add_config' && $request->{'group_id'} ) {
        return $self->_render_add_config($request);
    }
    elsif ( $request->{'rm'} eq 'insert_config' && $request->{'group_id'} ) {
        return $self->_render_insert_config($request);
    }
    elsif ( $request->{'rm'} eq 'edit_config' && $request->{'config_id'} ) {
        return $self->_render_edit_config($request);
    }
    elsif ( $request->{'rm'} eq 'update_config' && $request->{'config_id'} ) {
        return $self->_render_update_config($request);
    }
    elsif ( $request->{'rm'} eq 'delete_config_ask' && $request->{'config_id'} ) {
        return $self->_render_delete_config_ask($request);
    }
    elsif ( $request->{'rm'} eq 'delete_config' && $request->{'config_id'} ) {
        return $self->_render_delete_config($request);
    }
    #
    # Config_contacts
    #
    elsif ( $request->{'rm'} eq 'list_config_contacts' && $request->{'contact_id'}) {
        return $self->_render_list_config_contacts($request);
    }
    elsif ( $request->{'rm'} eq 'add_config_contacts' && $request->{'contact_id'} ) {
        return $self->_render_add_config_contacts($request);
    }
    elsif ( $request->{'rm'} eq 'insert_config_contacts' && $request->{'contact_id'} ) {
        return $self->_render_insert_config_contacts($request);
    }
    elsif ( $request->{'rm'} eq 'edit_config_contacts' && $request->{'cconfig_id'} ) {
        return $self->_render_edit_config_contacts($request);
    }
    elsif ( $request->{'rm'} eq 'update_config_contacts' && $request->{'cconfig_id'} ) {
        return $self->_render_update_config_contacts($request);
    }
    elsif ( $request->{'rm'} eq 'delete_config_contacts_ask' && $request->{'cconfig_id'} ) {
        return $self->_render_delete_config_contacts_ask($request);
    }
    elsif ( $request->{'rm'} eq 'delete_config_contacts' && $request->{'cconfig_id'} ) {
        return $self->_render_delete_config_contacts($request);
    }
    #
    # Services
    #
    elsif ( $request->{'rm'} eq 'list_services' && $request->{'group_id'} ) {
        return $self->_render_list_services($request);
    }
    elsif ( $request->{'rm'} eq 'add_service' && $request->{'group_id'} ) {
        return $self->_render_add_service($request);
    }
    elsif ( $request->{'rm'} eq 'insert_service' && $request->{'group_id'} ) {
        return $self->_render_insert_service($request);
    }
    elsif ( $request->{'rm'} eq 'edit_service' && $request->{'gs_id'} ) {
        return $self->_render_edit_service($request);
    }
    elsif ( $request->{'rm'} eq 'update_group_service' && $request->{'gs_id'} ) {
        return $self->_render_update_service($request);
    }
    elsif ( $request->{'rm'} eq 'delete_group_service_ask' && $request->{'gs_id'} ) {
        return $self->_render_delete_service_ask($request);
    }
    elsif ( $request->{'rm'} eq 'delete_group_service' && $request->{'gs_id'} ) {
        return $self->_render_delete_service($request);
    }
    #
    # Groups
    #
    elsif ( $request->{'rm'} eq 'list_groups' ) {
        return $self->_render_list_groups($request);
    }
    elsif ( $request->{'rm'} eq 'add_group' ) {
        return $self->_render_add_group($request);
    }
    elsif ( $request->{'rm'} eq 'insert_group' && $request->{'name'} ) {
        return $self->_render_insert_group($request);
    }
    elsif ( $request->{'rm'} eq 'edit_group' && $request->{'group_id'} ) {
        return $self->_render_edit_group($request);
    }
    elsif ( $request->{'rm'} eq 'update_group' && $request->{'group_id'} ) {
        return $self->_render_update_group($request);
    }
    elsif ( $request->{'rm'} eq 'delete_group_ask' && $request->{'group_id'} ) {
        return $self->_render_delete_group_ask($request);
    }
    elsif ( $request->{'rm'} eq 'delete_group' && $request->{'group_id'} ) {
        return $self->_render_delete_group($request);
    }
    #
    # Error-Handler
    #
    else {
        return $self->_render_show_error();
    }
    ## use critic
}

sub _render_list_groups {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'list_groups.tpl',
        {
            'groups' => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_add_group {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'add_group.tpl',
        {
            'groups' => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_insert_group {
    my $self = shift;
    my $request = shift;

    my $sql = 'INSERT INTO groups (`name`,`key`) VALUES(?,?)';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'name'},$request->{'key'});
    my $group_id = $self->dbh()->last_insert_id(undef, undef, undef, undef);

    return [ 301, [ 'Location', '?rm=overview&group_id='.$group_id ], [] ];
}

sub _render_edit_group {
    my $self = shift;
    my $request = shift;

    my $sql = 'SELECT `id`,`name` FROM groups WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'group_id'});
    my ($id,$name) = $sth->fetchrow_array();

    my $body;
    $self->tt()->process(
        'edit_group.tpl',
        {
            'name'      => $name,
            'group_id'  => $request->{'group_id'},
            'groups' => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_update_group {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'UPDATE groups SET `name` = ?, `key` = ? WHERE id = ?';

    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare SQL '.$sql.' w/ error: '.$self->dbh()->errstr, level => 'error', );
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
    }
    if(!$sth->execute($request->{'name'},$request->{'new_group_key'},$request->{'group_id'})) {
        $self->logger()->log( message => 'Failed to execute stmt w/ error: '.$sth->errstr, level => 'error', );
    }

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

sub _render_delete_group_ask {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'delete_group_ask.tpl',
        {
            'group_id' => $request->{'group_id'},
            'groups' => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_delete_group {
    my $self = shift;
    my $request = shift;

    return unless $request->{'group_id'};

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'DELETE FROM groups WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare SQL '.$sql.' w/ error: '.$self->dbh()->errstr, level => 'error', );
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
    }
    if(!$sth->execute($request->{'group_id'})) {
        $self->logger()->log( message => 'Failed to execute stmt w/ error: '.$sth->errstr, level => 'error', );
    }
    $sth->finish();

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

sub _render_list_services {
    my $self = shift;
    my $request = shift;

    # Group Services
    my $sql = 'SELECT id,name,desc,class FROM group_services WHERE group_id = ? ORDER BY name';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'group_id'});
    my @gs = ();
    while(my ($id,$name,$desc,$class) = $sth->fetchrow_array()) {
        push(@gs, {
            'id'        => $id,
            'name'      => $name,
            'desc'      => $desc,
            'class'     => 'App::Standby::Service::'.$class,
        });
    }
    $sth->finish();

    my $body;
    $self->tt()->process(
        'list_services.tpl',
        {
            'group_id' => $request->{'group_id'},
            'gs' => \@gs,
            'groups' => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_add_service {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'add_service.tpl',
        {
            'group_id' => $request->{'group_id'},
            'groups' => $self->_get_group_array(),
            'services' => $self->_get_service_classes(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_insert_service {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'INSERT INTO group_services (`group_id`,`name`,`desc`,`class`) VALUES(?,?,?,?)';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'group_id'},$request->{'name'},$request->{'desc'},$request->{'class'});

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

sub _render_edit_service {
    my $self = shift;
    my $request = shift;

    my $sql = 'SELECT `id`,`name`,`desc`,`class` FROM group_services WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'gs_id'});
    my ($id,$name,$desc,$class) = $sth->fetchrow_array();

    my $body;
    $self->tt()->process(
        'edit_service.tpl',
        {
            'gs_id'     => $request->{'gs_id'},
            'name'      => $name,
            'desc'      => $desc,
            'class'     => $class,
            'group_id'  => $request->{'group_id'},
            'groups' => $self->_get_group_array(),
            'services' => $self->_get_service_classes(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_update_service {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'UPDATE group_services SET `name` = ?, `desc` = ?, `class` = ? WHERE id = ?';

    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare SQL '.$sql.' w/ error: '.$self->dbh()->errstr, level => 'error', );
    }
    if(!$sth->execute($request->{'value'},$request->{'config_id'})) {
        $self->logger()->log( message => 'Failed to execute stmt w/ error: '.$sth->errstr, level => 'error', );
    }
    $sth->finish();

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

sub _render_delete_service_ask {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'delete_service_ask.tpl',
        {
            'gs_id' => $request->{'gs_id'},
            'group_id' => $request->{'group_id'},
            'groups' => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_delete_service {
    my $self = shift;
    my $request = shift;

    return unless $request->{'gs_id'};

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'DELETE FROM group_services WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
      $self->logger()->log( message => 'Failed to prepare SQL '.$sql.' w/ error: '.$self->dbh()->errstr, level => 'error', );
    }
    if(!$sth->execute($request->{'gs_id'})) {
      $self->logger()->log( message => 'Failed to execute stmt w/ error: '.$sth->errstr, level => 'error', );
    }
    $sth->finish();

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

#
# Config
#

sub _render_list_config {
    my $self = shift;
    my $request = shift;

    # Config
    my $sql = 'SELECT `id`,`key`,`value` FROM config WHERE `group_id` = ? ORDER BY `key`';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'group_id'});
    my @config = ();
    while(my ( $id, $key, $value ) = $sth->fetchrow_array()) {
        push(@config,{
            'id'    => $id,
            'key'   => $key,
            'value' => $value,
        });
    }
    $sth->finish();

    my $body;
    $self->tt()->process(
        'list_config.tpl',
        {
            'group_id' => $request->{'group_id'},
            'config' => \@config,
            'groups' => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_add_config {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'add_config.tpl',
        {
            'group_id' => $request->{'group_id'},
            'groups' => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_insert_config {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'INSERT INTO config (`key`,`value`,`group_id`) VALUES (?,?,?)';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'key'},$request->{'value'},$request->{'group_id'});

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

sub _render_edit_config {
    my $self = shift;
    my $request = shift;

    my $sql = 'SELECT `id`,`key`,`value` FROM config WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'config_id'});
    my ($id,$key,$value) = $sth->fetchrow_array();

    my $body;
    $self->tt()->process(
        'edit_config.tpl',
        {
            'config_id'  => $request->{'config_id'},
            'key'     => $key,
            'value' => $value,
            'group_id' => $request->{'group_id'},
            'groups' => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_update_config {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'UPDATE config SET `value` = ? WHERE id = ?';

    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        #print "Prepare failed: ".$self->dbh()->errstr()."\n";
    }
    if(!$sth->execute($request->{'value'},$request->{'config_id'})) {
        #print "Exec failed: ".$sth->errstr()."\n";
    }

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

sub _render_delete_config_ask {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'delete_config_ask.tpl',
        {
            'config_id' => $request->{'config_id'},
            'group_id' => $request->{'group_id'},
            'groups' => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_delete_config {
    my $self = shift;
    my $request = shift;

    return unless $request->{'config_id'};

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'DELETE FROM config WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'config_id'});
    $sth->finish();

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

#
# Config_contacts
#

sub _render_list_config_contacts {
    my $self = shift;
    my $request = shift;

    # Config
    my $sql = 'SELECT `id`,`key`,`value` FROM config_contacts WHERE `contact_id` = ? ORDER BY `key`';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'contact_id'});
    my @config = ();
    while(my ( $id, $key, $value ) = $sth->fetchrow_array()) {
        push(@config,{
            'id'    => $id,
            'key'   => $key,
            'value' => $value,
        });
    }
    $sth->finish();

    my $body;
    $self->tt()->process(
        'list_config_contacts.tpl',
        {
            'contact_id' => $request->{'contact_id'},
            'config' => \@config,
            'groups' => $self->_get_group_array(),
            'group_id'  => $request->{'group_id'},
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_add_config_contacts {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'add_config_contacts.tpl',
        {
            'contact_id' => $request->{'contact_id'},
            'group_id'  => $request->{'group_id'},
            'contacts'  => $self->_get_contacts_array($request->{'group_id'}),
            'groups'    => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_insert_config_contacts {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=list_config_contacts&contact_id='.$request->{'contact_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'INSERT INTO config_contacts (`key`,`value`,`contact_id`) VALUES (?,?,?)';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'key'},$request->{'value'},$request->{'contact_id'});

    return [ 301, [ 'Location', '?rm=list_config_contacts&contact_id='.$request->{'contact_id'} ], [] ];
}

sub _render_edit_config_contacts {
    my $self = shift;
    my $request = shift;

    my $sql = 'SELECT `id`,`key`,`value` FROM config_contacts WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'cconfig_id'});
    my ($id,$key,$value) = $sth->fetchrow_array();

    my $body;
    $self->tt()->process(
        'edit_config_contacts.tpl',
        {
            'cconfig_id'        => $request->{'cconfig_id'},
            'key'               => $key,
            'value'             => $value,
            'group_id'          => $request->{'group_id'},
            'contact_id'        => $request->{'contact_id'},
            'contacts'          => $self->_get_contacts_array($request->{'group_id'}),
            'groups'            => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_update_config_contacts {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=list_config_contacts&contact_id='.$request->{'contact_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'UPDATE config_contacts SET `value` = ? WHERE id = ?';

    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        #print "Prepare failed: ".$self->dbh()->errstr()."\n";
    }
    if(!$sth->execute($request->{'value'},$request->{'cconfig_id'})) {
        #print "Exec failed: ".$sth->errstr()."\n";
    }

    return [ 301, [ 'Location', '?rm=list_config_contacts&contact_id='.$request->{'contact_id'} ], [] ];
}

sub _render_delete_config_contacts_ask {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'delete_config_contacts_ask.tpl',
        {
            'cconfig_id'        => $request->{'cconfig_id'},
            'group_id'          => $request->{'group_id'},
            'contact_id'        => $request->{'contact_id'},
            'groups'            => $self->_get_group_array(),
        },
        \$body,
    );

    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_delete_config_contacts {
    my $self = shift;
    my $request = shift;

    return [ 301, [ 'Location', '?rm=list_config_contacts&contact_id='.$request->{'contact_id'}.'&msg=Missing%20Args' ], [] ] unless $request->{'cconfig_id'};

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=list_config_contacts&contact_id='.$request->{'contact_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'DELETE FROM config_contacts WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'cconfig_id'});
    $sth->finish();

    return [ 301, [ 'Location', '?rm=list_config_contacts&contact_id='.$request->{'contact_id'} ], [] ];
}

#
# Contacts
#
sub _render_list_contacts {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'list_contacts.tpl',
        {
            'group_id'  => $request->{'group_id'},
            'contacts'  => $self->_get_contacts_array($request->{'group_id'}),
            'groups'    => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_add_contact {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'add_contact.tpl',
        {
            'group_id' => $request->{'group_id'},
            'groups' => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_insert_contact {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'INSERT INTO contacts (`name`,`cellphone`, `group_id`,`is_enabled`,`ordinal`) VALUES (?,?,?,0,0)';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'name'},$request->{'cellphone'},$request->{'group_id'});
    my $contact_id = $self->dbh()->last_insert_id(undef, undef, undef, undef);

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

sub _render_edit_contact {
    my $self = shift;
    my $request = shift;

    my $sql = 'SELECT name,cellphone FROM contacts WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'contact_id'});
    my ($name,$cellphone) = $sth->fetchrow_array();
    $sth->finish();

    my $body;
    $self->tt()->process(
        'edit_contact.tpl',
        {
            'contact_id' => $request->{'contact_id'},
            'name'      => $name,
            'cellphone' => $cellphone,
            'group_id'  => $request->{'group_id'},
            'groups'    => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_update_contact {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $sql = 'UPDATE contacts SET ';
    my @args = ();

    foreach my $key (qw(name cellphone group_id)) {
        if(defined($request->{$key})) {
            $sql .= '`'.$key.'` = ?, ';
            push(@args,$request->{$key});
        }
    }

    # remove trailing comma
    $sql =~ s/,\s$//;

    $sql .= ' WHERE id = ?';
    push(@args, $request->{'contact_id'});

    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare statement from SQL '.$sql.' w/ error: '.$self->dbh()->errstr(), level => 'error', );
    }
    if(!$sth->execute(@args)) {
        $self->logger()->log( message => 'Failed to execute statement w/ error: '.$sth->errstr(), level => 'error', );
    }

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

sub _render_delete_contact_ask {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'delete_contact_ask.tpl',
        {
            'contact_id' => $request->{'contact_id'},
            'group_id' => $request->{'group_id'},
            'groups'    => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_delete_contact {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    return unless $request->{'contact_id'};

    my $sql = 'DELETE FROM contacts WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare statement from SQL '.$sql.' w/ error: '.$self->dbh()->errstr(), level => 'error', );
    }
    if(!$sth->execute($request->{'contact_id'})) {
        $self->logger()->log( message => 'Failed to execute statement w/ error: '.$sth->errstr(), level => 'error', );
    }
    $sth->finish();

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

sub _render_update_janitor {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $error = '';
    my $Group = $self->groups()->{$request->{'group_id'}};
    if($Group) {
        try {
            my $users = $Group->set_janitor($request->{'janitor'});
            if(scalar(@$users)) {
                $self->logger()->log( message => "Updated janitor", level => 'debug', );
            } else {
                $error = 'Failed to set new janitor';
                $self->logger()->log( message => "Failed to set new janitor", level => 'error', );
            }
        } catch {
            $self->logger()->log( message => "Failed to set new janitor: ".$_, level => 'error', );
        };
    } else {
        $self->logger()->log( message => "Unable to set new janitor. Got no group.", level => 'error', );
    }

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

sub _render_enable_contact_ask {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'enable_contact_ask.tpl',
        {
            'contact_id' => $request->{'contact_id'},
            'group_id' => $request->{'group_id'},
            'groups'    => $self->_get_group_array(),
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_enable_contact {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $Group = $self->groups()->{$request->{'group_id'}};
    if($Group) {
        try {
            $Group->enable_contact($request->{'contact_id'});
        } catch {
            $self->logger()->log( message => "Failed to enable user: ".$_, level => 'error', );
        };
    }

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

sub _render_disable_contact_ask {
    my $self = shift;
    my $request = shift;

    my $body;
    $self->tt()->process(
        'disable_contact_ask.tpl',
        {
            'contact_id' => $request->{'contact_id'},
            'group_id' => $request->{'group_id'},
        },
        \$body,
    );
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

sub _render_disable_contact {
    my $self = shift;
    my $request = shift;

    # verify group_key before any modification
    if(!$self->_verify_group_key($request)) {
        return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'}.'&msg=Invalid%20Key' ], [] ];
    }

    my $Group = $self->groups()->{$request->{'group_id'}};
    if($Group) {
        try {
            $Group->disable_contact($request->{'contact_id'});
        } catch {
            $self->logger()->log( message => "Failed to disable user: ".$_, level => 'error', );
        };
    }

    return [ 301, [ 'Location', '?rm=overview&group_id='.$request->{'group_id'} ], [] ];
}

#
# Overview
#

sub _render_overview {
    my $self = shift;
    my $request = shift;

    # Groups
    my $group_name = '';
    my $sql = 'SELECT id,name FROM groups';
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare SQL '.$sql.' w/ error: '.$self->dbh()->errstr, level => 'error', );
        return [ 500, [ 'Content-Type', 'text/html'], []];
    }
    if(!$sth->execute()) {
        $self->logger()->log( message => 'Failed to execute stmt w/ error: '.$sth->errstr, level => 'error', );
        return [ 500, [ 'Content-Type', 'text/html'], []];
    }
    my @groups = ();
    while(my ($id,$name) = $sth->fetchrow_array()) {
        push(@groups,{ 'id' => $id, 'name' => $name, });
        if($id == $request->{'group_id'}) {
            $group_name = $name;
        }
    }
    $sth->finish();

    # User
    $sql = 'SELECT id,name,cellphone,is_enabled FROM contacts WHERE group_id = ? ORDER BY name';
    $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'group_id'});
    my @users = ();
    while(my ($id,$name,$cellphone,$is_enabled) = $sth->fetchrow_array()) {
        push(@users,{
            'id' => $id,
            'name' => $name,
            'cellphone' => $cellphone,
            'is_enabled' => $is_enabled,
        });
    }
    $sth->finish();
    my @random_contacts = List::Util::shuffle(grep { $_->{'is_enabled'} } @users);

    # Ordering
    $sql = 'SELECT id,name,cellphone,ordinal FROM contacts WHERE group_id = ? AND is_enabled AND ordinal > 0 ORDER BY ordinal';
    $sth = $self->dbh()->prepare($sql);
    $sth->execute($request->{'group_id'});
    my @ordered_contacts = ();
    while(my ($id,$name,$cellphone,$ordinal) = $sth->fetchrow_array()) {
        push(@ordered_contacts,{
            'id' => $id,
            'name' => $name,
            'cellphone' => $cellphone,
            'ordinal' => $ordinal,
        });
    }
    $sth->finish();

    my $services_ref = {};
    if($self->groups() && $request->{'group_id'} && $self->groups()->{$request->{'group_id'}}) {
        $services_ref = $self->groups()->{$request->{'group_id'}}->services();
    }

    my $body;
    $self->tt()->process(
        'overview.tpl',
        {
            'groups'   => \@groups,
            'users'    => \@users,
            'random_contacts' => \@random_contacts,
            'ordered_contacts'   => \@ordered_contacts,
            'group_id' => $request->{'group_id'},
            'group_name' => $group_name,
            'services' => $services_ref,
        },
        \$body,
    ) or return [ 500, [ 'Content-Type', 'text/plain'], [$self->tt()->error()]];
    return [ 200, [ 'Content-Type', 'text/html'], [$body]];
}

#
# Error-Handler
#

sub _render_show_error {
    my $self = shift;
    my $request = shift;

    my $body = "Error!\n";

    return [ 500, [ 'Content-Type', 'text/html'], [$body]];
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Standby::Frontend - Plack based web frontend for App::Standby

=head1 METHODS

=head2 groups

Get a hash ref of all groups containing their names and objects.

=head2 run

Handle a Plack request.

=head1 NAME

App::Standby::Frontend - Plack based web frontend for App::Standby

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
