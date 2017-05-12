package Amazon::Dash::Button;
$Amazon::Dash::Button::VERSION = '0.11';
$Amazon::Dash::Button = '0.10';

use Amazon::Dash::Button::Device ();
use Net::Pcap::Easy              ();

use strict;
use warnings;

# ABSTRACT: a very simple perl interface to play & interact with an Amazon Dash Button.

=head1 NAME
Amazon::Dash::Button - a very simple perl interface to play & interact with an Amazon Dash Button.

=head1 VERSION

version 0.11

=head1 DESCRIPTION

Amazon::Dash::Button allows you to discover your mac address button and
set a listener to run any custom actions when the button is clicked...

Here is a non exhaustive list of ideas, applications you can think about:

=over 4

=item control your music player (provide an example for mpd: Music Player Daemon)

=item silent doorbell which send a notification (text, email, ...)

=item order your favorite pizza

=item switch on/off the light

=item open the garage door

=item ...

=back

Feel free to complete this list, and submit more ideas.

This can be used on a Raspberry Pi, linux, mac os computer...
In order to properly listen to packets you would need to run it as root using 'sudo' 

=head1 Setting

=head2 Linking the button to your wifi network

The first thing to do once you have received your button is to set it and discover it.
Here is the basic setting process:

=over 4

=item use your phone or table to perform the basic setting, but do not complete it, stop when asking to select to link a product with the button.

=item  in the mobile app you would find a menu "Your Dash Button" -> "Settings" then "Set up a new device".

=item  choose your dash device, then follow the instructions: long press on the button until it discovery mode (blue light)

=item  provide the wifi password of your network

=item  but do not select the exact product linked to your button exit from there !

=back

=head2 Detecting the button

Amazon::Dash::Button comes with one search method which allows you to look for your device.
You mainly want to know the mac address of your button

=head3 * from the command line

You can use the sample scripts provided in the distribution to detect your button.
The button should be listed as one of the Amazon device, as shown in the sample below:

		> sudo ./examples/search.pl
		> sudo ./examples/search.pl eth0
		Password:
		# using filter: arp or ( udp and ( port 67 or port 68 ) )
		# listening on device: en0
		# using cache Yes
		ARP - Mac Address = c8:b1:ce:bb:a3:1c
		ARP - Mac Address = 36:07:8d:ab:61:b7
		ARP - Mac Address = a6:5e:88:28:d2:9f
		ARP - Mac Address = e9:97:12:9e:38:56
		ARP - Mac Address = 68:54:b5:41:69:9c - Amazon device

=head3 * oneliner

Or simply opt for one of the oneliner below to search for your buttong

		perl -MAmazon::Dash::Button -e 'Amazon::Dash::Button->search()'

you can also provide your own filter to look for your button.
By default it's using udp and arp lookup which should cover most of the buttons.
Depending on your button generation and software version it might use one or the other.

You will find several options to use with the search function there, in order to run it 
as a oneliner, simple replace 'YOUR RULE HERE' with the rule you want to use.

		perl -MAmazon::Dash::Button -e 'YOUR RULE HERE'

		# this is the default rule
		Amazon::Dash::Button->search( filter => q{arp or ( udp and ( port 67 or port 68 ) )} );

		# only look on udp
		Amazon::Dash::Button->search( filter => q{'udp and ( port 67 or port 68 )} );

		# remove more noise using cache (by default disabled), one mac address is only displayed once
		Amazon::Dash::Button->search( cache => 1 );

You can also specifiy the network device to use to listen depending 
if it's a wifi or cable ethernet connection use one or the other.

		# search on a specific device
		Amazon::Dash::Button->search( dev => q{en0} );
		Amazon::Dash::Button->search( dev => q{eth0} );

=head1 Usage

=head2 Manage a single button

Create one object and call listen on it.

		Amazon::Dash::Button->new( from => {
			# required options
			mac	=> '00:11:22:33:44:55',
			onClick	=> sub { print q{Got a Click !} },
			#... optional options
			#name => q{Your Button Name},
			#timeout => 5, # in seconds
			#_fork_for_onClick => 1, # run the onClick in a forked process
			} )->listen;


=head2 Add more than a single button to the same listener

You can chain multiple button declaration using the add fucntion.

		Amazon::Dash::Button->new()->add(
			mac	=> '00:11:22:33:44:55',
			onClick	=> sub { ... },
			)->add(
			mac	=> 'aa:11:22:33:44:66',
			onClick	=> sub { ... },
			)->add(
			mac	=> 'bb:11:22:33:44:77',
			onClick	=> sub { ... },
			# ... you can add as many button as you want
			)->listen();

=head2 Options when creating a new Amazon::Dash::Button object

Here are some options when creating a button listener
Same as for search you can add a filter to listen.

		Amazon::Dash::Button->new( from => ...,
			dev     => q{eth0},
			filter  => q{'udp and ( port 67 or port 68 )},
			timeout => 5, # ignore any further clicks in the next 5 seconds
		 )->listen();


=head1 Basic installation process

Here are some basic steps to install it on a Raspberry Pi for example:

	cpanm Amazon::Dash::Button
	apt-get install libpcap0.8
	apt-get install libpcap-dev

The git repo also provides a very basic systemctl service

	cd systemctl/
	# adjust the path to your perl script then
	sudo make install

=cut

use Simple::Accessor qw{from dev filter timeout devices};

# default values
sub _build_timeout { 5 }
sub _build_filter  { q{arp or ( udp and ( port 67 or port 68 ) ) } }
sub _build_dev     { 'en0' }

# the list of our button
sub _build_devices { [] }

sub build {
    my $self = shift;

    my $from = $self->from;
    if ( defined $from ) {
        if ( ref $from eq 'HASH' ) {
            $self->add($from);
        }
        elsif ( ref $from ) {
            die "Error from is a " . ( ref $from ) . " - not supported";
        }
        else {
            # ... handle YAML file there
        }
    }

    return $self;
}

# use our own db, other options are
# use Net::MacMap (); # less dependencies, this is a standalone db... not really up to date...
# use Net::MAC::Vendor             ();

# source https://macvendors.co/vendors/1/Amazon+Technologies+Inc.
my %AMAZON_MAC = map { lc($_) => 1 } qw{
  0C:47:C9
  34:D2:70
  40:B4:CD
  44:65:0D
  50:F5:DA
  68:37:E9
  68:54:FD
  74:75:48
  74:C2:46
  84:D6:D0
  88:71:E5
  A0:02:DC
  AC:63:BE
  B4:7C:9C
  F0:27:2D
  F0:D2:F1
};

# from http://standards-oui.ieee.org/oui/oui.txt
# 0C-47-C9   (hex)		Amazon Technologies Inc.
# 34-D2-70   (hex)		Amazon Technologies Inc.
# 40-B4-CD   (hex)		Amazon Technologies Inc.
# 44-65-0D   (hex)		Amazon Technologies Inc.
# 50-F5-DA   (hex)		Amazon Technologies Inc.
# 68-37-E9   (hex)		Amazon Technologies Inc.
# 68-54-FD   (hex)		Amazon Technologies Inc.
# 74-75-48   (hex)		Amazon Technologies Inc.
# 74-C2-46   (hex)		Amazon Technologies Inc.
# 84-D6-D0   (hex)		Amazon Technologies Inc.
# 88-71-E5   (hex)		Amazon Technologies Inc.
# A0-02-DC   (hex)		Amazon Technologies Inc.
# AC-63-BE   (hex)		Amazon Technologies Inc.
# B4-7C-9C   (hex)		Amazon Technologies Inc.
# F0-27-2D   (hex)		Amazon Technologies Inc.
# F0-D2-F1   (hex)		Amazon Technologies Inc.

sub is_mac_from_amazon {
    my $mac = shift;

    if ( defined($mac) && $mac =~ qr{^(.{8})} ) {
        return $AMAZON_MAC{$1};
    }

    return;
}

sub _pretty_mac {
    my $mac = shift;
    return unless $mac;
    return $mac if $mac =~ qr{:};
    my @ls = split( //, lc($mac) );
    my @pairs;
    my $i;
    for ( $i = 0 ; $i < scalar @ls ; $i += 2 ) {
        push @pairs, $ls[$i] . $ls[ $i + 1 ];
    }
    my $mac_formatted = join( q{:}, @pairs );    # . qq{ - $mac };

    $mac_formatted .= ' - Amazon device' if is_mac_from_amazon($mac_formatted);
    return $mac_formatted;

   #return $mac_formatted . ' - ' . Net::MAC::Vendor::lookup( $mac_formatted );
   #return $mac_formatted . ' - ' . Net::MacMap::vendor( uc( $mac_formatted ) );
}

sub search {
    my ( $pkg, %opts ) = @_;

    my $self = __PACKAGE__->new(%opts);

    my %cache;

    print "# using filter: " . $self->filter . "\n";
    print "# listening on device: " . $self->dev . "\n";

    my $use_cache = $opts{cache};
    print "# using cache " . ( $use_cache ? q{Yes} : q{No} ) . "\n";

    my $npe = Net::Pcap::Easy->new(
        dev              => $self->dev,
        filter           => $self->filter,
        packets_per_loop => 10,
        bytes_to_capture => 1024,
        promiscuous      => 0,               # true or false

        udp_callback => sub {
            my ( $npe, $ether, $ip, $udp, $header ) = @_;

            #return if $udp->{src_port} < 67 or $udp->{src_port} > 69;

            my $key = "udp:" . $ether->{src_mac};
            return if $use_cache && $cache{$key};
            $cache{$key} = 1;

            print "UDP - from $ip->{src_ip}:$udp->{src_port} [ Mac Address = "
              . _pretty_mac( $ether->{src_mac} ) . " ]\n";

            return;

        },
        arp_callback => sub {
            my ( $npe, $ether, $arp, $header ) = @_;

            my $key = "arp:" . $ether->{src_mac};

            return if $use_cache && $cache{$key};
            $cache{$key} = 1;

            print "ARP - Mac Address = "
              . _pretty_mac( $ether->{src_mac} ) . "\n";

            return;
        },
    );

    1 while $npe->loop;

    return;
}

sub listen {
    my ( $self, %opts ) = @_;

    my $all_macs = { map { $_->mac() => 1 } @{ $self->devices() } };

    my $handle_mac = sub {
        my $gotmac = shift;

        return unless defined $gotmac;
        return unless $all_macs->{$gotmac};

        foreach my $device ( @{ $self->devices() } ) {
            $device->check($gotmac);

            # do not return as we can add more than one rule for the same device
        }

        return;
    };

    my $npe = Net::Pcap::Easy->new(
        dev              => $self->dev,
        filter           => $self->filter,
        packets_per_loop => 10,
        bytes_to_capture => 1024,
        promiscuous      => 0,               # true or false

        udp_callback => sub {
            my ( $npe, $ether, $ip, $udp, $header ) = @_;

            $handle_mac->( $ether->{src_mac} );

            return;

        },
        arp_callback => sub {
            my ( $npe, $ether, $arp, $header ) = @_;

            $handle_mac->( $ether->{src_mac} );

            return;
        },
    );

    while (1) {
        $npe->loop for 1 .. 10;
        while ( my $pid = waitpid( -1, 1 ) > 0 ) {
            print "cleanup kid $pid\n";
        }
        sleep(1);
    }

    #1 while $npe->loop;

    # never reached
    return;
}

sub add {
    my ( $self, @info ) = @_;
    die unless ref $self;
    die "incorrect call to add" if ref $info[0] && defined $info[1];
    if ( ref $info[0] ) {
        @info = %{ $info[0] };
    }

    push @{ $self->devices() }, Amazon::Dash::Button::Device->new(@info);

    return $self;
}

1;

=head1 CONTRIBUTE

You can contribute to this project on github L<https://github.com/atoomic/Amazon-Dash-Button>

=cut

__END__
