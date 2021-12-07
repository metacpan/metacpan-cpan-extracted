package Data::Sah::DefaultValueJS;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Data::Sah::DefaultValueCommon;
use IPC::System::Options;
use Nodejs::Util qw(get_nodejs_path);

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-28'; # DATE
our $DIST = 'Data-Sah-DefaultValue'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(gen_default_value_code);

our %SPEC;

our $Log_Default_Value_Code = $ENV{LOG_SAH_DEFAULT_VALUE_CODE} // 0;

$SPEC{gen_default_value_code} = {
    v => 1.1,
    summary => 'Generate code to set default value',
    description => <<'_',

This is mostly for testing. Normally the coercion rules will be used from
<pm:Data::Sah>.

_
    args => {
        %Data::Sah::DefaultValueCommon::gen_default_value_code_args,
    },
    result_naked => 1,
};
sub gen_default_value_code {
    my %args = @_;

    my $rules = Data::Sah::DefaultValueCommon::get_default_value_rules(
        %args,
        compiler=>'js',
    );

    my $code;
    if (@$rules) {
        my $expr = '';
        $code = join(
            "",
            "function (res) {\n",
            (map {
                "  if (res === undefined || res === null) { res = $rules->[$_]{expr_value} }\n"
            } (reverse 0..$#{$rules})),
            "  return res\n",
            "}",
        );
    } else {
        $code = 'function (res) { return res }';
    }

    if ($Log_Default_Value_Code) {
        log_trace("Default-value code (gen args: %s): %s", \%args, $code);
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
        my $src = "var default_value_code = $code;\n\n".
            "console.log(JSON.stringify(default_value_code(".
                $json->encode($data).")))";

        my ($jsh, $jsfn) = File::Temp::tempfile();
        print $jsh $src;
        close($jsh) or die "Can't write JS code to file $jsfn: $!";

        my $out = IPC::System::Options::readpipe($nodejs_path, $jsfn);
        $json->decode($out);
    };
}

1;
# ABSTRACT: Generate code to set default value

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::DefaultValueJS - Generate code to set default value

=head1 VERSION

This document describes version 0.001 of Data::Sah::DefaultValueJS (from Perl distribution Data-Sah-DefaultValue), released on 2021-11-28.

=head1 SYNOPSIS

 use Data::Sah::DefaultValueJS qw(gen_default_value_code);

 # use as you would use Data::Sah::DefaultValue

=head1 DESCRIPTION

This module is just like L<Data::Sah::DefaultValue> except that it uses
JavaScript default-value rule modules.

=head1 VARIABLES

=head2 $Log_Default_Value_Code => bool (default: from ENV or 0)

If set to true, will log the generated default-value code (currently using
L<Log::ger> at trace level). To see the log message, e.g. to the screen, you can
use something like:

 % TRACE=1 perl -MLog::ger::LevelFromEnv -MLog::ger::Output=Screen \
     -MData::Sah::DefaultValueJS=gen_default_value_code -E'my $c = gen_default_value_code(...)'

=head1 FUNCTIONS


=head2 gen_default_value_code

Usage:

 gen_default_value_code(%args) -> any

Generate code to set default value.

This is mostly for testing. Normally the coercion rules will be used from
L<Data::Sah>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<default_value_rules> => I<array[str]>

A specification of default-value rules to use (or avoid).

This setting is used to specify which default-value rules to use (or avoid) in a
flexible way. Each element is a string, in the form of either C<NAME> to mean
specifically include a rule, or C<!NAME> to exclude a rule.

To use the default-value rules R1 and R2:

 ['R1', 'R2']

=item * B<source> => I<bool>

If set to true, will return coercer source code string instead of compiled code.


=back

Return value:  (any)

=head1 ENVIRONMENT

=head2 LOG_DEFAULT_VALUE_CODE => bool

Set default for C<$Log_Default_Value_Code>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-DefaultValue>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-DefaultValue>.

=head1 SEE ALSO

L<Data::Sah::DefaultValue>

L<App::SahUtils>

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

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-DefaultValue>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
