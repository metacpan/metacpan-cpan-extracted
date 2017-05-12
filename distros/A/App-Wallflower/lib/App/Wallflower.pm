package App::Wallflower;
$App::Wallflower::VERSION = '1.007';
use strict;
use warnings;

use Getopt::Long qw( GetOptionsFromArray );
use Pod::Usage;
use Carp;
use Plack::Util ();
use URI;
use Wallflower;
use Wallflower::Util qw( links_from );

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
            printf "$status %s%s\n", $url->path;
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
        'verbose!',      'errors!',
        'host=s@',
        'url|uri=s',
        'help',          'manual',
        'tutorial',
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
    return bless {
        option     => \%option,
        args       => $args,
        callbacks  => \@cb,
        seen       => {},
        wallflower => Wallflower->new(
            application => ref $option{application}
                ? $option{application}
                : Plack::Util::load_psgi( $option{application} ),
            ( destination => $option{destination} )x!! $option{destination},
            ( index       => $option{index}       )x!! $option{index},
            ( url         => $option{url}         )x!! $option{url},
        ),
    }, $class;

}

sub run {
    my ($self) = @_;
    ( my $args, $self->{args} ) = ( $self->{args}, [] );
    my $method = $self->{option}{filter} ? '_process_args' : '_process_queue';
    $self->$method(@$args);
}

sub _process_args {
    my $self = shift;
    local @ARGV = @_;
    while (<>) {

        # ignore blank lines and comments
        next if /^\s*(#|$)/;
        chomp;

        $self->_process_queue("$_");
    }
}

sub _process_queue {
    my ( $self,       @queue ) = @_;
    my ( $wallflower, $seen )  = @{$self}{qw( wallflower seen )};
    my $follow  = $self->{option}{follow};
    my $host_ok = $self->_host_regexp;

    # I'm just hanging on to my friend's purse
    local $ENV{PLACK_ENV} = $self->{option}{environment};
    local @INC = ( @{ $self->{option}{inc} }, @INC );
    @queue = ('/') if !@queue;
    while (@queue) {

        my $url = URI->new( shift @queue );
        next if $seen->{ $url->path }++;
        next if $url->scheme && ! eval { $url->host =~ $host_ok };

        # get the response
        my $response = $wallflower->get($url);

        # run the callbacks
        $_->( $url => $response ) for @{ $self->{callbacks} };

        # obtain links to resources
        my ( $status, $headers, $file ) = @$response;
        if ( $status eq '200' && $follow ) {
            push @queue, links_from( $response => $url );
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

Copyright 2012-2015 by Philippe Bruhat (BooK).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

