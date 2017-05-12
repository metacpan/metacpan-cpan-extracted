package Attribute::Boolean::Value;

use strict;
use warnings; # FATAL => 'all';
use 5.14.0;
use utf8;

=head1 NAME

Attribute::Boolean::Value - An overridden class for a boolean value

=head1 USAGE

This is a private class for use only by Attribute::Boolean

=cut

use parent 'Exporter';
use version;
use Carp;

our $VERSION = version->declare('v1.0.7');
our @EXPORT = qw(true false);

sub true();
sub false();

use overload
   "0+"    => sub { ${$_[0]} },
   "bool"  => sub { ${$_[0]} },
   '""'    => sub { ${$_[0]} ? 'true' : 'false'},
   '!'	   => sub { ${$_[0]} ? false : true},
   '-'	   => sub { croak 'subtraction not possible'},
   '+'	   => sub { croak 'addition not possible'},
   fallback => 1
   ;

my $true  = do { bless \(my $dummy = 1), __PACKAGE__ };
my $false = do { bless \(my $dummy = 0), __PACKAGE__ };

sub true()  { $true  }
sub false() { $false }

sub TO_JSON($) {
    return $_[0] ? \1 : \0;
}

1;
