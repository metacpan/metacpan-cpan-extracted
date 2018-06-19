# ABSTRACT: Determine the responsible party for tests via git for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Git

package App::Prove::Elasticsearch::Blamer::Git;
$App::Prove::Elasticsearch::Blamer::Git::VERSION = '0.001';
use strict;
use warnings;
use utf8;

use Git;

sub get_responsible_party {
    my $email = Git::command_oneline('config', 'user.email');
    chomp $email;
    return $email;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Blamer::Git - Determine the responsible party for tests via git for upload to elasticsearch

=head1 VERSION

version 0.001

=head1 SUBROUTINES

=head2 get_responsible_party

Get the responsible party from the author.email in git-config

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
