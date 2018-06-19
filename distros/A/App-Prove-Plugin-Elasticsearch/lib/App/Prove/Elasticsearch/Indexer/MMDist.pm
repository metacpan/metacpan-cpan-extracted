# ABSTRACT: Names your elasticsearch index after your distribution as defined in Makefile.PL
# PODNAME: App::Prove::Elasticsearch::Indexer::MMDist

package App::Prove::Elasticsearch::Indexer::MMDist;
$App::Prove::Elasticsearch::Indexer::MMDist::VERSION = '0.001';
use strict;
use warnings;

use parent qw{App::Prove::Elasticsearch::Indexer};

our $index = __CLASS__->SUPER::index;
our $dfile //= 'Makefile.PL';

if (open(my $dh, '<', $dfile)) {
    ;
    while (<$dh>) {
        ($index) = $_ =~ /DISTNAME.*\s*?=>\s*?["|'](.*)["|'],?/;
        if ($index) {
            $index =~ s/^\s+//;
            last;
        }
    }
    close $dh;
} else {
    print
      "# WARNING: Could not open $dfile, falling back to index name '$index'\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Indexer::MMDist - Names your elasticsearch index after your distribution as defined in Makefile.PL

=head1 VERSION

version 0.001

=head2 GOTCHAS

If dist.ini cannot be found, the index name will fall back to the default indexer's name.

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
