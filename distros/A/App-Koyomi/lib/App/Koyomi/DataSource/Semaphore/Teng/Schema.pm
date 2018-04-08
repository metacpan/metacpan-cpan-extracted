package App::Koyomi::DataSource::Semaphore::Teng::Schema;

use strict;
use warnings;
use 5.010_001;
use Teng::Schema::Declare;

use version; our $VERSION = 'v0.6.1';

table {
    name    'semaphores';
    pk      'job_id';
    columns qw/job_id number run_host run_pid created_on run_date updated_at/;
};

1;
__END__

=encoding utf-8

=head1 NAME

App::Koyomi::DataSource::Semaphore::Teng::Schema - Teng::Schema class for semaphore datasource

=head1 SYNOPSIS

    use App::Koyomi::DataSource::Semaphore::Teng::Schema;
    my $schema = App::Koyomi::DataSource::Semaphore::Teng::Schema->instance;

=head1 DESCRIPTION

Teng::Schema class for semaphore datasource.

=head1 SEE ALSO

L<App::Koyomi::DataSource::Semaphore::Teng>,
L<Teng::Schema>

=head1 AUTHORS

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015-2017 IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

