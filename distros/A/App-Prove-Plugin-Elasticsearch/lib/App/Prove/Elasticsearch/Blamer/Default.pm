# ABSTRACT: Determine the responsible for tests via Changes file for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Default

package App::Prove::Elasticsearch::Blamer::Default;
$App::Prove::Elasticsearch::Blamer::Default::VERSION = '0.001';
use strict;
use warnings;
use utf8;

use File::Basename qw{dirname};
use Cwd qw{abs_path};

our $party = {};

sub get_responsible_party {
    my $loc = abs_path(dirname(shift) . "/../Changes");

    return $party->{$loc} if $party->{$loc};
    my $ret;
    open(my $fh, '<', $loc) or die "Could not open $loc";
    while (<$fh>) {
        ($ret) = $_ =~ m/\s*\w*\s*(\w*)$/;
        last if $ret;
    }
    close $fh;
    die 'Could not determine the latest version from Changes!' unless $ret;
    $party->{$loc} = $ret;
    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Blamer::Default - Determine the responsible for tests via Changes file for upload to elasticsearch

=head1 VERSION

version 0.001

=head1 SUBROUTINES

=head2 get_responsible_party

Get the responsible party from Changes

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
