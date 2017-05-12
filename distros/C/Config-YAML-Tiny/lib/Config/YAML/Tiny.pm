package Config::YAML::Tiny;
use strict;
use warnings;

use YAML::Tiny qw(Load Dump);

use vars qw( $AUTOLOAD );

our $VERSION = '1.42.0';

sub new {
    my $class = shift;
    my %priv  = ();
    my %args  = ();

    die("Can't create Config::YAML object with no config file.\n")
      if ( $_[0] ne "config" );
    shift;
    $priv{config} = shift;

    if ( @_ && ( $_[0] eq "output" ) ) { shift; $priv{output} = shift; }
    if ( @_ && ( $_[0] eq "strict" ) ) { shift; $priv{strict} = shift; }

    my $self = bless {
                       _infile  => $priv{config},
                       _outfile => $priv{output} || $priv{config},
                       _strict  => $priv{strict} || 0,
    }, $class;

    %args = @_;
    @{$self}{ keys %args } = values %args;

    $self->read;
    return $self;
} ## end sub new

sub Config::YAML::Tiny::AUTOLOAD {
    no strict 'refs';
    my ( $self, $newval ) = @_;

    if ( $AUTOLOAD =~ /.*::get_(\w+)/ ) {
        my $attr = $1;
        return undef if ( !defined $self->{$attr} );
        *{$AUTOLOAD} = sub { return $_[0]->{$attr} };
        return $self->{$attr};
    }

    if ( $AUTOLOAD =~ /.*::set_(\w+)/ ) {
        my $attr = $1;
        *{$AUTOLOAD} = sub { $_[0]->{$attr} = $_[1]; return };
        $self->{$attr} = $newval;
        return;
    }
}

sub fold {
    my ( $self, $data ) = @_;

    # add check for HASHREF when strict mode is implemented
    @{$self}{ keys %{$data} } = values %{$data};
}

sub read {
    my ( $self, $file ) = @_;
    $self->{_infile} = $file if $file;

    my $yaml = '';
    my $line;

    open( FH, '<', $self->{_infile} )
      or die "Can't open $self->{_infile}; $!\n";
    while ( $line = <FH> ) {
        next if ( $line =~ /^\-{3,}/ );
        next if ( $line =~ /^#/ );
        next if ( $line =~ /^$/ );
        $yaml .= $line;
    }
    close(FH);
    my $tmpyaml = Load($yaml);
    @{$self}{ keys %{$tmpyaml} } = values %{$tmpyaml};    # woo, hash slice
}

sub write {
    my $self = shift;
    my %tmpyaml;

    # strip out internal state parameters
    while ( my ( $k, $v ) = each %{$self} ) {
        $tmpyaml{$k} = $v unless ( $k =~ /^_/ );
    }

    # write data out to file
    open( FH, '>', $self->{_outfile} )
      or die "Can't open $self->{_outfile}: $!\n";
    print FH Dump( \%tmpyaml );
    close(FH);
}

sub get {
    my ( $self, $arg ) = @_;
    return $self->{$arg};
}

sub set {
    my ( $self, $key, $val ) = @_;
    $self->{$key} = $val;
}

1;    # End of Config::YAML

__END__

=head1 NAME

Config::YAML::Tiny - simple reading and writing of YAML-formatted
configuration files using YAML::Tiny

=head1 VERSION

Version 1.42.0

=cut

=head1 SYNOPSIS

    use Config::YAML::Tiny;

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

=head1 DESCRIPTION

Config::YAML is a somewhat object-oriented wrapper around
the YAML module which makes reading and writing
configuration files simple. Handling multiple config files
(e.g. system and per-user configuration, or a gallery app
with per-directory configuration) is a snap.

=head1 METHODS

=head2 new

Creates a new Config::YAML::Tiny object.

    my $c = Config::YAML::Tiny->new( config => initial_config, 
                               output => output_config
                             );

The C<config> parameter specifies the file to be read in
during object creation. It is required, and must be the
first parameter given. If the second parameter is C<output>,
then it is used to specify the file to which configuration
data will later be written out.  This positional dependancy
makes it possible to have parameters named "config" and/or
"output" in config files.

Initial configuration values can be passed as subsequent
parameters to the constructor:

    my $c = Config::YAML::Tiny->new( config => "~/.foorc",
                               foo    => "abc",
                               bar    => "xyz",
                               baz    => [ 1, 2, 3 ],
                             );

=cut

=head2 get_*/set_*

If you'd prefer not to directly molest the object to store
and retrieve configuration data (something I B<highly
recommend>, autoloading methods of the forms C<get_[param]>
and C<set_[param]> are provided. Continuing from the
previous example:

    print $c->get_foo;      # prints "abc"
    my $val = $c->get_quux; # $c->{quux} doesn't exist; returns undef

    $c->set_bar(30);     # $c->{bar} now equals 30, not "xyz"
    my @list = qw(alpha beta gamma);
    $c->set_baz(\@list); # $c->{baz} now a reference to @list

=cut

=head2 fold

Convenience method for folding multiple values into the
config object at once. Requires a hashref as its argument.

    $prefs{theme}  = param(theme);
    $prefs{format} = param(format);
    $prefs{sortby} = param(order);

    $c->fold(\%prefs);

    my $format = $c->get_format; # value matches that of param(format)

=cut

=head2 read

Imports a YAML-formatted config file.

    $c->read('/usr/share/fooapp/fooconf');

C<read()> is called at object creation and imports the file
specified by C<< new(config=>) >>, so there is no need to
call it manually unless multiple config files exist.

=cut

=head2 write

Dump current configuration state to a YAML-formatted flat
file.

    $c->write;

The file to be written is specified in the constructor call.
See the C<new> method documentation for details.

=cut

=head1 DEPRECATED METHODS

These methods have been superceded and will likely be
removed in the next release.

=head2 get

Returns the value of a parameter.

    print $c->get('foo');

=cut

=head2 set

Sets the value of a parameter:

    $c->set('foo',1);

    my @paints = qw( oil acrylic tempera );
    $c->set('paints', \@paints);

=cut

=head1 COMPATABILITY WITH CONFIG::YAML

This module should be able to work as a drop in replacement
of L<Config::YAML>.

This code began as a quick post of the L<Config::YAML> 1.42
code changing as little as possible to get YAML::Tiny
working and the module passing all of the unit tests
provided by its predecessor.

In future releases I plan on refactoring the methods to
replacement some of its code with functionality already in
YAML::Tiny. I also intend on removing the deprecated methods
at some point also.

My intention will be to maintain compatability with
L<Config::YAML> using the original unit test.

=head1 KNOWN ISSUES

=over

=item

Config::YAML::Tiny ignores the YAML document separation
string (C<--->) because it has no concept of multiple
targets for the data coming from a config file.

=back

=head1 SUPPORT

Bugs should be reported via the GitHub project issues
tracking system:
L<http://github.com/tima/perl-config-yaml-tiny/issues>.

=head1 AUTHOR

Timothy Appnel (<tima@cpan.org>)

Originally based on Config::YAML by Shawn Boyette
(<mdxi@cpan.org>) who based his original implementation off of
C<YAML::ConfigFile> by Kirrily "Skud" Robert.

=head1 SEE ALSO

L<Config::YAML> L<YAML::Tiny>

=head1 COPYRIGHT AND LICENCE

Config::YAML:Tiny is Copyright 2010, Timothy Appnel, 
tima@cpan.org unlessnoted otherwise. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
