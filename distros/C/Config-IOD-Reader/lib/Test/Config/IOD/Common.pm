package Test::Config::IOD::Common;

our $DATE = '2021-06-23'; # DATE
our $VERSION = '0.343'; # VERSION

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

our $CLASS = "Config::IOD::Reader";

sub test_common_iod {

    eval "require $CLASS"; die if $@;

    subtest "opt: default_section" => sub {
        test_read_iod(
            args  => {default_section=>'bawaan'},
            input => <<'_',
a=1
_
            result => {bawaan=>{a=>1}},
        );
    };

    subtest "opt: allow_directives" => sub {
        test_read_iod(
            args  => {allow_directives=>['merge']},
            input => <<'_',
;!noop
_
            dies  => 1,
        );
        test_read_iod(
            args  => {allow_directives=>['noop']},
            input => <<'_',
;!noop
_
            result => {},
        );
    };

    subtest "opt: disallow_directives" => sub {
        test_read_iod(
            args  => {disallow_directives=>['noop']},
            input => <<'_',
;!noop
_
            dies  => 1,
        );
        test_read_iod(
            args  => {disallow_directives=>['merge']},
            input => <<'_',
;!noop
_
            result => {},
        );
    };

    subtest "opt: allow_directives + disallow_directives" => sub {
        test_read_iod(
            args  => {
                allow_directives    => ['noop'],
                disallow_directives => ['noop'],
            },
            input => <<'_',
;!noop
_
            dies  => 1,
        );
    };

    subtest "opt: enable_directive=0" => sub {
        test_read_iod(
            args  => {enable_directive=>0},
            input => <<'_',
[s1]
a=1
[s2]
;!merge s1
b=2
_
            result => {s1=>{a=>1}, s2=>{b=>2}},
        );
        test_read_iod(
            args  => {enable_directive=>0},
            input => <<'_',
[s1]
a=1
[s2]
!merge s1
b=2
_
            dies => 1,
        );
    };

    subtest "opt: enable_quoting=0" => sub {
        test_read_iod(
            args  => {enable_quoting=>0},
            input => <<'_',
name="1\n2"
_
            result => {GLOBAL=>{name=>'"1\\n2"'}},
        );
    };

    subtest "opt: enable_bracket=0" => sub {
        test_read_iod(
            args  => {enable_bracket=>0},
            input => <<'_',
name=[1,2,3]
_
            result => {GLOBAL=>{name=>'[1,2,3]'}},
        );
    };

    subtest "opt: enable_brace=0" => sub {
        test_read_iod(
            args  => {enable_brace=>0},
            input => <<'_',
name={"a":1}
_
            result => {GLOBAL=>{name=>'{"a":1}'}},
        );
    };

    subtest "opt: enable_encoding=0" => sub {
        test_read_iod(
            args  => {enable_encoding=>0},
            input => <<'_',
name=!hex 5e5e
_
            result => {GLOBAL=>{name=>'!hex 5e5e'}},
        );
    };

    subtest "opt: allow_encodings" => sub {
        test_read_iod(
            args  => {allow_encodings=>['hex']},
            input => <<'_',
name=!json "1\n2"
_
            dies => 1,
        );
        test_read_iod(
            args  => {allow_encodings=>['json']},
            input => <<'_',
name=!json "1\n2"
name2=!j "3\n4"
_
            result => {GLOBAL=>{name=>"1\n2", name2=>"3\n4"}},
        );
    };

    subtest "opt: disallow_encodings" => sub {
        test_read_iod(
            args  => {disallow_encodings=>['json']},
            input => <<'_',
name=!json "1\n2"
_
            dies => 1,
        );
        test_read_iod(
            args  => {disallow_encodings=>['json']},
            input => <<'_',
name=!j "1\n2"
_
            dies => 1,
        );
        test_read_iod(
            args  => {disallow_encodings=>['hex']},
            input => <<'_',
name=!json "1\n2"
_
            result => {GLOBAL=>{name=>"1\n2"}},
        );
    };

    subtest "opt: allow_encodings + disallow_encodings" => sub {
        test_read_iod(
            args  => {
                allow_encodings   =>['json'],
                disallow_encodings=>['json'],
            },
            input => <<'_',
name=!json "1\n2"
_
            dies => 1,
        );
    };

    subtest "opt: allow_bang_only=0" => sub {
        test_read_iod(
            args  => {allow_bang_only=>0},
            input => <<'_',
a=1
!noop
_
            dies => 1,
        );
    };

    subtest "opt: allow_duplicate_key=0" => sub {
        test_read_iod(
            args  => {allow_duplicate_key=>0},
            input => <<'_',
a=1
a=2
_
            dies => 1,
        );
    };

    subtest "opt: ignore_unknown_directive=1" => sub {
        test_read_iod(
            args  => {ignore_unknown_directive=>1},
            input => <<'_',
;!foo bar
_
            result => {},
        );
    };

    # temporarily placed here
    subtest "expr" => sub {
        test_read_iod(
            name  => "must be enabled first",
            args  => {},
            input => <<'_',
a=!e 1+1
_
            dies => 1,
        );
        test_read_iod(
            name  => "must be valid",
            args  => {enable_expr=>1},
            input => <<'_',
a=!e 1+
_
            dies => 1,
        );
        test_read_iod(
            args  => {enable_expr=>1},
            input => <<'_',
a=!e 1+1
[sect]
b=!e val("GLOBAL.a")*3
c=!e val("b") x 3
_
            result => {GLOBAL=>{a=>2}, sect=>{b=>6, c=>666}},
        );
    };
}

sub test_read_iod {
    my %args = @_;

    my $parser_args = $args{args};
    my $test_name = $args{name} //
        "{". join(", ",
                  (map {"$_=$parser_args->{$_}"}
                       sort keys %$parser_args),
              ) . "}";
    subtest $test_name => sub {

        my $parser = $CLASS->new(%$parser_args);

        my $res;
        eval {
            if ($CLASS eq 'Config::IOD') {
                $res = $parser->read_string($args{input})->dump;
            } else {
                $res = $parser->read_string($args{input});
            }
        };
        my $err = $@;
        if ($args{dies}) {
            ok($err, "dies") or diag explain $res;
            return;
        } else {
            ok(!$err, "doesn't die")
                or do { diag explain "err=$err"; return };
            is_deeply($res, $args{result}, 'result')
                or diag explain $res;
        }
    };
}

1;
# ABSTRACT: Common tests for Config::IOD and Config::IOD::Reader

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Config::IOD::Common - Common tests for Config::IOD and Config::IOD::Reader

=head1 VERSION

This document describes version 0.343 of Test::Config::IOD::Common (from Perl distribution Config-IOD-Reader), released on 2021-06-23.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Config-IOD-Reader>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Config-IOD-Reader>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-IOD-Reader>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
