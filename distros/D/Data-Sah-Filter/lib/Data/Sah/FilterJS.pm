package Data::Sah::FilterJS;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Data::Sah::FilterCommon;
use IPC::System::Options;
use Nodejs::Util qw(get_nodejs_path);

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-16'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.011'; # VERSION

our @EXPORT_OK = qw(gen_filter);

our %SPEC;

our $Log_Filter_Code = $ENV{LOG_SAH_FILTER_CODE} // 0;

$SPEC{gen_filter} = {
    v => 1.1,
    summary => 'Generate filter code',
    description => <<'_',

This is mostly for testing. Normally the filter rules will be used from
<pm:Data::Sah>.

_
    args => {
        filter_names => {
            schema => ['array*', of=>'str*'],
        },
    },
    result_naked => 1,
};
sub gen_filter {
    my %args = @_;

    my $rules = Data::Sah::FilterCommon::get_filter_rules(
        %args,
        compiler=>'js',
        data_term=>'data',
    );

    my $code;
    if (@$rules) {
        $code = join(
            "",
            "function (data) {\n",
            "    if (data === undefined || data === null) {\n",
            "        return null;\n",
            "    }\n",
            (map { "    data = $_->{expr_filter};\n" } @$rules),
            "    return data;\n",
            "}",
        );
    } else {
        $code = 'function (data) { return data }';
    }

    if ($Log_Filter_Code) {
        log_trace("Filter code (gen args: %s): %s", \%args, $code);
    }

    return $code if $args{source};

    state $nodejs_path = get_nodejs_path();
    die "Can't find node.js in PATH" unless $nodejs_path;

    sub {
        require File::Temp;
        require JSON;
        #require String::ShellQuote;

        my $data = shift;

        state $json = JSON->new->allow_nonref;

        # code to be sent to nodejs
        my $src = "var filter = $code;\n\n".
            "console.log(JSON.stringify(filter(".
                $json->encode($data).")))";

        my ($jsh, $jsfn) = File::Temp::tempfile();
        print $jsh $src;
        close($jsh) or die "Can't write JS code to file $jsfn: $!";

        my $out = IPC::System::Options::readpipe($nodejs_path, $jsfn);
        $json->decode($out);
    };
}

1;
# ABSTRACT: Generate filter code

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::FilterJS - Generate filter code

=head1 VERSION

This document describes version 0.011 of Data::Sah::FilterJS (from Perl distribution Data-Sah-Filter), released on 2022-07-16.

=head1 SYNOPSIS

 use Data::Sah::FilterJS qw(gen_filter);

 # use as you would use Data::Sah::Filter

=head1 DESCRIPTION

This module is just like L<Data::Sah::Filter> except that it uses JavaScript
filter rule modules.

=head1 VARIABLES

=head2 $Log_Filter_Code => bool (default: from ENV or 0)

If set to true, will log the generated filter code (currently using L<Log::ger>
at trace level). To see the log message, e.g. to the screen, you can use
something like:

 % TRACE=1 perl -MLog::ger::LevelFromEnv -MLog::ger::Output=Screen \
     -MData::Sah::FilterJS=gen_filter -E'my $c = gen_filter(...)'

=head1 FUNCTIONS


=head2 gen_filter

Usage:

 gen_filter(%args) -> any

Generate filter code.

This is mostly for testing. Normally the filter rules will be used from
L<Data::Sah>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filter_names> => I<array[str]>


=back

Return value:  (any)

=head1 ENVIRONMENT

=head2 LOG_SAH_FILTER_CODE => bool

Set default for C<$Log_Filter_Code>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

=head1 SEE ALSO

L<Data::Sah::Filter>

L<App::SahUtils>, including L<filter-with-sah> to conveniently test filtering
from the command-line.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
