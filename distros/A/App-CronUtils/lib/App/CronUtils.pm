package App::CronUtils;

our $DATE = '2019-11-03'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI utilities related to cron & crontab',
};

my %arg0_file = (
    file => {
        schema => 'filename*',
        req => 1,
        pos => 0,
    },
);

my %argopt_parser = (
    parser => {
        schema => ['str*', in=>[qw/Parse::Crontab Pegex::Crontab/]],
        #default => 'Parse::Crontab',
        default => 'Pegex::Crontab',
    },
);

$SPEC{parse_crontab} = {
    v => 1.1,
    summary => "Parse crontab file into data structure",
    description => <<'_',

Will return 500 status if there is a parsing error.

Resulting data structure can be different depending on the parser selected.

_
    args => {
        %arg0_file,
        %argopt_parser,
    },
};
sub parse_crontab {
    require File::Slurper::Dash;

    my %args = @_;
    my $parser = $args{parser} // 'Parse::Crontab';

    my $crontab_str = File::Slurper::Dash::read_text($args{file});

    my $crontab_data;
    if ($parser eq 'Parse::Crontab') {
        require File::Temp;
        require Parse::Crontab;
        my ($tmp_fh, $tmp_path) = File::Temp::tempfile();
        File::Slurper::Dash::write_text($tmp_path, $crontab_str);
        my $parser = Parse::Crontab->new(verbose=>1, file=>$tmp_path);
        unless ($parser->is_valid) {
            return [500, "Can't parse $args{file}: " . $parser->error_messages];
        }
        $crontab_data = [];
        # XXX use entries instead of jobs, unwrap minute hour etc from the
        # object
        for my $job ($parser->jobs) {
            push @$crontab_data, {
                minute =>  $job->minute + 0,
                hour => $job->hour,
                day => $job->day,
                month => $job->month,
                day_of_week => $job->day_of_week,
                command => $job->command,
            };
        }
        #use DD; dd $crontab_data;
        return [200, "OK", $crontab_data];
    } elsif ($parser eq 'Pegex::Crontab') {
        require Pegex::Crontab;
        $crontab_data = Pegex::Crontab->new->parse($crontab_str);
        return [200, "OK", $crontab_data];
    } else {
        return [400, "Unknown parser '$parser'"];
    }
}

1;
# ABSTRACT: CLI utilities related to cron & crontab

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CronUtils - CLI utilities related to cron & crontab

=head1 VERSION

This document describes version 0.001 of App::CronUtils (from Perl distribution App-CronUtils), released on 2019-11-03.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes the following CLI utilities related to cron &
crontab:

=over

=item * L<parse-crontab>

=back

=head1 FUNCTIONS


=head2 parse_crontab

Usage:

 parse_crontab(%args) -> [status, msg, payload, meta]

Parse crontab file into data structure.

Will return 500 status if there is a parsing error.

Resulting data structure can be different depending on the parser selected.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file>* => I<filename>

=item * B<parser> => I<str> (default: "Pegex::Crontab")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CronUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CronUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CronUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
