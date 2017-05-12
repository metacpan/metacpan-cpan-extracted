# NAME

ec2-cssh - Cluster SSH your EC2 instances

# INSTALLATION

This is a standard Perl package.

On system Perl:

    cpan -i App::EC2Cssh

With cpanm:

    cpanm App::EC2Cssh

# SYNOPSIS

Cssh using a predefined set called 'frontend' in your config file (see CONFIGURATION section):

    ec2-ssh -s=frontends

    ec2-ssh -s=frontends --demux 'ssh user@{$host} tail -f /var/log/syslog'

# OPTIONS

- --set=&lt;name>, -s=&lt;name>

    **Required.** Use the set &lt;name> of instances defined in your config file

- --demux &lt;command>

    Optional. Use this command and demux their output to the shell instead of launching a cssh interactive session.

- --verbose, -v

    Go in verbose mode

- --config=&lt;config file>, -c=&lt;config file>

    Use the config file instead of the automatically detected one (see CONFIGURATION section)

- --help, -h

    Display this help.

# CONFIGURATION

ec2-cssh relies on a configuration files to hold your Amazon AWS EC2 settings, your machine set settings
and the command line to use to ClusterSSH onto your machines.

If no --config option is given, ec2-cssh will look for the following files in order: **.ec2cssh.conf**, **$HOME/.ec2cssh.conf**, **/etc/ec2cssh.conf**

## Linux Config example:

In this example, only one instances set 'mytagvalue' defined. This
set will generate all the instances with a tag 'mytag' having a value 'myvalue'

    {
       'ec2_config' => {
           AWSAccessKeyId => '.. Your access Key ID ..',
           SecretAccessKey => '.. Your secret access Key ..',
           region => 'eu-west-1',
           debug => 0,
       },
       'ec2_sets' => {
           'mytagvalue' => {
               'Filter' =>  [
                   [ 'tag:mytag' , 'myvalue' ],
               ]
           }
       },
       'command' => q|cssh { join(' ' , map{ '<your username>@'.$_.':22' }  @hosts ) }|
     }

Then you can do:

    $ ec2-ssh -s=mytagvalue

## OSX Config example:

Only the command changes. See Section 'INSTALLING cssh' for more help on
CsshX for Mac OSX.

    {
       .. Same a Linux. Only this changes: ..
       'command' => q|csshX --screen 1 { join(' ' , map{ '<your username>@'.$_.':22' }  @hosts ) }|
    }

# INSTANCES SET CONFIGURATION

The format of a set configuration follows the following structure:

    'set' => {
       InstanceId => [ 'instanceID1' , 'instanceID2', ... ],
       Filters => [
          [ 'Filter name', 'Filter value1' , 'Filter value 2', ... ],
          .. Other filters ..
       ]
     }

Both InstanceID and Filters are optional.

See [http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeInstances.html](http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeInstances.html) for all available
ways of filtering instances.

## SPLIT CONFIGURATION

Having a config file is fine, but what if you want to keep your credentials secret, and have
your EC2 sets of machine in a .ec2cssh.conf file per projects?

With ec2-cssh, this is possible by splitting the configuration in severl files.
For instance, you can have:

- .ec2cssh.conf in your project directory:

        {
           'ec2_config' => { region => 'project-specific-aws-region' },
           'ec2_sets' => { 'projectspecificset' => ... },
        }

- $HOME/.ec2cssh.conf:

        {
           'ec2_config' => { .. Your credentials },
           'ec2_sets' => { 'asetilike' => ... }
        }

- /etc/ec2cssh.conf:

        {
          ec2_sets => { 'asystemwideset' => .. }
          command => '.. System wide Cssh command ..'
        }

## INSTALLING cssh

### To install cssh on Linux (Debian):

    sudo  apt-get install clusterssh

TROUBLESHOOTING

If you run system cssh on linux and you have installed this under perlbrew, it is likely you
will run into issues running cssh. This is because cssh is implemented in Perl and even though
it's installed at system level, it will try to lookup its packages in your perlbrew current
environment. The easiest way to work around that is to also install cssh in your current perlbrew.

To do that, run: `cpanm App::ClusterSSH@4.03_06` (for the latest version)

### To install CsshX for Mac OSX:

    brew install csshx

# ABOUT

This code is released under the same licence as Perl5 itself.

Copyright Jerome Eteve (jerome@eteve.net) 2015.

# SEE ALSO

Cluster SSH (Linux) Homepage: [https://github.com/duncs/clusterssh/wiki](https://github.com/duncs/clusterssh/wiki)

CsshX (Mac OSX) Homepage: [https://github.com/brockgr/csshx](https://github.com/brockgr/csshx)
