use MoopsX::UsingMoose;
use 5.14.0;
use strict;
use warnings;

# ABSTRACT: Role for plain output
# PODNAME: Acme::Resume::Output::ToPlain
our $VERSION = '0.0105';

role Acme::Resume::Output::ToPlain {

    use String::Nudge;

    method to_plain {

        my @lines = ($self->name, '',
                     $self->email, '',
                     $self->phone, '',
                     $self->formatted_address, '');

        if($self->has_education) {
            push @lines => 'Education', '-' x length 'education';

            foreach my $edu ($self->all_educations) {
                push @lines => 'School:   ' . $edu->school;
                push @lines => 'Url:      ' . $edu->url if $edu->has_url;
                push @lines => 'Location: ' . $edu->location;
                push @lines => 'Program:  ' . $edu->program;
                push @lines => 'Started:  ' . $edu->started->strftime('%Y-%m-%d');
                push @lines => 'Left:     ' . $edu->left->strftime('%Y-%m-%d') if $edu->has_left;
                push @lines => "Description:\n" . nudge($edu->description), '', '';
            }
        }

        if($self->has_job_history) {
            push @lines => '', 'Work experience', '-' x length 'work experience';

            foreach my $job ($self->all_jobs) {

                push @lines => 'Company:  ' . $job->company;
                push @lines => 'Url:      ' . $job->url if $job->has_url;
                push @lines => 'Location: ' . $job->location;
                push @lines => 'Role:     ' . $job->role;
                push @lines => 'Started:  ' . $job->started->strftime('%Y-%m-%d');

                if($job->has_left) {
                    my $start = $job->started;
                    my $left = $job->left;

                    $left = $left->minus_years($start->year);
                    $left = $left->minus_months($start->month);
                    $left = $left->minus_days($start->day_of_month);

                    push @lines => 'Left:     ' . $job->left->strftime('%Y-%m-%d') . ' ' . sprintf '(%d years, %d months and %d days)', $left->year, $left->month, $left->day_of_month;
                }
                elsif($job->current) {
                    my $start = $job->started;
                    my $now = Time::Moment->now;

                    $now = $now->minus_years($start->year);
                    $now = $now->minus_months($start->month);
                    $now = $now->minus_days($start->day_of_month);
                    push @lines => 'Left:     Current job' . ' ' . sprintf '(%d years, %d months and %d days - and counting)', $now->year, $now->month, $now->day_of_month;
                }
                push @lines => "Description:\n" . nudge($job->description), '', '';
            }
        }

        return join "\n" => @lines;
    }

    method formatted_address {
        return $self->join_address("\n");
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Resume::Output::ToPlain - Role for plain output

=head1 VERSION

Version 0.0105, released 2021-09-29.

=head1 SOURCE

L<https://github.com/Csson/p5-Acme-Resume>

=head1 HOMEPAGE

L<https://metacpan.org/release/Acme-Resume>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
