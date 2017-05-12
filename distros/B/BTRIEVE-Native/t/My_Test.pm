package My_Test;

$File = 'TEST.BTR';

$Length = 13;

$Spec =
{
  File => [ $Length, 512, 1, 0, 0, 0    ]
, Key  => [       1,   3, 0, 0, 0, 0, 0 ]
};

$Mask = 'A3A10';

$FirstKey       = 101;
$NotExistingKey = 999;

$Data =
[
  [ $FirstKey+4,'Abc']
, [ $FirstKey  ,'Bcd']
, [ $FirstKey+2,'Cde']
];

1;

=head1 SPECIFICATION

=head2 File

  2 S  short int Logical Record Length
  2 S  short int Page Size
  2 S  short int Number of Indexes
  4 x4 char      Reserved
  2 S  short int File Flags
  1 C  char      Number of Duplicate Pointers To Reserve
  1 x  char      Not Used
  2 S  short int Allocation

=head2 Key

  2 S  short int Key Position
  2 S  short int Key Length
  2 S  short int Key Flags
  4 x4 char      Reserved
  1 C  char      Extended Data Type
  1 C  char      Null Value
  2 x2 char      Not Used
  1 C  char      Manually Assigned Key Number
  1 C  char      ACS Number

=cut
