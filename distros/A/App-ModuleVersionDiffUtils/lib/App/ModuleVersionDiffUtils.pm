package App::ModuleVersionDiffUtils;

our $DATE = '2018-04-26'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

our %SPEC;

sub _load_module {
    require Module::Path::More;

    my ($args, $which) = @_;

    my $paths;
    {
        local @INC = (@{ $args->{include_dir} // []}, @INC);

        $paths = Module::Path::More::module_path(
            module => $args->{module},
            all => 1,
        );
    }
    log_trace "Found module %s in %s", $args->{module}, $paths;

    if (@$paths < 2) {
        die "Found less than two versions of $args->{module}, need at least two";
    }

    (my $mod_pm = "$args->{module}.pm") =~ s!::!/!g;
    if ($which == 1) {
        do $paths->[0];
        $INC{$mod_pm} = $paths->[0];
    } else {
        do $paths->[1];
        $INC{$mod_pm} = $paths->[1];
    }
}

sub _load_first_module {
    my $args = shift;
    _load_module($args, 1);
}

# XXX how to turn off redefine warnings?
sub _load_second_module {
    my $args = shift;
    _load_module($args, 2);
}

our %args_module_spec = (
    include_dir => {
        schema => ['array*', of=>'dirname*'],
        cmdline_aliases => {I=>{}},
    },
    module => {
        schema => 'perl::modname*',
        description => <<'_',

Module will be searched in the `@INC` (you can specify `-I` to add more
directories to search). There needs to be at least two locations of the module.
Otherwise, the application will croak.

_
            req => 1,
            pos => 0,
        },
);

$SPEC{diff_two_module_version_hash} = {
    v => 1.1,
    args => {
        %args_module_spec,
        hash_name => {
            summary => 'Hash name to be found in module namespace, with sigil',
            schema => ['str*', match=>qr/\A[%\$]\w+\z/],
            req => 1,
            pos => 1,
        },
    },
    'cmdline.skip_format' => 1,
    examples => [
        {
            argv => ['Foo::Bar', '%hash'],
            summary => 'Diff %hash between two versions of Foo::Bar',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => ['Foo::Bar', '$hashref'],
            summary => 'Diff $hashref between two versions of Foo::Bar',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub diff_two_module_version_hash {
    my %args = @_;

    my $mod = $args{module};
    _load_first_module(\%args);
    my $version1 = ${"$mod\::VERSION"} // 'dev';

    my $hash1;
    if ($args{hash_name} =~ /\A%(.+)/) {
        $hash1 = { %{"$mod\::$1"} };
        %{"$mod\::$1"} = ();
    } elsif ($args{hash_name} =~ /\A\$(.+)/) {
        $hash1 = ${"$mod\::$1"};
        die "\$$mod\::$1 is not a hashref" unless ref $hash1 eq 'HASH';
        $hash1 = {%$hash1};
        %{ ${"$mod\::$1"} } = ();
    } else {
        die "Invalid hash name $args{hash_name}, must be '\%foo' or '\$foo'";
    }

    undef ${"$mod\::VERSION"};
    _load_second_module(\%args);
    my $version2 = ${"$mod\::VERSION"} // 'dev';

    my $hash2;
    if ($args{hash_name} =~ /\A%(.+)/) {
        $hash2 = { %{"$mod\::$1"} };
        %{"$mod\::$1"} = ();
    } elsif ($args{hash_name} =~ /\A\$(.+)/) {
        $hash2 = ${"$mod\::$1"};
        die "\$$mod\::$1 is not a hashref" unless ref $hash2 eq 'HASH';
        $hash2 = {%$hash2};
        %{ ${"$mod\::$1"} } = ();
    } else {
        die "Invalid hash name $args{hash_name}, must be '\%foo' or '\$foo'";
    }

    my ($label1, $label2);
    if ($version1 ne $version2) {
        $label1 = "$mod version $version1";
        $label2 = "$mod version $version2";
    } else {
        $label1 = "first version of $mod";
        $label2 = "second version of $mod";
    }

    my @res;

    push @res, "Keys only in ${label1}'s hash:\n";
    for my $k (sort keys %$hash1) {
        next if exists $hash2->{$k};
        push @res, "  $k\n";
    }
    push @res, "\n";

    push @res, "Keys only in ${label2}'s hash:\n";
    for my $k (sort keys %$hash2) {
        next if exists $hash1->{$k};
        push @res, "  $k\n";
    }
    push @res, "\n";

    push @res, "Keys where the values change:\n";
    for my $k (sort keys %$hash2) {
        next unless exists $hash1->{$k};
        my $v1 = $hash1->{$k} // '';
        my $v2 = $hash2->{$k} // '';
        next if $v1 eq $v2;
        push @res, "  $k ($v1 -> $v2)\n";
    }

    [200, "OK", join("", @res), {'cmdline.skip_format'=>1}];
}

1;
# ABSTRACT: Utilities to diff stuffs from two different versions of a module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ModuleVersionDiffUtils - Utilities to diff stuffs from two different versions of a module

=head1 VERSION

This document describes version 0.001 of App::ModuleVersionDiffUtils (from Perl distribution App-ModuleVersionDiffUtils), released on 2018-04-26.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<diff-two-module-version-hash>

=back

=head1 FUNCTIONS


=head2 diff_two_module_version_hash

Usage:

 diff_two_module_version_hash(%args) -> [status, msg, result, meta]

Examples:

=over

=item * Diff %hash between two versions of Foo::Bar:

 diff_two_module_version_hash( module => "Foo::Bar", hash_name => "%hash");

=item * Diff $hashref between two versions of Foo::Bar:

 diff_two_module_version_hash( module => "Foo::Bar", hash_name => "\$hashref");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<hash_name>* => I<str>

Hash name to be found in module namespace, with sigil.

=item * B<include_dir> => I<array[dirname]>

=item * B<module>* => I<perl::modname>

Module will be searched in the C<@INC> (you can specify C<-I> to add more
directories to search). There needs to be at least two locations of the module.
Otherwise, the application will croak.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ModuleVersionDiffUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ModuleVersionDiffUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ModuleVersionDiffUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
