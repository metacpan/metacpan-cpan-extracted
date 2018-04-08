package App::Koyomi::DataSource::Semaphore;

use strict;
use warnings;
use 5.010_001;
use Carp qw(croak);

use version; our $VERSION = 'v0.6.1';

sub instance         { croak 'Must implement in child class!'; }
sub get_by_job_id    { croak 'Must implement in child class!'; }
sub create           { croak 'Must implement in child class!'; }
sub delete_by_job_id { croak 'Must implement in child class!'; }

1;

__END__

=encoding utf8

=head1 NAME

B<App::Koyomi::DataSource::Semaphore> - Abstract datasource class for semaphore entity

=head1 SYNOPSIS

    use parent qw(App::Koyomi::DataSource::Semaphore);

    # Your implementation goes below
    sub instance { ... }
    sub get_by_job_id { ... }
    sub create { ... }
    sub delete_by_job_id { ... }

=head1 DESCRIPTION

Abstract datasource class for koyomi semaphore entity.

=head1 METHODS

=over 4

=item B<instance>

Construct datasource object.
Probably it's singleton.

=item B<get_by_job_id>

Fetch one semaphore by job_id.

=item B<create>

Create a semaphore.

=item B<delete_by_job_id>

Delete one semaphore specified by job_id.

=back

=head1 SEE ALSO

L<App::Koyomi::Job>

=head1 AUTHORS

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015-2017 IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

