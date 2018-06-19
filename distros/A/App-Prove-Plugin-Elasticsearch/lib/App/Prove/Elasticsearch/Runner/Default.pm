package App::Prove::Elasticsearch::Runner::Default;
$App::Prove::Elasticsearch::Runner::Default::VERSION = '0.001';

# PODNAME: App::Prove::Elasticsearch::Runner::Default;
# ABSTRACT: Run your tests in testd with prove

use strict;
use warnings;

use App::Prove;

sub run {
    my ($config, @tests) = @_;

    my @args = ('-PElasticsearch');
    push(@args, (split(/ /, $config->{'runner.args'})))
      if $config->{'runner.args'};
    push(@args, @tests);
    my $p = App::Prove->new();
    $p->process_args(@args);
    return $p->run();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Runner::Default; - Run your tests in testd with prove

=head1 VERSION

version 0.001

=head1 RATIONALE

Most days you will run tests using 'prove'.
However, there's no reason to restrict this to perl testing,
this framework should work with any kind of testing problem.

Therefore, you get a runner plugin framework, much like the other App::Prove::Elasticsearch* plugins.

=head1 SUBROUTINES

=head2 run($config,@tests)

Runs the provided tests.
It is up to the caller to put rules files and rc files in the right place;
one trick would be to subclass this and dope out $ENV{HOME} temporarily to find the shinies correctly.

Alternatively, you could pass secret information in the elastest configuration to control behavior.
For example, you can set the args= parameter like you would on the command line in the [runner] section.

    [runner]
    args=-j2 -wlvm -Ilib

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
