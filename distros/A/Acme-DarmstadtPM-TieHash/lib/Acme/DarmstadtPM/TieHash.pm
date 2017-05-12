package Acme::DarmstadtPM::TieHash;

# ABSTRACT: a module that shows that Perl can do all the Ruby things ;-)

use strict;
use warnings;

use Tie::ListKeyedHash;

our $VERSION = '0.4';

sub TIEHASH{
    my ($class,$code) = @_;
    
    
    my $self = {};
    my %hash;
    bless $self,$class;
    
    tie %hash,'Tie::ListKeyedHash';
    $self->{HASH} = \%hash;
    $self->{CODE} = $code;
    
    return $self;
}

sub FETCH{
    my ($self,$key) = @_;
    
    if (not ref $key) {
        $key = [split(/$;/,$key)];
    }
    
    unless(exists $self->{HASH}->{$key}){
        $self->{HASH}->{$key} = $self->{CODE}->(@$key);
    }
    
    return $self->{HASH}->{$key};
}

sub STORE{
    my ($self,$key,$value) = @_;
    
    if (not ref $key) {
        $key = [split(/$;/,$key)];
    }
    
    $self->{HASH}->{$key} = $value;
}

sub DELETE{
    my ($self,$key) = @_;

    if (not ref $key) {
        $key = [split(/$;/,$key)];
    }
    
    delete $self->{HASH}->{$key};
}

sub EXISTS{
    my ($self,$key) = @_;

    if (not ref $key) {
        $key = [split(/$;/,$key)];
    }

    return exists $self->{HASH}->{$key} ? 1 : 0;
}

sub CLEAR{
    my ($self) = @_;
    $self->{HASH} = ();
}

sub FIRSTKEY{
	my ($self) = @_;
	
	my $a = keys %{$self->{HASH}}; 
	my $key = scalar each %{$self->{HASH}};
	return if (not defined $key);
	return [$key];
}

sub NEXTKEY {
	my ($self,$last_key) = @_;
	my $key = scalar each %{$self->{HASH}};
	return if (not defined $key);
	return [$key];
}

1;

__END__

=pod

=head1 NAME

Acme::DarmstadtPM::TieHash - a module that shows that Perl can do all the Ruby things ;-)

=head1 VERSION

version 0.4

=head1 SYNOPSIS

  #!/usr/bin/perl
   
  use strict;
  use warnings;
  use Test::More tests => 2;
  
  use constant ADT => 'Acme::DarmstadtPM::TieHash';
   
  use_ok(ADT);
   
  tie my %hash,ADT,sub{$_[0] + $_[-1]};
  
  is($hash{[1,5]},6,'Check [1,5]');
   
  untie %hash;

=head1 DESCRIPTION

Ronnie sent a mail to the mailinglist with some good Ruby stuff. I said, that all these
things can be done in Perl, too. So this module is a proof how smart Perl is...

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
