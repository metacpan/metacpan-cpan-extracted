# ABSTRACT: App Module ad utilities for appspec tool
use strict;
use warnings;
use 5.010;
use utf8;
package App::AppSpec;
use Term::ANSIColor;
use File::Basename qw/ dirname /;

our $VERSION = '0.002'; # VERSION

use base 'App::Spec::Run::Cmd';

sub _read_spec {
    my ($self, $run) = @_;
    my $parameters = $run->parameters;

    my $spec_file = $parameters->{spec_file};
    my $spec = App::Spec->read($spec_file);
    return $spec;
}

sub cmd_completion {
    my ($self, $run) = @_;
    my $options = $run->options;
    my $parameters = $run->parameters;

    my $shell = $options->{zsh} ? "zsh" : $options->{bash} ? "bash" : '';
    die "Specify which shell" unless $shell;

    my $spec = $self->_read_spec($run);
    my $completion = $spec->generate_completion(
        shell => $shell,
    );
    say $completion;
}

sub generate_pod {
    my ($self, $run) = @_;
    my $parameters = $run->parameters;

    my $spec = $self->_read_spec($run);
    my $pod = $spec->generate_pod(
    );
    say $pod;
}

sub cmd_validate {
    my ($self, $run) = @_;
    my $options = $run->options;
    my $parameters = $run->parameters;
    my $color = $self->colorize;

    my @errors;
    require App::AppSpec::Schema::Validator;
    my $validator = App::AppSpec::Schema::Validator->new;
    my $spec_file = $parameters->{spec_file};
    if (ref $spec_file eq 'SCALAR') {
        my $spec = YAML::XS::Load($$spec_file);
        @errors = $validator->validate_spec($spec);
    }
    else {
        @errors = $validator->validate_spec_file($spec_file);
    }
    binmode STDOUT, ":encoding(utf-8)";
    if (@errors) {
        print $validator->format_errors(\@errors);
        $color and print color 'red';
        say "Not valid!";
        $color and print color 'reset';
    }
    else {
        $color and print color 'bold green';
        say "Validated ✓";
        $color and print color 'reset';
    }
}

sub cmd_new {
    my ($self, $run) = @_;
    my $options = $run->options;
    my $params = $run->parameters;
    my $dist_path = $params->{path};
    require File::Path;

    my $name = $options->{name};
    my $class = $options->{class};
    my $overwrite = $options->{overwrite};
    unless ($name =~ m/^\w[\w+-]*/) {
        die "Option name '$name': invalid app name";
    }
    unless ($class =~ m/^[a-zA-Z]\w*(::\w+)+$/) {
        die "Option class '$class': invalid classname";
    }
    my $dist = $class;
    $dist =~ s/::/-/g;
    $dist = $dist_path // $dist;
    if (-d $dist and not $overwrite) {
        die "Directory $dist already exists";
    }
    elsif (-d $dist) {
        say "Removing old $dist directory first";
        File::Path::remove_tree($dist);
    }
    my $spec = <<"EOM";
name: $name
appspec: { version: '0.001' }
class: $class
title: 'app title'
description: 'app description'
options:
- name: "some-option"
  type: "flag"
  summary: "option summary"
EOM
    my $module = <<"EOM";
package $class;
use strict;
use warnings;
use feature qw/ say /;
use base 'App::Spec::Run::Cmd';

sub mycommand \{
    my (\$self, \$run) = \@_;
    my \$options = \$run->options;
    my \$parameters = \$run->parameters;

    say "Hello world";
\}

1;
EOM
    my $script = <<"EOM";
#!/usr/bin/env perl
use strict;
use warnings;

use App::Spec;
use App::AppSpec;
use $class;
use File::Share qw/ dist_file /;

my \$specfile = dist_file("$dist", "$name-spec.yaml");
my \$spec = App::Spec->read(\$specfile);
my \$run = \$spec->runner;
\$run->run;
EOM
    if ($options->{"with-subcommands"}) {
            $spec .= <<"EOM";
subcommands:
    mycommand:
      summary: "Summary for mycommand"
      op: "mycommand"
      description: "Description for mycommand"
      parameters:
      - name: "myparam"
        summary: "Summary for myparam"
        required: 1
EOM
    }
    my $module_path = $class;
    $module_path =~ s#::#/#g;
    $module_path = "$dist/lib/$module_path.pm";
    File::Path::make_path($dist);
    File::Path::make_path("$dist/share");
    File::Path::make_path("$dist/bin");
    File::Path::make_path(dirname $module_path);
    my $specfile = "$dist/share/$name-spec.yaml";
    say "Writig spec to $specfile";
    open my $fh, ">", $specfile or die $!;
    print $fh $spec;
    close $fh;

    open $fh, ">", $module_path or die $!;
    print $fh $module;
    close $fh;

    open $fh, ">", "$dist/bin/$name" or die $!;
    print $fh $script;
    close $fh;
}

=pod

=head1 NAME

App::AppSpec - Utilities for App::Spec authors

=head1 SYNOPSIS

See L<appspec> documentation for the command line utility.

=head1 DESCRIPTION

This is the app class for the L<appspec> command line tool.
It contains utilities for L<App::Spec> files, like generating
completion or pod from it.

=head1 METHODS

=over 4

=item cmd_completion, cmd_new, cmd_validate, generate_pod

=back

=cut

1;
