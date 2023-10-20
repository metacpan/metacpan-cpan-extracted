#! perl

use v5.20;

use Test2::V0;
use Test::Lib;

use My::Test::AutoCleanHash;
use Data::Dumper;
use OptArgs2;

use experimental 'signatures', 'postderef';

package My::Form {

    use Form::Tiny plugins => ['+CXC::Form::Tiny::Plugin::OptArgs2'];

    use Types::Standard       qw( Any ArrayRef Bool Enum HashRef Str );
    use Types::Path::Tiny     qw( Path File Dir);
    use Types::Common::String qw( NonEmptyStr );

    form_field 'dir' => ( type => Dir, coerce => 1 );
    option( comment => 'existing directory', );

    form_field 'file' => ( type => File, coerce => 1 );
    option(
        comment  => 'Query in a file',
        isa_name => 'ADQL in a file',
    );

    form_field 'adql' => ( type => NonEmptyStr, );
    option(
        comment  => 'Query on the command line',
        isa_name => 'ADQL',
    );

    form_field 'url' => (
        type    => Str,
        default => sub { 'https://cda.cfa.harvard.edu/csc2tap' },
    );

    option(
        comment      => 'CSC TAP endpoint',
        isa_name     => 'URL',
        show_default => 1,
    );

    form_field 'output.file' => ( type => Path, coerce => 1 );
    option(
        name     => 'output',
        comment  => 'File to store parsed results',
        isa_name => 'filename',
    );

    form_field 'output.encoding' => ( type => Enum [ 'json', 'yaml' ], );
    option(
        name    => 'encoding',
        comment => sprintf( 'encoding format for --output [%s]', join( ' | ', qw( json yaml ) ) ),
    );

    form_field 'raw.encoding' => ( type => Enum [ 'foo', 'bar' ], );
    option(
        name    => 'raw-format',
        comment => sprintf( 'requested VO format [%s]', join( ' | ', qw( foo bar ) ) ),
    );

    form_field 'raw.file' => ( type => Path, coerce => 1 );
    option(
        name     => 'raw-output',
        comment  => 'store raw results from CSC server in this file',
        isa_name => 'filename',
    );


    form_field 'upload' => ( type => HashRef [NonEmptyStr], );
    option( comment => 'table name/filename pairs to upload', );

    form_field 'vars' => (
        type    => HashRef [Str],
        default => sub { { a => 1 } },
    );
    option(
        name    => 'var',
        comment => 'variables to interpolate into query template',
    );

    form_field 'use_db' => (
        type    => Bool,
        default => sub { 0 },
    );
    option(
        name    => 'db',
        comment => 'output to database instead of a file',
    );

    form_field 'any_thing_goes' => ( type => Any, );
    option( comment => 'the world is your oyster', );

    # add some arguments, in reverse order

    form_field 'arg2' => ( type => ArrayRef, );
    argument(
        comment => 'every thing else',
        greedy  => 1,
        order   => 2,
    );

    form_field 'arg1' => ( type => Any, );
    argument(
        comment => 'first argument',
        order   => 1,
    );
}


sub options {
    {
        'raw-output' => 3,
        'raw-format' => 'foo',
        encoding     => 'json',
        dir          => 't/data',
        file         => 't/data/cscquery.csc',
        output       => 2,
        url          => 1,
        # files need to exist; test doesn't do anything with them.
        upload => {
            table1 => 't/data/cscquery.csc',
            table2 => 't/data/cscquery.csc',
        },
        arg1           => 'val1',
        arg2           => [ 'val2.1', 'val2.2' ],
        any_thing_goes => 'Uppsala',
    };
}



sub argv {
    my %argv = options()->%*;

    my @args = ( delete( $argv{arg1} ), delete( $argv{arg2} )->@* );

    @ARGV = ();
    for my $arg ( keys %argv ) {
        my $value = $argv{$arg};

        if ( !ref $value ) {
            push @ARGV, "--$arg", $value;
        }
        else {
            for my $key ( keys $value->%* ) {
                push @ARGV, "--$arg", join q{=}, $key, $value->{$key};
            }
        }
    }

    push @ARGV, @args;
}

my $form = My::Form->new;

argv();
my $args;

ok( lives { $args = optargs( comment => 'comment', optargs => $form->optargs ) },
    'form->optargs accepted by OptArgs2::optargs' )
  or bail_out( $@ );

{
    tie my %options, 'My::Test::AutoCleanHash', options();

    is(
        $args,
        hash {
            field arg1         => $options{arg1};
            field arg2         => $options{arg2};
            field file         => $options{file};
            field dir          => $options{dir};
            field url          => $options{url};
            field output       => $options{output};
            field encoding     => $options{encoding};
            field 'raw-output' => $options{'raw-output'};
            field 'raw-format' => $options{'raw-format'};
            field upload       => hash {
                my %upload = $options{upload}->%*;
                field $_ => $upload{$_} for keys %upload;
                end;
            };
            field any_thing_goes => $options{any_thing_goes};
            end;
        },
        'optargs correctly parsed command line input',
    );

    bail_out( q{didn' t process all of the options : } . join q{,}, keys %options )
      if keys %options;
}


ok(
    lives {
        $form->set_input_from_optargs( $args )
    },
    'set input from optargs output',
);

ok( $form->valid, 'form validated input' )
  or bail_out Dumper( $form->errors_hash );

{
    tie my %options, 'My::Test::AutoCleanHash', options();

    is(
        $form->fields,
        hash {
            field arg1   => $options{arg1};
            field arg2   => $options{arg2};
            field file   => $options{file};
            field dir    => $options{dir};
            field url    => $options{url};
            field output => hash {
                field file     => $options{output};
                field encoding => $options{encoding};
                end;
            };
            field raw => hash {
                field file     => $options{'raw-output'};
                field encoding => $options{'raw-format'};
                end;
            };
            end;
            field upload => hash {
                my %upload = $options{upload}->%*;
                field $_ => $upload{$_} for keys %upload;
                end;
            };
            field use_db => F();
            field vars   => hash {
                field a => 1;
                end;
            };
            field any_thing_goes => $options{any_thing_goes};
            end;
        },
        'form fields match expectations',
    );

    bail_out( q{didn't process all of the options: } . join q{,}, keys %options )
      if keys %options;

}


done_testing;
