# ABSTRACT: Determine the version of a system under test via the module's Changes file for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Versioner::Default

package App::Prove::Elasticsearch::Versioner::Default;
$App::Prove::Elasticsearch::Versioner::Default::VERSION = '0.001';
use strict;
use warnings;
use utf8;

use File::Basename qw{dirname};
use Cwd qw{abs_path};

our $version = {};

sub get_version {
    my $loc = abs_path(dirname(shift) . "/../Changes");

    return $version->{$loc} if $version->{$loc};
    my $ret;
    open(my $fh, '<', $loc) or die "Could not open Changes in $loc";
    while (<$fh>) {
        ($ret) = $_ =~ m/(^\S*)/;
        last if $ret;
    }
    close $fh;
    die 'Could not determine the latest version from Changes!' unless $ret;
    $version->{$loc} = $ret;
    return $ret;
}

*get_file_version = \&get_version;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Versioner::Default - Determine the version of a system under test via the module's Changes file for upload to elasticsearch

=head1 VERSION

version 0.001

=head1 SUBROUTINES

=head2 get_version

Reads Changes and returns the version therein.

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
