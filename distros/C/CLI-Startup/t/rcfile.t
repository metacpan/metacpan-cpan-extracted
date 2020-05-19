# Test reading and writing of RC files

use Test::More;
use Test::Trap;
use Test::Exception;

eval "use CLI::Startup";
plan skip_all => "Can't load CLI::Startup" if $@;

use Cwd;

# Create a temp directory
my $dir    = getcwd();
my $rcfile = "$dir/tmp/rcfile";
mkdir "$dir/tmp" or plan skip_all => "Can't create temp directory";

# Reading a nonexistent file should silently succeed
{
    my $app3 = CLI::Startup->new({
        rcfile  => "$dir/tmp/no_such_file",
        options => { foo => 'bar' },
    });
    lives_ok { $app3->init } "Init with nonexistent file";
    is_deeply $app3->get_config, { default => {} }, "Config is empty";
}

# Repeat the above, using a command-line argument instead of
# an option in the constructor.
{
    local @ARGV = ( "--rcfile=$dir/tmp/no_such_file" );
    my $app = CLI::Startup->new({ foo => 'bar' });
    lives_ok { $app->init } "Init with command-line rcfile";
    ok $app->get_rcfile eq "$dir/tmp/no_such_file", "rcfile set correctly";
    is_deeply $app->get_config, { default => {} }, "Config is empty";
}

# Specify a blank config-file name, then try to write it. That should
# fail with an error.
{
    my $app = CLI::Startup->new({
        rcfile  => '',
        options => { foo => 'bar' },
    });
    ok $app->get_rcfile eq '', "Set blank rcfile name";

    local @ARGV = ('--write-rcfile');
    trap { $app->init() };

    ok $trap->leaveby eq 'die', "App died trying to write file";
    like $trap->die, qr/no file specified/, "Correct error message";
}

# Specify a blank config file on the command line. That should also fail.
{
    my $app = CLI::Startup->new({ foo => 'bar' });

    local @ARGV = ('--rcfile', '', '--write-rcfile');
    trap { $app->init() };

    ok $trap->leaveby eq 'die', "Error exit trying to write file";
    like $trap->die, qr/no file specified/, "Correct error message";
}

# Don't specify any config file on the command line. That should also fail.
{
    my $app = CLI::Startup->new({ foo => 'bar' });

    local @ARGV = ('--rcfile=', '--write-rcfile');
    trap { $app->init() };

    ok $trap->leaveby eq 'die', "Error exit trying to write file";
    like $trap->die, qr/no file specified/, "Correct error message";
}

# Specify a config file in the constructor, then change it, and
# THEN specify a different config file on the command line. The
# one on the command line should win.
{
    # Create a CLI::Startup object and read the rc file
    my $app = CLI::Startup->new( {
            rcfile  => '/foo',
            options => { foo => 'bar' },
    } );
    ok $app->get_rcfile eq '/foo', "Set rcfile in constructor";

    $app->set_rcfile('/bar');
    ok $app->get_rcfile eq '/bar', "Changed rcfile in mutator";

    local @ARGV = ('--rcfile=/baz');
    $app->init();
    ok $app->get_rcfile eq '/baz', "Command line override rcfile";
}

# Write and read various different types of RC file
{
    local @ARGV = ();

    # All the config files should contain this data structure
    $config = {
        default => {
            foo     => 1,
            bar     => 'baz',
            baz     => 0,
            hash    => { a => 1, b => 2, c => 3 },
            list    => [ 1, 2, 3, 'purple' ],
        },
        extras  => { a => 1, b => 2, c => '3, 4, 5', }
    };

    # When parsed, the options should include verbose => 0 as well.
    my $options = { %{$config->{default}}, verbose => 0 };


    # These are the command-line options corresponding to the 
    # above config file contents.
    my $optspec = {
        'foo'     => 'foo option',
        'bar=s'   => 'bar option',
        'baz'     => 'baz option',
        'hash=s%' => 'Hashy option',
        'list=s@' => 'Listy option',
    };

    my $app1;

    # First: Perl config
    {
        open OUT, '>', $rcfile;
        print OUT qq{
            {
                'default'  => {
                    'foo'  => 1,
                    'bar'  => 'baz',
                    'baz'  => 0,
                    'hash' => { a => 1, b => 2, c => 3 },
                    'list' => [ 1, 2, 3, 'purple' ],
                },
                'extras'  => {
                    'a' => 1,
                    'b' => 2,
                    'c' => '3, 4, 5',
                },
            }
        };
        close OUT;

        $app1 = CLI::Startup->new({
            rcfile  => $rcfile,
            options => $optspec,
        });
        $app1->init;

        # Verify the raw command line options, the final options, and the
        # config file contents.
        is_deeply $app1->get_config, $config, "Read Perl config correctly";
        is_deeply $app1->get_options, $options,
            "...with the correct program options";
        is_deeply $app1->get_raw_options, {}, "...and an empty command line";

        # Verify that the config file can be written in an indempotent fashion
        trap { $app1->_write_rcfile_perl($rcfile) };
        ok $trap->leaveby eq "return", "Wrote Perl config successfully";

        my $app2 = CLI::Startup->new({
            rcfile  => $rcfile,
            options => $optspec,
        });
        $app2->init;

        is_deeply $app2->get_config, $config, "Reread Perl config correctly";
    }

    # If available: INI-style file
    SKIP: {
        my $tests = 7;

        eval "use Config::INI::Writer";
        skip("Config::INI::Writer is not installed", $tests) if $@;

        eval "use Config::Any::INI";
        skip("Config::Any::INI is not installed", $tests) if $@;
        skip("INI config files not supported", $tests)
            unless Config::Any::INI->is_supported;

        trap { $app1->_write_rcfile_ini($rcfile) };
        ok $trap->leaveby eq "return", "Wrote INI config successfully";

        my $app2 = CLI::Startup->new({
            rcfile  => $rcfile,
            options => $optspec,
        });
        $app2->init;

        is_deeply $app2->get_config, $config, "Read INI config correctly";
        is_deeply $app1->get_options, $options,
            "...with the correct program options";
        is_deeply $app2->get_raw_options, {}, "...and an empty command line";

        # While we're here, test simple name/value pairs. They're actually
        # parsed by the INI-file parser.
        my $config = {
            default => {
                foo => 'bar',
                bar => 'baz',
            },
        };

        # First: Bare name/value pairs. This doesn't support
        # extra data.
        open OUT, ">", $rcfile;
        print OUT "foo=bar\nbar=baz\n";
        close OUT;

        my $app3 = CLI::Startup->new({
            rcfile  => $rcfile,
            options => { a => 1 },
        });
        $app3->init;

        is_deeply $app3->get_config, $config, "Read simple config correctly";
        is_deeply $app3->get_options, { foo => 'bar', bar => 'baz', verbose => 0 },
            "...with the correct program options";
        is_deeply $app3->get_raw_options, {}, "...and an empty command line";
    }

    # If available: YAML config
    SKIP: {
        my $tests = 4;

        eval "use YAML::Any";
        skip("YAML::Any is not installed", $tests) if $@;

        eval "use Config::Any::YAML";
        skip("Config::Any::YAML is not installed", $tests) if $@;
        skip("YAML config files not supported", $tests)
            unless Config::Any::YAML->is_supported;

        trap { $app1->_write_rcfile_yaml($rcfile) };
        ok $trap->leaveby eq "return", "Wrote YAML config successfully";

        my $app2 = CLI::Startup->new({
            rcfile  => $rcfile,
            options => $optspec,
        });
        $app2->init;

        is_deeply $app2->get_config, $config, "Read YAML config correctly";
        is_deeply $app1->get_options, $options,
            "...with the correct program options";
        is_deeply $app2->get_raw_options, {}, "...and an empty command line";
    }

    # If available: JSON config
    SKIP: {
        my $tests = 4;

        eval "use JSON::MaybeXS";
        skip("JSON::MaybeXS is not installed", $tests) if $@;

        eval "use Config::Any::JSON";
        skip("Config::Any::JSON is not installed", $tests) if $@;
        skip("JSON config files not supported", $tests)
            unless Config::Any::YAML->is_supported;

        trap { $app1->_write_rcfile_json($rcfile) };
        ok $trap->leaveby eq "return", "Wrote JSON config successfully";

        my $app2 = CLI::Startup->new({
            rcfile  => $rcfile,
            options => $optspec,
        });
        $app2->init;

        is_deeply $app2->get_config, $config, "Read JSON config correctly";
        is_deeply $app1->get_options, $options,
            "...with the correct program options";
        is_deeply $app2->get_raw_options, {}, "...and an empty command line";
    }

    # If available: XML config
    SKIP: {
        my $tests = 4;

        eval "use XML::Simple";
        skip("XML::Simple is not installed", $tests) if $@;

        eval "use Config::Any::XML";
        skip("Config::Any::XML is not installed", $tests) if $@;
        skip("XML config files not supported", $tests)
            unless Config::Any::YAML->is_supported;

        trap { $app1->_write_rcfile_xml($rcfile) };
        ok $trap->leaveby eq "return", "Wrote XML config successfully";

        my $app2 = CLI::Startup->new({
            rcfile  => $rcfile,
            options => $optspec,
        });
        $app2->init;

        is_deeply $app2->get_config, $config, "Read XML config correctly";
        is_deeply $app1->get_options, $options,
            "...with the correct program options";
        is_deeply $app2->get_raw_options, {}, "...and an empty command line";
    }
}

# Call init() for a nonexistent rc file, then write back the
# config, and read in the config file in a second app object.
# The config data should match.
{
    my $file = "$dir/tmp/auto";

    local @ARGV = (
        "--rcfile=$file", qw/ --write-rcfile --rcfile-format=perl --foo --bar=baz /
    );
    my $app = CLI::Startup->new({
        options => {
            foo     => 'foo option',
            'bar=s' => 'bar option',
        },
    });

    trap { $app->init };
    ok $trap->leaveby eq 'exit', 'Init with nonexistent command-line rcfile'
        or diag "\$app->init ended by: " . $trap->leaveby . "\nError was: " . $trap->die;

    ok $app->get_rcfile eq $file, "rcfile set correctly";
    is_deeply $app->get_config, { default => {} }, "Config is initially empty.";

    ok -r "$file", "File was created"
        or diag "Info for file: $file:\n" . file_info($file);

    my $app2 = CLI::Startup->new({
        rcfile  => "$file",
        options => { foo => 'bar' },
    });
    $app2->init;
    is_deeply $app2->get_config, { default => { foo => 1, bar => 'baz' }},
        "Writeback is idempotent";
}

# Specify a custom rcfile writer
{
    my $app = CLI::Startup->new({
        write_rcfile => sub { print "writer called" },
        options      => { foo => 'bar' },
    });
    ok $app->get_write_rcfile, "Custom writer defined";

    local @ARGV = ('--write-rcfile');
    trap { $app->init() };

    ok $trap->leaveby eq 'exit', "Custom writer returned normally";
    like $trap->stdout, qr/writer called/, "Writer was indeed called";
}

# Disable rcfile writing
{
    my $app = CLI::Startup->new({
        write_rcfile => undef,
        options      => { foo => 'bar' },
    });
    ok !$app->get_write_rcfile, "--write-rcfile disabled";

    local @ARGV = ('--write-rcfile');

    # Command-line option will simply be unrecognized
    trap { $app->init() };
    ok $trap->exit == 1, "Error exit with disabled --write-rcfile";
    like $trap->stderr, qr/Unknown option/, "Unknown option error message";

    # Forcibly requesting a writeback from code should die
    trap { $app->init(); $app->write_rcfile };
    ok $trap->leaveby eq 'die', "Dies when forced to write rcfile";
    like $trap->die, qr/but called anyway/, "Correct error message";
}

# Read a more complicated RC file in YAML syntax
SKIP: {
    my $tests = 1;

    eval "use YAML::Any";
    skip("YAML::Any is not installed", $tests) if $@;

    eval "use Config::Any::YAML";
    skip("Config::Any::YAML is not installed", $tests) if $@;
    skip("YAML config files not supported", $tests)
        unless Config::Any::YAML->is_supported;

    # Create the file
    open OUT, ">", $rcfile;
    print OUT <<EOF;
---
default:
  foo: bar
  bar: baz
  baz: [ 1, 2, 3 ]
  qux: { a: 1, b: 2, c: 3 }
EOF
    close OUT;

    my $app = CLI::Startup->new({
        rcfile  => $rcfile,
        options => {
            'foo=s'  => 1,
            'bar=s'  => 1,
            'baz=i@' => 1,
            'qux=s%' => 1,
        },
    });
    $app->init;

    my $config = {
        default => {
            foo => 'bar',
            bar => 'baz',
            baz => [ 1, 2, 3 ],
            qux => { a => 1, b => 2, c => 3 },
        }
    };

    is_deeply $app->get_config, $config, "More complicated YAML config";
}

# Command-line overrides contents of rcfile
{
    open OUT, ">", $rcfile;
    print OUT qq{{
        default => {
            foo => 'bar',
            bar => 'qux',
        }
    }};
    close OUT;

    my $app = CLI::Startup->new({
        rcfile  => $rcfile,
        options => { 'foo=s' => 'foo', 'bar=s' => 'bar' },
    });

    local @ARGV = ('--foo=baz');
    $app->init;
    ok $app->get_options->{foo} eq 'baz', "Command line overrides config file";
    ok $app->get_options->{bar} eq 'qux', "Default value taken from rcfile";
    is_deeply $app->get_raw_options, { foo => 'baz' }, "Raw command-line options";
}


SKIP: {
    my $tests = 11;

    eval "use Config::INI::Writer";
    skip("Config::INI::Writer is not installed", $tests) if $@;

    eval "use Config::Any::INI";
    skip("Config::Any::INI is not installed", $tests) if $@;
    skip("INI config files not supported", $tests)
        unless Config::Any::INI->is_supported;

    # rcfile with listy settings
    {
        open OUT, ">", $rcfile;
        print OUT <<EOF;
x=a
EOF
        close OUT;

        my $app = CLI::Startup->new(
            {   rcfile  => $rcfile,
                options => { 'x=s@' => 'x option' },
            } );
        $app->init;

        ok ref( $app->get_options->{x} ) eq 'ARRAY',
            "Option was listified";
        is_deeply $app->get_raw_options, {}, "No command-line options";
    }

    # rcfile with multiple listy options
    {
        open OUT, ">", $rcfile;
        print OUT <<EOF;
x=a,b,c, d
EOF
        close OUT;

        my $app = CLI::Startup->new(
            {   rcfile  => $rcfile,
                options => { 'x=s@' => 'x option' },
            } );
        $app->init;

        is_deeply $app->get_options->{x}, [qw/a b c d/], "Listy option";
        is_deeply $app->get_raw_options, {}, "No command-line options";
    }

    # rcfile with hashy settings
    {
        open OUT, ">", $rcfile;
        print OUT <<EOF;
x=a=1, b=2, c=3=3
EOF
        close OUT;

        my $app = CLI::Startup->new(
            {   rcfile  => $rcfile,
                options => { 'x=s%' => 'x option' },
            } );
        $app->init;

        is_deeply $app->get_options->{x}, { a => 1, b => 2, c => '3=3' },
            "Option was hashified";
        is_deeply $app->get_raw_options, {}, "No command-line options";
    }

    # rcfile with a single hashy setting
    {
        open OUT, ">", $rcfile;
        print OUT <<EOF;
x=a=1
EOF
        close OUT;

        my $app = CLI::Startup->new(
            {   rcfile  => $rcfile,
                options => { 'x=s%' => 'x option' },
            } );
        $app->init;

        is_deeply $app->get_options->{x}, { a => 1 },
            "Single hashy option";
        is_deeply $app->get_raw_options, {}, "No command-line options";
    }

    # rcfile with empty-valued hash setting
    {
        open OUT, ">", $rcfile;
        print OUT <<EOF;
x=a=
y=a
EOF
        close OUT;

        my $app = CLI::Startup->new(
            {   rcfile  => $rcfile,
                options => { 'x=s%' => 'x option', 'y=s%' => 'y option' },
            } );
        $app->init;

        is_deeply $app->get_options->{x}, { a => '' },
            "Blank-valued hashy option";
        is_deeply $app->get_options->{y}, { a => '' },
            "Blank-valued hashy option";
        is_deeply $app->get_raw_options, {}, "No command-line options";
    }
}

# Clean up
unlink $_ for glob("$dir/tmp/*");
rmdir "$dir/tmp";

done_testing();


sub file_info
{
    my ($filename) = @_;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks)
    = stat($filename);

     return qq{
        Inode\t$ino
        Mode\t$mode
        UID\t$uid
        GID\t$gid
        Size\t$size
        Ctime\t$ctime
        Mtime\t$mtime
        Atime\t$atime
     };
}
