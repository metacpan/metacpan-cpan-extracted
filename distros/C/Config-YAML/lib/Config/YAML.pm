package Config::YAML;

# $Id: YAML.pm 41 2005-03-15 22:33:09Z mdxi $

use warnings;
use strict;
use YAML;

use vars qw( $AUTOLOAD );

=head1 NAME

Config::YAML - Simple configuration automation

=head1 VERSION

Version 1.42

=cut

our $VERSION = '1.42';

=head1 SYNOPSIS

Config::YAML is a somewhat object-oriented wrapper around the YAML
module which makes reading and writing configuration files
simple. Handling multiple config files (e.g. system and per-user
configuration, or a gallery app with per-directory configuration) is a
snap.

    use Config::YAML;

    # create Config::YAML object with any desired initial options
    # parameters; load system config; set alternate output file
    my $c = Config::YAML->new( config => "/usr/share/foo/globalconf",
                               output => "~/.foorc",
                               param1 => value1,
                               param2 => value2,
                               ...
                               paramN => valueN,
                             );

    # integrate user's own config
    $c->read("~/.foorc");

    # integrate command line args using Getopt::Long
    $rc = GetOptions ( $c,
                       'param1|p!',
                       'param2|P',
                       'paramN|n',
                     );

    # Write configuration state to disk
    $c->write;

    # simply get params back for use...
    do_something() unless $c->{param1};
    # or get them more OO-ly if that makes you feel better
    my $value = $c->get_param2;

=cut




=head1 METHODS

=head2 new

Creates a new Config::YAML object.

    my $c = Config::YAML->new( config => initial_config, 
                               output => output_config
                             );

The C<config> parameter specifies the file to be read in during object
creation. It is required, and must be the first parameter given. If
the second parameter is C<output>, then it is used to specify the file
to which configuration data will later be written out.  This
positional dependancy makes it possible to have parameters named
"config" and/or "output" in config files.

Initial configuration values can be passed as subsequent parameters to
the constructor:

    my $c = Config::YAML->new( config => "~/.foorc",
                               foo    => "abc",
                               bar    => "xyz",
                               baz    => [ 1, 2, 3 ],
                             );

=cut

sub new {
    my $class = shift;
    my %priv  = ();
    my %args  = ();

    die("Can't create Config::YAML object with no config file.\n") 
        if ($_[0] ne "config");
    shift; $priv{config} = shift;

    if (@_ && ($_[0] eq "output")) { shift; $priv{output} = shift; }
    if (@_ && ($_[0] eq "strict")) { shift; $priv{strict} = shift; }

    my $self = bless { _infile   => $priv{config},
                       _outfile  => $priv{output}   || $priv{config},
                       _strict   => $priv{strict}   || 0,
                     }, $class;

    %args = @_;
    @{$self}{keys %args} = values %args;

    $self->read;
    return $self;
}

=head2 get_*/set_*

If you'd prefer not to directly molest the object to store and
retrieve configuration data, autoloading methods of the forms
C<get_[param]> and C<set_[param]> are provided. Continuing from the
previous example:

    print $c->get_foo;      # prints "abc"
    my $val = $c->get_quux; # $c->{quux} doesn't exist; returns undef

    $c->set_bar(30);     # $c->{bar} now equals 30, not "xyz"
    my @list = qw(alpha beta gamma);
    $c->set_baz(\@list); # $c->{baz} now a reference to @list

=cut

sub Config::YAML::AUTOLOAD {
    no strict 'refs';
    my ($self, $newval) = @_;

    if ($AUTOLOAD =~ /.*::get_(\w+)/) {
        my $attr = $1;
        return undef if (!defined $self->{$attr});
        *{$AUTOLOAD} = sub { return $_[0]->{$attr} };
        return $self->{$attr};
    }

    if ($AUTOLOAD =~ /.*::set_(\w+)/) {
        my $attr = $1;
        *{$AUTOLOAD} = sub { $_[0]->{$attr} = $_[1]; return };
        $self->{$attr} = $newval;
        return;
    }
}

=head2 fold

Convenience method for folding multiple values into the config object
at once. Requires a hashref as its argument.

    $prefs{theme}  = param(theme);
    $prefs{format} = param(format);
    $prefs{sortby} = param(order);

    $c->fold(\%prefs);

    my $format = $c->get_format; # value matches that of param(format)

=cut

sub fold {
    my ($self, $data) = @_;
    # add check for HASHREF when strict mode is implemented
    @{$self}{keys %{$data}} = values %{$data};
}

=head2 read

Imports a YAML-formatted config file.

    $c->read('/usr/share/fooapp/fooconf');

C<read()> is called at object creation and imports the file specified
by C<< new(config=>) >>, so there is no need to call it manually
unless multiple config files exist.

=cut

sub read {
    my ($self, $file) = @_;
    $self->{_infile} = $file if $file;

    my $yaml;
    my $line;

    open(FH,'<',$self->{_infile}) or die "Can't open $self->{_infile}; $!\n";
    while ($line = <FH>) {
        next if ($line =~ /^\-{3,}/);
        next if ($line =~ /^#/);
        next if ($line =~ /^$/);
        $yaml .= $line;
    }
    close(FH);

    my $tmpyaml = Load($yaml);
    @{$self}{keys %{$tmpyaml}} = values %{$tmpyaml}; # woo, hash slice
}

=head2 write

Dump current configuration state to a YAML-formatted flat file.

    $c->write;

The file to be written is specified in the constructor call. See the
C<new> method documentation for details.

=cut

sub write {
    my $self = shift;
    my %tmpyaml;

    # strip out internal state parameters
    while(my($k,$v) = each%{$self}) {
        $tmpyaml{$k} = $v unless ($k =~ /^_/);
    }

    # write data out to file
    open(FH,'>',$self->{_outfile}) or die "Can't open $self->{_outfile}: $!\n";
    print FH Dump(\%tmpyaml);
    close(FH);
}

=head1 DEPRECATED METHODS

These methods have been superceded and will likely be removed in the
next release.

=head2 get

Returns the value of a parameter.

    print $c->get('foo');

=cut

sub get {
    my ($self, $arg) = @_;
    return $self->{$arg};
}

=head2 set

Sets the value of a parameter:

    $c->set('foo',1);

    my @paints = qw( oil acrylic tempera );
    $c->set('paints', \@paints);

=cut

sub set {
    my ($self, $key, $val) = @_;
    $self->{$key} = $val;
}

=head1 AUTHOR

Shawn Boyette (C<< <mdxi@cpan.org> >>)

Original implementation by Kirrily "Skud" Robert (as
C<YAML::ConfigFile>).

=head1 BUGS

=over

=item

Config::YAML ignores the YAML document separation string (C<--->)
because it has no concept of multiple targets for the data coming from
a config file.

=back

Please report any bugs or feature requests to
C<bug-yaml-configfile@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Shawn Boyette, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; # End of Config::YAML
