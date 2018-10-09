package App::BitBucketCli::Command::Projects;

# Created on: 2018-06-07 08:23:20
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

extends 'App::BitBucketCli';

our $VERSION = 0.006;

sub options {
    return [qw/
        colors|c=s%
        force|f!
        long|l
        project|p=s
        regexp|R
        remote|m=s
        repository|r=s
        sleep|s=i
    /]
}

sub projects {
    my ($self) = @_;

    my @projects = sort {
            lc $a->name cmp lc $b->name;
        }
        $self->core->projects();

    my %len;
    for my $project (@projects) {
        $len{name} = length $project->name if !$len{name} || $len{name} < length $project->name;
        $len{key} = length $project->key if !$len{key} || $len{key} < length $project->key;
    }
    for my $project (@projects) {
        if ( $self->opt->long ) {
            my $desc = $project->description || '';
            if ( $desc ) {
                $desc =~ s/^\s+//xms;

                $desc = join "\n" . ' ' x ( $len{name} + $len{key} + 2 ),
                    split /\r?\n/, $desc;
            }

            printf "%-$len{name}s %-$len{key}s %s\n", $project->name, $project->key, $desc;
        }
        else {
            print $project->name . "\n";
        }
    }
}

1;

__END__

=head1 NAME

App::BitBucketCli::Command::Projects - Show the projects in the BitBucket Server

=head1 VERSION

This documentation refers to App::BitBucketCli::Command::Projects version 0.006

=head1 SYNOPSIS

   bb-cli projects [options]

 OPTIONS:
  -c --colors[=]str Change colours used specified as key=value
                    eg --colors disabled=grey22
                    current colour names aborted, disabled and notbuilt
  -f --force        Force action
  -l --long         Show long form data if possible
  -p --project[=]str
                    For commands that need a project name this is the name to use
  -R --recipient[=]str
                    ??
  -R --regexp[=]str ??
  -m --remote[=]str ??
  -r --repository[=]str
                    For commands that work on repositories this contains the repository
  -s --sleep[=]seconds
                    ??
  -t --test         ??

 CONFIGURATION:
  -h --host[=]str   Specify the Stash/Bitbucket Servier host name
  -P --password[=]str
                    The password to connect to the server as
  -u --username[=]str
                    The username to connect to the server as

  -v --verbose       Show more detailed option
     --version       Prints the version information
     --help          Prints this help information
     --man           Prints the full documentation for bb-cli

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<options ()>

Returns the command line options

=head2 C<projects ()>

Processes the projects subcommand.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
