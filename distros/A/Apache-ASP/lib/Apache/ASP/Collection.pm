
package Apache::ASP::Collection;

use Apache::ASP::CollectionItem;
use strict;

sub Contents { 
    my($self, $key) = @_;
    
    if(defined $key) {
	$self->Item($key);
    } else {
	$self;
    }
}

sub Item {
    my($self, $key, $value) = @_;
    my @rv;
    my $item_config = $main::Server->Config('CollectionItem');

    if(defined $value) {
	if(ref($self->{$key}) and $self->{$key} =~ /HASH/) {
	    # multi leveled collection go two levels down
	    $rv[0] = $self->{$key}{$value};
	} else {
	    return $self->{$key} = $value;
	}
    } elsif(defined $key) {
	my $value = $self->{$key};	
	if (defined $value) {
	    if(wantarray || $item_config) {
		@rv = (ref($value) =~ /ARRAY/o) ? @{$value} : ($value);
	    } else {
		@rv = (ref($value) =~ /ARRAY/o) ? ($value->[0]) : ($value);
	    }
	} else {
	    $rv[0] = $value;
	}
    } else {
	# returns hash to self by default, so compat with 
	# $Request->Form() & such null collection calls.
	return $self;
    }

    # coming from the collections we need this like
    # $Request->QueryString('foo')->Item() syntax, but is incompatible
    # with $Request->QueryString('foo') syntax
    if ($item_config) {
	$rv[0] = Apache::ASP::CollectionItem->new(\@rv);
    }

    wantarray ? @rv : $rv[0];
}

sub Count {
    my $self = shift;
    scalar(keys %$self);
}

sub Key {
    my($self, $index) = @_;
    my @keys = sort(keys %$self);
    $keys[$index-1];
}

sub SetProperty {
    my($self, $property, $key, $value) = @_;
    if($property =~ /property/io) {
	# do this to avoid recursion
	die("can't get the property $property for $self");
    } else {
	$self->$property($key, $value);
    }
}	

sub GetProperty {
    my($self, $property, $key) = @_;
    if($property =~ /property/io) {
	# do this to avoid recursion
	die("can't get the property $property for $self");
    } else {
	$self->$property($key);
    }
}	
	
1;
