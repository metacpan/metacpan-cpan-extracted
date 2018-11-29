package Acme::DarmstadtPM::TieHash;

# ABSTRACT: a module that shows that Perl can do all the Ruby things ;-)

use strict;
use warnings;

our $VERSION = '0.5';
our $SEP     = '__Acme::DarmstadtPM::TieHash::KeySeparator__';

sub TIEHASH {
    my ($class,$code) = @_;
    
    
    my $self = {};
    bless $self,$class;
    
    $self->{HASH} = {};
    $self->{CODE} = $code;
    
    return $self;
}

sub FETCH {
    my ($self,$key) = @_;

    return if !ref $key;
    
    my $internal_key = join $SEP, @{ $key || [] };
    if ( !exists $self->{HASH}->{$internal_key} ) {
        $self->{HASH}->{$internal_key} = $self->{CODE}->(@$key);
    }
    
    $self->{HASH}->{$internal_key};
}

sub STORE {
    my ($self,$key,$value) = @_;
    
    my $internal_key = join $SEP, @{ $key || [] };
    $self->{HASH}->{$internal_key} = $value;
}

sub DELETE {
    my ($self,$key) = @_;

    my $internal_key = join $SEP, @{ $key || [] };
    my $value = delete $self->{HASH}->{$internal_key};

    return $value;
}

sub EXISTS {
    my ($self,$key) = @_;

    my $internal_key = join $SEP, @{ $key || [] };
    exists $self->{HASH}->{$internal_key};
}

sub CLEAR {
    my ($self) = @_;

    $self->{HASH} = {};
}

sub FIRSTKEY {
	my ($self) = @_;

	my $a = keys %{ $self->{HASH} };
	my $key = scalar each %{ $self->{HASH} };

    return if !defined $key;
    return [ split /$SEP/, $key ];
}

sub NEXTKEY {
	my ($self,$last_key) = @_;

	my $key = scalar each %{ $self->{HASH} };

    return if !defined $key;
    return [ split /$SEP/, $key ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::DarmstadtPM::TieHash - a module that shows that Perl can do all the Ruby things ;-)

=head1 VERSION

version 0.5

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

=for Pod::Coverage TIEHASH FETCH STORE EXISTS NEXTKEY FIRSTKEY CLEAR DELETE

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
