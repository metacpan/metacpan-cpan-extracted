package Data::RuledValidator::Plugin::EmailLoose;

our $VERSION = '0.03';

use Email::Valid::Loose;

Data::RuledValidator->add_condition_operator
  (
   'mail_loose' => sub{my($self, $v) = @_; return Email::Valid::Loose->address($v) ? 1 : ()},
  );

1;
__END__

=pod

=head1 NAME

Data::RuledValidator::Plugin::EmailLoose - use Email::Valid::Loose

=head1 DESCRIPTION

=head1 Description

=head1 Synopsys

=head1 Author

Ktat, E<lt>ktat@cpan.orgE<gt>

=head1 Copyright

Copyright 2006-2007 by Ktat

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
