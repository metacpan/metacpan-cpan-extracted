# ABSTRACT: Determine the version of a system under test via environment variable for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Versioner::Env

package App::Prove::Elasticsearch::Versioner::Env;
$App::Prove::Elasticsearch::Versioner::Env::VERSION = '0.001';
use strict;
use warnings;
use utf8;

sub get_version {
    die "TESTSUITE_VERSION not set" unless $ENV{TESTSUITE_VERSION};
    return $ENV{TESTSUITE_VERSION};
}

*get_file_version = \&get_version;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Versioner::Env - Determine the version of a system under test via environment variable for upload to elasticsearch

=head1 VERSION

version 0.001

=head1 SUBROUTINES

=head2 get_version

Reads $ENV{TESTSUITE_VERSION} and returns the version therein.

=head2 get_file_version(file)

Gets the version of a particular file.  Used in versioners where that is possibly the case
such as Git.  In this case it will always be the same as the SUT version.

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
