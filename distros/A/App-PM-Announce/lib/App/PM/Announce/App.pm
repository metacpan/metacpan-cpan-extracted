package App::PM::Announce::App;

use warnings;
use strict;

use Getopt::Chain;
use App::PM::Announce;
use App::PM::Announce::Util;
use DateTime;
use Text::Table;
use Data::Dump qw/dd pp dump/;
use Document::TriPart;

my @feeds = @App::PM::Announce::Feed::feeds;

my $app;
my @app;
sub app {
    return $app ||= App::PM::Announce->new(@app);
}

sub help {
    print <<_END_

Usage:

    $0 -[vdh?] <COMMAND>

        -v, -d,  --verbose  Debugging mode. Be verbose when reporting
        -h, -?,  --help     This help screen

    config                  Check the config file (@{[ app->config_file ]})

    config edit             Edit the config file using \$EDITOR ($ENV{EDITOR})

    history                 Show announcement history

    history <query>         Show announcement history for event <query>, where <query> should be enough of the uuid to be unambiguous

    template                Print out a template to be used for input to the 'announce' command

        --image <image>     Attach <image> (can be either a local file or remote URL) to the Meetup event

    announce                Read STDIN for the event information and make a post for each feed

        -n, --dry-run       Don't actually login and announce, just show what would be done

    test                    Post a bogus event to a test meetup account, test linkedin account, and test greymatter account

    help                    This help screen

SYNOPSIS

    # Initialize and edit the config (only need to do this once)
    pm-announce config edit
    
    # Generate a template for the event
    pm-announce template > event.txt

    # Edit event.txt with your editor of choice...

    # Announce the event
    pm-announce announce < event.txt

_END_
}

sub run {
    Getopt::Chain->process(
        options => [qw/ verbose|v dry-run|n help|h|? /],
        run => sub {
            my ($context, @arguments) = @_;
            push @app, qw/debug 1 verbose 1/ if $context->option( 'verbose' );
            push @app, qw/dry_run 1/ if $context->option( 'dry-run' );
            return if @arguments && ! $context->option( 'help' );
            app;
            help;
            exit;
        },
        commands => {
            help => sub {
                help;
            },
            config => {
                run => sub {
                    my ($context, @arguments) = @_;
                    return if @arguments;
                    my $config = app->config;
                    print "\n";
                    print "Using config file: ", app->config_file, "\n";
                    print "\n";
                    print pp $config;
                    print "\n\n";
                    print "Configured to announce to: ", join ", ", grep { app->config->{feed}->{$_} } @feeds;
                    print "\n";
                    print "\n";
                },

                commands => {
                    edit => sub {
                        my ($context, @arguments) = @_;
                        Document::TriPart::_edit_file( app->config_file );
                    },
                },
            },
            test => sub {
                my ($context, @arguments) = @_;
                $app = App::PM::Announce->new(config_file => undef, config_default => {
                    feed => {
                        meetup => {qw{
                            username robert...krimen@gmail.com
                            password test8378
                            uri http://www.meetup.com/The-San-Francisco-Beta-Tester-Meetup-Group/calendar/?action=new
                        }},
                        linkedin => {qw{
                            username robertkrimen+alice8378@gmail.com
                            password test8378
                            uri http://www.linkedin.com/groupAnswers?start=&gid=1873425
                        }},
                        greymatter => {qw{
                            username alice8378
                            password test8378
                            uri http://72.14.179.195/cgi-bin/greymatter/gm.cgi
                        }},
                    },
                });

                my $key = int rand $$;
                my $description = join ' ', @arguments;
                $description ||= 'Default description';
                app->announce(
                    uuid => Data::UUID->new->create_str,
                    title => "$description ($key)",
                    description => "$description ($key)",
                    venue => 920502,
                    datetime => DateTime->now->add(days => 10),
                );
            },
            template => {
                options => [ 'image=s' ],
                run => sub {
                    my ($context, @arguments) = @_;
                    print STDOUT app->template( image => $context->option( 'image' ) || '' );
                },
            },
            announce => sub {
                my ($context, @arguments) = @_;
                my ($event, $report) = app->announce( \*STDIN );
                if ($event) {
                    print "\n";
                    print join "\n", @$report, '', '' if @$report;
                    print "\"$event->{title}\" has been announced on: ", join( ', ', map { $event->{"did_$_"} ? $_ : () } @feeds ), "\n";
                    print "The Meetup link is $event->{meetup_link}", "\n" if $event->{meetup_link};
                    print "\n";
                }
            },
            history => sub {
                my ($context, @arguments) = @_;
                my $query = shift @arguments;
                if ($query) {
                    my $event = app->history->find( $query );
                    my $data = $event->{data};
                    {
                        no warnings 'uninitialized';
                        print "\n";
                        print <<_END_;
"$data->{title}"
$event->{uuid}
$data->{meetup_link}
_END_
                        print "Made ", App::PM::Announce::Util->age( $event->{insert_datetime} ) . ' ago', " (", $event->{insert_datetime}, ")\n";
                        print "Announced on ", join( ', ', map { $data->{"did_$_"} ? $_ : () } @feeds ), "\n";
                        print "\n";

                    }
                }
                else {
                    my $verbose = $context->option( 'verbose' );
                    my @all = app->history->all;
                    my @table = map {
                        my $data = $_->{data};
                        my $did;
                        $did += $data->{"did_$_"} ? 1 : 0 for @feeds;
                        [
                            $verbose ? $_->{uuid} : substr($_->{uuid}, 0, 8),
                            $data->{title},
                            $verbose ? $_->{insert_datetime} : App::PM::Announce::Util->age( $_->{insert_datetime} ) . ' ago',
                            "$did/4"
                        ];
                    } app->history->all;
                    my $table = Text::Table->new( 'uuid', \' | ', 'title', \' | ', 'age', \' | ', 'did' )->load( @table );
                    print
                        "\n",
                        $table->rule( '-', '+' ),
                        $table->body,
                        $table->rule( '-', '+' ),
                        "\n",
                    ;
                }
            },
        },
    );
}

1;

__END__
            print <<_END_;

The only thing you can do right now:

    $0 test

Which will submit an announcement to:

    robert...krimen\@gmail.com / test8378 \@ http://www.meetup.com/The-San-Francisco-Beta-Tester-Meetup-Group/calendar/?action=new
    robertkrimen+alice8378\@gmail.com / test8378 \@ http://www.linkedin.com/groupAnswers?start=&gid=1873425
    alice8378 / test8378 \@ http://72.14.179.195/cgi-bin/greymatter/gm.cgi

_END_
