# NAME
Amazon::Dash::Button - a very simple perl interface to play & interact with an Amazon Dash Button.

# VERSION

version 0.11

# DESCRIPTION

Amazon::Dash::Button allows you to discover your mac address button and
set a listener to run any custom actions when the button is clicked...

Here is a non exhaustive list of ideas, applications you can think about:

- control your music player (provide an example for mpd: Music Player Daemon)
- silent doorbell which send a notification (text, email, ...)
- order your favorite pizza
- switch on/off the light
- open the garage door
- ...

Feel free to complete this list, and submit more ideas.

This can be used on a Raspberry Pi, linux, mac os computer...
In order to properly listen to packets you would need to run it as root using 'sudo' 

# Setting

## Linking the button to your wifi network

The first thing to do once you have received your button is to set it and discover it.
Here is the basic setting process:

- use your phone or table to perform the basic setting, but do not complete it, stop when asking to select to link a product with the button.
- in the mobile app you would find a menu "Your Dash Button" -> "Settings" then "Set up a new device".
- choose your dash device, then follow the instructions: long press on the button until it discovery mode (blue light)
- provide the wifi password of your network
- but do not select the exact product linked to your button exit from there !

## Detecting the button

Amazon::Dash::Button comes with one search method which allows you to look for your device.
You mainly want to know the mac address of your button

### \* from the command line

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

### \* oneliner

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

# Usage

## Manage a single button

Create one object and call listen on it.

                Amazon::Dash::Button->new( from => {
                        # required options
                        mac     => '00:11:22:33:44:55',
                        onClick => sub { print q{Got a Click !} },
                        #... optional options
                        #name => q{Your Button Name},
                        #timeout => 5, # in seconds
                        #_fork_for_onClick => 1, # run the onClick in a forked process
                        } )->listen;

## Add more than a single button to the same listener

You can chain multiple button declaration using the add fucntion.

                Amazon::Dash::Button->new()->add(
                        mac     => '00:11:22:33:44:55',
                        onClick => sub { ... },
                        )->add(
                        mac     => 'aa:11:22:33:44:66',
                        onClick => sub { ... },
                        )->add(
                        mac     => 'bb:11:22:33:44:77',
                        onClick => sub { ... },
                        # ... you can add as many button as you want
                        )->listen();

## Options when creating a new Amazon::Dash::Button object

Here are some options when creating a button listener
Same as for search you can add a filter to listen.

                Amazon::Dash::Button->new( from => ...,
                        dev     => q{eth0},
                        filter  => q{'udp and ( port 67 or port 68 )},
                        timeout => 5, # ignore any further clicks in the next 5 seconds
                 )->listen();

# Basic installation process

Here are some basic steps to install it on a Raspberry Pi for example:

        cpanm Amazon::Dash::Button
        apt-get install libpcap0.8
        apt-get install libpcap-dev

The git repo also provides a very basic systemctl service

        cd systemctl/
        # adjust the path to your perl script then
        sudo make install

# CONTRIBUTE

You can contribute to this project on github [https://github.com/atoomic/Amazon-Dash-Button](https://github.com/atoomic/Amazon-Dash-Button)
