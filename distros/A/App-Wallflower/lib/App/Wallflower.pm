package App::Wallflower;
$App::Wallflower::VERSION = '1.012';
use strict;
use warnings;

use Getopt::Long qw( GetOptionsFromArray );
use Pod::Usage;
use Carp;
use Plack::Util ();
use URI;
use Wallflower;
use Wallflower::Util qw( links_from );
use List::Util qw( uniqstr max );
use Path::Tiny;

sub _default_options {
    return (
        follow      => 1,
        environment => 'deployment',
        host        => ['localhost'],
        verbose     => 1,
        errors      => 1,
    );
}

# [ activating option, coderef ]
my @callbacks = (
    [
        errors => sub {
            my ( $url, $response ) = @_;
            my ( $status, $headers, $file ) = @$response;
            return if $status == 200;
            printf "$status %s\n", $url->path;
        },
    ],
    [
        verbose => sub {
            my ( $url, $response ) = @_;
            my ( $status, $headers, $file ) = @$response;
            return if $status != 200;
            printf "$status %s%s\n", $url->path,
              $file && " => $file [${\-s $file}]";
        },
    ],
    [
        tap => sub {
            my ( $url, $response ) = @_;
            my ( $status, $headers, $file ) = @$response;
            is( $status, 200, $url->path );
        },
    ],
);

sub new_with_options {
    my ( $class, $args ) = @_;
    my $input = (caller)[1];
    $args ||= [];

    # save previous configuration
    my $save = Getopt::Long::Configure();

    # ensure we use Getopt::Long's default configuration
    Getopt::Long::ConfigDefaults();

    # get the command-line options (modifies $args)
    my %option = _default_options();
    GetOptionsFromArray(
        $args,           \%option,
        'application=s', 'destination|directory=s',
        'index=s',       'environment=s',
        'follow!',       'filter|files|F',
        'quiet',         'include|INC=s@',
        'verbose!',      'errors!',                 'tap!',
        'host=s@',
        'url|uri=s',
        'parallel=i',
        'help',          'manual',
        'tutorial',      'version',
    ) or pod2usage(
        -input   => $input,
        -verbose => 1,
        -exitval => 2,
    );

    # restore Getopt::Long configuration
    Getopt::Long::Configure($save);

    # simple on-line help
    pod2usage( -verbose => 1, -input => $input ) if $option{help};
    pod2usage( -verbose => 2, -input => $input ) if $option{manual};
    pod2usage(
        -verbose => 2,
        -input   => do {
            require Pod::Find;
            Pod::Find::pod_where( { -inc => 1 }, 'Wallflower::Tutorial' );
        },
    ) if $option{tutorial};
    print "wallflower version $Wallflower::VERSION\n" and exit
      if $option{version};

    # application is required
    pod2usage(
        -input   => $input,
        -verbose => 1,
        -exitval => 2,
        -message => 'Missing required option: application'
    ) if !exists $option{application};

    # create the object
    return $class->new(
        option => \%option,
        args   => $args,
    );

}

sub new {
    my ( $class, %args ) = @_;
    my %option = ( _default_options(), %{ $args{option} || {} } );
    my $args   = $args{args} || [];
    my @cb     = @{ $args{callbacks} || [] };

    # application is required
    croak "Option application is required" if !exists $option{application};

    # setup TAP
    if ( $option{tap} ) {
        require Test::More;
        import Test::More;
        if ( $option{parallel} ) {
            my $tb = Test::Builder->new;
            $tb->no_plan;
            $tb->use_numbers(0);
        }
        $option{quiet} = 1;    # --tap = --quiet
        if ( !exists $option{destination} ) {
            $option{destination} = Path::Tiny->tempdir( CLEANUP => 1 );
        }
    }

    # --quiet = --no-verbose --no-errors
    $option{verbose} = $option{errors} = 0 if $option{quiet};

    # add the hostname passed via --url to the list built with --host
    push @{ $option{host} }, URI->new( $option{url} )->host
       if $option{url};

    # pre-defined callbacks
    push @cb, map $_->[1], grep $option{ $_->[0] }, @callbacks;

    # include option
    my $path_sep = $Config::Config{path_sep} || ';';
    $option{inc} = [ split /\Q$path_sep\E/, join $path_sep,
        @{ $option{include} || [] } ];

    local $ENV{PLACK_ENV} = $option{environment};
    local @INC = ( @{ $option{inc} }, @INC );
    my $self = {
        option     => \%option,
        args       => $args,
        callbacks  => \@cb,
        seen       => {},                # keyed on $url->path
        todo       => [],
        wallflower => Wallflower->new(
            application => ref $option{application}
                ? $option{application}
                : Plack::Util::load_psgi( $option{application} ),
            ( destination => $option{destination} )x!! $option{destination},
            ( index       => $option{index}       )x!! $option{index},
            ( url         => $option{url}         )x!! $option{url},
        ),
    };

    # setup parallel processing
    if ( $self->{option}{parallel} ) {
        require Fcntl;
        import Fcntl qw( :seek :flock );
        $self->{_parent_}  = $$;
        $self->{_forked_}  = 0;
        $self->{_ipc_dir_} = Path::Tiny->tempdir(
            CLEANUP  => 1,
            TEMPLATE => 'wallflower-XXXX'
        );
    }

    return bless $self, $class;
}

sub run {
    my ($self) = @_;
    ( my $args, $self->{args} ) = ( $self->{args}, [] );
    my $method = $self->{option}{filter} ? '_process_args' : '_process_queue';
    $self->$method(@$args);
    if    ( $self->{option}{parallel} ) { $self->_wait_for_kids; }
    elsif ( $self->{option}{tap} )      { done_testing(); }
}

sub _push_todo {
    my ( $self, @items ) = @_;
    my $seen    = $self->{seen};
    my $todo    = $self->{todo};
    my $host_ok = $self->_host_regexp;

    # add to the to-do list
    @items = uniqstr                       # unique
      grep !$seen->{$_},                   # not already seen
      map ref() ? $_->path : $_,           # paths
      grep !ref || !$_->scheme             # from URI
        || eval { $_->host =~ $host_ok },  # pointing only to expected hosts
      @items;

    push @$todo, @items;

    if ( $self->{option}{parallel} ) {
        if   ( $self->{_parent_} == $$ ) { $self->_aggregate_todo(@items); }
        else                             { $self->_save_todo; }
    }
}

sub _aggregate_todo {
    my ( $self, @items ) = @_;
    my $TODO   = $self->{_ipc_dir_}->child('__TODO__');
    my $latest = ( stat $TODO )[9] || 0;

    # aggregate all child todo into ours and save it as __TODO__
    local *ARGV;
    @ARGV = glob $self->{_ipc_dir_}->child('todo-*');
    no warnings 'inplace';    # some files may already be gone
    my $fh = File::Temp->new(
        TEMPLATE => "__TODO__-XXXX",
        DIR      => $self->{_ipc_dir_},
    );
    print $fh uniqstr @ARGV ? <> : (), map "$_\n", @items;
    close $fh;
    rename "$fh", $TODO
      or die "Can't rename $fh to $TODO: $!";

    # the parent to-do list is always empty
    $self->{todo} = [];

    # fork all kids
    if ( !$self->{_forked_} ) {
        for ( 1 .. $self->{option}{parallel} ) {
            if ( not my $pid = fork ) {
                $self->{_pidfile_} = Path::Tiny->tempfile(
                    TEMPLATE => "pid-$$-XXXX",
                    DIR      => $self->{_ipc_dir_},
                );
                delete $self->{_seen_fh_};    # will reopen
                return;
            }
            elsif ( !defined $pid ) {
                warn "Couldn't fork: $!";
            }
            else {
                $self->{_forked_}++;
            }
        }
        sleep 1;    # give them time to settle
    }
}

sub _save_todo {
    my ($self) = @_;

    # save the child todo
    my $fh = File::Temp->new(
        TEMPLATE => "todo-$$-XXXX",
        DIR      => $self->{_ipc_dir_},
    );
    print $fh map "$_\n", @{ $self->{todo} };
    close $fh;
    $self->{_todo_fh_} = $fh;    # deletes previous one
}

# returns a boolean indicating if the update can be trusted
sub _update_todo {
    my ($self) = @_;
    my $todo   = $self->{todo};
    my $TODO   = $self->{_ipc_dir_}->child('__TODO__');
    my $SEEN   = $self->{_ipc_dir_}->child('__SEEN__');

    return if !-e $TODO;
    my $certainty =    # this update can be trusted if __TODO__ is the
      ( stat $TODO )[9] > max( 0, map +(stat)[9] || 0,    # most recent
        $SEEN, glob $self->{_ipc_dir_}->child('todo-*')); # file of all

    # read from the shared todo
    open my $fh, '<', $TODO or die "Can't open $TODO: $!";
    @$todo = <$fh>;
    chomp(@$todo);

    return $certainty;
}

sub _next_todo {
    my ($self) = @_;
    my $seen   = $self->{seen};
    my $todo   = $self->{todo};
    my $next;

    if ( $self->{option}{parallel} ) {

       # in parallel mode, the parent does not render anything
       return if $self->{_parent_} == $$;

      TODO:

        # read from the shared seen file
        my $SEEN = $self->{_ipc_dir_}->child('__SEEN__');
        my $seen_fh = $self->{_seen_fh_} ||= do {
            open my $fh, -e $SEEN ? '+<' : '+>', $SEEN
              or die "Can't open $SEEN in read-write mode: $!";
            $fh->autoflush(1);
            $fh;
        };
        flock( $seen_fh, LOCK_EX() ) or die "Cannot lock $SEEN: $!\n";
        seek( $seen_fh, 0, SEEK_CUR() );
        while (<$seen_fh>) { chomp; $seen->{$_}++; }

        # find a todo item not seen
        ( $next, @$todo ) = uniqstr grep !$seen->{$_}, @$todo;

        # or update todo and try again
        if ( !defined $next ) {
            my $certain = $self->_update_todo;
            ( $next, @$todo ) = uniqstr grep !$seen->{$_}, @$todo;

            # if we can't trust the update, try the entire thing again
            if ( !defined $next && !$certain ) {
                flock( $seen_fh, LOCK_UN() ) or die "Cannot unlock $SEEN: $!\n";
                sleep 1;
                goto TODO;
            }
        }

        # write to the shared seen file
        if ( defined $next ) {    # /!\ NOT ELSE /!\
            seek( $seen_fh, 0, SEEK_END() );
            print $seen_fh "$next\n";
        }
        flock( $seen_fh, LOCK_UN() ) or die "Cannot unlock $SEEN: $!\n";
    }
    else {
        ( $next, @$todo ) = uniqstr grep !$seen->{$_}, @$todo;
    }

    # nothing to do
    return undef if !defined $next;

    $seen->{$next}++;
    return URI->new($next);
}

sub _wait_for_kids {
    my ($self) = @_;
    return if $self->{_parent_} != $$;
    while ( @{ [ glob( $self->{_ipc_dir_}->child('pid-*') ) ] } ) {
        $self->_aggregate_todo;
        sleep 1;
    }
    if ( $self->{option}{tap} ) {
        my $count;
        my $SEEN = $self->{_ipc_dir_}->child( '__SEEN__' );
        open my $fh, '<', $SEEN or die "Can't open $SEEN: $!";
        seek $fh, 0, SEEK_SET();
        $count++ while <$fh>;
        my $tb = Test::Builder->new;
        $tb->no_ending(1);
        $tb->done_testing($count);
    }
}

sub _process_args {
    my $self = shift;
    local *ARGV;
    @ARGV = @_;
    while (<>) {

        # ignore blank lines and comments
        next if /^\s*(#|$)/;
        chomp;

        $self->_process_queue("$_");

        # child processes should not process the filter input
        last if $self->{option}{parallel} && $self->{_parent_} != $$;
    }
}

sub _process_queue {
    my ( $self,       @queue ) = @_;
    my ( $wallflower, $seen )  = @{$self}{qw( wallflower seen )};
    my $follow  = $self->{option}{follow};

    # I'm just hanging on to my friend's purse
    local $ENV{PLACK_ENV} = $self->{option}{environment};
    local @INC = ( @{ $self->{option}{inc} }, @INC );
    $self->_push_todo( @queue ? @queue : ('/') );

    while ( my $url = $self->_next_todo ) {

        # get the response
        my $response = $wallflower->get($url);

        # run the callbacks
        $_->( $url => $response ) for @{ $self->{callbacks} };

        # obtain links to resources
        my ( $status, $headers, $file ) = @$response;
        if ( $status eq '200' && $follow ) {
            $self->_push_todo( links_from( $response => $url ) );
        }

        # follow 301 Moved Permanently
        elsif ( $status eq '301' ) {
            require HTTP::Headers;
            my $l = HTTP::Headers->new(@$headers)->header('Location');
            unshift @queue, $l if $l;
        }
    }
}

sub _host_regexp {
    my ($self) = @_;
    my $re = join '|',
        map { s/\./\\./g; s/\*/.*/g; $_ }
        @{ $self->{option}{host} };
    return qr{^(?:$re)$};
}

1;

__END__

=pod

=head1 NAME

App::Wallflower - Class performing the moves for the wallflower program

=head1 VERSION

version 1.012

=head1 SYNOPSIS

    # this is the actual code for wallflower
    use App::Wallflower;
    App::Wallflower->new_with_options( \@ARGV )->run;

=head1 DESCRIPTION

L<App::Wallflower> is a container for functions for the L<wallflower>
program.

=head2 new_with_options

    App::Wallflower->new_with_options( \@ARGV );

Process options in the provided array reference (modifying it),
and return a object ready to be C<run()>.

See L<wallflower> for the list of options and their usage.

=head2 new

    App::Wallflower->new( option => \%option, args => \@args );

Create an object ready to be C<run()>.

C<option> is a hashref of options as produced by L<Getopt::Long>, and
C<args> is an array ref of optional arguments to be processed by C<run()>

=head2 run

Make L<wallflower> dance.

Process the remaining arguments according to the options,
i.e. either as URLs to save or as files containing lists of URLs to save.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2018 by Philippe Bruhat (BooK).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
