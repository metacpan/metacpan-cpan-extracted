package Complete::Sah;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-18'; # DATE
our $DIST = 'Complete-Sah'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Complete::Common qw(:all);
use Complete::Util qw(combine_answers complete_array_elem hashify_answer);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(complete_from_schema);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Sah-related completion routines',
};

$SPEC{complete_from_schema} = {
    v => 1.1,
    summary => 'Complete a value from schema',
    description => <<'_',

Employ some heuristics to complete a value from Sah schema. For example, if
schema is `[str => in => [qw/new open resolved rejected/]]`, then we can
complete from the `in` clause. Or for something like `[int => between => [1,
20]]` we can complete using values from 1 to 20.

_
    args => {
        schema => {
            summary => 'Must be normalized',
            req => 1,
        },
        schema_is_normalized => {
            schema => 'bool',
            default => 0,
        },
        word => {
            schema => [str => default => ''],
            req => 1,
        },
    },
};
sub complete_from_schema {
    my %args = @_;
    my $sch  = $args{schema};
    my $word = $args{word} // "";

    unless ($args{schema_is_normalized}) {
        require Data::Sah::Normalize;
        $sch =Data::Sah::Normalize::normalize_schema($sch);
    }

    my $fres;
    log_trace("[compsah] entering complete_from_schema, word=<%s>, schema=%s", $word, $sch);

    my ($type, $cs) = @{$sch};

    # schema might be based on other schemas, if that is the case, let's try to
    # look at Sah::SchemaR::* module to quickly find the base type
    unless ($type =~ /\A(all|any|array|bool|buf|cistr|code|date|duration|float|hash|int|num|obj|re|str|undef)\z/) {
        no strict 'refs';
        my $pkg = "Sah::SchemaR::$type";
        (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
        eval { require $pkg_pm; 1 };
        if ($@) {
            log_trace("[compsah] couldn't load schema module %s: %s, skipped", $pkg, $@);
            goto RETURN_RES;
        }
        my $rsch = ${"$pkg\::rschema"};
        $type = $rsch->[0];
        # let's just merge everything, for quick checking of clause
        $cs = {};
        for my $cs0 (@{ $rsch->[1] // [] }) {
            for (keys %$cs0) {
                $cs->{$_} = $cs0->{$_};
            }
        }
        log_trace("[compsah] retrieving schema from module %s, base type=%s", $pkg, $type);
    }

    my $static;
    my $words;
    my $summaries;
    eval {
        if (my $xcomp = $cs->{'x.completion'}) {
            require Module::Installed::Tiny;
            my $comp;
            if (ref($xcomp) eq 'CODE') {
                $comp = $xcomp;
            } else {
                my ($submod, $xcargs);
                if (ref($xcomp) eq 'ARRAY') {
                    $submod = $xcomp->[0];
                    $xcargs = $xcomp->[1];
                } else {
                    $submod = $xcomp;
                    $xcargs = {};
                }
                my $mod = "Perinci::Sub::XCompletion::$submod";
                if (Module::Installed::Tiny::module_installed($mod)) {
                    log_trace("[compsah] loading module %s ...", $mod);
                    my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
                    require $mod_pm;
                    my $fref = \&{"$mod\::gen_completion"};
                    log_trace("[compsah] invoking %s's gen_completion(%s) ...", $mod, $xcargs);
                    $comp = $fref->(%$xcargs);
                } else {
                    log_trace("[compsah] module %s is not installed, skipped", $mod);
                }
            }
            if ($comp) {
                log_trace("[compsah] using arg completion routine from schema's 'x.completion' attribute");
                $fres = $comp->(
                    %{$args{extras} // {}},
                    word=>$word, arg=>$args{arg}, args=>$args{args});
                return; # from eval
                }
            }

        if ($cs->{is} && !ref($cs->{is})) {
            log_trace("[compsah] adding completion from schema's 'is' clause");
            push @$words, $cs->{is};
            push @$summaries, undef;
            $static++;
            return; # from eval. there should not be any other value
        }
        if ($cs->{in}) {
            log_trace("[compsah] adding completion from schema's 'in' clause");
            for my $i (0..$#{ $cs->{in} }) {
                next if ref $cs->{in}[$i];
                push @$words    , $cs->{in}[$i];
                push @$summaries, $cs->{'x.in.summaries'} ? $cs->{'x.in.summaries'}[$i] : undef;
            }
            $static++;
            return; # from eval. there should not be any other value
        }
        if ($cs->{'examples'}) {
            log_trace("[compsah] adding completion from schema's 'examples' clause");
            for my $eg (@{ $cs->{'examples'} }) {
                if (ref $eg eq 'HASH') {
                    next unless defined $eg->{value};
                    next if ref $eg->{value};
                    push @$words, $eg->{value};
                    push @$summaries, $eg->{summary};
                } else {
                    next unless defined $eg;
                    next if ref $eg;
                    push @$words, $eg;
                    push @$summaries, undef;
                }
            }
            $static++;
            return; # from eval. there should not be any other value
        }
        if ($type eq 'any') {
            # because currently Data::Sah::Normalize doesn't recursively
            # normalize schemas in 'of' clauses, etc.
            require Data::Sah::Normalize;
            if ($cs->{of} && @{ $cs->{of} }) {

                $fres = combine_answers(
                    grep { defined } map {
                        complete_from_schema(
                            schema=>Data::Sah::Normalize::normalize_schema($_),
                            word => $word,
                        )
                    } @{ $cs->{of} }
                );
                goto RETURN_RES; # directly return result
            }
        }
        if ($type eq 'bool') {
            log_trace("[compsah] adding completion from possible values of bool");
            push @$words, 0, 1;
            push @$summaries, undef, undef;
            $static++;
            return; # from eval
        }
        if ($type eq 'int') {
            my $limit = 100;
            if ($cs->{between} &&
                    $cs->{between}[0] - $cs->{between}[0] <= $limit) {
                log_trace("[compsah] adding completion from schema's 'between' clause");
                for ($cs->{between}[0] .. $cs->{between}[1]) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif ($cs->{xbetween} &&
                         $cs->{xbetween}[0] - $cs->{xbetween}[0] <= $limit) {
                log_trace("[compsah] adding completion from schema's 'xbetween' clause");
                for ($cs->{xbetween}[0]+1 .. $cs->{xbetween}[1]-1) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (defined($cs->{min}) && defined($cs->{max}) &&
                         $cs->{max}-$cs->{min} <= $limit) {
                log_trace("[compsah] adding completion from schema's 'min' & 'max' clauses");
                for ($cs->{min} .. $cs->{max}) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (defined($cs->{min}) && defined($cs->{xmax}) &&
                         $cs->{xmax}-$cs->{min} <= $limit) {
                log_trace("[compsah] adding completion from schema's 'min' & 'xmax' clauses");
                for ($cs->{min} .. $cs->{xmax}-1) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (defined($cs->{xmin}) && defined($cs->{max}) &&
                         $cs->{max}-$cs->{xmin} <= $limit) {
                log_trace("[compsah] adding completion from schema's 'xmin' & 'max' clauses");
                for ($cs->{xmin}+1 .. $cs->{max}) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (defined($cs->{xmin}) && defined($cs->{xmax}) &&
                         $cs->{xmax}-$cs->{xmin} <= $limit) {
                log_trace("[compsah] adding completion from schema's 'xmin' & 'xmax' clauses");
                for ($cs->{xmin}+1 .. $cs->{xmax}-1) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (length($word) && $word !~ /\A-?\d*\z/) {
                log_trace("[compsah] word not an int");
                $words = [];
                $summaries = [];
            } else {
                # do a digit by digit completion
                $words = [];
                $summaries = [];
                for my $sign ("", "-") {
                    for ("", 0..9) {
                        my $i = $sign . $word . $_;
                        next unless length $i;
                        next unless $i =~ /\A-?\d+\z/;
                        next if $i eq '-0';
                        next if $i =~ /\A-?0\d/;
                        next if $cs->{between} &&
                            ($i < $cs->{between}[0] ||
                                 $i > $cs->{between}[1]);
                        next if $cs->{xbetween} &&
                            ($i <= $cs->{xbetween}[0] ||
                                 $i >= $cs->{xbetween}[1]);
                        next if defined($cs->{min} ) && $i <  $cs->{min};
                        next if defined($cs->{xmin}) && $i <= $cs->{xmin};
                        next if defined($cs->{max} ) && $i >  $cs->{max};
                        next if defined($cs->{xmin}) && $i >= $cs->{xmax};
                        push @$words, $i;
                        push @$summaries, undef;
                    }
                }
            }
            return; # from eval
        }
        if ($type eq 'float') {
            if (length($word) && $word !~ /\A-?\d*(\.\d*)?\z/) {
                log_trace("[compsah] word not a float");
                $words = [];
                $summaries = [];
            } else {
                $words = [];
                $summaries = [];
                for my $sig ("", "-") {
                    for ("", 0..9,
                         ".0",".1",".2",".3",".4",".5",".6",".7",".8",".9") {
                        my $f = $sig . $word . $_;
                        next unless length $f;
                        next unless $f =~ /\A-?\d+(\.\d+)?\z/;
                        next if $f eq '-0';
                        next if $f =~ /\A-?0\d\z/;
                        next if $cs->{between} &&
                            ($f < $cs->{between}[0] ||
                                 $f > $cs->{between}[1]);
                        next if $cs->{xbetween} &&
                            ($f <= $cs->{xbetween}[0] ||
                                 $f >= $cs->{xbetween}[1]);
                        next if defined($cs->{min} ) && $f <  $cs->{min};
                        next if defined($cs->{xmin}) && $f <= $cs->{xmin};
                        next if defined($cs->{max} ) && $f >  $cs->{max};
                        next if defined($cs->{xmin}) && $f >= $cs->{xmax};
                        push @$words, $f;
                        push @$summaries, undef;
                    }
                }
                my @orders = sort { $words->[$a] cmp $words->[$b] }
                    0..$#{$words};
                my $words     = [map {$words->[$_]    } @orders];
                my $summaries = [map {$summaries->[$_]} @orders];
            }
            return; # from eval
        }
    }; # eval

    log_trace("[compsah] complete_from_schema died: %s", $@) if $@;

    goto RETURN_RES unless $words;
    $fres = hashify_answer(
        complete_array_elem(array=>$words, summaries=>$summaries, word=>$word),
        {static=>$static && $word eq '' ? 1:0},
    );

  RETURN_RES:
    log_trace("[compsah] leaving complete_from_schema, result=%s", $fres);
    $fres;
}

1;
# ABSTRACT: Sah-related completion routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Sah - Sah-related completion routines

=head1 VERSION

This document describes version 0.001 of Complete::Sah (from Perl distribution Complete-Sah), released on 2019-12-18.

=head1 SYNOPSIS

 use Complete::Sah qw(complete_from_schema);
 my $res = complete_from_schema(word => 'a', schema=>[str => {in=>[qw/apple apricot banana/]}]);
 # -> {words=>['apple', 'apricot'], static=>0}

=head1 FUNCTIONS


=head2 complete_from_schema

Usage:

 complete_from_schema(%args) -> [status, msg, payload, meta]

Complete a value from schema.

Employ some heuristics to complete a value from Sah schema. For example, if
schema is C<< [str =E<gt> in =E<gt> [qw/new open resolved rejected/]] >>, then we can
complete from the C<in> clause. Or for something like C<< [int =E<gt> between =E<gt> [1,
20]] >> we can complete using values from 1 to 20.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>

Must be normalized.

=item * B<schema_is_normalized> => I<bool> (default: 0)

=item * B<word>* => I<str> (default: "")

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

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
