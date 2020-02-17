package App::unbelievable::CLI;
# see script/unbelievable for docs.

use App::unbelievable::Util;
use Cwd;

# === Runner for script/unbelievable ======================================

sub run {
    require Getopt::Long::Subcommand;
    require Pod::Usage;
    my $args = shift or die "No args";
    local @ARGV = @$args;
    my %opts = (    # Defaults
        verbose => 0
    );

    my $res = Getopt::Long::Subcommand::GetOptions(
        summary => 'Build a static site',
        default_subcommand => 'help',

        # common options recognized by all subcommands
        options => {
            'help|h|?|usage' => {
                summary => 'Display help message',
                handler => \$opts{help},
                #handler => sub {
                #    my ($cb, $val, $res) = @_;
                #    if ($res->{subcommand}) {
                #        say "Help message for $res->{subcommand} ...";
                #    } else {
                #        say "General help message ...";
                #    }
                #    exit 0;
                #},
            },
            'man' => {
                summary => 'Display full docs',
                handler => \$opts{man},
            },
            'version|V' => {
                summary => 'Display program version',
                handler => sub {
                    say "$0 version $main::VERSION";
                    exit 0;
                },
            },
            'verbose|v+' => {
                handler => \$opts{verbose},
            },
        }, # options

        # subcommands
        subcommands => {
            new => {
                summary => 'Create a new site',
            },
            build => {
                summary => 'Build the static html',
                options => {
                    's|route-style=s' => {
                        summary => 'Which style of route to request',
                        handler => \$opts{route_style},
                    },
                },
            },
            serve => {
                summary => 'Serve the static HTML using a local server',
                # TODO
                #options => {
                #    'server|s=s' => {
                #        summary => 'Which server to use',
                #        handler => \$opts{server},
                #    },
                #},
            },
            aio => {
                summary => 'build + serve (all in one)',
            },
            help => {
                summary => 'Show help',
            },
        }, # subcommands
    );

    $VERBOSE = $opts{verbose} if $opts{verbose} > $VERBOSE;

    _diag("Got options:\n", Dumper($res), Dumper(\%opts));

    Pod::Usage::pod2usage() unless $res->{success};
    Pod::Usage::pod2usage(-verbose => 1, -exitval => 0) if $opts{help};
    Pod::Usage::pod2usage(-verbose => 1, -exitval => 0)
        if $res->{success} && $res->{subcommand}->[0] eq 'help';
    Pod::Usage::pod2usage(-verbose => 2, -exitval => 0) if $opts{man};

    my $cmdname = 'cmd_' . join '_', @{$res->{subcommand}};
    my $fn = __PACKAGE__->can($cmdname)
        or die "I don't know subcommand $cmdname";
    return $fn->($res, \%opts);
} #run()

# === Subcommands =========================================================

sub cmd_help {
    Pod::Usage::pod2usage(-verbose => 1, -exitval => 0);
}

sub cmd_aio {
    my ($res, $opts) = @_;
    my $rv = cmd_build($res, $opts);
    return $rv if $rv;
    $rv = cmd_serve($res, $opts);
    return $rv;
}

sub cmd_new {
    my ($res, $opts) = @_;
    say "New site";
    return 0;
} #cmd_new()

sub cmd_build {
    my ($res, $opts) = @_;
    say "Build site";

    # Defaults
    $opts->{route_style} //= 'htmlfile';

    _diag("unbelivable opts:\n", Dumper($opts));

    require App::Wallflower;
    require Config;
    require File::Find::Rule;
    require File::Temp;

    # TODO get CPU count per
    # https://gist.github.com/aras-p/47e2252d6b1fa57d3619fd8e021690ec

    # List the routes
    # TODO get all GET routes from app
    my @routes;

    # Get and filter the routes from /content.
    push @routes, File::Find::Rule->readable->file->not_name('.*')->relative
                    ->in(_here('content'));
    if($opts->{route_style} eq 'htmlfile') {
        s{\.[^\.]+$}{.html} foreach @routes;
    } elsif($opts->{route_style} eq 'dir') {
        s{\.[^\.]+$}{/} foreach @routes;
    } else {
        die "Unknown route style $opts->{route_style}";
    }

    # public/ --- all files appear just as they are, sans leading /public
    push @routes, File::Find::Rule->readable->file->relative
                    ->in(_here('public'));
    s{^([^/])}{/$1} foreach @routes;
    push @routes, '/';
    _diag("Routes:\n", join("\n", @routes));

    # Export the routes where wallflower can find them
    my $fh = File::Temp->new();
    say {$fh} join("\n", @routes);
    close $fh;  # TODO does this work?

    my $destdir = _here('_output');     # TODO make this an option
    do { no autodie; mkdir $destdir };
    my $wallflower_opts = [
        ( '--verbose' )x!! $VERBOSE,
        '--application' => _here('bin/app.psgi'),
        '--destination' => $destdir,
        '--INC' => join($Config::Config{path_sep}, @INC),
        '--files',  # Flag
        "$fh",      # Stringifies to the filename
    ];
    _diag("Wallflower options:\n", Dumper($wallflower_opts));
    my $builder = App::Wallflower->new_with_options($wallflower_opts);
    return $builder->run // 0;
} #cmd_build()

sub cmd_serve {
    # Thanks to plackup(1) and to https://github.com/plack/Plack/issues/93
    require Plack::Runner;
    my $runner = Plack::Runner->new;    # TODO add options
    my $dir = _here('_output');
    $dir =~ s/"/\"/g;   # Just in case
    $runner->parse_options(
        qw(-MPlack::App::File -MPlack::Middleware::DirIndex -e),
        "enable 'DirIndex'; Plack::App::File->new(root => \"$dir\")->to_app"
    );
    return $runner->run;
}

# === Helpers =============================================================

# Return the path of a directory under cwd
sub _here {
    return File::Spec->rel2abs(File::Spec->catpath(getcwd, @_));
}

1;
