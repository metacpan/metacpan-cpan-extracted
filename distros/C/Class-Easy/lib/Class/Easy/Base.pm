package Class::Easy::Base;

use Class::Easy::Import;

require Class::Easy;

sub import {
	my $mypkg   = shift;
	my $callpkg = caller;
	
	my %params = @_;
	
	# use warnings
	${^WARNING_BITS} ^= ${^WARNING_BITS} ^ $Class::Easy::Import::WARN;
	
	# use strict, use utf8;
	$^H |= $Class::Easy::Import::H;
	
	# use feature
	$^H{feature_switch} = $^H{feature_say} = $^H{feature_state} = 1;
	
	# probably check for try_to_use is enough
	return
		if defined *{"$callpkg\::try_to_use"}{CODE}
			and Class::Easy::sub_fullname (*{"$callpkg\::try_to_use"}{CODE}) eq 'Class::Easy::__ANON__';
	
	# export subs
	*{"$callpkg\::$_"} = \&{"Class::Easy::$_"} foreach @Class::Easy::EXPORT;
	foreach my $p (keys %Class::Easy::EXPORT_FOREIGN) {
		*{"$callpkg\::$_"} = \&{"$p\::$_"} foreach @{$Class::Easy::EXPORT_FOREIGN{$p}};
	}
	
	push @{"$callpkg\::ISA"}, 'Class::Easy::Base';

}

sub new {
	my $class  = shift;
	my $params = {@_};
	
	bless $params, $class;
}

sub set_field_values {
	my $self   = shift;
	my %params = @_;
	
	foreach my $k (keys %params) {
		$self->$k ($params{$k});
	}
}

sub list_all_subs {
	my $class = shift;
	
	$class = ref $class if ref $class;
	
	my $sub_by_type = Class::Easy::list_all_subs_for ($class);
	
	wantarray
		? (
			keys %{$sub_by_type->{method}}, 
			keys %{$sub_by_type->{runtime}},
			map {@{$sub_by_type->{inherited}->{$_}}} keys %{$sub_by_type->{inherited}})
		: $sub_by_type;

}

sub attach_paths {
	my $class = shift;
	
	$class = ref $class if ref $class;
	
	my @pack_chunks = split(/\:\:/, $class);
	
	require File::Spec;
	
	my $FS = 'File::Spec';
	
	my $pack_path = join ('/', @pack_chunks) . '.pm';
	my $pack_inc_path = $INC{$pack_path};

	$pack_path = $FS->canonpath ($pack_path);
	
	my $pack_abs_path = $FS->rel2abs ($FS->canonpath ($pack_inc_path));
	Class::Easy::make_accessor ($class, 'package_path', default => $pack_abs_path);
	
	my $lib_path = substr ($pack_abs_path, 0, rindex ($pack_abs_path, $pack_path));
	Class::Easy::make_accessor ($class, 'lib_path', default => $FS->canonpath ($lib_path));
}

1;

__END__

=head1 NAME

Class::Easy::Base - base package for classes

=head1 ABSTRACT

when you use this package, it makes everything of Class::Easy available for you
with OOP sause.

=head1 SYNOPSIS

SYNOPSIS

	package My::Class;
	
	use Class::Easy::Base;
	
	has x => (is => 'ro');
	
	has 'y';
	
	1;
	
	package main;
	
	my $c = My::Class->new (x => 1, y => 2);
	
	$c->x;     # return 1
	
	$c->x (3); # store 3

=head1 BEWARE

THIS PACKAGE PUT HERSELF INTO CALLER CLASS @ISA. IF YOU DON'T WANT SUCH
STRANGE BEHAVIOUR, PLEASE USE L<Class::Easy>
	
=head1 METHODS

=head2 new

create new object

	my $c = My::Class->new (x => 1, y => 2);

=cut

=head2 attach_paths

make two accessor methods: lib_path and package_path

=cut

=head2 list_all_subs

return sub list

for detailed explanation, please see 'list_all_subs_for' function in L<Class::Easy>

=cut

=head2 set_field_values

set field values by calling accessor methods

	$c->set_field_values (x => 3, y => 4);
	# equivalent calls:
	$c->x (3);
	$c->y (4);

=cut

=head1 AUTHOR

Ivan Baktsheev, C<< <apla at the-singlers.us> >>

=head1 BUGS

Please report any bugs or feature requests to my email address,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Easy>. 
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT



=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Ivan Baktsheev

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
