package App::MonM::Report;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Report - The MonM report manager

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Report;

    my $report = App::MonM::Report->new(
        name => "my report",
        configfile => $ctk->configfile
    );

    $report->title("My title");
    $report->abstract("My lead");
    $report->common(
        ["Field 1", "Foo"],
        ["Field 2", "Bar"],
    );
    $report->summary("All right!");
    $report->errors("My error #1", "My error #2");
    $report->footer($ctk->tms());

    print $report->as_string;

=head1 DESCRIPTION

This is an extension for working with the monm reports

=head2 new

    my $report = App::MonM::Report->new(
        name => "my report",
        configfile => $ctk->configfile
    );

Create new report

=head2 abstract

    $report->abstract("Paragraph 1", "Paragraph 2");

Sets the abstract part of report

=head2 as_string

    print $report->as_string;

Returns report as string

=head2 clean

    $report->clean;

Cleans the report

=head2 common

    $report->common(
        ["Field 1", "Foo"],
        ["Field 2", "Bar"],
    );

Sets the common part of report

=head2 errors

    $report->errors("My error #1", "My error #2");

Sets the errors part of report

=head2 footer

    $report->footer();
    $report->footer($ctk->tms());

Sets the footer of report

=head2 report_build

Internal method for building report

=head2 summary

    $report->summary("Hi!", "All right!");

Sets the summary part of report

=head2 title

    $report->title("My title");

Sets the title of report

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.00';

use App::MonM::Const qw/HOSTNAME PROJECTNAME DATETIME_FORMAT/;
use CTK::ConfGenUtil qw/is_array array/;
use CTK::Util qw/dtf tz_diff/;

sub new {
    my $class = shift;
    my %args = @_;

    my ($caller_pkg) = caller || __PACKAGE__;

    my $self = bless {
            report  => [], # Report array
            title   => [],
            abstract=> [],
            common  => [],
            summary => [],
            errors  => [],
            footer  => [],
            sign    => sprintf("%s/%s", $caller_pkg, $caller_pkg->VERSION),
            name    => $args{name} || "virtual",
            configfile => $args{configfile} || "",
        }, $class;

    return $self;
}
sub clean {
    my $self = shift;
    for (qw/report title abstract common summary errors footer/) {
        $self->{$_} = []
    }
    return $self;
}
sub report_build {
    my $self = shift;
    my @report = ();
    push @report, @{(array($self->{title}))};
    push @report, @{(array($self->{abstract}))};
    push @report, @{(array($self->{common}))};
    push @report, @{(array($self->{summary}))};
    push @report, @{(array($self->{errors}))};
    push @report, @{(array($self->{footer}))};
    $self->{report} = [@report];
    return $self;
}
sub as_string {
    my $self = shift;
    $self->report_build;
    my $report = $self->{report} || [];
    return '' unless is_array($report);
    return join "\n", @$report;
}

sub title { # title [, name]
    my $self = shift;
    my $title = shift || "report";
    my $name = shift;

    $self->{title} = [(
        sprintf("Dear %s user,", PROJECTNAME), "",
        sprintf("This is a automatic-generated %s for %s\non %s, created by %s",
            $title, $name // $self->{name}, HOSTNAME, $self->{sign}), "",
    )];

    return $self;
}
sub abstract { # foo, bar, ...
    my $self = shift;
    my @rep = @_;
    $self->{abstract} = [(@rep, "")];
    return $self;
}
sub common { # [foo, bar], [baz, quux]
    my $self = shift;
    my @hdr = @_;
    my @rep = (
        "-"x32,
        "COMMON INFORMATION",
        "-"x32,"",
    );
    my $maxlen = 0;
    foreach my $r (@hdr) {
        $maxlen = length($r->[0]) if $maxlen < length($r->[0])
    }
    foreach my $r (@hdr) {
        push @rep, sprintf("%s %s: %s", $r->[0], " "x($maxlen-length($r->[0])),  $r->[1]);
    }
    $self->{common} = [(@rep, "")];

    return $self;
}
sub summary { # string1, string2, ...
    my $self = shift;
    my @summary = @_;
    unless (scalar(@summary)) {
        $self->{summary} = [];
        return $self;
    }
    my @rep = (
        "-"x32,
        "SUMMARY",
        "-"x32,"",
    );
    push @rep, @summary;
    $self->{summary} = [(@rep, "")];

    return $self;
}
sub errors { # error1, error2
    my $self = shift;
    my @errs = @_;
    my @rep = (
        "-"x32,
        "LIST OF OCCURRED ERRORS",
        "-"x32,"",
    );
    if (@errs) {
        push @rep, @errs;
    } else {
        push @rep, "No errors found";
    }
    $self->{errors} = [(@rep, "")];

    return $self;
}
sub footer { # tms
    my $self = shift;
    my $tms = shift;
    my @rep = ("---");
    push @rep, sprintf("Hostname    : %s", HOSTNAME);
    push @rep, sprintf("Program     : %s (%s, Perl %s)", $0, $^O, $^V);
    push @rep, sprintf("Version     : %s", $self->{sign});
    push @rep, sprintf("Config file : %s", $self->{configfile}) if $self->{configfile};
    push @rep, sprintf("PID         : %d", $$);
    push @rep, sprintf("Work time   : %s", $tms) if $tms;
    push @rep, sprintf("Generated   : %s", dtf(DATETIME_FORMAT . " " . tz_diff()));

    $self->{footer} = [(@rep)];

    return $self;
}

1;

__END__
