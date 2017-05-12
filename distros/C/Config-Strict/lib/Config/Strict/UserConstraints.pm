package Config::Strict::UserConstraints;
use strict;
use warnings;

our $VERSION = '0.07';

use Carp qw(confess);
use Declare::Constraints::Simple-Library;

#__PACKAGE__->install_into( 'Config::Strict' );

sub make_constraint {
    my ( $class, $name, $sub, $message ) = @_;
#    $name    ||= '__ANON__';   TODO?
    confess "No name" unless $name;
    confess "Not a coderef" unless $sub and ref $sub and ref $sub eq 'CODE';
    $message ||= "Value doesn't pass $name constraint";

#    print "Making constraint $name...\n";
    # This just registers $name as a DCS constraint and returns true:
    constraint(
        $name => sub {
#                _result( $sub->( @_ ), $message );
                $sub->( @_ ) ? _true : _false( $message );
        }
    );
}

1;