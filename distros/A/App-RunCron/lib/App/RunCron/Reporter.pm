package App::RunCron::Reporter;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite (
    new => 1
);
sub run { die '`run` is abstract method' }

1;

__END__

=encoding utf-8

=head1 NAME

App::RunCron::Reporter - base class for reporters of App::RunCron

=head1 SYNOPSIS

    package App::RunCron::Reporter::Blah;
    use parent 'App::RunCron::Reporter';

    sub run {
        my ($self, $runcron) = @_;
        my $report = $runcron->report;
        ...
    }

=head1 DESCRIPTION

App::RunCron::Reporter is a base class for reporters of App::RunCron.

=head2 INTERFACE

Supporting duck typing so, Reporter classes not need to be inherited L<App::RunCron::Reporter>.
Only two methods should be implemented.

=head3 C<< my $reporter = $class->new($args:HashRef) >>

Constructor method.

=head3 C<< $reporter->run($runcron:App::RunCron) >>

Main process of reporter which accepts L<App::RunCron> object.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
