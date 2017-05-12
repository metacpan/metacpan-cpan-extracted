package API::CPanel::Mysql;

use strict;
use warnings;

use API::CPanel;
use Data::Dumper;

our $VERSION = 0.07;

# ƒобавл€ет пользовател€ в базу mysql
# IN:
#   - do_as_user - cPanel пользователь дл€ которого создаетс€ mysql-пользователь
#   - username   - »м€ mysql-пользовател€ дл€ создани€ 
#                  (фактически будет создан mysql-пользователь с именем: <do_as_user>_<username>).
#   - password   - ѕароль дл€ mysql-пользовател€.
sub adduser {
    my $params = shift;

    # ћодуль Mysql cPanel'а с которым работаем относитс€ к первой версии api
    $params->{'cpanel_xmlapi_apiversion'} = 1;
    # ƒобавл€ем нового пользовател€ в базу от имени пользовател€ передаваемого в параметре do_as_user
    # ‘актически это значит что работа€ с cPanel от реселлера мы создаем mysql 
    # юзера дл€ cPanel-пользовател€ с логином do_as_user
    $params->{'user'} = delete $params->{'do_as_user'};

    $params->{'cpanel_xmlapi_module'} = 'Mysql';
    $params->{'cpanel_xmlapi_func'}   = 'adduser';

    $params->{'arg-0'}  = delete $params->{'username'};
    $params->{'arg-1'}  = delete $params->{'password'};

    return unless $params->{'user'}  &&
                  $params->{'arg-0'} &&
                  $params->{'arg-1'};

    my $result = API::CPanel::action_abstract(
        params         => $params,
        func           => 'cpanel',
        want_hash      => '1',
        allowed_fields => '
            user 
            cpanel_xmlapi_module 
            cpanel_xmlapi_func 
            cpanel_xmlapi_apiversion 
            arg-0
            arg-1',
    );

    return $result->{event}->{result};
}

# ƒобавл€ет базу mysql
# IN:
#   - do_as_user - cPanel пользователь дл€ которого создаетс€ mysql-база
#   - dbname     - »м€ бд дл€ создани€ 
#                  (фактически будет создана бд с именем: <do_as_user>_<dbname>).
sub adddb {
    my $params = shift;

    # ћодуль Mysql cPanel'а с которым работаем относитс€ к первой версии api
    $params->{'cpanel_xmlapi_apiversion'} = 1;
    # ƒобавл€ем бд от имени пользовател€ передаваемого в параметре do_as_user
    # ‘актически это значит что работа€ с cPanel от реселлера мы создаем бд
    # дл€ cPanel-пользовател€ с логином do_as_user
    $params->{'user'} = delete $params->{'do_as_user'};

    $params->{'cpanel_xmlapi_module'} = 'Mysql';
    $params->{'cpanel_xmlapi_func'}   = 'adddb';

    $params->{'arg-0'}  = delete $params->{'dbname'};

    return unless $params->{'user'} &&
                  $params->{'arg-0'};


    my $result = API::CPanel::action_abstract(
        params         => $params,
        func           => 'cpanel',
        want_hash      => '1',
        allowed_fields => '
            user 
            cpanel_xmlapi_module 
            cpanel_xmlapi_func 
            cpanel_xmlapi_apiversion 
            arg-0',
    );

    return $result->{event}->{result};
}

# ”станавливает разрешени€ к базе
# IN:
#   - do_as_user - cPanel пользователь дл€ которого создаетс€ mysql-база
#   - dbname     - »м€ бд
#   - dbuser     - »м€ пользовател€
#   - perms_list - —писок разрешений:
#                       alter      => ALTER
#                       temporary  => CREATE TEMPORARY TABLES
#                       routine    => CREATE ROUTINE
#                       create     => CREATE
#                       delete     => DELETE
#                       drop       => DROP
#                       select     => SELECT
#                       insert     => INSERT
#                       update     => UPDATE
#                       references => REFERENCES
#                       index      => INDEX
#                       lock       => LOCK TABLES
#                       all        => ALL
sub grant_perms {
    my $params = shift;

    # ћодуль Mysql cPanel'а с которым работаем относитс€ к первой версии api
    $params->{'cpanel_xmlapi_apiversion'} = 1;
    # ƒобавл€ем бд от имени пользовател€ передаваемого в параметре do_as_user
    # ‘актически это значит что работа€ с cPanel от реселлера мы создаем бд
    # дл€ cPanel-пользовател€ с логином do_as_user
    $params->{'user'} = delete $params->{'do_as_user'};

    $params->{'cpanel_xmlapi_module'} = 'Mysql';
    $params->{'cpanel_xmlapi_func'}   = 'adduserdb';

    $params->{'arg-0'}  = delete $params->{'dbname'};
    $params->{'arg-1'}  = delete $params->{'dbuser'};
    $params->{'arg-2'}  = delete $params->{'perms_list'};

    return unless $params->{'user'}  &&
                  $params->{'arg-0'} &&
                  $params->{'arg-1'} &&
                  $params->{'arg-2'};

    my $result = API::CPanel::action_abstract(
        params         => $params,
        func           => 'cpanel',
        want_hash      => '1',
        allowed_fields => '
            user 
            cpanel_xmlapi_module 
            cpanel_xmlapi_func 
            cpanel_xmlapi_apiversion 
            arg-0
            arg-1
            arg-2',
    );

    return $result->{event}->{result};
}




1;
