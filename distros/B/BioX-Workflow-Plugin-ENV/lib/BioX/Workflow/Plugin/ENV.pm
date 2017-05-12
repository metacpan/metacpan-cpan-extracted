package BioX::Workflow::Plugin::ENV;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use Data::Dumper;
use Data::Pairs;

use Moose::Role;

before 'write_process' => sub {
    my $self = shift;

    $DB::single=2;
    my $tmp = "EXPORT SAMPLE={\$sample} && \\\n";
    $DB::single=2;
    my $newprocess = $tmp.$self->process;
    $self->process($newprocess);
};

1;
__END__

=encoding utf-8

=head1 NAME

BioX::Workflow::Plugin::ENV - Export SAMPLE to ENV

=head1 SYNOPSIS

    plugins:
        - ENV
    global:
        - thing1: thing2

=head1 DESCRIPTION

BioX::Workflow::Plugin::ENV is a simple plugin to export your Sample name to your environment

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2015- Jillian Rowe

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
