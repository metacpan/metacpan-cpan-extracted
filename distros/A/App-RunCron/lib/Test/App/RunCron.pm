package Test::App::RunCron;
use strict;
use warnings;
use utf8;

use App::RunCron;
use Test::More ();
use Test::Mock::Guard ();
use YAML::Tiny;

use parent 'Exporter';

our @EXPORT = qw/runcron_yml_ok mock_runcron/;

sub runcron_yml_ok {
    my $yml         = shift || 'runcron.yml';
    my $description = shift || "test of $yml";

    eval {
        my $conf = YAML::Tiny::LoadFile($yml);
        my $obj = App::RunCron->new($conf);

        my @reporters;

        for my $reporter_kind (qw/reporter error_reporter common_reporter/) {
            push @reporters, App::RunCron::_retrieve_plugins($conf->{$reporter_kind}) if $conf->{$reporter_kind};
        }

        for my $r (@reporters) {
            my ($class, $arg) = @$r;
            App::RunCron::_load_class_with_prefix($class, 'App::RunCron::Reporter')->new($arg || ());
        }
    };
    my $err = $@;
    my $BUILDER = Test::More->builder;
    if ($err) {
        $BUILDER->ok(0, $description);
        $BUILDER->diag($err);
    }
    else {
        $BUILDER->ok(1, $description);
    }
}

sub mock_runcron {
    my %args = @_ == 1 ? %{$_[0]} : @_;

    my %mock;
    for my $key (keys %args) {
        $mock{$key} = sub { $args{$key} };
    }
    my $guard = Test::Mock::Guard->new('App::RunCron' => {
        run             => sub { die "can't run mock object" },
        command         => sub { [qw/dummy/] },
        report          => sub { 'mock report' },
        exit_code       => sub { 0 },
        %mock,
    });
    my $mock = App::RunCron->new;
    $mock->{_guard} = $guard;
    $mock;
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::App::RunCron - test framework for App::RunCron

=head1 SYNOPSIS

    use Test::App::RunCron;

    runcron_yml_ok 'runcron.yml';

    my $mock_runcron = mock_runcron;
    eval {
        MyApp::Reporter->new->run($mock_runcron);
    };
    ok !$@, 'my reporter ok';

=head1 DESCRIPTION

Test::App::RunCron is a test framework for App::RunCron

=head1 FUNCTIONS

=head2 C<< runcron_yml_ok($yml_file:Str) >>

Test C<$yml_file> is valid or not.

=head2 C<< $mock_runcron = mock_runcron(%opt) >>

Return mock object of C<App::RunCron>. It is utility for testing your custom RunCron::Reporter.

=head1 SEE ALSO

L<runcron>, L<App::RunCron>

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
