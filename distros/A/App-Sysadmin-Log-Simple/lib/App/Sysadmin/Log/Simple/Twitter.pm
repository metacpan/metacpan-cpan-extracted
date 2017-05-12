package App::Sysadmin::Log::Simple::Twitter;
use strict;
use warnings;
use autodie qw(:file :filesys);
use Config::General qw(ParseConfig);
use Path::Tiny;

# ABSTRACT: a Twitter-logger for App::Sysadmin::Log::Simple
our $VERSION = '0.009'; # VERSION


sub new {
    my $class = shift;
    my %opts  = @_;
    my $app   = $opts{app};

    my $oauth_file;
    if ($app->{oauth_file}) {
        $oauth_file = $app->{oauth_file};
    }
    else {
        require File::HomeDir;

        my $HOME = File::HomeDir->users_home(
            $app->{user} || $ENV{SUDO_USER} || $ENV{USER}
        );
        $oauth_file = path($HOME, '.sysadmin-log-twitter-oauth');
    }

    return bless {
        oauth_file  => $oauth_file,
        do_twitter  => $app->{do_twitter},
    }, $class;
}


sub log {
    my $self     = shift;
    my $logentry = shift;

    return unless $self->{do_twitter};

    require Net::Twitter::Lite::WithAPIv1_1;

    warn "You should do: chmod 600 $self->{oauth_file}\n"
        if ($self->{oauth_file}->stat->mode & 07777) != 0600; ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
    my $conf = Config::General->new($self->{oauth_file});
    my %oauth = $conf->getall();

    my $ua = __PACKAGE__
        . '/' . (defined __PACKAGE__->VERSION ? __PACKAGE__->VERSION : 'dev');
    my $t = Net::Twitter::Lite::WithAPIv1_1->new(
        consumer_key        => $oauth{consumer_key},
        consumer_secret     => $oauth{consumer_secret},
        access_token        => $oauth{oauth_token},
        access_token_secret => $oauth{oauth_token_secret},
        ssl                 => 1,
        useragent           => $ua,
    );
    $t->access_token($oauth{oauth_token});
    $t->access_token_secret($oauth{oauth_token_secret});

    my $result = $t->update($logentry);
    die 'Something went wrong' unless $result->{text} eq $logentry;

    my $url = 'https://twitter.com/'
        . $result->{user}->{screen_name}
        . '/status/' . $result->{id_str};
    return "Posted to Twitter: $url";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Sysadmin::Log::Simple::Twitter - a Twitter-logger for App::Sysadmin::Log::Simple

=head1 VERSION

version 0.009

=head1 DESCRIPTION

This provides a log method that publishes your log entry to a Twitter feed.

=head1 METHODS

=head2 new

This creates a new App::Sysadmin::Log::Simple::Twitter object.

You're required to register this application at L<https://dev.twitter.com>, and
provide the consumer key, consumer secret, access token, and access token
secret. Upon registering the application, get the consumer key and secret from
the app details view. To get the I<access> key and secret, click "My Access
Token" on the right sidebar.

These data should be placed in a private (C<chmod 600>) file in
F<$HOME/.sysadmin-log-twitter-oauth>:

    consumer_key        =   ...
    consumer_secret     =   ...
    oauth_token         =   ...
    oauth_token_secret  =   ...

Or, you can provide a different location for the file:

    my $logger = App::Sysadmin::Log::Simple::Twitter->new(
        oauth_file => '/etc/twitter',
    );

=head2 log

This tweets your log message.

=head1 AVAILABILITY

The project homepage is L<http://p3rl.org/App::Sysadmin::Log::Simple>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/App::Sysadmin::Log::Simple/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/App-Sysadmin-Log-Simple>
and may be cloned from L<git://github.com/doherty/App-Sysadmin-Log-Simple.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/App-Sysadmin-Log-Simple/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
