package App::arraydata;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-07'; # DATE
our $DIST = 'App-arraydata'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use List::Util qw(shuffle);

our %SPEC;

our %argspecopt_module = (
    module => {
        schema => 'perl::arraydata::modname_with_optional_args*',
        cmdline_aliases => {m=>{}},
        pos => 0,
    },
);

#our %argspecopt_modules = (
#    modules => {
#        schema => 'perl::arraydata::modnames_with_optional_args*',
#    },
#);

sub _list_installed {
    require Module::List::More;
    my $mods = Module::List::More::list_modules(
        "ArrayData::",
        {
            list_modules  => 1,
            list_pod      => 0,
            recurse       => 1,
            return_path   => 1,
        });
    my @res;
    for my $mod0 (sort keys %$mods) {
        (my $mod = $mod0) =~ s/\AArrayData:://;

        push @res, {
            name => $mod,
            path => $mods->{$mod0}{module_path},
        };
     }
    \@res;
}

$SPEC{arraydata} = {
    v => 1.1,
    summary => 'Show content of ArrayData modules (plus a few other things)',
    args => {
        %argspecopt_module,
        action => {
            schema  => ['str*', in=>[
                'list_installed',
                #'list_cpan',
                'dump',
                'pick',
                #'stat',
            ]],
            default => 'dump',
            cmdline_aliases => {
                L => {
                    summary=>'List installed ArrayData::*',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'list_installed' },
                },
                C => {
                    summary=>'List ArrayData::* on CPAN',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'list_installed' },
                },
                R => {
                    summary=>'Pick random elements from an ArrayData module',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'pick' },
                },
                #S => {
                #    summary=>'Show statistics contained in the ArrayData module',
                #    is_flag => 1,
                #    code => sub { my $args=shift; $args->{action} = 'stat' },
                #},
            },
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        num => {
            summary => 'Number of elements to pick (for -R)',
            schema => 'posint*',
            default => 1,
            cmdline_aliases => {n=>{}},
        },
        #lcpan => {
        #    schema => 'bool',
        #    summary => 'Use local CPAN mirror first when available (for -C)',
        #},
    },
    examples => [
    ],
    'cmdline.default_format' => 'text-simple',
};
sub arraydata {
    my %args = @_;
    my $action = $args{action} // 'dump';

    if ($action eq 'list_installed') {
        my @rows;
        for my $row (@{ _list_installed() }) {
            push @rows, $args{detail} ? $row : $row->{name};
        }
        return [200, "OK", \@rows];
    }

    return [400, "Please specify module"] unless defined $args{module};

    require Module::Load::Util;
    my $obj = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>"ArrayData"}, $args{module});

    if ($action eq 'pick') {
        return [200, "OK", [$obj->pick_items(n=>$args{num})]];
    }

    # dump
    my @items;
    while ($obj->has_next_item) { push @items, $obj->get_next_item }
    [200, "OK", \@items];
}

1;
# ABSTRACT: Show content of ArrayData modules (plus a few other things)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::arraydata - Show content of ArrayData modules (plus a few other things)

=head1 VERSION

This document describes version 0.001 of App::arraydata (from Perl distribution App-arraydata), released on 2021-06-07.

=head1 SYNOPSIS

See the included script L<arraydata>.

=head1 FUNCTIONS


=head2 arraydata

Usage:

 arraydata(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show content of ArrayData modules (plus a few other things).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "dump")

=item * B<detail> => I<bool>

=item * B<module> => I<perl::arraydata::modname_with_optional_args>

=item * B<num> => I<posint> (default: 1)

Number of elements to pick (for -R).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-arraydata>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-arraydata>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-arraydata>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ArrayData> and C<ArrayData::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
