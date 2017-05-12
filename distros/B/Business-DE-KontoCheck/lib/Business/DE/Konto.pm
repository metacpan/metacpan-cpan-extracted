package Business::DE::Konto;
#---------------------------------------------
# $Id: Konto.pm,v 1.12 2002/09/12 21:59:37 tina Exp $
#---------------------------------------------
use strict;
use Data::Dumper;
require Exporter;
use base qw(Exporter);
use vars qw(%error_codes @EXPORT_OK %EXPORT_TAGS $VERSION);
$VERSION = '0.02';
@EXPORT_OK = qw(%error_codes);
%EXPORT_TAGS = ( 'errorcodes' => [@EXPORT_OK]);
sub new {
    my ($class, $args) = @_;
	my $self = {};
	my @args = qw(PLZ BLZ INST METHOD ORT KONTONR BIC);
	@$self{@args} = @$args{@args};
	bless ($self, $class);
}

sub get_zip { $_[0]->{PLZ} }
sub get_blz { $_[0]->{BLZ} }
sub get_bankname { $_[0]->{INST} }
sub get_location { $_[0]->{ORT} }
sub get_account_no { $_[0]->{KONTONR} }
sub get_bic { $_[0]->{BIC} }
sub get_method { $_[0]->{METHOD} }

sub _setValue {
	my ($self, %args) = @_;
	while (my ($key,$value) = each %args) {
		$self->{$key} = $value;
	}
}
sub check {
	my ($self) = @_;
	#print "debug 1\n";
	return 1 unless $self->{ERRORS};
	#print "debug 2\n";
	return if $self->{ERRORS}->{ERR_KNR_INVALID} && (keys %{$self->{ERRORS}}) == 1;
	#print "debug 3\n";
	return 0;
}

sub _setErrorCodes {
	my $self = shift;
	my $codes = shift or return;
	%error_codes = %$codes;
}
sub _setError {
	my ($self, $error) = @_;
	$self->{ERRORS}->{$error}++
}
sub printErrors {
	my ($self) = @_;
	my $errors = $self->{ERRORS} || return '';
	#print Dumper $self->{ERRORS};
	my $err_string;
	for my $error (keys %$errors) {
		$err_string .= "Error $error: $error_codes{$error}\n";
		#print "Error $error: $error_codes{$error}\n";
	}
	return $err_string;
}
sub getErrors {
	my ($self) = @_;
	my $errors = $self->{ERRORS} || return '';
	return [keys %$errors];
}
%error_codes = (
	ERR_NO_BLZ      => 'Please supply a BLZ',
	ERR_BLZ         => 'Please supply a BLZ with 8 digits',
	ERR_BLZ_EXIST   => 'BLZ doesn\'t exist',
	ERR_BLZ_FILE    => 'BLZ-File corrupted',
	ERR_NO_KNR      => 'Please supply an account number',
	ERR_KNR         => 'Please supply a valid account number with only digits',
	ERR_KNR_INVALID => 'Account-number is invalid',
	ERR_METHOD      => 'Method not implemented yet',
);
1;

__END__

=pod

=head1 NAME

Business::DE::Konto - German Bank-Account data

=head1 AUTHOR

Tina Mueller

=head1 METHODS

=over 4

=item new

Contructor

=item check

Returns 1 if the account number check was valid or 0. This
method should not be used as not all check methods have
been implemented.

=item get_zip

Returns zipcode of the bank

=item get_blz

Returns blz of the bank.

=item get_bankname

Returns name of the bank institute

=item get_location

Reutrns Location (City, ...) of the bank.

=item get_account_no

Returns account number.

=item get_method

Returns the checkmethod for this bank.

=item get_bic

Returns BIC (Bank Identifier Code) of the bank.

=item getErrors

Returns error codes.

=item printErrors

Returns human readable error messages.


=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Tina Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
