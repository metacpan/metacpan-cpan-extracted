package App::ape;
$App::ape::VERSION = '0.001';

# PODNAME: App::ape
# ABSTRACT: Implements the `ape` binary

use strict;
use warnings;

use Pod::Usage;

use App::ape::test;
use App::ape::plan;
use App::ape::update;

sub new {
    my (undef, @args) = @_;
    my $command = shift @args;

    #I am being sneaky here and using bin/ape's POD
    return pod2usage(0) unless grep { $_ eq $command } qw{plan test update};

    my $program          = "App::ape::$command";
    my $program_perlized = "$program.pm";
    $program_perlized =~ s/::/\//g;
    $0 = $INC{$program_perlized};

    return $program->new(@args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ape - Implements the `ape` binary

=head1 VERSION

version 0.001

=head1 CONSTRUCTOR

=head2 new

Routes requests to the appropriate subcommand and sets $0 appropriately.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://https://github.com/teodesian/App-Prove-Elasticsearch>
and may be cloned from L<git://https://github.com/teodesian/App-Prove-Elasticsearch.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
