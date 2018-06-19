# ABSTRACT: Determine the responsible party for tests via environment variable for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Env

package App::Prove::Elasticsearch::Blamer::Env;
$App::Prove::Elasticsearch::Blamer::Env::VERSION = '0.001';
use strict;
use warnings;
use utf8;

sub get_responsible_party {
    die "TESTSUITE_EXECUTOR not set" unless $ENV{TESTSUITE_EXECUTOR};
    return $ENV{TESTSUITE_EXECUTOR};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Blamer::Env - Determine the responsible party for tests via environment variable for upload to elasticsearch

=head1 VERSION

version 0.001

=head1 SUBROUTINES

=head2 get_responsible_party

Get the responsible party from $ENV{TESTSUITE_EXECUTOR}

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
