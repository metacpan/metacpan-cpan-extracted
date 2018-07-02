package App::JC::Client;
#ABSTRACT: small JIRA command line client
use strict;
use warnings;
use Moose;
use MooseX::App qw(Color BashCompletion);

# the version of the module
our $VERSION = '0.001';




option 'url' => (
                  is => 'rw',
                  isa=>"Str",
                  required=>1,
                  documentation=>"JIRA URL"
                );

option 'user' => (
                  is => 'rw',
                  isa=>"Str",
                  required=>1,
                  documentation=>"JIRA User"
                );

option 'pass' => (
                  is => 'rw',
                  isa=>"Str",
                  required=>1,
                  documentation=>"JIRA Password"
                );


option 'defaulttasktype' => (
                  is => 'rw',
                  isa=>"Str",
                  required=>1,
                  documentation=>"default task type"
                );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JC::Client - small JIRA command line client

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This is a small JIRA REST API command line client written in Perl.

At the moment only listing issues of projects, adding issues to projects, starting an issue
and updating an issues estimated time are available. Further operations will be added in the future.

=head2 Configuration file

A configuration file is supported for all global options. The Config::Any Module is used for
parsing configuration files and you can use any of its supported file formats.

=head3 Example

the config file lies within your home directory: ~/.jc.yaml
In this case the config file is written in yaml.

  ---
  url: https://jirahost/jira/
  user: yourusername
  pass: yourpassword

  default:
          tasktype: Aufgabe

Please make sure the config file is only readable by your user because a password is saved within it.

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
