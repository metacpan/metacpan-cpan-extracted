package Data::Sah::Format;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Data::Sah::FormatCommon;

our %SPEC;

our $Log_Formatter_Code = $ENV{LOG_SAH_FORMATTER_CODE} // 0;

$SPEC{gen_formatter} = {
    v => 1.1,
    summary => 'Generate formatter code',
    args => {
        %Data::Sah::FormatterCommon::gen_formatter_args,
    },
    result_naked => 1,
};
sub gen_formatter {
    my %args = @_;

    my $format   = $args{format};
    my $pkg = "Data::Sah::Format::perl\::$format";
    (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;

    require $pkg_pm;

    my $fmt = &{"$pkg\::format"}(
        data_term => '$data',
        (args => $args{formatter_args}) x !!defined($args{formatter_args}),
    );

    my $code;

    my $code_require .= '';
    #my %mem;
    if ($fmt->{modules}) {
        for my $mod (keys %{$fmt->{modules}}) {
            #next if $mem{$mod}++;
            $code_require .= "require $mod;\n";
        }
    }

    $code = join(
        "",
        $code_require,
        "sub {\n",
        "    my \$data = shift;\n",
        "    $fmt->{expr};\n",
        "}",
    );

    if ($Log_Formatter_Code) {
        log_trace("Formatter code (gen args: %s): %s", \%args, $code);
    }

    return $code if $args{source};

    my $formatter = eval $code;
    die if $@;
    $formatter;
}

1;
# ABSTRACT: Formatter for Data::Sah

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Format - Formatter for Data::Sah

=head1 VERSION

This document describes version 0.003 of Data::Sah::Format (from Perl distribution Data-Sah-Format), released on 2017-07-10.

=head1 SYNOPSIS

 use Data::Sah::Format qw(gen_formatter);

 my $c = gen_formatter(
     format => 'iso8601_date',
     #format_args => {...},
 );

 my $val;
 $val = $c->(1465784006);   # "2016-06-13"
 $val = $c->(DateTime->new(year=>2016, month=>6, day=>13)); # "2016-06-13"
 $val = $c->("2016-06-13"); # unchanged
 $val = $c->("9999-99-99"); # unchanged
 $val = $c->("foo");        # unchanged
 $val = $c->([]);           # unchanged

=head1 DESCRIPTION

=head1 VARIABLES

=head2 $Log_Formatter_Code => bool (default: from ENV or 0)

If set to true, will log the generated formatter code (currently using
L<Log::ger> at trace level). To see the log message, e.g. to the screen, you can
use something like:

 % TRACE=1 perl -MLog::ger::LevelFromEnv -MLog::ger::Output=Screen \
     -MData::Sah::Format=gen_formatter -E'my $c = gen_formatter(...)'

=head1 FUNCTIONS


=head2 gen_formatter

Usage:

 gen_formatter() -> any

Generate formatter code.

This function is not exported.

No arguments.

Return value:  (any)

=head1 ENVIRONMENT

=head2 LOG_SAH_FORMATTER_CODE => bool

Set default for C<$Log_Formatter_Code>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Format>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Format>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Format>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah>

L<Data::Sah::FormatterJS>

L<App::SahUtils>, including L<format-with-sah> to conveniently test formatting
from the command-line.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
