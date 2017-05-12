package App::Presto::PrettyPrinter;
our $AUTHORITY = 'cpan:MPERRY';
$App::Presto::PrettyPrinter::VERSION = '0.010';
# ABSTRACT: abstracted pretty-printer support

use strict;
use warnings;
use Moo;

my %PRETTY_PRINTERS = (
    'Data::Dump' => sub {
        require Data::Dump;
        return Data::Dump::dump(shift) . "\n";
    },
    'Data::Dumper' => sub {
        require Data::Dumper;
        no warnings 'once';
        local $Data::Dumper::Sortkeys = 1;
        return Data::Dumper::Dumper(shift);
    },
    'JSON' => sub { require JSON; return JSON->new->pretty->encode(shift) },
    'YAML' => sub { require YAML; return YAML::Dump(shift) },
);

has config => (
    is => 'lazy',
);
sub _build_config {
    return App::Presto->instance->config;
}

sub pretty_print {
    my $self = shift;
    my $data = shift;
    my $driver = $self->config->get('pretty_printer');
    my $printer = $PRETTY_PRINTERS{$driver} || $PRETTY_PRINTERS{'Data::Dumper'};
    return $printer->($data);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Presto::PrettyPrinter - abstracted pretty-printer support

=head1 VERSION

version 0.010

=head1 AUTHORS

=over 4

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Matt Perry <matt@mattperry.com> (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brian Phillips and Shutterstock Images (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
