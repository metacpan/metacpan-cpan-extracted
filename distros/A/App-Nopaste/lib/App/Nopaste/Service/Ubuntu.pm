use strict;
use warnings;
package App::Nopaste::Service::Ubuntu;
# ABSTRACT: Service provider for Ubuntu - https://paste.ubuntu.com/

our $VERSION = '1.013';

use parent 'App::Nopaste::Service';

my $languages = {
    "Plain Text"                     => "text",
    "Gherkin"                        => "Cucumber",
    "ABAP"                           => "abap",
    "Ada"                            => "ada",
    "autohotkey"                     => "ahk",
    "ANTLR"                          => "antlr",
    "ANTLR With ActionScript Target" => "antlr-as",
    "ANTLR With CPP Target"          => "antlr-cpp",
    "ANTLR With C# Target"           => "antlr-csharp",
    "ANTLR With Java Target"         => "antlr-java",
    "ANTLR With ObjectiveC Target"   => "antlr-objc",
    "ANTLR With Perl Target"         => "antlr-perl",
    "ANTLR With Python Target"       => "antlr-python",
    "ANTLR With Ruby Target"         => "antlr-ruby",
    "ApacheConf"                     => "apacheconf",
    "AppleScript"                    => "applescript",
    "ActionScript"                   => "as",
    "ActionScript 3"                 => "as3",
    "aspx-cs"                        => "aspx-cs",
    "aspx-vb"                        => "aspx-vb",
    "Asymptote"                      => "asy",
    "Makefile"                       => "basemake",
    "Bash"                           => "bash",
    "Batchfile"                      => "bat",
    "BBCode"                         => "bbcode",
    "Befunge"                        => "befunge",
    "BlitzMax"                       => "blitzmax",
    "Boo"                            => "boo",
    "C"                              => "c",
    "c-objdump"                      => "c-objdump",
    "Coldfusion HTML"                => "cfm",
    "cfstatement"                    => "cfs",
    "Cheetah"                        => "cheetah",
    "Clojure"                        => "clojure",
    "CMake"                          => "cmake",
    "CoffeeScript"                   => "coffee-script",
    "Common Lisp"                    => "common-lisp",
    "Bash Session"                   => "console",
    "Debian Control file"            => "control",
    "C++"                            => "cpp",
    "cpp-objdump"                    => "cpp-objdump",
    "C#"                             => "csharp",
    "CSS"                            => "css",
    "CSS+Django/Jinja"               => "css+django",
    "CSS+Ruby"                       => "css+erb",
    "CSS+Genshi Text"                => "css+genshitext",
    "CSS+Mako"                       => "css+mako",
    "CSS+Myghty"                     => "css+myghty",
    "CSS+PHP"                        => "css+php",
    "CSS+Smarty"                     => "css+smarty",
    "Cython"                         => "cython",
    "D"                              => "d",
    "d-objdump"                      => "d-objdump",
    "Delphi"                         => "delphi",
    "Diff"                           => "diff",
    "Django/Jinja"                   => "django",
    "Darcs Patch"                    => "dpatch",
    "Duel"                           => "duel",
    "Dylan"                          => "dylan",
    "ERB"                            => "erb",
    "Erlang erl session"             => "erl",
    "Erlang"                         => "erlang",
    "Evoque"                         => "evoque",
    "Factor"                         => "factor",
    "Felix"                          => "felix",
    "Fortran"                        => "fortran",
    "GAS"                            => "gas",
    "Genshi"                         => "genshi",
    "Genshi Text"                    => "genshitext",
    "GLSL"                           => "glsl",
    "Gnuplot"                        => "gnuplot",
    "Go"                             => "go",
    "GoodData-CL"                    => "gooddata-cl",
    "Groff"                          => "groff",
    "Haml"                           => "haml",
    "Haskell"                        => "haskell",
    "HTML"                           => "html",
    "HTML+Cheetah"                   => "html+cheetah",
    "HTML+Django/Jinja"              => "html+django",
    "HTML+Evoque"                    => "html+evoque",
    "HTML+Genshi"                    => "html+genshi",
    "HTML+Mako"                      => "html+mako",
    "HTML+Myghty"                    => "html+myghty",
    "HTML+PHP"                       => "html+php",
    "HTML+Smarty"                    => "html+smarty",
    "HTML+Velocity"                  => "html+velocity",
    "haXe"                           => "hx",
    "Hybris"                         => "hybris",
    "INI"                            => "ini",
    "Io"                             => "io",
    "Ioke"                           => "ioke",
    "IRC logs"                       => "irc",
    "Jade"                           => "jade",
    "Java"                           => "java",
    "JavaScript"                     => "js",
    "JavaScript+Cheetah"             => "js+cheetah",
    "JavaScript+Django/Jinja"        => "js+django",
    "JavaScript+Ruby"                => "js+erb",
    "JavaScript+Genshi Text"         => "js+genshitext",
    "JavaScript+Mako"                => "js+mako",
    "JavaScript+Myghty"              => "js+myghty",
    "JavaScript+PHP"                 => "js+php",
    "JavaScript+Smarty"              => "js+smarty",
    "Java Server Page"               => "jsp",
    "Literate Haskell"               => "lhs",
    "Lighttpd configuration file"    => "lighty",
    "LLVM"                           => "llvm",
    "Logtalk"                        => "logtalk",
    "Lua"                            => "lua",
    "Makefile"                       => "make",
    "Mako"                           => "mako",
    "MAQL"                           => "maql",
    "Mason"                          => "mason",
    "Matlab"                         => "matlab",
    "Matlab session"                 => "matlabsession",
    "MiniD"                          => "minid",
    "Modelica"                       => "modelica",
    "Modula-2"                       => "modula2",
    "MOOCode"                        => "moocode",
    "MuPAD"                          => "mupad",
    "MXML"                           => "mxml",
    "Myghty"                         => "myghty",
    "MySQL"                          => "mysql",
    "NASM"                           => "nasm",
    "Newspeak"                       => "newspeak",
    "Nginx configuration file"       => "nginx",
    "NumPy"                          => "numpy",
    "objdump"                        => "objdump",
    "Objective-C"                    => "objective-c",
    "Objective-J"                    => "objective-j",
    "OCaml"                          => "ocaml",
    "Ooc"                            => "ooc",
    "Perl"                           => "perl",
    "PHP"                            => "php",
    "PostScript"                     => "postscript",
    "Gettext Catalog"                => "pot",
    "POVRay"                         => "pov",
    "Prolog"                         => "prolog",
    "Properties"                     => "properties",
    "Protocol Buffer"                => "protobuf",
    "Python 3.0 Traceback"           => "py3tb",
    "Python console session"         => "pycon",
    "Python Traceback"               => "pytb",
    "Python"                         => "python",
    "Python 3"                       => "python3",
    "Ragel"                          => "ragel",
    "Ragel in C Host"                => "ragel-c",
    "Ragel in CPP Host"              => "ragel-cpp",
    "Ragel in D Host"                => "ragel-d",
    "Embedded Ragel"                 => "ragel-em",
    "Ragel in Java Host"             => "ragel-java",
    "Ragel in Objective C Host"      => "ragel-objc",
    "Ragel in Ruby Host"             => "ragel-ruby",
    "Raw token data"                 => "raw",
    "Ruby"                           => "rb",
    "Ruby irb session"               => "rbcon",
    "RConsole"                       => "rconsole",
    "REBOL"                          => "rebol",
    "Redcode"                        => "redcode",
    "RHTML"                          => "rhtml",
    "reStructuredText"               => "rst",
    "Sass"                           => "sass",
    "Scala"                          => "scala",
    "Scaml"                          => "scaml",
    "Scheme"                         => "scheme",
    "SCSS"                           => "scss",
    "Smalltalk"                      => "smalltalk",
    "Smarty"                         => "smarty",
    "Debian Sourcelist"              => "sourceslist",
    "S"                              => "splus",
    "SQL"                            => "sql",
    "sqlite3con"                     => "sqlite3",
    "SquidConf"                      => "squidconf",
    "Scalate Server Page"            => "ssp",
    "Tcl"                            => "tcl",
    "Tcsh"                           => "tcsh",
    "TeX"                            => "tex",
    "Text only"                      => "text",
    "MoinMoin/Trac Wiki markup"      => "trac-wiki",
    "verilog"                        => "v",
    "Vala"                           => "vala",
    "VB.net"                         => "vb.net",
    "Velocity"                       => "velocity",
    "VimL"                           => "vim",
    "XML"                            => "xml",
    "XML+Cheetah"                    => "xml+cheetah",
    "XML+Django/Jinja"               => "xml+django",
    "XML+Ruby"                       => "xml+erb",
    "XML+Evoque"                     => "xml+evoque",
    "XML+Mako"                       => "xml+mako",
    "XML+Myghty"                     => "xml+myghty",
    "XML+PHP"                        => "xml+php",
    "XML+Smarty"                     => "xml+smarty",
    "XML+Velocity"                   => "xml+velocity",
    "XQuery"                         => "xquery",
    "XSLT"                           => "xslt",
    "YAML"                           => "yaml",
};

sub uri { "https://paste.ubuntu.com/" }

sub fill_form {
    my $self = shift;
    my $mech = shift;
    my %args = @_;
    my $lang = $languages->{$args{lang}} if $args{lang};

    $mech->form_number(1);
    $mech->submit_form(
        fields        => {
            content => $args{text},
            do { $args{nick} ? (poster => $args{nick}) : () },
            do { $lang ? (syntax => $lang) : () },
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

App::Nopaste::Service::Ubuntu - Service provider for Ubuntu - https://paste.ubuntu.com/

=head1 VERSION

version 1.013

=for stopwords Niebur gregor herrmann

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=App-Nopaste>
(or L<bug-App-Nopaste@rt.cpan.org|mailto:bug-App-Nopaste@rt.cpan.org>).

=head1 AUTHOR

gregor herrmann, <gregoa@debian.org>

(Based on App::Nopaste::Service::Debian, written by
Ryan Niebur, C<< <ryanryan52@gmail.com> >>)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
