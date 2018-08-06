package App::isbn;

our $DATE = '2018-08-02'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

my $re_excluded_names = qr/^(Amazon)$/; # not a real driver

sub _installed_drivers {
    require PERLANCAR::Module::List;
    my $lres = PERLANCAR::Module::List::list_modules("WWW::Scraper::ISBN::", {list_modules=>1});

    my $res = [];
    for my $e (sort keys %$lres) {
        my ($name) = $e =~ /::(\w+)_Driver$/ or next;
        next if $name =~ $re_excluded_names;
        push @{$res}, $name;
    }

    return $res;
}

$SPEC{isbn} = {
    v => 1.1,
    summary => 'List available drivers',
    args => {
        action => {
            schema => 'str*',
            description => <<'_',

Choose what action to perform. The default is 'search'. Other actions include:

* 'installed_drivers' - List installed driver modules. Will return the driver
  names, e.g. if <pm:WWW::Scraper::ISBN::AmazonUS_Driver> is installed then will
  include `AmazonUS` in the result.

* 'available_drivers' - List available driver modules on CPAN. Currently uses
  and requires <pm:App::lcpan> and an up-to-date local mini-CPAN.

_
            default => 'search',
            cmdline_aliases => {
                l => {is_flag=>1, summary => 'Shortcut for --action installed_drivers', code => sub { $_[0]{action} = 'installed_drivers' }},
                L => {is_flag=>1, summary => 'Shortcut for --action available_drivers', code => sub { $_[0]{action} = 'available_drivers' }},
            },
        },
        isbn => {
            schema => 'str*',
            pos => 0,
        },
        drivers => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'driver',
            schema => ['array*', of=>'str*'],
            # XXX
            #elem_completion => sub {
            #    my %args = @_;
            #},
            cmdline_aliases => {
                d => {},
            },
        },
    },
};
sub isbn {
    my %args = @_;
    my $action = $args{action} // 'search';

    if ($action eq 'available_drivers') {
        require App::lcpan::Call;
        my $lres = App::lcpan::Call::call_lcpan_script(argv => ["mods", "-l", "--namespace", "WWW::Scraper::ISBN"]);
        return [412, "Can't call lcpan: $lres->[0] - $lres->[1]"] if $lres->[0] != 200;

        my $res = [200, "OK", []];
        for my $e (@{$lres->[2]}) {
            my ($name) = $e->{module} =~ /::(\w+)_Driver$/ or next;
            next if $name =~ $re_excluded_names;
            push @{$res->[2]}, $name;
        }

        return $res;
    } elsif ($action eq 'installed_drivers') {
        return [200, "OK", _installed_drivers()];
    } elsif ($action eq 'search') {
        require WWW::Scraper::ISBN;

        my $isbn = $args{isbn} or return [400, "Please specify ISBN"];
        $isbn =~ s/[^0-9Xx]//g;
        my $drivers = $args{drivers} // _installed_drivers();
        my $res = [200, "OK", {}];
        for my $driver (@$drivers) {
            log_info "Searching ISBN %s using %s driver ...", $isbn, $driver;
            my $scraper = WWW::Scraper::ISBN->new();
            $scraper->drivers($driver);
            my $rec = $scraper->search($isbn);
            if ($rec->found) {
                my $book = $rec->book;
                for my $k (keys %$book) {
                    next if $k =~ /^(html)$/;
                    $res->[2]{"${driver}_$k"} = "$book->{$k}";
                }
            } else {
                log_info "Couldn't find ISBN %s using driver %s", $isbn, $driver;
            }
        }
        return $res;
    } else {
        return [400, "Unknown action"];
    }
}

1;
# ABSTRACT: Query book information by ISBN

__END__

=pod

=encoding UTF-8

=head1 NAME

App::isbn - Query book information by ISBN

=head1 VERSION

This document describes version 0.001 of App::isbn (from Perl distribution App-isbn), released on 2018-08-02.

=head1 SYNOPSIS

See L<isbn> script.

=head1 FUNCTIONS


=head2 isbn

Usage:

 isbn(%args) -> [status, msg, result, meta]

List available drivers.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "search")

Choose what action to perform. The default is 'search'. Other actions include:

=over

=item * 'installed_drivers' - List installed driver modules. Will return the driver
names, e.g. if L<WWW::Scraper::ISBN::AmazonUS_Driver> is installed then will
include C<AmazonUS> in the result.

=item * 'available_drivers' - List available driver modules on CPAN. Currently uses
and requires L<App::lcpan> and an up-to-date local mini-CPAN.

=back

=item * B<drivers> => I<array[str]>

=item * B<isbn> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-isbn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-isbn>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-isbn>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
