package Acme::CPANAuthors::India;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

# PODNAME: Acme::CPANAuthors::India
our $VERSION = '0.07'; # VERSION
# ABSTRACT: We are the Indian CPAN Authors. Coming from that big peninsula in the center of Asia, the original Indians. The ones columbus was looking for. :)
#
# This file is part of Acme-CPANAuthors-India
#
# This software is copyright (c) 2013 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# Dependencies

use Acme::CPANAuthors::Register (
    ADARSHTP  => 'ADARSH TP',
    AGUL      => 'Ashish Gulhati',
    ARJUNS    => 'Arjun Surendra',
    ARUN      => 'Arun Venkataraman',
    ARUNBEAR  => 'Arun Prasaad',
    ASHISHM   => 'Ashish Mukherjee',
    ASHOOOO   => 'Ashish Kasturia',
    AVIKAK    => 'Avinash Kak',
    AVINASH   => 'Avinash Chopde',
    AWA       => 'Vandana Awasthi',
    BALAJIRAM => 'Balaji Ramasubramanian',
    CHI       => 'chitresh sharma',
    CGANESAN  => 'Chander Ganesan',
    DEEPAKG   => 'Deepak Gulati',
    DHAVAL    => 'Dhaval Dhanani',
    DNARAYAN  => 'David Narayan',
    GAURAV    => 'Gaurav Vaidya',
    GAURAVKH  => 'Gaurav Khambhala',
    GERA      => 'Devendra Gera',
    GOYALI    => 'Abhishek Jain',
    GVENKAT   => 'venkatakrishnan',
    HAGGAI    => 'Alan Haggai Alavi',
    HARPREET  => 'Harpreet Saini',
    HUGHES    => 'Manish Saxena',
    JNAGRA    => 'Jasvir Nagra',
    KARTHIKK  => 'Karthik Krishnamurthy',
    KARTHIKU  => 'Karthik Umashankar',
    KCHAITAN  => 'A.Krishna Chaitanya',
    KRAMAN    => 'Karthikeyan Rajaram',
    KRISHPL   => 'Krishna Shamu Sethuraman',
    KTHAKORE  => 'Kartik Thakore',
    MALAY     => 'Malay Kumar Basu',
    MANJUNATH => 'Manjunath Kumatagi',
    MITHUN    => 'Mithun Ayachit',
    MVR       => 'Ramana Mokkapati',
    MUKUND    => 'Mukund Deshmukh',
    MPGUTTA   => 'Mohan Prasad Gutta',
    NISHANT   => 'Nishant Kakani',
    PRASAD    => 'Prasad Balan',
    PRATH     => 'Pratheepan Raveendranathan',
    PRAVEEN   => 'Praveen Kumar',
    PRATP     => 'Pratap Pereira',
    PRASHANT  => 'Prashant Shewale',
    PJAIN     => 'Pankaj Jain',
    RAMAN     => 'Raman.P',
    ROHITM    => 'Rohit Mishra',
    RVAIDH    => 'Rajesh Vaidheeswarran',
    SEN       => 'Sanjaysen Palash',
    SARAVANAN => 'Saravanan S E',
    SBALA     => 'S Balamurugan',
    SHGUN     => 'Shishir Gundavaram',
    SMALHOTRA => 'Sidharth Malhotra',
    SREEKANTH => 'Sreekanth Kocharlakota',
    SRSHAH    => 'Sagar R. Shah',
    SRIRAM    => 'Sriram Srinivasan',
    SACHINJSK => 'Sachin Sebastian',
    SUNILS    => 'Sunil S',
    SPRADEEP  => 'S Pradeep',
    SIMRAN    => 'simran',
    SIDD      => 'Siddhartha Basu',
    SID       => 'Siddharth Patwardhan',
    SHANTANU  => 'Shantanu Bhadoria',
    TSINGH    => 'Singh T. Junior',
    UARUN     => 'Arun Kumar U',
    VIKAS     => 'Vikas Naresh Kumar',
    VARUNK    => 'Varun kacholia',
    VIPUL     => 'Vipul Ved Prakash',
);

1;

=pod

=head1 NAME

Acme::CPANAuthors::India - We are the Indian CPAN Authors. Coming from that big peninsula in the center of Asia, the original Indians. The ones columbus was looking for. :)

=head1 VERSION

version 0.07

=head1 SYNOPSIS

     use Acme::CPANAuthors;
 
     my $authors  = Acme::CPANAuthors->new("India");
 
     my $number   = $authors->count;
     my @ids      = $authors->id;
     my @distros  = $authors->distributions("SHANTANU");
     my $url      = $authors->avatar_url("SHANTANU");
     my $kwalitee = $authors->kwalitee("SHANTANU");
     my $name     = $authors->name("SHANTANU");
     ...

=head1 DESCRIPTION

This Module provides a List of all Indian CPAN Authors Listed. 

=head1 NOTES

  * If you are a Indian CPAN author not listed here, please send your ID/name via email or a pull request on github so I can keep this module up to date. 
  * If you are not a Indian CPAN author but still on the list here, please send me your ID/name via email or submit a pull request on github and I will remove your name.

=head1 SEE ALSO

  * [Acme::CPANAuthors::Register]

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/acme-cpanauthors-india/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/acme-cpanauthors-india>

  git clone git://github.com/shantanubhadoria/acme-cpanauthors-india.git

=head1 AUTHOR

Shantanu Bhadoria <shantanu at cpan dott org>

=head1 CONTRIBUTORS

=over 4

=item *

Shantanu <shantanu@cpan.org>

=item *

Shantanu Bhadoria <shantanu.bhadoria@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


 # End of Acme::CPANAuthors::India
