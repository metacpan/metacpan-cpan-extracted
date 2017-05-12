package Data::All::Base;


use strict;


use Symbol;

use base 'Exporter';

our @EXPORT = qw(new internal attribute populate  error );

our $VERSION = 1.0;

sub internal;
internal 'ERROR'	=> [];

sub error {
	my $self = shift;
	push (@{ $self->__ERROR() }, @_) if @_;
	$self->__ERROR();
}

sub new
#   Bypass Spiffy's new, so we can call init()
{
    my $class = shift;
    my $self = bless Symbol::gensym(), $class;
	
    return ($self->can('init'))
        ? $self->init(@_)
        : $self;
}


sub attribute 
# Creates an anonymous subroutine and places it in the caller's
# package (i.e. $self->name). 
# Consider lvalue expression to allow $self->name = "newvalue".
# http://perl.active-venture.com/pod/perlsub.html
{
    my $package = caller;
    my ($attribute, $default) = @_;
    no strict 'refs';
    return if defined &{"${package}::$attribute"};
    *{"${package}::$attribute"} =
      sub {
          my $self = shift;
          unless (exists *$self->{$attribute}) {
              *$self->{$attribute} = 
                ref($default) eq 'ARRAY' ? [] :
                ref($default) eq 'HASH' ? {} : 
                $default;
          }
          return *$self->{$attribute} unless @_;
          *$self->{$attribute} = shift;
      };
}

sub internal
#   Used like attribute 'name' => 'val'. The difference being
#   the internal attribute and it accessor are stored as '__name'
{
    my $package = caller;
    my ($attribute, $default) = @_;
    $attribute = "__$attribute";
    no strict 'refs';
    return if defined &{"${package}::$attribute"};
    *{"${package}::$attribute"} =
      sub {
          my $self = shift;
          unless (exists *$self->{$attribute}) {
              *$self->{$attribute} = $default;
          }
          return *$self->{$attribute} unless @_;
          *$self->{$attribute} = shift;
      };
}


sub populate 
#   populate $self->ACCESSOR with arguments in $args.
#   This is usually called by init() after the args have been parsed. 
{
    my ($self, $args) = @_;

    for my $a (keys %{ $args })
    {
        warn("No attribute method for $a"), next 
            unless $self->can($a);
        #warn 9, "Running $a"; 
        $self->$a($args->{$a});
    }
}






1;