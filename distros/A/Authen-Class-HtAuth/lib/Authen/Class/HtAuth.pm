package Authen::Class::HtAuth::Base;

use strict;
use warnings;

use base 'Class::Data::Inheritable';

# Crikey!  I don't really like this.
# Explanation:
# a) create these inheritable class data accessors
# b) in the "real" class, override them to turn them into translucent dealies
__PACKAGE__->mk_classdata('htusers');
__PACKAGE__->mk_classdata('htgroups');
__PACKAGE__->mk_classdata('_ApacheHtpasswd');
__PACKAGE__->mk_classdata('_ApacheHtgroup');


package Authen::Class::HtAuth;
use base 'Authen::Class::HtAuth::Base';

use strict;
use warnings;

use Carp;
use Apache::Htpasswd;
use Apache::Htgroup;

our $VERSION = 0.02;

sub _ApacheHtpasswd {
	my $self = shift;

	if (ref $self and defined $self->{_apachehtpasswd}) {
		$self->{_apachehtpasswd} = shift if @_;
		$self->{_apachehtpasswd};
	}
	else {
		$self->__ApacheHtpasswd_accessor(@_);
	}
}

sub _ApacheHtgroup {
	my $self = shift;

	if (ref $self and defined $self->{_apachehtgroup}) {
		$self->{_apachehtgroup} = shift if @_;
		$self->{_apachehtgroup};
	}
	else {
		$self->__ApacheHtgroup_accessor(@_);
	}
}

sub htusers {
	my $self = shift;

	if (ref $self) {
		if (@_) {
			$self->{_apachehtpasswd} = Apache::Htpasswd->new(
				{ passwdFile => $_[0],
				  ReadOnly => 1,
				}
			);
			$self->{htusers} = $_[0];
		}

		return defined $self->{htusers} ? $self->{htusers} : $self->_htusers_accessor;
	}
	else {
		if (@_) {
			$self->_ApacheHtpasswd(
				Apache::Htpasswd->new(
					{ passwdFile => $_[0],
					  ReadOnly => 1,
					}
			) );
		}

		return $self->_htusers_accessor(@_);
	}
}

sub htgroups {
	my $self = shift;

	if (ref $self) {
		if (@_) {
			$self->{_apachehtgroup} = Apache::Htgroup->new($_[0]);
			$self->{htgroups} = $_[0];
		}

		return defined $self->{htgroups} ? $self->{htgroups} : $self->_htgroups_accessor;
	}
	else {
		if (@_) {
			$self->_ApacheHtgroup( Apache::Htgroup->new($_[0]) );
		}

		return $self->_htgroups_accessor(@_);
	}
}

sub _op_group_check {
	my ($htgroup, $user, $groupdef)  = @_;
	my ($op, @groups) = @$groupdef;

	if (lc $op eq "all") {
		foreach (@groups) {
			return 0 unless ref $_ eq "ARRAY"
				? _op_group_check($htgroup, $user, $_)
				: $htgroup->ismember($user, $_);
		}
		return 1;
	}
	elsif (lc $op eq "one") {
		foreach (@groups) {
			return 1 if ref $_ eq "ARRAY"
				? _op_group_check($htgroup, $user, $_)
				: $htgroup->ismember($user, $_);
		}
		return 0;
	}
	elsif (lc $op eq "not") {
		foreach (@groups) {
			return 0 if ref $_ eq "ARRAY"
				? _op_group_check($htgroup, $user, $_)
				: $htgroup->ismember($user, $_);
		}
		return 1;
	}
	else {
		croak "bad group definition, unknown logical operand $op";
	}
}

sub check {
	my ($self, $user, $pass, %named) = @_;

	return 0 unless $self->_ApacheHtpasswd->htCheckPassword($user, $pass);

	if (defined $named{groups}) {
		return 0 unless $self->groupcheck($user, %named);
	}

	return 1;
}

sub groupcheck {
	my ($self, $user, %named) = @_;
	my @groups;

	defined $named{groups} or croak "->groupcheck called with no groups to check";

	@groups = @{$named{groups}};

	GROUP: foreach (@groups) {
		if (ref $_ eq "ARRAY") {
			return 0 unless _op_group_check($self->_ApacheHtgroup, $user, $_);
		}
		else {
			return 0 unless $self->_ApacheHtgroup->ismember($user, $_);
		}
	}

	return 1;
}

sub new {
	my ($proto, %opts) = @_;
	my $class = ref $proto || $proto;

	my $self = bless {}, $class;

	$self->htusers($opts{htusers}) if $opts{htusers};
	$self->htgroups($opts{htgroups}) if $opts{htgroups};

	return $self;
}

1;
__END__

=head1 NAME

Authen::Class::HtAuth - class-based authentication backend using Apache user
and group files

=head1 SYNOPSIS

  use Authen::Class::HtAuth;

  my $htauth = Authen::Class::HtAuth->new(
    htusers  => "/path/to/users",
    htgroups => "/path/to/groups",
  );

  if ($htauth->check($user, $pass)) { ... }
  if ($htauth->check($user, $pass, groups => [qw/foo bar baz/])) { ... }

=head1 DESCRIPTION

Authen::Class::HtAuth is an authentication backend for use with Apache passwd
and group files.  Authen::Class::HtAuth can be instantiated as an object or
inherited into your own class.

Class-based example:

  package MyAuth;
  use base 'Authen::Class::HtAuth';

  MyAuth->htusers("/path/to/users");
  MyAuth->htgroups("/path/to/groups"); # optional

# elsewhere...
  
  use MyAuth;
  if (MyAuth->check("user", "pass", groups => ["foo"]))  # groups is optional
  { ... }

Object example:
  
  use Authen::Class::HtAuth;

  my $htauth = Authen::Class::HtAuth->new(
    htusers => "/path/to/users",   # optional
    htgroups => "/path/to/groups", # optional
  );

  # or you can load the user and group files after object creation

  $htauth->htusers("/path/to/users");
  $htauth->htgroups("/path/to/groups"); # optional

  if ($htauth->check(qw/user pass/, groups => ['foo'])) # groups is optional
  {
    ...
  }

=head1 Methods

=over 4

=item B<new>

Creates a Authen::Class::HtAuth object

=item B<htusers>

Where $foo is a class name or an instance of Authen::Class::HtAuth

  $foo->htusers("/path/to/users");

This method loads an Apache style "users" file.

=item B<htgroups>

Where $foo is a class name or an instance of Authen::Class::HtAuth

  $foo->htgroups("/path/to/groups");

This method loads an Apache style "groups" file.

=item B<check>

Where $foo is a class name or an instance of Authen::Class::HtAuth

  $foo->check($username, $password, groups => \@groups);

This method checks $username and $password against the current htusers file,
and optionally checks whether the user is in all the groups specified in the
list of scalars given in named parameter groups.

Alternatively, groups may contain array refs, each with a first element of
either "One" or "All", in which case, ->check determines that, in the case of
"One", the user is in at least one of the groups, and in the case of "All", the
user is in all the groups.  There is no built-in limit to the depth of the
logic.

For example:

  $foo->check($u, $p, groups => [
    [One =>
      [One => qw/admin root/],          # one of these
      [All => qw/foos editor/]          # or all of these
    ],
    [Not => qw/crazy bastard invalid/], # but none of these
  ])                                    # must match

=item B<groupcheck>

Where $foo is a class name or an instance of Authen::Class::HtAuth

  $foo->groupcheck($username, groups => \@groups);

=back

=head1 AUTHOR

Ryan McGuigan, <ryan@cardweb.com>

=head1 BUGS

Please report any bugs or feature requests to <ryan@cardweb.com>

=head1 SEE ALSO

=over 4

=item Apache::Htpasswd

=item Apache::Htgroup

=item Class::Data::Inheritable

=back

=head1 COPYRIGHT & LICENSE

Copyright 2005 Ryan McGuigan, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

