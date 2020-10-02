# Container-Buildah
![Container::Buildah](container-buildah-logo.png "Container::Buildah")
Container::Buildah Perl module for building OCI/Docker-compatible Linux containers

CPAN: [https://metacpan.org/pod/Container::Buildah](https://metacpan.org/pod/Container::Buildah)

# NAME

Container::Buildah - wrapper around containers/buildah tool for multi-stage builds of OCI/Docker-compatible Linux containers

# VERSION

version 0.3.0

# SYNOPSIS

    use <Container::Buildah>;

        # configure container build stages
        Container::Buildah::init_config(
                basename => "swpkg",
                base_image => 'docker://docker.io/alpine:[% alpine_version %]',
                stages => {
                        build => {
                                from => "[% base_image %]",
                                func_exec => \&stage_build,
                                produces => [qw(/opt/swpkg-apk)],
                        },
                        runtime => {
                                from => "[% base_image %]",
                                consumes => [qw(build)],
                                func_exec => \&stage_runtime,
                                commit => ["[% basename %]:[% swpkg_version %]", "[% basename %]:latest"],
                        }
                },
                swpkg_version => "9.16.4",
        );

        # functions to run each stage inside their container namespaces
        sub stage_build {
                my $stage = shift;
                # code to run inside the namespace of the build container
                # set up build container and copy newly-built Alpine APK packages into /opt/swpkg-apk ...
                # See Container::Buildah:Stage for the object passed to each stage function
        }
        sub stage_runtime {
                my $stage = shift;
                # code to run inside the namespace of the runtime container
                # set up runtime container including installing Alpine APK packages from /opt/swpkg-apk ...
                # See Container::Buildah:Stage for the object passed to each stage function
        }

        # Container::Buildah::main serves as script mainline including processing command-line arguments
        Container::Buildah::main(); # run all the container stages

# DESCRIPTION

**Container::Buildah** allows Perl scripts to build OCI/Docker-compatible container images using the Open Source
_buildah_ command. Containers may be pipelined so the product of a build stage is consumed by one or more others.

The **Container::Buildah** module grew out of a wrapper script to run code inside the user namespace of a
container under construction. That remains the core of its purpose. It simplifies rootless builds of containers.

**Container::Buildah** may be used to write a script to configure container build stages.
The configuration of each build stage contains a reference to a callback function which will run inside the
user namespace of the container in order to build it.
The function is analagous to a Dockerfile, except that it's programmable with access to computation and the system.

The _buildah_ command has subcommands equivalent to Dockerfile directives.
For each stage of a container build, **Container::Buildah** creates a **Container::Buildah::Stage** object
and passes it to the callback function for that stage.
There are wrapper methods in **Container::Buildah::Stage** for
subcommands of buildah which take a container name as a parameter.

The **Container::Buildah** module has one singleton instance per program.
It contains configuration data for a container build process.
The data is similar to what would be in a Dockerfile, except this module makes it scriptable.

# METHODS

## status

prints a list of strings to STDERR, if debugging is set to level 1 or higher.

## debug

Prints a list of strings to STDERR, if debugging is at the specified level.
If the first argument is a HASH reference, it is used for key/value parameters.
The recognized parameters are
&#x3d;over
&#x3d;item "name" for the name of the caller function, defaults to the name from the Perl call stack
&#x3d;item "level" for the minimum debugging level to print the message
&#x3d;item "label" for an additional label string to enclose in brackets, such as a container name
&#x3d;back

## get\_config

## required\_config

## get\_debug

Return integer value of debug level

## set\_debug

Take an integer value parameter to set the debug level. A level of 0 means debugging is turned off. The default is 0.

## main

## prog

## cmd

## buildah

## bud

## containers

## from

## images

## info

## inspect

## mount

## pull

## push

## rename

## rm

## rmi

## tag

## umount

## unshare

## version

# FUNCTIONS

## init\_config

# FUNCTIONS AND METHODS

## Container::Buildah core functions and methods

## methods provided by Container::Buildah::Subcommand

# BUGS AND LIMITATIONS

Please report bugs via GitHub at [https://github.com/ikluft/Container-Buildah/issues](https://github.com/ikluft/Container-Buildah/issues)

Patches and enhancements may be submitted via a pull request at [https://github.com/ikluft/Container-Buildah/pulls](https://github.com/ikluft/Container-Buildah/pulls)

Containers can only be run with a Linux kernel revision 2.8 or newer.

# AUTHOR

Ian Kluft &lt;https://github.com/ikluft>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Ian Kluft.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004

