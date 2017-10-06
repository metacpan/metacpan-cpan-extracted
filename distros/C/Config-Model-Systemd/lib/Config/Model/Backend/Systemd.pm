#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2015-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::Systemd ;
$Config::Model::Backend::Systemd::VERSION = '0.234.2';
use strict;
use warnings;
use 5.010;
use Mouse ;
use Log::Log4perl qw(get_logger :levels);
use Path::Tiny 0.086;

extends 'Config::Model::Backend::Any';
with 'Config::Model::Backend::Systemd::Layers';

my $logger = get_logger("Backend::Systemd");

has config_dir => (
    is => 'rw',
    isa => 'Path::Tiny'
);

# TODO: accepts other systemd suffixes
my @service_types = qw/service socket/;
my $joined_types = join('|', @service_types);
my $filter = qr/\.($joined_types)(\.d)?$/;

sub get_backend_arg {
    my $self = shift ;

    my $ba = $self->instance->backend_arg;
    if (not $ba) {
        Config::Model::Exception::User->throw(
            objet => $self->node,
            error => "Missing systemd unit to work on. This may be passed as 3rd argument to cme",
        );
    }
    return $ba;
}

sub read {
    my $self = shift ;
    my $app = $self->instance->application;

    if ($app =~ /file/) {
        $self->read_systemd_files(@_);
    }
    else {
        $self->read_systemd_units(@_);
    }
}

sub read_systemd_files {
    my $self = shift ;
    my %args = @_ ;

    # args are:
    # root       => './my_test',  # fake root directory, used for tests
    # config_dir => /etc/foo',    # absolute path
    # config_file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    #use Tk::ObjScanner; Tk::ObjScanner::scan_object(\%args) ;
    my $file = $args{file_path};
    if (not $file) {
        Config::Model::Exception::User->throw(
            objet => $self->node,
            error => "Missing systemd file to work on. This may be passed as 3rd argument to cme",
        );
    }

    $logger->warn( "Loading unit file '$file'");
    my ($service_name, $unit_type) =  split /\./, path($file)->basename;

    my @to_create = $unit_type ? ($unit_type) : @service_types;
    foreach my $unit_type (@to_create) {
        $logger->debug("registering unit $unit_type name $service_name from file name");
        $self->node->load(step => qq!$unit_type:"$service_name"!, check => $args{check} ) ;
    }
}

sub read_systemd_units {
    my $self = shift ;
    my %args = @_ ;

    # args are:
    # root       => './my_test',  # fake root directory, used for tests
    # config_dir => /etc/foo',    # absolute path
    # config_file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    my $app = $self->instance->application;

    my $select_unit = $self->get_backend_arg;
    if (not $select_unit) {
        Config::Model::Exception::User->throw(
            objet => $self->node,
            error => "Missing systemd unit to work on. This may be passed as 3rd argument to cme",
        );
    }

    if ($select_unit ne '*') {
        $logger->warn( "Loading unit matching '$select_unit'");
    } else {
        $logger->warn("Loading all units...")
    }

    # load layers. layered mode is handled by Unit backend. Only a hash
    # key is created here, so layered mode does not matter
    foreach my $layer ($self->default_directories) {
        my $dir = path ($args{root}.$layer);
        next unless $dir->is_dir;
        $self->config_dir($dir);

        foreach my $file ($dir->children($filter) ) {
            my $unit_name = $file->basename($filter);
            $logger->trace( "checking unit $unit_name from $file (layered mode))");
            if ($select_unit ne '*' and $unit_name !~ /$select_unit/) {
                $logger->trace( "filtered out unit $unit_name from $file (layered mode))");
                next;
            }
            my ($unit_type) = ($file =~ $filter);
            $logger->debug( "registering unit $unit_type name $unit_name from $file (layered mode))");
            # force config_dir during init
            $self->node->load(step => qq!$unit_type:"$unit_name"!, check => $args{check} ) ;
        }
    }

    my $dir = path($args{root}.$args{config_dir});

    if (not $dir->is_dir) {
        $logger->debug("skipping missing directory $dir");
        return 1 ;
    }

    $self->config_dir($dir);
    my $found = 0;
    foreach my $file ($dir->children($filter) ) {
        my ($unit_type,$dot_d) = ($file =~ $filter);
        my $unit_name = $file->basename($filter);
        next if ($select_unit ne '*' and $unit_name !~ /$select_unit/);
        if ($file->realpath eq '/dev/null') {
            $logger->debug("unit $unit_type name $unit_name from $file is disabled");
            $self->node->load(step => qq!$unit_type:"$unit_name" disable=1!, check => $args{check} ) ;
        }
        elsif ($dot_d and $file->child('override.conf')->exists) {
            $logger->debug("registering unit $unit_type name $unit_name from override file");
            $self->node->load(step => qq!$unit_type:"$unit_name"!, check => $args{check} ) ;
        }
        else {
            $logger->debug("registering unit $unit_type name $unit_name from $file");
            $self->node->load(step => qq!$unit_type:"$unit_name"!, check => $args{check} ) ;
        }
        $found++;
    }

    if (not $found) {
        # no service exists, let's create them.
        my ($service_name, $unit_type) =  split /\./, $select_unit;
        my @to_create = $unit_type ? ($unit_type) : @service_types;
        $service_name //= $select_unit;
        foreach my $unit_type (@to_create) {
            $logger->debug("registering unit $unit_type name $service_name from scratch");
            $self->node->load(step => qq!$unit_type:"$service_name"!, check => $args{check} ) ;
        }
    }
    return 1 ;
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

    # file write is handled by Unit backend
    return 1 if $self->instance->application =~ /file/;

    my $dir = path($args{root}.$args{config_dir});
    die "Unknown directory $dir" unless $dir->is_dir;

    my $select_unit = $self->get_backend_arg;

    # delete files for non-existing elements (deleted services)
    foreach my $file ($dir->children($filter) ) {
        my ($unit_type) = ($file =~ $filter);
        my $unit_name = $file->basename($filter);

        next if ($select_unit ne '*' and $unit_name !~ /$select_unit/);

        my $unit_collection = $self->node->fetch_element($unit_type);
        if (not $unit_collection->defined($unit_name)) {
            $logger->warn("removing file $file of deleted service");
            $file->remove;
        }
    }

    return 1;
}

no Mouse ;
__PACKAGE__->meta->make_immutable ;

1;

# ABSTRACT: R/W backend for systemd configurations files

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::Systemd - R/W backend for systemd configurations files

=head1 VERSION

version 0.234.2

=head1 SYNOPSIS

 # in systemd model
 rw_config => {
     'backend' => 'Systemd'
 }

=head1 DESCRIPTION

Config::Model::Backend::Systemd provides a plugin class to enable
L<Config::Model> to read and write systemd configuration files. This
class inherits L<Config::Model::Backend::Any> is designed to be used
by L<Config::Model::BackendMgr>.

=head1 Methods

=head2 read

This method scans systemd default directory and systemd config
directory to create all units in L<Config::Model> tree. The actual
configuration parameters are read by
L<Config::Model::Backend::Systemd::Unit>.

=head2 write

This method is a bit of a misnomer. It deletes configuration files of
deleted service.

The actual configuration parameters are written by
L<Config::Model::Backend::Systemd::Unit>.

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015-2017 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
