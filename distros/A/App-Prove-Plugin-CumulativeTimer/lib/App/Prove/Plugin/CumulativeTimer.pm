package App::Prove::Plugin::CumulativeTimer;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Class::Method::Modifiers qw( around );
use TAP::Parser;
use TAP::Formatter::Session;

sub load {
    my ( $class, $p ) = @_;

    $p->{app_prove}->timer(1);

    my $first_start_time;
    my $first_start_times;
    around 'TAP::Formatter::Session::time_report' => sub {
        my $orig = shift;
        my ( $self, $formatter, $parser ) = @_;
        $first_start_time  ||= $parser->start_time;
        $first_start_times ||= $parser->start_times;
        no warnings 'redefine';
        local *TAP::Parser::start_time  = sub {$first_start_time};
        local *TAP::Parser::start_times = sub {$first_start_times};
        return $orig->(@_);
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Prove::Plugin::CumulativeTimer - A prove plugin to display cumulative elapsed time of tests.

=head1 SYNOPSIS

    $ prove -PCumulativeTimer tests

    # [14:22:52] tests/test1.t .. ok     2052 ms ( 0.00 usr  0.00 sys +  0.04 cusr  0.01 csys =  0.05 CPU)
    # [14:22:54] tests/test2.t .. ok     2111 ms ( 0.01 usr  0.00 sys +  0.08 cusr  0.02 csys =  0.11 CPU)

    # When you don't use this plugin, elapsed time of tests/tes2.t is not cumulative.
    $ prove --timer tests

    # [14:22:31] tests/test1.t .. ok     2049 ms ( 0.00 usr  0.00 sys +  0.04 cusr  0.01 csys =  0.05 CPU)
    # [14:22:33] tests/test2.t .. ok       60 ms ( 0.01 usr  0.00 sys +  0.05 cusr  0.01 csys =  0.07 CPU)

=head1 DESCRIPTION

App::Prove::Plugin::CumulativeTimer is a prove plugin to display cumulative elapsed time of tests.

This plugin replaces elaped time of --timer option with cumulative elapsed time.

--timer option is always set when you load this plugin.

=head1 LICENSE

Copyright (C) Masahiro Iuchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Iuchi E<lt>masahiro.iuchi@gmail.comE<gt>

=cut

