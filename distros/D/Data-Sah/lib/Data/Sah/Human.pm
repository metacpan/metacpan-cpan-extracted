package Data::Sah::Human;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any::IfLOG qw($log);

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

This document describes version 0.896 of Data::Sah::Human (from Perl distribution Data-Sah), released on 2019-07-04.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah>, L<Data::Sah::Compiler::human>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
