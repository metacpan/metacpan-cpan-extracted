# Copyright (c) 2005 Timothy Appnel
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
#
# Class::ConfigMgr - A base class for implementing a
# singleton object configuration manager.
#

package Class::ConfigMgr;
use strict;
use warnings;

use vars qw( $VERSION );
$VERSION = 0.1;

use Class::ErrorHandler;
@Class::ConfigMgr::ISA = qw( Class::ErrorHandler );

sub instance {
    my $class = shift;
    no strict 'refs';
    return ${"${class}::cfg"} if ${"${class}::cfg"};
    ${"${class}::cfg"} = $class->new;
}

sub new {
    my $mgr = bless { __directive => {} }, $_[0];
    $mgr->init;
    $mgr;
}

sub init { die "'init' must be overloaded." }

sub define {
    my $mgr = shift;
    my ( $dir, %param ) = @_;
    $mgr->{__directive}{$dir} = undef;
    $mgr->set( $dir, $param{Default} ) if exists $param{Default};
}

sub read_config {
    my ( $class, $cfg_file ) = @_;
    my $mgr = $class->instance;
    local ( *FH, $_, $/ );
    $/ = "\n";
    open FH, $cfg_file
      or return $class->error("Error opening file '$cfg_file': $!");
    while (<FH>) {
        chomp;
        next if !/\S/ || /^#/;
        my ( $dir, $val ) = $_ =~ /^\s*(\S+)\s+(.+)$/;
        $val =~ s/\s*$//;
        next unless $dir && defined($val);
        return $class->error("$cfg_file: $.: directive $dir")
          unless exists $mgr->{__directive}->{$dir};
        $mgr->set( $dir, $val );
    }
    close FH;
    1;
}

sub get { $_[0]->{__directive}{ $_[1] } }
sub set { $_[0]->{__directive}{ $_[1] } = $_[2] }

sub DESTROY { }

use vars qw( $AUTOLOAD );

sub AUTOLOAD {
    my $mgr = $_[0];
    ( my $dir = $AUTOLOAD ) =~ s!.+::!!;
    die("No such configuration directive '$dir'")
      unless exists $mgr->{__directive}->{$dir};
    no strict 'refs';
    *$AUTOLOAD = sub {
        my $mgr = shift;
        @_ ? $mgr->set( $dir, $_[0] ) : $mgr->get($dir);
    };
    goto &$AUTOLOAD;
}

1;

__END__

=begin

=head1 NAME

Class::ConfigMgr is a base class for implementing a
singleton object configuration manager.

=head1 SYNOPSIS
 
 # a basic subclass
 package Foo::ConfigMgr;
 use Class::ConfigMgr;
 @Foo::ConfigMgr::ISA = qw( Class::ConfigMgr );
 sub init {
    my $cfg = shift;
    $cfg->define(Foo,Default=>1); 
    $cfg->define(Bar,Default=>1); 
    $cfg->define(Baz); 
    $cfg->define(Fred); 
 }
 
 # example config file foo.cfg
 Bar 0
 Fred RightSaid
 # Foo 40
 
 # application code
 Foo::ConfigMgr->read_config('foo.cfg') or
    die Foo::ConfigMgr->errstr;
 my $cfg = Foo::ConfigMgr->instance;
 print $cfg->Foo;  # 1 (default. 40 was commented out.)
 print $cfg->Bar;  # 0
 print $cfg->Fred; # RightSaid
 print $cfg->Baz;  # (undefined)
 # print $cfg->Quux; # ERROR!
 
=head1 DESCRIPTION

Class::ConfigMgr is a base class for implementing a
singleton object configuration manager. This module is based
off of the configuration manager found in Movable Type and a 
limited subset of L<AppConfig> configuration files.

=head1 METHODS

=over

=item read_config($file)

Initializes the configuration manager by reads the
configuration file specified by $file. Returns undefined if
the configuration file could not be read. Use the C<errstr>
to retreive the error message. This method should only be
called once and before any use of the C<instance> method.

=item instance

C<instance> returns a reference to the singleton object that
is managing the configuration. As a singleton object,
developers should B<ALWAYS> call this method rather the call
than C<new>, 

=item define

This method defines which directives are recognized by the
application and optionally a default value if the directive
is not explicted defined in the configuration file.
C<define> is most commonly used within the C<init> method
all subclasses must implement.

=item error

Captures an error message and return C<undef>. Inherited
from L<Class::ErrorHandler>.

=item errstr

Returns the last captured error message set by C<error>.
Inherited from L<Class::ErrorHandler>.

=back

=head1 SUBCLASSING

Subclassing Class::ConfigMgr is easy and only requires one
method, C<init>, to be implemented.

=over

=item init

All subclasses of Class::ConfigMgr must implement an C<init>
method that defines which directives are recognized and any
associated default values. This method is automatically
called by C<read_config> before the actual configuration
file is read. It is passed a reference to the singleton and
the return value is ignored. See the example subclass in the
L<SYNOPSIS>. 

=back

=head1 DEPENDENCIES

L<Class::ErrorHandler>

=head1 LICENSE

The software is released under the Artistic License. The
terms of the Artistic License are described at 
L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, Class::ConfigMgr is Copyright
2005, Timothy Appnel, tima@cpan.org. All rights reserved.

=cut
