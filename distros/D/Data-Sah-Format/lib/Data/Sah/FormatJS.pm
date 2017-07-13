package Data::Sah::FormatJS;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Data::Sah::FormatCommon;
use IPC::System::Options;
use Nodejs::Util qw(get_nodejs_path);

our %SPEC;

our $Log_Formatter_Code = $ENV{LOG_SAH_FORMATTER_CODE} // 0;

$SPEC{gen_formatter} = {
    v => 1.1,
    summary => 'Generate formatter code',
    args => {
        %Data::Sah::FormatCommon::gen_formatter_args,
    },
    result_naked => 1,
};
sub gen_formatter {
    my %args = @_;

    my $format   = $args{format};
    my $pkg = "Data::Sah::Format::js\::$format";
    (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;

    require $pkg_pm;

    my $fmt = &{"$pkg\::format"}(
        data_term => 'data',
        (args => $args{formatter_args}) x !!defined($args{formatter_args}),
    );

    my $code = join(
        "",
        "function (data) {\n",
        "    return ($fmt->{expr});\n",
        "}",
    );

    if ($Log_Formatter_Code) {
        log_trace("Formatter code (gen args: %s): %s", \%args, $code);
    }

    return $code if $args{source};

    state $nodejs_path = get_nodejs_path();
    die "Can't find node.js in PATH" unless $nodejs_path;

    sub {
        require File::Temp;
        require JSON::MaybeXS;
        #require String::ShellQuote;

        my $data = shift;

        state $json = JSON::MaybeXS->new->allow_nonref;

        # code to be sent to nodejs
        my $src = "var formatter = $code;\n\n".
            "console.log(JSON.stringify(formatter(".
                $json->encode($data).")))";

        my ($jsh, $jsfn) = File::Temp::tempfile();
        print $jsh $src;
        close($jsh) or die "Can't write JS code to file $jsfn: $!";

        my $out = IPC::System::Options::readpipe($nodejs_path, $jsfn);
        $json->decode($out);
    };
}

1;
# ABSTRACT: Generate formatter code

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::FormatJS - Generate formatter code

=head1 VERSION

This document describes version 0.003 of Data::Sah::FormatJS (from Perl distribution Data-Sah-Format), released on 2017-07-10.

=head1 SYNOPSIS

 use Data::Sah::FormatJS qw(gen_formatter);

 # use as you would use Data::Sah::Format

=head1 DESCRIPTION

This module is just like L<Data::Sah::Format> except that it uses JavaScript
formatting modules.

=head1 VARIABLES

=head2 $Log_Formatter_Code => bool (default: from ENV or 0)

If set to true, will log the generated formatter code (currently using
L<Log::ger> at trace level). To see the log message, e.g. to the screen, you can
use something like:

 % TRACE=1 perl -MLog::ger::LevelFromEnv -MLog::ger::Output=Screen \
     -MData::Sah::FormatJS=gen_formatter -E'my $c = gen_formatter(...)'

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

L<Data::Sah::Format>

L<App::SahUtils>, including L<format-with-sah> to conveniently test formatting
from the command-line.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
