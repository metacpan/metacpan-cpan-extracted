package Apache::Hadoop::Config;

use 5.010001;
use strict;
use warnings;

our @ISA = qw();
our $VERSION = '0.01';


# class definition begins

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = {
        namenode       => $args{'namenode'}  || 'localhost',
        secondary      => $args{'secondary'} || '0.0.0.0',
        proxynode      => $args{'proxynode'} || 'localhost',
        proxyport      => $args{'proxyport'} || 8888,
        hadoop_install => $args{'hadoop_install'}  || '/usr/local/hadoop',
        hadoop_confdir => $args{'hadoop_confdir'}  || '/usr/local/hadoop/etc/hadoop',
        hdfs_tmp       => $args{'hdfs_tmp'}  || '/hdfs/tmp',
        hdfs_name_disks=> $args{'hdfs_name_disks'} || 
            [ '/hdfs/name1',
              '/hdfs/name2',
            ],
        hdfs_data_disks=> $args{'hdfs_data_disks'} || 
            [ '/hdfs/data1',
              '/hdfs/data2',
              '/hdfs/data3',
              '/hdfs/data4',
            ],
        hadoop_logs    => [ '/logs', '/logs/userlog' ],
        debug          => $args{'debug'}    || undef,

        config         => $args{'config'}   || undef,

        sysinfo=> {
            cpu        => $args{'cpuinfo'}  || undef,
            mem        => $args{'meminfo'}  || undef,
            disk       => $args{'diskinfo'} || undef,
        },
    };
    bless $self, $class;
    return $self;
}

# internal utils
sub _minimum {
    my ($self, @arr) = (@_);
    my $min;
    for (@arr) { $min = $_ if !$min || $_ < $min; }
    return $min;
}

sub _maximum {
    my ($self, @arr) = (@_);
    my $max;
    for (@arr) { $max = $_ if !$max || $_ > $max; }
    return $max;
}

sub _copyconf {
    my ($self, $config) = (@_);
    unless ( defined $self->{'config'} ) {
        $self->{'config'} = $config;
        return;
    }

    foreach my $file ( keys %{$config} ) {
        foreach my $param ( keys %{$config->{$file}} ) {
            $self->{'config'}->{$file}->{$param} = $config->{$file}->{$param}
                unless defined $self->{'config'}->{$file}->{$param};
        }
    }
}

# get config template
sub basic_config {
    my ($self) = (@_);
    my $config = {
        'core-site.xml' => {
            'fs.defaultFS' => 'http://'.$self->{namenode}.':9000',
            'hadoop.tmp.dir' => $self->{'hdfs_tmp'},
            },
        'hdfs-site.xml' => {
            'dfs.replication' => 1,
            'dfs.namenode.name.dir' => join ( ',', map { 'file://'.$_ } @{$self->{'hdfs_name_disks'}} ),
            'dfs.datanode.data.dir' => join ( ',', map { 'file://'.$_ } @{$self->{'hdfs_data_disks'}} ),

            # secondary namenode 
            'dfs.namenode.secondary.http-address' => $self->{'secondary'}.':50090',
            'dfs.namenode.secondary.https-address'=> $self->{'secondary'}.':50091',
            },
        'yarn-site.xml' => {
            'yarn.nodemanager.aux-services' => 'mapreduce_shuffle',
            'yarn.nodemanager.aux-services.mapreduce.shuffle.class' => 'org.apache.hadoop.mapred.ShuffleHandler',
            'yarn.web-proxy.address' => $self->{'proxynode'}.':'.$self->{'proxyport'},
            },
        'mapred-site.xml' => {
            'mapreduce.framework.name' => 'yarn',
            }
        };
    
    $self->_copyconf ( $config );
}

#
# directory management
#
sub _mkdir {
    my ($self, %opts) = (@_);
    my $mode = $opts{'mode'} || 0750;
    my $u = umask (0);
    map { mkdir $_, $mode; chdir $_; } split (/\//, $opts{'directory'});
}

sub create_hdfs_name_disks {
    my ($self) = (@_);
    foreach my $dir ( @{$self->{'hdfs_name_disks'}} ) {
        print "creating ".$dir, "\n" if defined $self->{'debug'};
        $self->_mkdir( directory => $dir );
    }
}

sub create_hdfs_data_disks {
    my ($self) = (@_);
    foreach my $dir ( @{$self->{'hdfs_data_disks'}} ) {
        print "creating ".$dir, "\n" if defined $self->{'debug'};
        $self->_mkdir( directory => $dir );
    }
}

sub create_hdfs_tmpdir {
    my ($self) = (@_);
    print "creating ".$self->{'hdfs_tmp'}, "\n" if defined $self->{'debug'};
    $self->_mkdir( directory => $self->{'hdfs_tmp'}, mode => 01775 );
}

sub create_hadoop_logdir {
    # $hadoop_install/tmp 1775
    my ($self) = (@_);
    foreach my $dir ( @{$self->{'hadoop_logs'}} ) {
        print "creating ".$self->{'hadoop_install'}.$dir, "\n" if defined $self->{'debug'};
        $self->_mkdir( directory => $self->{'hadoop_install'}.$dir, mode => 01775 );
    }
}
# ends

#
# begin recommended settings
#

# get cpu core count
sub _get_cpu_cores {
    my ($self) = (@_);
    my $cpuinfo = '/proc/cpuinfo';
    open CPU, $cpuinfo or die "Cannot open $cpuinfo, $!\n";
    $self->{'sysinfo'}->{'cpu'} = scalar (map /^processor/, <CPU>);
    close CPU;
}

# get memory size
sub _get_memory_system {
    my ($self) = (@_);
    my $meminfo = '/proc/meminfo';
    open MEM, $meminfo or die "Cannot open $meminfo, $!\n";
    $self->{'sysinfo'}->{'mem'} = (split (/\s+/, (grep /^MemTotal/, <MEM>)[0]))[1];
    $self->{'sysinfo'}->{'mem'} = $self->{'sysinfo'}->{'mem'} / (1024.0 * 1024.0);
    close MEM;
}

# get disk info: not implemented
sub _get_disk_count {
    my ($self) = (@_);
    $self->{'sysinfo'}->{'disk'} = scalar @{$self->{'hdfs_data_disks'}}
}

# calculate reserved memory
sub _get_memory_reserved {
    my ($self) = (@_);
    my ($m, $m1, $m2, $m3);

    $self->_get_memory_system unless defined $self->{'sysinfo'}->{'mem'};
    $m = $self->{'sysinfo'}->{'mem'};
    $m1 = int (0.124102 * $m + 1.236659); # approximated by a linear eq through least square
    $m2 = $m >= 16 ? $m1 - ($m1%2) : $m1;
    $m3 = $m >= 64 ? $m2 - ($m2%2) : $m2;
    print "reserved_mem (gb): ",$m3,"\n" if $self->{'debug'};
    return $m3;
}

# calculate available memory (total - reserved)
sub _calc_memory_available {
    my ($self) = (@_);
    $self->_get_memory_system unless defined $self->{'sysinfo'}->{'mem'};
    my $mem = $self->{'sysinfo'}->{'mem'} - $self->_get_memory_reserved;
    $mem *= 1024; # mb
    print "available mem (mb): $mem\n" if $self->{'debug'};
    return $mem;
}

# calculate min container size
sub _calc_min_container_size {
    my ($self) = (@_);
    $self->_get_memory_system unless defined $self->{'sysinfo'}->{'mem'};
    my $m = $self->{'sysinfo'}->{'mem'};
    my $m1 = $m < 4 ? 0 : ($m < 8 ? 1 : ($m<24 ? 2 : 3));
    my $m2 = 2 ** $m1;
    my $m3 = 0.25 * $m2 * 1024; # mb
    print "min_container_size (mb): $m3\n" if $self->{'debug'};
    return $m3;
}

sub _calc_container_count {
    my ($self) = (@_);
    my ($cores, $disks);
    my $ratio = $self->_calc_memory_available / $self->_calc_min_container_size;

    $self->_get_cpu_cores unless defined $self->{'sysinfo'}->{'cpu'};
    $cores = 2 * $self->{'sysinfo'}->{'cpu'};

    unless (defined $self->{'sysinfo'}->{'disk'}) { $self->_get_disk_count; }
    $disks = 1.8 * $self->{'sysinfo'}->{'disk'};

    print "cores=$cores disks=$disks ratio=$ratio\n" if $self->{'debug'};
    return int ($self->_minimum($cores, $disks, $ratio));
}

sub _calc_container_memory {
    my ($self) = (@_);
    my $ratio = $self->_calc_memory_available / $self->_calc_container_count;
    my $size  = $self->_calc_min_container_size;
    return int($self->_maximum($size, $ratio));
}

sub memory_config {
    my ($self) = (@_);

    my $con = $self->_calc_container_count;
    my $mpc = $self->_calc_container_memory;

    my $config = {
        'yarn-site.xml' => {
            'yarn.nodemanager.resource.memory-mb' => $con * $mpc,
            'yarn.scheduler.minimum-allocation-mb' => $mpc,
            'yarn.scheduler.maximum-allocation-mb' => $con * $mpc,
            },
        'mapred-site.xml' => {
            'mapreduce.map.memory.mb' => $mpc,
            'mapreduce.reduce.memory.mb' => 2 * $mpc,
            'mapreduce.map.java.opts' => "-Xmx".int(0.8 * $mpc)."m",
            'mapreduce.reduce.java.opts' => "-Xmx".int(0.8 * 2 * $mpc)."m",
            },
        };
    $self->_copyconf ( $config );
}

sub print_config {
    my ($self) = (@_);

    print "min cont size (mb)    : ",$self->_calc_min_container_size,"\n";
    print "num of containers     : ",$self->_calc_container_count,"\n";
    print "mem per container (mb): ",$self->_calc_container_memory,"\n";
    foreach my $k ( keys %{$self->{'sysinfo'}} ) {
        print sprintf "%5s : %s\n", $k, $self->{'sysinfo'}->{$k} 
            if defined $self->{'sysinfo'}->{$k};
    }

    print "---------------\n";
    foreach my $file ( keys %{$self->{'config'}} ) {
        print $file, "\n";
        my $val = $self->{'config'}->{$file};
        foreach my $key ( keys %$val ) {
            print "  ",$key,": ", $val->{$key},"\n";
        }
    }
    print "---------------\n";
}

sub _tag {
    my ($self, %args) = (@_);

    my $header = qq{<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- site-specific property below: -->
};

    my $property = qq{  <property>
    <name>NAME</name>
    <value>VALUE</value>
  </property>
};
    # type = header, config, property
    # (type=config) begin=>1, end=>1
    # (type==property) name=>s value=>s
    #
    for ($args{'type'}) {
        /header/   && do { 
                        return $header; 
                        };
        /config/   && do {
                        my $str;
                        $str .= "<configuration>\n" if defined $args{'begin'};
                        $str .= "</configuration>\n" if defined $args{'end'};
                        return $str;
                        };
        /property/ && do {
                        my $str = $property;
                        $str =~ s/NAME/$args{'name'}/;
                        $str =~ s/VALUE/$args{'value'}/;
                        return $str;
                        };
    }
}
    
sub write_config {
    my ($self, %args) = (@_);
    my $cdir = $args{'confdir'} || $self->{'confdir'};
    
    foreach my $file ( keys %{$self->{'config'}} ) {
        print "-> writing to $cdir/$file ...\n";

        # open conf file
        open CONF, ">".$cdir.'/'.$file or die $!;

        # xml header
        print CONF $self->_tag (type=>'header');
        print CONF $self->_tag (type=>'config', begin=>1);

        # properties
        my $prop = $self->{'config'}->{$file};
        foreach my $key ( keys %{$prop} ) {
            print CONF $self->_tag( type=>'property', name=>$key, value=>$prop->{$key} );
        }

        # close config
        print CONF $self->_tag (type=>'config', end=>1);
        close CONF;
    }
}
#
# ends recommended settings

1;
__END__

=head1 NAME

Apache::Hadoop::Config - Perl extension for Hadoop node configuration

=head1 SYNOPSIS

  use Apache::Hadoop::Config;
  Hadoop configuration setup

Configuration of Apache Hadoop is easy to build a cluster with 
default settings. But those settings are not suitable for a wide
variety of hardware configuration. This perl package proposes
optimal properties for some of the configuration parameters based
on hardware configuration and user requirement.

It is primarily designed to extract hardware configuration from
/proc file system to understand cpu cores, system memory and 
disk layout information. But these parameters can be manually fed
as arguments to generate recommended settings.

This perl package can create namenode and datanode repositories,
set appropriate permissions and generate configuration XML files
with recommended settings.

=head1 DESCRIPTION

Perl extension Apache::Hadoop::Config is designed to address Hadoop 
deployment and configuration practices, enabling rapid 
provisioning of Hadoop cluster with customization. It has two 
distinct capabilities (1) to generate configuration files,
(2) create namenode and datanode repositories.

This package need to be installed ideally on at least one of the 
nodes in the cluster, assuming that all nodes have identical 
hardware configuration. However, this package can be installed 
on any other node and required hardware information can be supplied
using arguments and configuration files can be generated and copied
to actual cluster nodes.

This package is capable of creating repositories for namenode and
datanodes, for which it should be installed on ALL hadoop cluster
nodes.

Create a new Apache::Hadoop::Config object, either using system 
configuration or by supplying from command line arguments.

         my $h = Apache::Hadoop::Config->new; 

Basic configuration and memory settings are available using two
functions. Calling basic configuration function is required while
memory configuration is recommended.

        $h->basic_config;
        $h->memory_config;

The package can print or create XML configuration files independently,
using print and write functions, for configuration. It is necessary
to provide conf directory, writable, to write configuration XML files.

        $h->print_config;
        $h->write_config (confdir=>'etc/hadoop');

Additional configuration parameters can be supplied at the time of
creating the object.

        my $h = Apache::Hadoop::Config->new (
            config=> {
                'mapred-site.xml' => {
                    'mapreduce.task.io.sort.mb' => 256,
                },
                'core-site.xml'   => {
                    'hadoop.tmp.dir' => '/tmp/hadoop',
                },
            },
        );

These parameters will override any automatically generated parameters,
built into this package.

The package creates namenode and datanode volumes along with setting 
permission of hadoop.tmp.dir and log directories. The disk information
can be supplied at object construction time.

        my $h = Apache::Hadoop::Config->new (
            hdfs_name_disks => [ '/hdfs/namedisk1', '/hdfs/namedisk2' ],
            hdfs_data_disks => [ '/hdfs/datadisk1', '/hdfs/datadisk2' ],
            hdfs_tmp        => '/hdfs/tmp',
            hdfs_logdir     => [ '/logs', '/logs/userlog' ],
            );

Note that name disks and data disks accept reference to array type of 
data. The package creates all the namenode and datanode volumes and creates log
and tmp directories.
    
        $h->create_hdfs_name_disks;
        $h->create_hdfs_data_disks;
        $h->create_hdfs_tmpdir;
        $h->create_hadoop_logdir;

The permission will be set as appropriate. It is strongly recommended that
this package and associated script is executed by Hadoop Admin user (hduser).

Some of the basic configuration can be customized externally using 
object arguments. Namenode, secondary namenode, proxy node informations
can be customized. Default is localhost for each of them.

        my $h = Apache::Hadoop::Config->new (
            namenode => 'nn.myorg.com',
            secondary=> 'nn2.myorg.com',
            proxynode=> 'pr.myorg.com',
            proxyport=> '8888', # default, optional
            );

These are optional and required only when secondary namenode and proxy node
are different than primary namenode. 

=head1 EXAMPLES

Below are a few examples of different uses. The first example is to create
recommended configurations for the localhost or command-line provided data:

        #!/usr/bin/perl -w
        use strict;
        use warnings;
        use Apache::Hadoop::Config;
        use Getopt::Long;
        
        my %opts;
        GetOptions (\%opts, 'disks=s','memory=s','cores=s');
        
        my $h = Apache::Hadoop::Config->new (
                meminfo=>$opts{'memory'} || undef,
                cpuinfo=>$opts{'cores'} || undef,
                diskinfo=>$opts{'disks'} || undef,
                );
        
        # setup configs
        $h->basic_config;
        $h->memory_config;
        
        # print and save
        $h->print_config;
        $h->write_config (confdir=>'.');
        
        exit(0);

The above gives an output like below, if no argument is supplied:

        min cont size (mb)    : 256
        num of containers     : 7
        mem per container (mb): 368
         disk : 4
          cpu : 4
          mem : 3.52075958251953
        ---------------
        hdfs-site.xml
          dfs.namenode.secondary.http-address: 0.0.0.0:50090
          dfs.replication: 1
          dfs.datanode.data.dir: file:///hdfs/data1,file:///hdfs/data2,file:///hdfs/data3,file:///hdfs/data4
          dfs.namenode.secondary.https-address: 0.0.0.0:50091
          dfs.namenode.name.dir: file:///hdfs/name1,file:///hdfs/name2
        yarn-site.xml
          yarn.web-proxy.address: localhost:8888
          yarn.nodemanager.aux-services: mapreduce_shuffle
          yarn.scheduler.minimum-allocation-mb: 368
          yarn.scheduler.maximum-allocation-mb: 2576
          yarn.nodemanager.aux-services.mapreduce.shuffle.class: org.apache.hadoop.mapred.ShuffleHandler
          yarn.nodemanager.resource.memory-mb: 2576
        core-site.xml
          hadoop.tmp.dir: /hdfs/tmp
          fs.defaultFS: http://localhost:9000
        mapred-site.xml
          mapreduce.reduce.java.opts: -Xmx588m
          mapreduce.map.memory.mb: 368
          mapreduce.map.java.opts: -Xmx294m
          mapreduce.framework.name: yarn
          mapreduce.reduce.memory.mb: 736
        ---------------
        -> writing to ./hdfs-site.xml ...
        -> writing to ./yarn-site.xml ...
        -> writing to ./core-site.xml ...
        -> writing to ./mapred-site.xml ...

If supplied with some arguments, basically for a different clusters, the configuration files
can still be generated:

        $ perl hadoop_config.pl --cores 16 --memory 64 --disks 6
        min cont size (mb)    : 2048
        num of containers     : 10
        mem per container (mb): 5734
         disk : 6
          cpu : 16
          mem : 64
        ---------------
        hdfs-site.xml
          dfs.namenode.secondary.http-address: 0.0.0.0:50090
          dfs.replication: 1
          dfs.datanode.data.dir: file:///hdfs/data1,file:///hdfs/data2,file:///hdfs/data3,file:///hdfs/data4
          dfs.namenode.secondary.https-address: 0.0.0.0:50091
          dfs.namenode.name.dir: file:///hdfs/name1,file:///hdfs/name2
        yarn-site.xml
          yarn.web-proxy.address: localhost:8888
          yarn.nodemanager.aux-services: mapreduce_shuffle
          yarn.scheduler.minimum-allocation-mb: 5734
          yarn.scheduler.maximum-allocation-mb: 57340
          yarn.nodemanager.aux-services.mapreduce.shuffle.class: org.apache.hadoop.mapred.ShuffleHandler
          yarn.nodemanager.resource.memory-mb: 57340
        core-site.xml
          hadoop.tmp.dir: /hdfs/tmp
          fs.defaultFS: http://localhost:9000
        mapred-site.xml
          mapreduce.reduce.java.opts: -Xmx9174m
          mapreduce.map.memory.mb: 5734
          mapreduce.map.java.opts: -Xmx4587m
          mapreduce.framework.name: yarn
          mapreduce.reduce.memory.mb: 11468
        ---------------
        -> writing to ./hdfs-site.xml ...
        -> writing to ./yarn-site.xml ...
        -> writing to ./core-site.xml ...
        -> writing to ./mapred-site.xml ...

Different customization can be done, using object's constructor arguments. 


=head1 SEE ALSO

hadoop.apache.org - The Hadoop documentation and authoritative source for 
Apache Hadoop and its components.


=head1 AUTHOR

Snehasis Sinha, E<lt>snehasis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Snehasis Sinha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
