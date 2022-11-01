#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 28;
use Test::Trap
    qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

use App::XML::DocBook::Docmake ();

package MyTest::DocmakeAppDebug;

use vars qw(@commands_executed);

use parent 'App::XML::DocBook::Docmake';

sub _exec_command
{
    my ( $self, $args ) = @_;

    my $cmd = $args->{cmd};
    push @commands_executed, [@$cmd];
}

sub _mkdir
{
    # Do nothing - to override.
}

sub debug_commands
{
    my @ret = @commands_executed;

    # Reset the commands to allow for future use.
    @commands_executed = ();

    return \@ret;
}

package MyTest::DocmakeAppDebug::Newer;

use vars qw($should_update);

use vars qw(@ISA);

@ISA = ('MyTest::DocmakeAppDebug');

sub _should_update_output
{
    return $should_update->(@_);
}

package main;

{
    my $docmake = App::XML::DocBook::Docmake->new( { argv => ["help"] } );

    # TEST
    ok( $docmake, "Testing that docmake was initialized" );
}

{
    my $docmake = App::XML::DocBook::Docmake->new( { argv => ["help"] } );

    trap { $docmake->run(); };

    # TEST
    like(
        $trap->stdout(),
qr{Docmake version.*^A tool to convert DocBook/XML to other formats.*^Available commands:\n}ms,
        "Testing output of help"
    );
}

{
    my $docmake = MyTest::DocmakeAppDebug->new(
        {
            argv => [
                "-v",                    "--stringparam",
                "chunk.section.depth=2", "-o",
                "my-output-dir",         "xhtml",
                "input.xml",
            ]
        }
    );

    # TEST
    ok( $docmake, "Docmake was constructed successfully" );

    $docmake->run();

    # TEST
    is_deeply(
        MyTest::DocmakeAppDebug->debug_commands(),
        [
            [
                "xsltproc",
                "--nonet",
                "-o",
                "my-output-dir/",
                "--stringparam",
                "chunk.section.depth",
                "2",
"http://docbook.sourceforge.net/release/xsl/current/xhtml/docbook.xsl",
                "input.xml",
            ]
        ],
        "stringparam is propagated to the xsltproc command",
    );
}

{
    my @should_update;
    local $MyTest::DocmakeAppDebug::Newer::should_update = sub {
        my $self = shift;
        my $args = shift;
        push @should_update,
            [
            map      { $_ => $args->{$_} }
                sort { $a cmp $b }
                keys(%$args)
            ];
        return 1;
    };
    my $docmake = MyTest::DocmakeAppDebug::Newer->new(
        {
            argv => [
                "-v",  "--make", "-o", "GOTO-THE-output.pdf",
                "pdf", "MYMY-input.xml",
            ]
        }
    );

    # TEST
    ok( $docmake, "Docmake was constructed successfully" );

    $docmake->run();

    # TEST
    is_deeply(
        MyTest::DocmakeAppDebug->debug_commands(),
        [
            [
                "xsltproc",
                "--nonet",
                "-o",
                "GOTO-THE-output.fo",
"http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl",
                "MYMY-input.xml",
            ],
            [ "fop", "-pdf", "GOTO-THE-output.pdf", "GOTO-THE-output.fo", ],
        ],
        "Making sure all commands got run",
    );

    # TEST
    is_deeply(
        \@should_update,
        [
            [ "input", "MYMY-input.xml",     "output", "GOTO-THE-output.fo" ],
            [ "input", "GOTO-THE-output.fo", "output", "GOTO-THE-output.pdf" ],
        ],
        "should update is OK.",
    );
}

{
    my @should_update;
    local $MyTest::DocmakeAppDebug::Newer::should_update = sub {
        my $self = shift;
        my $args = shift;
        push @should_update,
            [
            map      { $_ => $args->{$_} }
                sort { $a cmp $b }
                keys(%$args)
            ];
        return 0;
    };
    my $docmake = MyTest::DocmakeAppDebug::Newer->new(
        {
            argv => [
                "-v",  "--make", "-o", "GOTO-THE-output.pdf",
                "pdf", "MYMY-input.xml",
            ]
        }
    );

    # TEST
    ok( $docmake, "Docmake was constructed successfully" );

    $docmake->run();

    # TEST
    is_deeply(
        MyTest::DocmakeAppDebug->debug_commands(),
        [], "No commands got run because of should_update",
    );

    # TEST
    is_deeply(
        \@should_update,
        [
            [ "input", "MYMY-input.xml",     "output", "GOTO-THE-output.fo" ],
            [ "input", "GOTO-THE-output.fo", "output", "GOTO-THE-output.pdf" ],
        ],
        "should update is OK.",
    );
}

{
    my $docmake = MyTest::DocmakeAppDebug->new(
        { argv => [ "-v", "-o", "my-output", "pdf", "input.xml", ] } );

    # TEST
    ok( $docmake, "Docmake was constructed successfully" );

    $docmake->run();

    # TEST
    is_deeply(
        MyTest::DocmakeAppDebug->debug_commands(),
        [
            [
                "xsltproc",
                "--nonet",
                "-o",
                "my-output.fo",
"http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl",
                "input.xml",
            ],
            [ "fop", "-pdf", "my-output", "my-output.fo", ],
        ],
"testing that .fo is added if the pdf filename does not contain a prefix",
    );
}

{
    my $docmake = MyTest::DocmakeAppDebug->new(
        {
            argv => [
                "-v",            "--stringparam",
                "empty.param=",  "-o",
                "my-output-dir", "xhtml",
                "input.xml",
            ]
        }
    );

    # TEST
    ok( $docmake, "Docmake was constructed successfully" );

    $docmake->run();

    # TEST
    is_deeply(
        MyTest::DocmakeAppDebug->debug_commands(),
        [
            [
                "xsltproc",
                "--nonet",
                "-o",
                "my-output-dir/",
                "--stringparam",
                "empty.param",
                "",
"http://docbook.sourceforge.net/release/xsl/current/xhtml/docbook.xsl",
                "input.xml",
            ]
        ],
"an empty stringparam is accepted and propagated to the xsltproc command",
    );
}

{
    my $docmake = MyTest::DocmakeAppDebug->new(
        {
            argv => [
                "-v",            "--stringparam",
                "empty.param=",  "-o",
                "my-output-dir", "xhtml-1_1",
                "input.xml",
            ]
        }
    );

    # TEST
    ok( $docmake, "xhtml-1_1 docmake was constructed successfully" );

    $docmake->run();

    # TEST
    is_deeply(
        MyTest::DocmakeAppDebug->debug_commands(),
        [
            [
                "xsltproc",
                "--nonet",
                "-o",
                "my-output-dir/",
                "--stringparam",
                "empty.param",
                "",
"http://docbook.sourceforge.net/release/xsl/current/xhtml-1_1/docbook.xsl",
                "input.xml",
            ]
        ],
        "Testing xhtml-1_1",
    );
}

{
    my $docmake = MyTest::DocmakeAppDebug->new(
        {
            argv => [
                "-v",            "--stringparam",
                "empty.param=",  "-o",
                "my-output-dir", "xhtml5",
                "input.xml",
            ]
        }
    );

    # TEST
    ok( $docmake, "xhtml5 docmake was constructed successfully" );

    $docmake->run();

    # TEST
    is_deeply(
        MyTest::DocmakeAppDebug->debug_commands(),
        [
            [
                "xsltproc",
                "--nonet",
                "-o",
                "my-output-dir/",
                "--stringparam",
                "empty.param",
                "",
"http://docbook.sourceforge.net/release/xsl/current/xhtml5/docbook.xsl",
                "input.xml",
            ]
        ],
        "Testing xhtml5",
    );
}

{
    my $docmake = MyTest::DocmakeAppDebug->new(
        {
            argv => [
                "-v",
                "--stringparam",
"root.filename=lib/docbook/5/essays/foss-and-other-beasts-v3/all-in-one.xhtml.temp.xml",
                "--basepath",
"/home/shlomif/Download/unpack/file/docbook/docbook-xsl-ns-snapshot",
                "--stylesheet",
"lib/sgml/shlomif-docbook/xsl-5-stylesheets/shlomif-essays-5-xhtml-onechunk.xsl",
                "xhtml-1_1",
                "lib/docbook/5/xml/foss-and-other-beasts-v3.xml",
            ]
        }
    );

    # TEST
    ok( $docmake, "DocBook 5 (with --basepath) was initialized." );

    $docmake->run();

    # TEST
    is_deeply(
        MyTest::DocmakeAppDebug->debug_commands(),
        [
            [
                "xsltproc",
                "--nonet",
                "--stringparam",
                "root.filename",
"lib/docbook/5/essays/foss-and-other-beasts-v3/all-in-one.xhtml.temp.xml",
                "--path",
"/home/shlomif/Download/unpack/file/docbook/docbook-xsl-ns-snapshot/xhtml-1_1",
"lib/sgml/shlomif-docbook/xsl-5-stylesheets/shlomif-essays-5-xhtml-onechunk.xsl",
                "lib/docbook/5/xml/foss-and-other-beasts-v3.xml",
            ]
        ],
        "Testing DocBook 5 (with --basepath)",
    );
}

{
    my $docmake =
        MyTest::DocmakeAppDebug->new( { argv => [ "pdf", "input.xml", ] } );

    # TEST
    ok( $docmake, "Docmake was constructed successfully" );

    trap
    {
        $docmake->run();
    };

    # TEST
    like(
        $trap->die(),
        qr/No -o flag was specified/,
        "Testing that an exception was thrown on pdf without the -o flag",
    );

    # TEST
    is_deeply(
        MyTest::DocmakeAppDebug->debug_commands(),
        [], "Testing that no commands were run on pdf without the -o flag",
    );

}

{
    my $docmake = MyTest::DocmakeAppDebug->new(
        {
            argv => [
                "-v",           "--stringparam",
                "empty.param=", "--trailing-slash=0",
                "-o",           "my-output-dir/notneeded.xhtml",
                "xhtml5",       "input.xml",
            ]
        }
    );

    # TEST
    ok( $docmake, "xhtml5 docmake was constructed successfully" );

    $docmake->run();

    # TEST
    ok( scalar( !-e "my-output-dir/notneeded.xhtml" ), "not created." );

    # TEST
    is_deeply(
        MyTest::DocmakeAppDebug->debug_commands(),
        [
            [
                "xsltproc",
                "--nonet",
                "-o",
                "my-output-dir/notneeded.xhtml",
                "--stringparam",
                "empty.param",
                "",
"http://docbook.sourceforge.net/release/xsl/current/xhtml5/docbook.xsl",
                "input.xml",
            ]
        ],
        "Testing xhtml5 trailing slash",
    );
}

{
    my $docmake = MyTest::DocmakeAppDebug->new(
        {
            argv => [
                "-v",            "--ns",
                "--stringparam", "empty.param=",
                "-o",            "my-output-dir",
                "xhtml5",        "input.xml",
            ]
        }
    );

    # TEST
    ok( $docmake, "xhtml5 namespacesed docmake was constructed successfully" );

    $docmake->run();

    # TEST
    is_deeply(
        MyTest::DocmakeAppDebug->debug_commands(),
        [
            [
                "xsltproc",
                "--nonet",
                "-o",
                "my-output-dir/",
                "--stringparam",
                "empty.param",
                "",
"http://docbook.sourceforge.net/release/xsl-ns/current/xhtml5/docbook.xsl",
                "input.xml",
            ]
        ],
        "Testing xhtml5 namespacesed",
    );
}

