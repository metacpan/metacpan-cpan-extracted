package Catmandu::Fix::Condition::marc_match;

use Moo;

our $VERSION = '1.253';

extends 'Catmandu::Fix::Condition::marc_all_match';

=head1 NAME

Catmandu::Fix::Condition::marc_match - Test if a MARC (sub)field matches a value

=head1 SYNOPSIS

   # marc_match(MARC_PATH,REGEX)

   # Match when 245 contains the value "My funny title"
   if marc_match('245','My funny title')
   	add_field('my.funny.title','true')
   end

   # Match when 245a contains the value "My funny title"
   if marc_match('245a','My funny title')
   	add_field('my.funny.title','true')
   end

   # Match when all 650 fields contain digits
   if marc_match('650','[0-9]')
     add_field('has_digits','true')
   end

   # Match when /one/ of the 650 fields contain digits
   do marc_each()
      if marc_all_match('650','[0-9]')
        add_field('has_digits','true')
      end
   end

=head1 DESCRIPTION

Evaluate the enclosing fixes only if the MARC (sub)field matches a
regular expression. When the MARC field is a repeated fiels, then all
the MARC fields should match the regular expression.

DEPRECATED: This condition is the same as L<Catmandu::Fix::Condition::marc_all_match>
and will be deleted in the future

=head1 METHODS

=head2 marc_match(MARC_PATH, REGEX)

Evaluates to true when all MARC_PATH values matches the REGEX, false otherwise.

=head1 SEE ALSO

L<Catmandu::Fix::Condition::marc_all_match>,
L<Catmandu::Fix::Condition::marc_any_match>,

=cut

1;
