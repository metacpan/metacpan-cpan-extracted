package App::GenModEmbedder;

our $DATE = '2016-12-26'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{gen_mod_embedder} = {
    v => 1.1,
    summary => 'Generate a piece of Perl code that embeds a module',
    description => <<'_',

Suppose your code depends on a (trivial, single file, stable) module and wants
to eliminate dependency on that module by embedding it into your code. To do
that, just put the output of this tool (the embedding code) somewhere in your
source code. The structure of the embedding code is as follows:

    unless (eval { require Foo::Bar; 1 }) {
        my $source = <<'END_OF_SOURCE';
        ...
        ...
    END_OF_SOURCE
        eval $source; die if $@;
        $INC{'Foo/Bar.pm'} = '(set by ' . __FILE__ . ')';
    }

Compared to fatpacking, this technique tries to load the original module first,
does not use require hook, and is suitable for use inside .pm file as well as
script.

Compared to datapacking, this technique tries to load the original module first,
does not use require hook nor DATA section, and is suitable for use inside .pm
file as well as script.

_
    args => {
        module => {
            schema => 'perl::modname',
            req => 1,
            pos => 0,
            completion => sub {
                require Complete::Module;
                my %args = @_;
                Complete::Module::complete_module(word=>$args{word});
            },
        },
        as => {
            summary => 'Rename the module',
            schema => 'perl::modname',
        },
        strip_pod => {
            schema => ['bool*', is=>1],
            default => 1,
        },
        indent_level => {
            schema => ['int*', min=>0],
            default => 0,
        },
    },
    links => [
        {url => 'Module::FatPack'},
        {url => 'Module::DataPack'},
        {url => 'App::FatPacker'},
        {url => 'App::depak'},
    ],
};
sub gen_mod_embedder {
    no strict 'refs';
    no warnings 'once';
    require ExtUtils::MakeMaker;
    require File::Slurper;
    require Module::Path::More;

    my %args = @_;
    my $mod = $args{module};
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;

    my $as = $args{as} // $mod;
    (my $as_pm = "$as.pm") =~ s!::!/!g;

    my $path = Module::Path::More::module_path(module => $mod)
        or return [400, "Can't find module $mod on filesystem"];

    my $version = MM->parse_version($path);
    defined $version or return [400, "Can't extract VERSION for $mod from $path"];

    my $source = File::Slurper::read_text($path);

    if ($args{strip_pod}) {
        require Perl::Stripper;
        my $stripper = Perl::Stripper->new(
            # strip_pod => 1, # the default
        );
        $source = $stripper->strip($source);
    }

    # XXX this is not perfect/proper
    if ($mod ne $as) {
        $source =~ s/\b(package\s+)\Q$mod\E\b/$1 . $as/es;
    }

    $source =~ s/\s+\z//s;
    $source .= "\n";
    $source =~ s/^/#/mg;

    my $i0 = "    " x $args{indent_level};

    my $preamble = "${i0}# BEGIN EMBEDDING MODULE: mod=$mod ver=$version generator=\"".__PACKAGE__." ".(${__PACKAGE__."::VERSION"})."\" generated-at=\"".(scalar localtime)."\"\n";
    $preamble .= "${i0}unless (eval { require $as; 1 }) {\n";
    $preamble .= "${i0}    my \$source = '##line ' . (__LINE__+1) . ' \"' . __FILE__ . qq(\"\\n) . <<'EOS';\n";
    my $postamble = "EOS\n";
    $postamble .= "${i0}    \$source =~ s/^#//gm;\n";
    $postamble .= "${i0}    eval \$source; die if \$@;\n";
    $postamble .= "${i0}    \$INC{'$as_pm'} = '(set by embedding code in '.__FILE__.')';\n";
    $postamble .= "${i0}}\n";
    $postamble .= "${i0}# END EMBEDDING MODULE\n";

    return [200, "OK", $preamble . $source . $postamble,
            {"cmdline.skip_format" => 1}];
}

1;
# ABSTRACT: Generate a piece of Perl code that embeds a module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GenModEmbedder - Generate a piece of Perl code that embeds a module

=head1 VERSION

This document describes version 0.003 of App::GenModEmbedder (from Perl distribution App-GenModEmbedder), released on 2016-12-26.

=head1 FUNCTIONS


=head2 gen_mod_embedder(%args) -> [status, msg, result, meta]

Generate a piece of Perl code that embeds a module.

Suppose your code depends on a (trivial, single file, stable) module and wants
to eliminate dependency on that module by embedding it into your code. To do
that, just put the output of this tool (the embedding code) somewhere in your
source code. The structure of the embedding code is as follows:

 unless (eval { require Foo::Bar; 1 }) {
     my $source = <<'END_OF_SOURCE';
     ...
     ...
 END_OF_SOURCE
     eval $source; die if $@;
     $INC{'Foo/Bar.pm'} = '(set by ' . __FILE__ . ')';
 }

Compared to fatpacking, this technique tries to load the original module first,
does not use require hook, and is suitable for use inside .pm file as well as
script.

Compared to datapacking, this technique tries to load the original module first,
does not use require hook nor DATA section, and is suitable for use inside .pm
file as well as script.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<as> => I<perl::modname>

Rename the module.

=item * B<indent_level> => I<int> (default: 0)

=item * B<module>* => I<perl::modname>

=item * B<strip_pod> => I<bool> (default: 1)

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

Please visit the project's homepage at L<https://metacpan.org/release/App-GenModEmbedder>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GenModEmbedder>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GenModEmbedder>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<Module::FatPack>.

L<Module::DataPack>.

L<App::FatPacker>.

L<App::depak>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
