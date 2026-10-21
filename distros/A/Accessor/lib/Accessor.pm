package Accessor;

=head1 NAME

Accessor - base class for accessor-pattern classes

=head1 USAGE

    my $obj = new Hash(myattr => 1);
    
    say $obj->myattr();   # get myattr, say 1
    say $obj->myattr(0);  # set myattr to 0
    
    package Hash;
    
    use base 'Accessor';
    
    sub new {
        my $class = shift;
        return bless {@_}, $class;
    }

=head1 VERSION

0.5

=head1 AUTHOR

Developed by Ivan Trunaev

Contacts <ivan@trunaev.ru>

=cut


use strict;
use warnings;

our $VERSION = '0.5';

our $AUTOLOAD;

sub AUTOLOAD {
	my $self = shift;

	my $name = $AUTOLOAD;
	return if $name =~ /^.*::[A-Z]+$/;
	$name =~ s/^.*:://;   # strip fully-qualified portion


	my $sub = sub {
		my $self = shift;
		if (scalar @_) {
			my $val = shift;
			$self->{$name} = $val;			
		}
		return $self->{$name};
	};

	no strict 'refs';
	*{$AUTOLOAD} = $sub;

	return $sub->($self, @_);
}

1;
