package Acme::CPANModules::DumpingDataForDebugging;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-07'; # DATE
our $DIST = 'Acme-CPANModules-DumpingDataForDebugging'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Some modules and tips when dumping data structures for debugging',
    description => <<'_',

This list catalogs some of the modules you can you to dump your data structures
for debugging purposes, so the modules will be judged mostly by the
appropriateness of its output for human viewing (instead of other criteria like
speed, footprint, etc).

_
    entries => [
        {
            module=>'Data::Dumper',
            tags => ['perl'],
            description => <<'_',

Everybody knows this module and it's core so sometimes it's the only appropriate
choice. However, the default setting is not really optimized for viewing by
human. I suggest you tweak these before dumping your data:

* Set $Data::Dumper::Useqq to 1.

By default, <pm:Data::Dumper> quotes strings using single-quotes and does not
quote things like "\n" and "\b" making it difficult to spot special characters.


_
        },

        {
            module=>'Data::Dump',
            tags => ['perl'],
            description => <<'_',

A data dumper that produces nicer Perl code output, with features like vertical
alignment of "=>" when dumping hashes, compacting sequences like 1,2,3,4,5,6 to
1..6, compacting repeating characters in string like "ccccccccccccccccccccc" to
("c" x 21), and so on.

It tries harder to produce Perl code that generates the original data structure,
particularly with circular references. But with interlinked references like
trees, Data::Dumper might be more helpful in showing you which references get
mentioned where. For example this data:

    $tree = {children=>[{children=>[{}]}, {children=>[]}]};
    $tree->{children}[0]{parent}=$tree;
    $tree->{children}[1]{parent}=$tree;
    $tree->{children}[0]{children}[0]{parent} = $tree->{children}[0];

Data::Dump will produce:

    do {
       my $a = {
         children => [
          { children => [{ parent => 'fix' }], parent => 'fix' },
          { children => [], parent => 'fix' },
        ],
      };
      $a->{children}[0]{children}[0]{parent} = $a->{children}[0];
      $a->{children}[0]{parent} = $a;
      $a->{children}[1]{parent} = $a;
      $a;
    }

while Data::Dumper will produce:

    $VAR1 = {
              'children' => [
                              {
                                'children' => [
                                                {
                                                  'parent' => $VAR1->{'children'}[0]
                                                }
                                              ],
                                'parent' => $VAR1
                              },
                              {
                                'parent' => $VAR1,
                                'children' => []
                              }
                            ]
            };

_
        },

        {
            module=>'Data::Dump::Color',
            tags => ['perl'],
            description => <<'_',

A modification to Data::Dump which adds color (and color theme) support, as well
as other visual aids like depth and array index/hash pair count indicator. It's
usually my go-to module for debugging.

_
        },

        {
            module=>'Data::Dumper::Compact',
            tags => ['perl'],
            description => <<'_',

A relatively recent module by MSTROUT. I will need to use this more to see if I
really like the output, but so far I do.

_
        },

        {
            module=>'XXX',
            tags => ['perl'],
            description => <<'_',

A nice little dumper module from the creator of YAML. Obviously, it uses YAML
output by default but it's configurable to dump in other formats. For example:

    PERL_XXX_DUMPER=Data::Dump::Color

It's main selling point is that the dumper function returns the original
arguments so the dumping can be done in various places in code, making it more
convenient. More (if not all) dumpers should do this too.

_
        },

        {
            module=>'Data::Printer',
            tags => ['perlish'],
            description => <<'_',

Favorites among many Perl programmers, it sports colors, array index indicator,
as well as nice object dumper showing methods and inheritance information. It's
also very customizable. It uses its own format though, and my preference for
dumping is the Perl format (with additional informations/hints as comments) so
I've never used it in my daily coding activities. I probably should though.

_
        },

        {
            module=>'JSON::Color',
            tags => ['json'],
            description => <<'_',

JSON is a limited format; it cannot represent many things that Perl supports
e.g. globs, circular references, or even ASCII NUL. But if you are working only
with JSON-able data, this JSON dumping module adds color output.

_
        },

        {
            module=>'YAML::Tiny::Color',
            tags => ['yaml'],
            description => <<'_',

_
        },
    ],
};

1;
# ABSTRACT: Some modules and tips when dumping data structures for debugging

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::DumpingDataForDebugging - Some modules and tips when dumping data structures for debugging

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::DumpingDataForDebugging (from Perl distribution Acme-CPANModules-DumpingDataForDebugging), released on 2020-02-07.

=head1 DESCRIPTION

Some modules and tips when dumping data structures for debugging.

This list catalogs some of the modules you can you to dump your data structures
for debugging purposes, so the modules will be judged mostly by the
appropriateness of its output for human viewing (instead of other criteria like
speed, footprint, etc).

=head1 INCLUDED MODULES

=over

=item * L<Data::Dumper>

Everybody knows this module and it's core so sometimes it's the only appropriate
choice. However, the default setting is not really optimized for viewing by
human. I suggest you tweak these before dumping your data:

=over

=item * Set $Data::Dumper::Useqq to 1.

=back

By default, L<Data::Dumper> quotes strings using single-quotes and does not
quote things like "\n" and "\b" making it difficult to spot special characters.


=item * L<Data::Dump>

A data dumper that produces nicer Perl code output, with features like vertical
alignment of "=>" when dumping hashes, compacting sequences like 1,2,3,4,5,6 to
1..6, compacting repeating characters in string like "ccccccccccccccccccccc" to
("c" x 21), and so on.

It tries harder to produce Perl code that generates the original data structure,
particularly with circular references. But with interlinked references like
trees, Data::Dumper might be more helpful in showing you which references get
mentioned where. For example this data:

 $tree = {children=>[{children=>[{}]}, {children=>[]}]};
 $tree->{children}[0]{parent}=$tree;
 $tree->{children}[1]{parent}=$tree;
 $tree->{children}[0]{children}[0]{parent} = $tree->{children}[0];

Data::Dump will produce:

 do {
    my $a = {
      children => [
       { children => [{ parent => 'fix' }], parent => 'fix' },
       { children => [], parent => 'fix' },
     ],
   };
   $a->{children}[0]{children}[0]{parent} = $a->{children}[0];
   $a->{children}[0]{parent} = $a;
   $a->{children}[1]{parent} = $a;
   $a;
 }

while Data::Dumper will produce:

 $VAR1 = {
           'children' => [
                           {
                             'children' => [
                                             {
                                               'parent' => $VAR1->{'children'}[0]
                                             }
                                           ],
                             'parent' => $VAR1
                           },
                           {
                             'parent' => $VAR1,
                             'children' => []
                           }
                         ]
         };


=item * L<Data::Dump::Color>

A modification to Data::Dump which adds color (and color theme) support, as well
as other visual aids like depth and array index/hash pair count indicator. It's
usually my go-to module for debugging.


=item * L<Data::Dumper::Compact>

A relatively recent module by MSTROUT. I will need to use this more to see if I
really like the output, but so far I do.


=item * L<XXX>

A nice little dumper module from the creator of YAML. Obviously, it uses YAML
output by default but it's configurable to dump in other formats. For example:

 PERL_XXX_DUMPER=Data::Dump::Color

It's main selling point is that the dumper function returns the original
arguments so the dumping can be done in various places in code, making it more
convenient. More (if not all) dumpers should do this too.


=item * L<Data::Printer>

Favorites among many Perl programmers, it sports colors, array index indicator,
as well as nice object dumper showing methods and inheritance information. It's
also very customizable. It uses its own format though, and my preference for
dumping is the Perl format (with additional informations/hints as comments) so
I've never used it in my daily coding activities. I probably should though.


=item * L<JSON::Color>

JSON is a limited format; it cannot represent many things that Perl supports
e.g. globs, circular references, or even ASCII NUL. But if you are working only
with JSON-able data, this JSON dumping module adds color output.


=item * L<YAML::Tiny::Color>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries DumpingDataForDebugging | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=DumpingDataForDebugging -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-DumpingDataForDebugging>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-DumpingDataForDebugging>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-DumpingDataForDebugging>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
