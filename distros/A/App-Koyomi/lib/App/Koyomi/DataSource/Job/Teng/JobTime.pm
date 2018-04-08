package App::Koyomi::DataSource::Job::Teng::JobTime;

use strict;
use warnings;
use 5.010_001;
use Smart::Args;

use App::Koyomi::Job;
use App::Koyomi::JobTime::Formatter qw(time2str);

use version; our $VERSION = 'v0.6.1';

# Accessor for job_times.columns
{
    no strict 'refs';
    for my $column (@App::Koyomi::Job::TIME_FIELDS) {
        *{ __PACKAGE__ . '::' . $column } = sub {
            my $self = shift;
            $self->{_job_time}->$column;
        };
    }
}

sub new {
    args(
        my $class,
        my $row => 'Teng::Row',
    );
    bless +{
        _job_time => $row,
    }, $class;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Koyomi::DataSource::Job::Teng::JobTime - Wrapper class for job_times datasource

=head1 SYNOPSIS

    use App::Koyomi::DataSource::Job::Teng::JobTime;
    my $job_time = App::Koyomi::DataSource::Job::Teng::JobTime->new(
        row => $row, # Teng::Row (`job_times` table)
    );

=head1 DESCRIPTION

Wrapper class for job_times datasource.

=head1 SEE ALSO

L<App::Koyomi::DataSource::Job::Teng::Data>,
L<Teng::Row>

=head1 AUTHORS

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015-2017 IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

