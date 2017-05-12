package Data::RuledValidator::Plugin::Core;

use strict;
use warnings;
use Carp;
use Email::Valid ();

our $VERSION = '0.04';

Data::RuledValidator->add_condition_operator
  (
   'num'      => sub{my($self, $v) = @_; return $v =~/^\d+$/},
   'number'   => sub{my($self, $v) = @_; return $v =~/^\d+$/},
   'alpha'    => sub{my($self, $v) = @_; return $v =~/^[a-zA-Z]+$/},
   'alphanum' => sub{my($self, $v) = @_; return $v =~/^[a-zA-Z0-9]+$/},
   'word'     => sub{my($self, $v) = @_; return $v =~/^\w+$/},
   'words'    => sub{my($self, $v) = @_; return $v =~/^[\w\s]+$/},
   'any'      => sub{my($self, $v) = @_; return (defined $v and $v ne '')},
   'not_null' => sub{my($self, $v) = @_; return (defined $v and $v ne '')},
   'null'     => sub{my($self, $v) = @_; return (not defined $v or $v eq '')},
  );

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Data::RuledValidator::Plugin::Core - Data::RuldedValidator core plugins

=head1 PROVIDED CONDITIONS

=over 4

=item num, number

 key is num
 key is number

=item alpha

 key is alpha

key is alphabet

=item alphanum

 key is alphanum

key is alphabet and number.

=item word

 key is word

key matches \w

=item words

 key is words

key matches \w and \s

=item any, not_null

 key is any
 key is not_null

key is any value. null value is invalid.

=item null

 key is null

key is null.

=back

=head1 SEE ALSO

=over 4

=item * Data::RuledValidator

=back

=head1 AUTHOR

Ktat, E<lt>ktat@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2007 by Ktat

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
