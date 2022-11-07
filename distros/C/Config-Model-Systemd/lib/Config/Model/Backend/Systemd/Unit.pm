#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2008-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::Systemd::Unit ;
$Config::Model::Backend::Systemd::Unit::VERSION = '0.252.1';
use strict;
use warnings;
use 5.020;
use Mouse ;
use Log::Log4perl qw(get_logger :levels);
use Path::Tiny;

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

extends 'Config::Model::Backend::IniFile';

with 'Config::Model::Backend::Systemd::Layers';

my $logger = get_logger("Backend::Systemd::Unit");
my $user_logger = get_logger("User");

sub get_unit_info ($self, $file_path) {
    # get info from tree when Unit is children of systemd (app is systemd)
    my $unit_type = $self->node->element_name;
    my $unit_name = $self->node->index_value;
    my $app = $self->instance->application;
    my ($trash, $app_type) = split /-/, $app;

    # get info from file name (app is systemd-* not -user)
    if (my $fp = $file_path->basename) {
        my ($n,$t) = split /\./, $fp;
        $unit_type ||= $t;
        $unit_name ||= $n;
    }

    # fallback to app type when file is name without unit type
    $unit_type ||= $app_type if ($app_type and $app_type ne 'user');

    Config::Model::Exception::User->throw(
        object => $self,
        error  => "Unknown unit type. Please add type to file name. e.g. "
        . $file_path->basename.".service or socket..."
    ) unless $unit_type;

    # safety check
    if ($app !~ /^systemd(-user)?$/ and $app !~ /^systemd-$unit_type/) {
        Config::Model::Exception::User->throw(
            objet => $self->node,
            error => "Unit type $unit_type does not match app $app"
        );
    }

    return ($unit_name, $unit_type);
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub read ($self, %args) {
    # enable 2 styles of comments (gh #1)
    $args{comment_delimiter} = "#;";

    # args are:
    # root       => './my_test',  # fake root directory, used for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # check      => yes|no|skip

    if ($self->instance->application =~ /-file$/) {
        # allow non-existent file to let user start from scratch
        return 1 unless  $args{file_path}->exists;

        return $self->load_ini_file(%args);
    }

    my ($unit_name, $unit_type) = $self->get_unit_info($args{file_path});
    my $app = $self->instance->application;

    $self->node->instance->layered_start;
    my $root = $args{root} || path('/');
    my $cwd = $args{root} || path('.');

    # load layers for this service
    my $found_unit = 0;
    foreach my $layer ($self->default_directories) {
        my $local_root = $layer =~ m!^/! ? $root : $cwd;
        my $layer_dir = $local_root->child($layer);
        next unless $layer_dir->is_dir;

        my $layer_file = $layer_dir->child($unit_name.'.'.$unit_type);
        next unless $layer_file->exists;

        $user_logger->warn("Reading unit '$unit_type' '$unit_name' from '$layer_file'.");
        $self->load_ini_file(%args, file_path => $layer_file);
        $found_unit++;

        # TODO: may also need to read files in
        # $unit_name.'.'.$unit_type.'.d' to get all default values
        # (e.g. /lib/systemd/system/rc-local.service.d/debian.conf)
    }
    $self->node->instance->layered_stop;

    if (not $found_unit) {
        $user_logger->warn("Could not find unit files for $unit_type name $unit_name");
    }

    # now read editable file (files that can be edited with systemctl edit <unit>.<type>
    # for systemd -> /etc/ systemd/system/unit.type.d/override.conf
    # for user -> ~/.local/systemd/user/*.conf
    # for local file -> $args{filexx}

    # TODO: document limitations (can't read arbitrary files in /etc/
    # systemd/system/unit.type.d/ and
    # ~/.local/systemd/user/unit.type.d/*.conf

    my $service_path;
    if ($app =~ /-user$/) {
        $service_path = $args{file_path} ;
    }
    else {
        $service_path = $args{file_path}->parent->child("$unit_name.$unit_type.d/override.conf");
    }

    if ($service_path->exists and $service_path->realpath eq '/dev/null') {
        $logger->debug("skipping unit $unit_type name $unit_name from $service_path");
    }
    elsif ($service_path->exists) {
        $logger->debug("reading unit $unit_type name $unit_name from $service_path");
        $self->load_ini_file(%args, file_path => $service_path);
    }
    return 1;
}

sub load_ini_file {
    my ($self, %args) = @_ ;

    $logger->debug("opening file '".$args{file_path}."' to read");

    my $res = $self->SUPER::read( %args );
    die "failed ". $args{file_path}." read" unless $res;
    return;
}

# overrides call to node->load_data
sub load_data ($self, %args) {
    my $check = $args{check};
    my $data  = $args{data} ;

    my $disp_leaf = sub {
        my ($scanner, $data, $node,$element_name,$index, $leaf_object) = @_ ;
        if (ref($data) eq 'ARRAY') {
            Config::Model::Exception::User->throw(
                object => $leaf_object,
                error  => "Cannot store twice the same value ('"
                .join("', '",@$data). "'). "
                ."Is '$element_name' line duplicated in config file ? "
                ."You can use -force option to load value '". $data->[-1]."'."
            ) if $check eq 'yes';
            $data = $data->[-1];
        }
        # remove this translation after Config::Model 2.146
        if ($leaf_object->value_type eq 'boolean') {
            $data = 'yes' if $data eq 'on';
            $data = 'no'  if $data eq 'off';
        }
        $leaf_object->store(value =>  $data, check => $check);
    } ;

    my $unit_cb = sub {
        my ($scanner, $data_ref,$node,@elements) = @_ ;

        # read data in the model order
        foreach my $elt (@elements) {
            my $unit_data = delete $data_ref->{$elt}; # extract relevant data
            next unless defined $unit_data;
            $scanner->scan_element($unit_data, $node,$elt) ;
        }
        # read accepted elements
        foreach my $elt (sort keys %$data_ref) {
            my $unit_data = $data_ref->{$elt}; # extract relevant data
            $scanner->scan_element($unit_data, $node,$elt) ;
        }
    };

    # this setup is required because IniFile backend cannot push value
    # coming from several ini files on a single list element. (even
    # though keys can be repeated in a single ini file and stored as
    # list in a single config element, this is not possible if the
    # list values come from several files)
    my $list_cb = sub {
        my ($scanner, $data,$node,$element_name,@idx) = @_ ;
        my $list_ref = ref($data) ? $data : [ $data ];
        my $list_obj= $node->fetch_element(name => $element_name, check => $check);
        foreach my $d (@$list_ref) {
            $list_obj->push($d); # push also empty values
        }

    };

    my $scan = Config::Model::ObjTreeScanner-> new (
        node_content_cb => $unit_cb,
        list_element_cb => $list_cb,
        leaf_cb => $disp_leaf,
    ) ;

    $scan->scan_node($data, $self->node) ;
    return;
}

sub write ($self, %args) {
    # args are:
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # check      => yes|no|skip

    if ($self->node->grab_value('disable')) {
        my $fp = $args{file_path};
        if ($fp->realpath ne '/dev/null') {
            $user_logger->warn("symlinking file $fp to /dev/null");
            $fp->remove;
            symlink ('/dev/null', $fp->stringify);
        }
        return 1;
    }

    my ($unit_name, $unit_type) = $self->get_unit_info($args{file_path});

    my $app = $self->instance->application;
    my $service_path;
    if ($app =~  /-(user|file)$/) {
        $service_path = $args{file_path};

        $logger->debug("writing unit to $service_path");
        # mouse super() does not work...
        $self->SUPER::write(%args, file_path => $service_path);
    }
    else {
        my $dir = $args{file_path}->parent->child("$unit_name.$unit_type.d");
        $dir->mkpath({ mode => oct(755) });
        $service_path = $dir->child('override.conf');

        $logger->debug("writing unit to $service_path");
        # mouse super() does not work...
        $self->SUPER::write(%args, file_path => $service_path);

        if (scalar $dir->children == 0) {
            # remove empty dir
            $logger->warn("Removing empty dir $dir");
            rmdir $dir;
        }
    }
    return 1;
}

sub _write_leaf{
    my ($self, $args, $node, $elt)  = @_ ;
    # must skip disable element which cannot be hidden :-(
    if ($elt eq 'disable') {
        return '';
    } else {
        return $self->SUPER::_write_leaf($args, $node, $elt);
    }
}

no Mouse ;
__PACKAGE__->meta->make_immutable ;

1;

# ABSTRACT: R/W backend for systemd unit files

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::Systemd::Unit - R/W backend for systemd unit files

=head1 VERSION

version 0.252.1

=head1 SYNOPSIS

 # in systemd service or socket model
 rw_config => {
     'auto_create' => '1',
     'auto_delete' => '1',
     'backend' => 'Systemd::Unit',
     'file' => '&index.service'
 }

=head1 DESCRIPTION

C<Config::Model::Backend::Systemd::Unit> provides a plugin class to enable
L<Config::Model> to read and write systemd configuration files. This
class inherits L<Config::Model::Backend::IniFile> is designed to be used
by L<Config::Model::BackendMgr>.

=head1 Methods

=head2 read

This method read config data from  systemd default file to get default
values and read config data.

=head2 write

This method write systemd configuration data.

When the service is disabled, the target configuration file is
replaced by a link to C</dev/null>.

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008-2022 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
