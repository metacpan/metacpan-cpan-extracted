package Acme::CPANModulesUtil::Bencher;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-30'; # DATE
our $DIST = 'Acme-CPANModulesUtil-Bencher'; # DIST
our $VERSION = '0.005'; # VERSION

our %SPEC;

our @EXPORT_OK = qw(gen_bencher_scenario);

$SPEC{gen_bencher_scenario} = {
    v => 1.1,
    summary => 'Generate/extract Bencher scenario from information in an Acme::CPANModules::* list',
    description => <<'_',

An <pm:Acme::CPANModules>::* module can contain benchmark information, for
example in <pm:Acme::CPANModules::TextTable>, each entry has the following
property:

      entries => [
          ...
          {
              module => 'Text::ANSITable',
              ...
              bench_code => sub {
                  my ($table) = @_;
                  my $t = Text::ANSITable->new(
                      use_utf8 => 0,
                      use_box_chars => 0,
                      use_color => 0,
                      columns => $table->[0],
                      border_style => 'Default::single_ascii',
                  );
                  $t->add_row($table->[$_]) for 1..@$table-1;
                  $t->draw;
              },

              # per-function participant
              functions => {
                  'func1' => {
                      bench_code_template => 'Text::ANSITable::func1([])',
                  },
                  ...
              },

The list also contains information about the benchmark datasets:

    bench_datasets => [
        {name=>'tiny (1x1)'    , argv => [_make_table( 1, 1)],},
        {name=>'small (3x5)'   , argv => [_make_table( 3, 5)],},
        {name=>'wide (30x5)'   , argv => [_make_table(30, 5)],},
        {name=>'long (3x300)'  , argv => [_make_table( 3, 300)],},
        {name=>'large (30x300)', argv => [_make_table(30, 300)],},
    ],

This routine extract those information and return a <pm:Bencher> scenario
structure.

_
    args => {
        cpanmodule => {
            summary => 'Name of Acme::CPANModules::* module, without the prefix',
            schema => 'perl::modname*',
            req => 1,
            pos => 0,
            'x.completion' => ['perl_modname' => {ns_prefix=>'Acme::CPANModules'}],
        },
    },
};
sub gen_bencher_scenario {
    my %args = @_;

    my $list;
    my $mod;

    if ($args{_list}) {
        $list = $args{_list};
    } else {
        $mod = $args{cpanmodule} or return [400, "Please specify cpanmodule"];
        $mod = "Acme::CPANModules::$mod" unless $mod =~ /\AAcme::CPANModules::/;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;

        $list = ${"$mod\::LIST"};
    }

    my $scenario = {
        summary => $list->{summary},
        participants => [],
    };

    $scenario->{description} = "This scenario is generated from ".
        ($mod ? "<pm:$mod>" : "an <pm:Acme::CPANModules> list").".";

    for (qw/datasets/) {
        if ($list->{"bench_$_"}) {
            $scenario->{$_} = $list->{"bench_$_"};
        }
    }

    for my $e (@{ $list->{entries} }) {
        my @per_function_participants;

        # we currently don't handle entries with 'modules'
        next unless $e->{module};

        # per-function participant
        if ($e->{functions}) {
            for my $fname (sort keys %{ $e->{functions} }) {
                my $fspec = $e->{functions}{$fname};
                my $p = {
                    module => $e->{module},
                    function => $fname,
                };
                my $has_bench_code;
                for (qw/code code_template fcall_template/) {
                    if (defined $fspec->{"bench_$_"}) {
                        $p->{$_} = $fspec->{"bench_$_"};
                        $has_bench_code++;
                    }
                }
                next unless $has_bench_code;
                push @per_function_participants, $p;
            }
        }

        my $p = {
            module => $e->{module},
        };
        my $has_bench_code;
        for (qw/code code_template fcall_template/) {
            if ($e->{"bench_$_"}) {
                $has_bench_code++;
                $p->{$_} = $e->{"bench_$_"};
            }
        }
        for (qw/include_by_default/) {
            if (exists $e->{"bench_$_"}) {
                $p->{$_} = $e->{"bench_$_"};
            }
        }
        if ($has_bench_code || (!@per_function_participants && !$scenario->{datasets})) {
            push @{ $scenario->{participants} }, $p;
        }
        push @{ $scenario->{participants} }, @per_function_participants;
    }

    [200, "OK", $scenario];
}

1;
# ABSTRACT: Generate/extract Bencher scenario from information in an Acme::CPANModules::* list

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModulesUtil::Bencher - Generate/extract Bencher scenario from information in an Acme::CPANModules::* list

=head1 VERSION

This document describes version 0.005 of Acme::CPANModulesUtil::Bencher (from Perl distribution Acme-CPANModulesUtil-Bencher), released on 2022-11-30.

=head1 FUNCTIONS


=head2 gen_bencher_scenario

Usage:

 gen_bencher_scenario(%args) -> [$status_code, $reason, $payload, \%result_meta]

GenerateE<sol>extract Bencher scenario from information in an Acme::CPANModules::* list.

An L<Acme::CPANModules>::* module can contain benchmark information, for
example in L<Acme::CPANModules::TextTable>, each entry has the following
property:

   entries => [
       ...
       {
           module => 'Text::ANSITable',
           ...
           bench_code => sub {
               my ($table) = @_;
               my $t = Text::ANSITable->new(
                   use_utf8 => 0,
                   use_box_chars => 0,
                   use_color => 0,
                   columns => $table->[0],
                   border_style => 'Default::single_ascii',
               );
               $t->add_row($table->[$_]) for 1..@$table-1;
               $t->draw;
           },
 
           # per-function participant
           functions => {
               'func1' => {
                   bench_code_template => 'Text::ANSITable::func1([])',
               },
               ...
           },

The list also contains information about the benchmark datasets:

 bench_datasets => [
     {name=>'tiny (1x1)'    , argv => [_make_table( 1, 1)],},
     {name=>'small (3x5)'   , argv => [_make_table( 3, 5)],},
     {name=>'wide (30x5)'   , argv => [_make_table(30, 5)],},
     {name=>'long (3x300)'  , argv => [_make_table( 3, 300)],},
     {name=>'large (30x300)', argv => [_make_table(30, 300)],},
 ],

This routine extract those information and return a L<Bencher> scenario
structure.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpanmodule>* => I<perl::modname>

Name of Acme::CPANModules::* module, without the prefix.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModulesUtil-Bencher>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModulesUtil-Bencher>.

=head1 SEE ALSO

L<Acme::CPANModules>

L<Bencher>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModulesUtil-Bencher>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
