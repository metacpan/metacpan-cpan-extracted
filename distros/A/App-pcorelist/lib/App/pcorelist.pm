# ABSTRACT: Wrapper around corelist with subcommands and tab completion
use strict;
use warnings;
package App::pcorelist;

our $VERSION = '0.001'; # VERSION

use 5.010;

use base 'App::Spec::Run::Cmd';
use Text::Table;
use File::Share qw/ dist_dir dist_file /;

sub module {
    my ($self, $run) = @_;
    my $options = $run->options;
    my $param = $run->parameters;

    my @cmd = qw/ corelist /;
    if ($options->{all}) {
        push @cmd, "-a";
    }
    if ($options->{date}) {
        push @cmd, "-d";
    }
    push @cmd, $param->{module};
    system(@cmd);
}

sub perl {
    my ($self, $run) = @_;
    if ($run->options->{release}) {
        my @cmd = qw/ corelist -r /;
        my @out = qx{@cmd};
        shift @out;
        shift @out;
        if ($run->options->{raw}) {
            @out = map {
                (split ' ', $_)[1] . "\n"
            } @out;
        }
        say @out;
        return;
    }
    my @cmd = qw/ corelist -v /;
    if ($run->options->{raw}) {
        my @out = qx{@cmd};
        shift @out;
        shift @out;
        say @out;
    }
    else {
        system(@cmd);
    }
}

sub diff {
    my ($self, $run) = @_;
    my $options = $run->options;
    my $param = $run->parameters;

    my @cmd = (qw/ corelist --diff /, $param->{perl1}, $param->{perl2});
    chomp(my @out = qx{@cmd});
    my @result;
    if ($options->{added} or $options->{removed}) {
        for my $line (@out) {
            my ($mod, $v1, $v2) = split ' ', $line;
            if ($options->{added} and $v1 =~ m/absent/) {
                push @result, $line;
            }
            if ($options->{removed} and $v2 =~ m/absent/) {
                push @result, $line;
            }
        }
    }
    else {
        @result = @out;
    }
    for my $item (@result) {
        my ($mod, $v1, $v2) = split ' ', $item;
        if ($v1 =~ m/absent/) {
            say $run->colored(out => ['green'], $item);
        }
        elsif ($v2 =~ m/absent/) {
            say $run->colored(out => ['red'], $item);
        }
        else {
            say $item;
        }
    }
}

sub features {
    my ($self, $run) = @_;
    my $param = $run->parameters;

    no warnings 'once';
    require feature;
    my $param_feature = $param->{feature};

    my %feature2version;
    my @bundles = map { $_->[0] }
                  sort { $b->[1] <=> $a->[1] }
                  map { [$_, _numify_version($_)] }
                  grep { not /[^0-9.]/ }
                  keys %feature::feature_bundle;
    for my $version (@bundles) {
        my $f = $feature::feature_bundle{$version};
        $feature2version{$_} = $version =~ /^\d\.\d+$/ ? "$version.0" : $version
            for @$f;
    }
    my @features = sort keys %feature2version;

    # allow internal feature names, just in case someone gives us __SUB__
    # instead of current_sub.
    while (my ($name, $internal) = each %feature::feature) {
        $internal =~ s/^feature_//;
        $feature2version{$internal} = $feature2version{$name}
            if $feature2version{$name};
    }

    if (@$param_feature) {
        for my $feature (@$param_feature) {
            if ($feature2version{ $feature }) {
                say sprintf "feature '%s' was first released with the perl"
                    . " %s feature bundle",
                    $feature, $feature2version{ $feature };
            }
            else {
                say sprintf "feature '%s' doesn't exist (or so I think)",
                    $feature;
            }
        }
    }
    else {
        if ($run->options->{raw}) {
            say for @features;
        }
        else {
            my $tb = Text::Table->new;
            for my $f (@features) {
                $tb->add($f, $feature2version{ $f });
            }
            say $tb;
        }
    }
}

sub _numify_version {
    my $ver = shift;
    if ($ver =~ /\..+\./) {
        $ver = version->new($ver)->numify;
    }
    $ver += 0;
    return $ver;
}

sub modules {
    my ($self, $run) = @_;

    my %modules;
    require Module::CoreList;
    for my $v (keys %Module::CoreList::delta) {
        my $changes = $Module::CoreList::delta{ $v };
        my $changed = $changes->{changed};
        my $removed = $changes->{removed};
        @modules{ (keys %$changed), (keys %$removed) } = ();
    }
    say for sort keys %modules;
}

sub completion_dir {
    my $sharedir = dist_dir('App-pcorelist');
    my $completion_dir = dist_file("App-pcorelist", 'completion');
    printf +("%-21s: %30s\n" x 4),
        'Shared directory', $sharedir,
        'Completion directory', $completion_dir,
        'zsh completion', "$completion_dir/zsh/_pcorelist",
        'bash completion', "$completion_dir/bash/pcorelist.bash";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::pcorelist - Wrapper around corelist with subcommands and tab completion

=head1 SYNOPSIS

See L<pcorelist> for usage.

=head1 DESCRIPTION

See L<pcorelist>.

=head1 METHODS

=over

=item completion_dir, diff, features, module, modules, perl

These are the methods that are called by C<pcorelist subcommand>.

See L<pcorelist>.

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2019 by Tina Müller

This library is free software and may be distributed under the same terms
as perl itself.

=cut
