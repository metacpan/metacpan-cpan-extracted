# ABSTRACT: Determine the responsible party for tests via system user & hostname for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Env

package App::Prove::Elasticsearch::Blamer::System;
$App::Prove::Elasticsearch::Blamer::System::VERSION = '0.001';
use strict;
use warnings;
use utf8;

use System::Info;

sub get_responsible_party {
    my $info = System::Info->sysinfo_hash();
    return _get_uname() . '@' . $info->{hostname};
}

sub _get_uname {
    my @pw_info = getpwuid($<);
    return $pw_info[0];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Blamer::Env - Determine the responsible party for tests via system user & hostname for upload to elasticsearch

=head1 VERSION

version 0.001

=head1 SUBROUTINES

=head2 get_responsible_party

Get the responsible party as your system user @ hostname.

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
