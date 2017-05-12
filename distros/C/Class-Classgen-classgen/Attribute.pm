# This object is used to generate the required methods for
# instance variables found in classgens control-file.
#
# Michael Schlueter				15.2.2000	3.00



# 3.03:
#	No changes in here				02.10.2000


# 3.02:
#	No changes in here				06.07.2000

# 3.01:
#	introduced get_h_.._at($key) for direct access of internal hash
#	19.5.2000
#	introduced delet_h_.._at($key) to delete one specific hash element
#	27.5.2000



package Class::Classgen::Attribute;

$VERSION=3.03;

	use strict;
	use Class::Classgen::Comments;
	
sub new {				# constructor
	my ($self, $var) = @_;
	my $type = ref($self)||$self;

	# class-attributes
	my $_var;
	
	$self=bless {
		_var	=> $_var
	}, $type;
	
	$self->set_var($var);
	return $self;
}

sub get_type {				# to determine type of instance variable
	my ($self) = @_;
	my $var = $self->get_var();
	$var =~ m/(.)/;			# retrieve the first character ($%@)
	return $1;
}

sub get_var {				# access instance-variable
	my ($self) = @_;
	$self->{_var};
}

sub generate_blessed_h {		# for blessing an anonymous hash
	my ($self) = @_;
	my $s;
	my $var = Class::Classgen::Comments::just_var($self->get_var());

	$s.= "\t\t".$self->generate_key()."\t\t=>";
	if($self->get_type() eq '$') {
	#	$s.= "\t".$self->get_var().",\n";
		$s.= "\t".$var.",\n";
	} else {		
		$s.= "\t\\" . $var. ", ".$var.",\n";
	}
}

sub generate_key {		# used to define appropriate method names
	my ($self) = @_;
	my $key = $self->simplify_var();
	
	# it is necessary to create different keys for e.g. $r, %r and @r
	my $id = '';
	$id = "h_" if( $self->get_type() eq '%' );
	$id = "l_" if( $self->get_type() eq '@' );
	
	$key = "_" . $id . $key;
	return $key;
}

sub name {				# generate a standard name
	my ($self, $method) = @_;
	return $method . "_" . $self->simplify_var();
}

sub simplify_var {			# to remove '^[\$%@]_+'
	my ($self) = @_;
	my $var = Class::Classgen::Comments::just_var($self->get_var());
	$var =~ s/^[\$%@]_*//;
	return $var;
}

sub set_var {				# manipulate instance-variable
	my ($self, $var) = @_;
	$self->{_var} = $var;
}

sub write_clear {			# generate clear() method for $scalars
	my ($self) = @_;
	my $s = '';
	
	if( $self->get_type() eq '$') {
		$s.= "sub ". $self->name('clear') . " {\n";	
		$s.= "\tmy (\$self) = \@_;\n";
		$s.= "\tmy \$v = \$self->" . $self->name('set') . "(undef);\n";
		$s.= "\n}\n\n";
	}
	
	return $s;
}

sub write_clear_h {			# generate clear() method for %hashes
	my ($self) = @_;
	my $s = '';
	
	if( $self->get_type() eq '%') {
		$s.= "sub ". $self->name('clear_h') . " {\n";	
		$s.= "\tmy (\$self) = \@_;\n";
		$s.= "\tmy \$rh = \$self->" . $self->name('get_rh') . "();\n";
		$s.= "\tundef \%\$rh;\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_clear_l {			# generate clear() method for @lists
	my ($self) = @_;
	my $s = '';
	
	if( $self->get_type() eq '@') {
		$s.= "sub ". $self->name('clear_l') . " {\n";	
		$s.= "\tmy (\$self) = \@_;\n";
		$s.= "\tmy \$rl = \$self->" . $self->name('get_rl') . "();\n";
		$s.= "\tundef \@\$rl;\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_delete_h_at {			# delete a specific element from %hash
	my ($self) = @_;
	my $s = '';

	if( $self->get_type() eq '%') {
		$s.= "sub ". $self->name('delete_h') . "_at {\n";	
		$s.= "\tmy (\$self, \$key) = \@_;\n";
		$s.= "\tmy \$rh = \$self->" . $self->name('get_rh') . "();\n";
		$s.= "\tdelete \$\$rh\{\$key\};\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_get {				# generate accessor method for $scalars
	my ($self) = @_;
	my $s = '';
	
	if( $self->get_type() eq '$') {
		$s.= "sub ". $self->name('get') . " {\n";	
		$s.= "\tmy (\$self) = \@_;\n";
		$s.= "\t\$self->{" . $self->generate_key() . "};\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_get_at {			# generate indexed-accessor for @lists
	my ($self) = @_;
	my $s = '';
	
	if( $self->get_type() eq '@') {
		$s.= "sub ". $self->name('get') . "_at {\n";	
		$s.= "\tmy (\$self, \$index) = \@_;\n";
		$s.= "\tmy \$rl = \$self->" . $self->name('get_rl') . "();\n";
		$s.= "\treturn \$\$rl\[\$index\];\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_get_h {			# generate accessor for %hashes
	my ($self) = @_;
	my $s = '';

	if( $self->get_type() eq '%') {
		$s.= "sub ". $self->name('get_h') . " {\n";	
		$s.= "\tmy (\$self) = \@_;\n";
		$s.= "\tmy \$rh = \$self->" . $self->name('get_rh') . "();\n";
		$s.= "\treturn \%\$rh;\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_get_h_at {			# generate accessor for %hashes
	my ($self) = @_;
	my $s = '';

	if( $self->get_type() eq '%') {
		$s.= "sub ". $self->name('get_h') . "_at {\n";	
		$s.= "\tmy (\$self, \$key) = \@_;\n";
		$s.= "\tmy \$rh = \$self->" . $self->name('get_rh') . "();\n";
		$s.= "\treturn \$\$rh\{\$key\};\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_get_keys_h {			# generate key-accessor for %hashes
	my ($self) = @_;
	my $s = '';

	if( $self->get_type() eq '%') {
		$s.= "sub ". $self->name('get_keys_h') . " {\n";	
		$s.= "\tmy (\$self) = \@_;\n";
		$s.= "\tmy \%h = \$self->" . $self->name('get_h') . "();\n";
		$s.= "\treturn keys \%h;\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_get_l {			# generate list-accessor for @lists
	my ($self) = @_;
	my $s = '';

	if( $self->get_type() eq '@') {
		$s.= "sub ". $self->name('get_l') . " {\n";	
		$s.= "\tmy (\$self) = \@_;\n";
		$s.= "\tmy \$rl = \$self->" . $self->name('get_rl') . "();\n";
		$s.= "\treturn \@\$rl;\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_get_rh {			# generate accessor to \%hashes
	my ($self) = @_;
	my $s = '';

	if( $self->get_type() eq '%') {
		$s.= "sub ". $self->name('get_rh') . " {\n";	
		$s.= "\tmy (\$self) = \@_;\n";
		$s.= "\tmy \$rh = \$self->{" . $self->generate_key() . "};\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_get_rl {			# generate accessor to \@lists
	my ($self) = @_;
	my $s = '';

	if( $self->get_type() eq '@') {
		$s.= "sub ". $self->name('get_rl') . " {\n";	
		$s.= "\tmy (\$self) = \@_;\n";
		$s.= "\tmy \$rl = \$self->{" . $self->generate_key() . "};\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_pop {				# generate pop-accessor for @lists
	my ($self) = @_;
	my $s = '';

	if( $self->get_type() eq '@') {
		$s.= "sub ". $self->name('pop') . " {\n";	
		$s.= "\tmy (\$self) = \@_;\n";
		$s.= "\tmy \$rl = \$self->" . $self->name('get_rl') . "();\n";
		$s.= "\treturn pop \@\$rl;\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_push {			# generate push-manipulator for @lists
	my ($self) = @_;
	my $s = '';

	if( $self->get_type() eq '@') {
		$s.= "sub ". $self->name('push') . " {\n";	
		$s.= "\tmy (\$self, \$value) = \@_;\n";
		$s.= "\tmy \$rl = \$self->" . $self->name('get_rl') . "();\n";
		$s.= "\tpush \@\$rl, \$value;\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_set {				# generate manipulator for $scalars
	my ($self) = @_;
	my $s = '';
	
	if( $self->get_type() eq '$') {
		$s.= "sub ". $self->name('set') . " {\n";	
		$s.= "\tmy (\$self, \$value) = \@_;\n";
		$s.= "\t\$self->{" . $self->generate_key() . "} = ";
		$s.= "\$value;\n";
		$s.= "}\n\n";
	}
	
	return $s;
}

sub write_set_h {			# generate manipulator for %hashes
	my ($self) = @_;
	my $s = '';
		
	if( $self->get_type() eq '%') {
		$s.= "sub ". $self->name('set_h') . " {\n";	
		$s.= "\tmy (\$self, \$key, \$value) = \@_;\n";
		$s.= "\tmy \$rh = \$self->"  . $self->name('get_rh') . "();\n";
		$s.= "\t\$\$rh{\$key} = \$value;\n";
		$s.= "}\n\n";
	}
	
	return $s;
}


sub write_set_l {			# generate manipulator for @lists
	my ($self) = @_;
	my $s = '';
	
	if( $self->get_type() eq '@') {
		$s.= "sub ". $self->name('set_l') . " {\n";	
		$s.= "\tmy (\$self, \$index, \$value) = \@_;\n";
		$s.= "\tmy \$rl = \$self->"  . $self->name('get_rl') . "();\n";
		$s.= "\t\$\$rl\[\$index\] = \$value;\n";
		$s.= "}\n\n";
	}
	
	return $s;
}


1;

__END__


=head1 NAME

Attribute.pm - generates all get- and set-methods for new classes created by classgen.

=head1 VERSION

3.03

=head1 SYNOPSIS

Within classgen called as:

	use Attribute;			# work with object Attribute
	my $attr = Attribute->new();	# derive a new Attribute instance $attr


Let Ex.pm be a generated class, with internal variables $var, %entry and @list:

	use Ex.pm;			# use generated class
	my $ex=Ex->new();		# creating a new object
	$ex->set_var('this is a test');	# setting instance variable $var
	$ex->set_h_entry( 12, twelve );	# like $entry{12}='twelve'
	$ex->set_h_entry( 60, sixty );	# 
	$ex->set_l_list( 3, -100 );	# like $list[3]=-100;
	$x=$ex->get_var();		# like $x=$var;
	$x=$ex->get_h_entry(12);
	@keys=$ex->get_keys_h_entry();	# get all keys of internal %entry
etc.

=head1 DESCRIPTION

It is good OOP-style to access and manipulate instance variables of a class NEVER by a direct call, but via appropriate methods. You should always follow this concept to avoid problems when inheriting from your object oriented code.

classgen has been designed for exactly this purpose: To have all necessary methods available for all instance variables. Right from the start.


=head2 General syntax for generated methods

The methods name itself should uniquely identify the type of instance variable accessed or modified. So the general method convention is:

=over 4

=item *
methodname_scalarname to work on a scalar instance

=item *
methodname_h_hashname to work on a hash instance

=item *
methodname_l_listname to work on a list instance

=back

With this convention you will always know what to expect, e.g.:

	use Example;
	$ex = Example->new();
	...
	print $ex->get_number;		# access instance variable $number
	print $ex->get_l_cities;	# access instance variable @cities
	print $ex->get_keys_h_country;	# get keys of inst.var. %country


For %hashes and @lists it is sometimes necessary to access the reference of the instance variable. Then use:

=over 4

=item *
methodname_rh_hashname to find the reference of a %hash instance 

=item *
methodname_rl_listname to find the reference of a @list instance 

=back

Some other methods deviate from these rules when purpose and involved type of instance variable are self evident. See below.


=head2 Generated methods for $scalars 

For all $scalar instance variables in classgens control file Attribute.pm generates (the phrase 'scalar' is replaced by the actual name of the $scalar instance variable):

=over 4

=item *
clear_scalar(): generated clear() method for $scalars

=item *
get_scalar(): generated accessor method for $scalars

=item *
set_scalar($value): generated manipulator for $scalars

=back

=head2 Example: control file contains $var of class Example.

Attribute generates clear_var(), get_var() and set_var. Class Example can be used like:

	use Example;	# use object Example
	use strict;	# recommended

	my $ex = Example->new();	# creating a new Example instance
	$ex->clear_var();		# set $var in Example to undef
	$ex->set_var( "what a wonderful day" );

	print $ex->get_var();



=head2 Generated methods for %hashes 

For all %hash instance variables in classgens control file Attribute.pm generates (the phrase 'hash' is replaced by the actual name of the %hash instance variable):

=over 4

=item *
clear_h_hash(): generated clear() method for %hashes

=item *
delete_h_hash_at($key): deletes $key from internal %hash.

=item *
get_h_hash(): generated accessor to the %hash itself

=item *
get_h_hash_at($key): generated key-based accessor to %hash

=item *
get_keys_h_hash(): generated key-accessor for %hashes

=item *
get_rh_hash(): generated accessor to \%hashes

=item *
set_h_hash($key, $value): generated manipulator for %hashes

=back

=head2 Generated methods for @lists 

For all @list instance variables in classgens control file Attribute.pm generates (the phrase 'list' is replaced by the actual name of the @list instance variable):

=over 4

=item *
clear_l_list(): generated clear() method for @lists

=item *
get_list_at($index): generated indexed-accessor for @lists

=item *
get_l_list(): generated list-accessor for @lists

=item *
get_rl_list(): generated accessor to \@lists

=item *
pop_list(): generated pop-accessor for @lists

=item *
push_list($value): generated push-manipulator for @lists

=item *
set_l_list($index, $value): generated manipulator method for @lists

=back


=head2 Internal methods

A few methods are needed to provide all this:

=item *
sub new: constructor

=item *
sub get_type: to determine type of instance variable

=item *
sub get_var: access instance-variable

=item *
sub generate_blessed_h: for blessing an anonymous hash

=item *
sub generate_key: used to define appropriate method names

=item *
sub name: generate a standard name

=item *
sub simplify_var: to remove '^[\$%@]_+'

=item *
sub set_var: manipulate instance-variable

=head1 ENVIRONMENT

Nothing special. Just use Perl5.


=head1 DIAGNOSTICS

There is no special diagnostics. Attribute.pm is used within classgen which is called with the B<-w> option.


=head1 BUGS

No bugs known.

=head1 FILES

Please refer to classgen.


=head1 SEE ALSO

perldoc classgen




=head1 AUTHOR

Name:  Michael Schlueter
email: mschlue@cpan.org

=head1 COPYRIGHT

Copyright (c) 2000, Michael Schlueter. All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
