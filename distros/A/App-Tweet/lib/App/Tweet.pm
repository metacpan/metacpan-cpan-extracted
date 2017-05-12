package App::Tweet;

use warnings;
use strict;

use Config::YAML;
use Crypt::CBC;
use File::HomeDir;
use File::Slurp;
use File::Spec;
use File::Touch;
use IO::Interactive qw(is_interactive);
use Log::Log4perl qw(:easy);
use Net::Twitter;
use String::Random;
use Term::Prompt;

Log::Log4perl->easy_init($ERROR);

use constant TWEET_CONFIG_FILE => '.tweet';
use constant TWEET_CIPHER_FILE => '.teewt';

our $VERSION = '1.02';

sub run {
    my ( $class, %args ) = @_;

    DEBUG "$_ => [$args{$_}]" for keys %args;

    die ERROR "message is a required argument" unless exists $args{message};

    _send_message( $args{message}, _get_configuration( \%args ) );
}

sub reconfigure {
    unlink File::Spec->join( File::HomeDir->my_data(), TWEET_CONFIG_FILE );
    _get_configuration();
}

sub _get_configuration {
    my ($args) = @_;
    my $conf = _read_configuration_file(
        File::Spec->join( File::HomeDir->my_data(), TWEET_CONFIG_FILE ),
        $args );
    return $conf;
}

sub _read_configuration_file {
    my ( $config_file, $args ) = @_;

    DEBUG "trying to read config file [$config_file]";

    my $cipher_key = _get_cipher_key();

    DEBUG "using cipher [$cipher_key]";

    my $cipher = Crypt::CBC->new( -key => $cipher_key, -cipher => 'Blowfish' );

    if ( not -e $config_file ) {
        DEBUG "creating config file [$config_file]";
        touch $config_file if not -e $config_file;
        chmod oct(600), $config_file;
    }

    my $config = Config::YAML->new( config => $config_file, );

    $config->{username} = $args->{username} if exists $args->{username};
    $config->{password} = $cipher->encrypt( $args->{password} )
      if exists $args->{password};

    if ( not defined $config->{username} ) {

        DEBUG "unable to find user name in configuration file";

        die ERROR
          "can't prompt for config file values in non-interactive environment"
          unless is_interactive();

        $config->{username} =
          prompt( 'x', 'Username: ', 'from twitter.com', qw{} );
        $config->write();
    }
    if ( not defined $config->{password} ) {

        DEBUG "unable to find password in configuration file";
        $config->{password} = $cipher->encrypt(
            prompt( 'p', 'Password: ', 'from twitter.com', qw{} ) );

        $config->write();
    }

    DEBUG "password [$config->{password}]";

    $config->{password} = $cipher->decrypt( $config->{password} );

    DEBUG "password [$config->{password}]";

    return $config;
}

sub _get_cipher_key {
    my $cipher_file =
      File::Spec->join( File::HomeDir->my_data(), TWEET_CIPHER_FILE );

    if ( not -e $cipher_file ) {

        DEBUG "cipher file not found, creating it [$cipher_file]";

        my $cipher_key = String::Random->new()->randpattern( '.' x 56 );

        DEBUG "created new cipher key [$cipher_key]";

        write_file( $cipher_file, $cipher_key );
        chmod oct(600), $cipher_file;

        return $cipher_key;
    }

    DEBUG "reading cipher file [$cipher_file]";

    return read_file($cipher_file);
}

sub _send_message {
    my ( $message, $config ) = @_;

    DEBUG "accessing twitter as [$config->{username}]";

    my $twitter = Net::Twitter->new(
        username => $config->{username},
        password => $config->{password},
    );

    DEBUG "sending message to twitter [$message]";

    $twitter->update($message)
      or ERROR
"something bad happened and I couldn't sent your message.  you might not be able to connect to twitter (try visiting twitter.com in your browser) or you might be using the wrong user name or password.";

    return;
}

1;

__END__

=pod

=head1 NAME

App::Tweet - tweet on twitter from the command line 

=head1 SYNOPSIS

  use App::Tweet;
  
  App::Tweet->run('tell this to twitter');
  
  App::Tweet->reconfigure;

=head1 DESCRIPTION

C<App::Tweet> is a simple wrapper around L<Net::Twitter> that allows for you to easily send
messages (tweets) to twitter.com as a specific user.  You should use the 'tweet' command to
interface with this module.

The first time you C<run> the application it will prompt you for a user name and password.  This 
information is stored in a configuration file in your system's application data store.  The 
password is stored in a somewhat encrypted state, but the cipher key for the encryption is
stored right beside the configuration file, so it's not super-security.  The permissions on 
the file are set to read/write only by the file owner, but that is only relevant on some systems.

If you ever need to reset or change the username or password perminantely, you can use the
C<reconfigure> method.  If the change is just temporary, pass in the new username and password
when C<run>ning the application.

=head1 METHODS

=over 4

=item run( message => 'x', [ username => 'x', password => 'x' ] )

Runs the application and attempts to send a message to twitter using a configured username
and password or the one provided as an argument to this command.

=item reconfigure

Forces re-prompting for the stored username and password.

=back

=head1 AUTHOR

Josh McAdams, C<< <josh dot mcadams at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-mover at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Tweet>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Tweet

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Tweet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Tweet>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Tweet>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Tweet>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Josh McAdams, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

