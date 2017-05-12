package Config::Maker::Option::Meta;

use utf8;
use warnings;
use strict;

use Carp;

use Config::Maker::Option;
use Config::Maker::Type;
our @ISA = qw(Config::Maker::Option);

sub set {
    my ($self, $value) = @_;
    if(UNIVERSAL::isa($value, 'Config::Maker::Option')) {
	$self->{-value} = $value->{-value};
	$self->{-children} = $value->{-children};
	$self->{-parent} = $value->{-parent};
    } else {
	$self->{-value} = $value;
	$self->{-children} = [];
	$self->{-parent} = undef; # FIXME This is a bit bogus...
    }
    $self;
}

sub set_child {
    my ($self, $name, $value) = @_;
    my $child = $self->get($name);
    unless(defined $child) { # No, we don't have that child...
	my $type = Config::Maker::Type->meta->get($name);
	$child = ref($self)->new(-type => $type, -value => $value);
	push @{$self->{-children}}, $child;
	$child->{-parent} = $self;
    }
    $child->set($value);
}

1;

__END__

=head1 NAME

Config::Maker::Option::Meta - Config::Maker::Option enhanced with setter

=head1 SYNOPSIS

  use Config::Maker::Option::Meta
FIXME

=head1 DESCRIPTION

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm).

=cut
# arch-tag: edcb28cd-b566-43fb-8ada-86ced3cae3ea
