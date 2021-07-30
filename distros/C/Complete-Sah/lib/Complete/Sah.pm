package Complete::Sah;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-29'; # DATE
our $DIST = 'Complete-Sah'; # DIST
our $VERSION = '0.008'; # VERSION

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
            description => <<'_',

Will be normalized, unless when `schema_is_normalized` is set to true, in which
case schema must already be normalized.

_
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

    my ($type, $clset) = @{$sch};

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
        $type = ref $rsch eq 'ARRAY' ? $rsch->[0] : $rsch->{type}; # support older (v.009-) version of Data::Sah::Resolve result
        my $clsets = ref $rsch eq 'ARRAY' ? $rsch->[1] : $rsch->{'clsets_after_type.alt.merge.merged'};
        # let's just merge everything, for quick checking of clause
        my $merged_clset = {};
        for my $clset0 (@{ $clsets }) {
            for (keys %$clset0) {
                $merged_clset->{$_} = $clset0->{$_};
            }
        }
        $clset = $merged_clset;
        log_trace("[compsah] retrieving schema from module %s, base type=%s", $pkg, $type);
    }

    my $static;
    my $words;
    my $summaries;
    eval {
        if (my $xcomp = $clset->{'x.completion'}) {
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
                    log_trace("[compsah] invoking %s\::gen_completion(%s) ...", $mod, $xcargs);
                    $comp = $fref->(%$xcargs);
                } else {
                    log_trace("[compsah] module %s is not installed, skipped", $mod);
                }
            }
            if ($comp) {
                my %cargs = (
                    %{$args{extras} // {}},
                    word=>$word, arg=>$args{arg}, args=>$args{args},
                );
                log_trace("[compsah] using arg completion routine from schema's 'x.completion' attribute with args (%s)", \%cargs);
                $fres = $comp->(%cargs);
                return; # from eval
                }
            }

        if ($clset->{is} && !ref($clset->{is})) {
            log_trace("[compsah] adding completion from schema's 'is' clause");
            push @$words, $clset->{is};
            push @$summaries, undef;
            $static++;
            return; # from eval. there should not be any other value
        }
        if ($clset->{in}) {
            log_trace("[compsah] adding completion from schema's 'in' clause");
            for my $i (0..$#{ $clset->{in} }) {
                next if ref $clset->{in}[$i];
                push @$words    , $clset->{in}[$i];
                push @$summaries, $clset->{'x.in.summaries'} ? $clset->{'x.in.summaries'}[$i] : undef;
            }
            $static++;
            return; # from eval. there should not be any other value
        }
        if ($clset->{'examples'}) {
            log_trace("[compsah] adding completion from schema's 'examples' clause");
            for my $eg (@{ $clset->{'examples'} }) {
                if (ref $eg eq 'HASH') {
                    next unless !exists($eg->{valid}) || $eg->{valid};
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
            #$static++;
            #return; # from eval. there should not be any other value
        }
        if ($type eq 'any') {
            # because currently Data::Sah::Normalize doesn't recursively
            # normalize schemas in 'of' clauses, etc.
            require Data::Sah::Normalize;
            if ($clset->{of} && @{ $clset->{of} }) {

                $fres = combine_answers(
                    grep { defined } map {
                        complete_from_schema(schema=>$_, word => $word)
                    } @{ $clset->{of} }
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
            if ($clset->{between} &&
                    $clset->{between}[0] - $clset->{between}[0] <= $limit) {
                log_trace("[compsah] adding completion from schema's 'between' clause");
                for ($clset->{between}[0] .. $clset->{between}[1]) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif ($clset->{xbetween} &&
                         $clset->{xbetween}[0] - $clset->{xbetween}[0] <= $limit) {
                log_trace("[compsah] adding completion from schema's 'xbetween' clause");
                for ($clset->{xbetween}[0]+1 .. $clset->{xbetween}[1]-1) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (defined($clset->{min}) && defined($clset->{max}) &&
                         $clset->{max}-$clset->{min} <= $limit) {
                log_trace("[compsah] adding completion from schema's 'min' & 'max' clauses");
                for ($clset->{min} .. $clset->{max}) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (defined($clset->{min}) && defined($clset->{xmax}) &&
                         $clset->{xmax}-$clset->{min} <= $limit) {
                log_trace("[compsah] adding completion from schema's 'min' & 'xmax' clauses");
                for ($clset->{min} .. $clset->{xmax}-1) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (defined($clset->{xmin}) && defined($clset->{max}) &&
                         $clset->{max}-$clset->{xmin} <= $limit) {
                log_trace("[compsah] adding completion from schema's 'xmin' & 'max' clauses");
                for ($clset->{xmin}+1 .. $clset->{max}) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (defined($clset->{xmin}) && defined($clset->{xmax}) &&
                         $clset->{xmax}-$clset->{xmin} <= $limit) {
                log_trace("[compsah] adding completion from schema's 'xmin' & 'xmax' clauses");
                for ($clset->{xmin}+1 .. $clset->{xmax}-1) {
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
                        next if $clset->{between} &&
                            ($i < $clset->{between}[0] ||
                                 $i > $clset->{between}[1]);
                        next if $clset->{xbetween} &&
                            ($i <= $clset->{xbetween}[0] ||
                                 $i >= $clset->{xbetween}[1]);
                        next if defined($clset->{min} ) && $i <  $clset->{min};
                        next if defined($clset->{xmin}) && $i <= $clset->{xmin};
                        next if defined($clset->{max} ) && $i >  $clset->{max};
                        next if defined($clset->{xmin}) && $i >= $clset->{xmax};
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
                        next if $clset->{between} &&
                            ($f < $clset->{between}[0] ||
                                 $f > $clset->{between}[1]);
                        next if $clset->{xbetween} &&
                            ($f <= $clset->{xbetween}[0] ||
                                 $f >= $clset->{xbetween}[1]);
                        next if defined($clset->{min} ) && $f <  $clset->{min};
                        next if defined($clset->{xmin}) && $f <= $clset->{xmin};
                        next if defined($clset->{max} ) && $f >  $clset->{max};
                        next if defined($clset->{xmin}) && $f >= $clset->{xmax};
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

    my $replace_map;
  GET_REPLACE_MAP:
    {
        last unless $clset->{prefilters};
        # TODO: make replace_map in Complete::Util equivalent as
        # Str::replace_map's map.
        for my $entry (@{ $clset->{prefilters} }) {
            next unless ref $entry eq 'ARRAY';
            next unless $entry->[0] eq 'Str::replace_map';
            $replace_map = {};
            for my $k (keys %{ $entry->[1]{map} }) {
                my $v = $entry->[1]{map}{$k};
                $replace_map->{$v} = [$k];
            }
            last;
        }
    }

    goto RETURN_RES unless $words;
    $fres = hashify_answer(
        complete_array_elem(
            array=>$words,
            summaries=>$summaries,
            word=>$word,
            (replace_map => $replace_map) x !!$replace_map,
        ),
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

This document describes version 0.008 of Complete::Sah (from Perl distribution Complete-Sah), released on 2021-07-29.

=head1 SYNOPSIS

 use Complete::Sah qw(complete_from_schema);
 my $res = complete_from_schema(word => 'a', schema=>[str => {in=>[qw/apple apricot banana/]}]);
 # -> {words=>['apple', 'apricot'], static=>0}

=head1 FUNCTIONS


=head2 complete_from_schema

Usage:

 complete_from_schema(%args) -> [$status_code, $reason, $payload, \%result_meta]

Complete a value from schema.

Employ some heuristics to complete a value from Sah schema. For example, if
schema is C<< [str =E<gt> in =E<gt> [qw/new open resolved rejected/]] >>, then we can
complete from the C<in> clause. Or for something like C<< [int =E<gt> between =E<gt> [1,
20]] >> we can complete using values from 1 to 20.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>

Will be normalized, unless when C<schema_is_normalized> is set to true, in which
case schema must already be normalized.

=item * B<schema_is_normalized> => I<bool> (default: 0)

=item * B<word>* => I<str> (default: "")


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

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

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
