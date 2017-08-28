#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2015-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::Systemd::Unit ;
$Config::Model::Backend::Systemd::Unit::VERSION = '0.234.1';
use strict;
use warnings;
use 5.010;
use Mouse ;
use Log::Log4perl qw(get_logger :levels);
use Path::Tiny;

extends 'Config::Model::Backend::IniFile';

with 'Config::Model::Backend::Systemd::Layers';

my $logger = get_logger("Backend::Systemd::Unit");

sub read {
    my $self = shift ;
    my %args = @_ ;

    # enable 2 styles of comments (gh #1)
    $args{comment_delimiter} = "#;";

    # args are:
    # root       => './my_test',  # fake root directory, used for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    # file write is handled by Unit backend
    if ($self->instance->application =~ /systemd-(?!user)/) {
        # file_path overridden by model => how can config_dir be found ?
        my $file = $args{file_path};
        # allow non-existent file to let user start from scratch
        return 1 unless  path( $file )->exists;

        return $self->load_ini_file(%args, file_path => $file);
    }

    my $unit_type = $self->node->element_name;
    my $unit_name   = $self->node->index_value;

    $self->node->instance->layered_start;
    # load layers for this service
    foreach my $layer ($self->default_directories) {
        my $dir = path ($args{root}.$layer);
        next unless $dir->is_dir;

        my $file = $dir->child($unit_name.'.'.$unit_type);
        next unless $file->exists;

        $logger->debug("reading default layer from unit $unit_type name $unit_name from $file");
        $self->load_ini_file(%args, file_path => $file);

        # TODO: may also need to read files in
        # $unit_name.'.'.$unit_type.'.d' to get all default values
        # (e.g. /lib/systemd/system/rc-local.service.d/debian.conf)
    }
    $self->node->instance->layered_stop;

    # now read editable file (files that can be edited with systemctl edit <unit>.<type>
    # for systemd -> /etc/ systemd/system/unit.type.d/override.conf
    # for user -> ~/.local/systemd/user/*.conf
    # for local file -> $args{filexx}

    # TODO: document limitations (can't read arbitrary files in /etc/
    # systemd/system/unit.type.d/ and
    # ~/.local/systemd/user/unit.type.d/*.conf

    my $app = $self->instance->application;
    $args{file_path} .= '.d/override.conf' if $app eq 'systemd';
    my $file_path = path( $args{file_path} );

    if ($file_path->exists and $file_path->realpath eq '/dev/null') {
        $logger->debug("skipping  unit $unit_type name $unit_name from ".$args{config_dir});
    }
    elsif ($file_path->exists) {
        $logger->debug("reading unit $unit_type name $unit_name from ".$args{file_path});
        $self->load_ini_file(%args);
    }
}

sub load_ini_file {
    my ($self, %args) = @_ ;

    $logger->debug("opening file '".$args{file_path}."' to read");
    my $file = path($args{file_path});

    my $fh = $file->openr_utf8;

    my $res = $self->SUPER::read(
        %args,
        io_handle => $fh,
    );
    $fh->close;
    die "failed $file read " unless $res;
}

# overrides call to node->load_data
sub load_data {
    my $self = shift;
    my %args = @_ ; # data, check, split_reg

    my $check = $args{check};
    my $data = $args{data} ;

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

            # force creation of element (can be removed with Config::Model 2.086)
            my $obj = $node->fetch_element(name => $elt, check => $check);

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
}

sub write {
    my $self = shift ;
    my %args = @_ ;

    # args are:
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    if ($self->node->grab_value('disable')) {
        my $fp = path($args{file_path});
        if ($fp->realpath ne '/dev/null') {
            $logger->warn("symlinking file $fp to /dev/null");
            $fp->remove;
            symlink ('/dev/null', $fp->stringify);
        }
        return 1;
    }

    my $app = $self->instance->application;
    if ($app eq 'systemd') {
        my $dir = path ($args{file_path} . '.d');
        $dir->mkpath;
        my $file_path = $dir->child('override.conf');
        $logger->debug("open $file_path to write");
        $args{file_path} = $file_path->stringify;
        $args{io_handle} = $file_path->openw_utf8;
    }

    $logger->debug("writing unit to ".$args{file_path});
    # mouse super() does not work...
    $self->SUPER::write(%args);
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

version 0.234.1

=head1 SYNOPSIS

 # in systemd service or socket model
 read_config => [
   {
     'auto_create' => '1',
     'auto_delete' => '1',
     'backend' => 'Systemd::Unit',
     'file' => '&index.service'
   }
 ]

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

This software is Copyright (c) 2015-2017 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
