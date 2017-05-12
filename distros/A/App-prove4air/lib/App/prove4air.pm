package App::prove4air;
BEGIN {
  $App::prove4air::VERSION = '0.0013';
}
# ABSTRACT: Test ActionScript (.as) with prove, Adobe Air, and tap4air

use strict;
use warnings;

use Path::Class;
use File::Temp qw/ tempdir /;
use File::Copy qw/ copy /;
use IPC::System::Simple();
use Getopt::Long qw/ GetOptions :config pass_through /;

sub run {
    my $self = shift;
    my @arguments = @_;

    my ( $build_air, $run_air, $exit );
    $build_air = $ENV{ BUILD_AIR } or do {
        print STDERR <<_END_;
*** Missing \$BUILD_AIR, try:
# BUILD_AIR=\$AIR_SDK/bin/mxmlc -incremental +configname=air -compiler.source-path=src/ -debug
_END_
        $build_air = '';
        $exit = 1
    };
    $run_air = $ENV{ RUN_AIR } or do {
        print STDERR <<_END_;
*** Missing \$RUN_AIR, try:
# RUN_AIR=AIR_SDK/bin/adl
_END_
        $run_air = '';
        $exit = 1
    };

    if ( $exit ) {
        exit 64;
    }

    my ( $exec );
    $exec = $ENV{TAP_VERSION} ? 1 : 0;
    {
        local @ARGV = @arguments;
        GetOptions( exec => \$exec );
        @arguments = @ARGV;
    }

    if ( $exec ) {
        $self->test( $arguments[ 0 ],
            build_air => $build_air,
            run_air => $run_air,
        );
    }
    else {
        require App::Prove;
        my $prove = App::Prove->new;
        $prove->process_args( @arguments );
        $prove->{exec} ||= "$0 --exec";
        $prove->{extension} ||= '.t.as';
        $prove->run;
    }
}

sub test {
    my $self = shift;
    my $script = shift;
    my %context = @_;

    die "*** Missing test (.t.as) script" unless defined $script && length $script;

    $script = file $script;

    my %test;
    $test{ dir } = dir( '.t', (join '-', $script->parent->dir_list, $script->basename ) );
    $test{ dir }->mkpath;
    $test{ script }     = $test{dir}->file( 'test.as' );
    $test{ xml }        = $test{dir}->file( 'test.xml' );
    $test{ result }     = $test{dir}->file( 'result.tap' );

    my ( @content, @import_content, @test_content );
    if ( ! -s $test{ script } || $test{ script }->stat->mtime < $script->stat->mtime ) {
        @content = $script->slurp;
        if ( $content[ 0 ] =~ m/^\s*\/\/\s*!(?:tap4air|prove4air)\b/ ) {
            my $split = -1;
            my $found = 0;
            for ( @content ) {
                $split += 1;
                if ( m/^\s*\/\/\s*\-\-\-\s*$/ ) {
                    $found = 1;
                    last;
                }
            }

            if ( $found ) {
                @import_content = @content[ 1 .. $split - 1 ];
                @test_content = @content[ $split + 1 .. @content - 1 ];
            }
            else {
                @test_content = @content[ 1 .. @content - 1 ];
            }
        }

        my $xmlns;
        $xmlns = "http://ns.adobe.com/air/application/1.5";
        $xmlns = "http://ns.adobe.com/air/application/2.0";

        if ( @test_content ) {
            $test{ script }->openw->print( <<_END_ );
package {

import yzzy.tap4air.Test;
import mx.core.UIComponent;
import flash.desktop.NativeApplication;
@{[ join '', @import_content ]}

    public class test extends UIComponent {
        
        public function test() {
var \$:* = Test.singleton();
@{[ join '', @test_content ]}
\$.exit();
        }
    }
}
_END_

            $test{ xml }->openw->print( <<_END_ );
<?xml version="1.0" encoding="UTF-8"?>
<application xmlns="$xmlns">
    <id>test</id>
    <version>0.0</version>
    <filename>test</filename>
    <initialWindow>
        <content>test.swf</content>
    </initialWindow>
</application>
_END_
        }
        else {
            my $xml = $script->parent->file( 'test.xml' );
            die "*** Missing .xml file" unless -s $xml;

            copy "$xml", "$test{ xml }" or die "Failed copy => $xml";

            if ( ! -s $test{ script } || $test{ script }->stat->mtime < $script->stat->mtime ) {
                copy "$script", "$test{ script }" or die "Failed copy $script => $test{ script }";
            }
        }
    }

    IPC::System::Simple::run( "$context{ build_air } $test{ script }" );
    IPC::System::Simple::run( "$context{ run_air } $test{ xml } > $test{ result }" );
    print $test{ result }->slurp;
}

1;



=pod

=head1 NAME

App::prove4air - Test ActionScript (.as) with prove, Adobe Air, and tap4air

=head1 VERSION

version 0.0013

=head1 SYNOPSIS

    $ git clone git://github.com/robertkrimen/tap4air.git tap4air
    $ export BUILD_AIR="$AIR_SDK/bin/mxmlc -incremental +configname=air -compiler.source-path=tap4air/src/ -debug"
    $ export RUN_AIR="$AIR_SDK/bin/adl"

    # Run against every .t.as in t/
    $ prove4air t/

=head1 DESCRIPTION

App::prove4air integrates with App::Prove and tap4air to provide prove-like TAP-testing in Adobe Air

=head1 An example test file

    // !prove4air
    // ---
    $.ok( 1, 'ok' );
    $.equal( 1, 1, 'equal' );
    $.unequal( 1, 2, 'unequal' );
    $.like( 'Xyzzy', /yzzy/, 'like' );
    $.unlike( 'Xyzzy', /Y/, 'unlike' );

=head1 An example test with an import

    // !prove4air
    import com.example.Example;
    // ---
    $.ok( 1, 'ok' );
    $.equal( 1, 1, 'equal' );

=head1 A test example in another (more traditional) style

    package {
        import yzzy.tap4air.Test;
        import mx.core.UIComponent;
        import flash.desktop.NativeApplication;

        public class test extends UIComponent {

            public function test() {
                Test.ok( 1, 'ok' );
                Test.equal( 1, 1, 'equal' );
                Test.unequal( 1, 2, 'unequal' );
                Test.like( 'Xyzzy', /yzzy/, 'like' );
                Test.unlike( 'Xyzzy', /Y/, 'unlike' );
                Test.exit();
            }
        }
    }

=head1 SEE ALSO

L<http://github.com/robertkrimen/tap4air>

L<App::Prove>

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

