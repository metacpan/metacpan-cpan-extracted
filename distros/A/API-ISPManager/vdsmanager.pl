#!/usr/bin/perl

use strict;
use warnings;

use API::ISPManager;
use Data::Dumper;
use Getopt::Long;

my ($username, $password, $host);
my ($var_node_id, $name, $vps_password, $os, $owner, $preset);

my $result = GetOptions (
    'username=s'    => \$username,
    'password=s'    => \$password,
    'host=s'        => \$host,
    'nodeid=s'      => \$var_node_id,
    'vpspassword=s' => \$vps_password,
    'owner=s'       => \$owner,
    'preset=s'      => \$preset,
    'os=s'          => \$os,
    'name=s'        => \$name,
);

die 'Required command line parameter missing!' unless $result;

# Конфигурация скрипта
my $connection_params = {
    username => $username,
    password => $password,
    host     => $host,
    path     => 'manager/vdsmgr',
};

#
#  name        => 'mymegavps6.ru',  # тут хочет доменку и ничего другого
#  password    => 'qwerty',
#  os          => 'centos-5-x86_64',
#  owner       => 'admin',
#  preset      => 'OVZ-1',
#  node_id     => '1',              # номер Ноды
#


# Создаем ВПС
# Добавить автоформирование veid
# N -- номер впса
# N001, N002, N003.... N999 
# просто передаем параметром номер и все, отдельный параметр как и пароль и все такое

my $create_result = create_vps(
    name        => $name,           # тут хочет доменку и ничего другого
    password    => $vps_password,
    os          => $os,
    owner       => $owner,
    preset      => $preset,
    node_id     => $var_node_id,    # номер Ноды
);

### warn Dumper($create_result);

if ( $create_result && $create_result->{ok} && $create_result->{ip} && $create_result->{veid} ) {
    print "$create_result->{ip}|$create_result->{veid}\n";
    exit 0; # всё окей!
} else {
    print "error\n";
    exit 1;
}

# Проверка существования дискового шаблона
sub check_disk_preset {
    my $disk_preset_name = shift;
    return '' unless $disk_preset_name;

    my $disk_templates =
        API::ISPManager::diskpreset::list( $connection_params );

    return '' unless $disk_templates && ref $disk_templates eq 'HASH';

    # List all disk templates
    my @list = keys %$disk_templates;

    for (@list) {
        # If this preset exists and ok:
        my $preset_ok = 
            $disk_preset_name eq $_        &&
            $disk_templates->{$_}          &&
            $disk_templates->{$_}->{state} &&
            $disk_templates->{$_}->{state} eq 'ok';

        return 1 if $preset_ok;
    }

    return '';
}


# Проверяем корректность переданного шаблона ВПС
sub check_vps_preset {
    my $disk_preset_name = shift;
    return '' unless $disk_preset_name;

    my $disk_templates =
        API::ISPManager::vdspreset::list( $connection_params );

    return '' unless $disk_templates && ref $disk_templates eq 'HASH';

    # List all VPS templates
    my @list = keys %$disk_templates;

    for (@list) {
        # If this preset exists:
        my $preset_ok = 
            $disk_preset_name eq $_ &&
            $disk_templates->{$_};

        return 1 if $preset_ok;
    }

    return '';
}


# Получаем детализацию тарифа ВПС
sub get_vps_preset_details {
    my $preset_name = shift;
    return '' unless $preset_name;

    my $vds_template_details = API::ISPManager::vdspreset::get( {
        %$connection_params ,
        elid => $preset_name
    } );

    # Фильтруем только нужные параметры тарифа
    my $clean_plan_details = { };
    my @required_params = qw(disk mem cpu proc desc traf);


    for (@required_params) {

        unless ( $vds_template_details->{$_} ) {
            warn "Required detail is missing!!\n";
            return '';
        }

        $clean_plan_details->{$_} = $vds_template_details->{$_};
    }
    
    return $clean_plan_details;
}


# Получаем ID следующей впски
sub get_next_veid {
    my $node_id = shift;
    return '' unless $node_id;

    my $vds_list = API::ISPManager::vds::list( { %$connection_params } );
    return unless $vds_list && ref $vds_list eq 'HASH';

    my @id_list =
        sort { $a <=> $b }
        grep { /^$node_id\d{3}$/ }
        map  { $vds_list->{$_}->{id} }
        keys %$vds_list;

    if (@id_list) {
        return ++$id_list[-1];  # продолжаем имеющуюся нумерацию
    } else {
        return "${node_id}001"; # это первый впс
    }
}

# Создаем ВПС
sub create_vps {
    my %params = @_;

    my $all_params_ok =
        $params{password} &&
        $params{os}       &&
        $params{owner}    &&
        $params{preset}   &&
        $params{node_id};
    
    unless ($all_params_ok)  {
        warn "Required parameter missing!\n";
        return '';
    }

    # Блок проверки входных параметров

    my $disk_preset = $params{os};

    unless ( check_disk_preset($disk_preset) ) {
        warn "Disk preset incorrect!\n";
        return '';
    }


    my $vps_preset = $params{preset};

    unless ( check_vps_preset($vps_preset) ) {
        warn "VPS preset incorrect!\n";
        return '';
    }


    # Выгружаем подробности тарифа
    my $vps_preset_details = get_vps_preset_details( $vps_preset );

    unless ($vps_preset_details && ref $vps_preset_details eq 'HASH') {
        warn "Cannot get preset details!\n";
        return '';
    }


    my $node_id = $params{node_id};

    unless ($node_id =~ m/^\d$/) {
        warn "In Node ID only numbers allowed!\n";
        return '';
    }


    my $veid = get_next_veid( $node_id );

    unless ($veid) {
        warn "Cannot get next VEID!\n";
        return '';
    }


    my $vps_name = $params{name}; # тут хочет доменку и ничего другого

    unless ($vps_name) {
        $vps_name = "ovz${veid}.fastvps.ru"
    }


    # Эти параметры пока проверять не будем
    my $server_password = $params{password};
    my $owner           = $params{owner};


    my $create_vps_result = API::ISPManager::vds::create( {
        %$connection_params,
        name       => $vps_name,
        id         => $veid,
        passwd     => $server_password,
        confirm    => $server_password,
        owner      => $owner,
        vdspreset  => $vps_preset,
        disktempl  => $disk_preset,

        %$vps_preset_details, # параметры ВПС тарифа
    } );

    if ($create_vps_result && ref $create_vps_result eq 'HASH' ) {
        return {
            %$create_vps_result,
            veid => $veid,
        }
    } else {
        return '';
    }
}


__DATA__
остыпало ошибку:

         'error' => {
                     'content' => 'Can\'t change pos in edit mode',
                     'code' => '1'
                   },
было из-за того, что траф не передавал
