package App::GraphicsColorNamesUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-10'; # DATE
our $DIST = 'App-GraphicsColorNamesUtils'; # DIST
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

our %SPEC;

sub _get_scheme_codes {
    my ($scheme) = @_;
    my $mod = "Graphics::ColorNames::$scheme";
    (my $modpm = "$mod.pm") =~ s!::!/!g;
    require $modpm;
    my $res = &{"$mod\::NamesRgbTable"}();
    if (ref $res eq 'HASH') {
        for (keys %$res) {
            $res->{$_} = sprintf("%06x", $res->{$_});
        }
        return $res;
    } else {
        return {};
    }
}

sub _get_all_schemes_codes {
    require Module::List::Tiny;
    my $mods = Module::List::Tiny::list_modules(
        "Graphics::ColorNames::", {list_modules=>1});
    my %all_codes;
    for my $mod (sort keys %$mods) {
        (my $scheme = $mod) =~ s/^Graphics::ColorNames:://;
        my $codes = _get_scheme_codes($scheme);
        for (keys %$codes) { $all_codes{$_} //= $codes->{$_} }
    }
    \%all_codes;
}

$SPEC{colorcode2name} = {
    v => 1.1,
    summary => 'Convert RGB color code to name',
    args => {
        code => {
            schema => 'color::rgb24*', # XXX disable coercion from color name
            req => 1,
            pos => 0,
        },
        approx => {
            summary => 'When a name with exact code is not found, '.
                'find the several closest ones',
            schema => 'bool*',
        },
    },
};
sub colorcode2name {
    require Graphics::ColorNames;

    my %args = @_;
    my $code = lc $args{code};

    my $all_codes = _get_all_schemes_codes();

    my %names;
    for my $name (sort keys %$all_codes) {
        my $code = $all_codes->{$name};
        $names{$code} //= [];
        push @{ $names{$code} }, $name
            unless grep { $_ eq $name } @{ $names{$code} };
    }

    if (defined $names{$code}) {
        return [200, "OK", join(", ", @{ $names{$code} })];
    } elsif ($args{approx}) {
        require Color::RGB::Util;

        my @colors_and_diffs =
            sort {
                $a->[2] <=> $b->[2]
            }
            map {
                # name, code, distance to wanted
                [$_, $all_codes->{$_}, Color::RGB::Util::rgb_diff($code, $all_codes->{$_}, 'approx1')]
            } sort keys %$all_codes;
        my @closest = splice @colors_and_diffs, 0, 5;
        return [200, "OK (approx)", [map {+{name=>$_->[0], code=>$_->[1]}} @closest], {
            'table.fields' => [qw/name code/]}];
    } else {
        return [404, "Color code '$code' does not yet have a name"];
    }
}

$SPEC{list_color_schemes} = {
    v => 1.1,
    summary => 'List all installed Graphics::ColorNames schemes',
};
sub list_color_schemes {
    require Graphics::ColorNames;

    my %args = @_;
    [200, "OK", [Graphics::ColorNames::all_schemes()]];
}

$SPEC{colorname2code} = {
    v => 1.1,
    summary => 'Convert color name to code',
    args => {
        name => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
};
sub colorname2code {
    require Graphics::ColorNames;

    my %args = @_;
    my $name = $args{name};

    my $all_codes = _get_all_schemes_codes();
    if (defined $all_codes->{$name}) {
        return [200, "OK", $all_codes->{$name}];
    } else {
        return [404, "Unknown color name '$name'"];
    }
}

$SPEC{list_color_names} = {
    v => 1.1,
    summary => 'List all color names from a Graphics::ColorNames scheme',
    args => {
        scheme => {
            schema => 'perl::colorscheme::modname*',
            req => 1,
            pos => 0,
        },
        detail => {
            schema => 'true*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_color_names {
    require Graphics::ColorNames;

    my %args = @_;

    my $codes = _get_scheme_codes($args{scheme});

    my @rows;
    my $resmeta = {};
    for (sort keys %$codes) {
        push @rows, {name=>$_, rgb=>$codes->{$_}};
    }

    if ($args{detail}) {
        $resmeta->{'table.fields'} = [qw/name rgb/];
    } else {
        @rows = map {$_->{name}} @rows;
    }

    [200, "OK", \@rows, $resmeta];
}

$SPEC{show_color_swatch} = {
    v => 1.1,
    summary => 'List all color names from a Graphics::ColorNames scheme as a color swatch',
    args => {
        scheme => {
            schema => 'perl::colorscheme::modname*',
            req => 1,
            pos => 0,
        },
        table_width => {
            schema => 'posint*',
            default => 80,
            cmdline_aliases => {w=>{}},
        },
        columns => {
            schema => 'posint*',
            default => 1,
            cmdline_aliases => {c=>{}},
        },
        row_height => {
            schema => 'posint*',
            default => 3,
        },
        #cell_padding => {
        #    schema => 'uint*',
        #    default => 0,
        #},
    },
};
sub show_color_swatch {
    require Color::RGB::Util;
    require Text::ANSITable;

    my %args = @_;
    my $table_width = $args{table_width} // 80;
    my $columns = $args{columns} // 1;

    my $column_width = int($table_width / $columns); $column_width = 1 if $column_width < 1;

    my $res = list_color_names(scheme => $args{scheme}, detail=>1);
    return $res unless $res->[0] == 200;

    my $t = Text::ANSITable->new;
    $t->border_style('Default::none_ascii');
    $t->columns([map {"col$_"} 1..$columns]);
    $t->cell_height($args{row_height} // 1);
    $t->cell_valign('middle');
    $t->cell_width($column_width);
    #$t->cell_pad($args{cell_padding} // 0);
    #$t->cell_vpad($args{cell_padding} // 0);

    my $rowidx = 0;
    my $colidx = 0;
    my @row;
    for my $i (0 .. $#{ $res->[2] }) {
        my $name = $res->[2][$i]{name};
        my $code = $res->[2][$i]{rgb};
        $t->set_cell_style($rowidx, $colidx, bgcolor => $code);
        $t->set_cell_style($rowidx, $colidx, fgcolor => Color::RGB::Util::rgb_is_dark($code) ? "ffffff" : "000000");
        push @row, "#".($i+1).". $name ($code)";
        if (@row >= $columns || $i == $#{ $res->[2] }) {
            $t->add_row([@row]);
            @row = ();
        }
        $colidx++;
        if ($colidx >= $columns) {
            $colidx = 0;
            $rowidx++;
        }
    }
    print $t->draw;
    #use DD; dd $t;
    [200];
}

1;
# ABSTRACT: Utilities related to Graphics::ColorNames

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GraphicsColorNamesUtils - Utilities related to Graphics::ColorNames

=head1 VERSION

This document describes version 0.005 of App::GraphicsColorNamesUtils (from Perl distribution App-GraphicsColorNamesUtils), released on 2020-06-10.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<colorcode2name>

=item * L<colorname2code>

=item * L<list-color-names>

=item * L<list-color-schemes>

=item * L<show-color-swatch>

=back

=head1 FUNCTIONS


=head2 colorcode2name

Usage:

 colorcode2name(%args) -> [status, msg, payload, meta]

Convert RGB color code to name.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<approx> => I<bool>

When a name with exact code is not found, find the several closest ones.

=item * B<code>* => I<color::rgb24>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 colorname2code

Usage:

 colorname2code(%args) -> [status, msg, payload, meta]

Convert color name to code.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<name>* => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_color_names

Usage:

 list_color_names(%args) -> [status, msg, payload, meta]

List all color names from a Graphics::ColorNames scheme.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<true>

=item * B<scheme>* => I<perl::colorscheme::modname>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_color_schemes

Usage:

 list_color_schemes() -> [status, msg, payload, meta]

List all installed Graphics::ColorNames schemes.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 show_color_swatch

Usage:

 show_color_swatch(%args) -> [status, msg, payload, meta]

List all color names from a Graphics::ColorNames scheme as a color swatch.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<columns> => I<posint> (default: 1)

=item * B<row_height> => I<posint> (default: 3)

=item * B<scheme>* => I<perl::colorscheme::modname>

=item * B<table_width> => I<posint> (default: 80)


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

Please visit the project's homepage at L<https://metacpan.org/release/App-GraphicsColorNamesUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GraphicsColorNamesUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GraphicsColorNamesUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
