# ABSTRACT: Determine the platform(s) of the system under test via environment variable for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Platformer::Env

package App::Prove::Elasticsearch::Platformer::Env;
$App::Prove::Elasticsearch::Platformer::Env::VERSION = '0.001';
use strict;
use warnings;
use utf8;

sub get_platforms {
    die "TESTSUITE_PLATFORM not set" unless $ENV{TESTSUITE_PLATFORM};
    my @ret = split(/,/, $ENV{TESTSUITE_PLATFORM});
    return \@ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Platformer::Env - Determine the platform(s) of the system under test via environment variable for upload to elasticsearch

=head1 VERSION

version 0.001

=head1 SUBROUTINES

=head2 get_platforms

Return the OS version and perl version as an array.

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
