# NAME

Acme::BABYMETAL - All about Japanese metal idol unit "BABYMETAL"

# SYNOPSIS

    use Acme::BABYMETAL;

    my $babymetal = Acme::BABYMETAL->new;

    $babymetal->homepage;
    $babymetal->youtube;
    $babymetal->facebook;
    $babymetal->instagram;
    $babymetal->twitter;

    my @members = $babymetal->members;
    for my $member (@members) {
        my $metal_name     = $member->metal_name;
        my $name_ja        = $member->name_ja;
        my $first_name_ja  = $member->first_name_ja;
        my $family_name_ja = $member->family_name_ja;
        my $name_en        = $member->name_en;
        my $first_name_en  = $member->first_name_en;
        my $family_name_en = $member->family_name_en;
        my $birthday       = $member->birthday;
        my $age            = $member->age;
        my $blood_type     = $member->blood_type;
        my $hometown       = $member->hometown;
        my $shout          = $member->shout;
    }

    my ($su_metal) = $babymetal->members('SU-METAL');
    my ($yuimetal) = $babymetal->members('YUIMETAL');
    my ($moametal) = $babymetal->members('MOAMETAL');

    $su_metal->shout;  # SU-METAL DEATH!!
    $yuimetal->shout;  # YUIMETAL DEATH!!
    $moametal->shout;  # MOAMETAL DEATH!!
    $babymetal->shout; # We are BABYMETAL DEATH!!

# DESCRIPTION

BABYMETAL is a Japanese metal idol unit.

Acme::BABYMETAL provides an easy method to information of BABYMETAL.

# LICENSE

Copyright (C) Hondallica.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hondallica <hondallica@gmail.com>
