package Class::Iterator;


# Copyright (c) 2003 Robert Silve
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself. 


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(imap igrep);

use Carp;

our $VERSION = "0.3";

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);
    $self->generator(shift || sub { return sub { return } });
    $self->init;
    return $self;
}

sub init {
    my $self = shift;
    $self->iterator($self->generator->())
}


sub next {
    my $self = shift;
    return $self->iterator->();
}

sub generator {
    my $self = shift;
    my $arg = shift;
    if ($arg) {
	$self->{_generator} = $arg;
    } else {
	return $self->{_generator};
    }

}

sub iterator {
    my $self = shift;
    my $arg = shift;
    if ($arg) {
	$self->{_iterator} = $arg;
    } else {
	return $self->{_iterator};
    }

}

sub AUTOLOAD {
    my ($self) = @_;
    my ($pack, $meth) =($AUTOLOAD =~ /^(.*)::(.*)$/);
    my @auth = qw(generator iterator);
    my %auth = map { $_ => 1 } @auth;
    unless ($auth{$meth}) {
	croak "Unknow method $meth";
    }
    
    my $code = sub {
	my $self = shift;
	my $arg = shift;
	if ($arg) {
	    $self->{"_$meth"} = $arg;
	} else {
	    return $self->{"_$meth"};
	}
    };
    
    *$AUTOLOAD = $code;
    goto &$AUTOLOAD;
	    
}

sub _imap {
    my ($rule, $generator) = @_;
    my $it = $generator->();
    return sub {
	return sub {
	    local $_ = $it->();
	    return unless defined $_;
	    return $rule->();
	}
    }
    
}

sub imap (&$) {
    my ($rule, $self) = @_;
    return $self->new(_imap($rule, $self->generator));
}


sub _igrep {
    my ($rule, $it) = @_;
#    my $it = $generator->();
    return sub {
	return sub {
	    while ( defined(my $v = $it->()) ) {
		local $_ = $v;
		return $_ if $rule->();
	    }
	    return;
	}
    }
    
}


sub igrep (&$) {
    my ($rule, $self) = @_;
    return $self->new(_igrep($rule, $self->iterator));
}



1;


__END__


# Below is stub documentation for your module. You better edit it!

=head1 NAME

Class::Iterator - Iterator class

=head1 SYNOPSIS

  use Class::Iterator;
  my $it = Class::Iterator->new(\&closure_generator);

  while (my $v = $it->next) { print "value : $v\n" }
  
  # use map like
  my $it2 = imap { ...some code with $_...} $it
  while (my $v = $it->next) { print "value : $v\n" }

  # use grep like
  my $it3 = igrep { ...some code with $_...} $it
  while (my $v = $it->next) { print "value : $v\n" }


=head1 DESCRIPTION

Class::Iterator is a generic iterator object class. It use a closure an wrap 
into an object interface.

=over 4

=item new(\&closure_generator)

This is the constructor. The argument is a sub which look like
  sub closure_generator {
    my $private_data;
    return sub {
      # do something with $private_data
      # and return it
      return $private_data
    }
}

=item next

calling this method make one iteration. 

=item $o = imap { ... } $it

This a creator. It create a new iterator from an existant
iterator in the manner of map.

=item $o = igrep { ... } $it

This a creator. It create a new iterator from an existant
iterator in the manner of grep.


=back

=head1 CREDITS

Marc Jason Dominius's YAPC::EU 2003 classes.
Ken Olstad 

=head1 AUTHOR

Robert Silve <robert@silve.net>

=cut
