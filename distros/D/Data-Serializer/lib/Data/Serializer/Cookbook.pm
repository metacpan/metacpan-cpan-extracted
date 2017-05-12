package Data::Serializer::Cookbook;


use warnings;
use strict;
use vars ('$VERSION');

$VERSION = '0.05';

1;

__END__;
#Documentation follows

=pod

=head1 NAME

Cookbook - Examples of how to use Data::Serializer

=head1 DESCRIPTION

B<Data::Serializer::Cookbook> is a collection of solutions 
for using B<Data::Serializer>.  

=head1 CONVENTIONS

Unless otherwise specified, all examples can be assumed to
begin with:

  use Data::Serializer;

  my $serializer = Data::Serializer->new();

Some examples will show different arguments to the B<new> method, 
where specified simply use that line instead of the simple form above.

=head1 CONVENTIONS for Raw Access

Fort hose who want a straight pass through to the underlying serializer, where 
nothing else is done (no encoding, encryption, compression, etc) there is L<Data::Serializer::Raw(3)>.

These begin like this:

  use Data::Serializer::Raw;

  my $raw_serializer = Data::Serializer::Raw->new();


=head1 Encrypting your data 

You wish to encrypt your data structure, so that it can only be decoded
by someone who shares the same key.  

=head2 Solution

  $serializer->secret('mysecret');

  my $encrypted_hashref = $serializer->serializer($hash);

  ... (in other program) ...

  $serializer->secret('mysecret');

  my $clear_hash = $serializer->deserializer($encrypted_hash);

Note:  You will have to have the Crypt::CBC module installed for
this to work.  

=head1 Compressing your data 

You wish to compress your data structure to cut down on how much
disk space it will take up.

=head2 Solution

  $serializer->compress(1);

  my $compressed_hashref = $serializer->serializer($hash);

  ... (in other program) ...

  my $clear_hash = $serializer->deserializer($compressed_hash);

Note:  You will have to have the Compress::Zlib module installed for
this to work.  Your mileage will vary dramatically depending on what
serializer you use.  Some serializers are already fairly compact.

=head1 You want to read in data serialized outside of Data::Serializer

You need to write a program that can read in data serialized in a 
format other than Data::Serializer.  For example you need to be able
to be able to process data serialized by XML::Dumper.

=head2 Solution

  use Data::Serializer::Raw;

  my $xml_raw_serializer = Data::Serializer::Raw->(serializer => 'XML::Dumper');

  my $hash_ref = $xml_raw_serializer->deserialize($xml_data);

=head1 You want to write serialized data in a form understood outside of Data::Serializer

You need to write a program that can write out data in a format 
other than Data::Serializer.  Or said more generically you need
to write out data in the format native to the underlying serializer.
For our example we will be exporting data using XML::Dumper format.

=head2 Solution

  ues Data::Serializer::Raw;

  my $xml_raw_serializer = Data::Serializer::Raw->(serializer => 'XML::Dumper');

  my $xml_data = $xml_raw_serializer->serialize($hash_ref);


=head1 You want to convert data between two different serializers native formats

You have data serialized by php that you want to convert to xml for use by other 
programs.

=head2 Solution

  use Data::Serializer::Raw;

  my $xml_raw_serializer = Data::Serializer::Raw->(serializer => 'XML::Dumper');

  my $php_raw_serializer = Data::Serializer::Raw->(serializer => 'PHP::Serialization');

  my $hash_ref = $php_raw_serializer->deserialize($php_data);

  my $xml_data = $xml_raw_serializer->serialize($hash_ref); 

=head1  Keeping data persistent between executions of a program.

You have a program that you run every 10 minutes, it uses SNMP to pull
some counters from one of your routers.  You want your program to keep
the counters from the last run so that it can see how much traffic has
passed over a link since it last ran.

=head2 Solution

  # path to store our serialized data
  # be paranoid, use full paths
  my $last_run_datafile = '/full/path/to/file/lastrun.data';

  #We keep our data as a hash reference
  my $last_data = $serializer->retrieve($last_run_datafile);
  
  #Pull in our new data through 'pull_data()';
  my $new_data = query_router($router);

  #run comparison code
  run_comparison($last_data,$new_data);

  $serializer->store($new_data);

=head1 AUTHOR

Neil Neely <F<neil@neely.cx>>.

=head1 COPYRIGHT

Copyright (c) 2001-2011 Neil Neely.  All rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

=over 4

=item  L<Data::Serializer(3)>

=item  L<Data::Serializer::Raw(3)>

=back

=cut
