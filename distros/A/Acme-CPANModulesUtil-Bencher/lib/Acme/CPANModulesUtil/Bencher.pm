package Acme::CPANModulesUtil::Bencher;

our $DATE = '2021-01-20'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

our %SPEC;

use Exporter qw(import);
our @EXPORT_OK = qw(gen_bencher_scenario);

$SPEC{gen_bencher_scenario} = {
    v => 1.1,
    summary => 'Generate/extract Bencher scenario from information in an Acme::CPANModules::* list',
    description => <<'_',

An <pm:Acme::CPANModules>::* module can contain benchmark information, for
example in <pm:Acme::CPANModules::TextTable>, each entry has the following
property:

    # entries => [
    #     ...
    #     {
    #         module => 'Text::ANSITable',
    #         ...
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

    for my $e (@{ $list->{entries} }) {
        my $p = {
            module => $e->{module},
        };
        for (qw/code code_template fcall_template/) {
            if ($e->{"bench_$_"}) {
                $p->{$_} = $e->{"bench_$_"};
            }
        }
        push @{ $scenario->{participants} }, $p;
    }

    for (qw/datasets/) {
        if ($list->{"bench_$_"}) {
            $scenario->{$_} = $list->{"bench_$_"};
        }
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

This document describes version 0.002 of Acme::CPANModulesUtil::Bencher (from Perl distribution Acme-CPANModulesUtil-Bencher), released on 2021-01-20.

=head1 FUNCTIONS


=head2 gen_bencher_scenario

Usage:

 gen_bencher_scenario(%args) -> [status, msg, payload, meta]

GenerateE<sol>extract Bencher scenario from information in an Acme::CPANModules::* list.

An L<Acme::CPANModules>::* module can contain benchmark information, for
example in L<Acme::CPANModules::TextTable>, each entry has the following
property:

 # entries => [
 #     ...
 #     {
 #         module => 'Text::ANSITable',
 #         ...
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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModulesUtil-Bencher>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModulesUtil-Bencher>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModulesUtil-Bencher/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules>

L<Bencher>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
