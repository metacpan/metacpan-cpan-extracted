# This object is used to access the different sections of 
# classgens control-file.
#
# Michael Schlueter				15.2.2000


# 3.03:
#	The failure, which caused duplicated #-lines in the header
#	section, has been corrected.			08.12.2000


# 3.02:
#	No changes in here				06.07.2000


package Class::Classgen::Section;

$VERSION=3.03;

	use Class::Classgen::Comments;	# to remove problems by typing errors

	use strict;
	
sub new {				# constructor
	my ($self, $id) = @_;
	my $type = ref($self)||$self;

	# instance-variables
	my $_identifier;
	my @_list;
	
	$self=bless {
		_id	=> $_identifier,
		_list	=> \@_list, @_list,
	}, $type;
	
	$self->set_id($id);
	return $self;
}

sub add {
	my ($self, $x) = @_;
	my $rl = $self->{_list};
#	$x =~ s/\s//g	unless( $self->get_id() =~ m/head/ );
#	push @$rl, $x	if( length($x) > 0 );

	my $a;
	if( $x=~m/ISA/ ) {
		$a=$x;
	} else {
		$a = Class::Classgen::Comments::just_var($x);
	}
	my $b = Class::Classgen::Comments::just_comments($x);
	$a =~ s/\s//g	unless( $self->get_id() =~ m/head/ );
	
	if($self->get_id()=~'head') {
		push @$rl, $a		if( length($a) > 0 );
	} else {
		push @$rl, $a.$b	if( length($a.$b) > 0 );
	}
}

sub get_id {			# access Sections instance variable
	my ($self) = @_;
	$self->{_id};
}

sub get_variables {		# access the list of required instance variables
	my ($self) = @_;
	my $rl = $self->{_list};
	my @list = @$rl;
}

sub set_id {			# manipulate Sections instance variable
	my ($self, $id) = @_;
	$self->{_id} = $id;
}

sub write_header {
	my ($self) = @_;
	
	# case 'header:'
	# this is the only case allowed to write the class-begining
		
	if( $self->get_id() =~ m/header/ ) {
		my @list = $self->get_variables();
		return Class::Classgen::Comments::repair_header(@list);
		# return @list;
	}
}


1;


__END__


=head1 NAME

Section.pm - Identifies the diffferent sections from classgens control file.

=head1 VERSION

3.03

=head1 SYNOPSIS

Used within classgen.

=head1 DESCRIPTION

Section.pm is needed to administer the information found in the control file of classgen for later use.


=head1 ENVIRONMENT

Nothing special. Just use Perl5.


=head1 DIAGNOSTICS

There is no special diagnostics. Section.pm is used within classgen which is called with the B<-w> option.


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
