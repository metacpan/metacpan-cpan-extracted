package Data::Sah::CoerceJS;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Data::Sah::CoerceCommon;
use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-24'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.054'; # VERSION

our @EXPORT_OK = qw(gen_coercer);

our %SPEC;

our $Log_Coercer_Code = $ENV{LOG_SAH_COERCER_CODE} // 0;

$SPEC{gen_coercer} = {
    v => 1.1,
    summary => 'Generate coercer code',
    description => <<'_',

This is mostly for testing. Normally the coercion rules will be used from
<pm:Data::Sah>.

_
    args => {
        %Data::Sah::CoerceCommon::gen_coercer_args,
        engine => {
            schema => ['str*', in=>['quickjs', 'nodejs']],
            default => 'quickjs',
        },
    },
    result_naked => 1,
};
sub gen_coercer {
    my %args = @_;

    my $rt = $args{return_type} // 'val';
    # old values still supported but deprecated
    $rt = 'bool_coerced+val' if $rt eq 'status+val';
    $rt = 'bool_coerced+str_errmsg+val' if $rt eq 'status+err+val';

    my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
        %args,
        compiler=>'js',
        data_term=>'data',
    );

    my $code;
    if (@$rules) {
        my $expr;
        for my $i (reverse 0..$#{$rules}) {
            my $rule = $rules->[$i];

            my $prev_term;
            if ($i == $#{$rules}) {
                if ($rt eq 'val') {
                    $prev_term = 'data';
                } elsif ($rt eq 'bool_coerced+val') {
                    $prev_term = '[null, data]';
                } else { # bool_coerced+str_errmsg+val
                    $prev_term = '[null, null, data]';
                }
            } else {
                $prev_term = $expr;
            }

            if ($rt eq 'val') {
                if ($rule->{meta}{might_fail}) {
                    $expr = "(function() { if ($rule->{expr_match}) { var _tmp1 = $rule->{expr_coerce}; if (_tmp1[0]) { return null } else { return _tmp1[1] } } else { return $prev_term } })()";
                } else {
                    $expr = "($rule->{expr_match}) ? ($rule->{expr_coerce}) : $prev_term";
                }
            } elsif ($rt eq 'bool_coerced+val') {
                if ($rule->{meta}{might_fail}) {
                    $expr = "(function() { if ($rule->{expr_match}) { var _tmp1 = $rule->{expr_coerce}; if (_tmp1[0]) { return [true, null] } else { return [true, _tmp1[1]] } } else { return $prev_term } })()";
                } else {
                    $expr = "($rule->{expr_match}) ? [true, $rule->{expr_coerce}] : $prev_term";
                }
            } else { # bool_coerced+str_errmsg+val
                if ($rule->{meta}{might_fail}) {
                    $expr = "(function() { if ($rule->{expr_match}) { var _tmp1 = $rule->{expr_coerce}; if (_tmp1[0]) { return [true, _tmp1[0], null] } else { return [true, null, _tmp1[1]] } } else { return $prev_term } })()";
                } else {
                    $expr = "($rule->{expr_match}) ? [true, null, $rule->{expr_coerce}] : $prev_term";
                }
            }
        }

        $code = join(
            "",
            "function (data) {\n",
            "    if (data === undefined || data === null) {\n",
            "        ", ($rt eq 'val' ? "return null;" :
                             $rt eq 'bool_coerced+val' ? "return [null, null];" :
                             "return [null, null, null];" # bool_coerced+str_errmsg+val
                         ), "\n",
            "    }\n",
            "    return ($expr);\n",
            "}",
        );
    } else {
        if ($rt eq 'val') {
            $code = 'function (data) { return data }';
        } elsif ($rt eq 'bool_coerced+val') {
            $code = 'function (data) { return [null, data] }';
        } else { # bool_coerced+str_errmsg+val
            $code = 'function (data) { return [null, null, data] }';
        }
    }

    if ($Log_Coercer_Code) {
        log_trace("Coercer code (gen args: %s): %s", \%args, $code);
    }

    return $code if $args{source};

    require JSON;
    state $json = JSON->new->allow_nonref;

    my $engine = $args{engine} // 'quickjs';

    if ($engine eq 'quickjs') {

        return sub {
            require JavaScript::QuickJS;

            my $data = shift;

            my $src = "var coercer = $code; coercer(".$json->encode($data).")";
            JavaScript::QuickJS->new->eval($src);
        };

    } elsif ($engine eq 'nodejs') {

        return sub {
            require File::Temp;
            require IPC::System::Options;
            require Nodejs::Util;
            #require String::ShellQuote;

            state $nodejs_path = Nodejs::Util::get_nodejs_path();
            die "Can't find node.js in PATH" unless $nodejs_path;

            my $data = shift;

            # code to be sent to nodejs
            my $src = "var coercer = $code; ".
                "console.log(JSON.stringify(coercer(".
                $json->encode($data).")))";

            my ($jsh, $jsfn) = File::Temp::tempfile();
            print $jsh $src;
            close($jsh) or die "Can't write JS code to file $jsfn: $!";

            my $out = IPC::System::Options::readpipe($nodejs_path, $jsfn);
            return $json->decode($out);
        };

    } else {

        die "Unknown engine '$engine'";

    }
}

1;
# ABSTRACT: Generate coercer code

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::CoerceJS - Generate coercer code

=head1 VERSION

This document describes version 0.054 of Data::Sah::CoerceJS (from Perl distribution Data-Sah-Coerce), released on 2023-10-24.

=head1 SYNOPSIS

 use Data::Sah::CoerceJS qw(gen_coercer);

 # use as you would use Data::Sah::Coerce

=head1 DESCRIPTION

This module is just like L<Data::Sah::Coerce> except that it uses JavaScript
coercion rule modules.

=head1 VARIABLES

=head2 $Log_Coercer_Code => bool (default: from ENV or 0)

If set to true, will log the generated coercer code (currently using L<Log::ger>
at trace level). To see the log message, e.g. to the screen, you can use
something like:

 % TRACE=1 perl -MLog::ger::LevelFromEnv -MLog::ger::Output=Screen \
     -MData::Sah::CoerceJS=gen_coercer -E'my $c = gen_coercer(...)'

=head1 FUNCTIONS


=head2 gen_coercer

Usage:

 gen_coercer(%args) -> any

Generate coercer code.

This is mostly for testing. Normally the coercion rules will be used from
L<Data::Sah>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<coerce_rules> => I<array[str]>

A specification of coercion rules to use (or avoid).

This setting is used to specify which coercion rules to use (or avoid) in a
flexible way. Each element is a string, in the form of either C<NAME> to mean
specifically include a rule, or C<!NAME> to exclude a rule.

Some coercion modules are used by default, unless explicitly avoided using the
'!NAME' rule.

To not use any rules:

To use the default rules plus R1 and R2:

 ['R1', 'R2']

To use the default rules but not R1 and R2:

 ['!R1', '!R2']

=item * B<coerce_to> => I<str>

Some Sah types, like C<date>, can be represented in a choice of types in the
target language. For example, in Perl you can store it as a floating number
a.k.a. C<float(epoch)>, or as a L<DateTime> object, or L<Time::Moment>
object. Storing in DateTime can be convenient for date manipulation but requires
an overhead of loading the module and storing in a bulky format. The choice is
yours to make, via this setting.

=item * B<engine> => I<str> (default: "quickjs")

(No description)

=item * B<return_type> => I<str> (default: "val")

C<val> means the coercer will return the input (possibly) coerced or undef if
coercion fails.

C<bool_coerced+val> means the coercer will return a 2-element array. The first
element is a bool value set to 1 if coercion has been performed or 0 if
otherwise. The second element is the (possibly) coerced input.

C<bool_coerced+str_errmsg+val> means the coercer will return a 3-element array.
The first element is a bool value set to 1 if coercion has been performed or 0
if otherwise. The second element is the error message string which will be set
if there is a failure in coercion (or undef if coercion is successful). The
third element is the (possibly) coerced input.

=item * B<source> => I<bool>

If set to true, will return coercer source code string instead of compiled code.

=item * B<type>* => I<sah::type_name>

(No description)


=back

Return value:  (any)

=head1 ENVIRONMENT

=head2 LOG_SAH_COERCER_CODE => bool

Set default for C<$Log_Coercer_Code>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

=head1 SEE ALSO

L<Data::Sah::Coerce>

L<App::SahUtils>, including L<coerce-with-sah> to conveniently test coercion
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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
