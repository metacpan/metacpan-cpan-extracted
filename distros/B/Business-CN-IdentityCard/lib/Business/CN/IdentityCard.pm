package Business::CN::IdentityCard;

use strict;
use vars qw($VERSION);
$VERSION = '0.05';
use base 'Class::Accessor::Fast';
use Date::Simple; # for validate_birthday

__PACKAGE__->mk_accessors(qw/err errstr province birthday/);

sub new {
	my ($proto, $id) = @_; # $id = the IdentityCard string
	my $class = ref($proto) || $proto;
	my $self = bless { }, $class;

	$self->_parse($id) if ($id);

	return $self;
}

sub _parse {
	my $self = shift;
	my $id = lc shift;
	
	unless ($id =~ /^(\d{17}(\d|x)|\d{15})$/) {
		$self->err('LENGTH');
		$self->errstr("Must be 15 or 18 length number!");
		return 0;
	}
	
	$self->{id} = $id;

	# parse
	( $self->{benti},
	  $self->{province_code}, $self->{district_code},
	  $self->{birthday}, $self->{serial_number},
	  $self->{postfix} )

	= ( length($id) == 18 )
			? ( $id =~ /((\d{2})(\d{4})(\d{8})(\d{3}))(\w)/ )
			: ( $id =~ /((\d{2})(\d{4})(\d{6})(\d{3}))/ );
	return 1;
}

sub validate {
	my ($self, $id) = @_;

	# we support new($id)+validate and new()+validate($id)
	unless($id) { $id = $self->{id}; }
	$self->_parse($id);

	$self->validate_province() and
	$self->validate_birthday() and
	$self->validate_postfix();
	
	return 0 if ($self->err);
	return 1;
}

sub validate_province {
	my $self = shift;

	my @province = ('','','','','','','','','','','','北京','天津','河北','山西','内蒙古','','','','','','辽宁','吉林','黑龙江','','','','','','','','上海','江苏','浙江','安微','福建','江西','山东','','','','河南','湖北','湖南','广东','广西','海南','','','','重庆','四川','贵州','云南','西藏','','','','','','','陕西','甘肃','青海','宁夏','新疆','','','','','','台湾','','','','','','','','','','香港','澳门','','','','','','','','','国外');
	my $province = substr($self->{id}, 0, 2);
	if (! $province[$self->{province_code}]) {
		$self->err('PROVINCE');
		$self->errstr('Province is faked');
		return 0;
	} else {
		$self->province($province[$self->{province_code}]);
		return 1;
	}
}

sub validate_birthday {
	my $self = shift;

	my ($year,$month,$day) = ( $self->birthday =~ /(\d{2,4})(\d{2})(\d{2})$/ );
	$year = ( length $year == 4 ) ? $year : '19'.$year;
	my $birthday = "$year-$month-$day";
	
	my $date  = Date::Simple->new($birthday);

	if ($date) {
		$self->birthday($birthday);
		return 1;
	} else {
		$self->err('BIRTHDAY');
		$self->errstr(sprintf("birthday: %s is invalid!", $self->birthday));
		return 0;
	}
}

sub validate_postfix {
	my $self = shift;
	return 1 if (length($self->{id}) == 15);

	my @gene = (7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2);
	my @v_code = ('1','0','x','9','8','7','6','5','4','3','2');
	my @id = split(//, $self->{benti});
	
	my $sum;
	map { $sum += $id[$_] * $gene[$_] } (0..16);

	if ($self->{postfix} ne $v_code[ $sum % 11 ]) {
		$self->err('POSTFIX');
		$self->errstr('postfix is invalid!');
		return 0;
	}
	return 1;
}

sub gender {
	my ($self, $format) = @_;
	$format = 'CN' unless ($format);
	if ($self->{serial_number} % 2 == 0 ) {
		return ($format eq 'CN') ? '女' : 'Female';
	} else {
		return ($format eq 'CN') ? '男' : 'Male';
	}
}

sub district {
	my $self = shift;
	eval('require Business::CN::IdentityCard::District;');
	my $key = $self->{province_code} . $self->{district_code};
	if (exists $Business::CN::IdentityCard::District::district{$key}) {
		return $Business::CN::IdentityCard::District::district{$key};
	} else {
		$self->err('DISTRICT');
		$self->errstr(sprintf("district code: %s is invalid or unkown district!", $key ));
		return undef;
	}
}	

1;
__END__

=head1 NAME

Business::CN::IdentityCard -  Validate the Identity Card NO. in China

=head1 SYNOPSIS

  use Business::CN::IdentityCard;
  my $id = '11010519491231002X'; # a unsure identity card no.
  my $idv = new Business::CN::IdentityCard;
  if ($idv->validate($id)) { # call the validate_id method
    print 'Pass';
    print $idv->gender; # the gender of the id, default is *Chinese*
    print $idv->gender('EN'); # the English gender: Male|Female
    print $idv->birthday; # the birthday of the id, eg: 1975-10-31
    print $idv->province; # the province of the id, in Chinese
    print $idv->district; # the district of the id, *NOT* suggested
  } else {
  	print $idv->err; # the type of error, details see below
    print $idv->errstr; # the error detail
  }

=head1 DESCRIPTION

It validates the given Identity Card NO., and give some info(including gender, birthday, province and district) of the id.

There is a Chinese document @ L<http://www.fayland.org/IDCard/Validate.html>. It explain the algorithm of how-to validate the Identity Card no.

=head1 METHOD

=over 4

=item new

you can declare the object with the id, such as

 my $idv = new Business::CN::IdentityCard($id);
 $idv->validate;

=item validate

if the id is provided by new, u can ignore the parameter, otherwise the parameter is needed. if the ID is correct, return 1, otherwise return 0 and u can get the error details. see below.

=item gender

return the gender of the id owner. default return the Chinese gender, use gender('EN') to get the Female or Male.

=item birthday

return the birthday of the id owner. the format is like YYYY-MM-DD

=item province

return the province of the id owner. It's Chinese.

=item district

B<NOT> suggested. because it's not perfect and takes memory. of course, use it if needed.

=item err

return the type of the error.

=over 4

=item B<LENGTH>

if the length of the id is not 15 or 18.

=item B<BIRTHDAY>

if the birthday is not a normal date.

=item B<PROVINCE>

no such province code. :)

=item B<DISTRICT>

what district? I haven't heard that before.

=item B<POSTFIX>

the last digit is definitely faked.

=back

=item errstr

the detail of the error

=back

=head1 CREDIT

Adam Kennedy - who advises me to change 'China::IdentityCard::Validate' to this.

chunzi - provide the basic of the enhanced version && district detail

joe - fix a regex bug

=head1 BUGS

feel free to report any bugs or corrections.

=head1 AUTHOR

Fayland <fayland@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2005 Fayland All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut