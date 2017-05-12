# NAME

Acme::MadokaMagica - It's miracles and magic are real module.

# SYNOPSIS

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

# DESCRIPTION

MadokaMagica is one of the most famouse Japanese TV animation.
This animation is magical girl heartful story.
When you leave 100 lines, the soul gem makes it impossible to use method.

It was in reference Acme::PriPara (C)htk291.

# LICENSE

Copyright (C) AnaTofuZ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

AnaTofuZ <e155730@ie.u-ryukyu.ac.jp>
