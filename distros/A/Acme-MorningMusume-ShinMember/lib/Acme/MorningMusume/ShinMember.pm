package Acme::MorningMusume::ShinMember;

use warnings;
use strict;
use Acme::MorningMusume;
use Acme::BloodType;
use utf8;
use base 'Acme::MorningMusume::Base';

=head1 NAME

Acme::MorningMusume::ShinMember - Create random Morning Musume!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Creates a random morning musume member that's "based on" two random
parent members:

    use Acme::MorningMusume::ShinMember;

    my $member = Acme::MorningMusume::ShinMember->new;
    print "I created ". $member->name_en. "!\n";
    # etc..

The C<$member> can then be used like any C<Acme::MorningMusume::Base>
object.  See C<bin/genmusume> for an example.

=head1 FUNCTIONS

=head2 info

Called by Acme::MorningMusume::Base::new to make the Musume.

=cut

sub info {    
    my $musume = Acme::MorningMusume->new;
    my @musume = $musume->select('age', 0, '<'); # all of 'em!
    my ($mom, $dad) = @musume[rand(@musume), rand(@musume)];
    
    my %attributes;
    $attributes{first_name_en} = $mom->first_name_en;
    $attributes{first_name_ja} = $mom->first_name_ja;
    utf8::decode($attributes{first_name_ja});
    $attributes{family_name_en}  = $dad->family_name_en;
    $attributes{family_name_ja}  = $dad->family_name_ja;
    utf8::decode($attributes{family_name_ja});
    $attributes{nick} = [substr($attributes{first_name_ja}, 0, 1).'っちゃん'];
    $attributes{birthday} = $mom->birthday - rand($mom->birthday - 
						  $dad->birthday);
    $attributes{blood_type} = Acme::BloodType->new(
				     {phenotype => $mom->blood_type} 
						  )->cross(
			      Acme::BloodType->new(
				     {phenotype => $dad->blood_type}))
			       ->get_bloodtype;
    
    $attributes{hometown} = (rand 1 < 0.5 ? $mom : $dad)->hometown;
    utf8::decode($attributes{hometown});

    $attributes{graduate_date} = undef;
    $attributes{class} = int ($mom->class - rand($mom->class - $dad->class));
    $attributes{emoticon} = [(@{$dad->emoticon||()}, 
			       @{$mom->emoticon||()})[0..rand 2]];
    utf8::decode($_) for @{$attributes{emoticon}};
    return %attributes;
}

=head1 AUTHOR

Jonathan Rockway, C<< <jrockway at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-morningmusume-shinmember at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-MorningMusume-ShinMember>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

Want the real Mornon

=head1 ACKNOWLEDGEMENTS

C<#perl>.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jonathan Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::MorningMusume::ShinMember
