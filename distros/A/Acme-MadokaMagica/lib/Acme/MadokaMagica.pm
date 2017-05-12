package Acme::MadokaMagica;
use 5.008001;
use strict;
use warnings;
use utf8;
use parent 'Exporter';

our $VERSION = "0.07";
our $miracle = "奇跡";
our $magical = "魔法";

our @EXPORT = qw[ $miracle $magical];

use Readonly;

Readonly our $KyoSaya => [
    "SakuraKyoko",
    "MikiSayaka",
];

Readonly our $MadoHomu => [
    "KanameMadoka",
    "AkemiHomura",
];

Readonly our $Alone => [
    "TomoeMami",
];

Readonly our $HollyQuintet => [
    @$MadoHomu,
    @$Alone,
    @$KyoSaya,
];

Readonly our $AloneMembers => [
    @$Alone,
];

Readonly our $MainMembers => [
    @$HollyQuintet,
];

sub alone_members {
    my $self = shift;
    return $self->members_of($AloneMembers, (caller)[2]);
}

sub main_members {
    my $self = shift;
    return $self->members_of($MainMembers, (caller)[2]);
}

sub members_of {
    my ($self, $team, $line) = @_;
    my @members;

    for my $member_name (@{ $team }){
        my $pkg = "Acme::MadokaMagica::TvMembers::$member_name";
        if (eval "require $pkg;1;"){
#            push @members,$pkg->new($line);
            push @members,$pkg->new({"line" => $line});
        }
    }

    return @members;
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::MadokaMagica - It's miracles and magic are real module.

=head1 SYNOPSIS

  use Acme::MadokaMagica;

    my($madoka,$homura,$mami,$kyouko,$sayaka) = Acme::MadokaMagica->main_members;

    print $madoka->name;         # '鹿目 まどか';
    print $madoka->firstname;    # 'まどか';
    print $madoka->lastname;     # '鹿目';
    print $madoka->age;          #  14;
    print  $madoka->birthday;    #  '10/3';
    print  $madoka->blood_type;  #  'A';
    print  $madoka->cv;          # '悠木碧';
    print  $madoka->say;         #   'ウェヒヒww';
    print  $madoka->color;       #   'Pink';
    print  $madoka->qb;
    print  $madoka->name;        # 'Kriemhild_Gretchen';
    print  $madoka->color;       #   'black';

    my ($mami) = Acme::MadokaMagica->alone_members;
    print $mami->say; #ティロ・フィナーレ

    my ($kyoko,$sayaka) = Acme::MadokaMagica->members_of($Acme::MadokaMagica::KyoSaya);

    print $kyoko->say; #'喰うかい?';
    $sayaka->qb;
    print $sayaka->name; #'Oktavia_Von_Seckendorff'


=head1 DESCRIPTION

MadokaMagica is one of the most famouse Japanese TV animation.
This animation is magical girl heartful story.
When you leave 100 lines, the soul gem makes it impossible to use method.

It was in reference Acme::PriPara (C)htk291.

=head1 LICENSE

Copyright (C) AnaTofuZ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

AnaTofuZ E<lt>e155730@ie.u-ryukyu.ac.jpE<gt>

=cut

