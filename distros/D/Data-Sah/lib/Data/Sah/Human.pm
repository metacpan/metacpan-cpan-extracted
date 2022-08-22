package Data::Sah::Human;

use 5.010;
use strict;
use warnings;
#use Log::Any::IfLOG qw($log);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-20'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.912'; # VERSION

our $Log_Validator_Code = $ENV{LOG_SAH_VALIDATOR_CODE} // 0;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(gen_human_msg);

sub gen_human_msg {
    require Data::Sah;

    my ($schema, $opts) = @_;

    state $hc = Data::Sah->new->get_compiler("human");

    my %args = (schema => $schema, %{$opts // {}});
    my $opt_source = delete $args{source};

    $args{log_result} = 1 if $Log_Validator_Code;

    my $cd = $hc->compile(%args);
    $opt_source ? $cd : $cd->{result};
}

1;
# ABSTRACT: Some functions to use Data::Sah human compiler

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Human - Some functions to use Data::Sah human compiler

=head1 VERSION

This document describes version 0.912 of Data::Sah::Human (from Perl distribution Data-Sah), released on 2022-08-20.

=head1 SYNOPSIS

 use Data::Sah::Human qw(gen_human_msg);

 say gen_human_msg(["int*", min=>2]); # -> "Integer, minimum 2"

=head1 DESCRIPTION

=head1 FUNCTIONS

None exported by default.

=head2 gen_human_msg($schema, \%opts) => STR (or ANY)

Compile schema using human compiler and return the result.

Known options (unknown ones will be passed to the compiler):

=over

=item * source => BOOL (default: 0)

If set to true, will return raw compilation result.

=back

=head1 ENVIRONMENT

L<LOG_SAH_VALIDATOR_CODE>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

=head1 SEE ALSO

L<Data::Sah>, L<Data::Sah::Compiler::human>.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
