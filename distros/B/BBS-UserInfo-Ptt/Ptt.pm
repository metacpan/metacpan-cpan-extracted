package BBS::UserInfo::Ptt;

use warnings;
use strict;

use Carp;
use Expect;

=head1 NAME

BBS::UserInfo::Ptt - Get user information of PTT-style BBS

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use BBS::UserInfo::Ptt;

    # create object
    my $bot = BBS::UserInfo::Ptt->new(
	    'debug' => 1,
	    'port' => 23,
	    'server' => 'ptt.cc',
	    'telnet' => '/usr/bin/telnet',
	    'timeout' => 10
	    );

    # connect to the server
    $bot->connect() or die('Unable to connect BBS');

    my $userdata = $bot->query('username');

    # print some data
    print($userdata->{'logintimes'});

=head1 FUNCTIONS

=head2 new()

Create a BBS::UserInfo::Ptt object, there are some parameters that you
can define:

    server => 'ptt.cc'	# Necessary, server name
    port => 23		# Optional, server port
    telnet => 'telnet'	# Optional, telnet program
    timeout => 10	# Optional, Expect timeout
    debug => 1		# Optional, print debug information

=cut

sub new {
    my ($class, %params) = @_;

    my %self = (
	'debug' => 0,
	'password' => '',	# incomplete function
	'port' => 23,
	'server' => undef,
	'telnet' => 'telnet',
	'timeout' => 10,
	'username' => 'guest'	# incomplete function
    );

    while (my ($k, $v) = each(%params)) {
	$self{$k} = $v if (exists $self{$k});
    }

    return bless(\%self, $class);
}

=head2 connect()

Connect to the BBS server.

=cut

sub connect {
    my $self = shift();

    $self->{'expect'} = Expect->spawn($self->{'telnet'}, $self->{'server'},
	$self->{'port'});
    $self->{'expect'}->log_stdout(0);

    return undef unless (defined($self->_login($self)));

    return $self->{'expect'};
}

sub _login {
    my $self = shift();

    my $bot = $self->{'expect'};
    my $debug = $self->{'debug'};

    print("Waiting for login\n") if ($debug);
    $bot->expect($self->{'timeout'}, '-re', '½Ð¿é¤J¥N¸¹');
    return undef if ($bot->error());

    $bot->send($self->{'username'}, "\r\n[D[D");
    return 1;
}

=head2 query()

Query user information and return a hash reference with:

=over 4

=item * nickname

=item * logintimes

=item * posttimes

=item * lastlogintime

=item * lastloginip

=back

=cut

sub query {
    my ($self, $user) = @_;

    my $bot = $self->{'expect'};
    my $debug = $self->{'debug'};
    my $timeout = $self->{'timeout'};

    $bot->send("[D[Dt\r\nq\r\n", $user, "\r\n");

    my %h;

    print("Waiting for nickname\n") if ($debug);
    $bot->expect($timeout, '-re', '¡m¢×¢Ò¼ÊºÙ¡n\S+\((.*)\)\s*¡m');
    $h{'nickname'} = ($bot->matchlist)[0];
    printf("nickname = %s\n", $h{'nickname'}) if ($debug);
    return undef if ($bot->error());

    print("Waiting for logintimes\n") if ($debug);
    $bot->expect($timeout, '-re', '¡m¤W¯¸¦¸¼Æ¡n(\d+)¦¸');
    $h{'logintimes'} = ($bot->matchlist)[0];
    printf("logintimes = %s\n", $h{'logintimes'}) if ($debug);
    return undef if ($bot->error());

    print("Waiting for posttimes\n") if ($debug);
    $bot->expect($timeout, '-re', '¡m¤å³¹½g¼Æ¡n(\d+)½g');
    $h{'posttimes'} = ($bot->matchlist)[0];
    printf("posttimes = %s\n", $h{'posttimes'}) if ($debug);
    return undef if ($bot->error());

    print("Waiting for lastelogintime\n") if ($debug);
    $bot->expect($timeout, '-re', '¡m¤W¦¸¤W¯¸¡n(\S+\s\S+\s\S+)\s');
    $h{'lastlogintime'} = ($bot->matchlist)[0];
    printf("lastlogintime = %s\n", $h{'lastlogintime'}) if ($debug);
    return undef if ($bot->error());

    print("Waiting for lasteloginip\n") if ($debug);
    $bot->expect($timeout, '-re', '¡m¤W¦¸¬G¶m¡n(\S+)');
    $h{'lastloginip'} = ($bot->matchlist)[0];
    printf("lastloginip = %s\n", $h{'lastloginip'}) if ($debug);
    return undef if ($bot->error());

    return \%h;
}

=head1 AUTHOR

Gea-Suan Lin, C<< <gslin at gslin.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Gea-Suan Lin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of BBS::UserInfo::Ptt
