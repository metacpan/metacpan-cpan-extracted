use strict;
use warnings;
package App::Nopaste::Service::Debian;
# ABSTRACT: Service provider for Debian - https://paste.debian.net/

our $VERSION = '1.013';

use parent 'App::Nopaste::Service';

my $languages = {
    "text" => "-1",
    "abap" => "abap",
    "ada" => "ada",
    "ahk" => "ahk",
    "antlr" => "antlr",
    "antlr-as" => "antlr-as",
    "antlr-cpp" => "antlr-cpp",
    "antlr-csharp" => "antlr-csharp",
    "antlr-java" => "antlr-java",
    "antlr-objc" => "antlr-objc",
    "antlr-perl" => "antlr-perl",
    "antlr-python" => "antlr-python",
    "antlr-ruby" => "antlr-ruby",
    "apacheconf" => "apacheconf",
    "applescript" => "applescript",
    "as" => "as",
    "as3" => "as3",
    "aspx-cs" => "aspx-cs",
    "aspx-vb" => "aspx-vb",
    "asy" => "asy",
    "awk" => "awk",
    "basemake" => "basemake",
    "bash" => "bash",
    "bat" => "bat",
    "bbcode" => "bbcode",
    "befunge" => "befunge",
    "blitzmax" => "blitzmax",
    "boo" => "boo",
    "brainfuck" => "brainfuck",
    "bro" => "bro",
    "c" => "c",
    "cfengine3" => "cfengine3",
    "cfm" => "cfm",
    "cfs" => "cfs",
    "cheetah" => "cheetah",
    "clojure" => "clojure",
    "cmake" => "cmake",
    "c-objdump" => "c-objdump",
    "coffee-script" => "coffee-script",
    "common-lisp" => "common-lisp",
    "console" => "console",
    "control" => "control",
    "coq" => "coq",
    "cpp" => "cpp",
    "cpp-objdump" => "cpp-objdump",
    "csharp" => "csharp",
    "css" => "css",
    "css+django" => "css+django",
    "css+erb" => "css+erb",
    "css+genshitext" => "css+genshitext",
    "css+mako" => "css+mako",
    "css+myghty" => "css+myghty",
    "css+php" => "css+php",
    "css+smarty" => "css+smarty",
    "Cucumber" => "Cucumber",
    "cython" => "cython",
    "d" => "d",
    "dart" => "dart",
    "delphi" => "delphi",
    "diff" => "diff",
    "django" => "django",
    "d-objdump" => "d-objdump",
    "dpatch" => "dpatch",
    "dtd" => "dtd",
    "duel" => "duel",
    "dylan" => "dylan",
    "ec" => "ec",
    "ecl" => "ecl",
    "elixir" => "elixir",
    "erb" => "erb",
    "erl" => "erl",
    "erlang" => "erlang",
    "evoque" => "evoque",
    "factor" => "factor",
    "fan" => "fan",
    "fancy" => "fancy",
    "felix" => "felix",
    "fortran" => "fortran",
    "fsharp" => "fsharp",
    "gas" => "gas",
    "genshi" => "genshi",
    "genshitext" => "genshitext",
    "glsl" => "glsl",
    "gnuplot" => "gnuplot",
    "go" => "go",
    "gooddata-cl" => "gooddata-cl",
    "gosu" => "gosu",
    "groff" => "groff",
    "groovy" => "groovy",
    "gst" => "gst",
    "haml" => "haml",
    "haskell" => "haskell",
    "html" => "html",
    "html+cheetah" => "html+cheetah",
    "html+django" => "html+django",
    "html+evoque" => "html+evoque",
    "html+genshi" => "html+genshi",
    "html+mako" => "html+mako",
    "html+myghty" => "html+myghty",
    "html+php" => "html+php",
    "html+smarty" => "html+smarty",
    "html+velocity" => "html+velocity",
    "http" => "http",
    "hx" => "hx",
    "hybris" => "hybris",
    "iex" => "iex",
    "ini" => "ini",
    "io" => "io",
    "ioke" => "ioke",
    "irc" => "irc",
    "jade" => "jade",
    "java" => "java",
    "js" => "js",
    "js+cheetah" => "js+cheetah",
    "js+django" => "js+django",
    "js+erb" => "js+erb",
    "js+genshitext" => "js+genshitext",
    "js+mako" => "js+mako",
    "js+myghty" => "js+myghty",
    "json" => "json",
    "jsp" => "jsp",
    "js+php" => "js+php",
    "js+smarty" => "js+smarty",
    "kotlin" => "kotlin",
    "lhs" => "lhs",
    "lighty" => "lighty",
    "llvm" => "llvm",
    "logtalk" => "logtalk",
    "lua" => "lua",
    "make" => "make",
    "mako" => "mako",
    "maql" => "maql",
    "mason" => "mason",
    "matlab" => "matlab",
    "matlabsession" => "matlabsession",
    "minid" => "minid",
    "modelica" => "modelica",
    "modula2" => "modula2",
    "moocode" => "moocode",
    "moon" => "moon",
    "mupad" => "mupad",
    "mxml" => "mxml",
    "myghty" => "myghty",
    "mysql" => "mysql",
    "nasm" => "nasm",
    "nemerle" => "nemerle",
    "newlisp" => "newlisp",
    "newspeak" => "newspeak",
    "nginx" => "nginx",
    "nimrod" => "nimrod",
    "numpy" => "numpy",
    "objdump" => "objdump",
    "objective-c" => "objective-c",
    "objective-j" => "objective-j",
    "ocaml" => "ocaml",
    "octave" => "octave",
    "ooc" => "ooc",
    "opa" => "opa",
    "openedge" => "openedge",
    "perl" => "perl",
    "php" => "php",
    "plpgsql" => "plpgsql",
    "postgresql" => "postgresql",
    "postscript" => "postscript",
    "pot" => "pot",
    "pov" => "pov",
    "powershell" => "powershell",
    "prolog" => "prolog",
    "properties" => "properties",
    "protobuf" => "protobuf",
    "psql" => "psql",
    "py3tb" => "py3tb",
    "pycon" => "pycon",
    "pypylog" => "pypylog",
    "pytb" => "pytb",
    "python" => "python",
    "python3" => "python3",
    "ragel" => "ragel",
    "ragel-c" => "ragel-c",
    "ragel-cpp" => "ragel-cpp",
    "ragel-d" => "ragel-d",
    "ragel-em" => "ragel-em",
    "ragel-java" => "ragel-java",
    "ragel-objc" => "ragel-objc",
    "ragel-ruby" => "ragel-ruby",
    "raw" => "raw",
    "rb" => "rb",
    "rbcon" => "rbcon",
    "rconsole" => "rconsole",
    "rebol" => "rebol",
    "redcode" => "redcode",
    "rhtml" => "rhtml",
    "rst" => "rst",
    "sass" => "sass",
    "scala" => "scala",
    "scaml" => "scaml",
    "scheme" => "scheme",
    "scilab" => "scilab",
    "scss" => "scss",
    "smalltalk" => "smalltalk",
    "smarty" => "smarty",
    "sml" => "sml",
    "snobol" => "snobol",
    "sourceslist" => "sourceslist",
    "splus" => "splus",
    "sql" => "sql",
    "sqlite3" => "sqlite3",
    "squidconf" => "squidconf",
    "ssp" => "ssp",
    "sv" => "sv",
    "tcl" => "tcl",
    "tcsh" => "tcsh",
    "tea" => "tea",
    "tex" => "tex",
    "text" => "text",
    "trac-wiki" => "trac-wiki",
    "urbiscript" => "urbiscript",
    "v" => "v",
    "vala" => "vala",
    "vb.net" => "vb.net",
    "velocity" => "velocity",
    "vhdl" => "vhdl",
    "vim" => "vim",
    "xml" => "xml",
    "xml+cheetah" => "xml+cheetah",
    "xml+django" => "xml+django",
    "xml+erb" => "xml+erb",
    "xml+evoque" => "xml+evoque",
    "xml+mako" => "xml+mako",
    "xml+myghty" => "xml+myghty",
    "xml+php" => "xml+php",
    "xml+smarty" => "xml+smarty",
    "xml+velocity" => "xml+velocity",
    "xquery" => "xquery",
    "xslt" => "xslt",
    "yaml" => "yaml",
};

sub uri { "https://paste.debian.net/" }

sub fill_form {
    my $self = shift;
    my $mech = shift;
    my %args = @_;
    my $lang = $languages->{$args{lang}} if $args{lang};

    $mech->form_number(1);
    if ($args{private}) {
        $mech->tick('private', '1');
    }
    $mech->submit_form(
        fields        => {
            code => $args{text},
            do { $args{nick} ? (poster => $args{nick}) : () },
            do { $lang ? (lang => $lang) : () },
        },
    );
}

sub return {
    my $self = shift;
    my $mech = shift;

    my $link = $mech->uri();

    return (1, $link);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Nopaste::Service::Debian - Service provider for Debian - https://paste.debian.net/

=head1 VERSION

version 1.013

=for stopwords Niebur

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=App-Nopaste>
(or L<bug-App-Nopaste@rt.cpan.org|mailto:bug-App-Nopaste@rt.cpan.org>).

=head1 AUTHOR

Ryan Niebur, <ryanryan52@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
