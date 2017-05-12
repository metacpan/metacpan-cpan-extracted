package App::Koyomi::DataSource::Job::Teng::Schema;

use strict;
use warnings;
use 5.010_001;
use Teng::Schema::Declare;

use App::Koyomi::Job;

use version; our $VERSION = 'v0.6.0';

table {
    name    'jobs';
    pk      'id';
    columns @App::Koyomi::Job::JOB_FIELDS;
};

table {
    name    'job_times';
    pk      'id';
    columns @App::Koyomi::Job::TIME_FIELDS;
};

1;
__END__

=encoding utf-8

=head1 NAME

App::Koyomi::DataSource::Job::Teng::Schema - Teng::Schema class for job datasource

=head1 SYNOPSIS

    use App::Koyomi::DataSource::Job::Teng::Schema;
    my $schema = App::Koyomi::DataSource::Job::Teng::Schema->instance;

=head1 DESCRIPTION

Teng::Schema class for job datasource.

=head1 SEE ALSO

L<App::Koyomi::DataSource::Job::Teng>,
L<Teng::Schema>

=head1 AUTHORS

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

