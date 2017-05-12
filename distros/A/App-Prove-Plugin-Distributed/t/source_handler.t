#!/usr/bin/perl -w

=head1 DESCRIPTION

This test is modified of the source_handler.t of the Test-Harness distribution to test the  L<TAP::Parser::SourceHandler::Worker>.

=cut

BEGIN {
    unshift @INC, 't/lib';
}

use strict;

use Test::More tests => 12;

use IO::File;
use IO::Handle;
use File::Spec;

use TAP::Parser::Source;
use TAP::Parser::SourceHandler;

my $IS_WIN32 = ( $^O =~ /^(MS)?Win32$/ );
my $HAS_SH   = -x '/bin/sh';
my $HAS_ECHO = -x '/bin/echo';

my $dir = File::Spec->catdir(
    't',
    'source_tests'
);

my $perl = $^X;

my %file = map { $_ => File::Spec->catfile( $dir, $_ ) }
  qw( source );

# Worker TAP source tests
{
    my $class = 'TAP::Parser::SourceHandler::Worker';
    my $tests = {
        default_vote => 0,
        can_handle   => [
            {   name => '.t',
                meta => {
                    is_file => 1,
                    file    => { lc_ext => '.t', dir => '' }
                },
                vote => 0.8 + 0.01,
            },
            {   name => '.pl',
                meta => {
                    is_file => 1,
                    file    => { lc_ext => '.pl', dir => '' }
                },
                vote => 0.9 + 0.01,
            },
            {   name => 't/.../file',
                meta => {
                    is_file => 1,
                    file    => { lc_ext => '', dir => 't' }
                },
                vote => 0.75 + 0.01,
            },
            {   name => '#!...perl',
                meta => {
                    is_file => 1,
                    file    => {
                        lc_ext => '', dir => '', shebang => '#!/usr/bin/perl'
                    }
                },
                vote => 0.9 + 0.01,
            },
            {   name => 'file default',
                meta => {
                    is_file => 1,
                    file    => { lc_ext => '', dir => '' }
                },
                vote => 0.25 + 0.01,
            },
        ],
        make_iterator => [
            {   name          => $file{source},
                raw           => \$file{source},
                iclass        => 'TAP::Parser::Iterator::Stream::Selectable',
                output        => [ '1..1', 'ok 1 - source' ],
                assemble_meta => 1,
            },
        ],
    };

    test_handler( $class, $tests );
}

###############################################################################
# helper sub

sub test_handler {
    my ( $class, $tests ) = @_;
    my ($short_class) = ( $class =~ /\:\:(\w+)$/ );

    use_ok $class;
    can_ok $class, 'can_handle', 'make_iterator';

    {
        my $default_vote = $tests->{default_vote} || 0;
        my $source = TAP::Parser::Source->new;
        is( $class->can_handle($source), $default_vote,
            '... can_handle default vote'
        );
    }

    for my $test ( @{ $tests->{can_handle} } ) {
        my $source = TAP::Parser::Source->new;
        $source->raw( $test->{raw} )       if $test->{raw};
        $source->meta( $test->{meta} )     if $test->{meta};
        $source->config( $test->{config} ) if $test->{config};
        $source->assemble_meta             if $test->{assemble_meta};
        my $vote = $test->{vote} || 0;
        my $name = $test->{name} || 'unnamed test';
        $name = "$short_class->can_handle( $name )";
        is( $class->can_handle($source), $vote, $name );
    }

    for my $test ( @{ $tests->{make_iterator} } ) {
        my $name = $test->{name} || 'unnamed test';
        $name = "$short_class->make_iterator( $name )";

        SKIP:
        {
            my $planned = 1;
            $planned += 1 + scalar @{ $test->{output} } if $test->{output};
            skip $test->{skip_reason}, $planned if $test->{skip};

            my $source = TAP::Parser::Source->new;
            $source->raw( $test->{raw} )       if $test->{raw};
            $source->test_args( $test->{test_args} ) if $test->{test_args};
            $source->meta( $test->{meta} )     if $test->{meta};
            $source->config( $test->{config} ) if $test->{config};
            $source->assemble_meta             if $test->{assemble_meta};

            my $iterator = eval { $class->make_iterator($source) };
            my $e = $@;
            if ( my $error = $test->{error} ) {
                $e = '' unless defined $e;
                like $e, $error, "$name threw expected error";
                next;
            }
            elsif ($e) {
                fail("$name threw an unexpected error");
                diag($e);
                next;
            }

            isa_ok $iterator, $test->{iclass}, $name;
            if ( $test->{output} ) {
                my $i = 1;
                for my $line ( @{ $test->{output} } ) {
                    is $iterator->next, $line, "... line $i";
                    $i++;
                }
                ok !$iterator->next, '... and we should have no more results';
            }
        }
    }
}
