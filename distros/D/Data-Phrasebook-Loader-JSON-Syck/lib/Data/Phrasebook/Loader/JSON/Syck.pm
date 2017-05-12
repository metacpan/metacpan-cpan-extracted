
package Data::Phrasebook::Loader::JSON::Syck;

use strict;
use warnings;

use Carp        'croak';
use JSON::Syck  ();
use File::Slurp ();

use Data::Phrasebook;

our $VERSION = '0.01';

use base 'Data::Phrasebook::Loader::Base';

sub load {
    my ($class, $filename) = @_;
    (defined $filename)
        || croak "No file given as argument!";
    (-e $filename)
        || croak "The file given '$filename' could not be found";        
    my $json = File::Slurp::slurp($filename) or croak "Could not slurp JSON file '$filename' got no data";
    my $d    = JSON::Syck::Load($json);
    (ref($d) eq 'HASH')
        || croak "Badly formatted JSON file '$filename'";
	$class->{JSON} = $d;    
}

sub get { 
	my ($class, $key) = @_;
	return undef unless $key;
	return undef unless $class->{JSON};
	$class->{JSON}->{$key};    
}

#sub dicts    { return () }
#sub keywords { return () }

1;

__END__

=pod

=head1 NAME

Data::Phrasebook::Loader::JSON::Syck - A Data::Phrasebook loader for JSON files

=head1 SYNOPSIS

  my $p = Data::Phrasebook->new(
      class  => 'Plain',
      loader => 'JSON::Syck',
      file   => 'errors.json',
  );
  
  # now use the phrasebook like any other ...
  warn $p->fetch('FAILED_LOGIN', { message => 'Could not find user'});

=head1 DESCRIPTION

This is a L<Data::Phrasebook> loader which will load phasebooks stored in 
JSON. It uses the very nice and very fast L<JSON::Syck> parser to load the 
JSON data. 

You should refer to the L<Data::Phrasebook> documentation for more 
information on how to use this module.

=head1 EXPECTED JSON FORMAT

This module expects that the JSON returned from C<JSON::Syck::Load($json)> will 
be a HASH reference. This is fairly simple as long as your top level data 
structure is a JSON hash. Here is an example from the test suite.

  {
      foo: "Welcome to [% my %] world. It is a nice [%place %].",
      bar: "Welcome to :my world. It is a nice :place."
  }

=head1 CAVEATS

This phrasebook loader does not yet support multiple phrasebook dictionaries.
Future plans do include supporting these, and we will retain backwards 
compatability with the JSON file format.

=head1 WHY JSON?

Because it is Plain Ole Javascript. If you need to share your phrasebook data 
(error messages and such) with Javascript, this is the ideal format.

=head1 METHODS 

These methods are those required by L<Data::Phrasebook::Loader>, they do not 
represent the API to this module. Please refer to the  L<Data::Phrasebook> for 
that information.

=over 4

=item B<load ($filename)>

=item B<get ($key)>

=back

=head1 SEE ALSO

=over 4

=item L<Data::Phrasebook>

=item L<JSON::Syck>

=item L<http://www.json.org/>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut