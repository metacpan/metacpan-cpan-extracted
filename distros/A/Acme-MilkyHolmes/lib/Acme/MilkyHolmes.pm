package Acme::MilkyHolmes;
use 5.008005;
use strict;
use warnings;
use parent qw(Exporter);

our $VERSION = "0.07";

use Acme::MilkyHolmes::Character::SherlockShellingford;
use Acme::MilkyHolmes::Character::NeroYuzurizaki;
use Acme::MilkyHolmes::Character::HerculeBarton;
use Acme::MilkyHolmes::Character::CordeliaGlauca;
use Acme::MilkyHolmes::Character::KazumiTokiwa;
use Acme::MilkyHolmes::Character::AliceMyojingawa;
use Readonly;

Readonly our $MilkyHolmesFeathers => [
    'KazumiTokiwa',
    'AliceMyojingawa',
];
Readonly our $MilkyHolmes => [
    'SherlockShellingford',
    'NeroYuzurizaki',
    'HerculeBarton',
    'CordeliaGlauca',
];
Readonly our $MilkyHolmesSisters  => [
    @{ $MilkyHolmes },
    @{ $MilkyHolmesFeathers },
];

our @EXPORT_OK = qw($MilkyHolmes $MilkyHolmesFeathers $MilkyHolmesSisters);


sub members {
    my ($class, %options) = @_;
    return $class->members_of($MilkyHolmes, %options);
}

sub members_of {
    my ($class, $team, %options) = @_;

    my @members = ();
    for my $member_name ( @{ $team }  ) {
        my $pkg = "Acme::MilkyHolmes::Character::$member_name";
        my $member = $pkg->new();
        $member->locale($options{locale}) if ( exists $options{locale} );
        push @members, $member;
    }
    return @members;
}


1;
__END__

=encoding utf-8

=for stopwords ja

=head1 NAME

Acme::MilkyHolmes - There's more than one way to do it!(SEIKAI HA HITOTSU! JANAI!!)

=head1 SYNOPSIS

    use strict;
    use warnings;
    use utf8;
    use Acme::MilkyHolmes;

    # fetch members of Milky Holmes(eg/say.pl)
    my ($sherlock, $nero, $elly, $cordelia) = Acme::MilkyHolmes->members();
    $sherlock->say('ってなんでですかー');
    $nero->say('僕のうまうま棒〜');
    $elly->say('恥ずかしい...');
    $cordelia->say('私の...お花畑...');

    # create character instance directly
    my $sherlock = Acme::MilkyHolmes::Character::SherlockShellingford->new();
    $sherlock->locale('en');
    $sherlock->name;               # => 'Sherlock Shellingford'
    $sherlock->firstname;          # => 'Sherlock'
    $sherlock->familyname;         # => 'Shellingford'
    $sherlock->nickname;           # => 'Sheryl'
    $sherlock->birthday;           # => 'March 31'
    $sherlock->voiced_by;          # => 'Suzuko Mimori'
    $sherlock->nickname_voiced_by; # => 'mimorin'
    $sherlock->toys;               # => 'Psychokinesis'
    $sherlock->color;              # => 'pink'

    # fetch each team members
    use Acme::MilkyHolmes qw($MilkyHolmes $MilkyHolmesFeathers $MilkyHolmesSisters);
    my ($sherlock, $nero, $elly, $cordelia) = Acme::MilkyHolmes->members_of($MilkyHolmes); # same as members()
    my ($kazumi, $alice) = Acme::MilkyHolmes->members_of($MilkyHolmesFeathers);
    my ($sherlock, $nero, $elly, $cordelia, $kazumi, $alice) = Acme::MilkyHolmes->members_of($MilkyHolmesSisters);

=head1 DESCRIPTION

Milky Holmes is one of the most famous Japanese TV animation. Acme::MilkyHolmes provides character information of Milky Holmes.

=head1 METHODS

=head2 C<members(%options)>

options: C<$options{locale} = ja,en> default is ja

    my @members = Acme::MilkyHolmes->members(locale => en);

fetch Milky Holmes members. See SYNOPSIS.

=head2 C<members_of($member_name_const, %options)>

options: C<$options{locale} = ja,en> default is ja

fetch members specified in C<$member_name_const>. See SYNOPSIS and EXPORTED CONSTANTS


=head1 EXPORTED CONSTANTS

=over 4

=item * C<$MilkyHolmes> : members of Milky Holmes (Sherlock, Nero, Elly and Cordelia).

=item * C<$MilkyHolmesFeathers> : members of Milky Holmes Feathers (Kazumi and Alice).

=item * C<$MilkyHolmesSisters> : members of Milky Holmes Sisters (Sherlock, Nero, Elly, Cordelia, Kazumi and Alice)

=back

=head1 SEE ALSO

=over 4

=item * Milky Holmes Official Site

L<http://milky-holmes.com/>

=item * Project Milky Holmes (Wikipedia - ja)

L<http://ja.wikipedia.org/wiki/%E3%83%9F%E3%83%AB%E3%82%AD%E3%82%A3%E3%83%9B%E3%83%BC%E3%83%A0%E3%82%BA>

=item * Milky Holmes (Wikipedia - en)

L<http://en.wikipedia.org/wiki/Tantei_Opera_Milky_Holmes>

=back

=head1 LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi@cpan.orgE<gt>

=cut

