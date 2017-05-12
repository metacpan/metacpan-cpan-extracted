package Config::Autoload;

use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.01';

sub new {

    my $class = shift;
    my $file = shift;
    my $construct = shift;

    if ( ! -f $file ) {
        croak "The config file doesn't exist";
    } elsif ( ! -r $file ) {
        croak "The config file isn't readable";
    }

    if ( defined($construct) && ref($construct) ne 'CODE' ) {
        croak "The second argument for new() must be a coderef";
    }

    my $mtime = (stat($file))[9];
    my $c;

    if ( defined $construct ) {
        $c = $construct->($file);
        unless (ref($c) eq 'HASH') {
            croak "Not a hashref returned from the subroutine";
        }
    } else {
        $c = _construct($file);
    }

    bless { file => $file, mtime => $mtime, 
            c => $c, construct => $construct }, $class;
}
        
sub _construct {

    my $file = shift;
    my %hash;

    open HD,$file or croak $!;
    while(<HD>) {
        next if /^#|^$/;
        chomp;
        my ($k,$v) = split;
        $hash{$k} = $v;
    }
    close HD;

    return \%hash;
}

sub load_key {

    my $self = shift;
    my $key = shift;

    return undef unless defined $key;

    my $file = $self->{file}; 

    if ( ! -f $file ) {
        for (0..3) {
            select(undef,undef,undef,0.25);
            last if -f $file;
        }
    }

    croak "The config file seems not exists" unless -f $file;
    my $mtime = (stat($file))[9];

    if ( $mtime != $self->{mtime} ) {
        $self = __PACKAGE__->new($file,$self->{construct});
    }

    return $self->{c}->{$key};
}

1;


=head1 NAME

Config::Autoload - Autoloads the config file whenever it is changed

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

    use Config::Autoload;

    my $config = Config::Autoload->new("/path/sample.conf");
    my $value = $config->load_key('key');

    # or

    my $config = Config::Autoload->new("/path/sample.conf",\&construct);
    my $value = $config->load_key('key');

    sub construct {

        my $file = shift;
        my %hash;

        open FD,$file or die $!;
        while(<FD>) {
            next if /^#|^$/;
            chomp;
            my ($k,$v) = split/ = /,$_;
            $hash{$k} =$v;
        }
        close FD;

        \%hash;
    }


=head1 METHODS

=head2 new()

Create an object. The full path to the config file is required.

    my $config = Config::Autoload->new("/path/sample.conf");

If the second argument is ignored, new() uses a defalut construct()
to built up a hash for storing the keys/values in the config file.

The default config file should be like:

    host 192.168.1.100
    port 1234
    user guest
    pass mypasswd

If you are using the different style of config file, you could built
up your own construct() and pass it to the new() method.

For example, the config file looks like:

    host = 192.168.1.100
    port = 1234
    user = guest
    pass = mypasswd

Then a construct() for it could be:

    sub construct {

        my $file = shift;  # you just shift it
        my %hash;

        open FD,$file or die $!;
        while(<FD>) {
            next if /^#|^$/;
            chomp;
            my ($k,$v) = split/ = /,$_;
            $hash{$k} =$v;
        }
        close FD;

        \%hash;  # requires a hashref to be returned
    }

And pass the reference of this subroutine to new():

    my $config = Config::Autoload->new("/path/sample.conf",\&construct);


=head2 load_key()

Load the value with a key from the config file.

    my $value = $config->load_key('key');

I primarily used this module for mod_perl, under which the object exists
for long time. Whenever the config file was changed, load_key() method will
get the updated value.


=head1 AUTHOR

Jeff Pang <pangj@arcor.de>


=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <pangj@arcor.de>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Autoload


=head1 COPYRIGHT & LICENSE

Copyright 2010 Jeff Pang, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.
