# ABSTRACT: Determine the version of a system under test via git for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Versioner::Git

package App::Prove::Elasticsearch::Versioner::Git;
$App::Prove::Elasticsearch::Versioner::Git::VERSION = '0.001';
use strict;
use warnings;
use utf8;

use Git;

sub get_version {
    my $out = Git::command_oneline('log', '--format=format:%H');
    my @shas = split(/\n/, $out);
    return shift(@shas);
}

sub get_file_version {
    my $input = shift;
    my $out =
      Git::command_oneline('log', '--format=format:%H', '--follow', $input);
    my @shas = split(/\n/, $out);
    return shift(@shas);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Versioner::Git - Determine the version of a system under test via git for upload to elasticsearch

=head1 VERSION

version 0.001

=head1 SUBROUTINES

=head2 get_version

Reads your git log and returns the current SHA as the version.

=head2 get_file_version(file)

Rather than getting the version of the software under test, get the version of a specific file.
Used to discover the version of a test being run for feeding into the indexer.

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
