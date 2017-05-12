package App::Koyomi::DataSource::Job::Teng::Object;

use strict;
use warnings;
use 5.010_001;

use parent qw(Teng);

use version; our $VERSION = 'v0.6.0';

1;
__END__

=encoding utf-8

=head1 NAME

App::Koyomi::DataSource::Job::Teng::Object - Teng's subclass for job datasource

=head1 SYNOPSIS

    use App::Koyomi::DataSource::Job::Teng::Object;
    my $teng = App::Koyomi::DataSource::Job::Teng::Object->new(%args);

=head1 DESCRIPTION

Teng's subclass for job datasource.

=head1 SEE ALSO

L<App::Koyomi::DataSource::Job::Teng>,
L<Teng>

=head1 AUTHORS

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

